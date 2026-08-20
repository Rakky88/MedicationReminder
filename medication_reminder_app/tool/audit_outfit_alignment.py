"""Create deterministic QA material for every dressed-pet landmark.

The output deliberately ignores emulator selections. It compares every full
outfit sprite with the naked adult landmark that its fitted headwear and bow
tie were approved against.
"""

from __future__ import annotations

import csv
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont, ImageOps, ImageStat

from normalize_pet_assets import (
    ADULT_PETS,
    DRESSED_GRIDS,
    OUTPUT,
    PET_HEAD_CENTER_X,
    PET_HEAD_FITS,
    PET_NECK_FITS,
    ROOT,
)


def load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    try:
        return ImageFont.truetype("arial.ttf", size)
    except OSError:
        return ImageFont.load_default()


def visible_bounds(image: Image.Image) -> tuple[int, int, int, int]:
    bounds = image.getchannel("A").point(lambda value: 255 if value > 8 else 0).getbbox()
    if bounds is None:
        raise RuntimeError("Sprite contains no visible pixels")
    return bounds


def sprite_path(prefix: str, outfit_id: str | None) -> Path:
    if outfit_id is None:
        return OUTPUT / f"{prefix}_adult.png"
    return OUTPUT / "fitted" / f"{prefix}_{outfit_id}.png"


FACE_HALF_WIDTH = {
    "cat_orange": 76,
    "cat_tuxedo": 76,
    "cat_gray": 76,
    "cat_calico": 76,
    "cat_black_bib": 76,
    "dog_golden": 84,
    "dog_beagle": 96,
    "dog_black_lab": 88,
    "dog_border_collie": 88,
    "dog_dachshund": 102,
    "chicken_hen": 64,
}


def normalized_face_patch(
    image: Image.Image,
    *,
    center_x: float,
    center_y: float,
    half_width: float,
    half_height: float,
) -> tuple[Image.Image, Image.Image]:
    crop = image.crop(
        (
            round(center_x - half_width),
            round(center_y - half_height),
            round(center_x + half_width),
            round(center_y + half_height),
        )
    )
    background = Image.new("RGBA", crop.size, (238, 244, 242, 255))
    background.alpha_composite(crop)
    crop.close()
    gray = ImageOps.autocontrast(
        ImageOps.grayscale(background.resize((48, 48), Image.Resampling.LANCZOS)),
        cutoff=1,
    )
    background.close()
    edges = gray.filter(ImageFilter.FIND_EDGES)
    return gray, edges


def face_patch_score(
    reference: tuple[Image.Image, Image.Image],
    candidate: tuple[Image.Image, Image.Image],
) -> float:
    gray_difference = ImageChops.difference(reference[0], candidate[0])
    edge_difference = ImageChops.difference(reference[1], candidate[1])
    gray_score = ImageStat.Stat(gray_difference).rms[0]
    edge_score = ImageStat.Stat(edge_difference).rms[0]
    gray_difference.close()
    edge_difference.close()
    candidate[0].close()
    candidate[1].close()
    return gray_score + edge_score * 0.85


