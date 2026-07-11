"""Create two realistic, loopable cultural-echo cues for the Batchoy bowl."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import soundfile as sf
from scipy.signal import butter, sosfiltfilt


ROOT = Path(__file__).resolve().parents[1]
AUDIO = ROOT / "audio"
OUTPUT = AUDIO / "cultural_echoes"
RNG = np.random.default_rng(1938)


def band_filter(audio: np.ndarray, sample_rate: int, low: float, high: float) -> np.ndarray:
    high_pass = butter(2, low, btype="highpass", fs=sample_rate, output="sos")
    low_pass = butter(3, high, btype="lowpass", fs=sample_rate, output="sos")
    audio = sosfiltfilt(high_pass, audio, axis=0)
    return sosfiltfilt(low_pass, audio, axis=0).astype(np.float32)


def seamless_recorded_segment(
    source: np.ndarray,
    sample_rate: int,
    start_seconds: float,
    duration: float,
    crossfade: float,
) -> np.ndarray:
    start = int(start_seconds * sample_rate)
    length = int(duration * sample_rate)
    fade_n = int(crossfade * sample_rate)
    needed = length + fade_n
    if start + needed > len(source):
        start = max(0, len(source) - needed)
    segment = source[start : start + needed].copy()
    if len(segment) < needed:
        segment = np.pad(segment, ((0, needed - len(segment)), (0, 0)), mode="wrap")
    loop = segment[:length].copy()
    curve = np.sin(np.linspace(0.0, np.pi / 2.0, fade_n)) ** 2
    loop[:fade_n] = segment[length : length + fade_n] * (1.0 - curve[:, None]) + loop[:fade_n] * curve[:, None]
    return loop


def add_damped_tone(
    audio: np.ndarray,
    sample_rate: int,
    start: float,
    duration: float,
    frequencies: tuple[float, ...],
    amplitude: float,
    decay: float,
) -> None:
    begin = int(start * sample_rate)
    n = min(int(duration * sample_rate), len(audio) - begin)
    if n <= 0:
        return
    t = np.arange(n, dtype=np.float32) / sample_rate
    tone = np.zeros(n, dtype=np.float32)
    for index, frequency in enumerate(frequencies):
        tone += np.sin(2 * np.pi * frequency * t + index * 0.7) / (index + 1)
    tone *= np.exp(-decay * t) * amplitude
    audio[begin : begin + n] += tone


def add_slurp(audio: np.ndarray, sample_rate: int, start: float, amplitude: float) -> None:
    duration = 0.72
    begin = int(start * sample_rate)
    n = min(int(duration * sample_rate), len(audio) - begin)
    if n <= 0:
        return
    t = np.arange(n, dtype=np.float32) / sample_rate
    noise = RNG.standard_normal(n).astype(np.float32)
    breath_band = butter(2, (420, 4_400), btype="bandpass", fs=sample_rate, output="sos")
    breath = sosfiltfilt(breath_band, noise).astype(np.float32)
    envelope = np.sin(np.pi * np.clip(t / duration, 0.0, 1.0)) ** 1.3
    # A gently falling wet resonance suggests noodles and broth without using a synthetic chirp.
    instantaneous = 760 - 310 * (t / duration) + 35 * np.sin(2 * np.pi * 8.0 * t)
    phase = 2 * np.pi * np.cumsum(instantaneous) / sample_rate
    wet = 0.16 * np.sin(phase) + 0.08 * np.sin(2.1 * phase)
    audio[begin : begin + n] += (0.34 * breath + wet) * envelope * amplitude


def normalize_peak(audio: np.ndarray, peak_db: float) -> np.ndarray:
    peak = float(np.max(np.abs(audio)))
    if peak:
        audio *= (10 ** (peak_db / 20.0)) / peak
    return audio.astype(np.float32)


def eatery_echo() -> tuple[np.ndarray, int]:
    source, sample_rate = sf.read(AUDIO / "artifact_cultural_clue.mp3", dtype="float32", always_2d=True)
    ambience = seamless_recorded_segment(source, sample_rate, 42.0, 20.0, 0.8)
    ambience = ambience.mean(axis=1)
    ambience = band_filter(ambience[:, None], sample_rate, 105, 7_600)[:, 0]
    cue = ambience * 0.76

    # Ceramic bowls, metal spoons, and eating gestures sit above the real room bed.
    for start, pitch, level in (
        (1.65, 1_460, 0.030), (3.10, 2_080, 0.024), (5.72, 1_720, 0.034),
        (8.45, 2_320, 0.021), (10.92, 1_560, 0.032), (13.58, 1_980, 0.025),
        (16.72, 1_640, 0.030), (18.25, 2_260, 0.022),
    ):
        add_damped_tone(cue, sample_rate, start, 0.19, (pitch, pitch * 1.63, pitch * 2.14), level, 31.0)
        add_damped_tone(cue, sample_rate, start + 0.035, 0.16, (380, 615), level * 0.8, 24.0)
    for start, level in ((4.15, 0.060), (9.62, 0.052), (14.90, 0.058)):
        add_slurp(cue, sample_rate, start, level)

    # A short circular room reflection gives it the soft, remembered quality of a cultural echo.
    dry = cue.copy()
    cue += np.roll(dry, int(0.087 * sample_rate)) * 0.10
    cue += np.roll(dry, int(0.173 * sample_rate)) * 0.055
    return normalize_peak(np.tanh(cue * 1.05), -5.0)[:, None], sample_rate


def periodic_noise(length: int, sample_rate: int, low: float, high: float, tilt: float) -> np.ndarray:
    frequencies = np.fft.rfftfreq(length, 1 / sample_rate)
    spectrum = RNG.standard_normal(len(frequencies)) + 1j * RNG.standard_normal(len(frequencies))
    shape = np.zeros_like(frequencies)
    mask = (frequencies >= low) & (frequencies <= high)
    shape[mask] = np.maximum(frequencies[mask], 1.0) ** tilt
    noise = np.fft.irfft(spectrum * shape, n=length).astype(np.float32)
    noise /= max(float(np.std(noise)), 1e-9)
    return noise


def steam_echo() -> tuple[np.ndarray, int]:
    source, sample_rate = sf.read(AUDIO / "broth_cultural_clue.mp3", dtype="float32", always_2d=True)
    duration = 10.0
    recorded = seamless_recorded_segment(source, sample_rate, 7.5, duration, 0.65)
    recorded = recorded.mean(axis=1)
    recorded = band_filter(recorded[:, None], sample_rate, 70, 13_000)[:, 0]

    n = int(duration * sample_rate)
    t = np.arange(n, dtype=np.float32) / sample_rate
    hiss = periodic_noise(n, sample_rate, 1_100, 13_500, -0.18)
    hiss_mod = 0.62 + 0.16 * np.sin(2 * np.pi * 0.3 * t) + 0.11 * np.sin(2 * np.pi * 0.7 * t + 0.8)
    cue = recorded * 0.62 + hiss * hiss_mod * 0.024

    # Irregular broth bubbles and tiny surface pops.
    bubble_times = (0.62, 1.38, 2.05, 3.16, 3.83, 4.92, 5.47, 6.68, 7.24, 8.36, 9.12)
    for index, start in enumerate(bubble_times):
        base = 118 + (index * 37) % 145
        add_damped_tone(cue, sample_rate, start, 0.18, (base, base * 1.48), 0.043, 29.0)
        pop_begin = int((start + 0.015) * sample_rate)
        pop_n = min(int(0.045 * sample_rate), len(cue) - pop_begin)
        if pop_n > 0:
            pt = np.arange(pop_n, dtype=np.float32) / sample_rate
            pop = RNG.standard_normal(pop_n).astype(np.float32) * np.exp(-95 * pt)
            cue[pop_begin : pop_begin + pop_n] += pop * 0.012

    dry = cue.copy()
    cue += np.roll(dry, int(0.061 * sample_rate)) * 0.075
    cue += np.roll(dry, int(0.139 * sample_rate)) * 0.04
    # Lift the steady low-level hiss relative to the bubble transients so the
    # steam remains audible beneath exploration music at close range.
    cue = np.sign(cue) * np.abs(cue) ** 0.76
    return normalize_peak(np.tanh(cue * 1.08), -6.0)[:, None], sample_rate


def write(name: str, audio: np.ndarray, sample_rate: int) -> None:
    if not np.isfinite(audio).all():
        raise ValueError(f"{name} contains invalid samples")
    sf.write(OUTPUT / name, audio, sample_rate, subtype="PCM_24")
    peak = 20 * np.log10(max(float(np.max(np.abs(audio))), 1e-12))
    rms = 20 * np.log10(max(float(np.sqrt(np.mean(audio**2))), 1e-12))
    print(f"{name:31} {len(audio) / sample_rate:6.2f}s peak {peak:5.2f} dBFS RMS {rms:6.2f} dBFS")


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, generator in (
        ("batchoy_eatery_echo.wav", eatery_echo),
        ("batchoy_steam_echo.wav", steam_echo),
    ):
        audio, sample_rate = generator()
        write(name, audio, sample_rate)


if __name__ == "__main__":
    main()
