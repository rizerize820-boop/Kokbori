extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const ControlsScript = preload("res://scripts/mobile_controls.gd")
const VehicleScript = preload("res://scripts/vehicle.gd")

var materials: Dictionary = {}
var loading_layer: CanvasLayer

func _ready() -> void:
	_build_materials()
	_build_environment()
	_show_loading_screen("ЗАГРУЗКА ГОРОДА АСТАНЫ...")
	await get_tree().process_frame
	if FileAccess.file_exists("res://data/astana_osm.geojson"):
		await _build_osm_city()
		if int(_osm_surfaces.get("processed_count", 0)) < 20:
			push_warning("OSM map has too few usable features; loading fallback city.")
			_build_street_grid()
			_build_city()
		else:
			_build_baiterek()
	else:
		_build_street_grid()
		_build_city()
	_hide_loading_screen()
	var player := CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.position = Vector3(-1.0, 0.15, 38.0)
	add_child(player)
	var camry := CharacterBody3D.new()
	camry.set_script(VehicleScript)
	camry.position = Vector3(2.5, 0.15, 35.0)
	add_child(camry)
	camry.call("set_driver", player)
	var controls := CanvasLayer.new()
	controls.set_script(ControlsScript)
	add_child(controls)

func _show_loading_screen(message: String) -> void:
	loading_layer = CanvasLayer.new()
	loading_layer.layer = 100
	add_child(loading_layer)
	var panel := ColorRect.new()
	panel.color = Color("#101a24")
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loading_layer.add_child(panel)
	var label := Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.add_theme_color_override("font_color", Color("#e6edf2"))
	label.add_theme_font_size_override("font_size", 22)
	panel.add_child(label)

func _hide_loading_screen() -> void:
	if is_instance_valid(loading_layer):
		loading_layer.queue_free()
	loading_layer = null

func _build_materials() -> void:
	materials["road"] = _material(Color("#252b33"))
	materials["sidewalk"] = _material(Color("#aeb5b7"))
	materials["line"] = _material(Color("#e7dfbd"))
	materials["road_mark"] = _material(Color("#e8dfc4"))
	materials["road_edge"] = _material(Color("#b9c0bd"))
	materials["grass"] = _material(Color("#667b68"))
	materials["building_a"] = _material(Color("#b8b9b4"))
	materials["building_b"] = _material(Color("#9fa9b2"))
	materials["building_c"] = _material(Color("#c5b9a7"))
	materials["window_glass"] = _material(Color("#243f55"))
	(materials["window_glass"] as StandardMaterial3D).roughness = 0.22
	(materials["window_glass"] as StandardMaterial3D).metallic = 0.24
	materials["facade_trim"] = _material(Color("#d6d4ca"))
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
	mat.vertex_color_use_as_albedo = false
	# OSM polygons do not have a guaranteed winding order. Render both sides
	# so building walls, park polygons and road surfaces cannot vanish.
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
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
	env.ambient_light_energy = 0.82
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("#b8c5ce")
	env.fog_density = 0.0009
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)
	var ground_size := 16000.0 if FileAccess.file_exists("res://data/astana_osm.geojson") else 220.0
	# A continuous, thick physics floor sits exactly beneath the map surfaces.
	_solid_box(self, Vector3(0, -1.0, 0), Vector3(ground_size, 2.0, ground_size), materials["grass"])

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

func _baiterek_segment(parent: Node3D, start: Vector3, finish: Vector3, radius: float, mat: Material) -> void:
	var direction := finish - start
	var mesh_instance := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius * 0.82
	cylinder.bottom_radius = radius
	cylinder.height = direction.length()
	cylinder.radial_segments = 16
	mesh_instance.mesh = cylinder
	mesh_instance.material_override = mat
	mesh_instance.position = (start + finish) * 0.5
	mesh_instance.quaternion = Quaternion(Vector3.UP, direction.normalized())
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mesh_instance)