def register_face(
    prefix: str,
    reference_image: Image.Image,
    candidate_image: Image.Image,
) -> tuple[float, float, float, float]:
    base_x = PET_HEAD_CENTER_X[prefix]
    base_eye_y = PET_HEAD_FITS[prefix][5]
    base_y = base_eye_y + 18
    half_width = FACE_HALF_WIDTH[prefix]
    half_height = 58
    reference = normalized_face_patch(
        reference_image,
        center_x=base_x,
        center_y=base_y,
        half_width=half_width,
        half_height=half_height,
    )

    best: tuple[float, float, float, float] | None = None
    # The outfit pipeline centres the complete silhouette, so its head is
    # normally near the canvas centre even when the naked pet's tail shifts it.
    for scale in (0.82, 0.88, 0.94, 1.00, 1.06, 1.12, 1.18):
        for center_x in range(222, 291, 4):
            for center_y in range(round(base_y - 34), round(base_y + 35), 4):
                candidate = normalized_face_patch(
                    candidate_image,
                    center_x=center_x,
                    center_y=center_y,
                    half_width=half_width * scale,
                    half_height=half_height * scale,
                )
                score = face_patch_score(reference, candidate)
                if best is None or score < best[0]:
                    best = (score, center_x, center_y, scale)

    assert best is not None
    _, coarse_x, coarse_y, coarse_scale = best
    for scale_step in range(-3, 4):
        scale = coarse_scale + scale_step * 0.015
        for center_x in range(round(coarse_x - 4), round(coarse_x + 5)):
            for center_y in range(round(coarse_y - 4), round(coarse_y + 5)):
                candidate = normalized_face_patch(
                    candidate_image,
                    center_x=center_x,
                    center_y=center_y,
                    half_width=half_width * scale,
                    half_height=half_height * scale,
                )
                score = face_patch_score(reference, candidate)
                if score < best[0]:
                    best = (score, center_x, center_y, scale)

    reference[0].close()
    reference[1].close()
    score, center_x, center_y, scale = best
    return center_x, center_y, scale, score


def measure_face_registrations(
    output_directory: Path,
) -> dict[tuple[str, str], tuple[float, float, float, float]]:
    registrations: dict[tuple[str, str], tuple[float, float, float, float]] = {}
    report = output_directory / "face_registrations.tsv"
    with report.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t")
        writer.writerow(("pet", "outfit", "face_x", "face_y", "scale", "score"))
        for prefix in ADULT_PETS:
            with Image.open(sprite_path(prefix, None)).convert("RGBA") as reference:
                for outfit_id in DRESSED_GRIDS:
                    with Image.open(sprite_path(prefix, outfit_id)).convert(
                        "RGBA"
                    ) as candidate:
                        result = register_face(prefix, reference, candidate)
                    registrations[(prefix, outfit_id)] = result
                    writer.writerow(
                        (
                            prefix,
                            outfit_id,
                            f"{result[0]:.1f}",
                            f"{result[1]:.1f}",
                            f"{result[2]:.3f}",
                            f"{result[3]:.2f}",
                        )
                    )
    return registrations


