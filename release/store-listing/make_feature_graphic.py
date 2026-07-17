from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

WIDTH, HEIGHT = 1024, 500
ROOT = Path(__file__).resolve().parents[3]
FONT_DIR = ROOT / "PlaceWellPdfGenerator" / "placewell_generator" / "fonts"
OUT = Path(__file__).with_name("play-feature-graphic.png")

BLUE_GRAY = (184, 200, 216)
CREAM = (248, 244, 235)
NAVY = "#243040"
AMBER = "#C9A66B"
INK_MUTED = "#6E7781"


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_DIR / name), size)


def text_width(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.FreeTypeFont) -> int:
    bbox = draw.textbbox((0, 0), text, font=fnt)
    return bbox[2] - bbox[0]


def make_gradient() -> Image.Image:
    img = Image.new("RGB", (WIDTH, HEIGHT), CREAM)
    px = img.load()
    for x in range(WIDTH):
        t = x / (WIDTH - 1)
        for y in range(HEIGHT):
            v = (x * 0.72 + y * 0.28) / (WIDTH * 0.72 + HEIGHT * 0.28)
            blend = min(1, max(0, v * 1.08))
            color = tuple(round(BLUE_GRAY[i] * (1 - blend) + CREAM[i] * blend) for i in range(3))
            px[x, y] = color
    return img


def draw_wordmark(draw: ImageDraw.ImageDraw) -> None:
    word_font = font("CormorantGaramond-SemiBold.ttf", 112)
    text = "PlaceWell"
    total = text_width(draw, text, word_font)
    x = (WIDTH - total) // 2
    y = 124
    for ch in text:
        fill = AMBER if ch == "W" else NAVY
        draw.text((x, y), ch, font=word_font, fill=fill)
        x += text_width(draw, ch, word_font)


def main() -> None:
    img = make_gradient().convert("RGBA")
    draw = ImageDraw.Draw(img)

    # Soft porcelain card glow.
    card = Image.new("RGBA", (760, 300), (255, 255, 255, 86))
    mask = Image.new("L", card.size, 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle((0, 0, card.size[0] - 1, card.size[1] - 1), radius=46, fill=210)
    img.alpha_composite(card, ((WIDTH - card.size[0]) // 2, 92))

    draw = ImageDraw.Draw(img)
    draw_wordmark(draw)

    tagline_font = font("LibreBaskerville-Italic.ttf", 34)
    tagline = "Everything in its place, done well."
    tw = text_width(draw, tagline, tagline_font)
    draw.text(((WIDTH - tw) // 2, 268), tagline, font=tagline_font, fill=NAVY)

    sub_font = font("Jost-Regular.ttf", 24)
    sub = "QR-coded labels + a calm companion app"
    sw = text_width(draw, sub, sub_font)
    draw.text(((WIDTH - sw) // 2, 336), sub, font=sub_font, fill=INK_MUTED)

    # Minimal amber QR-label motif.
    label_x, label_y = 822, 350
    draw.rounded_rectangle((label_x, label_y, label_x + 92, label_y + 58), radius=14, fill=(255, 255, 255, 150), outline=AMBER, width=2)
    for i in range(3):
        for j in range(3):
            if (i, j) != (1, 1):
                draw.rectangle((label_x + 18 + i * 14, label_y + 14 + j * 10, label_x + 25 + i * 14, label_y + 21 + j * 10), fill=NAVY)

    img = img.convert("RGB")
    img.save(OUT)

    with Image.open(OUT) as check:
        if check.size != (WIDTH, HEIGHT):
            raise SystemExit(f"Unexpected size: {check.size}")
    print(f"Saved {OUT} at {WIDTH}x{HEIGHT}")


if __name__ == "__main__":
    main()