func _build_baiterek() -> void:
	# Approximate real-world Baiterek location, projected using the same OSM origin.
	var p := _osm_point([71.4304, 51.1282])
	var base := Vector3(p.x, 0.0, p.z)
	var landmark := Node3D.new()
	landmark.name = "Baiterek_Realistic_Landmark"
	landmark.position = base
	add_child(landmark)

	var stone := _material(Color("#c8c9c4"))
	var white_metal := _material(Color("#dce2e4"))
	white_metal.metallic = 0.72
	white_metal.roughness = 0.24
	var gold_glass := _material(Color("#d9a92e"))
	gold_glass.metallic = 0.68
	gold_glass.roughness = 0.16
	gold_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gold_glass.albedo_color = Color(0.86, 0.66, 0.18, 0.94)
	var dark_glass := _material(Color("#354b59"))
	dark_glass.metallic = 0.42
	dark_glass.roughness = 0.2

	# Broad public plaza and a low circular stone podium.
	var plaza := CylinderMesh.new()
	plaza.top_radius = 17.0
	plaza.bottom_radius = 19.0
	plaza.height = 0.55
	plaza.radial_segments = 48
	var plaza_node := MeshInstance3D.new()
	plaza_node.mesh = plaza
	plaza_node.material_override = stone
	plaza_node.position.y = 0.28
	landmark.add_child(plaza_node)

	var podium := CylinderMesh.new()
	podium.top_radius = 7.0
	podium.bottom_radius = 9.5
	podium.height = 2.4
	podium.radial_segments = 40
	var podium_node := MeshInstance3D.new()
	podium_node.mesh = podium
	podium_node.material_override = white_metal
	podium_node.position.y = 1.45
	landmark.add_child(podium_node)

	# Four tapered structural legs converge toward the observation sphere.
	var leg_angles := [0.0, PI * 0.5, PI, PI * 1.5]
	for angle in leg_angles:
		var radial := Vector3(cos(angle), 0.0, sin(angle))
		_baiterek_segment(landmark, radial * 6.4 + Vector3.UP * 2.0,
			radial * 1.15 + Vector3.UP * 75.0, 0.78, white_metal)
		# Fine gold inlay along each main support.
		_baiterek_segment(landmark, radial * 6.0 + Vector3.UP * 3.0,
			radial * 1.35 + Vector3.UP * 73.0, 0.10, materials["gold"])

	# Central mast and collars make the tall silhouette readable from far away.
	_baiterek_segment(landmark, Vector3(0, 5, 0), Vector3(0, 83, 0), 0.62, white_metal)
	for y in [12.0, 28.0, 44.0, 60.0, 74.0]:
		var collar := TorusMesh.new()
		collar.inner_radius = 0.68
		collar.outer_radius = 0.88
		collar.rings = 8
		collar.ring_segments = 24
		var collar_node := MeshInstance3D.new()
		collar_node.mesh = collar
		collar_node.material_override = materials["gold"]
		collar_node.position.y = y
		landmark.add_child(collar_node)

	# Large golden glass orb, with subtle structural latitude/longitude rings.
	var orb := MeshInstance3D.new()
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 11.2
	orb_mesh.height = 22.4
	orb_mesh.radial_segments = 48
	orb_mesh.rings = 32
	orb.mesh = orb_mesh
	orb.material_override = gold_glass
	orb.position.y = 85.0
	orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	landmark.add_child(orb)

	for y_offset in [-6.0, -3.0, 0.0, 3.0, 6.0]:
		var ring_radius := sqrt(maxf(0.1, 11.2 * 11.2 - y_offset * y_offset))
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = ring_radius - 0.10
		ring_mesh.outer_radius = ring_radius + 0.10
		ring_mesh.rings = 6
		ring_mesh.ring_segments = 48
		var ring_node := MeshInstance3D.new()
		ring_node.mesh = ring_mesh
		ring_node.material_override = white_metal
		ring_node.position.y = 85.0 + y_offset
		landmark.add_child(ring_node)

	# Thin vertical ribs on the orb give it a glazed, engineered finish.
	for index in range(16):
		var angle := TAU * float(index) / 16.0
		var rib := MeshInstance3D.new()
		var rib_mesh := CylinderMesh.new()
		rib_mesh.top_radius = 0.055
		rib_mesh.bottom_radius = 0.055
		rib_mesh.height = 19.5
		rib_mesh.radial_segments = 6
		rib.mesh = rib_mesh
		rib.material_override = white_metal
		rib.position = Vector3(cos(angle) * 10.95, 85.0, sin(angle) * 10.95)
		landmark.add_child(rib)

	# Small warm lights around the base and orb perimeter.
	for index in range(12):
		var angle := TAU * float(index) / 12.0
		var light := OmniLight3D.new()
		light.light_color = Color("#ffd98a")
		light.light_energy = 0.55
		light.omni_range = 8.0
		light.position = Vector3(cos(angle) * 8.5, 4.0, sin(angle) * 8.5)
		landmark.add_child(light)

	print("Built detailed Baiterek landmark at its mapped Astana coordinates.")

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
const OSM_ORIGIN_LON := 71.4305
const OSM_ORIGIN_LAT := 51.1283
const OSM_LAT_METERS := 111320.0
const OSM_MAX_FEATURES := 16000
const OSM_RENDER_RADIUS := 3200.0
const OSM_FACADE_RADIUS := 1100.0
var _osm_surfaces: Dictionary = {}

