"""Build 20 meows and 20 purrs from attributed real-cat recordings.

Install ``imageio-ffmpeg`` before running this maintenance script. The source
recordings and their licences are documented in assets/sounds/ATTRIBUTION.md.
No synthetic oscillator sounds are used: meows are separate vocalisations and
purrs are different passages from two continuous real purr recordings.
"""

from __future__ import annotations

import argparse
import json
import math
import shutil
import struct
import subprocess
import wave
from pathlib import Path

import imageio_ffmpeg


ROOT = Path(__file__).resolve().parents[1]
SOURCE_AUDIO = ROOT / ".source_audio" / "cc0"
ASSET_OUTPUT = ROOT / "assets" / "sounds"
ANDROID_OUTPUT = ROOT / "android" / "app" / "src" / "main" / "res" / "raw"
FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
PURR_TARGET_LUFS = -20.0
PURR_TRUE_PEAK_DBTP = -1.5
PURR_LRA = 3.0

# Eighteen isolated vocalisations in the CC0 "Kitten meows" recording. The
# remaining two files use the other two CC0 real-cat recordings in full.
MEOW_SEGMENTS = (
    (0.42, 1.67),
    (2.04, 2.63),
    (3.85, 4.43),
    (4.90, 5.40),
    (6.00, 6.54),
    (7.91, 8.54),
    (9.10, 10.52),
    (11.01, 11.80),
    (12.39, 12.94),
    (13.43, 14.14),
    (14.86, 15.43),
    (16.00, 16.51),
    (17.01, 17.84),
    (18.36, 18.96),
    (20.18, 21.03),
    (25.69, 26.31),
    (27.00, 27.59),
    (28.83, 29.50),
)


def _measure_loudness(
    source: Path,
    *,
    start: float | None = None,
    duration: float | None = None,
    prefilters: str | None = None,
) -> dict[str, str]:
    command = [FFMPEG, "-hide_banner", "-nostats"]
    if start is not None:
        command.extend(("-ss", f"{start:.3f}"))
    if duration is not None:
        command.extend(("-t", f"{duration:.3f}"))
    filters = (
        f"loudnorm=I={PURR_TARGET_LUFS}:TP={PURR_TRUE_PEAK_DBTP}:"
        f"LRA={PURR_LRA}:print_format=json"
    )
    if prefilters:
        filters = f"{prefilters},{filters}"
    command.extend(("-i", str(source), "-af", filters, "-f", "null", "-"))
    result = subprocess.run(command, check=True, capture_output=True, text=True)
    payload_start = result.stderr.rfind("{")
    payload_end = result.stderr.rfind("}")
    if payload_start < 0 or payload_end <= payload_start:
        raise RuntimeError(f"Could not read loudness measurement for {source}")
    return json.loads(result.stderr[payload_start : payload_end + 1])


def _loudnorm_filter(measured: dict[str, str]) -> str:
    return (
        f"loudnorm=I={PURR_TARGET_LUFS}:TP={PURR_TRUE_PEAK_DBTP}:"
        f"LRA={PURR_LRA}:measured_I={measured['input_i']}:"
        f"measured_TP={measured['input_tp']}:"
        f"measured_LRA={measured['input_lra']}:"
        f"measured_thresh={measured['input_thresh']}:"
        f"offset={measured['target_offset']}:linear=true"
    )


def _convert(source: Path, target: Path, start: float, duration: float, kind: str) -> None:
    fade_out_start = max(0.05, duration - (0.10 if kind == "meow" else 0.28))
    if kind == "purr":
        prefilters = (
            "highpass=f=70,lowpass=f=8000,"
            "acompressor=threshold=0.06:ratio=6:attack=10:release=500:makeup=1,"
            "afade=t=in:st=0:d=0.16,"
            f"afade=t=out:st={fade_out_start:.3f}:d=0.28"
        )
        measured = _measure_loudness(
            source,
            start=start,
            duration=duration,
            prefilters=prefilters,
        )
        filters = f"{prefilters},{_loudnorm_filter(measured)}"
    else:
        filters = (
            "loudnorm=I=-14:TP=-1.5:LRA=9,"
            "afade=t=in:st=0:d=0.02,"
            f"afade=t=out:st={fade_out_start:.3f}:d=0.10"
        )
    subprocess.run(
        [
            FFMPEG,
            "-hide_banner",
            "-loglevel",
            "error",
            "-y",
            "-ss",
            f"{start:.3f}",
            "-t",
            f"{duration:.3f}",
            "-i",
            str(source),
            "-af",
            filters,
            "-ar",
            "32000",
            "-ac",
            "1",
            "-c:a",
            "pcm_s16le",
            str(target),
        ],
        check=True,
    )


