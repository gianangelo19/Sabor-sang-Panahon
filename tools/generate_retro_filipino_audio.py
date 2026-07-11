"""Generate an original retro-Filipino music and SFX pack for the Godot project."""

from __future__ import annotations

import subprocess
import tempfile
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy.signal import butter, sosfilt


SR = 44_100
ROOT = Path(__file__).resolve().parents[1]
AUDIO_DIR = ROOT / "audio" / "retro_filipino_pack"
RNG = np.random.default_rng(1946)


def midi_freq(note: float) -> float:
    return 440.0 * 2.0 ** ((note - 69.0) / 12.0)


def adsr(length: int, attack: float, release: float, sustain: float = 0.82) -> np.ndarray:
    env = np.full(length, sustain, dtype=np.float32)
    attack_n = min(length, max(1, int(attack * SR)))
    release_n = min(length, max(1, int(release * SR)))
    env[:attack_n] = np.linspace(0.0, 1.0, attack_n, endpoint=False)
    env[-release_n:] *= np.linspace(1.0, 0.0, release_n)
    return env


def synth_note(note: float, duration: float, instrument: str) -> np.ndarray:
    n = max(1, int(duration * SR))
    t = np.arange(n, dtype=np.float32) / SR
    freq = midi_freq(note)
    vibrato = 0.0025 * np.sin(2 * np.pi * 5.2 * t)
    phase = 2 * np.pi * freq * (t + vibrato / 5.2)

    if instrument == "pluck":
        wave = (
            np.sin(phase)
            + 0.55 * np.sin(2.01 * phase + 0.2)
            + 0.25 * np.sin(3.02 * phase + 0.5)
            + 0.11 * np.sin(4.03 * phase)
        )
        wave *= np.exp(-4.8 * t / max(duration, 0.08))
        wave *= adsr(n, 0.003, min(0.09, duration * 0.3), 1.0)
    elif instrument == "pulse":
        cycle = np.mod(phase, 2 * np.pi)
        wave = np.where(cycle < 0.28 * 2 * np.pi, 1.0, -1.0)
        wave += 0.18 * np.sin(phase)
        wave *= adsr(n, 0.012, min(0.13, duration * 0.4), 0.72)
    elif instrument == "triangle":
        wave = (2.0 / np.pi) * np.arcsin(np.sin(phase))
        wave += 0.12 * np.sin(2 * phase)
        wave *= adsr(n, 0.008, min(0.12, duration * 0.35), 0.9)
    elif instrument == "pad":
        wave = 0.7 * np.sin(phase) + 0.22 * np.sin(2 * phase) + 0.08 * np.sin(3 * phase)
        wave *= adsr(n, min(0.28, duration * 0.25), min(0.35, duration * 0.3), 0.72)
    elif instrument == "bell":
        wave = (
            np.sin(phase)
            + 0.48 * np.sin(2.76 * phase + 0.3) * np.exp(-2.0 * t)
            + 0.23 * np.sin(5.41 * phase) * np.exp(-4.0 * t)
        )
        wave *= np.exp(-3.4 * t / max(duration, 0.08))
        wave *= adsr(n, 0.002, min(0.16, duration * 0.4), 1.0)
    else:
        raise ValueError(f"Unknown instrument: {instrument}")
    return wave.astype(np.float32)


def add_note(
    mix: np.ndarray,
    start: float,
    duration: float,
    note: float,
    amplitude: float,
    instrument: str,
    pan: float = 0.0,
) -> None:
    begin = int(start * SR)
    if begin >= len(mix):
        return
    mono = synth_note(note, duration, instrument)
    mono = mono[: len(mix) - begin]
    left = np.sqrt((1.0 - np.clip(pan, -1.0, 1.0)) * 0.5)
    right = np.sqrt((1.0 + np.clip(pan, -1.0, 1.0)) * 0.5)
    mix[begin : begin + len(mono), 0] += mono * amplitude * left
    mix[begin : begin + len(mono), 1] += mono * amplitude * right


