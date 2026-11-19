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
  way[landuse~"grass|forest|meadow|recreation_ground"]({SOUTH},{WEST},{NORTH},{EAST});
  way[natural~"water|wood"]({SOUTH},{WEST},{NORTH},{EAST});
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
        closed = len(coords) >= 4 and coords[0] == coords[-1]
        if "building" in tags and closed:
            geometry = {"type": "Polygon", "coordinates": [coords]}
            kind = "building"
        elif closed and ("leisure" in tags or "landuse" in tags or tags.get("natural") in ("water", "wood")):
            geometry = {"type": "Polygon", "coordinates": [coords]}
            kind = "water_area" if tags.get("natural") == "water" else "green_area"
        else:
            geometry = {"type": "LineString", "coordinates": coords}
            kind = "road" if "highway" in tags else ("water" if "waterway" in tags else "park")
        features.append({
            "type": "Feature",
            "properties": {
                "kind": kind,
                "height": tags.get("height", tags.get("building:height", "")),
                "levels": tags.get("building:levels", tags.get("levels", "")),
                "name": tags.get("name", ""),
                "highway": tags.get("highway", ""),
                "building": tags.get("building", ""),
                "facade_colour": tags.get("building:facade:colour", tags.get("building:colour", "")),
                "roof_colour": tags.get("roof:colour", ""),
                "roof_shape": tags.get("roof:shape", ""),
                "roof_height": tags.get("roof:height", ""),
                "surface": tags.get("surface", ""),
                "lanes": tags.get("lanes", ""),
                "width": tags.get("width", ""),
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
