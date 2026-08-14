"""Create aligned pet sprites, fitted wardrobe overlays, and launcher icons."""

from pathlib import Path
from collections import deque

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "design_assets" / "pets"
OUTPUT = ROOT / "assets" / "cats"
CANVAS_SIZE = 512
STAGES = ("kitten", "young", "adult")
TARGET_HEIGHTS = (330, 405, 455)
DISPLAY_WIDTH = 330

GROWTH_SHEETS = {
    "cat_black_bib": "cat_black_bib_growth_transparent.png",
    "dog_golden": "dog_golden_growth_transparent.png",
    "dog_beagle": "dog_beagle_growth_transparent.png",
    "dog_black_lab": "dog_black_lab_growth_transparent.png",
    "dog_border_collie": "dog_border_collie_growth_transparent.png",
    "dog_dachshund": "dog_dachshund_growth_transparent.png",
    "chicken_hen": "chicken_growth_transparent.png",
}

ADULT_PETS = (
    "cat_orange",
    "cat_tuxedo",
    "cat_gray",
    "cat_calico",
    "cat_black_bib",
    "dog_golden",
    "dog_beagle",
    "dog_black_lab",
    "dog_border_collie",
    "dog_dachshund",
    "chicken_hen",
)

DRESSED_GRIDS = {
    "outfit_hoodie": "outfit_hoodie_grid_transparent.png",
    "outfit_cape": "outfit_cape_grid_transparent.png",
    "outfit_sweater": "outfit_sweater_grid_transparent.png",
    "supporter_outfit": "supporter_outfit_grid_transparent.png",
    "chicken_outfit_overalls": "chicken_outfit_overalls_grid_transparent.png",
    "doctor_outfit": "doctor_outfit_grid_transparent.png",
}

DOCTOR_ITEM_SOURCES = {
    "doctor_hat_fezz": "doctor_fezz_transparent.png",
    "doctor_bow_tie": "doctor_bow_tie_transparent.png",
    "doctor_tardis_toy": "doctor_tardis_toy_transparent.png",
}

# Source pixels remain untouched. These content boxes deliberately exclude a
# few disconnected guide pixels in older accessory exports, while the anchors
# describe the visual centre of the cap/frames instead of the full PNG bounds
# (which include asymmetrical brims and spectacle arms).
HEAD_ACCESSORIES = {
    "hat_cap": ("shop_hat_cap", "hat", (174, 14, 338, 126), (271, 112), 1.00),
    "hat_wizard": ("shop_hat_wizard", "hat", (162, 2, 351, 137), (256, 116), 0.92),
    "hat_crown": ("shop_hat_crown", "hat", (189, 22, 323, 121), (256, 116), 1.02),
    "supporter_hat": ("supporter_hat", "hat", (189, 22, 323, 121), (256, 116), 1.02),
    "chicken_hat_straw": ("chicken_hat_straw", "hat", (186, 12, 327, 98), (256, 88), 1.02),
    "doctor_hat_fezz": ("doctor_hat_fezz", "hat", None, None, 1.00),
    # The round frame has a considerably narrower source crop than the other
    # glasses. A small item-specific correction keeps both lenses over the
    # eyes on broad adult heads without changing the source artwork.
    "glasses_round": ("shop_glasses_round", "glasses", (196, 121, 315, 178), (242, 145), 1.12),
    "supporter_glasses": ("supporter_glasses", "glasses", (170, 119, 341, 199), (244, 159), 0.86),
    "glasses_sun": ("shop_glasses_sun", "glasses", (151, 120, 361, 197), (235, 157), 0.78),
    "glasses_star": ("shop_glasses_star", "glasses", (170, 119, 341, 199), (244, 159), 0.86),
    "chicken_glasses_egg": ("chicken_glasses_egg", "glasses", (185, 117, 353, 209), (256, 162), 0.80),
}

