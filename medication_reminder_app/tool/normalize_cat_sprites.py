"""Slice and normalize the generated cat sheet into centered app sprites."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "design_assets" / "cats" / "cat_growth_sheet_transparent_v4.png"
OUTPUT = ROOT / "assets" / "cats"
VARIANTS = ("orange", "tuxedo", "gray", "calico")
STAGES = ("kitten", "young", "adult")
TARGET_HEIGHTS = (330, 405, 455)
CANVAS_SIZE = 512
BOTTOM_MARGIN = 28


def keep_main_vertical_run(image: Image.Image) -> Image.Image:
    """Drop cat fragments that crossed into an adjacent generated grid cell."""
    alpha = image.getchannel("A")
    row_has_pixels = [
        any(
            value >= 24
            for value in alpha.crop(
                (0, y, alpha.width, y + 1),
            ).get_flattened_data()
        )
        for y in range(alpha.height)
    ]
    runs: list[tuple[int, int]] = []
    start: int | None = None
    for y, occupied in enumerate(row_has_pixels + [False]):
        if occupied and start is None:
            start = y
        elif not occupied and start is not None:
            runs.append((start, y))
            start = None
    if not runs:
        return image
    main_top, main_bottom = max(runs, key=lambda run: run[1] - run[0])
    cleaned = image.copy()
    cleaned_alpha = cleaned.getchannel("A")
    if main_top > 0:
        cleaned_alpha.paste(0, (0, 0, alpha.width, main_top))
    if main_bottom < alpha.height:
        cleaned_alpha.paste(0, (0, main_bottom, alpha.width, alpha.height))
    cleaned.putalpha(cleaned_alpha)
    return cleaned


def main() -> None:
    sheet = Image.open(SOURCE).convert("RGBA")
    for row, variant in enumerate(VARIANTS):
        top = round(row * sheet.height / len(VARIANTS))
        bottom = round((row + 1) * sheet.height / len(VARIANTS))
        for column, stage in enumerate(STAGES):
            left = round(column * sheet.width / len(STAGES))
            right = round((column + 1) * sheet.width / len(STAGES))
            cell = keep_main_vertical_run(
                sheet.crop((left, top, right, bottom)),
            )
            alpha_box = cell.getchannel("A").getbbox()
            if alpha_box is None:
                raise RuntimeError(f"No visible cat found for {variant} {stage}")

            cat = cell.crop(alpha_box)
            target_height = TARGET_HEIGHTS[column]
            scale = min(target_height / cat.height, (CANVAS_SIZE - 24) / cat.width)
            new_size = (round(cat.width * scale), round(cat.height * scale))
            cat = cat.resize(new_size, Image.Resampling.LANCZOS)

            canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
            x = (CANVAS_SIZE - cat.width) // 2
            y = CANVAS_SIZE - BOTTOM_MARGIN - cat.height
            canvas.alpha_composite(cat, (x, y))
            canvas.save(OUTPUT / f"cat_{variant}_{stage}.png", optimize=True)

    sheet.close()


if __name__ == "__main__":
    main()
