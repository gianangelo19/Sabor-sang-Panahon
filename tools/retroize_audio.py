"""Create a warm 16-bit-era mix while preserving the source performance."""

from __future__ import annotations

import argparse
import subprocess
import tempfile
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy.signal import butter, sosfilt


def retroize(samples: np.ndarray, sample_rate: int) -> np.ndarray:
    audio = samples.astype(np.float32, copy=True)

    # Trim sub-bass and glossy highs to resemble an older console's sound path.
    high_pass = butter(2, 55, btype="highpass", fs=sample_rate, output="sos")
    low_pass = butter(4, min(11_000, sample_rate * 0.45), btype="lowpass", fs=sample_rate, output="sos")
    audio = sosfilt(high_pass, audio, axis=0).astype(np.float32)
    audio = sosfilt(low_pass, audio, axis=0).astype(np.float32)

    # Blend in a 24 kHz-style sample-and-hold layer for audible pixel texture.
    held = np.repeat(audio[::2], 2, axis=0)[: len(audio)]
    audio *= 0.78
    audio += held * 0.22

    # A dithered 10-bit layer keeps the effect musical instead of harsh.
    rng = np.random.default_rng(1995)
    levels = 2**9
    dither = rng.uniform(-0.5 / levels, 0.5 / levels, audio.shape).astype(np.float32)
    quantized = np.round((audio + dither) * levels) / levels
    audio *= 0.66
    audio += quantized.astype(np.float32) * 0.34

    # Older game mixes were generally less wide; a quiet cross-delay restores
    # some dreamy space without fighting positional effects in the game.
    if audio.shape[1] >= 2:
        mid = (audio[:, 0] + audio[:, 1]) * 0.5
        side = (audio[:, 0] - audio[:, 1]) * 0.5 * 0.72
        audio[:, 0] = mid + side
        audio[:, 1] = mid - side

        delay = max(1, round(sample_rate * 0.011))
        wet_left = audio[:-delay, 1].copy()
        wet_right = audio[:-delay, 0].copy()
        audio[delay:, 0] = audio[delay:, 0] * 0.94 + wet_left * 0.06
        audio[delay:, 1] = audio[delay:, 1] * 0.94 + wet_right * 0.06

    # Soft harmonic rounding gives the result the warmth of a console mix bus.
    drive = 1.16
    audio = np.tanh(audio * drive).astype(np.float32) / np.tanh(drive)

    peak = float(np.max(np.abs(audio)))
    if peak:
        audio *= (10 ** (-1.0 / 20.0)) / peak
    return audio


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    samples, sample_rate = sf.read(args.input, dtype="float32", always_2d=True)
    processed = retroize(samples, sample_rate)
    args.output.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as wav_file:
        wav_path = Path(wav_file.name)
    try:
        sf.write(wav_path, processed, sample_rate, subtype="PCM_24")
        subprocess.run(
            [
                "ffmpeg",
                "-y",
                "-v",
                "error",
                "-i",
                str(wav_path),
                "-codec:a",
                "libmp3lame",
                "-q:a",
                "2",
                str(args.output),
            ],
            check=True,
        )
    finally:
        wav_path.unlink(missing_ok=True)

    duration = len(processed) / sample_rate
    peak_db = 20 * np.log10(max(float(np.max(np.abs(processed))), 1e-12))
    rms_db = 20 * np.log10(max(float(np.sqrt(np.mean(processed**2))), 1e-12))
    print(f"Created {args.output}")
    print(f"Duration: {duration:.3f} s | Peak: {peak_db:.2f} dBFS | RMS: {rms_db:.2f} dBFS")


if __name__ == "__main__":
    main()
