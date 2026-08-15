"""Render exported emulator-review selections as desktop contact sheets.

Usage:
    python tool/render_visual_review.py path/to/export.txt --output tmp/review.png
"""

from __future__ import annotations

import argparse
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from normalize_pet_assets import DRESSED_GRIDS, HEAD_ACCESSORIES, ROOT


VARIANT_PREFIXES = {
    "catOrange": "cat_orange",
    "catTuxedo": "cat_tuxedo",
    "catGray": "cat_gray",
    "catCalico": "cat_calico",
    "catBlackBib": "cat_black_bib",
    "dogGolden": "dog_golden",
    "dogBeagle": "dog_beagle",
    "dogBlackLab": "dog_black_lab",
    "dogBorderCollie": "dog_border_collie",
    "dogDachshund": "dog_dachshund",
    "chickenHen": "chicken_hen",
}


def load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    try:
        return ImageFont.truetype("arial.ttf", size)
    except OSError:
        return ImageFont.load_default()


def render_composition(item_id: str, prefix: str) -> Image.Image:
    assets = ROOT / "assets" / "cats"
    if item_id == "dragon_mode":
        return Image.open(
            assets / "fitted" / f"{prefix}_dragon_mode_young.png"
        ).convert("RGBA")
    if item_id in DRESSED_GRIDS:
        return Image.open(assets / "fitted" / f"{prefix}_{item_id}.png").convert(
            "RGBA"
        )

    body = Image.open(assets / f"{prefix}_adult.png").convert("RGBA")
    overlay_path = assets / "fitted_accessories" / f"{prefix}_{item_id}.png"
    if item_id not in HEAD_ACCESSORIES and item_id != "doctor_bow_tie":
        body.close()
        raise ValueError(f"Unsupported review item: {item_id}")
    with Image.open(overlay_path).convert("RGBA") as overlay:
        body.alpha_composite(overlay)
    return body


def parse_selections(path: Path) -> list[tuple[str, str]]:
    selections: list[tuple[str, str]] = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or "|" not in line:
            continue
        item_id, variant = line.split("|", 1)
        if variant not in VARIANT_PREFIXES:
            raise ValueError(f"Unknown pet variant in review export: {variant}")
        selections.append((item_id, variant))
    return selections


def render_pages(
    selections: list[tuple[str, str]], output: Path, *, per_page: int = 20
) -> list[Path]:
    columns = 4
    cell_width = 320
    cell_height = 350
    pet_size = 285
    label_font = load_font(17)
    outputs: list[Path] = []
    page_count = max(1, math.ceil(len(selections) / per_page))
    output.parent.mkdir(parents=True, exist_ok=True)

    for page_index in range(page_count):
        page_selections = selections[
            page_index * per_page : (page_index + 1) * per_page
        ]
        rows = max(1, math.ceil(len(page_selections) / columns))
        sheet = Image.new(
            "RGBA", (columns * cell_width, rows * cell_height), (238, 244, 242, 255)
        )
        draw = ImageDraw.Draw(sheet)
        for index, (item_id, variant) in enumerate(page_selections):
            prefix = VARIANT_PREFIXES[variant]
            composition = render_composition(item_id, prefix)
            composition.thumbnail((pet_size, pet_size), Image.Resampling.LANCZOS)
            column = index % columns
            row = index // columns
            x = column * cell_width + (cell_width - composition.width) // 2
            y = row * cell_height + 4
            sheet.alpha_composite(composition, (x, y))
            composition.close()
            label = f"{item_id} | {variant}"
            label_box = draw.textbbox((0, 0), label, font=label_font)
            label_width = label_box[2] - label_box[0]
            draw.text(
                (
                    column * cell_width + max(5, (cell_width - label_width) // 2),
                    row * cell_height + pet_size + 18,
                ),
                label,
                fill=(24, 45, 43, 255),
                font=label_font,
            )

        suffix = "" if page_count == 1 else f"_{page_index + 1:02d}"
        page_output = output.with_name(f"{output.stem}{suffix}{output.suffix}")
        sheet.save(page_output, optimize=True)
        sheet.close()
        outputs.append(page_output)
    return outputs


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("selection_file", type=Path)
    parser.add_argument("--output", type=Path, default=ROOT / "tmp" / "review.png")
    arguments = parser.parse_args()
    selections = parse_selections(arguments.selection_file)
    for output in render_pages(selections, arguments.output):
        print(output)


if __name__ == "__main__":
    main()
