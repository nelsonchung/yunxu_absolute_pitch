#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE_CANDIDATES = [
    ROOT / "assets/icon/app_icon_yunxu_1024.png",
    ROOT / "assets/icon/app_icon_yunxu_1024.png.png",
    ROOT / "assets/icon/app_icon_yunxu_1024拷貝.png.png",
    ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png",
    ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png",
]
OUTPUT = ROOT / "assets/icon/app_icon_yunxu_1024.png"

OLD_TOP = (150, 192, 215)
OLD_BOTTOM = (87, 96, 102)
OLD_TEXT = (59, 62, 69)

NEW_TOP = (255, 244, 222)
NEW_BOTTOM = (12, 122, 107)
NEW_TEXT = (32, 49, 58)
NEW_MONOGRAM = (255, 250, 242)

SUPERSAMPLE = 4


def color_distance(left: tuple[int, int, int], right: tuple[int, int, int]) -> int:
    return sum((l - r) ** 2 for l, r in zip(left, right))


def split_line_y(x: int) -> float:
    return 420 - (x * 0.25)


def resolve_source() -> Path:
    for candidate in SOURCE_CANDIDATES:
        if candidate.exists():
            return candidate
    raise FileNotFoundError("Could not find a source icon to rebuild from.")


def build_base() -> Image.Image:
    source = Image.open(resolve_source()).convert("RGBA")
    pixels = source.load()
    result = Image.new("RGBA", source.size)
    output = result.load()

    for y in range(source.height):
        for x in range(source.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                output[x, y] = (0, 0, 0, 0)
                continue

            rgb = (r, g, b)
            top_distance = color_distance(rgb, OLD_TOP)
            bottom_distance = color_distance(rgb, OLD_BOTTOM)
            text_distance = color_distance(rgb, OLD_TEXT)

            if y < 340 and text_distance < min(top_distance, bottom_distance) * 0.95:
                mapped = NEW_TEXT
            elif y <= split_line_y(x) + 3 and top_distance <= bottom_distance:
                mapped = NEW_TOP
            else:
                mapped = NEW_BOTTOM

            output[x, y] = (*mapped, a)

    return result


def draw_yel(size: int) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)

    scale = size / 1024
    stroke = round(64 * scale)
    joint_radius = stroke // 2
    color = (*NEW_MONOGRAM, 255)
    glyph_top = 440
    glyph_bottom = 875
    l_top = 404
    y_top = 440
    y_join = 605

    def point(x: float, y: float) -> tuple[int, int]:
        return round(x * scale), round(y * scale)

    def dot(x: float, y: float) -> None:
        cx, cy = point(x, y)
        draw.ellipse(
            [
                cx - joint_radius,
                cy - joint_radius,
                cx + joint_radius,
                cy + joint_radius,
            ],
            fill=color,
        )

    # Rounded, monoline forms keep the original lower-mark feel while adding E.
    draw.line(
        [point(145, y_top), point(265, y_join), point(265, glyph_bottom)],
        fill=color,
        width=stroke,
        joint="curve",
    )
    draw.line(
        [point(385, y_top), point(265, y_join)],
        fill=color,
        width=stroke,
        joint="curve",
    )

    draw.line(
        [point(468, glyph_top), point(468, glyph_bottom)],
        fill=color,
        width=stroke,
    )
    draw.line(
        [point(468, glyph_top), point(620, glyph_top)],
        fill=color,
        width=stroke,
    )
    draw.line(
        [point(468, 658), point(590, 658)],
        fill=color,
        width=stroke,
    )
    draw.line(
        [point(468, glyph_bottom), point(620, glyph_bottom)],
        fill=color,
        width=stroke,
    )
    dot(468, glyph_top)
    dot(468, 658)
    dot(468, glyph_bottom)

    draw.line(
        [point(735, l_top), point(735, glyph_bottom), point(902, glyph_bottom)],
        fill=color,
        width=stroke,
        joint="curve",
    )

    return canvas


def render_icon() -> Image.Image:
    base = build_base()
    monogram = draw_yel(1024 * SUPERSAMPLE).resize(
        (1024, 1024),
        Image.Resampling.LANCZOS,
    )
    return Image.alpha_composite(base, monogram)


def main() -> None:
    icon = render_icon()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    icon.save(OUTPUT, format="PNG")
    print(f"Rendered brand icon to {OUTPUT}")


if __name__ == "__main__":
    main()
