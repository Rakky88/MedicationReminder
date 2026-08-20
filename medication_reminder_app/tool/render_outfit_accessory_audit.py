"""Render every tailored-outfit/accessory/pet combination for visual QA.

The script reads the exact registrations used by Flutter from
``lib/outfit_accessory_fits.dart``. It produces two independent review layouts:
one grouped by outfit and one grouped by pet. Every one of the 1,980 runtime
combinations is therefore visible twice, in addition to the landmark sheets
created by ``audit_outfit_alignment.py``.
"""

from __future__ import annotations

import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from normalize_pet_assets import ADULT_PETS, DRESSED_GRIDS, HEAD_ACCESSORIES, OUTPUT, ROOT


WEARABLES = (*HEAD_ACCESSORIES, "doctor_bow_tie")
FIT_SOURCE = ROOT / "lib" / "outfit_accessory_fits.dart"
AUDIT_OUTPUT = ROOT / "tmp" / "outfit_accessory_audit"
BACKGROUND = (238, 244, 242, 255)


def load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    try:
        return ImageFont.truetype("arial.ttf", size)
    except OSError:
        return ImageFont.load_default()


def read_runtime_fits() -> dict[tuple[str, str], tuple[float, float, float]]:
    """Parse the compact const Dart table so QA cannot drift from runtime."""
    source = FIT_SOURCE.read_text(encoding="utf-8")
    table_match = re.search(
        r"const outfitFaceFits = <String, List<OutfitFaceFit>>\{(.*?)\n\};",
        source,
        re.DOTALL,
    )
    if table_match is None:
        raise RuntimeError("Could not find outfitFaceFits in the Dart source")
    fits: dict[tuple[str, str], tuple[float, float, float]] = {}
    blocks = re.finditer(
        r"'([^']+)': \[(.*?)\n\s*\],",
        table_match.group(1),
        re.DOTALL,
    )
    for block in blocks:
        outfit_id = block.group(1)
        values = [
            tuple(float(value) for value in match)
            for match in re.findall(
                r"\((-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?),\s*(-?(?:\d+(?:\.\d+)?|\.\d+))\)",
                block.group(2),
            )
        ]
        if len(values) != len(ADULT_PETS):
            raise RuntimeError(
                f"Expected {len(ADULT_PETS)} fits for {outfit_id}, found {len(values)}"
            )
        for prefix, value in zip(ADULT_PETS, values, strict=True):
            fits[(outfit_id, prefix)] = value
    expected = len(DRESSED_GRIDS) * len(ADULT_PETS)
    if set(outfit_id for outfit_id, _ in fits) != set(DRESSED_GRIDS):
        raise RuntimeError("Runtime fit outfits do not match DRESSED_GRIDS")
    if len(fits) != expected:
        raise RuntimeError(f"Expected {expected} registrations, found {len(fits)}")
    return fits


def read_hat_top_insets() -> dict[tuple[str, str], float]:
    source = FIT_SOURCE.read_text(encoding="utf-8")
    table_match = re.search(
        r"const fittedHatTopInsets = <String, List<double>>\{(.*?)\n\};",
        source,
        re.DOTALL,
    )
    if table_match is None:
        raise RuntimeError("Could not find fittedHatTopInsets in the Dart source")
    result: dict[tuple[str, str], float] = {}
    for item_id, raw_values in re.findall(
        r"'([^']+)': \[([^\]]+)\]", table_match.group(1)
    ):
        values = [float(value) for value in re.findall(r"\d+(?:\.\d+)?", raw_values)]
        if len(values) != len(ADULT_PETS):
            raise RuntimeError(f"Unexpected top-inset count for {item_id}")
        for prefix, value in zip(ADULT_PETS, values, strict=True):
            result[(item_id, prefix)] = value
    return result


