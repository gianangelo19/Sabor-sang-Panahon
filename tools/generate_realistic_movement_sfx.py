"""Create naturalistic footsteps and separate wooden-door sounds from source recordings."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import soundfile as sf
from scipy.signal import butter, resample, sosfiltfilt


ROOT = Path(__file__).resolve().parents[1]
AUDIO = ROOT / "audio"
OUTPUT = AUDIO / "realistic_sfx_pack"
RNG = np.random.default_rng(20260711)


def filter_audio(audio: np.ndarray, sample_rate: int, low: float, high: float) -> np.ndarray:
    high_pass = butter(2, low, btype="highpass", fs=sample_rate, output="sos")
    low_pass = butter(3, high, btype="lowpass", fs=sample_rate, output="sos")
    audio = sosfiltfilt(high_pass, audio, axis=0)
    return sosfiltfilt(low_pass, audio, axis=0).astype(np.float32)


def normalize_peak(audio: np.ndarray, peak_db: float) -> np.ndarray:
    peak = float(np.max(np.abs(audio)))
    if peak:
        audio = audio * ((10 ** (peak_db / 20.0)) / peak)
    return audio.astype(np.float32)


def fade_edges(audio: np.ndarray, sample_rate: int, seconds: float) -> np.ndarray:
    fade_n = min(len(audio) // 2, int(seconds * sample_rate))
    curve = np.sin(np.linspace(0.0, np.pi / 2.0, fade_n)) ** 2
    audio[:fade_n] *= curve[:, None] if audio.ndim == 2 else curve
    audio[-fade_n:] *= curve[::-1, None] if audio.ndim == 2 else curve[::-1]
    return audio


def realistic_asphalt_walk() -> tuple[np.ndarray, int]:
    source, sample_rate = sf.read(AUDIO / "walking sound effect.mp3", dtype="float32", always_2d=True)
    # Trim at quiet points halfway around the first and last footfalls so the
    # recorded cadence remains even when the controller restarts the stream.
    start = int(0.075 * sample_rate)
    end = min(len(source), int(12.075 * sample_rate))
    walk = source[start:end].copy()
    walk = filter_audio(walk, sample_rate, 48, 14_500)

    # Keep the real stereo road reflections, with a small width reduction so
    # footsteps remain centered under the first-person player.
    mid = (walk[:, 0] + walk[:, 1]) * 0.5
    side = (walk[:, 0] - walk[:, 1]) * 0.34
    walk[:, 0] = mid + side
    walk[:, 1] = mid - side
    walk = fade_edges(walk, sample_rate, 0.012)
    return normalize_peak(walk, -3.0), sample_rate


def realistic_door_open() -> tuple[np.ndarray, int]:
    source, sample_rate = sf.read(AUDIO / "wood_door_sound.mp3", dtype="float32", always_2d=True)
    door = source.mean(axis=1, keepdims=True)
    door = filter_audio(door, sample_rate, 58, 13_000)

    # Preserve the recorded latch and hinge motion, lifting only the quieter
    # wood resonance so it reads at the door's short in-game distance.
    door = np.sign(door) * np.abs(door) ** 0.88
    door = fade_edges(door, sample_rate, 0.008)
    return normalize_peak(door, -2.5), sample_rate


def realistic_door_close() -> tuple[np.ndarray, int]:
    source, sample_rate = sf.read(AUDIO / "wood_door_sound.mp3", dtype="float32", always_2d=True)
    recorded = source.mean(axis=1)
    recorded = filter_audio(recorded[:, None], sample_rate, 58, 13_000)[:, 0]

    duration = 0.94
    close = np.zeros(int(duration * sample_rate), dtype=np.float32)

    # Reverse and slightly tighten the recorded hinge travel: the spectral
    # character remains real wood while its motion now leads into the jamb.
    hinge_source = recorded[int(0.12 * sample_rate) : int(1.18 * sample_rate)][::-1]
    hinge = resample(hinge_source, int(0.62 * sample_rate)).astype(np.float32)
    hinge *= np.sin(np.linspace(0.0, np.pi, len(hinge))) ** 0.7
    hinge_start = int(0.035 * sample_rate)
    close[hinge_start : hinge_start + len(hinge)] += hinge * 0.58

    # Layer a broad, non-tonal wooden impact with short cabinet resonances.
    impact_start = int(0.645 * sample_rate)
    impact_len = int(0.27 * sample_rate)
    t = np.arange(impact_len, dtype=np.float32) / sample_rate
    noise = RNG.standard_normal(impact_len).astype(np.float32)
    wood_band = butter(2, (95, 2_300), btype="bandpass", fs=sample_rate, output="sos")
    wood_noise = sosfiltfilt(wood_band, noise) * np.exp(-25 * t)
    resonance = (
        0.75 * np.sin(2 * np.pi * 79 * t + 0.3)
        + 0.42 * np.sin(2 * np.pi * 137 * t + 1.1)
        + 0.20 * np.sin(2 * np.pi * 246 * t)
    ) * np.exp(-20 * t)
    close[impact_start : impact_start + impact_len] += 0.34 * wood_noise + 0.30 * resonance

    # A lighter metal/wood latch follows the main impact by a few milliseconds.
    latch_start = int(0.684 * sample_rate)
    latch_len = int(0.12 * sample_rate)
    lt = np.arange(latch_len, dtype=np.float32) / sample_rate
    latch_noise = RNG.standard_normal(latch_len).astype(np.float32)
    latch_band = butter(2, (750, 7_500), btype="bandpass", fs=sample_rate, output="sos")
    latch = sosfiltfilt(latch_band, latch_noise) * np.exp(-46 * lt)
    latch += 0.20 * np.sin(2 * np.pi * 1_180 * lt) * np.exp(-38 * lt)
    close[latch_start : latch_start + latch_len] += latch * 0.16

    close = filter_audio(close[:, None], sample_rate, 48, 14_000)
    close = np.tanh(close * 1.18)
    close = fade_edges(close, sample_rate, 0.008)
    return normalize_peak(close, -2.0), sample_rate


def write(name: str, audio: np.ndarray, sample_rate: int) -> None:
    if not np.isfinite(audio).all():
        raise ValueError(f"{name} contains invalid samples")
    sf.write(OUTPUT / name, audio, sample_rate, subtype="PCM_24")
    peak = 20 * np.log10(max(float(np.max(np.abs(audio))), 1e-12))
    rms = 20 * np.log10(max(float(np.sqrt(np.mean(audio**2))), 1e-12))
    channels = 1 if audio.ndim == 1 else audio.shape[1]
    print(f"{name:30} {len(audio) / sample_rate:6.3f}s {channels}ch peak {peak:5.2f} dBFS RMS {rms:6.2f} dBFS")


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, generator in (
        ("walking_asphalt_realistic.wav", realistic_asphalt_walk),
        ("wood_door_open_realistic.wav", realistic_door_open),
        ("wood_door_close_realistic.wav", realistic_door_close),
    ):
        audio, sample_rate = generator()
        write(name, audio, sample_rate)


if __name__ == "__main__":
    main()
