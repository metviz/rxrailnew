"""Build the crash-hotspot asset for RxRail from kavach's derived tables.

    python3 tool/build_crash_hotspots.py <kavach derived dir> <output json>

Output: [[lat, lng, label, kind], ...]; kind "j" = junction (alert close in),
"s" = ~1-mile road stretch (alert from farther out).
"""
import csv
import json
import math
import sys
from pathlib import Path

# A fatal stretch this close to a Wake cluster is the same place.
DEDUPE_M = 500


def metres(a, b):
    """Equirectangular distance; fine at these ranges."""
    x = math.radians(b[1] - a[1]) * math.cos(math.radians((a[0] + b[0]) / 2))
    return math.hypot(x, math.radians(b[0] - a[0])) * 6371000


def rows(path):
    with open(path, newline="") as f:
        yield from csv.DictReader(f)


def build(derived: Path) -> list:
    out = []
    for r in rows(derived / "clusters.csv"):
        label = " ".join(r["where"].split()).title().replace(" @ ", " at ")
        kind = "j" if r["kind"] == "junction" else "s"
        out.append([round(float(r["lat"]), 5), round(float(r["lon"]), 5), label, kind])
    clusters = [(p[0], p[1]) for p in out]
    for r in rows(derived / "nc_fatal_segments.csv"):
        # mile 999 = milepost unknown: the point is the centroid of crashes
        # scattered along the whole road, not a place.
        if float(r["mile"]) >= 999:
            continue
        p = (round(float(r["lat"]), 5), round(float(r["lon"]), 5))
        if any(metres(p, c) < DEDUPE_M for c in clusters):
            continue
        out.append([p[0], p[1], f'{r["road"].title()}, {r["county"]} County', "s"])
    return out


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    points = build(Path(sys.argv[1]))
    assert points and all(33 < p[0] < 37 and -85 < p[1] < -75 for p in points), "point outside NC"
    Path(sys.argv[2]).write_text(json.dumps(points, separators=(",", ":")))
    print(f"{len(points)} hotspots -> {sys.argv[2]}")