def add_woodblock(mix: np.ndarray, start: float, amplitude: float, pan: float = 0.0) -> None:
    duration = 0.085
    n = int(duration * SR)
    t = np.arange(n, dtype=np.float32) / SR
    click = (np.sin(2 * np.pi * 1_180 * t) + 0.52 * np.sin(2 * np.pi * 1_790 * t))
    click *= np.exp(-48 * t)
    begin = int(start * SR)
    click = click[: max(0, min(n, len(mix) - begin))]
    if not len(click):
        return
    left = np.sqrt((1.0 - pan) * 0.5)
    right = np.sqrt((1.0 + pan) * 0.5)
    mix[begin : begin + len(click), 0] += click * amplitude * left
    mix[begin : begin + len(click), 1] += click * amplitude * right


def add_soft_kick(mix: np.ndarray, start: float, amplitude: float) -> None:
    duration = 0.22
    n = int(duration * SR)
    t = np.arange(n, dtype=np.float32) / SR
    phase = 2 * np.pi * (88 * t - 31 * t**2)
    kick = np.sin(phase) * np.exp(-18 * t)
    begin = int(start * SR)
    kick = kick[: max(0, min(n, len(mix) - begin))]
    if len(kick):
        mix[begin : begin + len(kick)] += kick[:, None] * amplitude


def add_shaker(mix: np.ndarray, start: float, amplitude: float, pan: float) -> None:
    duration = 0.055
    n = int(duration * SR)
    noise = RNG.standard_normal(n).astype(np.float32)
    high = butter(2, 4_500, btype="highpass", fs=SR, output="sos")
    noise = sosfilt(high, noise).astype(np.float32)
    noise *= np.exp(-75 * np.arange(n) / SR)
    begin = int(start * SR)
    noise = noise[: max(0, min(n, len(mix) - begin))]
    if not len(noise):
        return
    left = np.sqrt((1.0 - pan) * 0.5)
    right = np.sqrt((1.0 + pan) * 0.5)
    mix[begin : begin + len(noise), 0] += noise * amplitude * left
    mix[begin : begin + len(noise), 1] += noise * amplitude * right


def circular_reverb(mix: np.ndarray, amount: float) -> np.ndarray:
    dry = mix.copy()
    for delay, gain, cross in ((0.093, 0.20, False), (0.181, 0.13, True), (0.307, 0.08, False)):
        shifted = np.roll(dry, int(delay * SR), axis=0)
        if cross:
            shifted = shifted[:, ::-1]
        mix += shifted * (gain * amount)
    return mix


def master_music(mix: np.ndarray) -> np.ndarray:
    high = butter(2, 42, btype="highpass", fs=SR, output="sos")
    low = butter(4, 12_200, btype="lowpass", fs=SR, output="sos")
    mix = sosfilt(high, mix, axis=0).astype(np.float32)
    mix = sosfilt(low, mix, axis=0).astype(np.float32)
    mix = np.tanh(mix * 1.18).astype(np.float32)
    return normalize_peak(mix, -1.4)


