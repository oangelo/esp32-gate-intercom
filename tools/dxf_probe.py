#!/usr/bin/env python3
"""Measure a DXF mechanical drawing: outline extents, holes and text callouts.

Written for the Waveshare ESP32-S3-AUDIO-Board drawing, but generic: it reads the
group-code pairs of an ASCII DXF (AutoCAD R14+) and reports what a case designer
needs, without trusting a rendered image or a vision model.

Usage:
    dxf_probe.py <file.dxf> [--top N] [--text]

Output:
    - overall extents in drawing units (mm for this drawing) and the resulting size
    - every profile (closed polyline) with its bounding box, largest first
    - every CIRCLE grouped by diameter, with centres
    - with --text: all TEXT/MTEXT strings with their insertion points
"""
import argparse
import collections
import re
import sys


def pairs(path):
    """Yield (code, value) group pairs from a DXF, tolerating a non-UTF8 codepage."""
    with open(path, "rb") as fh:
        raw = fh.read()
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        text = raw.decode("gbk", errors="replace")
    lines = text.replace("\r\n", "\n").split("\n")
    i = 0
    while i + 1 < len(lines):
        code = lines[i].strip()
        if re.fullmatch(r"-?\d+", code):
            yield int(code), lines[i + 1].strip()
            i += 2
        else:
            i += 1


def collect(path):
    """Return [(entity_type, [(code, value), ...]), ...] for the ENTITIES section."""
    ents, cur, cur_type, in_entities, pending = [], [], None, False, False
    for code, value in pairs(path):
        if code == 0 and value == "SECTION":
            pending = True
            continue
        if pending and code == 2:
            in_entities = value == "ENTITIES"
            pending = False
            continue
        if code == 0 and value == "ENDSEC":
            if in_entities and cur:
                ents.append((cur_type, cur))
            cur, cur_type, in_entities = [], None, False
            continue
        if not in_entities:
            continue
        if code == 0:
            if cur:
                ents.append((cur_type, cur))
            cur_type, cur = value, []
        else:
            cur.append((code, value))
    if cur:
        ents.append((cur_type, cur))
    return ents


def first(ent, code):
    """First value for a group code in an entity payload [(code, value), ...]."""
    for c, v in ent:
        if c == code:
            return v
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dxf")
    ap.add_argument("--top", type=int, default=25)
    ap.add_argument("--text", action="store_true")
    args = ap.parse_args()

    ents = collect(args.dxf)
    counts = collections.Counter(t for t, _ in ents)
    print(f"entities: {sum(counts.values())}")
    print("types: " + ", ".join(f"{t}={n}" for t, n in counts.most_common(12)))

    xs, ys, circles, polys = [], [], [], []

    for typ, ent in ents:
        if typ == "LINE":
            for code, axis in ((10, xs), (11, xs), (20, ys), (21, ys)):
                v = first(ent, code)
                if v is not None:
                    axis.append(float(v))
        elif typ in ("LWPOLYLINE", "POLYLINE"):
            pts = []
            for code, v in ent:
                if code == 10:
                    pts.append([float(v), None])
                elif code == 20 and pts and pts[-1][1] is None:
                    pts[-1][1] = float(v)
            pts = [p for p in pts if p[1] is not None]
            if pts:
                px = [p[0] for p in pts]
                py = [p[1] for p in pts]
                xs += px
                ys += py
                polys.append((min(px), min(py), max(px), max(py), len(pts)))
        elif typ == "CIRCLE":
            cx, cy, r = first(ent, 10), first(ent, 20), first(ent, 40)
            if cx is not None and cy is not None and r is not None:
                cx, cy, r = float(cx), float(cy), float(r)
                xs += [cx - r, cx + r]
                ys += [cy - r, cy + r]
                circles.append((cx, cy, 2 * r))

    if xs and ys:
        print(f"extents: x {min(xs):8.2f} .. {max(xs):8.2f}   size {max(xs) - min(xs):7.2f}")
        print(f"         y {min(ys):8.2f} .. {max(ys):8.2f}   size {max(ys) - min(ys):7.2f}")

    if polys:
        print(f"\nprofiles (closed polylines), largest first, {len(polys)} total:")
        for p in sorted(polys, key=lambda p: -(p[2] - p[0]) * (p[3] - p[1]))[: args.top]:
            print(f"  bbox {p[0]:8.2f} {p[1]:8.2f} -> {p[2]:8.2f} {p[3]:8.2f}"
                  f"   size {p[2] - p[0]:7.2f} x {p[3] - p[1]:7.2f}   {p[4]:3d} pts")

    if circles:
        by_d = collections.defaultdict(list)
        for cx, cy, dia in circles:
            by_d[round(dia, 2)].append((round(cx, 2), round(cy, 2)))
        print(f"\ncircles: {len(circles)} total, {len(by_d)} distinct diameters")
        for dia in sorted(by_d, reverse=True)[: args.top]:
            pts = by_d[dia]
            shown = ", ".join(f"({x},{y})" for x, y in pts[:6])
            print(f"  d={dia:7.2f}  n={len(pts):3d}  {shown}{' ...' if len(pts) > 6 else ''}")

    if args.text:
        print("\ntext:")
        for typ, ent in ents:
            if typ in ("TEXT", "MTEXT"):
                s = first(ent, 1)
                if s:
                    print(f"  {s!r}  @ ({first(ent, 10)},{first(ent, 20)})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
