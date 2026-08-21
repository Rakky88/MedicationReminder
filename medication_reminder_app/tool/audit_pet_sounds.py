"""Audit every bundled pet sound and build ordered listening montages.

Run with the temporary maintenance environment used by the project::

    python tool/audit_pet_sounds.py

The script needs ``imageio-ffmpeg`` and ``numpy``. Generated reports and
montages live under ``tmp/pet_sound_audit`` and are intentionally gitignored.
"""

from __future__ import annotations

import csv
import hashlib
import math
import subprocess
import wave
from pathlib import Path

import imageio_ffmpeg
import numpy as np


ROOT = Path(__file__).resolve().parents[1]
SOUND_DIR = ROOT / "assets" / "sounds"
OUTPUT_DIR = ROOT / "tmp" / "pet_sound_audit"
FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
SAMPLE_RATE = 32_000

SOUND_SETS = (
    "cat_meow",
    "cat_purr",
    "dog_bark",
    "dog_pant",
    "chicken_crow",
    "chicken_cluck",
)

# Purring is intentionally continuous, so silence-to-sound separation is not a
# meaningful cleanliness signal for that set. The other limits protect the
# reviewed baseline from accidentally reintroducing obvious background noise.
MIN_QUIET_TO_ACTIVE_SEPARATION_DB = {
    "cat_meow": 20.0,
    "dog_bark": 40.0,
    "dog_pant": 20.0,
    "chicken_crow": 35.0,
    "chicken_cluck": 35.0,
}


def _decode(path: Path) -> np.ndarray:
    result = subprocess.run(
        [
            FFMPEG,
            "-hide_banner",
            "-loglevel",
            "error",
            "-i",
            str(path),
            "-f",
            "s16le",
            "-acodec",
            "pcm_s16le",
            "-ar",
            str(SAMPLE_RATE),
            "-ac",
            "1",
            "pipe:1",
        ],
        check=True,
        capture_output=True,
    )
    return np.frombuffer(result.stdout, dtype="<i2").astype(np.float64) / 32768.0


def _dbfs(value: float) -> float:
    return 20.0 * math.log10(max(value, 1e-9))


def _metrics(samples: np.ndarray) -> dict[str, float]:
    frame_length = max(1, round(SAMPLE_RATE * 0.02))
    usable = samples[: len(samples) - (len(samples) % frame_length)]
    frames = usable.reshape(-1, frame_length) if len(usable) else samples.reshape(1, -1)
    frame_rms = np.sqrt(np.mean(np.square(frames), axis=1))
    active_threshold = max(10 ** (-45 / 20), float(np.percentile(frame_rms, 65)) * 0.18)
    active = frame_rms[frame_rms >= active_threshold]
    quiet = frame_rms[frame_rms < active_threshold]
    active_rms = float(np.median(active)) if len(active) else float(np.mean(frame_rms))
    quiet_rms = float(np.median(quiet)) if len(quiet) else float(np.percentile(frame_rms, 10))
    return {
        "duration_seconds": len(samples) / SAMPLE_RATE,
        "rms_dbfs": _dbfs(float(np.sqrt(np.mean(np.square(samples))))),
        "peak_dbfs": _dbfs(float(np.max(np.abs(samples)))),
        "quiet_dbfs": _dbfs(quiet_rms),
        "active_dbfs": _dbfs(active_rms),
        "quiet_to_active_db": _dbfs(quiet_rms) - _dbfs(active_rms),
        "active_percent": 100.0 * len(active) / max(1, len(frame_rms)),
        "clipped_percent": 100.0 * float(np.mean(np.abs(samples) >= 0.999)),
    }


def _write_wav(path: Path, samples: np.ndarray) -> None:
    encoded = np.clip(samples * 32767.0, -32768, 32767).astype("<i2")
    with wave.open(str(path), "wb") as target:
        target.setnchannels(1)
        target.setsampwidth(2)
        target.setframerate(SAMPLE_RATE)
        target.writeframes(encoded.tobytes())


def _encode_review_mp3(source: Path, target: Path) -> None:
    subprocess.run(
        [
            FFMPEG,
            "-hide_banner",
            "-loglevel",
            "error",
            "-y",
            "-i",
            str(source),
            "-c:a",
            "libmp3lame",
            "-b:a",
            "96k",
            str(target),
        ],
        check=True,
    )


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    rows: list[dict[str, str | float]] = []
    silence = np.zeros(round(SAMPLE_RATE * 0.45), dtype=np.float64)

    for stem in SOUND_SETS:
        paths = sorted(SOUND_DIR.glob(f"{stem}_*.*"))
        if len(paths) != 20:
            raise RuntimeError(f"Expected 20 {stem} variants, found {len(paths)}")
        hashes = {hashlib.sha256(path.read_bytes()).hexdigest() for path in paths}
        if len(hashes) != 20:
            raise RuntimeError(f"Expected 20 unique {stem} variants, found {len(hashes)}")
        montage: list[np.ndarray] = []
        for index, path in enumerate(paths, 1):
            samples = _decode(path)
            metrics = _metrics(samples)
            minimum = MIN_QUIET_TO_ACTIVE_SEPARATION_DB.get(stem)
            separation = -metrics["quiet_to_active_db"]
            if minimum is not None and separation < minimum:
                raise RuntimeError(
                    f"{path.name} has only {separation:.1f} dB quiet-to-active "
                    f"separation; expected at least {minimum:.1f} dB"
                )
            rows.append({"set": stem, "index": index, "file": path.name, **metrics})
            montage.extend((samples, silence))

        review_wav = OUTPUT_DIR / f"{stem}_review.wav"
        review_mp3 = OUTPUT_DIR / f"{stem}_review.mp3"
        _write_wav(review_wav, np.concatenate(montage))
        _encode_review_mp3(review_wav, review_mp3)
        review_wav.unlink()

    report = OUTPUT_DIR / "pet_sound_metrics.tsv"
    with report.open("w", encoding="utf-8", newline="") as target:
        writer = csv.DictWriter(target, fieldnames=rows[0].keys(), delimiter="\t")
        writer.writeheader()
        writer.writerows(rows)

    print(f"Audited {len(rows)} sounds. Report: {report}")


if __name__ == "__main__":
    main()