def transformed_overlay(
    overlay: Image.Image,
    fit: tuple[float, float, float],
    prefix: str,
    wearable_id: str,
    top_insets: dict[tuple[str, str], float],
) -> Image.Image:
    """Apply CatAvatar's centre-based 512px scale and translation."""
    face_x, face_y, scale = fit
    base_face = {
        "cat_orange": (248, 158),
        "cat_tuxedo": (249, 158),
        "cat_gray": (247, 158),
        "cat_calico": (247, 158),
        "cat_black_bib": (246, 158),
        "dog_golden": (271, 106),
        "dog_beagle": (260, 116),
        "dog_black_lab": (260, 110),
        "dog_border_collie": (270, 126),
        "dog_dachshund": (262, 114),
        "chicken_hen": (256, 150),
    }[prefix]
    scale_x = scale
    scale_y = scale
    base_top = top_insets.get((wearable_id, prefix))
    if base_top is not None and base_top < base_face[1]:
        scale_y = min(scale_y, (face_y - 2) / (base_face[1] - base_top))
    dx = face_x - (256 + (base_face[0] - 256) * scale_x)
    dy = face_y - (256 + (base_face[1] - 256) * scale_y)
    size = round(512 * scale_x), round(512 * scale_y)
    resized = overlay.resize(size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    canvas.alpha_composite(
        resized,
        (
            round((512 - size[0]) / 2 + dx),
            round((512 - size[1]) / 2 + dy),
        ),
    )
    resized.close()
    return canvas


def composition(
    outfit_id: str,
    wearable_id: str,
    prefix: str,
    fits: dict[tuple[str, str], tuple[float, float, float]],
    top_insets: dict[tuple[str, str], float],
) -> tuple[Image.Image, tuple[int, int, int, int] | None]:
    body_path = OUTPUT / "fitted" / f"{prefix}_{outfit_id}.png"
    overlay_path = OUTPUT / "fitted_accessories" / f"{prefix}_{wearable_id}.png"
    body = Image.open(body_path).convert("RGBA")
    with Image.open(overlay_path).convert("RGBA") as source:
        overlay = transformed_overlay(
            source,
            fits[(outfit_id, prefix)],
            prefix,
            wearable_id,
            top_insets,
        )
    bounds = overlay.getchannel("A").point(lambda alpha: 255 if alpha > 8 else 0).getbbox()
    body.alpha_composite(overlay)
    overlay.close()
    return body, bounds


def draw_cell(
    sheet: Image.Image,
    image: Image.Image,
    *,
    left: int,
    top: int,
    cell_size: int,
) -> None:
    rendered = image.resize((cell_size, cell_size), Image.Resampling.LANCZOS)
    sheet.alpha_composite(rendered, (left, top))
    rendered.close()


def render_by_outfit(
    fits: dict[tuple[str, str], tuple[float, float, float]],
    top_insets: dict[tuple[str, str], float],
) -> list[Path]:
    outputs: list[Path] = []
    cell_size = 214
    row_label_width = 152
    header_height = 76
    title_font = load_font(24)
    label_font = load_font(14)
    for outfit_id in DRESSED_GRIDS:
        for section, wearable_start in enumerate((0, 9), start=1):
            wearables = WEARABLES[wearable_start : wearable_start + 9]
            sheet = Image.new(
                "RGBA",
                (
                    row_label_width + len(wearables) * cell_size,
                    header_height + len(ADULT_PETS) * cell_size,
                ),
                BACKGROUND,
            )
            draw = ImageDraw.Draw(sheet)
            draw.text((10, 8), f"{outfit_id} - deel {section}/2", fill=(24, 45, 43), font=title_font)
            for column, wearable_id in enumerate(wearables):
                draw.text(
                    (row_label_width + column * cell_size + 4, 48),
                    wearable_id,
                    fill=(24, 45, 43),
                    font=label_font,
                )
            for row, prefix in enumerate(ADULT_PETS):
                top = header_height + row * cell_size
                draw.text((8, top + 94), prefix, fill=(24, 45, 43), font=label_font)
                for column, wearable_id in enumerate(wearables):
                    rendered, _ = composition(
                        outfit_id,
                        wearable_id,
                        prefix,
                        fits,
                        top_insets,
                    )
                    draw_cell(
                        sheet,
                        rendered,
                        left=row_label_width + column * cell_size,
                        top=top,
                        cell_size=cell_size,
                    )
                    rendered.close()
            output = AUDIT_OUTPUT / "by_outfit" / f"{outfit_id}_{section}.png"
            output.parent.mkdir(parents=True, exist_ok=True)
            sheet.save(output, optimize=True)
            sheet.close()
            outputs.append(output)
    return outputs


def render_by_pet(
    fits: dict[tuple[str, str], tuple[float, float, float]],
    top_insets: dict[tuple[str, str], float],
) -> list[Path]:
    outputs: list[Path] = []
    cell_size = 172
    row_label_width = 215
    header_height = 72
    title_font = load_font(24)
    label_font = load_font(12)
    for prefix in ADULT_PETS:
        sheet = Image.new(
            "RGBA",
            (
                row_label_width + len(WEARABLES) * cell_size,
                header_height + len(DRESSED_GRIDS) * cell_size,
            ),
            BACKGROUND,
        )
        draw = ImageDraw.Draw(sheet)
        draw.text((10, 8), prefix, fill=(24, 45, 43), font=title_font)
        for column, wearable_id in enumerate(WEARABLES):
            draw.text(
                (row_label_width + column * cell_size + 3, 48),
                wearable_id,
                fill=(24, 45, 43),
                font=label_font,
            )
        for row, outfit_id in enumerate(DRESSED_GRIDS):
            top = header_height + row * cell_size
            draw.text((8, top + 76), outfit_id, fill=(24, 45, 43), font=label_font)
            for column, wearable_id in enumerate(WEARABLES):
                rendered, _ = composition(
                    outfit_id,
                    wearable_id,
                    prefix,
                    fits,
                    top_insets,
                )
                draw_cell(
                    sheet,
                    rendered,
                    left=row_label_width + column * cell_size,
                    top=top,
                    cell_size=cell_size,
                )
                rendered.close()
        output = AUDIT_OUTPUT / "by_pet" / f"{prefix}.png"
        output.parent.mkdir(parents=True, exist_ok=True)
        sheet.save(output, optimize=True)
        sheet.close()
        outputs.append(output)
    return outputs


def render_bow_ties(
    fits: dict[tuple[str, str], tuple[float, float, float]],
    top_insets: dict[tuple[str, str], float],
) -> list[Path]:
    """Render collar-level checks at a larger size than the matrix sheets."""
    outputs: list[Path] = []
    columns = 4
    cell_size = 390
    header_height = 48
    label_font = load_font(17)
    for outfit_id in DRESSED_GRIDS:
        rows = (len(ADULT_PETS) + columns - 1) // columns
        sheet = Image.new(
            "RGBA",
            (columns * cell_size, header_height + rows * (cell_size + 26)),
            BACKGROUND,
        )
        draw = ImageDraw.Draw(sheet)
        draw.text((10, 10), f"{outfit_id} - bow tie", fill=(24, 45, 43), font=label_font)
        for index, prefix in enumerate(ADULT_PETS):
            row, column = divmod(index, columns)
            top = header_height + row * (cell_size + 26)
            rendered, _ = composition(
                outfit_id,
                "doctor_bow_tie",
                prefix,
                fits,
                top_insets,
            )
            draw_cell(
                sheet,
                rendered,
                left=column * cell_size,
                top=top,
                cell_size=cell_size,
            )
            rendered.close()
            draw.text(
                (column * cell_size + 8, top + cell_size + 2),
                prefix,
                fill=(24, 45, 43),
                font=label_font,
            )
        output = AUDIT_OUTPUT / "bow_ties" / f"{outfit_id}.png"
        output.parent.mkdir(parents=True, exist_ok=True)
        sheet.save(output, optimize=True)
        sheet.close()
        outputs.append(output)
    return outputs


def write_geometry_report(
    fits: dict[tuple[str, str], tuple[float, float, float]],
    top_insets: dict[tuple[str, str], float],
) -> Path:
    report = AUDIT_OUTPUT / "geometry.tsv"
    report.parent.mkdir(parents=True, exist_ok=True)
    clipped: list[str] = []
    lines = ["outfit\twearable\tpet\tleft\ttop\tright\tbottom"]
    for outfit_id in DRESSED_GRIDS:
        for wearable_id in WEARABLES:
            for prefix in ADULT_PETS:
                rendered, bounds = composition(
                    outfit_id,
                    wearable_id,
                    prefix,
                    fits,
                    top_insets,
                )
                rendered.close()
                if bounds is None:
                    raise RuntimeError(f"Empty overlay: {outfit_id}|{wearable_id}|{prefix}")
                left, top, right, bottom = bounds
                lines.append(
                    f"{outfit_id}\t{wearable_id}\t{prefix}\t{left}\t{top}\t{right}\t{bottom}"
                )
                if left <= 0 or top <= 0 or right >= 512 or bottom >= 512:
                    clipped.append(f"{outfit_id}|{wearable_id}|{prefix}: {bounds}")
    report.write_text("\n".join(lines) + "\n", encoding="utf-8")
    if clipped:
        raise RuntimeError("Transformed overlays touch the canvas:\n" + "\n".join(clipped))
    return report


def main() -> None:
    fits = read_runtime_fits()
    top_insets = read_hat_top_insets()
    report = write_geometry_report(fits, top_insets)
    outfit_sheets = render_by_outfit(fits, top_insets)
    pet_sheets = render_by_pet(fits, top_insets)
    bow_sheets = render_bow_ties(fits, top_insets)
    print(f"Checked {len(DRESSED_GRIDS) * len(WEARABLES) * len(ADULT_PETS)} combinations")
    print(report)
    print(f"Rendered {len(outfit_sheets)} outfit sheets and {len(pet_sheets)} pet sheets")
    print(f"Rendered {len(bow_sheets)} large bow-tie sheets")


if __name__ == "__main__":
    main()
