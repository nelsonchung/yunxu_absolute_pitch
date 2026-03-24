#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = ROOT / "assets/icon/app_icon_yunxu_1024.png"


IOS_SIZES = {
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png": 20,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png": 40,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png": 60,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png": 29,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png": 58,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png": 87,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png": 40,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png": 80,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png": 120,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png": 120,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png": 180,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png": 76,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png": 152,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png": 167,
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png": 1024,
}

MACOS_SIZES = {
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png": 16,
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png": 32,
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png": 64,
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png": 128,
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png": 256,
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png": 512,
    "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png": 1024,
}

ANDROID_SIZES = {
    "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": 48,
    "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": 72,
    "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": 96,
    "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": 144,
    "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": 192,
}

WEB_SIZES = {
    "web/icons/Icon-192.png": 192,
    "web/icons/Icon-512.png": 512,
    "web/icons/Icon-maskable-192.png": 192,
    "web/icons/Icon-maskable-512.png": 512,
    "web/favicon.png": 64,
}

WINDOWS_ICON = ROOT / "windows/runner/resources/app_icon.ico"
WINDOWS_ICO_SIZES = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate all platform launcher icons from the master 1024x1024 PNG.",
    )
    parser.add_argument(
        "--source",
        type=Path,
        default=DEFAULT_SOURCE,
        help="Path to the square source PNG. Defaults to assets/icon/app_icon_yunxu_1024.png",
    )
    return parser.parse_args()


def load_source(path: Path) -> Image.Image:
    resolved = path if path.is_absolute() else ROOT / path
    image = Image.open(resolved).convert("RGB")
    if image.width != image.height:
        raise ValueError(f"Source image must be square, got {image.width}x{image.height}")
    return image


def save_png(image: Image.Image, relative_path: str, size: int) -> None:
    target = ROOT / relative_path
    target.parent.mkdir(parents=True, exist_ok=True)
    resized = image.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(target, format="PNG")


def generate_png_sets(image: Image.Image) -> None:
    for relative_path, size in {
        **IOS_SIZES,
        **MACOS_SIZES,
        **ANDROID_SIZES,
        **WEB_SIZES,
    }.items():
        save_png(image, relative_path, size)


def generate_windows_ico(image: Image.Image) -> None:
    WINDOWS_ICON.parent.mkdir(parents=True, exist_ok=True)
    image.save(WINDOWS_ICON, format="ICO", sizes=WINDOWS_ICO_SIZES)


def main() -> None:
    args = parse_args()
    source = load_source(args.source)
    generate_png_sets(source)
    generate_windows_ico(source)
    print(f"Generated app icons from {args.source}")


if __name__ == "__main__":
    main()
