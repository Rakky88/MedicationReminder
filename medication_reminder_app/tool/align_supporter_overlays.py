"""Align generated supporter cutouts to the existing 512px cat overlays."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "cats"
SOURCES = ROOT / "tmp" / "imagegen"
PAIRS = {
    "hat": "shop_hat_crown.png",
    "glasses": "shop_glasses_star.png",
    "outfit": "shop_outfit_cape.png",
    "toy": "shop_toy_teddy.png",
}


def main() -> None:
    for kind, reference_name in PAIRS.items():
        reference = Image.open(ASSETS / reference_name).convert("RGBA")
        generated_source = SOURCES / f"supporter_{kind}_cutout.png"
        if not generated_source.exists():
            generated_source = ASSETS / f"supporter_{kind}.png"
        generated = Image.open(generated_source).convert("RGBA")
        reference_box = reference.getchannel("A").getbbox()
        generated_box = generated.getchannel("A").getbbox()
        if reference_box is None or generated_box is None:
            raise RuntimeError(f"Missing visible pixels for {kind}")
        subject = generated.crop(generated_box)
        left, top, right, bottom = reference_box
        width, height = right - left, bottom - top
        if kind == "toy":
            ratio = min(width / subject.width, height / subject.height)
            size = (round(subject.width * ratio), round(subject.height * ratio))
            subject = subject.resize(size, Image.Resampling.LANCZOS)
            position = (left + (width - size[0]) // 2, bottom - size[1])
        else:
            subject = subject.resize((width, height), Image.Resampling.LANCZOS)
            position = (left, top)
        output = Image.new("RGBA", reference.size, (0, 0, 0, 0))
        output.alpha_composite(subject, position)
        alpha = output.getchannel("A")
        if alpha.getpixel((0, 0)) or alpha.getpixel((511, 511)):
            raise RuntimeError(f"Non-transparent corner in {kind}")
        opaque_colors = [
            color for color in output.get_flattened_data() if color[3] > 32
        ]
        if any(
            red > 225 and blue > 200 and green < 70
            for red, green, blue, _ in opaque_colors
        ):
            raise RuntimeError(f"Chroma spill remains in {kind}")
        output.save(ASSETS / f"supporter_{kind}.png", optimize=True)
        print(kind, output.size, alpha.getbbox())

    preview = Image.open(ASSETS / "cat_tuxedo_adult.png").convert("RGBA")
    for kind in ("outfit", "hat", "glasses", "toy"):
        preview.alpha_composite(
            Image.open(ASSETS / f"supporter_{kind}.png").convert("RGBA")
        )
    SOURCES.mkdir(parents=True, exist_ok=True)
    preview.save(SOURCES / "supporter_preview.png", optimize=True)


if __name__ == "__main__":
    main()
