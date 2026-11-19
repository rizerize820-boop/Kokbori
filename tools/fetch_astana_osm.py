#!/usr/bin/env python3
"""Fetch an Astana-area OpenStreetMap snapshot as compact GeoJSON for KOKBORI."""
import json
import os
import sys
import time
import urllib.parse
import urllib.request

# Published Astana bounding box (WGS84): south, west, north, east.
SOUTH, WEST, NORTH, EAST = 50.85761, 71.21797, 51.35111, 71.78519
OVERPASS = os.environ.get("OVERPASS_URL", "https://overpass-api.de/api/interpreter")
QUERY = f"""[out:json][timeout:240];
(
  way[building]({SOUTH},{WEST},{NORTH},{EAST});
  way[highway]({SOUTH},{WEST},{NORTH},{EAST});
  way[waterway]({SOUTH},{WEST},{NORTH},{EAST});
  way[leisure~"park|garden|playground"]({SOUTH},{WEST},{NORTH},{EAST});
);
out tags geom;
"""

def main():
    os.makedirs("Engine/data", exist_ok=True)
    req = urllib.request.Request(
        OVERPASS,
        data=urllib.parse.urlencode({"data": QUERY}).encode(),
        headers={"User-Agent": "KOKBORI-RP/0.1 (Astana map data build)"},
    )
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=300) as response:
                payload = json.load(response)
            break
        except Exception:
            if attempt == 3:
                raise
            time.sleep(12 * (attempt + 1))
    features = []
    for element in payload.get("elements", []):
        points = element.get("geometry", [])
        if len(points) < 2:
            continue
        tags = element.get("tags", {})
        coords = [[p["lon"], p["lat"]] for p in points]
        if "building" in tags and len(coords) >= 4 and coords[0] == coords[-1]:
            geometry = {"type": "Polygon", "coordinates": [coords]}
            kind = "building"
        else:
            geometry = {"type": "LineString", "coordinates": coords}
            kind = "road" if "highway" in tags else ("water" if "waterway" in tags else "park")
        features.append({
            "type": "Feature",
            "properties": {
                "kind": kind,
                "height": tags.get("height", ""),
                "levels": tags.get("building:levels", ""),
                "name": tags.get("name", ""),
                "highway": tags.get("highway", ""),
            },
            "geometry": geometry,
        })
    if not features:
        raise RuntimeError("Overpass returned no usable Astana features")
    out = {"type": "FeatureCollection", "source": "© OpenStreetMap contributors",
           "bbox": [WEST, SOUTH, EAST, NORTH], "features": features}
    with open("Engine/data/astana_osm.geojson", "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
    print(f"Saved {len(features)} OSM features to Engine/data/astana_osm.geojson")

if __name__ == "__main__":
    main()
