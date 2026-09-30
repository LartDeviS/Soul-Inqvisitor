#!/usr/bin/env python3
"""Generate black + red-gold SI launcher icons for Android mipmap folders."""

from PIL import Image, ImageDraw, ImageFont
import os

ROOT = os.path.dirname(os.path.abspath(__file__))
RES = os.path.join(ROOT, "android", "app", "src", "main", "res")

SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

def find_font(size: int):
    candidates = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
        "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "C:/Windows/Fonts/arialbd.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()

def make_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)

    # thin red ring
    m = max(2, size // 12)
    w = max(2, size // 36)
    draw.ellipse([m, m, size - m - 1, size - m - 1], outline=(139, 0, 0, 220), width=w)

    font = find_font(int(size * 0.42))
    text = "SI"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (size - tw) / 2 - bbox[0]
    y = (size - th) / 2 - bbox[1] - size * 0.02

    scale = max(1, size // 96)
    # red outline
    for ox, oy in [(-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, 1), (-1, 1), (1, -1)]:
        draw.text((x + ox * scale, y + oy * scale), text, font=font, fill=(178, 34, 34, 255))
    # gold fill
    draw.text((x, y), text, font=font, fill=(255, 215, 0, 255))
    return img

def main():
    if not os.path.isdir(RES):
        print(f"ERROR: not found: {RES}")
        print("Run this script from the project root (where android/ is).")
        return

    for folder, size in SIZES.items():
        out_dir = os.path.join(RES, folder)
        os.makedirs(out_dir, exist_ok=True)
        icon = make_icon(size)
        for name in ("ic_launcher.png", "ic_launcher_round.png"):
            path = os.path.join(out_dir, name)
            icon.save(path, "PNG")
            print(f"OK  {folder}/{name}  ({size}x{size})")

    # adaptive foreground (optional but useful)
    drawable = os.path.join(RES, "drawable")
    os.makedirs(drawable, exist_ok=True)
    fg = make_icon(432)
    fg_path = os.path.join(drawable, "ic_launcher_foreground.png")
    fg.save(fg_path, "PNG")
    print(f"OK  drawable/ic_launcher_foreground.png")

    bg_xml = os.path.join(drawable, "ic_launcher_background.xml")
    with open(bg_xml, "w", encoding="utf-8") as f:
        f.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<shape xmlns:android="http://schemas.android.com/apk/res/android" '
            'android:shape="rectangle">\n'
            '    <solid android:color="#000000"/>\n'
            "</shape>\n"
        )
    print("OK  drawable/ic_launcher_background.xml")

    anydpi = os.path.join(RES, "mipmap-anydpi-v26")
    os.makedirs(anydpi, exist_ok=True)
    adaptive = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@drawable/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@drawable/ic_launcher_foreground"/>\n'
        "</adaptive-icon>\n"
    )
    for name in ("ic_launcher.xml", "ic_launcher_round.xml"):
        path = os.path.join(anydpi, name)
        with open(path, "w", encoding="utf-8") as f:
            f.write(adaptive)
        print(f"OK  mipmap-anydpi-v26/{name}")

    print("\nDone. Commit, push, rebuild APK.")
    print("Uninstall old app on the phone so the icon cache refreshes.")

if __name__ == "__main__":
    main()