def compose_main_menu() -> np.ndarray:
    bpm = 84.0
    beat = 60.0 / bpm
    beats_per_bar = 4
    bars = 24
    mix = np.zeros((int(bars * beats_per_bar * beat * SR), 2), dtype=np.float32)

    chords = [
        (43, 47, 50),  # G major
        (42, 45, 50),  # D/F-sharp
        (36, 40, 43),  # C major
        (38, 42, 45),  # D major
        (43, 47, 50),
        (36, 40, 43),
        (38, 43, 47),  # G over D
        (38, 42, 45),
    ]
    melody = [
        ((0, .75, 71), (.75, .75, 74), (1.5, 1.45, 79), (3.0, .78, 74)),
        ((0, 1.0, 69), (1.0, .75, 71), (1.75, 1.2, 74), (3.0, .78, 69)),
        ((0, .75, 76), (.75, .75, 79), (1.5, 1.4, 81), (3.0, .78, 79)),
        ((0, .75, 78), (.75, .75, 76), (1.5, 1.4, 74)),
        ((0, 1.0, 74), (1.0, .75, 71), (1.75, 1.2, 67), (3.0, .78, 71)),
        ((0, .75, 76), (.75, .75, 79), (1.5, 1.4, 76), (3.0, .78, 74)),
        ((0, .75, 71), (.75, .75, 74), (1.5, .75, 79), (2.25, .75, 81), (3.0, .78, 79)),
        ((0, .75, 78), (.75, .75, 76), (1.5, 2.25, 74)),
    ]

    for bar in range(bars):
        bar_start = bar * beats_per_bar * beat
        chord = chords[bar % 8]
        # Spacious major-key harmony keeps the title screen warm and welcoming.
        for note in chord:
            add_note(mix, bar_start, 3.85 * beat, note + 12, 0.016, "pad", (note - chord[1]) * 0.06)
        add_note(mix, bar_start, 1.35 * beat, chord[0] - 12, 0.058, "triangle", -0.06)
        add_note(mix, bar_start + 2 * beat, 0.9 * beat, chord[2] - 12, 0.038, "triangle", 0.06)

        arp_positions = (0.0, 0.75, 1.5, 2.5, 3.25)
        arp_indices = (0, 1, 2, 1, 2)
        for step, (position, chord_index) in enumerate(zip(arp_positions, arp_indices)):
            add_note(
                mix,
                bar_start + position * beat,
                0.42 * beat,
                chord[chord_index] + 24,
                0.045,
                "pluck",
                -0.25 + step * 0.12,
            )
        add_woodblock(mix, bar_start + beat, 0.009, -0.2)
        add_woodblock(mix, bar_start + 3 * beat, 0.008, 0.2)

        # A soft triangle melody supplies the retro identity without dominating.
        for offset, duration, note in melody[bar % 8]:
            add_note(mix, bar_start + offset * beat, duration * beat * 0.9, note, 0.055, "triangle", 0.08)
            if bar >= 16 and offset == 0:
                add_note(mix, bar_start + offset * beat, 0.28 * beat, note + 12, 0.015, "pluck", 0.2)

    mastered = master_music(circular_reverb(mix, 0.42))
    return normalize_peak(mastered, -3.2)


def compose_in_game() -> np.ndarray:
    bpm = 96.0
    beat = 60.0 / bpm
    beats_per_bar = 4
    bars = 32
    mix = np.zeros((int(bars * beats_per_bar * beat * SR), 2), dtype=np.float32)
    chords = [
        (43, 47, 50), (40, 43, 47), (36, 40, 43), (38, 42, 45),
        (43, 47, 50), (47, 50, 54), (36, 40, 43), (38, 42, 45),
        (40, 43, 47), (47, 50, 54), (36, 40, 43), (43, 47, 50),
        (45, 48, 52), (38, 42, 45), (43, 47, 50), (38, 42, 45),
    ]
    melody = [
        (71, 74, 79, 74), (79, 76, 71, 69), (67, 71, 74, 76), (69, 74, 78, 74),
        (71, 74, 79, 81), (83, 81, 79, 74), (76, 74, 71, 67), (69, 71, 74, 78),
        (79, 76, 74, 71), (71, 74, 78, 81), (79, 76, 74, 67), (71, 74, 79, 74),
        (69, 72, 76, 72), (69, 74, 78, 81), (79, 74, 71, 67), (69, 71, 74, 78),
    ]

    for bar in range(bars):
        bar_start = bar * beats_per_bar * beat
        chord = chords[bar % 16]
        add_note(mix, bar_start, 1.55 * beat, chord[0] - 12, 0.12, "triangle", -0.05)
        add_note(mix, bar_start + 2 * beat, 1.55 * beat, chord[2] - 12, 0.10, "triangle", 0.05)
        for note in chord:
            add_note(mix, bar_start, 3.85 * beat, note + 12, 0.023, "pad", (note - chord[1]) * 0.08)

        # Bright off-beat plucks mimic a compact retro rondalla accompaniment.
        pattern = (0, 1, 2, 1, 0, 1, 2, 1)
        for step, chord_index in enumerate(pattern):
            pan = -0.32 if step % 2 == 0 else 0.32
            add_note(mix, bar_start + step * 0.5 * beat, 0.36 * beat, chord[chord_index] + 24, 0.077, "pluck", pan)
            add_shaker(mix, bar_start + step * 0.5 * beat, 0.0065 if step % 2 else 0.004, pan * 0.7)
        add_soft_kick(mix, bar_start, 0.105)
        add_soft_kick(mix, bar_start + 2 * beat, 0.075)
        add_woodblock(mix, bar_start + beat, 0.047, 0.22)
        add_woodblock(mix, bar_start + 3 * beat, 0.043, -0.22)

        # Leave breathing room in alternate bars so exploration remains unobtrusive.
        if bar % 2 == 0 or bar >= 24:
            notes = melody[bar % 16]
            for i, note in enumerate(notes):
                offset = i * beat
                duration = 0.78 * beat if i < 3 else 0.9 * beat
                add_note(mix, bar_start + offset, duration, note, 0.076, "pulse", 0.11)
                add_note(mix, bar_start + offset, duration * 0.7, note + 12, 0.029, "pluck", 0.24)

    return master_music(circular_reverb(mix, 0.55))


