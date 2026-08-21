"""Generate the one-page PlaceWell customer app quick-start PDF."""

from io import BytesIO
from pathlib import Path

import qrcode
from reportlab.lib.colors import HexColor
from reportlab.lib.pagesizes import letter
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
FONT_DIR = WORKSPACE_ROOT / "PlaceWellPdfGenerator" / "placewell_generator" / "fonts"
APP_ICON = WORKSPACE_ROOT / "PlaceWellApp" / "assets" / "adaptive-icon.png"
OUTPUT = Path(__file__).resolve().parent / "PlaceWell_App_Quick_Start.pdf"

# Temporary until the iOS App Store listing is live. Replace with the final
# App Store URL and regenerate the PDF after Apple approval.
IOS_DOWNLOAD_URL = "https://placewell.app"
ANDROID_DOWNLOAD_URL = "https://play.google.com/store/apps/details?id=com.placewell.app"

INK = HexColor("#263244")
CHALK = HexColor("#F5F0E8")
WHITE = HexColor("#FFFFFF")
AMBER = HexColor("#C9A66B")
AMBER_DARK = HexColor("#A98245")
SAGE = HexColor("#8FAF8F")
STONE = HexColor("#64717D")
PALE_BLUE = HexColor("#EEF5F7")
LINE = HexColor("#DFE5E7")


def register_fonts():
    pdfmetrics.registerFont(TTFont("Cormorant", FONT_DIR / "CormorantGaramond-Regular.ttf"))
    pdfmetrics.registerFont(TTFont("CormorantSemi", FONT_DIR / "CormorantGaramond-SemiBold.ttf"))
    pdfmetrics.registerFont(TTFont("Jost", FONT_DIR / "Jost-Regular.ttf"))
    pdfmetrics.registerFont(TTFont("JostMedium", FONT_DIR / "Jost-Medium.ttf"))
    pdfmetrics.registerFont(TTFont("DMMono", FONT_DIR / "DMMono-Regular.ttf"))


def qr_image(url):
    qr = qrcode.QRCode(version=None, box_size=10, border=3)
    qr.add_data(url)
    qr.make(fit=True)
    image = qr.make_image(fill_color="#263244", back_color="white").convert("RGB")
    buffer = BytesIO()
    image.save(buffer, format="PNG")
    buffer.seek(0)
    return ImageReader(buffer)


def centered_text(pdf, text, x, y, width, font, size, color):
    pdf.setFont(font, size)
    pdf.setFillColor(color)
    pdf.drawCentredString(x + width / 2, y, text)


def draw_qr_card(pdf, x, y, width, height, title, subtitle, url):
    pdf.setFillColor(WHITE)
    pdf.setStrokeColor(LINE)
    pdf.setLineWidth(0.8)
    pdf.roundRect(x, y, width, height, 14, fill=1, stroke=1)

    qr_size = 96
    pdf.drawImage(
        qr_image(url),
        x + (width - qr_size) / 2,
        y + 55,
        qr_size,
        qr_size,
        preserveAspectRatio=True,
        mask="auto",
    )
    centered_text(pdf, title, x, y + 34, width, "JostMedium", 12, INK)
    centered_text(pdf, subtitle, x, y + 17, width, "Jost", 8.5, STONE)


def draw_step(pdf, number, title, body, x, y, width, height, accent):
    pdf.setFillColor(WHITE)
    pdf.setStrokeColor(LINE)
    pdf.setLineWidth(0.7)
    pdf.roundRect(x, y, width, height, 12, fill=1, stroke=1)

    badge_x = x + 26
    badge_y = y + height - 25
    pdf.setFillColor(accent)
    pdf.circle(badge_x, badge_y, 13, fill=1, stroke=0)
    pdf.setFont("DMMono", 10)
    pdf.setFillColor(WHITE)
    pdf.drawCentredString(badge_x, badge_y - 3.5, str(number))

    pdf.setFont("JostMedium", 12)
    pdf.setFillColor(INK)
    pdf.drawString(x + 48, y + height - 29, title)

    pdf.setFont("Jost", 9.2)
    pdf.setFillColor(STONE)
    text = pdf.beginText(x + 18, y + height - 52)
    text.setLeading(13)
    for line in body:
        text.textLine(line)
    pdf.drawText(text)


