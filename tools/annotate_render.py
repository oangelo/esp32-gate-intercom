#!/usr/bin/env python3
"""Label the internal volumes in a case render, so a picture explains itself.

The render draws the shell as a ghost (%) and the internal volumes in flat colours that come from
`ghosts()` in cad/case.scad. This script finds each volume by HUE (not by RGB distance: orange and
gold are neighbours and a distance threshold mixes them up) and writes a labelled copy.

Usage:
    annotate_render.py <in.png> <out.png> --view parts   # board, speaker, buck
    annotate_render.py <in.png> <out.png> --view puck    # the whole Waveshare as one cylinder

The label text is the measured size of the volume, taken from docs/dimensions.md, so a stale label is
a visible contradiction instead of a silent lie.
"""
import argparse

import numpy as np
from PIL import Image, ImageDraw, ImageFont

# (hue low, hue high, label) per view. Hues are degrees; the shell is a desaturated grey and the
# background is nearly white, so a saturation floor alone separates them from any volume.
VIEWS = {
    "unit": [
        (45, 70, "WAVESHARE ASSEMBLED: O58 x 47.00, screwed as one"),
    ],
    "section": [
        (45, 70, "WAVESHARE ASSEMBLED: O58 x 47.00, held between seat and pads"),
    ],
    "parts": [
        (95, 165, "PCB: bare board, 57.63 x 1.20 (rejected layout)"),
        (20, 44, "SPEAKER: SPK-4020-5W, O43.30 x 20.50 (rejected layout)"),
    ],
}


def hue_mask(img, h0, h1, smin=0.45, vmin=0.20):
    a = np.asarray(img.convert("RGB")).astype(float) / 255.0
    mx, mn = a.max(axis=2), a.min(axis=2)
    s = (mx - mn) / np.maximum(mx, 1e-6)
    r, g, b = a[:, :, 0], a[:, :, 1], a[:, :, 2]
    d = np.maximum(mx - mn, 1e-6)
    h = np.zeros_like(mx)
    h = np.where(mx == r, ((g - b) / d) % 6, h)
    h = np.where(mx == g, (b - r) / d + 2, h)
    h = np.where(mx == b, (r - g) / d + 4, h)
    h = h * 60.0
    return (h >= h0) & (h <= h1) & (s >= smin) & (mx >= vmin)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--view", choices=sorted(VIEWS), required=True)
    ap.add_argument("--min-px", type=int, default=200)
    args = ap.parse_args()

    img = Image.open(args.src).convert("RGB")
    draw = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype("/usr/share/fonts/TTF/DejaVuSans-Bold.ttf", 24)
    except OSError:
        font = ImageFont.load_default()

    for h0, h1, label in VIEWS[args.view]:
        mask = hue_mask(img, h0, h1)
        n = int(mask.sum())
        if n < args.min_px:
            print(f"  not found ({n} px): {label}")
            continue
        ys, xs = np.nonzero(mask)
        x0, y0, x1, y1 = int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())
        cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
        ly = y0 - 40 if y0 > 70 else y1 + 16
        lx = max(12, min(img.width - 20 - 13 * len(label), x0 - 40))
        draw.line([(lx + 8, ly + 30), (cx, cy)], fill=(255, 255, 255), width=5)
        draw.line([(lx + 8, ly + 30), (cx, cy)], fill=(20, 20, 20), width=2)
        draw.rectangle([lx - 8, ly - 8, lx + 16 + 13 * len(label), ly + 38],
                       fill=(255, 255, 255), outline=(20, 20, 20), width=2)
        draw.text((lx, ly), label, fill=(20, 20, 20), font=font)
        print(f"  {label:<48} {n:>7} px  box x{x0}-{x1} y{y0}-{y1}")

    img.save(args.dst)
    print(f"  wrote {args.dst}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
