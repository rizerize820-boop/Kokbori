extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const ControlsScript = preload("res://scripts/mobile_controls.gd")

var materials: Dictionary = {}

func _ready() -> void:
	_build_materials()
	_build_environment()
	if FileAccess.file_exists("res://data/astana_osm.geojson"):
		_build_osm_city()
	else:
		_build_street_grid()
		_build_city()
	var player := CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.position = Vector3(0, 0.15, 12)
	add_child(player)
	var controls := CanvasLayer.new()
	controls.set_script(ControlsScript)
	add_child(controls)

func _build_materials() -> void:
	materials["road"] = _material(Color("#252b33"))
	materials["sidewalk"] = _material(Color("#aeb5b7"))
	materials["line"] = _material(Color("#e7dfbd"))
	materials["grass"] = _material(Color("#667b68"))
	materials["building_a"] = _material(Color("#b8b9b4"))
	materials["building_b"] = _material(Color("#9fa9b2"))
	materials["building_c"] = _material(Color("#c5b9a7"))
	materials["glass"] = _material(Color("#38566c"))
	(materials["glass"] as StandardMaterial3D).roughness = 0.34
	(materials["glass"] as StandardMaterial3D).metallic = 0.18
	materials["trim"] = _material(Color("#d7d9d6"))
	materials["gold"] = _material(Color("#d9ae58"))
	(materials["gold"] as StandardMaterial3D).roughness = 0.28
	(materials["gold"] as StandardMaterial3D).metallic = 0.52
	materials["water"] = _material(Color("#285d78"))
	(materials["water"] as StandardMaterial3D).roughness = 0.22
	materials["tree"] = _material(Color("#315c42"))
	materials["trunk"] = _material(Color("#66513c"))

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	return mat

func _visual_box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = pos
	parent.add_child(instance)
	return instance

func _solid_box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	parent.add_child(body)
	_visual_box(body, Vector3.ZERO, size, mat)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	return body

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#315a83")
	sky_material.sky_horizon_color = Color("#b8c7d2")
	sky_material.ground_bottom_color = Color("#303a43")
	sky_material.ground_horizon_color = Color("#89969a")
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#b8c8dc")
	env.ambient_light_energy = 0.72
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("#aabac8")
	env.fog_density = 0.0018
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)
	_solid_box(self, Vector3(0, -0.3, 0), Vector3(220, 0.5, 220), materials["grass"])

func _build_street_grid() -> void:
	# Secondary streets create a connected city grid around the central avenue.
	for x in [-37.0, 37.0]:
		_visual_box(self, Vector3(x, -0.012, 0), Vector3(7.0, 0.075, 150.0), materials["road"])
		_visual_box(self, Vector3(x - 4.5, 0.055, 0), Vector3(1.5, 0.13, 150.0), materials["sidewalk"])
		_visual_box(self, Vector3(x + 4.5, 0.055, 0), Vector3(1.5, 0.13, 150.0), materials["sidewalk"])
	for z in [-40.0, 40.0]:
		_visual_box(self, Vector3(0, -0.01, z), Vector3(150.0, 0.075, 7.0), materials["road"])
		_visual_box(self, Vector3(0, 0.055, z - 4.5), Vector3(150.0, 0.13, 1.5), materials["sidewalk"])
		_visual_box(self, Vector3(0, 0.055, z + 4.5), Vector3(150.0, 0.13, 1.5), materials["sidewalk"])
	for x in [-37.0, 37.0]:
		for z in range(-64, 65, 16):
			_visual_box(self, Vector3(x, 0.035, float(z)), Vector3(0.12, 0.02, 2.4), materials["line"])
	for z in [-40.0, 40.0]:
		for x in range(-64, 65, 16):
			_visual_box(self, Vector3(float(x), 0.035, z), Vector3(2.4, 0.02, 0.12), materials["line"])

