"""Render exported emulator-review selections as desktop contact sheets.

Usage:
    python tool/render_visual_review.py path/to/export.txt --output tmp/review.png
    python tool/render_visual_review.py --all --output tmp/full_review.png
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

# (asset filename, scale, horizontal offset, vertical offset). The three
# streak toys use the same centre-based scale and canvas-relative translation
# as CatAvatar; the other toys are already positioned on the shared canvas.
TOY_OVERLAYS = {
    "toy_yarn": ("shop_toy_yarn.png", 1.0, 0.0, 0.0),
    "doctor_tardis_toy": ("doctor_tardis_toy.png", 1.0, 0.0, 0.0),
    "supporter_toy": ("supporter_toy.png", 1.0, 0.0, 0.0),
    "toy_mouse": ("shop_toy_mouse.png", 1.0, 0.0, 0.0),
    "toy_teddy": ("shop_toy_teddy.png", 1.0, 0.0, 0.0),
    "chicken_toy_corn": ("chicken_toy_corn.png", 1.0, 0.0, 0.0),
    "streak_200_toy_rocket": ("streak_200_toy_rocket.png", 0.58, 0.155, 0.155),
    "streak_365_toy_year_cake": (
        "streak_365_toy_year_cake.png",
        0.55,
        0.155,
        0.155,
    ),
    "streak_750_toy_comet": ("streak_750_toy_comet.png", 0.50, 0.205, 0.175),
}


def load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    try:
        return ImageFont.truetype("arial.ttf", size)
    except OSError:
        return ImageFont.load_default()


def render_composition(item_id: str, prefix: str) -> Image.Image:
    assets = ROOT / "assets" / "cats"
    if item_id == "base_adult":
        return Image.open(assets / f"{prefix}_adult.png").convert("RGBA")
    if item_id == "dragon_mode":
        return Image.open(
            assets / "fitted" / f"{prefix}_dragon_mode_young.png"
        ).convert("RGBA")
    if item_id in DRESSED_GRIDS:
        return Image.open(assets / "fitted" / f"{prefix}_{item_id}.png").convert(
            "RGBA"
        )

    body = Image.open(assets / f"{prefix}_adult.png").convert("RGBA")
    if item_id in TOY_OVERLAYS:
        filename, scale, dx, dy = TOY_OVERLAYS[item_id]
        with Image.open(assets / filename).convert("RGBA") as toy:
            # Image.asset first applies BoxFit.contain to the 512px avatar.
            # Some streak sources are 1254px, so reproduce that fit before
            # applying CatAvatar's Transform.scale/translate.
            fitted = toy.resize(body.size, Image.Resampling.LANCZOS)
            if scale == 1:
                body.alpha_composite(fitted)
            else:
                size = round(fitted.width * scale), round(fitted.height * scale)
                scaled = fitted.resize(size, Image.Resampling.LANCZOS)
                body.alpha_composite(
                    scaled,
                    (
                        round((fitted.width - scaled.width) / 2 + fitted.width * dx),
                        round((fitted.height - scaled.height) / 2 + fitted.height * dy),
                    ),
                )
                scaled.close()
            fitted.close()
        return body
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


def all_selections() -> list[tuple[str, str]]:
    """Return every pet/item combination rendered by the wardrobe UI."""
    item_ids = (
        "base_adult",
        *DRESSED_GRIDS,
        *HEAD_ACCESSORIES,
        "doctor_bow_tie",
        *TOY_OVERLAYS,
        "dragon_mode",
    )
    return [
        (item_id, variant)
        for item_id in item_ids
        for variant in VARIANT_PREFIXES
    ]


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
    parser.add_argument("selection_file", type=Path, nargs="?")
    parser.add_argument(
        "--all",
        action="store_true",
        help="render every pet with every wearable and toy",
    )
    parser.add_argument("--per-page", type=int, default=20)
    parser.add_argument("--output", type=Path, default=ROOT / "tmp" / "review.png")
    arguments = parser.parse_args()
    if arguments.all == (arguments.selection_file is not None):
        parser.error("provide either a selection file or --all")
    if arguments.per_page < 1:
        parser.error("--per-page must be at least 1")
    selections = (
        all_selections()
        if arguments.all
        else parse_selections(arguments.selection_file)
    )
    for output in render_pages(
        selections,
        arguments.output,
        per_page=arguments.per_page,
    ):
        print(output)


if __name__ == "__main__":
    main()