func _osm_point(coord: Array) -> Vector3:
	var lat_scale := cos(deg_to_rad(OSM_ORIGIN_LAT))
	var x := (float(coord[0]) - OSM_ORIGIN_LON) * OSM_LAT_METERS * lat_scale
	var z := -(float(coord[1]) - OSM_ORIGIN_LAT) * OSM_LAT_METERS
	return Vector3(x, 0.0, z)

func _build_osm_city() -> void:
	var file := FileAccess.open("res://data/astana_osm.geojson", FileAccess.READ)
	if file == null:
		push_error("Astana map data is missing.")
		_build_street_grid()
		_build_city()
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("features"):
		push_error("Astana OSM snapshot is invalid.")
		_build_street_grid()
		_build_city()
		return

	# Combine geometry into a small number of shared meshes. Creating one node
	# per building/road way made the full-city scene too expensive for iPhones.
	for key in ["walls", "roofs", "windows", "facade_trim", "roads", "road_marks", "road_edges", "paths", "water_lines", "green", "water_areas"]:
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		_osm_surfaces[key] = tool

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
		# Build only the playable central area; the source snapshot covers a huge metro region.
		var sample_coord: Array = []
		if geometry.get("type", "") == "Polygon" and not coords.is_empty():
			var sample_ring: Array = coords[0]
			if not sample_ring.is_empty():
				sample_coord = sample_ring[0]
		elif geometry.get("type", "") == "LineString" and not coords.is_empty():
			sample_coord = coords[0]
		if sample_coord.size() >= 2 and _osm_point(sample_coord).length() > OSM_RENDER_RADIUS:
			continue
		if geometry.get("type", "") == "Polygon" and not coords.is_empty():
			var ring: Array = coords[0]
			if ring.size() >= 4:
				if kind == "building":
					_add_osm_building(ring, properties)
				else:
					_add_osm_area(ring, kind)
				processed += 1
		elif geometry.get("type", "") == "LineString" and coords.size() >= 2:
			_add_osm_line(coords, kind, properties)
			processed += 1
		if processed > 0 and processed % 150 == 0:
			await get_tree().process_frame
	_osm_surfaces["processed_count"] = processed

	_commit_osm_surface("walls", materials["building_a"])
	_commit_osm_surface("roofs", materials["building_b"])
	_commit_osm_surface("windows", materials["window_glass"])
	_commit_osm_surface("facade_trim", materials["facade_trim"])
	_commit_osm_surface("roads", materials["road"])
	_commit_osm_surface("road_marks", materials["road_mark"])
	_commit_osm_surface("road_edges", materials["road_edge"])
	_commit_osm_surface("paths", materials["sidewalk"])
	_commit_osm_surface("water_lines", materials["water"])
	_commit_osm_surface("green", materials["grass"])
	_commit_osm_surface("water_areas", materials["water"])
	print("Loaded ", processed, " Astana OpenStreetMap features. © OpenStreetMap contributors")

