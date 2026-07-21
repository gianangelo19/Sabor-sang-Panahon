"""Create seamless, subtle ambience loops for the main La Paz locations."""

from __future__ import annotations

from pathlib import Path
import subprocess

import numpy as np
import soundfile as sf
from scipy.signal import butter, resample_poly, sosfiltfilt


ROOT = Path(__file__).resolve().parents[1]
AUDIO = ROOT / "audio"
OUTPUT = AUDIO / "ambience"
SAMPLE_RATE = 48_000
LOOP_SECONDS = 60.0
RNG = np.random.default_rng(20260721)


def read_stereo(path: Path) -> np.ndarray:
    audio, sample_rate = sf.read(path, dtype="float32", always_2d=True)
    if audio.shape[1] == 1:
        audio = np.repeat(audio, 2, axis=1)
    elif audio.shape[1] > 2:
        audio = audio[:, :2]
    if sample_rate != SAMPLE_RATE:
        divisor = int(np.gcd(sample_rate, SAMPLE_RATE))
        audio = resample_poly(
            audio,
            SAMPLE_RATE // divisor,
            sample_rate // divisor,
            axis=0,
        ).astype(np.float32)
    return audio.astype(np.float32)


def seamless_segment(
    source: np.ndarray,
    duration: float = LOOP_SECONDS,
    start: float = 0.0,
    crossfade: float = 4.0,
) -> np.ndarray:
    length = int(duration * SAMPLE_RATE)
    fade_length = int(crossfade * SAMPLE_RATE)
    start_frame = int(start * SAMPLE_RATE) % len(source)
    indices = (start_frame + np.arange(length + fade_length)) % len(source)
    extended = source[indices]
    loop = extended[:length].copy()
    curve = np.sin(np.linspace(0.0, np.pi / 2.0, fade_length)) ** 2
    loop[:fade_length] = (
        extended[length:] * (1.0 - curve[:, None])
        + loop[:fade_length] * curve[:, None]
    )
    return loop.astype(np.float32)


def band_filter(audio: np.ndarray, low: float, high: float, order: int = 3) -> np.ndarray:
    high_pass = butter(2, low, btype="highpass", fs=SAMPLE_RATE, output="sos")
    low_pass = butter(order, high, btype="lowpass", fs=SAMPLE_RATE, output="sos")
    audio = sosfiltfilt(high_pass, audio, axis=0)
    return sosfiltfilt(low_pass, audio, axis=0).astype(np.float32)


def set_rms(audio: np.ndarray, target_db: float) -> np.ndarray:
    rms = float(np.sqrt(np.mean(audio**2)))
    if rms <= 1e-12:
        return audio.astype(np.float32)
    return (audio * ((10.0 ** (target_db / 20.0)) / rms)).astype(np.float32)


def finalize(audio: np.ndarray, target_rms_db: float, peak_db: float) -> np.ndarray:
    audio = audio - np.mean(audio, axis=0, keepdims=True)
    # Gentle saturation catches isolated field-recording transients without
    # flattening the slow movement that makes ambience feel alive.
    audio = np.tanh(audio * 1.35) / np.tanh(1.35)
    audio = set_rms(audio, target_rms_db)
    peak = float(np.max(np.abs(audio)))
    peak_target = 10.0 ** (peak_db / 20.0)
    if peak > peak_target:
        audio *= peak_target / peak
    return audio.astype(np.float32)


def add_vehicle_passes(audio: np.ndarray, vehicle: np.ndarray) -> None:
    mono = vehicle.mean(axis=1)
    event_seconds = 7.0
    event_length = int(event_seconds * SAMPLE_RATE)
    starts = (6.0, 21.5, 38.0, 51.0)
    for event_index, start_seconds in enumerate(starts):
        begin = int(start_seconds * SAMPLE_RATE)
        available = min(event_length, len(audio) - begin)
        if available <= 0:
            continue
        source_start = (event_index * int(2.3 * SAMPLE_RATE)) % max(1, len(mono) - available)
        event = mono[source_start : source_start + available].copy()
        envelope = np.sin(np.linspace(0.0, np.pi, available)) ** 1.8
        pan = np.linspace(-0.72, 0.72, available)
        if event_index % 2:
            pan = pan[::-1]
        left = np.sqrt((1.0 - pan) * 0.5)
        right = np.sqrt((1.0 + pan) * 0.5)
        gain = 0.040 + 0.009 * RNG.random()
        audio[begin : begin + available, 0] += event * envelope * left * gain
        audio[begin : begin + available, 1] += event * envelope * right * gain


def street_ambience() -> np.ndarray:
    street_source = read_stereo(AUDIO / "street_lapaz_ambiance.mp3")
    street_source = band_filter(street_source, 55.0, 12_000.0)
    street = seamless_segment(street_source, start=7.5)
    street = set_rms(street, -29.0)

    jeepney_source = read_stereo(AUDIO / "idle jeepney sound.mp3")
    jeepney_source = band_filter(jeepney_source, 65.0, 5_800.0)
    jeepney_idle = seamless_segment(jeepney_source, start=14.0)
    jeepney_idle = set_rms(jeepney_idle, -39.0)
    street += jeepney_idle

    cruising = read_stereo(
        AUDIO / "retro_filipino_pack" / "jeepney_cruising_subtle_loop.ogg"
    )
    cruising = band_filter(cruising, 75.0, 6_500.0)
    add_vehicle_passes(street, cruising)
    return finalize(street, -27.5, -7.5)


