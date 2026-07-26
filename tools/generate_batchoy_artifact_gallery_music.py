"""Generate an original gallery theme for the recovered La Paz Batchoy artifact.

The composition is synthesized from scratch and exported as an upload-ready MP3.
It intentionally uses no sampled or copyrighted recordings.
"""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np


SAMPLE_RATE = 44_100
BPM = 78.0
BEAT = 60.0 / BPM
BARS = 20
TAIL_SECONDS = 3.0
ROOT = Path(__file__).resolve().parents[1]
OUTPUT = (
    ROOT
    / "assets"
    / "audio"
    / "gallery"
    / "batchoy_artifact_gallery_theme.mp3"
)
RNG = np.random.default_rng(20260726)


def midi_frequency(note: float) -> float:
    return 440.0 * 2.0 ** ((note - 69.0) / 12.0)


def smooth_noise(length: int, window: int = 64) -> np.ndarray:
    noise = RNG.standard_normal(length + window).astype(np.float32)
    kernel = np.ones(window, dtype=np.float32) / window
    return np.convolve(noise, kernel, mode="valid")[:length]


def envelope(
    length: int,
    attack: float,
    release: float,
    sustain: float = 0.82,
) -> np.ndarray:
    env = np.full(length, sustain, dtype=np.float32)
    attack_samples = min(length, max(1, int(attack * SAMPLE_RATE)))
    release_samples = min(length, max(1, int(release * SAMPLE_RATE)))
    env[:attack_samples] = np.linspace(
        0.0,
        1.0,
        attack_samples,
        endpoint=False,
        dtype=np.float32,
    )
    env[-release_samples:] *= np.linspace(
        1.0,
        0.0,
        release_samples,
        dtype=np.float32,
    )
    return env


def synth_note(note: float, duration: float, instrument: str) -> np.ndarray:
    length = max(1, int(duration * SAMPLE_RATE))
    time = np.arange(length, dtype=np.float32) / SAMPLE_RATE
    frequency = midi_frequency(note)
    phase = 2.0 * np.pi * frequency * time

    if instrument == "rondalla":
        # Bright, quickly decaying plucks evoke a small string ensemble.
        signal = (
            np.sin(phase)
            + 0.52 * np.sin(2.01 * phase + 0.18)
            + 0.25 * np.sin(3.02 * phase + 0.41)
            + 0.11 * np.sin(4.04 * phase + 0.77)
        )
        signal += 0.22 * np.sin(phase * 1.003 + 0.35)
        signal *= np.exp(-4.0 * time / max(duration, 0.12))
        signal *= envelope(length, 0.004, min(0.16, duration * 0.35), 1.0)
    elif instrument == "flute":
        vibrato = 0.0032 * np.sin(2.0 * np.pi * 5.1 * time)
        flute_phase = 2.0 * np.pi * frequency * (
            time + vibrato / (2.0 * np.pi * 5.1)
        )
        breath = smooth_noise(length, 96)
        signal = (
            0.92 * np.sin(flute_phase)
            + 0.16 * np.sin(2.0 * flute_phase)
            + 0.05 * np.sin(3.0 * flute_phase)
            + 0.035 * breath
        )
        signal *= envelope(
            length,
            min(0.12, duration * 0.22),
            min(0.28, duration * 0.3),
            0.86,
        )
    elif instrument == "pad":
        signal = (
            0.62 * np.sin(phase)
            + 0.18 * np.sin(phase * 0.997 + 0.7)
            + 0.14 * np.sin(2.0 * phase + 0.25)
            + 0.06 * np.sin(3.0 * phase + 0.6)
        )
        signal *= envelope(
            length,
            min(0.55, duration * 0.3),
            min(0.75, duration * 0.35),
            0.68,
        )
    elif instrument == "bass":
        triangle = (2.0 / np.pi) * np.arcsin(np.sin(phase))
        signal = 0.68 * np.sin(phase) + 0.32 * triangle
        signal *= envelope(length, 0.025, min(0.3, duration * 0.35), 0.76)
    elif instrument == "bell":
        signal = (
            np.sin(phase)
            + 0.52 * np.sin(2.71 * phase + 0.2) * np.exp(-1.9 * time)
            + 0.27 * np.sin(4.12 * phase + 0.5) * np.exp(-3.1 * time)
            + 0.12 * np.sin(6.83 * phase + 0.9) * np.exp(-5.2 * time)
        )
        signal *= np.exp(-2.65 * time / max(duration, 0.1))
        signal *= envelope(length, 0.003, min(0.32, duration * 0.4), 1.0)
    else:
        raise ValueError(f"Unknown instrument: {instrument}")

    return signal.astype(np.float32)