def build_pdf():
    register_fonts()
    width, height = letter
    pdf = canvas.Canvas(str(OUTPUT), pagesize=letter)
    pdf.setTitle("PlaceWell App Quick Start")
    pdf.setAuthor("PlaceWell by BeNiralu")

    pdf.setFillColor(CHALK)
    pdf.rect(0, 0, width, height, fill=1, stroke=0)

    pdf.setFillColor(PALE_BLUE)
    pdf.roundRect(28, height - 180, width - 56, 152, 20, fill=1, stroke=0)

    icon_size = 62
    pdf.drawImage(
        str(APP_ICON),
        52,
        height - 140,
        icon_size,
        icon_size,
        preserveAspectRatio=True,
        mask="auto",
    )

    pdf.setFont("CormorantSemi", 35)
    pdf.setFillColor(INK)
    pdf.drawString(130, height - 84, "Place")
    place_width = pdf.stringWidth("Place", "CormorantSemi", 35)
    pdf.setFillColor(AMBER)
    pdf.drawString(130 + place_width, height - 84, "Well")

    pdf.setFont("JostMedium", 13)
    pdf.setFillColor(INK)
    pdf.drawString(132, height - 108, "Smart labels. Simple setup.")

    pdf.setFont("Jost", 9.5)
    pdf.setFillColor(STONE)
    pdf.drawString(132, height - 127, "Download the app, load your label set, and start organizing.")

    pdf.setFillColor(AMBER)
    pdf.roundRect(width - 167, height - 158, 112, 30, 15, fill=1, stroke=0)
    centered_text(pdf, "QUICK START", width - 167, height - 147, 112, "DMMono", 9, WHITE)

    centered_text(pdf, "Download the PlaceWell app", 0, height - 211, width, "CormorantSemi", 22, INK)
    centered_text(
        pdf,
        "Scan the QR for your phone.",
        0,
        height - 230,
        width,
        "Jost",
        9.5,
        STONE,
    )

    card_width = 170
    card_height = 184
    gap = 22
    cards_x = (width - (card_width * 2 + gap)) / 2
    cards_y = height - 426
    draw_qr_card(
        pdf,
        cards_x,
        cards_y,
        card_width,
        card_height,
        "iPhone",
        "PlaceWell download page",
        IOS_DOWNLOAD_URL,
    )
    draw_qr_card(
        pdf,
        cards_x + card_width + gap,
        cards_y,
        card_width,
        card_height,
        "Android",
        "Get it on Google Play",
        ANDROID_DOWNLOAD_URL,
    )

    pdf.setFillColor(AMBER_DARK)
    pdf.setFont("JostMedium", 9.5)
    pdf.drawCentredString(
        width / 2,
        cards_y - 22,
        "Your package includes a separate Order QR - keep it nearby.",
    )

    centered_text(pdf, "Set up in four easy steps", 0, cards_y - 57, width, "CormorantSemi", 21, INK)

    margin = 46
    step_gap = 12
    step_width = (width - margin * 2 - step_gap) / 2
    step_height = 86
    row_one_y = cards_y - 161
    row_two_y = row_one_y - step_height - 12

    draw_step(
        pdf,
        1,
        "Download PlaceWell",
        ["Scan the QR above for your phone,", "then install and open the app."],
        margin,
        row_one_y,
        step_width,
        step_height,
        AMBER,
    )
    draw_step(
        pdf,
        2,
        "Load your label set",
        ["Tap the gold Scan button, allow camera", "access, and scan your included Order QR."],
        margin + step_width + step_gap,
        row_one_y,
        step_width,
        step_height,
        SAGE,
    )
    draw_step(
        pdf,
        3,
        "Set up your labels",
        ["Review the labels, choose their room and", "location, then tap Create Labels."],
        margin,
        row_two_y,
        step_width,
        step_height,
        SAGE,
    )
    draw_step(
        pdf,
        4,
        "Stick, scan, and organize",
        ["Apply each label. Scan it anytime to", "view or update what is stored there."],
        margin + step_width + step_gap,
        row_two_y,
        step_width,
        step_height,
        AMBER,
    )

    footer_y = 28
    pdf.setFillColor(INK)
    pdf.setFont("JostMedium", 9.5)
    pdf.drawCentredString(
        width / 2,
        footer_y + 18,
        "Keep your Order QR until your label set has been added successfully.",
    )
    pdf.setFont("DMMono", 7.5)
    pdf.setFillColor(STONE)
    pdf.drawCentredString(width / 2, footer_y, "PLACEWELL.APP  |  BY BENIRALU")

    pdf.save()
    print(OUTPUT)


if __name__ == "__main__":
    build_pdf()
