extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const ControlsScript = preload("res://scripts/mobile_controls.gd")

func _ready() -> void:
	_build_environment()
	_build_city()
	var player := CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.position = Vector3(0, 0.15, 10)
	add_child(player)
	var controls := CanvasLayer.new()
	controls.set_script(ControlsScript)
	add_child(controls)

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	return mat

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	parent.add_child(body)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color)
	body.add_child(mesh_instance)
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
	env.sky = Sky.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.78, 0.88)
	env.ambient_light_energy = 0.7
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 1.25
	add_child(sun)
	var ground := StaticBody3D.new()
	ground.position.y = -0.25
	add_child(ground)
	var ground_mesh := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(180, 0.5, 180)
	ground_mesh.mesh = plane
	ground_mesh.material_override = _material(Color(0.38, 0.43, 0.35))
	ground.add_child(ground_mesh)
	var ground_collision := CollisionShape3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = plane.size
	ground_collision.shape = ground_shape
	ground.add_child(ground_collision)

func _build_city() -> void:
	# Main avenue and cross streets
	_box(self, Vector3(0, 0.015, 0), Vector3(18, 0.08, 150), Color(0.12, 0.13, 0.15))
	_box(self, Vector3(0, 0.02, 0), Vector3(150, 0.08, 12), Color(0.13, 0.14, 0.16))
	# Sidewalks
	for x in [-11.0, 11.0]:
		_box(self, Vector3(x, 0.08, 0), Vector3(3, 0.16, 150), Color(0.58, 0.59, 0.57))
	for z in [-9.0, 9.0]:
		_box(self, Vector3(0, 0.08, z), Vector3(150, 0.16, 2), Color(0.58, 0.59, 0.57))
	# District blocks: original placeholder buildings, not extracted game assets.
	for row in range(5):
		for col in range(5):
			var x := -52.0 + float(col) * 25.0
			var z := -52.0 + float(row) * 25.0
			if abs(x) < 17.0 or abs(z) < 13.0:
				continue
			var h := 8.0 + float((row * 7 + col * 3) % 5) * 3.0
			var w := 10.0 + float((row + col) % 3) * 2.0
			var shade := 0.52 + float((row + col) % 4) * 0.045
			_box(self, Vector3(x, h * 0.5, z), Vector3(w, h, 10), Color(shade, shade * 0.96, shade * 0.9))
	# Stylized Baiterek-inspired landmark at the end of the avenue.
	var tower := _box(self, Vector3(0, 10, -38), Vector3(1.8, 20, 1.8), Color(0.72, 0.76, 0.82))
	var sphere := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 4.0
	sphere_mesh.height = 8.0
	sphere.mesh = sphere_mesh
	sphere.position = Vector3(0, 22, -38)
	sphere.material_override = _material(Color(0.88, 0.68, 0.24))
	add_child(sphere)
	# A simple river channel and embankments on the west side.
	_box(self, Vector3(-66, -0.02, 0), Vector3(18, 0.12, 150), Color(0.16, 0.38, 0.55))
	_box(self, Vector3(-55, 0.12, 0), Vector3(2, 0.3, 150), Color(0.66, 0.64, 0.57))
