#!/usr/bin/env python3
"""Derive the 4.7" App Store set (750x1334) from the 6.9" store screenshots.

Why this exists: an iPhone SE / 6s (iOS 15) showed *no* screenshots on the
store page — the old App Store client never falls back to the 6.9" set, so the
listing needs its own 4.7" images. No simulator here can take them any more
(Xcode 27's iOS 27 runtime refuses every 4.7" device), so the 6.9" shots are
re-cut instead: the bezel is pure #212121, so dropping bands of it until the
frame is 16:9 is invisible, and only then is the image scaled down.

    python3 scripts/make_47_screenshots.py            # docs/store/screenshots
    python3 scripts/make_47_screenshots.py --check    # verify, write nothing
"""

import argparse
import sys
from pathlib import Path

from PIL import Image

SOURCE_SIZE = (1320, 2868)
TARGET_SIZE = (750, 1334)
PREFIX = "iphone47_"
# The native SE capture (screenshots/ios-se) framed the square this way.
TOP_SHARE = 175 / (175 + 165)


def bezel_runs(pixels, width, height, bezel):
  """Rows that are nothing but bezel colour, as (start, length) runs."""
  runs, start = [], None
  for y in range(height):
    uniform = all(pixels[x, y] == bezel for x in range(0, width, 8))
    if uniform and start is None:
      start = y
    elif not uniform and start is not None:
      runs.append((start, y - start))
      start = None
  if start is not None:
    runs.append((start, height - start))
  return runs


def convert(path: Path, out: Path) -> None:
  image = Image.open(path).convert("RGB")
  if image.size != SOURCE_SIZE:
    raise SystemExit(f"{path}: expected {SOURCE_SIZE}, got {image.size}")
  width, height = image.size
  pixels = image.load()
  bezel = pixels[0, 0]

  keep = round(width * TARGET_SIZE[1] / TARGET_SIZE[0])  # 16:9 at this width
  drop = height - keep

  runs = [run for run in bezel_runs(pixels, width, height, bezel) if run[1] > 100]
  if len(runs) < 2:
    raise SystemExit(f"{path}: no bezel band to cut ({runs})")
  top, bottom = runs[0], runs[-1]
  if top[1] + bottom[1] < drop:
    raise SystemExit(f"{path}: bezel is only {top[1] + bottom[1]}px, need {drop}")

  # Split what is left over between the two bands, top slightly taller.
  spare = top[1] + bottom[1] - drop
  top_keep = min(top[1], round(spare * TOP_SHARE))
  bottom_keep = spare - top_keep
  cuts = [(top[0], top[0] + top[1] - top_keep),
          (bottom[0] + bottom_keep, bottom[0] + bottom[1])]

  rows = [r for r in range(height) if not any(a <= r < b for a, b in cuts)]
  cut = Image.new("RGB", (width, len(rows)))
  for index, row in enumerate(rows):
    cut.paste(image.crop((0, row, width, row + 1)), (0, index))
  cut.resize(TARGET_SIZE, Image.LANCZOS).save(out)


def main() -> int:
  parser = argparse.ArgumentParser()
  parser.add_argument("root", nargs="?", default="docs/store/screenshots")
  parser.add_argument("--check", action="store_true",
                      help="report what is missing or stale, write nothing")
  args = parser.parse_args()

  root = Path(args.root)
  sources = sorted(p for p in root.glob("*/*.png") if not p.name.startswith(PREFIX))
  if not sources:
    raise SystemExit(f"no screenshots under {root}")

  stale = []
  for source in sources:
    out = source.with_name(PREFIX + source.name)
    if args.check:
      if not out.exists() or out.stat().st_mtime < source.stat().st_mtime:
        stale.append(out)
      continue
    convert(source, out)
    print(f"{out}  {TARGET_SIZE[0]}x{TARGET_SIZE[1]}")

  if stale:
    print("missing or older than their 6.9\" source:", file=sys.stderr)
    for path in stale:
      print(f"  {path}", file=sys.stderr)
    return 1
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
