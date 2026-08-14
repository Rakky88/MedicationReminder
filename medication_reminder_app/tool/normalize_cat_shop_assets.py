"""Slice the generated shop sheet into aligned transparent cat overlays."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "design_assets" / "cats" / "cat_shop_accessories_transparent.png"
OUTPUT = ROOT / "assets" / "cats"
CANVAS_SIZE = 512

ITEMS = (
    (("hat_cap", 210, 112, 256, 70), ("hat_wizard", 225, 135, 256, 70), ("hat_crown", 198, 99, 256, 72)),
    (("glasses_round", 225, 84, 256, 163), ("glasses_sun", 210, 78, 256, 158), ("glasses_star", 205, 80, 256, 159)),
    (("outfit_hoodie", 330, 250, 256, 365), ("outfit_cape", 345, 258, 256, 362), ("outfit_sweater", 330, 250, 256, 365)),
    (("toy_yarn", 145, 145, 415, 420), ("toy_mouse", 155, 125, 410, 425), ("toy_teddy", 145, 155, 415, 410)),
)


def main() -> None:
    sheet = Image.open(SOURCE).convert("RGBA")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for row, row_items in enumerate(ITEMS):
        top = round(row * sheet.height / len(ITEMS))
        bottom = round((row + 1) * sheet.height / len(ITEMS))
        for column, (name, max_width, max_height, center_x, center_y) in enumerate(row_items):
            left = round(column * sheet.width / len(row_items))
            right = round((column + 1) * sheet.width / len(row_items))
            cell = sheet.crop((left, top, right, bottom))
            box = cell.getchannel("A").getbbox()
            if box is None:
                raise RuntimeError(f"No accessory found for {name}")
            item = cell.crop(box)
            scale = min(max_width / item.width, max_height / item.height)
            item = item.resize(
                (round(item.width * scale), round(item.height * scale)),
                Image.Resampling.LANCZOS,
            )
            if name == "hat_wizard":
                alpha = item.getchannel("A").point(
                    lambda value: 0 if value <= 8 else (value if value < 64 else 255)
                )
                item.putalpha(alpha)
            canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
            x = round(center_x - item.width / 2)
            y = round(center_y - item.height / 2)
            canvas.alpha_composite(item, (x, y))
            canvas.save(OUTPUT / f"shop_{name}.png", optimize=True)
            print(name, canvas.getchannel("A").getbbox())
    sheet.close()

    variants = ("orange", "tuxedo", "gray", "calico")
    flattened_items = [item for row_items in ITEMS for item in row_items]
    preview = Image.new(
        "RGB",
        (CANVAS_SIZE * len(variants), CANVAS_SIZE * len(flattened_items)),
        "#edf2f3",
    )
    for row, (name, *_placement) in enumerate(flattened_items):
        for column, variant in enumerate(variants):
            cat = Image.open(OUTPUT / f"cat_{variant}_adult.png").convert("RGBA")
            composed = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
            composed.alpha_composite(cat)
            accessory = Image.open(OUTPUT / f"shop_{name}.png").convert("RGBA")
            composed.alpha_composite(accessory)
            preview.paste(
                composed.convert("RGB"),
                (column * CANVAS_SIZE, row * CANVAS_SIZE),
            )
            accessory.close()
            cat.close()
    preview.save(ROOT / "tmp_shop_all_variants.jpg", quality=92)


if __name__ == "__main__":
    main()