def periodic_noise(duration: float, low_hz: float, high_hz: float, tilt: float = 0.0) -> np.ndarray:
    n = int(duration * SR)
    freqs = np.fft.rfftfreq(n, 1 / SR)
    spectrum = RNG.standard_normal(len(freqs)) + 1j * RNG.standard_normal(len(freqs))
    mask = (freqs >= low_hz) & (freqs <= high_hz)
    shape = np.zeros_like(freqs)
    safe = np.maximum(freqs[mask], 1.0)
    shape[mask] = safe**tilt
    noise = np.fft.irfft(spectrum * shape, n=n).astype(np.float32)
    noise /= max(float(np.std(noise)), 1e-9)
    return noise


def normalize_peak(audio: np.ndarray, peak_db: float) -> np.ndarray:
    peak = float(np.max(np.abs(audio)))
    if peak > 0:
        audio = audio * ((10 ** (peak_db / 20.0)) / peak)
    return audio.astype(np.float32)


def jeepney_idle() -> np.ndarray:
    duration = 12.0
    n = int(duration * SR)
    t = np.arange(n, dtype=np.float32) / SR
    phase = 2 * np.pi * 24.0 * t + 0.19 * np.sin(2 * np.pi * 0.25 * t)
    engine = sum((1.0 / h) * np.sin(h * phase + 0.13 * h) for h in range(1, 9))
    rumble = periodic_noise(duration, 28, 340, -0.45)
    metal = periodic_noise(duration, 520, 3_100, -0.2)
    rattle_gate = np.maximum(0.0, np.sin(2 * np.pi * 7.5 * t)) ** 12
    audio = 0.48 * engine + 0.17 * rumble + 0.07 * metal * rattle_gate
    audio *= 0.96 + 0.04 * np.sin(2 * np.pi * 0.25 * t + 1.2)
    audio = np.tanh(audio * 0.72)
    return normalize_peak(audio, -3.0)


def jeepney_cruising() -> np.ndarray:
    duration = 12.0
    n = int(duration * SR)
    t = np.arange(n, dtype=np.float32) / SR
    phase = 2 * np.pi * 52.0 * t + 0.27 * np.sin(2 * np.pi * 0.25 * t)
    engine = sum((1.0 / h**0.72) * np.sin(h * phase + 0.2 * h) for h in range(1, 11))
    road = periodic_noise(duration, 45, 2_600, -0.32)
    whine = np.sin(2 * np.pi * 416 * t + 0.9 * np.sin(2 * np.pi * 0.25 * t))
    chassis = periodic_noise(duration, 700, 4_600, -0.12)
    vibration = 0.5 + 0.5 * np.sin(2 * np.pi * 9.0 * t) ** 8
    audio = 0.38 * engine + 0.20 * road + 0.065 * whine + 0.045 * chassis * vibration
    audio *= 0.94 + 0.06 * np.sin(2 * np.pi * 0.25 * t + 0.4)
    audio = np.tanh(audio * 0.76)
    return normalize_peak(audio, -3.0)


def walking_asphalt() -> np.ndarray:
    duration = 3.6
    audio = np.zeros(int(duration * SR), dtype=np.float32)
    step_times = np.arange(0.18, duration, 0.45)
    for index, start in enumerate(step_times):
        length = int(0.19 * SR)
        t = np.arange(length, dtype=np.float32) / SR
        noise = RNG.standard_normal(length).astype(np.float32)
        band = butter(2, (420, 6_200), btype="bandpass", fs=SR, output="sos")
        grit = sosfilt(band, noise).astype(np.float32) * np.exp(-26 * t)
        thud_freq = 92 if index % 2 == 0 else 104
        thud = np.sin(2 * np.pi * thud_freq * t) * np.exp(-31 * t)
        heel = np.sin(2 * np.pi * 230 * t) * np.exp(-48 * t)
        step = 0.34 * grit + 0.56 * thud + 0.18 * heel
        begin = int(start * SR)
        audio[begin : begin + min(length, len(audio) - begin)] += step[: len(audio) - begin]
    return normalize_peak(np.tanh(audio * 1.15), -4.0)