def _normalize_finished_purr(path: Path) -> None:
    # A second measured pass on the decoded WAV removes source-codec and
    # segment-seeking differences. It also gives every final asset the same
    # perceived level without making short peaks harsh.
    prefilters = (
        "highpass=f=70,lowpass=f=8000,"
        "acompressor=threshold=0.06:ratio=6:attack=10:release=500:makeup=1"
    )
    measured = _measure_loudness(path, prefilters=prefilters)
    temporary = path.with_name(f".{path.stem}.normalized.wav")
    subprocess.run(
        [
            FFMPEG,
            "-hide_banner",
            "-loglevel",
            "error",
            "-y",
            "-i",
            str(path),
            "-af",
            f"{prefilters},{_loudnorm_filter(measured)}",
            "-ar",
            "32000",
            "-ac",
            "1",
            "-c:a",
            "pcm_s16le",
            str(temporary),
        ],
        check=True,
    )
    temporary.replace(path)


def _validate(path: Path, minimum_seconds: float) -> None:
    with wave.open(str(path), "rb") as source:
        if source.getnchannels() != 1 or source.getsampwidth() != 2:
            raise RuntimeError(f"Unexpected WAV layout: {path}")
        duration = source.getnframes() / source.getframerate()
        samples = struct.unpack(f"<{source.getnframes()}h", source.readframes(source.getnframes()))
    rms = math.sqrt(sum(value * value for value in samples) / max(1, len(samples)))
    if duration < minimum_seconds or rms < 350:
        raise RuntimeError(f"Invalid or inaudible output: {path} ({duration:.2f}s, RMS {rms:.0f})")


def _generate_meows() -> None:
    compilation = SOURCE_AUDIO / "cat_meow_2.mp3"
    meow_sources = (
        *((compilation, start, end - start) for start, end in MEOW_SEGMENTS),
        (SOURCE_AUDIO / "cat_meow_1.mp3", 0.0, 1.55),
        (SOURCE_AUDIO / "cat_meow_3.mp3", 0.0, 2.95),
    )
    for index, (source, start, duration) in enumerate(meow_sources, 1):
        target = ASSET_OUTPUT / f"cat_meow_{index:02}.wav"
        _convert(source, target, start, duration, "meow")
        _validate(target, 0.35)
        shutil.copyfile(target, ANDROID_OUTPUT / target.name)


def _generate_purrs() -> None:
    purr_sources = (
        *((SOURCE_AUDIO / "cat_purr_2.mp3", index * 1.15, 4.5) for index in range(12)),
        *((SOURCE_AUDIO / "cat_purr_3.mp3", index, 4.5) for index in range(8)),
    )
    for index, (source, start, duration) in enumerate(purr_sources, 1):
        target = ASSET_OUTPUT / f"cat_purr_{index:02}.wav"
        _convert(source, target, start, duration, "purr")
        _normalize_finished_purr(target)
        _validate(target, 4.0)

    loudness = [
        float(_measure_loudness(ASSET_OUTPUT / f"cat_purr_{index:02}.wav")["input_i"])
        for index in range(1, 21)
    ]
    if max(loudness) - min(loudness) > 0.5:
        raise RuntimeError(
            "Purr loudness differs by more than 0.5 LU: "
            f"{min(loudness):.1f} to {max(loudness):.1f} LUFS"
        )
    if any(abs(level - PURR_TARGET_LUFS) > 0.5 for level in loudness):
        raise RuntimeError(f"Purr loudness misses {PURR_TARGET_LUFS:.1f} LUFS: {loudness}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--purr-only",
        action="store_true",
        help="Regenerate only the twenty volume-matched purr passages.",
    )
    args = parser.parse_args()
    ASSET_OUTPUT.mkdir(parents=True, exist_ok=True)
    ANDROID_OUTPUT.mkdir(parents=True, exist_ok=True)

    if not args.purr_only:
        _generate_meows()
    _generate_purrs()

    scope = "20 real purr passages" if args.purr_only else "20 real meows and 20 real purr passages"
    print(f"Created and validated {scope}.")


if __name__ == "__main__":
    main()
