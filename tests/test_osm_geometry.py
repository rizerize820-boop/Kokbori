import unittest

from tools.fetch_astana_osm import assemble_multipolygon, point_in_ring


class OSMRelationGeometryTests(unittest.TestCase):
    def test_inner_ring_is_preserved_with_its_outer(self):
        members = [
            {"role": "outer", "geometry": [
                {"lon": 0, "lat": 0}, {"lon": 10, "lat": 0},
                {"lon": 10, "lat": 10}, {"lon": 0, "lat": 10},
                {"lon": 0, "lat": 0},
            ]},
            {"role": "inner", "geometry": [
                {"lon": 2, "lat": 2}, {"lon": 4, "lat": 2},
                {"lon": 4, "lat": 4}, {"lon": 2, "lat": 4},
                {"lon": 2, "lat": 2},
            ]},
        ]
        polygons = assemble_multipolygon(members, lambda points: [
            [point["lon"], point["lat"]] for point in points
        ])
        self.assertEqual(len(polygons), 1)
        self.assertEqual(len(polygons[0]), 2)
        self.assertEqual(polygons[0][1][0], [2, 2])

    def test_inner_ring_attaches_to_smallest_containing_outer(self):
        def ring(x1, y1, x2, y2):
            return [
                {"lon": x1, "lat": y1}, {"lon": x2, "lat": y1},
                {"lon": x2, "lat": y2}, {"lon": x1, "lat": y2},
                {"lon": x1, "lat": y1},
            ]

        members = [
            {"role": "outer", "geometry": ring(0, 0, 20, 20)},
            {"role": "outer", "geometry": ring(5, 5, 15, 15)},
            {"role": "inner", "geometry": ring(7, 7, 9, 9)},
        ]
        polygons = assemble_multipolygon(members, lambda points: [
            [point["lon"], point["lat"]] for point in points
        ])
        self.assertEqual([len(polygon) for polygon in polygons], [1, 2])

    def test_point_in_ring(self):
        square = [[0, 0], [10, 0], [10, 10], [0, 10]]
        self.assertTrue(point_in_ring([5, 5], square))
        self.assertFalse(point_in_ring([15, 5], square))


if __name__ == "__main__":
    unittest.main()