# (hat X scale, hat Y scale, hat seat Y, glasses X scale, glasses Y scale,
# eye-line Y). Horizontal and vertical scale are deliberately independent:
# wider headwear reads naturally on broad dog/cat heads without making tall
# hats clip, while the visual anchor remains fixed on the measured landmark.
# The tailored outfit composites retain the same head placement, so these
# derived overlays fit naked/dressed adults and notification artwork alike.
PET_HEAD_FITS = {
    "cat_orange": (1.18, 1.00, 110, 1.20, 1.00, 130),
    "cat_tuxedo": (1.18, 1.00, 110, 1.20, 1.00, 130),
    "cat_gray": (1.18, 1.00, 110, 1.20, 1.00, 130),
    "cat_calico": (1.18, 1.00, 110, 1.20, 1.00, 130),
    "cat_black_bib": (1.18, 1.00, 110, 1.20, 1.00, 130),
    "dog_golden": (1.18, 0.72, 79, 1.20, 1.00, 88),
    "dog_beagle": (1.18, 0.72, 85, 1.20, 1.00, 94),
    "dog_black_lab": (1.18, 0.70, 75, 1.20, 1.00, 84),
    "dog_border_collie": (1.18, 0.72, 99, 1.20, 1.00, 108),
    "dog_dachshund": (1.18, 0.72, 83, 1.20, 1.00, 92),
    "chicken_hen": (1.05, 0.82, 97, 1.00, 0.78, 132),
}

# (maximum width, maximum height, vertical centre) for collar-level items.
# The fitted bow tie uses each adult animal's measured neck/chest landmark.
PET_NECK_FITS = {
    "cat_orange": (118, 58, 194),
    "cat_tuxedo": (118, 58, 194),
    "cat_gray": (118, 58, 194),
    "cat_calico": (118, 58, 194),
    "cat_black_bib": (112, 56, 202),
    "dog_golden": (108, 52, 174),
    "dog_beagle": (108, 52, 192),
    "dog_black_lab": (106, 50, 170),
    "dog_border_collie": (106, 50, 194),
    "dog_dachshund": (106, 50, 196),
    "chicken_hen": (94, 46, 220),
}


def visible_crop(image: Image.Image, name: str) -> Image.Image:
    box = image.getchannel("A").getbbox()
    if box is None:
        raise RuntimeError(f"No visible pixels found for {name}")
    return image.crop(box)


def guarded_pet_crop(image: Image.Image, name: str) -> Image.Image:
    """Ignore disconnected remnants from neighbouring growth-sheet cells."""
    guard = round(image.width * 0.08)
    guarded = image.crop((guard, 0, image.width - guard, image.height))
    alpha = guarded.getchannel("A")
    bounds = alpha.getbbox()
    if bounds is None:
        raise RuntimeError(f"No visible pet pixels found for {name}")
    pixels = alpha.load()
    width, height = alpha.size
    seen = bytearray(width * height)
    largest: tuple[int, tuple[int, int, int, int]] | None = None
    left, top, right, bottom = bounds
    for y in range(top, bottom):
        for x in range(left, right):
            offset = y * width + x
            if seen[offset] or pixels[x, y] < 12:
                continue
            seen[offset] = 1
            queue = deque([(x, y)])
            count = 0
            min_x = max_x = x
            min_y = max_y = y
            while queue:
                current_x, current_y = queue.popleft()
                count += 1
                min_x = min(min_x, current_x)
                max_x = max(max_x, current_x)
                min_y = min(min_y, current_y)
                max_y = max(max_y, current_y)
                for next_x, next_y in (
                    (current_x - 1, current_y),
                    (current_x + 1, current_y),
                    (current_x, current_y - 1),
                    (current_x, current_y + 1),
                ):
                    if not (0 <= next_x < width and 0 <= next_y < height):
                        continue
                    next_offset = next_y * width + next_x
                    if seen[next_offset] or pixels[next_x, next_y] < 12:
                        continue
                    seen[next_offset] = 1
                    queue.append((next_x, next_y))
            component = (count, (min_x, min_y, max_x + 1, max_y + 1))
            if largest is None or component[0] > largest[0]:
                largest = component
    if largest is None:
        raise RuntimeError(f"No connected pet pixels found for {name}")
    _, (left, top, right, bottom) = largest
    padding = 3
    return guarded.crop(
        (
            max(0, left - padding),
            max(0, top - padding),
            min(width, right + padding),
            min(height, bottom + padding),
        )
    )