func _commit_osm_surface(key: String, mat: Material) -> void:
	var tool: SurfaceTool = _osm_surfaces[key]
	tool.generate_normals()
	var mesh := tool.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	var surface_material: StandardMaterial3D = mat as StandardMaterial3D
	if key == "walls" or key == "roofs":
		surface_material = (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
		surface_material.vertex_color_use_as_albedo = true
	instance.material_override = surface_material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(instance)

func _add_osm_building(ring: Array, properties: Dictionary) -> void:
	var points := PackedVector2Array()
	for coord in ring:
		var p := _osm_point(coord)
		points.append(Vector2(p.x, p.z))
	if points.size() > 3 and points[0].is_equal_approx(points[points.size() - 1]):
		points.remove_at(points.size() - 1)
	if points.size() < 3:
		return
	var height := 9.3
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
	var facade_color := _osm_color(str(properties.get("facade_colour", "")), Color("#aeb8bf"))
	var roof_color := _osm_color(str(properties.get("roof_colour", "")), Color("#68747d"))
	var walls: SurfaceTool = _osm_surfaces["walls"]
	for i in range(points.size()):
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		walls.set_color(facade_color)
		walls.add_vertex(Vector3(a.x, 0, a.y))
		walls.set_color(facade_color)
		walls.add_vertex(Vector3(b.x, 0, b.y))
		walls.set_color(facade_color.darkened(0.06))
		walls.add_vertex(Vector3(b.x, height, b.y))
		walls.set_color(facade_color)
		walls.add_vertex(Vector3(a.x, 0, a.y))
		walls.set_color(facade_color.darkened(0.06))
		walls.add_vertex(Vector3(b.x, height, b.y))
		walls.set_color(facade_color.lightened(0.035))
		walls.add_vertex(Vector3(a.x, height, a.y))
	var roof: SurfaceTool = _osm_surfaces["roofs"]
	for i in range(0, triangles.size(), 3):
		for j in range(3):
			var p := points[triangles[i + j]]
			roof.set_color(roof_color)
			roof.add_vertex(Vector3(p.x, height, p.y))

	# Add repeated, scale-aware facade windows and floor bands to OSM buildings.
	# Geometry is batched into shared meshes to keep draw calls low on iPhone.
	var center := Vector2.ZERO
	for point in points:
		center += point
	center /= float(points.size())
	if center.length() > OSM_FACADE_RADIUS:
		return
	var windows: SurfaceTool = _osm_surfaces["windows"]
	var trim: SurfaceTool = _osm_surfaces["facade_trim"]
	var floors := maxi(1, int(floor(height / 3.2)))
	for i in range(points.size()):
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		var edge := b - a
		var edge_len := edge.length()
		if edge_len < 3.2:
			continue
		var tangent := edge / edge_len
		var outward := Vector2(tangent.y, -tangent.x)
		var count := maxi(1, int(floor(edge_len / 3.0)))
		for floor_index in range(floors):
			var y := 1.35 + float(floor_index) * 3.2
			if y + 1.45 > height:
				continue
			# Continuous narrow belt between floors.
			_add_osm_quad(trim,
				Vector3(a.x + outward.x * 0.035, y - 0.12, a.y + outward.y * 0.035),
				Vector3(b.x + outward.x * 0.035, y - 0.12, b.y + outward.y * 0.035),
				Vector3(b.x + outward.x * 0.035, y - 0.04, b.y + outward.y * 0.035),
				Vector3(a.x + outward.x * 0.035, y - 0.04, a.y + outward.y * 0.035))
			for window_index in range(count):
				var window_t := (float(window_index) + 0.5) / float(count)
				var half_w := minf(0.58, edge_len / float(count) * 0.28)
				var center_point := a + edge * window_t
				var left := center_point - tangent * half_w + outward * 0.045
				var right := center_point + tangent * half_w + outward * 0.045
				_add_osm_quad(windows,
					Vector3(left.x, y, left.y),
					Vector3(right.x, y, right.y),
					Vector3(right.x, y + 1.35, right.y),
					Vector3(left.x, y + 1.35, left.y))

func _osm_color(value: String, fallback: Color) -> Color:
	var candidate := value.strip_edges()
	if candidate.is_empty():
		return fallback
	if not candidate.begins_with("#"):
		candidate = "#" + candidate
	if candidate.length() == 7 or candidate.length() == 9:
		return Color.from_string(candidate, fallback)
	return fallback

func _add_osm_quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)
	surface.add_vertex(a)
	surface.add_vertex(c)
	surface.add_vertex(d)

func _add_osm_area(ring: Array, kind: String) -> void:
	var points := PackedVector2Array()
	for coord in ring:
		var p := _osm_point(coord)
		points.append(Vector2(p.x, p.z))
	if points.size() > 3 and points[0].is_equal_approx(points[points.size() - 1]):
		points.remove_at(points.size() - 1)
	if points.size() < 3:
		return
	var indices := Geometry2D.triangulate_polygon(points)
	if indices.is_empty():
		return
	var key := "water_areas" if kind == "water_area" else "green"
	var st: SurfaceTool = _osm_surfaces[key]
	for i in range(0, indices.size(), 3):
		for j in range(3):
			var p := points[indices[i + j]]
			st.add_vertex(Vector3(p.x, 0.035, p.y))