def wood_door_open() -> np.ndarray:
    duration = 0.95
    n = int(duration * SR)
    t = np.arange(n, dtype=np.float32) / SR
    audio = np.zeros(n, dtype=np.float32)

    latch_n = int(0.13 * SR)
    lt = np.arange(latch_n, dtype=np.float32) / SR
    latch = (np.sin(2 * np.pi * 640 * lt) + 0.45 * np.sin(2 * np.pi * 1_470 * lt)) * np.exp(-42 * lt)
    audio[int(0.025 * SR) : int(0.025 * SR) + latch_n] += latch * 0.54

    begin = int(0.11 * SR)
    creak_t = np.arange(n - begin, dtype=np.float32) / SR
    inst_freq = 112 - 48 * (creak_t / max(creak_t[-1], 1e-6)) + 9 * np.sin(2 * np.pi * 4.1 * creak_t)
    phase = 2 * np.pi * np.cumsum(inst_freq) / SR
    scrape_noise = RNG.standard_normal(len(creak_t)).astype(np.float32)
    band = butter(2, (180, 2_800), btype="bandpass", fs=SR, output="sos")
    scrape_noise = sosfilt(band, scrape_noise).astype(np.float32)
    creak_shape = np.maximum(0.0, np.sin(np.pi * np.clip(creak_t / 0.76, 0, 1)))
    creak_env = creak_shape**1.4
    creak = (0.56 * np.sin(phase) + 0.23 * np.sin(2.03 * phase) + 0.10 * scrape_noise) * creak_env
    audio[begin:] += creak
    audio *= np.linspace(1.0, 0.0, n, dtype=np.float32) ** 0.18
    return normalize_peak(np.tanh(audio * 1.25), -2.5)


def selecting_app() -> np.ndarray:
    duration = 0.19
    mix = np.zeros((int(duration * SR), 2), dtype=np.float32)
    add_note(mix, 0.0, 0.105, 79, 0.34, "pulse", -0.18)
    add_note(mix, 0.052, 0.13, 86, 0.31, "bell", 0.18)
    return normalize_peak(mix, -4.0)


def menu_button_press() -> np.ndarray:
    duration = 0.13
    mix = np.zeros((int(duration * SR), 2), dtype=np.float32)
    add_note(mix, 0.0, 0.085, 79, 0.19, "triangle", -0.08)
    add_note(mix, 0.018, 0.105, 86, 0.095, "pluck", 0.10)
    add_woodblock(mix, 0.0, 0.012, 0.0)
    fade = int(0.025 * SR)
    mix[-fade:] *= np.linspace(1.0, 0.0, fade)[:, None]
    return normalize_peak(mix, -5.0)


def phone_open_sound() -> np.ndarray:
    duration = 0.22
    mix = np.zeros((int(duration * SR), 2), dtype=np.float32)
    add_note(mix, 0.0, 0.13, 74, 0.12, "triangle", -0.14)
    add_note(mix, 0.055, 0.15, 79, 0.14, "bell", 0.14)
    add_woodblock(mix, 0.0, 0.008, 0.0)
    return normalize_peak(mix, -4.5)


def phone_close_sound() -> np.ndarray:
    duration = 0.19
    mix = np.zeros((int(duration * SR), 2), dtype=np.float32)
    add_note(mix, 0.0, 0.12, 79, 0.11, "triangle", 0.12)
    add_note(mix, 0.045, 0.13, 74, 0.13, "pluck", -0.12)
    add_woodblock(mix, 0.09, 0.009, 0.0)
    return normalize_peak(mix, -4.5)


def phone_tap_sound() -> np.ndarray:
    duration = 0.085
    mix = np.zeros((int(duration * SR), 2), dtype=np.float32)
    add_note(mix, 0.0, 0.075, 83, 0.095, "pluck", 0.04)
    add_woodblock(mix, 0.0, 0.007, -0.04)
    return normalize_peak(mix, -6.0)