def separated_growth_crop(
    sheet: Image.Image,
    *,
    stage_index: int,
    stage_count: int,
    name: str,
) -> Image.Image:
    """Extract a stage whose artwork crosses the nominal third boundaries.

    The chicken source has three clearly separated silhouettes, but the adult
    hen starts inside the middle third. Dividing that sheet into equal cells
    therefore removed part of her left wing and torso. Transparent column gaps
    are the actual boundaries and preserve the complete artwork.
    """
    alpha = sheet.getchannel("A").point(lambda value: 255 if value > 8 else 0)
    occupied_columns = [
        x
        for x in range(sheet.width)
        if alpha.crop((x, 0, x + 1, sheet.height)).getbbox() is not None
    ]
    runs: list[tuple[int, int]] = []
    if occupied_columns:
        start = previous = occupied_columns[0]
        for x in occupied_columns[1:]:
            if x > previous + 1:
                runs.append((start, previous + 1))
                start = x
            previous = x
        runs.append((start, previous + 1))
    # Ignore isolated export pixels while retaining the three real animals.
    runs = [run for run in runs if run[1] - run[0] > sheet.width * 0.05]
    if len(runs) != stage_count:
        raise RuntimeError(
            f"Expected {stage_count} separated growth stages for {name}, found {runs}"
        )
    left = 0 if stage_index == 0 else (runs[stage_index - 1][1] + runs[stage_index][0]) // 2
    right = (
        sheet.width
        if stage_index == stage_count - 1
        else (runs[stage_index][1] + runs[stage_index + 1][0]) // 2
    )
    return visible_crop(sheet.crop((left, 0, right, sheet.height)), name)


def center_visible_to_width(image: Image.Image, width: int) -> Image.Image:
    if image.width >= width:
        return image
    pad = width - image.width
    left_pad = pad // 2
    right_pad = pad - left_pad
    canvas = Image.new("RGBA", (width, image.height), (0, 0, 0, 0))
    canvas.alpha_composite(image, (left_pad, 0))
    return canvas


