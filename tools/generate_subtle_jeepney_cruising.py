"""Create a natural, restrained interior jeepney cruising loop."""

from __future__ import annotations

from pathlib import Path
import subprocess

import numpy as np
import soundfile as sf
from scipy.signal import butter, resample_poly, sosfiltfilt


ROOT = Path(__file__).resolve().parents[1]
AUDIO = ROOT / "audio"
OUTPUT = AUDIO / "retro_filipino_pack" / "jeepney_cruising_subtle_loop.ogg"
SAMPLE_RATE = 48_000
DURATION = 18.0
RNG = np.random.default_rng(20260721)


def read_stereo(path: Path) -> np.ndarray:
    audio, sample_rate = sf.read(path, dtype="float32", always_2d=True)
    if audio.shape[1] == 1:
        audio = np.repeat(audio, 2, axis=1)
    if sample_rate != SAMPLE_RATE:
        divisor = int(np.gcd(sample_rate, SAMPLE_RATE))
        audio = resample_poly(
            audio,
            SAMPLE_RATE // divisor,
            sample_rate // divisor,
            axis=0,
        )
    return audio[:, :2].astype(np.float32)


def band_filter(audio: np.ndarray, low: float, high: float) -> np.ndarray:
    high_pass = butter(2, low, btype="highpass", fs=SAMPLE_RATE, output="sos")
    low_pass = butter(3, high, btype="lowpass", fs=SAMPLE_RATE, output="sos")
    audio = sosfiltfilt(high_pass, audio, axis=0)
    return sosfiltfilt(low_pass, audio, axis=0).astype(np.float32)


def seamless_segment(
    source: np.ndarray,
    start_seconds: float,
    crossfade_seconds: float = 2.5,
) -> np.ndarray:
    length = int(DURATION * SAMPLE_RATE)
    fade_length = int(crossfade_seconds * SAMPLE_RATE)
    start = int(start_seconds * SAMPLE_RATE)
    extended = source[start : start + length + fade_length]
    if len(extended) < length + fade_length:
        repeats = int(np.ceil((length + fade_length) / len(source))) + 1
        extended = np.tile(source, (repeats, 1))[: length + fade_length]
    loop = extended[:length].copy()
    curve = np.sin(np.linspace(0.0, np.pi / 2.0, fade_length)) ** 2
    loop[:fade_length] = (
        extended[length:] * (1.0 - curve[:, None])
        + loop[:fade_length] * curve[:, None]
    )
    return loop.astype(np.float32)


def set_rms(audio: np.ndarray, target_db: float) -> np.ndarray:
    rms = float(np.sqrt(np.mean(audio**2)))
    if rms <= 1e-12:
        return audio.astype(np.float32)
    return (audio * ((10.0 ** (target_db / 20.0)) / rms)).astype(np.float32)


def generate() -> np.ndarray:
    # Start with the actual recorded jeepney engine and raise its speed slightly
    # so it reads as cruising rather than another copy of the idle loop.
    engine_source = read_stereo(AUDIO / "idle jeepney sound.mp3")
    engine_source = resample_poly(engine_source, 25, 27, axis=0).astype(np.float32)
    engine_source = band_filter(engine_source, 48.0, 4_800.0)
    engine = seamless_segment(engine_source, start_seconds=12.0)

    # Keep the engine centered inside the vehicle instead of filling the stereo
    # field like music.
    mid = engine.mean(axis=1)
    side = (engine[:, 0] - engine[:, 1]) * 0.16
    engine[:, 0] = mid + side
    engine[:, 1] = mid - side
    engine = set_rms(engine, -25.0)

    road_source = read_stereo(AUDIO / "street_lapaz_ambiance.mp3")
    road_source = band_filter(road_source, 170.0, 5_200.0)
    road = seamless_segment(road_source, start_seconds=42.0)
    road = set_rms(road, -34.5)

    # A very quiet chassis texture prevents the ride from sounding stationary.
    noise = RNG.standard_normal((int((DURATION + 3.0) * SAMPLE_RATE), 2)).astype(np.float32)
    noise = band_filter(noise, 520.0, 3_800.0)
    chassis = seamless_segment(noise, start_seconds=0.0, crossfade_seconds=3.0)
    time = np.arange(len(chassis), dtype=np.float32) / SAMPLE_RATE
    vibration = 0.34 + 0.66 * np.sin(2.0 * np.pi * 7.0 * time) ** 10
    chassis *= vibration[:, None]
    chassis = set_rms(chassis, -39.0)

    cruise = engine + road + chassis
    cruise *= (
        0.96 + 0.04 * np.sin(2.0 * np.pi * (3.0 / DURATION) * time + 0.3)
    )[:, None]
    cruise -= np.mean(cruise, axis=0, keepdims=True)
    cruise = np.tanh(cruise * 1.25) / np.tanh(1.25)
    cruise = set_rms(cruise, -24.0)

    peak_target = 10.0 ** (-8.0 / 20.0)
    peak = float(np.max(np.abs(cruise)))
    if peak > peak_target:
        cruise *= peak_target / peak
    return cruise.astype(np.float32)


def main() -> None:
    audio = generate()
    temporary_wav = OUTPUT.with_name(f".{OUTPUT.stem}.render.wav")
    sf.write(temporary_wav, audio, SAMPLE_RATE, subtype="PCM_24")
    try:
        subprocess.run(
            [
                "ffmpeg",
                "-loglevel",
                "error",
                "-y",
                "-i",
                str(temporary_wav),
                "-codec:a",
                "libvorbis",
                "-q:a",
                "5",
                str(OUTPUT),
            ],
            check=True,
        )
    finally:
        temporary_wav.unlink(missing_ok=True)

    rendered, sample_rate = sf.read(OUTPUT, dtype="float32", always_2d=True)
    peak_db = 20.0 * np.log10(max(float(np.max(np.abs(rendered))), 1e-12))
    rms_db = 20.0 * np.log10(max(float(np.sqrt(np.mean(rendered**2))), 1e-12))
    print(
        f"{OUTPUT.relative_to(ROOT)}: {len(rendered) / sample_rate:.1f}s, "
        f"stereo, peak {peak_db:.2f} dBFS, RMS {rms_db:.2f} dBFS"
    )


if __name__ == "__main__":
    main()