func _build_city() -> void:
	# Main avenue, side streets and sidewalks.
	_visual_box(self, Vector3(0, -0.015, 0), Vector3(18, 0.08, 180), materials["road"])
	_visual_box(self, Vector3(0, 0.0, 0), Vector3(180, 0.08, 12), materials["road"])
	for x in [-11.0, 11.0]:
		_visual_box(self, Vector3(x, 0.07, 0), Vector3(3.0, 0.16, 180), materials["sidewalk"])
	for z in [-9.0, 9.0]:
		_visual_box(self, Vector3(0, 0.07, z), Vector3(180, 0.16, 2.0), materials["sidewalk"])
	# Dashed centre lines and pedestrian crossings.
	for z in range(-80, 81, 8):
		_visual_box(self, Vector3(0, 0.04, float(z)), Vector3(0.16, 0.025, 3.2), materials["line"])
	for i in range(7):
		_visual_box(self, Vector3(-5.0 + float(i) * 1.65, 0.065, 7.2), Vector3(0.95, 0.025, 2.2), materials["line"])
		_visual_box(self, Vector3(-5.0 + float(i) * 1.65, 0.065, -7.2), Vector3(0.95, 0.025, 2.2), materials["line"])
	# City blocks: restrained geometry and shared materials for mobile performance.
	for row in range(5):
		for col in range(5):
			var x := -52.0 + float(col) * 25.0
			var z := -55.0 + float(row) * 27.0
			if abs(x) < 17.0 or abs(z) < 14.0:
				continue
			var h := 12.0 + float((row * 7 + col * 3) % 5) * 4.0
			var w := 11.0 + float((row + col) % 3) * 2.0
			var mat: Material = materials["building_a"]
			if (row + col) % 3 == 1:
				mat = materials["building_b"]
			elif (row + col) % 3 == 2:
				mat = materials["building_c"]
			var building := Node3D.new()
			building.position = Vector3(x, 0, z)
			add_child(building)
			_solid_box(building, Vector3(0, h * 0.5, 0), Vector3(w, h, 10), mat)
			_visual_box(building, Vector3(0, h + 0.18, 0), Vector3(w + 0.35, 0.35, 10.35), materials["trim"])
			_add_windows(building, w, h)
	# Green strips, trees and street lamps along the main avenue.
	for side in [-1.0, 1.0]:
		_visual_box(self, Vector3(side * 13.2, 0.015, 0), Vector3(1.0, 0.06, 180), materials["grass"])
		for z in range(-72, 73, 18):
			_add_tree(Vector3(side * 13.2, 0, float(z)))
			_add_lamp(Vector3(side * 9.0, 0, float(z) + 5.0))
	# Astana-inspired river and embankment.
	_visual_box(self, Vector3(-76, -0.015, 0), Vector3(15, 0.08, 180), materials["water"])
	_visual_box(self, Vector3(-67.5, 0.08, 0), Vector3(1.0, 0.3, 180), materials["trim"])
	# Baiterek-inspired landmark on the central avenue.
	_solid_box(self, Vector3(0, 10, -43), Vector3(2.2, 20, 2.2), materials["trim"])
	var sphere := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 4.2
	sphere_mesh.height = 8.4
	sphere.mesh = sphere_mesh
	sphere.position = Vector3(0, 22, -43)
	sphere.material_override = materials["gold"]
	add_child(sphere)
	_visual_box(self, Vector3(0, 17.5, -43), Vector3(5.5, 0.35, 5.5), materials["trim"])

func _add_windows(parent: Node3D, width: float, height: float) -> void:
	var window_mesh := BoxMesh.new()
	window_mesh.size = Vector3(1.05, 1.25, 0.07)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	var count := int(floor(width / 2.0)) * int(floor(height / 3.0))
	multi.mesh = window_mesh
	multi.instance_count = count * 2
	var index := 0
	for floor_index in range(int(floor(height / 3.0))):
		for column in range(int(floor(width / 2.0))):
			var wx := -width * 0.5 + 1.2 + float(column) * 2.0
			var wy := 2.0 + float(floor_index) * 3.0
			multi.set_instance_transform(index, Transform3D(Basis(), Vector3(wx, wy, -5.06)))
			index += 1
			multi.set_instance_transform(index, Transform3D(Basis(Vector3.UP, PI), Vector3(wx, wy, 5.06)))
			index += 1
	var windows := MultiMeshInstance3D.new()
	windows.multimesh = multi
	windows.material_override = materials["glass"]
	parent.add_child(windows)

func _add_tree(pos: Vector3) -> void:
	var tree := Node3D.new()
	tree.position = pos
	add_child(tree)
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.16
	trunk_mesh.bottom_radius = 0.24
	trunk_mesh.height = 2.2
	trunk.mesh = trunk_mesh
	trunk.position.y = 1.1
	trunk.material_override = materials["trunk"]
	tree.add_child(trunk)
	var crown := MeshInstance3D.new()
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 1.35
	crown_mesh.height = 2.4
	crown.mesh = crown_mesh
	crown.position.y = 2.8
	crown.material_override = materials["tree"]
	tree.add_child(crown)