def write_bounds_report(output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t")
        writer.writerow(
            (
                "pet",
                "outfit",
                "left",
                "top",
                "right",
                "bottom",
                "width",
                "height",
                "center_x",
                "horizontal_margin",
            )
        )
        for prefix in ADULT_PETS:
            for outfit_id in (None, *DRESSED_GRIDS):
                with Image.open(sprite_path(prefix, outfit_id)).convert("RGBA") as image:
                    left, top, right, bottom = visible_bounds(image)
                writer.writerow(
                    (
                        prefix,
                        outfit_id or "naked",
                        left,
                        top,
                        right - 1,
                        bottom - 1,
                        right - left,
                        bottom - top,
                        f"{(left + right - 1) / 2:.1f}",
                        min(left, 512 - right),
                    )
                )


def render_landmark_sheets(
    output_directory: Path,
    registrations: dict[tuple[str, str], tuple[float, float, float, float]],
) -> list[Path]:
    output_directory.mkdir(parents=True, exist_ok=True)
    states = (None, *DRESSED_GRIDS)
    columns = 4
    cell_size = 360
    sprite_size = 320
    header_height = 42
    title_font = load_font(21)
    label_font = load_font(15)
    outputs: list[Path] = []

    for prefix in ADULT_PETS:
        rows = (len(states) + columns - 1) // columns
        sheet = Image.new(
            "RGBA",
            (columns * cell_size, rows * (cell_size + header_height)),
            (238, 244, 242, 255),
        )
        draw = ImageDraw.Draw(sheet)
        head_x = PET_HEAD_CENTER_X[prefix]
        hat_y = PET_HEAD_FITS[prefix][2]
        eye_y = PET_HEAD_FITS[prefix][5]
        neck_x = PET_NECK_FITS[prefix][2]
        neck_y = PET_NECK_FITS[prefix][3]

        for index, outfit_id in enumerate(states):
            row, column = divmod(index, columns)
            origin_x = column * cell_size
            origin_y = row * (cell_size + header_height)
            with Image.open(sprite_path(prefix, outfit_id)).convert("RGBA") as source:
                sprite = source.resize((sprite_size, sprite_size), Image.Resampling.LANCZOS)
            sprite_x = origin_x + (cell_size - sprite_size) // 2
            sheet.alpha_composite(sprite, (sprite_x, origin_y))
            sprite.close()

            scale = sprite_size / 512
            guide_x = sprite_x + round(head_x * scale)
            neck_guide_x = sprite_x + round(neck_x * scale)
            draw.line(
                (guide_x, origin_y, guide_x, origin_y + round(250 * scale)),
                fill=(198, 40, 40, 210),
                width=2,
            )
            draw.line(
                (
                    sprite_x,
                    origin_y + round(hat_y * scale),
                    sprite_x + sprite_size,
                    origin_y + round(hat_y * scale),
                ),
                fill=(245, 124, 0, 210),
                width=2,
            )
            draw.line(
                (
                    sprite_x,
                    origin_y + round(eye_y * scale),
                    sprite_x + sprite_size,
                    origin_y + round(eye_y * scale),
                ),
                fill=(21, 101, 192, 210),
                width=2,
            )
            draw.ellipse(
                (
                    neck_guide_x - 4,
                    origin_y + round(neck_y * scale) - 4,
                    neck_guide_x + 4,
                    origin_y + round(neck_y * scale) + 4,
                ),
                fill=(123, 31, 162, 230),
            )
            if outfit_id is not None:
                face_x, face_y, face_scale, _ = registrations[(prefix, outfit_id)]
                registered_eye_y = face_y - 18 * face_scale
                registered_neck_x = face_x + (neck_x - head_x) * face_scale
                registered_neck_y = face_y + (
                    neck_y - (eye_y + 18)
                ) * face_scale
                detected_x = sprite_x + round(face_x * scale)
                detected_eye_y = origin_y + round(registered_eye_y * scale)
                detected_neck_x = sprite_x + round(registered_neck_x * scale)
                detected_neck_y = origin_y + round(registered_neck_y * scale)
                draw.line(
                    (
                        detected_x - 9,
                        detected_eye_y,
                        detected_x + 9,
                        detected_eye_y,
                    ),
                    fill=(0, 137, 123, 255),
                    width=3,
                )
                draw.line(
                    (
                        detected_x,
                        detected_eye_y - 9,
                        detected_x,
                        detected_eye_y + 9,
                    ),
                    fill=(0, 137, 123, 255),
                    width=3,
                )
                draw.ellipse(
                    (
                        detected_neck_x - 5,
                        detected_neck_y - 5,
                        detected_neck_x + 5,
                        detected_neck_y + 5,
                    ),
                    outline=(0, 137, 123, 255),
                    width=3,
                )
            label = outfit_id or "naked reference"
            draw.text(
                (origin_x + 8, origin_y + sprite_size + 8),
                label,
                fill=(24, 45, 43, 255),
                font=label_font,
            )

        draw.rectangle((0, 0, 350, 34), fill=(238, 244, 242, 230))
        draw.text((8, 5), prefix, fill=(24, 45, 43, 255), font=title_font)
        output = output_directory / f"{prefix}.png"
        sheet.save(output, optimize=True)
        sheet.close()
        outputs.append(output)
    return outputs


def main() -> None:
    output_directory = ROOT / "tmp" / "outfit_landmark_audit"
    output_directory.mkdir(parents=True, exist_ok=True)
    write_bounds_report(output_directory / "bounds.tsv")
    registrations = measure_face_registrations(output_directory)
    for output in render_landmark_sheets(output_directory, registrations):
        print(output.relative_to(ROOT))
    print((output_directory / "bounds.tsv").relative_to(ROOT))
    print((output_directory / "face_registrations.tsv").relative_to(ROOT))


if __name__ == "__main__":
    main()
