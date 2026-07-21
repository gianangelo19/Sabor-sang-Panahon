"""Generate a soft, unobtrusive click for typewriter-style dialogue reveals."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import soundfile as sf
from scipy.signal import butter, sosfilt


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "audio" / "retro_filipino_pack" / "dialogue_type_click.wav"
SAMPLE_RATE = 48_000
RNG = np.random.default_rng(20260721)


def generate_click() -> np.ndarray:
    """Build a tiny felted mechanical tick with no reverb or stereo movement."""
    duration = 0.042
    count = int(duration * SAMPLE_RATE)
    time = np.arange(count, dtype=np.float64) / SAMPLE_RATE

    # A short band-limited noise impulse provides the physical key-tap texture.
    noise = RNG.standard_normal(count)
    noise_filter = butter(2, (620, 5_200), btype="bandpass", fs=SAMPLE_RATE, output="sos")
    noise = sosfilt(noise_filter, noise)
    noise_envelope = np.exp(-time * 245.0)

    # Quiet, inharmonic resonances make the sound readable at low volume without
    # turning it into a bright UI beep.
    resonances = (
        0.36 * np.sin(2.0 * np.pi * 920.0 * time + 0.25)
        + 0.22 * np.sin(2.0 * np.pi * 1_570.0 * time + 1.10)
        + 0.10 * np.sin(2.0 * np.pi * 2_680.0 * time + 0.65)
    ) * np.exp(-time * 190.0)

    # A very soft key-bottom contact follows the initial tap by 4.5 ms.
    second_start = int(0.0045 * SAMPLE_RATE)
    second_time = np.arange(count - second_start, dtype=np.float64) / SAMPLE_RATE
    second = np.zeros(count, dtype=np.float64)
    second[second_start:] = (
        0.12 * np.sin(2.0 * np.pi * 710.0 * second_time + 0.4)
        + 0.07 * RNG.standard_normal(len(second_time))
    ) * np.exp(-second_time * 310.0)

    click = 0.48 * noise * noise_envelope + resonances + second

    # Remove sub-bass and soften the top end so rapid repeated playback does not
    # compete with voices, ambience, or the dialogue itself.
    soft_filter = butter(2, (360, 4_600), btype="bandpass", fs=SAMPLE_RATE, output="sos")
    click = sosfilt(soft_filter, click)

    click -= np.mean(click)
    attack = int(0.00035 * SAMPLE_RATE)
    release = int(0.009 * SAMPLE_RATE)
    click[:attack] *= np.sin(np.linspace(0.0, np.pi / 2.0, attack)) ** 2
    click[-release:] *= np.cos(np.linspace(0.0, np.pi / 2.0, release)) ** 2

    target_peak = 10.0 ** (-18.5 / 20.0)
    click *= target_peak / np.max(np.abs(click))
    return click.astype(np.float32)


def main() -> None:
    click = generate_click()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    sf.write(OUTPUT, click, SAMPLE_RATE, subtype="PCM_16")

    peak_db = 20.0 * np.log10(max(float(np.max(np.abs(click))), 1e-12))
    rms_db = 20.0 * np.log10(max(float(np.sqrt(np.mean(click**2))), 1e-12))
    print(
        f"{OUTPUT.relative_to(ROOT)}: {len(click) / SAMPLE_RATE:.3f}s, mono, "
        f"{SAMPLE_RATE} Hz, peak {peak_db:.2f} dBFS, RMS {rms_db:.2f} dBFS"
    )


if __name__ == "__main__":
    main()