func _add_lamp(pos: Vector3) -> void:
	var lamp := Node3D.new()
	lamp.position = pos
	add_child(lamp)
	_visual_box(lamp, Vector3(0, 2.4, 0), Vector3(0.12, 4.8, 0.12), materials["trim"])
	_visual_box(lamp, Vector3(0, 4.75, -0.45), Vector3(0.85, 0.12, 0.18), materials["gold"])

# OpenStreetMap coordinates are projected locally around central Astana.
const OSM_ORIGIN_LON := 71.50158
const OSM_ORIGIN_LAT := 51.10436
const OSM_LAT_METERS := 111320.0
const OSM_MAX_FEATURES := 18000

func _osm_point(coord: Array) -> Vector3:
	var lat_scale := cos(deg_to_rad(OSM_ORIGIN_LAT))
	var x := (float(coord[0]) - OSM_ORIGIN_LON) * OSM_LAT_METERS * lat_scale
	var z := -(float(coord[1]) - OSM_ORIGIN_LAT) * OSM_LAT_METERS
	return Vector3(x, 0.0, z)

func _build_osm_city() -> void:
	var file := FileAccess.open("res://data/astana_osm.geojson", FileAccess.READ)
	if file == null:
		_build_street_grid()
		_build_city()
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("features"):
		push_warning("Astana OSM snapshot is invalid; using prototype district.")
		_build_street_grid()
		_build_city()
		return
	var features: Array = parsed["features"]
	var processed := 0
	for feature in features:
		if processed >= OSM_MAX_FEATURES:
			break
		if typeof(feature) != TYPE_DICTIONARY:
			continue
		var geometry: Dictionary = feature.get("geometry", {})
		var properties: Dictionary = feature.get("properties", {})
		var kind := str(properties.get("kind", ""))
		var coords: Array = geometry.get("coordinates", [])
		if kind == "building" and geometry.get("type", "") == "Polygon" and not coords.is_empty():
			var ring: Array = coords[0]
			if ring.size() >= 4:
				_add_osm_building(ring, properties)
				processed += 1
		elif geometry.get("type", "") == "LineString" and coords.size() >= 2:
			_add_osm_line(coords, kind, str(properties.get("highway", "")))
			processed += 1
	print("Loaded ", processed, " Astana OpenStreetMap features. © OpenStreetMap contributors")

func _add_osm_building(ring: Array, properties: Dictionary) -> void:
	var points := PackedVector2Array()
	for coord in ring:
		var p := _osm_point(coord)
		points.append(Vector2(p.x, p.z))
	if points.size() > 3 and points[0].is_equal_approx(points[points.size() - 1]):
		points.remove_at(points.size() - 1)
	if points.size() < 3:
		return
	var height := 10.0
	var tagged_height := str(properties.get("height", "")).replace(" m", "").replace("m", "")
	if tagged_height.is_valid_float():
		height = clampf(float(tagged_height), 3.0, 180.0)
	else:
		var levels := str(properties.get("levels", ""))
		if levels.is_valid_float():
			height = clampf(float(levels) * 3.1, 3.0, 180.0)
	var triangles := Geometry2D.triangulate_polygon(points)
	if triangles.is_empty():
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, triangles.size(), 3):
		for j in range(3):
			var p := points[triangles[i + j]]
			st.add_vertex(Vector3(p.x, height, p.y))
	for i in range(points.size()):
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		st.add_vertex(Vector3(a.x, 0, a.y))
		st.add_vertex(Vector3(b.x, 0, b.y))
		st.add_vertex(Vector3(b.x, height, b.y))
		st.add_vertex(Vector3(a.x, 0, a.y))
		st.add_vertex(Vector3(b.x, height, b.y))
		st.add_vertex(Vector3(a.x, height, a.y))
	st.generate_normals()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.material_override = materials["building_a"]
	add_child(mesh_instance)

func _add_osm_line(coords: Array, kind: String, highway: String) -> void:
	var width := 0.8
	var mat: Material = materials["sidewalk"]
	if kind == "road":
		width = 5.0 if highway in ["motorway", "trunk", "primary", "secondary"] else 2.8
		mat = materials["road"]
	elif kind == "water":
		width = 3.0
		mat = materials["water"]
	else:
		width = 1.5
		mat = materials["grass"]
	for i in range(coords.size() - 1):
		var a := _osm_point(coords[i])
		var b := _osm_point(coords[i + 1])
		var delta := b - a
		var length := Vector2(delta.x, delta.z).length()
		if length < 0.5 or length > 250.0:
			continue
		var segment := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(width, 0.12, length)
		segment.mesh = box
		segment.material_override = mat
		segment.position = (a + b) * 0.5
		segment.rotation.y = atan2(delta.x, delta.z)
		add_child(segment)
