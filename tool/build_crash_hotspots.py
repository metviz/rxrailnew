"""Build RxRail's crash-hotspot files from kavach's derived tables.

    python3 tool/build_crash_hotspots.py <kavach derived dir> <states dir> <bundled NC json>

Writes <states dir>/<ST>.json for every state (the app downloads these with
a state's offline map) and a copy of NC's as the bundled asset.

Each file: [[lat, lng, label, kind], ...]; kind "j" = junction (alert close
in), "s" = ~1-mile road stretch (alert from farther out).
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


# Share of a state's fatal road-miles kept, ranked by the model's risk of
# another fatal crash. 95% of scored miles had a single fatal crash in three
# years; alerting on all of them would be noise.
TOP_SHARE = 0.10
MIN_PER_STATE = 50


def road_label(road: str) -> str:
    """'US-101 HOLLYWOOD FWY' -> 'US-101 Hollywood Fwy'."""
    return " ".join(
        w if any(c.isdigit() for c in w) or "-" in w else w.capitalize()
        for w in road.split()
    )


def national(derived: Path) -> dict:
    """State -> top-risk fatal road-miles from the national model."""
    by_state = {}
    for r in rows(derived / "us_model_scores.csv"):
        by_state.setdefault(r["state"], []).append(r)
    out = {}
    for state, rs in by_state.items():
        rs.sort(key=lambda r: -float(r["risk"]))
        keep = rs[: max(MIN_PER_STATE, round(len(rs) * TOP_SHARE))]
        out[state] = [
            [round(float(r["lat"]), 5), round(float(r["lon"]), 5), road_label(r["road"]), "s"]
            for r in keep
        ]
    return out


def build_nc(derived: Path) -> list:
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


def build(derived: Path) -> dict:
    states = national(derived)
    # NC has richer local data; national miles fill in around it.
    nc = build_nc(derived)
    local = [(p[0], p[1]) for p in nc]
    nc += [p for p in states.get("NC", []) if all(metres(p, c) >= DEDUPE_M for c in local)]
    states["NC"] = nc
    return states


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    states = build(Path(sys.argv[1]))
    assert len(states) == 51, f"{len(states)} states"
    assert all(33 < p[0] < 37 and -85 < p[1] < -75 for p in states["NC"]), "NC point outside NC"
    assert all(17 < p[0] < 72 and -180 < p[1] < -65 and p[2] for ps in states.values() for p in ps)
    out = Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    for state, points in states.items():
        (out / f"{state}.json").write_text(json.dumps(points, separators=(",", ":")))
    Path(sys.argv[3]).write_text(json.dumps(states["NC"], separators=(",", ":")))
    print(f"{sum(map(len, states.values()))} hotspots in {len(states)} states -> {out}")