def add_note(
    mix: np.ndarray,
    start: float,
    duration: float,
    note: float,
    amplitude: float,
    instrument: str,
    pan: float = 0.0,
) -> None:
    begin = int(start * SAMPLE_RATE)
    if begin >= len(mix):
        return
    signal = synth_note(note, duration, instrument)
    signal = signal[: len(mix) - begin]
    pan = float(np.clip(pan, -1.0, 1.0))
    left = math.sqrt((1.0 - pan) * 0.5)
    right = math.sqrt((1.0 + pan) * 0.5)
    mix[begin : begin + len(signal), 0] += signal * amplitude * left
    mix[begin : begin + len(signal), 1] += signal * amplitude * right


def add_wood_tap(
    mix: np.ndarray,
    start: float,
    amplitude: float,
    pan: float,
) -> None:
    duration = 0.09
    length = int(duration * SAMPLE_RATE)
    time = np.arange(length, dtype=np.float32) / SAMPLE_RATE
    signal = (
        np.sin(2.0 * np.pi * 890.0 * time)
        + 0.47 * np.sin(2.0 * np.pi * 1_430.0 * time + 0.35)
    )
    signal *= np.exp(-46.0 * time)
    begin = int(start * SAMPLE_RATE)
    signal = signal[: max(0, min(length, len(mix) - begin))]
    if not len(signal):
        return
    left = math.sqrt((1.0 - pan) * 0.5)
    right = math.sqrt((1.0 + pan) * 0.5)
    mix[begin : begin + len(signal), 0] += signal * amplitude * left
    mix[begin : begin + len(signal), 1] += signal * amplitude * right


def add_soft_shaker(
    mix: np.ndarray,
    start: float,
    amplitude: float,
    pan: float,
) -> None:
    duration = 0.075
    length = int(duration * SAMPLE_RATE)
    time = np.arange(length, dtype=np.float32) / SAMPLE_RATE
    noise = RNG.standard_normal(length).astype(np.float32)
    # A first difference removes most low-frequency energy.
    noise = np.concatenate(([0.0], np.diff(noise))).astype(np.float32)
    noise *= np.exp(-57.0 * time)
    begin = int(start * SAMPLE_RATE)
    noise = noise[: max(0, min(length, len(mix) - begin))]
    if not len(noise):
        return
    left = math.sqrt((1.0 - pan) * 0.5)
    right = math.sqrt((1.0 + pan) * 0.5)
    mix[begin : begin + len(noise), 0] += noise * amplitude * left
    mix[begin : begin + len(noise), 1] += noise * amplitude * right


def add_ceramic_chime(mix: np.ndarray, start: float, amplitude: float) -> None:
    # A resonant, bowl-like chime marks the artifact's recovery.
    for note, delay, gain, pan in (
        (72, 0.0, 1.0, -0.18),
        (79, 0.08, 0.78, 0.15),
        (84, 0.18, 0.52, 0.02),
    ):
        add_note(
            mix,
            start + delay,
            2.15,
            note,
            amplitude * gain,
            "bell",
            pan,
        )


CHORDS = (
    (48, 52, 55),  # C
    (47, 50, 55),  # G/B
    (45, 48, 52),  # Am
    (41, 45, 48),  # F
    (40, 48, 52),  # C/E
    (41, 45, 48),  # F
    (38, 41, 45, 48),  # Dm7
    (43, 47, 50),  # G
    (48, 52, 55),  # C
    (40, 43, 47),  # Em
    (41, 45, 48),  # F
    (43, 47, 50),  # G
    (45, 48, 52),  # Am
    (43, 47, 52),  # C/G
    (41, 45, 48),  # F
    (43, 47, 50),  # G
    (48, 52, 55),  # C
    (47, 50, 55),  # G/B
    (41, 45, 48),  # F
    (48, 52, 55),  # C
)


