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
  way["building:part"]({SOUTH},{WEST},{NORTH},{EAST});
  relation[building]({SOUTH},{WEST},{NORTH},{EAST});
  relation[leisure~"park|garden|playground"]({SOUTH},{WEST},{NORTH},{EAST});
  relation[landuse~"grass|forest|meadow|recreation_ground"]({SOUTH},{WEST},{NORTH},{EAST});
  relation[natural~"water|wood"]({SOUTH},{WEST},{NORTH},{EAST});
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
    buckets = {"building": [], "road": [], "area": [], "water": []}
    def rounded_coords(points):
        return [[round(float(p["lon"]), 6), round(float(p["lat"]), 6)] for p in points]

    def props_for(tags, kind):
        return {
            "kind": kind,
            "height": tags.get("height", tags.get("building:height", "")),
            "levels": tags.get("building:levels", tags.get("levels", "")),
            "name": tags.get("name", ""),
            "highway": tags.get("highway", ""),
            "building": tags.get("building", tags.get("building:part", "")),
            "facade_colour": tags.get("building:facade:colour", tags.get("building:colour", "")),
            "roof_colour": tags.get("roof:colour", ""),
            "roof_shape": tags.get("roof:shape", ""),
            "roof_height": tags.get("roof:height", ""),
            "surface": tags.get("surface", ""),
            "lanes": tags.get("lanes", ""),
            "width": tags.get("width", ""),
        }

    def add_feature(kind, coords, tags):
        if len(coords) < 2:
            return
        closed = len(coords) >= 4 and coords[0] == coords[-1]
        if kind == "building" and closed:
            geometry = {"type": "Polygon", "coordinates": [coords]}
            bucket = "building"
        elif closed and kind == "area":
            geometry = {"type": "Polygon", "coordinates": [coords]}
            bucket = "area"
        else:
            geometry = {"type": "LineString", "coordinates": coords}
            bucket = "road" if kind == "road" else "water"
        buckets[bucket].append({
            "type": "Feature",
            "properties": props_for(tags, "water_area" if bucket == "area" and tags.get("natural") == "water" else
                                    "green_area" if bucket == "area" else
                                    "water" if bucket == "water" else
                                    "building" if bucket == "building" else "road"),
            "geometry": geometry,
        })

    for element in payload.get("elements", []):
        tags = element.get("tags", {})
        if element.get("type") == "way":
            points = element.get("geometry", [])
            coords = rounded_coords(points)
            if "building" in tags or "building:part" in tags:
                add_feature("building", coords, tags)
            elif "highway" in tags:
                add_feature("road", coords, tags)
            elif "waterway" in tags:
                add_feature("water", coords, tags)
            elif any(k in tags for k in ("leisure", "landuse", "natural")):
                add_feature("area", coords, tags)
        elif element.get("type") == "relation":
            # Keep outer rings of mapped multipolygons; inner holes are not yet
            # represented by the current in-game polygon renderer.
            for member in element.get("members", []):
                if member.get("role", "") != "outer":
                    continue
                coords = rounded_coords(member.get("geometry", []))
                if len(coords) < 4 or coords[0] != coords[-1]:
                    continue
                if "building" in tags:
                    add_feature("building", coords, tags)
                elif any(k in tags for k in ("leisure", "landuse", "natural")):
                    add_feature("area", coords, tags)

    # Bound the mobile snapshot and preserve a mix of city features.
    limits = {"building": 30000, "road": 18000, "area": 1500, "water": 600}
    features = []
    for key in ("building", "road", "water", "area"):
        features.extend(buckets[key][:limits[key]])
    if not features:
        raise RuntimeError("Overpass returned no usable Astana features")
    out = {"type": "FeatureCollection", "source": "© OpenStreetMap contributors",
           "bbox": [WEST, SOUTH, EAST, NORTH], "features": features}
    with open("Engine/data/astana_osm.geojson", "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
    print(f"Saved {len(features)} OSM features to Engine/data/astana_osm.geojson (expanded Astana mobile snapshot)")

if __name__ == "__main__":
    main()
