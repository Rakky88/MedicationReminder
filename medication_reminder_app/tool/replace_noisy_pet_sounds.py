"""Replace pet-sound variants whose animal-to-background ratio is poor.

The two clean CC0 source previews and their licences are documented in
``assets/sounds/ATTRIBUTION.md``. Keep the downloaded originals under
``.source_audio/cc0``; that maintenance directory is intentionally not part of
the APK or Git repository.
"""

from __future__ import annotations

import hashlib
import shutil
import subprocess
from pathlib import Path

import imageio_ffmpeg


ROOT = Path(__file__).resolve().parents[1]
SOUNDS = ROOT / "assets" / "sounds"
ANDROID_RAW = ROOT / "android" / "app" / "src" / "main" / "res" / "raw"
SOURCES = ROOT / ".source_audio" / "cc0"
FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()

SOURCE_HASHES = {
    "chicken_crow_clean_cabled_mess.mp3":
        "01dec6c4c9fc699b2400cb77feec096a6f4238fe3db0a45ab923a008b377f320",
    "chicken_cluck_clean_jhennaside.mp3":
        "ef894c32913dd23641442ab001465609f4a78c50ff4717af6a1fd93856ee68d9",
}


def _verify_source(name: str) -> Path:
    path = SOURCES / name
    if not path.is_file():
        raise FileNotFoundError(f"Missing maintenance source: {path}")
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if digest != SOURCE_HASHES[name]:
        raise RuntimeError(f"Unexpected source checksum for {name}: {digest}")
    return path


def _render(
    source: Path,
    target: Path,
    *,
    filters: str,
    start: float | None = None,
    duration: float | None = None,
) -> None:
    command = [FFMPEG, "-hide_banner", "-loglevel", "error", "-y"]
    if start is not None:
        command.extend(("-ss", f"{start:.3f}"))
    if duration is not None:
        command.extend(("-t", f"{duration:.3f}"))
    command.extend(
        (
            "-i",
            str(source),
            "-af",
            filters,
            "-ar",
            "32000",
            "-ac",
            "1",
            "-c:a",
            "libmp3lame",
            "-b:a",
            "96k",
            str(target),
        )
    )
    subprocess.run(command, check=True)


def _pitch_filter(factor: float) -> str:
    return (
        "aresample=32000,"
        f"asetrate={32000 * factor:.3f},aresample=32000,"
        f"atempo={1 / factor:.6f}"
    )


def _replace_noisy_dog_pants() -> None:
    # These passages had less than 20 dB separation between the pant and the
    # room tone (three were below 5 dB). Rebuild them from the five clean real-
    # dog passages, which all have at least 20 dB separation.
    clean_sources = {
        2: 1,
        3: 5,
        4: 7,
        6: 9,
        8: 11,
        10: 1,
        12: 5,
        13: 7,
        14: 9,
        15: 11,
        16: 1,
        17: 5,
        18: 7,
        19: 9,
        20: 11,
    }
    pitch_factors = tuple(0.965 + index * 0.0035 for index in range(20))
    for target_index, source_index in clean_sources.items():
        factor = pitch_factors[(target_index - 1) % len(pitch_factors)]
        _render(
            SOUNDS / f"dog_pant_{source_index:02}.mp3",
            SOUNDS / f"dog_pant_{target_index:02}.mp3",
            filters=(
                f"{_pitch_filter(factor)},"
                "highpass=f=85,lowpass=f=9000,afftdn=nf=-45,"
                "loudnorm=I=-18:TP=-1.5:LRA=7,"
                "afade=t=in:st=0:d=0.04,afade=t=out:st=3.95:d=0.25"
            ),
            duration=4.2,
        )


def _replace_chicken_clucks(source: Path) -> None:
    factors = (0.958, 0.972, 0.985, 0.997, 1.011, 1.026, 1.041)
    for index in range(1, 21):
        factor = factors[(index - 1) % len(factors)]
        start = ((index - 1) % 6) * 0.16
        _render(
            source,
            SOUNDS / f"chicken_cluck_{index:02}.mp3",
            filters=(
                f"{_pitch_filter(factor)},highpass=f=95,lowpass=f=9500,"
                "afftdn=nf=-50,loudnorm=I=-18:TP=-1.5:LRA=8,"
                "afade=t=in:st=0:d=0.025,afade=t=out:st=3.32:d=0.28"
            ),
            start=start,
            duration=3.6,
        )


def _replace_noisy_chicken_crows(source: Path) -> None:
    # Variants 1-7 are already isolated and clean. The remaining source
    # recordings had clearly audible farm/room ambience between calls.
    factors = tuple(0.94 + index * 0.01 for index in range(13))
    for index in range(8, 21):
        factor = factors[(index - 8) % len(factors)]
        target = SOUNDS / f"chicken_crow_{index:02}.mp3"
        _render(
            source,
            target,
            filters=(
                f"{_pitch_filter(factor)},highpass=f=90,lowpass=f=10500,"
                "afftdn=nf=-52,loudnorm=I=-16:TP=-1.5:LRA=7,"
                "afade=t=in:st=0:d=0.02,afade=t=out:st=2.20:d=0.24,"
                "apad=pad_dur=0.25"
            ),
        )
        shutil.copyfile(target, ANDROID_RAW / target.name)


def _decode_check(path: Path) -> None:
    subprocess.run(
        [
            FFMPEG,
            "-hide_banner",
            "-loglevel",
            "error",
            "-i",
            str(path),
            "-f",
            "null",
            "-",
        ],
        check=True,
        stdout=subprocess.DEVNULL,
    )


def main() -> None:
    cluck = _verify_source("chicken_cluck_clean_jhennaside.mp3")
    crow = _verify_source("chicken_crow_clean_cabled_mess.mp3")
    _replace_noisy_dog_pants()
    _replace_chicken_clucks(cluck)
    _replace_noisy_chicken_crows(crow)

    changed = [
        *(
            SOUNDS / f"dog_pant_{index:02}.mp3"
            for index in (2, 3, 4, 6, 8, 10, 12, 13, 14, 15, 16, 17, 18, 19, 20)
        ),
        *(SOUNDS / f"chicken_cluck_{index:02}.mp3" for index in range(1, 21)),
        *(SOUNDS / f"chicken_crow_{index:02}.mp3" for index in range(8, 21)),
    ]
    for path in changed:
        _decode_check(path)
    print(f"Replaced and decoded {len(changed)} noisy pet-sound variants.")


if __name__ == "__main__":
    main()