MELODY = {
    2: ((0.0, 0.9, 76), (1.0, 0.9, 79), (2.0, 1.35, 81), (3.5, 0.45, 79)),
    3: ((0.0, 0.9, 74), (1.0, 0.9, 79), (2.0, 1.9, 76)),
    4: ((0.0, 0.9, 76), (1.0, 0.9, 72), (2.0, 0.9, 69), (3.0, 0.9, 72)),
    5: ((0.0, 0.9, 69), (1.0, 0.9, 72), (2.0, 1.9, 74)),
    6: ((0.0, 0.9, 72), (1.0, 0.9, 76), (2.0, 0.9, 79), (3.0, 0.9, 81)),
    7: ((0.0, 1.4, 79), (1.5, 0.45, 76), (2.0, 1.9, 74)),
    8: ((0.0, 0.9, 76), (1.0, 0.9, 79), (2.0, 0.9, 84), (3.0, 0.9, 83)),
    9: ((0.0, 0.9, 79), (1.0, 0.9, 76), (2.0, 1.9, 74)),
    10: ((0.0, 0.65, 77), (0.75, 0.65, 79), (1.5, 0.9, 81), (2.5, 1.4, 84)),
    11: ((0.0, 0.9, 83), (1.0, 0.9, 81), (2.0, 0.9, 79), (3.0, 0.9, 74)),
    12: ((0.0, 0.9, 81), (1.0, 0.9, 76), (2.0, 0.9, 72), (3.0, 0.9, 76)),
    13: ((0.0, 0.9, 79), (1.0, 0.9, 76), (2.0, 1.9, 74)),
    14: ((0.0, 0.9, 76), (1.0, 0.9, 79), (2.0, 1.35, 81), (3.5, 0.45, 79)),
    15: ((0.0, 0.9, 74), (1.0, 0.9, 79), (2.0, 1.9, 76)),
    16: ((0.0, 0.9, 76), (1.0, 0.9, 72), (2.0, 0.9, 69), (3.0, 0.9, 72)),
    17: ((0.0, 0.9, 74), (1.0, 0.9, 76), (2.0, 1.9, 72)),
    18: ((0.0, 0.9, 69), (1.0, 0.9, 72), (2.0, 1.9, 76)),
    19: ((0.0, 0.9, 74), (1.0, 2.8, 72)),
}