def placed_overlay(
    item: Image.Image,
    *,
    max_width: int,
    max_height: int,
    center_x: int,
    center_y: int,
) -> Image.Image:
    scale = min(max_width / item.width, max_height / item.height)
    item = item.resize(
        (round(item.width * scale), round(item.height * scale)),
        Image.Resampling.LANCZOS,
    )
    # Body garments need enough width for the animal to read as being inside
    # the outfit. The generated cut-outs remain intact; only overly narrow
    # torso pieces receive a modest horizontal fit correction.
    if max_width >= 300 and item.width < 260:
        item = item.resize((260, item.height), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    canvas.alpha_composite(
        item,
        (round(center_x - item.width / 2), round(center_y - item.height / 2)),
    )
    return canvas


def normalize_growth_sheets() -> None:
    for prefix, filename in GROWTH_SHEETS.items():
        sheet = Image.open(SOURCE / filename).convert("RGBA")
        for index, stage in enumerate(STAGES):
            left = round(index * sheet.width / len(STAGES))
            right = round((index + 1) * sheet.width / len(STAGES))
            if prefix == "chicken_hen":
                pet = separated_growth_crop(
                    sheet,
                    stage_index=index,
                    stage_count=len(STAGES),
                    name=f"{prefix} {stage}",
                )
            else:
                pet = guarded_pet_crop(
                    sheet.crop((left, 0, right, sheet.height)),
                    f"{prefix} {stage}",
                )
            target_height = TARGET_HEIGHTS[index]
            scale = min(target_height / pet.height, DISPLAY_WIDTH / pet.width)
            pet = pet.resize(
                (round(pet.width * scale), round(pet.height * scale)),
                Image.Resampling.LANCZOS,
            )
            pet = center_visible_to_width(pet, DISPLAY_WIDTH)

            canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
            visual_box = pet.getchannel("A").point(
                lambda alpha: 255 if alpha > 8 else 0
            ).getbbox()
            if visual_box is None:
                raise RuntimeError(f"No rendered pet pixels found for {prefix} {stage}")
            visual_left, _, visual_right, visual_bottom = visual_box
            x = round(CANVAS_SIZE / 2 - (visual_left + visual_right) / 2)
            y = 484 - visual_bottom
            canvas.alpha_composite(pet, (x, y))
            output = OUTPUT / f"{prefix}_{stage}.png"
            canvas.save(output, optimize=True)
            print(output.name, canvas.getchannel("A").getbbox())
        sheet.close()


def slice_grid(
    source_name: str,
    specs: tuple[tuple[str, int, int, int, int], ...],
) -> None:
    sheet = Image.open(SOURCE / source_name).convert("RGBA")
    for index, (name, width, height, center_x, center_y) in enumerate(specs):
        row, column = divmod(index, 2)
        left = round(column * sheet.width / 2)
        right = round((column + 1) * sheet.width / 2)
        top = round(row * sheet.height / 2)
        bottom = round((row + 1) * sheet.height / 2)
        item = visible_crop(sheet.crop((left, top, right, bottom)), name)
        canvas = placed_overlay(
            item,
            max_width=width,
            max_height=height,
            center_x=center_x,
            center_y=center_y,
        )
        output = OUTPUT / f"{name}.png"
        canvas.save(output, optimize=True)
        print(output.name, canvas.getchannel("A").getbbox())
    sheet.close()


def normalize_accessories() -> None:
    slice_grid(
        "chicken_items_transparent.png",
        (
            ("chicken_hat_straw", 250, 122, 256, 73),
            ("chicken_glasses_egg", 230, 92, 256, 163),
            ("chicken_outfit_overalls", 345, 260, 256, 360),
            ("chicken_toy_corn", 175, 175, 407, 405),
        ),
    )


def normalize_doctor_items() -> None:
    """Place the generated code-only items on the shared 512px canvas."""
    specs = {
        "doctor_hat_fezz": (170, 100, 256, 66, True),
        "doctor_bow_tie": (126, 62, 256, 194, False),
        "doctor_tardis_toy": (150, 190, 404, 390, False),
    }
    for item_id, source_name in DOCTOR_ITEM_SOURCES.items():
        source = Image.open(SOURCE / source_name).convert("RGBA")
        item = visible_crop(source, item_id)
        width, height, center_x, center_y, stretch = specs[item_id]
        if stretch:
            item = item.resize((width, height), Image.Resampling.LANCZOS)
            canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
            canvas.alpha_composite(
                item,
                (round(center_x - width / 2), round(center_y - height / 2)),
            )
        else:
            canvas = placed_overlay(
                item,
                max_width=width,
                max_height=height,
                center_x=center_x,
                center_y=center_y,
            )
        output = OUTPUT / f"{item_id}.png"
        canvas.save(output, optimize=True)
        print(output.name, canvas.getchannel("A").getbbox())
        source.close()
        item.close()
        canvas.close()
    slice_grid(
        "fitted_outfits_transparent.png",
        (
            ("shop_outfit_hoodie", 330, 260, 256, 360),
            ("shop_outfit_cape", 350, 260, 256, 360),
            ("shop_outfit_sweater", 330, 260, 256, 360),
            ("supporter_outfit", 350, 260, 256, 360),
        ),
    )


def normalize_dressed_pets() -> None:
    """Extract full, individually tailored adult-pet outfit composites."""
    dressed_output = OUTPUT / "fitted"
    dressed_output.mkdir(parents=True, exist_ok=True)
    dressed_source = SOURCE / "dressed"
    for outfit_id, filename in DRESSED_GRIDS.items():
        sheet = Image.open(dressed_source / filename).convert("RGBA")
        cell_width = sheet.width / 4
        cell_height = sheet.height / 4
        top_offset = sheet.height / 8
        for index, prefix in enumerate(ADULT_PETS):
            row, column = divmod(index, 4)
            left = round(column * cell_width)
            right = round((column + 1) * cell_width)
            top = round(top_offset + row * cell_height)
            bottom = round(top_offset + (row + 1) * cell_height)
            dressed = visible_crop(
                sheet.crop((left, top, right, bottom)),
                f"{prefix} {outfit_id}",
            )
            target_height = TARGET_HEIGHTS[-1]
            scale = min(
                target_height / dressed.height,
                DISPLAY_WIDTH / dressed.width,
            )
            dressed = dressed.resize(
                (round(dressed.width * scale), round(dressed.height * scale)),
                Image.Resampling.LANCZOS,
            )
            dressed = center_visible_to_width(dressed, DISPLAY_WIDTH)
            canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
            bottom_margin = 28
            x = (CANVAS_SIZE - dressed.width) // 2
            y = CANVAS_SIZE - bottom_margin - dressed.height
            canvas.alpha_composite(dressed, (x, y))
            output = dressed_output / f"{prefix}_{outfit_id}.png"
            canvas.save(output, optimize=True)
            print(output.relative_to(OUTPUT), canvas.getchannel("A").getbbox())
        sheet.close()


def normalize_fitted_head_accessories() -> None:
    """Create clean, anchored hat/glasses copies for every adult pet."""
    fitted_output = OUTPUT / "fitted_accessories"
    fitted_output.mkdir(parents=True, exist_ok=True)
    for prefix in ADULT_PETS:
        (
            hat_scale_x,
            hat_scale_y,
            hat_y,
            glasses_scale_x,
            glasses_scale_y,
            glasses_y,
        ) = PET_HEAD_FITS[prefix]
        for item_id, (
            source_name,
            category,
            content_box,
            source_anchor,
            item_scale,
        ) in HEAD_ACCESSORIES.items():
            source = Image.open(OUTPUT / f"{source_name}.png").convert("RGBA")
            if content_box is None:
                content_box = source.getchannel("A").getbbox()
            if content_box is None:
                raise RuntimeError(f"No visible pixels found for {item_id}")
            if source_anchor is None:
                source_anchor = (256, content_box[3] - 6)
            content = source.crop(content_box)
            pet_scale_x = hat_scale_x if category == "hat" else glasses_scale_x
            pet_scale_y = hat_scale_y if category == "hat" else glasses_scale_y
            scale_x = item_scale * pet_scale_x
            scale_y = item_scale * pet_scale_y
            content = content.resize(
                (
                    round(content.width * scale_x),
                    round(content.height * scale_y),
                ),
                Image.Resampling.LANCZOS,
            )
            anchor_x = (source_anchor[0] - content_box[0]) * scale_x
            anchor_y = (source_anchor[1] - content_box[1]) * scale_y
            target_y = hat_y if category == "hat" else glasses_y
            canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
            canvas.alpha_composite(
                content,
                (round(CANVAS_SIZE / 2 - anchor_x), round(target_y - anchor_y)),
            )
            output = fitted_output / f"{prefix}_{item_id}.png"
            canvas.save(output, optimize=True)
            print(output.relative_to(OUTPUT), canvas.getchannel("A").getbbox())
            source.close()
            content.close()
            canvas.close()


def normalize_fitted_neckwear() -> None:
    """Create a bow tie fitted to every adult pet's neck landmark."""
    source = Image.open(OUTPUT / "doctor_bow_tie.png").convert("RGBA")
    item = visible_crop(source, "doctor_bow_tie")
    fitted_output = OUTPUT / "fitted_accessories"
    fitted_output.mkdir(parents=True, exist_ok=True)
    for prefix, (width, height, center_y) in PET_NECK_FITS.items():
        canvas = placed_overlay(
            item,
            max_width=width,
            max_height=height,
            center_x=CANVAS_SIZE // 2,
            center_y=center_y,
        )
        output = fitted_output / f"{prefix}_doctor_bow_tie.png"
        canvas.save(output, optimize=True)
        print(output.relative_to(OUTPUT), canvas.getchannel("A").getbbox())
        canvas.close()
    source.close()
    item.close()


def prepare_logo_mark(size: int = 1024) -> Image.Image:
    """Centre the transparent mark inside every adaptive-icon safe mask."""
    source = Image.open(
        ROOT / "design_assets" / "branding" / "app_logo_v3_mark.png"
    ).convert("RGBA")
    mark = visible_crop(source, "application logo")
    safe_extent = round(size * 0.54)
    scale = min(safe_extent / mark.width, safe_extent / mark.height)
    mark = mark.resize(
        (round(mark.width * scale), round(mark.height * scale)),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(
        mark,
        ((size - mark.width) // 2, (size - mark.height) // 2),
    )
    source.close()
    mark.close()
    return canvas


def prepare_logo(size: int = 1024) -> Image.Image:
    mark = prepare_logo_mark(size)
    logo = Image.new("RGBA", (size, size), (7, 94, 101, 255))
    logo.alpha_composite(mark)
    mark.close()
    return logo.convert("RGB")


def save_resized(logo: Image.Image, path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    logo.resize((size, size), Image.Resampling.LANCZOS).save(path, optimize=True)


def generate_launcher_icons() -> None:
    logo = prepare_logo()
    adaptive_mark = prepare_logo_mark(432)
    branding = ROOT / "assets" / "branding"
    branding.mkdir(parents=True, exist_ok=True)
    save_resized(logo, branding / "app_logo.png", 1024)

    android_sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for density, size in android_sizes.items():
        save_resized(
            logo,
            ROOT / "android" / "app" / "src" / "main" / "res" / f"mipmap-{density}" / "ic_launcher.png",
            size,
        )
    adaptive_path = (
        ROOT
        / "android"
        / "app"
        / "src"
        / "main"
        / "res"
        / "drawable"
        / "ic_launcher_foreground.png"
    )
    adaptive_path.parent.mkdir(parents=True, exist_ok=True)
    adaptive_mark.save(adaptive_path, optimize=True)

    ios_sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    ios_dir = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for filename, size in ios_sizes.items():
        save_resized(logo, ios_dir / filename, size)

    mac_sizes = (16, 32, 64, 128, 256, 512, 1024)
    mac_dir = ROOT / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for size in mac_sizes:
        save_resized(logo, mac_dir / f"app_icon_{size}.png", size)

    save_resized(logo, ROOT / "web" / "favicon.png", 32)
    save_resized(logo, ROOT / "web" / "icons" / "Icon-192.png", 192)
    save_resized(logo, ROOT / "web" / "icons" / "Icon-512.png", 512)
    save_resized(logo, ROOT / "web" / "icons" / "Icon-maskable-192.png", 192)
    save_resized(logo, ROOT / "web" / "icons" / "Icon-maskable-512.png", 512)
    logo.save(
        ROOT / "windows" / "runner" / "resources" / "app_icon.ico",
        sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )
    logo.close()
    adaptive_mark.close()


def generate_fit_preview() -> None:
    pets = tuple(f"{prefix}_adult" for prefix in ADULT_PETS)
    combinations = (
        (),
        ("outfit_hoodie",),
        ("outfit_cape",),
        ("outfit_sweater",),
        ("supporter_outfit",),
        ("chicken_outfit_overalls",),
        (
            "chicken_outfit_overalls",
            "chicken_hat_straw",
            "chicken_glasses_egg",
            "chicken_toy_corn",
        ),
    )
    preview = Image.new(
        "RGBA",
        (CANVAS_SIZE * len(combinations), CANVAS_SIZE * len(pets)),
        (238, 244, 242, 255),
    )
    for row, pet_name in enumerate(pets):
        pet = Image.open(OUTPUT / f"{pet_name}.png").convert("RGBA")
        for column, accessories in enumerate(combinations):
            composition = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
            outfit_name = next(
                (name for name in accessories if name in DRESSED_GRIDS),
                None,
            )
            if outfit_name is None:
                composition.alpha_composite(pet)
            else:
                prefix = pet_name.removesuffix("_adult")
                dressed = Image.open(
                    OUTPUT / "fitted" / f"{prefix}_{outfit_name}.png"
                ).convert("RGBA")
                composition.alpha_composite(dressed)
                dressed.close()
            for accessory_name in (
                name for name in accessories if name != outfit_name
            ):
                accessory = Image.open(OUTPUT / f"{accessory_name}.png").convert("RGBA")
                composition.alpha_composite(accessory)
                accessory.close()
            preview.alpha_composite(composition, (column * CANVAS_SIZE, row * CANVAS_SIZE))
        pet.close()
    preview_path = ROOT / "tmp" / "pet_fit_preview.png"
    preview_path.parent.mkdir(parents=True, exist_ok=True)
    preview.save(preview_path, optimize=True)
    preview.close()


def generate_accessory_fit_preview(*, outfit_id: str | None = None) -> None:
    """Render every fitted head accessory on every adult body for visual QA."""
    pets = tuple(f"{prefix}_adult" for prefix in ADULT_PETS)
    accessories = (
        None,
        "shop_hat_cap",
        "shop_hat_wizard",
        "shop_hat_crown",
        "supporter_hat",
        "chicken_hat_straw",
        "shop_glasses_round",
        "supporter_glasses",
        "shop_glasses_sun",
        "shop_glasses_star",
        "chicken_glasses_egg",
    )
    cell_size = 256
    preview = Image.new(
        "RGBA",
        (cell_size * len(accessories), cell_size * len(pets)),
        (238, 244, 242, 255),
    )
    for row, pet_name in enumerate(pets):
        prefix = pet_name.removesuffix("_adult")
        pet_path = (
            OUTPUT / f"{pet_name}.png"
            if outfit_id is None
            else OUTPUT / "fitted" / f"{prefix}_{outfit_id}.png"
        )
        pet = Image.open(pet_path).convert("RGBA")
        for column, accessory_name in enumerate(accessories):
            composition = pet.copy()
            if accessory_name is not None:
                item_id = next(
                    item_id
                    for item_id, item_spec in HEAD_ACCESSORIES.items()
                    if item_spec[0] == accessory_name
                )
                accessory = Image.open(
                    OUTPUT / "fitted_accessories" / f"{prefix}_{item_id}.png"
                ).convert("RGBA")
                composition.alpha_composite(accessory)
                accessory.close()
            composition = composition.resize(
                (cell_size, cell_size),
                Image.Resampling.LANCZOS,
            )
            preview.alpha_composite(
                composition,
                (column * cell_size, row * cell_size),
            )
            composition.close()
        pet.close()
    suffix = "" if outfit_id is None else f"_{outfit_id}"
    preview_path = ROOT / "tmp" / f"accessory_fit_preview{suffix}.png"
    preview_path.parent.mkdir(parents=True, exist_ok=True)
    preview.save(preview_path, optimize=True)
    preview.close()


def generate_per_pet_accessory_previews(
    prefixes: tuple[str, ...] = ADULT_PETS,
) -> None:
    """Render two large QA rows per body state for every adult animal."""
    hats = (
        "hat_cap",
        "hat_wizard",
        "hat_crown",
        "supporter_hat",
        "chicken_hat_straw",
    )
    glasses = (
        "glasses_round",
        "supporter_glasses",
        "glasses_sun",
        "glasses_star",
        "chicken_glasses_egg",
    )
    try:
        title_font = ImageFont.truetype("arial.ttf", 28)
        label_font = ImageFont.truetype("arial.ttf", 20)
    except OSError:
        title_font = ImageFont.load_default()
        label_font = ImageFont.load_default()

    cell_size = 384
    render_size = 330
    header_height = 56
    preview_output = ROOT / "tmp" / "accessory_per_pet"
    preview_output.mkdir(parents=True, exist_ok=True)

    for prefix in prefixes:
        preview = Image.new(
            "RGBA",
            (cell_size * 5, header_height + cell_size * 4),
            (238, 244, 242, 255),
        )
        draw = ImageDraw.Draw(preview)
        draw.text((16, 12), prefix, fill=(24, 45, 43, 255), font=title_font)
        for body_index, outfit_id in enumerate((None, "outfit_cape")):
            body_path = (
                OUTPUT / f"{prefix}_adult.png"
                if outfit_id is None
                else OUTPUT / "fitted" / f"{prefix}_{outfit_id}.png"
            )
            body = Image.open(body_path).convert("RGBA")
            for category_index, accessory_ids in enumerate((hats, glasses)):
                row = body_index * 2 + category_index
                for column, item_id in enumerate(accessory_ids):
                    composition = body.copy()
                    accessory = Image.open(
                        OUTPUT
                        / "fitted_accessories"
                        / f"{prefix}_{item_id}.png"
                    ).convert("RGBA")
                    composition.alpha_composite(accessory)
                    accessory.close()
                    composition.thumbnail(
                        (render_size, render_size),
                        Image.Resampling.LANCZOS,
                    )
                    cell_x = column * cell_size
                    cell_y = header_height + row * cell_size
                    preview.alpha_composite(
                        composition,
                        (
                            cell_x + (cell_size - composition.width) // 2,
                            cell_y + 6,
                        ),
                    )
                    state = "normal" if outfit_id is None else "cape"
                    label = f"{state} · {item_id}"
                    label_box = draw.textbbox((0, 0), label, font=label_font)
                    label_width = label_box[2] - label_box[0]
                    draw.text(
                        (
                            cell_x + (cell_size - label_width) // 2,
                            cell_y + cell_size - 40,
                        ),
                        label,
                        fill=(24, 45, 43, 255),
                        font=label_font,
                    )
                    composition.close()
            body.close()
        preview.save(preview_output / f"{prefix}.png", optimize=True)
        preview.close()


def generate_head_landmark_reference() -> None:
    """Render adult heads with coordinates for deterministic accessory fitting."""
    columns = 4
    rows = 3
    grid = Image.new(
        "RGBA",
        (CANVAS_SIZE * columns, CANVAS_SIZE * rows),
        (238, 244, 242, 255),
    )
    for index, prefix in enumerate(ADULT_PETS):
        row, column = divmod(index, columns)
        pet = Image.open(OUTPUT / f"{prefix}_adult.png").convert("RGBA")
        cell = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (238, 244, 242, 255))
        cell.alpha_composite(pet)
        draw = ImageDraw.Draw(cell)
        for coordinate in range(20, 241, 20):
            draw.line((0, coordinate, CANVAS_SIZE, coordinate), fill=(0, 96, 88, 110), width=1)
            draw.text((4, coordinate + 2), str(coordinate), fill=(0, 70, 65, 255))
        draw.line((256, 0, 256, 240), fill=(190, 35, 35, 150), width=1)
        draw.text((8, 8), prefix, fill=(24, 45, 43, 255))
        grid.alpha_composite(cell, (column * CANVAS_SIZE, row * CANVAS_SIZE))
        pet.close()
        cell.close()
    preview_path = ROOT / "tmp" / "head_landmark_reference.png"
    preview_path.parent.mkdir(parents=True, exist_ok=True)
    grid.save(preview_path, optimize=True)
    grid.close()


def generate_adult_reference_grid() -> None:
    """Build the fixed 4x3 reference grid used for outfit image edits."""
    pets = tuple(f"{prefix}_adult" for prefix in ADULT_PETS)
    grid_size = 1024
    cell_size = 256
    top = 128
    key_color = (255, 0, 255, 255)
    grid = Image.new("RGBA", (grid_size, grid_size), key_color)
    for index, pet_name in enumerate(pets):
        row, column = divmod(index, 4)
        pet = Image.open(OUTPUT / f"{pet_name}.png").convert("RGBA")
        pet_crop = visible_crop(pet, pet_name)
        scale = min(224 / pet_crop.height, 230 / pet_crop.width)
        pet_crop = pet_crop.resize(
            (round(pet_crop.width * scale), round(pet_crop.height * scale)),
            Image.Resampling.LANCZOS,
        )
        cell_x = column * cell_size
        cell_y = top + row * cell_size
        x = cell_x + (cell_size - pet_crop.width) // 2
        y = cell_y + cell_size - 12 - pet_crop.height
        grid.alpha_composite(pet_crop, (x, y))
        pet.close()
    output = ROOT / "tmp" / "adult_pet_reference_grid.png"
    output.parent.mkdir(parents=True, exist_ok=True)
    grid.convert("RGB").save(output, optimize=True)
    grid.close()


def generate_doctor_who_preview() -> None:
    """Render the complete code-only set on every adult pet for visual QA."""
    grid = Image.new("RGBA", (2048, 1536), (238, 244, 242, 255))
    for index, prefix in enumerate(ADULT_PETS):
        row, column = divmod(index, 4)
        composition = Image.open(
            OUTPUT / "fitted" / f"{prefix}_doctor_outfit.png"
        ).convert("RGBA")
        for item_id in ("doctor_bow_tie", "doctor_hat_fezz"):
            accessory = Image.open(
                OUTPUT / "fitted_accessories" / f"{prefix}_{item_id}.png"
            ).convert("RGBA")
            composition.alpha_composite(accessory)
            accessory.close()
        toy = Image.open(OUTPUT / "doctor_tardis_toy.png").convert("RGBA")
        composition.alpha_composite(toy)
        toy.close()
        grid.alpha_composite(composition, (column * CANVAS_SIZE, row * CANVAS_SIZE))
        composition.close()
    output = ROOT / "tmp" / "doctor_who_preview.png"
    output.parent.mkdir(parents=True, exist_ok=True)
    grid.save(output, optimize=True)
    grid.close()


def generate_growth_reference_grid() -> None:
    """Show every stage on the same fixed canvas with centre/ground guides."""
    prefixes = ADULT_PETS
    cell_width = 210
    cell_height = 205
    label_width = 190
    grid = Image.new(
        "RGBA",
        (label_width + len(STAGES) * cell_width, 35 + len(prefixes) * cell_height),
        (242, 247, 246, 255),
    )
    draw = ImageDraw.Draw(grid)
    for index, stage in enumerate(STAGES):
        draw.text((label_width + index * cell_width + 75, 10), stage, fill=(0, 60, 64))
    for row, prefix in enumerate(prefixes):
        top = 35 + row * cell_height
        draw.text((8, top + 90), prefix, fill=(0, 45, 48))
        for column, stage in enumerate(STAGES):
            left = label_width + column * cell_width
            draw.rectangle(
                (left + 5, top + 5, left + 195, top + 195),
                fill=(220, 237, 234, 255),
                outline=(80, 115, 112, 255),
            )
            draw.line((left + 100, top + 5, left + 100, top + 195), fill=(0, 140, 130, 100))
            ground_y = top + 5 + round(484 / CANVAS_SIZE * 190)
            draw.line((left + 5, ground_y, left + 195, ground_y), fill=(190, 70, 55, 180))
            pet = Image.open(OUTPUT / f"{prefix}_{stage}.png").convert("RGBA")
            pet = pet.resize((190, 190), Image.Resampling.LANCZOS)
            grid.alpha_composite(pet, (left + 5, top + 5))
            pet.close()
    output = ROOT / "tmp" / "pet_growth_reference_grid.png"
    output.parent.mkdir(parents=True, exist_ok=True)
    grid.convert("RGB").save(output, optimize=True)
    grid.close()


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    normalize_growth_sheets()
    normalize_accessories()
    normalize_doctor_items()
    normalize_dressed_pets()
    normalize_fitted_head_accessories()
    normalize_fitted_neckwear()
    generate_launcher_icons()
    generate_fit_preview()
    generate_accessory_fit_preview()
    generate_accessory_fit_preview(outfit_id="outfit_cape")
    generate_per_pet_accessory_previews()
    generate_adult_reference_grid()
    generate_doctor_who_preview()
    generate_growth_reference_grid()


if __name__ == "__main__":
    main()