func _add_osm_line(coords: Array, kind: String, properties: Dictionary) -> void:
	var highway := str(properties.get("highway", ""))
	var width := 0.8
	var key := "paths"
	if kind == "road":
		var road_widths := {
			"motorway": 15.0, "trunk": 12.0, "primary": 10.0,
			"secondary": 8.0, "tertiary": 6.5, "residential": 5.5,
			"living_street": 4.5, "service": 3.5, "footway": 1.4,
			"path": 1.2, "cycleway": 1.8, "pedestrian": 3.0
		}
		width = float(road_widths.get(highway, 3.0))
		var tagged_width := str(properties.get("width", "")).replace(" m", "").replace("m", "")
		if tagged_width.is_valid_float():
			width = clampf(float(tagged_width), 1.0, 24.0)
		elif str(properties.get("lanes", "")).is_valid_float():
			width = clampf(float(properties.get("lanes")) * 3.2, 2.5, 24.0)
		key = "roads" if highway not in ["footway", "path", "cycleway", "pedestrian"] else "paths"
	elif kind == "water":
		width = 3.0
		key = "water_lines"
	else:
		width = 1.5
		key = "green"

	var surface: SurfaceTool = _osm_surfaces[key]
	for i in range(coords.size() - 1):
		var a := _osm_point(coords[i])
		var b := _osm_point(coords[i + 1])
		var delta := Vector2(b.x - a.x, b.z - a.z)
		var length := delta.length()
		if length < 0.5 or length > 250.0:
			continue
		var side := Vector2(-delta.y, delta.x).normalized() * width * 0.5
		var p1 := Vector3(a.x + side.x, 0.065, a.z + side.y)
		var p2 := Vector3(a.x - side.x, 0.065, a.z - side.y)
		var p3 := Vector3(b.x - side.x, 0.065, b.z - side.y)
		var p4 := Vector3(b.x + side.x, 0.065, b.z + side.y)
		surface.add_vertex(p1)
		surface.add_vertex(p2)
		surface.add_vertex(p3)
		surface.add_vertex(p1)
		surface.add_vertex(p3)
		surface.add_vertex(p4)
		# Dashed center markings on larger streets make intersections and lanes easier to read.
		if kind == "road" and highway in ["motorway", "trunk", "primary", "secondary", "tertiary"]:
			# Thin edge lines clarify the road width and make lanes easier to read.
			var edge_normal := Vector2(-delta.y, delta.x).normalized()
			var edge_offset := maxf(0.0, width * 0.5 - 0.22)
			for edge_sign in [-1.0, 1.0]:
				var edge_a := a + Vector3(edge_normal.x, 0.0, edge_normal.y) * edge_offset * edge_sign
				var edge_b := b + Vector3(edge_normal.x, 0.0, edge_normal.y) * edge_offset * edge_sign
				var edge_side := Vector3(edge_normal.x, 0.0, edge_normal.y) * 0.065
				_add_osm_quad(_osm_surfaces["road_edges"], edge_a + edge_side + Vector3.UP * 0.094, edge_a - edge_side + Vector3.UP * 0.094, edge_b - edge_side + Vector3.UP * 0.094, edge_b + edge_side + Vector3.UP * 0.094)
			var mark_side := edge_normal * 0.075
			var dash_start := 0.0
			while dash_start < length:
				var dash_end := minf(dash_start + 3.2, length)
				var mark_a := a.lerp(b, dash_start / length)
				var mark_b := a.lerp(b, dash_end / length)
				_add_osm_quad(_osm_surfaces["road_marks"],
					Vector3(mark_a.x + mark_side.x, 0.092, mark_a.z + mark_side.y),
					Vector3(mark_a.x - mark_side.x, 0.092, mark_a.z - mark_side.y),
					Vector3(mark_b.x - mark_side.x, 0.092, mark_b.z - mark_side.y),
					Vector3(mark_b.x + mark_side.x, 0.092, mark_b.z + mark_side.y))
				dash_start += 7.0