def compose() -> np.ndarray:
    duration = BARS * 4.0 * BEAT + TAIL_SECONDS
    mix = np.zeros((int(duration * SAMPLE_RATE), 2), dtype=np.float32)

    add_ceramic_chime(mix, 0.34, 0.085)

    for bar, chord in enumerate(CHORDS):
        bar_start = bar * 4.0 * BEAT
        section_gain = 0.72 if bar < 2 or bar >= 18 else 1.0

        for index, note in enumerate(chord):
            pan = -0.28 + (0.56 * index / max(1, len(chord) - 1))
            add_note(
                mix,
                bar_start,
                3.92 * BEAT,
                note + 12,
                0.029 * section_gain,
                "pad",
                pan,
            )

        add_note(
            mix,
            bar_start,
            1.55 * BEAT,
            chord[0] - 12,
            0.063 * section_gain,
            "bass",
            -0.04,
        )
        add_note(
            mix,
            bar_start + 2.0 * BEAT,
            1.45 * BEAT,
            chord[-1] - 12,
            0.045 * section_gain,
            "bass",
            0.04,
        )

        if 1 <= bar <= 18:
            pattern = (0, 1, 2, 1, 0, 1, 2, 1)
            available = min(3, len(chord))
            for step, chord_index in enumerate(pattern):
                note = chord[chord_index % available] + 24
                pan = -0.3 if step % 2 == 0 else 0.3
                add_note(
                    mix,
                    bar_start + step * 0.5 * BEAT,
                    0.39 * BEAT,
                    note,
                    0.062 * section_gain,
                    "rondalla",
                    pan,
                )
                if bar >= 4:
                    add_soft_shaker(
                        mix,
                        bar_start + step * 0.5 * BEAT,
                        0.0048 * section_gain,
                        pan * 0.6,
                    )

            add_wood_tap(
                mix,
                bar_start + BEAT,
                0.018 * section_gain,
                0.22,
            )
            add_wood_tap(
                mix,
                bar_start + 3.0 * BEAT,
                0.015 * section_gain,
                -0.22,
            )

        for offset, note_length, note in MELODY.get(bar, ()):
            add_note(
                mix,
                bar_start + offset * BEAT,
                note_length * BEAT,
                note,
                0.081 * section_gain,
                "flute",
                0.08,
            )
            add_note(
                mix,
                bar_start + offset * BEAT,
                min(0.42 * BEAT, note_length * BEAT),
                note + 12,
                0.021 * section_gain,
                "rondalla",
                0.27,
            )

    final_bar = (BARS - 1) * 4.0 * BEAT
    add_ceramic_chime(mix, final_bar + 1.9 * BEAT, 0.042)

    # Spacious multi-tap reverb without wrapping the tail into the beginning.
    dry = mix.copy()
    wet = np.zeros_like(mix)
    for delay_seconds, gain, crossfeed in (
        (0.087, 0.17, False),
        (0.163, 0.12, True),
        (0.281, 0.08, False),
        (0.421, 0.045, True),
    ):
        delay = int(delay_seconds * SAMPLE_RATE)
        delayed = dry[:-delay, ::-1] if crossfeed else dry[:-delay]
        wet[delay:] += delayed * gain
    mix += wet

    # Gentle mastering keeps the gallery ambience warm and unobtrusive.
    mix -= np.mean(mix, axis=0, keepdims=True)
    mix = np.tanh(mix * 1.28).astype(np.float32)
    peak = float(np.max(np.abs(mix)))
    mix *= (10.0 ** (-1.5 / 20.0)) / max(peak, 1e-9)

    fade_in = int(0.38 * SAMPLE_RATE)
    fade_out = int(3.0 * SAMPLE_RATE)
    mix[:fade_in] *= np.linspace(0.0, 1.0, fade_in, dtype=np.float32)[:, None]
    mix[-fade_out:] *= np.linspace(
        1.0,
        0.0,
        fade_out,
        dtype=np.float32,
    )[:, None]
    return mix


def pcm_bytes(audio: np.ndarray) -> bytes:
    pcm = np.clip(audio, -1.0, 1.0)
    pcm = (pcm * 32_767.0).astype("<i2")
    return pcm.tobytes()


def encode_mp3(audio: np.ndarray, output_path: Path) -> None:
    try:
        import lameenc
    except ImportError as error:
        raise RuntimeError(
            "The 'lameenc' package is required. Install it with "
            "'python3 -m pip install lameenc'."
        ) from error

    encoder = lameenc.Encoder()
    encoder.set_bit_rate(128)
    encoder.set_in_sample_rate(SAMPLE_RATE)
    encoder.set_channels(2)
    encoder.set_quality(2)
    encoded = encoder.encode(pcm_bytes(audio)) + encoder.flush()
    output_path.write_bytes(encoded)


def main() -> None:
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    audio = compose()
    encode_mp3(audio, OUTPUT)

    duration = len(audio) / SAMPLE_RATE
    peak_db = 20.0 * math.log10(max(float(np.max(np.abs(audio))), 1e-12))
    rms_db = 20.0 * math.log10(
        max(float(np.sqrt(np.mean(audio**2))), 1e-12)
    )
    size_mb = OUTPUT.stat().st_size / (1024.0 * 1024.0)
    print(
        f"Created {OUTPUT}\n"
        f"Duration: {duration:.2f}s | Peak: {peak_db:.2f} dBFS | "
        f"RMS: {rms_db:.2f} dBFS | Size: {size_mb:.2f} MB"
    )


if __name__ == "__main__":
    main()
