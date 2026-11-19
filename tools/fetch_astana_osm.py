#!/usr/bin/env python3
"""Fetch an Astana-area OpenStreetMap snapshot as compact GeoJSON for KOKBORI."""
import json
import os
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


def rounded_coords(points):
    return [[round(float(p["lon"]), 6), round(float(p["lat"]), 6)] for p in points]


def ring_area(ring):
    """Signed shoelace area; used to select the smallest containing outer ring."""
    return sum(
        ring[i][0] * ring[(i + 1) % len(ring)][1]
        - ring[(i + 1) % len(ring)][0] * ring[i][1]
        for i in range(len(ring))
    ) * 0.5


def point_in_ring(point, ring):
    """Return whether a 2D point is inside a ring using ray casting."""
    x, y = point
    inside = False
    j = len(ring) - 1
    for i in range(len(ring)):
        xi, yi = ring[i]
        xj, yj = ring[j]
        if (yi > y) != (yj > y):
            crossing_x = (xj - xi) * (y - yi) / (yj - yi) + xi
            if x < crossing_x:
                inside = not inside
        j = i
    return inside


def assemble_multipolygon(members, coordinate_converter):
    """Group relation outer rings with the inner rings that belong to them."""
    outers, inners = [], []
    for member in members:
        role = member.get("role", "")
        if role not in ("outer", "inner"):
            continue
        ring = coordinate_converter(member.get("geometry", []))
        if len(ring) < 4 or ring[0] != ring[-1]:
            continue
        # Remove the duplicate closing coordinate while testing/serializing.
        ring = ring[:-1]
        if len(ring) < 3:
            continue
        if role == "outer":
            outers.append(ring)
        else:
            inners.append(ring)

    polygons = [[outer] for outer in outers]
    for inner in inners:
        candidates = [
            index for index, polygon in enumerate(polygons)
            if point_in_ring(inner[0], polygon[0])
        ]
        if not candidates:
            continue
        owner = min(candidates, key=lambda index: abs(ring_area(polygons[index][0])))
        polygons[owner].append(inner)

    # GeoJSON linear rings must be closed.
    return [[ring + [ring[0]] for ring in polygon] for polygon in polygons]


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

    def add_polygon(bucket, rings, tags, kind):
        if not rings or len(rings[0]) < 4:
            return
        buckets[bucket].append({
            "type": "Feature",
            "properties": props_for(tags, kind),
            "geometry": {"type": "Polygon", "coordinates": rings},
        })

    def add_feature(kind, coords, tags):
        if len(coords) < 2:
            return
        closed = len(coords) >= 4 and coords[0] == coords[-1]
        if kind == "building" and closed:
            add_polygon("building", [coords], tags, "building")
        elif closed and kind == "area":
            area_kind = "water_area" if tags.get("natural") == "water" else "green_area"
            add_polygon("area", [coords], tags, area_kind)
        else:
            bucket = "road" if kind == "road" else "water"
            feature_kind = "road" if bucket == "road" else "water"
            buckets[bucket].append({
                "type": "Feature",
                "properties": props_for(tags, feature_kind),
                "geometry": {"type": "LineString", "coordinates": coords},
            })

    for element in payload.get("elements", []):
        tags = element.get("tags", {})
        if element.get("type") == "way":
            coords = rounded_coords(element.get("geometry", []))
            if "building" in tags or "building:part" in tags:
                add_feature("building", coords, tags)
            elif "highway" in tags:
                add_feature("road", coords, tags)
            elif "waterway" in tags:
                add_feature("water", coords, tags)
            elif any(key in tags for key in ("leisure", "landuse", "natural")):
                add_feature("area", coords, tags)
        elif element.get("type") == "relation":
            if "building" in tags:
                bucket, kind = "building", "building"
            elif any(key in tags for key in ("leisure", "landuse", "natural")):
                bucket = "area"
                kind = "water_area" if tags.get("natural") == "water" else "green_area"
            else:
                continue
            polygons = assemble_multipolygon(element.get("members", []), rounded_coords)
            for rings in polygons:
                add_polygon(bucket, rings, tags, kind)

    # Bound the mobile snapshot and preserve a mix of city features.
    limits = {"building": 11000, "road": 6000, "area": 700, "water": 300}
    features = []
    for key in ("building", "road", "water", "area"):
        features.extend(buckets[key][:limits[key]])
    if not features:
        raise RuntimeError("Overpass returned no usable Astana features")

    out = {
        "type": "FeatureCollection",
        "source": "© OpenStreetMap contributors",
        "bbox": [WEST, SOUTH, EAST, NORTH],
        "features": features,
    }
    with open("Engine/data/astana_osm.geojson", "w", encoding="utf-8") as output:
        json.dump(out, output, ensure_ascii=False, separators=(",", ":"))
    print(f"Saved {len(features)} OSM features to Engine/data/astana_osm.geojson (bounded mobile snapshot)")


if __name__ == "__main__":
    main()