def market_ambience() -> np.ndarray:
    crowd_path = (
        ROOT
        / "minigames-main"
        / "snatch_battle"
        / "assets"
        / "audio"
        / "ambience"
        / "amb_meat_market_stall_loop.ogg"
    )
    crowd_source = read_stereo(crowd_path)
    crowd_source = band_filter(crowd_source, 105.0, 10_500.0)
    # Keep a few seconds of unused source at the end so the crossfade has true
    # continuation audio instead of wrapping across the source file's hard cut.
    market_duration = 54.0
    crowd = seamless_segment(
        crowd_source,
        duration=market_duration,
        start=1.0,
        crossfade=4.0,
    )
    crowd = set_rms(crowd, -27.0)

    street_source = read_stereo(AUDIO / "street_lapaz_ambiance.mp3")
    street_source = band_filter(street_source, 70.0, 3_200.0)
    street = seamless_segment(street_source, duration=market_duration, start=24.0)
    street = set_rms(street, -38.0)
    return finalize(crowd + street, -26.5, -7.0)


def grandmas_house_ambience() -> np.ndarray:
    house_source = read_stereo(AUDIO / "lapaz_home_ambiance.mp3")
    house_source = band_filter(house_source, 65.0, 8_500.0)
    house = seamless_segment(house_source, crossfade=4.5)
    house = np.sign(house) * np.abs(house) ** 0.84
    house = set_rms(house, -34.0)

    old_room_path = (
        ROOT
        / "minigames-main"
        / "box_unboxing"
        / "assets"
        / "audio"
        / "ambience"
        / "amb_old_room_loop.ogg"
    )
    room_source = read_stereo(old_room_path)
    room_source = band_filter(room_source, 45.0, 4_200.0)
    room_tone = seamless_segment(room_source, start=4.0)
    room_tone = set_rms(room_tone, -32.5)

    distant_source = read_stereo(AUDIO / "street_lapaz_ambiance.mp3")
    distant_source = band_filter(distant_source, 80.0, 1_500.0)
    distant_street = seamless_segment(distant_source, start=31.0)
    distant_street = set_rms(distant_street, -43.0)
    house_mix = house + room_tone + distant_street
    # The original house recording has a few isolated hard transients. Gentle
    # crest compression keeps those from forcing the entire room tone too low.
    house_mix = np.sign(house_mix) * np.abs(house_mix) ** 0.84
    return finalize(house_mix, -29.5, -8.5)


def apartment_ambience() -> np.ndarray:
    apartment_source = read_stereo(AUDIO / "apartment_ambiance.mp3")
    apartment_source = band_filter(apartment_source, 70.0, 7_000.0)
    apartment = seamless_segment(apartment_source, start=18.0)
    apartment = set_rms(apartment, -32.5)

    old_room_path = (
        ROOT
        / "minigames-main"
        / "box_unboxing"
        / "assets"
        / "audio"
        / "ambience"
        / "amb_old_room_loop.ogg"
    )
    room_source = read_stereo(old_room_path)
    room_source = band_filter(room_source, 55.0, 2_800.0)
    room_tone = seamless_segment(room_source, start=10.0)
    room_tone = set_rms(room_tone, -36.0)

    time = np.arange(len(apartment), dtype=np.float32) / SAMPLE_RATE
    fan = (
        np.sin(2.0 * np.pi * 93.0 * time + 0.2)
        + 0.38 * np.sin(2.0 * np.pi * 186.0 * time + 0.8)
    )
    fan *= 1.0 + 0.09 * np.sin(2.0 * np.pi * 0.10 * time)
    fan = np.column_stack((fan, fan))
    fan = set_rms(fan, -45.0)

    distant_source = read_stereo(AUDIO / "street_lapaz_ambiance.mp3")
    distant_source = band_filter(distant_source, 70.0, 1_100.0)
    distant_city = seamless_segment(distant_source, start=12.0)
    distant_city = set_rms(distant_city, -44.0)
    return finalize(apartment + room_tone + fan + distant_city, -30.5, -9.0)


def write_loop(name: str, audio: np.ndarray) -> None:
    if not np.isfinite(audio).all():
        raise ValueError(f"{name} contains invalid samples")
    path = OUTPUT / name
    temporary_wav = OUTPUT / f".{path.stem}.render.wav"
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
                str(path),
            ],
            check=True,
        )
    finally:
        temporary_wav.unlink(missing_ok=True)
    rendered, sample_rate = sf.read(path, dtype="float32", always_2d=True)
    peak_db = 20.0 * np.log10(max(float(np.max(np.abs(rendered))), 1e-12))
    rms_db = 20.0 * np.log10(max(float(np.sqrt(np.mean(rendered**2))), 1e-12))
    print(
        f"{name:36} {len(rendered) / sample_rate:5.1f}s "
        f"peak {peak_db:6.2f} dBFS RMS {rms_db:6.2f} dBFS "
        f"{path.stat().st_size / 1024:7.1f} KiB"
    )


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    generators = (
        ("la_paz_street_loop.ogg", street_ambience),
        ("la_paz_public_market_loop.ogg", market_ambience),
        ("grandmas_house_loop.ogg", grandmas_house_ambience),
        ("apartment_room_loop.ogg", apartment_ambience),
    )
    for name, generator in generators:
        write_loop(name, generator())


if __name__ == "__main__":
    main()
