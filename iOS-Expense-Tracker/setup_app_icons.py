#!/usr/bin/env python3
from __future__ import annotations

import json
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print(
        "ERROR: Pillow is required to validate and derive icon sizes. "
        "Install it with: python3 -m pip install Pillow",
        file=sys.stderr,
    )
    raise SystemExit(1)


ROOT = Path(__file__).resolve().parent
LOGO_DIR = ROOT / "logo"
APPICON_DIR = ROOT / "Assets.xcassets" / "AppIcon.appiconset"


@dataclass(frozen=True)
class IconSlot:
    idiom: str
    size: str
    scale: str
    pixels: int
    filename: str


ICON_SLOTS = [
    IconSlot("iphone", "20x20", "2x", 40, "AppIcon-20@2x.png"),
    IconSlot("iphone", "20x20", "3x", 60, "AppIcon-20@3x.png"),
    IconSlot("iphone", "29x29", "2x", 58, "AppIcon-29@2x.png"),
    IconSlot("iphone", "29x29", "3x", 87, "AppIcon-29@3x.png"),
    IconSlot("iphone", "40x40", "2x", 80, "AppIcon-40@2x.png"),
    IconSlot("iphone", "40x40", "3x", 120, "AppIcon-40@3x.png"),
    IconSlot("iphone", "60x60", "2x", 120, "AppIcon-60@2x.png"),
    IconSlot("iphone", "60x60", "3x", 180, "AppIcon-60@3x.png"),
    IconSlot("ipad", "20x20", "1x", 20, "AppIcon-iPad-20@1x.png"),
    IconSlot("ipad", "20x20", "2x", 40, "AppIcon-iPad-20@2x.png"),
    IconSlot("ipad", "29x29", "1x", 29, "AppIcon-iPad-29@1x.png"),
    IconSlot("ipad", "29x29", "2x", 58, "AppIcon-iPad-29@2x.png"),
    IconSlot("ipad", "40x40", "1x", 40, "AppIcon-iPad-40@1x.png"),
    IconSlot("ipad", "40x40", "2x", 80, "AppIcon-iPad-40@2x.png"),
    IconSlot("ipad", "76x76", "1x", 76, "AppIcon-iPad-76@1x.png"),
    IconSlot("ipad", "76x76", "2x", 152, "AppIcon-iPad-76@2x.png"),
    IconSlot("ipad", "83.5x83.5", "2x", 167, "AppIcon-iPad-83.5@2x.png"),
    IconSlot("ios-marketing", "1024x1024", "1x", 1024, "AppIcon-1024.png"),
]

REQUIRED_SOURCE_SIZES = {58, 60, 80, 87, 120, 180}


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def read_square_png_size(path: Path) -> int:
    try:
        with Image.open(path) as image:
            width, height = image.size
            fmt = image.format
    except Exception as exc:
        fail(f"Unable to read PNG '{path.name}': {exc}")

    if fmt != "PNG":
        fail(f"'{path.name}' is not a PNG file.")
    if width != height:
        fail(f"'{path.name}' must be square, got {width}x{height}.")
    return width


def discover_source_icons() -> dict[int, Path]:
    if not LOGO_DIR.exists():
        fail(f"Missing logo directory: {LOGO_DIR}")
    if not LOGO_DIR.is_dir():
        fail(f"Logo path is not a directory: {LOGO_DIR}")

    png_files = sorted(LOGO_DIR.glob("*.png"))
    if not png_files:
        fail(f"No PNG files found in: {LOGO_DIR}")

    icons_by_size: dict[int, Path] = {}
    duplicate_sizes: dict[int, list[str]] = {}

    for png in png_files:
        size = read_square_png_size(png)
        if size in icons_by_size:
            duplicate_sizes.setdefault(size, [icons_by_size[size].name]).append(png.name)
            continue
        icons_by_size[size] = png

    if duplicate_sizes:
        details = "; ".join(
            f"{size}px: {', '.join(names)}"
            for size, names in sorted(duplicate_sizes.items())
        )
        fail(f"Duplicate icon sizes found. Keep one PNG per size. {details}")

    missing = sorted(REQUIRED_SOURCE_SIZES.difference(icons_by_size))
    if missing:
        fail(f"Missing required logo PNG sizes: {', '.join(f'{size}x{size}' for size in missing)}")

    return icons_by_size


def prepare_appicon_dir() -> None:
    if APPICON_DIR.exists():
        shutil.rmtree(APPICON_DIR)
    APPICON_DIR.mkdir(parents=True, exist_ok=True)


def source_for_size(size: int, icons_by_size: dict[int, Path]) -> Path:
    if size in icons_by_size:
        return icons_by_size[size]

    larger_sources = [source_size for source_size in icons_by_size if source_size > size]
    if larger_sources:
        return icons_by_size[min(larger_sources)]

    return icons_by_size[max(icons_by_size)]


def write_icon(slot: IconSlot, icons_by_size: dict[int, Path]) -> None:
    destination = APPICON_DIR / slot.filename
    source = source_for_size(slot.pixels, icons_by_size)
    source_size = read_square_png_size(source)

    if source_size == slot.pixels:
        shutil.copy2(source, destination)
        return

    with Image.open(source) as image:
        image = image.convert("RGBA")
        resized = image.resize((slot.pixels, slot.pixels), Image.Resampling.LANCZOS)
        resized.save(destination, "PNG")


def validate_generated_icons() -> None:
    for slot in ICON_SLOTS:
        path = APPICON_DIR / slot.filename
        if not path.exists():
            fail(f"Generated icon is missing: {slot.filename}")
        actual_size = read_square_png_size(path)
        if actual_size != slot.pixels:
            fail(f"{slot.filename} should be {slot.pixels}x{slot.pixels}, got {actual_size}x{actual_size}.")


def write_contents_json() -> None:
    images = [
        {
            "idiom": slot.idiom,
            "size": slot.size,
            "scale": slot.scale,
            "filename": slot.filename,
        }
        for slot in ICON_SLOTS
    ]
    contents = {
        "images": images,
        "info": {
            "author": "xcode",
            "version": 1,
        },
    }

    (APPICON_DIR / "Contents.json").write_text(
        json.dumps(contents, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    icons_by_size = discover_source_icons()
    prepare_appicon_dir()

    for slot in ICON_SLOTS:
        write_icon(slot, icons_by_size)

    validate_generated_icons()
    write_contents_json()

    print(f"App icons generated successfully: {APPICON_DIR}")
    print("Source sizes:", ", ".join(f"{size}x{size}" for size in sorted(icons_by_size)))
    print(f"Generated files: {len(ICON_SLOTS)} icons + Contents.json")


if __name__ == "__main__":
    main()