def phone_back_sound() -> np.ndarray:
    duration = 0.13
    mix = np.zeros((int(duration * SR), 2), dtype=np.float32)
    add_note(mix, 0.0, 0.085, 81, 0.09, "triangle", 0.10)
    add_note(mix, 0.035, 0.085, 76, 0.10, "pluck", -0.10)
    return normalize_peak(mix, -5.5)


def dialogue_continue_sound() -> np.ndarray:
    duration = 0.15
    mix = np.zeros((int(duration * SR), 2), dtype=np.float32)
    add_note(mix, 0.0, 0.13, 74, 0.10, "pluck", -0.06)
    add_note(mix, 0.025, 0.11, 79, 0.055, "triangle", 0.06)
    add_woodblock(mix, 0.0, 0.010, 0.0)
    return normalize_peak(mix, -5.0)


def completed_task() -> np.ndarray:
    duration = 1.45
    mix = np.zeros((int(duration * SR), 2), dtype=np.float32)
    notes = (67, 71, 74, 79)
    for index, note in enumerate(notes):
        start = index * 0.18
        add_note(mix, start, 0.48, note, 0.22, "pluck", -0.35 + index * 0.23)
        add_note(mix, start, 0.28, note + 12, 0.10, "pulse", -0.2 + index * 0.14)
    add_note(mix, 0.74, 0.64, 83, 0.15, "bell", 0.1)
    add_note(mix, 0.74, 0.64, 86, 0.11, "bell", 0.28)
    mix = circular_reverb(mix, 0.32)
    fade = int(0.22 * SR)
    mix[-fade:] *= np.linspace(1.0, 0.0, fade)[:, None]
    return normalize_peak(mix, -3.0)


def write_music(name: str, audio: np.ndarray) -> None:
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as wav_file:
        wav_path = Path(wav_file.name)
    try:
        sf.write(wav_path, audio, SR, subtype="PCM_24")
        subprocess.run(
            [
                "ffmpeg", "-y", "-v", "error", "-i", str(wav_path),
                "-codec:a", "libvorbis", "-q:a", "5", str(AUDIO_DIR / name),
            ],
            check=True,
        )
    finally:
        wav_path.unlink(missing_ok=True)


def write_sfx(name: str, audio: np.ndarray) -> None:
    sf.write(AUDIO_DIR / name, audio, SR, subtype="PCM_16")


def describe(name: str, audio: np.ndarray) -> None:
    if not np.isfinite(audio).all():
        raise ValueError(f"{name} contains non-finite samples")
    duration = len(audio) / SR
    peak = 20 * np.log10(max(float(np.max(np.abs(audio))), 1e-12))
    rms = 20 * np.log10(max(float(np.sqrt(np.mean(audio**2))), 1e-12))
    channels = 1 if audio.ndim == 1 else audio.shape[1]
    print(f"{name:36s} {duration:7.3f}s  {channels}ch  peak {peak:6.2f} dBFS  RMS {rms:6.2f} dBFS")


def main() -> None:
    AUDIO_DIR.mkdir(parents=True, exist_ok=True)
    assets = (
        ("main_menu_retro_filipino.ogg", compose_main_menu),
        ("in_game_retro_filipino.ogg", compose_in_game),
        ("jeepney_idle_loop.wav", jeepney_idle),
        ("jeepney_cruising_loop.wav", jeepney_cruising),
        ("walking_asphalt_loop.wav", walking_asphalt),
        ("wood_door_open.wav", wood_door_open),
        ("select_app.wav", selecting_app),
        ("menu_button_press.wav", menu_button_press),
        ("phone_open.wav", phone_open_sound),
        ("phone_close.wav", phone_close_sound),
        ("phone_tap.wav", phone_tap_sound),
        ("phone_back.wav", phone_back_sound),
        ("dialogue_continue.wav", dialogue_continue_sound),
        ("completed_task.wav", completed_task),
    )
    for name, generator in assets:
        audio = generator()
        describe(name, audio)
        if name.endswith(".ogg"):
            write_music(name, audio)
        else:
            write_sfx(name, audio)


if __name__ == "__main__":
    main()
