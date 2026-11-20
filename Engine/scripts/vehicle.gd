extends VehicleBody3D

const MAX_SPEED_KMH := 140.0
const MAX_ENGINE_FORCE := 4200.0
const MAX_REVERSE_FORCE := 2400.0
const MAX_BRAKE_FORCE := 55.0
const HANDBRAKE_FORCE := 90.0
const MAX_STEER_ANGLE := 0.45
const STEER_SPEED := 5.0

var throttle := 0.0
var steering_input := 0.0
var handbrake := false
var driving := false
var driver: CharacterBody3D
var driver_collider: CollisionShape3D
var driver_camera_pivot: Node3D
var driver_mesh: Node3D

func _ready() -> void:
	name = "Toyota_Camry_55"
	mass = 1250.0
	linear_damp = 0.05
	angular_damp = 1.8
	continuous_cd = true
	can_sleep = false
	collision_layer = 2
	# Ground is on layer 2 as well; oversized OSM building boxes are excluded.
	collision_mask = 2
	_build_chassis()
	_build_wheels()
	_build_visual()

func _build_chassis() -> void:
	var collision := CollisionShape3D.new()
	collision.name = "ChassisCollision"
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.9, 0.72, 4.25)
	collision.shape = shape
	collision.position = Vector3(0.0, -0.02, 0.0)
	add_child(collision)

func _build_wheels() -> void:
	_add_wheel("FrontLeftWheel", Vector3(-0.79, -0.60, -1.34), true, true)
	_add_wheel("FrontRightWheel", Vector3(0.79, -0.60, -1.34), true, true)
	_add_wheel("RearLeftWheel", Vector3(-0.79, -0.60, 1.34), false, true)
	_add_wheel("RearRightWheel", Vector3(0.79, -0.60, 1.34), false, true)

func _add_wheel(wheel_name: String, wheel_position: Vector3, steering_wheel: bool, traction_wheel: bool) -> void:
	var wheel := VehicleWheel3D.new()
	wheel.name = wheel_name
	wheel.position = wheel_position
	wheel.use_as_steering = steering_wheel
	wheel.use_as_traction = traction_wheel
	wheel.wheel_radius = 0.34
	wheel.wheel_rest_length = 0.20
	wheel.suspension_travel = 0.22
	wheel.suspension_stiffness = 25.0
	wheel.suspension_max_force = 9000.0
	wheel.suspension_damping_compression = 4.4
	wheel.suspension_damping_relaxation = 2.3
	wheel.wheel_friction_slip = 1.35
	wheel.wheel_roll_influence = 0.08
	add_child(wheel)

func _build_visual() -> void:
	# Detailed procedural sedan body. Physics chassis and wheel nodes stay intact.
	_add_box("Camry lower body", Vector3(0.0, -0.02, 0.0), Vector3(1.92, 0.62, 4.22), Color("#687783"))
	_add_box("Front hood", Vector3(0.0, 0.31, -1.38), Vector3(1.78, 0.20, 1.18), Color("#82919b"))
	_add_box("Rear deck", Vector3(0.0, 0.32, 1.48), Vector3(1.78, 0.19, 0.92), Color("#74838d"))
	_add_box("Cabin", Vector3(0.0, 0.77, 0.08), Vector3(1.58, 0.88, 2.05), Color("#263746"))
	_add_box("Roof", Vector3(0.0, 1.23, 0.12), Vector3(1.48, 0.12, 1.55), Color("#87949c"))
	# Side glazing and pillars.
	for side in [-1.0, 1.0]:
		_add_box("Front side glass", Vector3(side * 0.805, 0.84, -0.48), Vector3(0.035, 0.48, 0.78), Color("#24465d"))
		_add_box("Rear side glass", Vector3(side * 0.805, 0.84, 0.48), Vector3(0.035, 0.48, 0.72), Color("#24465d"))
		_add_box("Side sill", Vector3(side * 0.91, -0.30, 0.0), Vector3(0.10, 0.12, 2.85), Color("#303b43"))
		_add_box("Side mirror", Vector3(side * 0.96, 0.55, -0.76), Vector3(0.20, 0.15, 0.28), Color("#202b34"))
	# Windscreens, bumpers, grille and light clusters.
	_add_box("Front windshield", Vector3(0.0, 0.91, -0.94), Vector3(1.43, 0.52, 0.055), Color("#31536a"))
	_add_box("Rear windshield", Vector3(0.0, 0.91, 1.03), Vector3(1.43, 0.48, 0.055), Color("#31536a"))
	_add_box("Front bumper", Vector3(0.0, -0.22, -2.10), Vector3(1.88, 0.22, 0.16), Color("#303a42"))
	_add_box("Rear bumper", Vector3(0.0, -0.22, 2.10), Vector3(1.88, 0.22, 0.16), Color("#303a42"))
	_add_box("Front grille", Vector3(0.0, 0.02, -2.13), Vector3(0.72, 0.22, 0.035), Color("#111a21"))
	for side in [-1.0, 1.0]:
		_add_box("LED headlamp", Vector3(side * 0.66, 0.12, -2.13), Vector3(0.43, 0.16, 0.045), Color("#e8edf0"))
		_add_box("Tail lamp", Vector3(side * 0.66, 0.12, 2.13), Vector3(0.43, 0.18, 0.045), Color("#a83b38"))
		_add_box("Door handle", Vector3(side * 0.965, 0.22, 0.10), Vector3(0.035, 0.055, 0.22), Color("#d0d6d8"))
		_add_wheel_visual(Vector3(side * 0.94, -0.40, -1.34))
		_add_wheel_visual(Vector3(side * 0.94, -0.40, 1.34))

func _add_wheel_visual(pos: Vector3) -> void:
	var tire := MeshInstance3D.new()
	var tire_mesh := CylinderMesh.new()
	tire_mesh.top_radius = 0.35
	tire_mesh.bottom_radius = 0.35
	tire_mesh.height = 0.22
	tire_mesh.radial_segments = 20
	tire.mesh = tire_mesh
	tire.position = pos
	tire.rotation_degrees.z = 90.0
	tire.material_override = _mat(Color("#151a1f"))
	add_child(tire)
	var rim := MeshInstance3D.new()
	var rim_mesh := CylinderMesh.new()
	rim_mesh.top_radius = 0.20
	rim_mesh.bottom_radius = 0.20
	rim_mesh.height = 0.235
	rim_mesh.radial_segments = 16
	rim.mesh = rim_mesh
	rim.position = pos
	rim.rotation_degrees.z = 90.0
	rim.material_override = _mat(Color("#aab4bb"))
	add_child(rim)

func _mat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.55
	material.metallic = 0.12
	return material

func _add_box(part_name: String, pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = part_name
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = pos
	mesh_instance.material_override = _mat(color)
	add_child(mesh_instance)

func set_driver(player: CharacterBody3D) -> void:
	driver = player
	driver_collider = player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	driver_camera_pivot = player.get_node_or_null("CameraPivot") as Node3D
	driver_mesh = player.get_node_or_null("CharacterVisuals") as Node3D

func can_enter() -> bool:
	return not driving and driver != null and global_position.distance_to(driver.global_position) < 10.0

func toggle_player() -> void:
	if not driving:
		if not can_enter():
			return
		driving = true
		driver.set_physics_process(false)
		if driver_collider != null:
			driver_collider.set_deferred("disabled", true)
		if driver_mesh != null:
			driver_mesh.visible = false
		driver.global_position = global_position + Vector3.UP * 0.9
		driver.global_rotation = global_rotation
	else:
		driving = false
		throttle = 0.0
		steering_input = 0.0
		handbrake = false
		engine_force = 0.0
		brake = 0.0
		driver.global_position = global_position + global_transform.basis.x * 2.2 + Vector3.UP * 0.95
		driver.global_rotation = Vector3.ZERO
		if driver_collider != null:
			driver_collider.set_deferred("disabled", false)
		if driver_mesh != null:
			driver_mesh.visible = true
		driver.set_physics_process(true)

func set_controls(gas: float, turn: float) -> void:
	if not driving:
		throttle = 0.0
		steering_input = 0.0
		return
	throttle = clampf(gas, -1.0, 1.0)
	steering_input = clampf(turn, -1.0, 1.0)

func set_handbrake(pressed: bool) -> void:
	handbrake = pressed

func get_wheel_contact_count() -> int:
	var contacts := 0
	for child in get_children():
		if child is VehicleWheel3D and child.is_in_contact():
			contacts += 1
	return contacts

func get_speed_kmh() -> int:
	var forward_speed := linear_velocity.dot(-global_transform.basis.z)
	return int(round(absf(forward_speed) * 3.6))

func _physics_process(delta: float) -> void:
	if global_position.y < -5.0:
		global_position = Vector3(global_position.x, 1.15, global_position.z)
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
	if not driving:
		engine_force = 0.0
		brake = 0.0
		return

	var forward_speed := linear_velocity.dot(-global_transform.basis.z)
	var speed_kmh := absf(forward_speed) * 3.6
	var engine := 0.0
	var braking := 0.0

	if throttle > 0.05:
		if forward_speed < -0.5:
			braking = MAX_BRAKE_FORCE
		elif speed_kmh < MAX_SPEED_KMH:
			engine = MAX_ENGINE_FORCE * throttle
	elif throttle < -0.05:
		if forward_speed > 0.5:
			braking = MAX_BRAKE_FORCE
		elif speed_kmh < 35.0:
			engine = MAX_REVERSE_FORCE * throttle

	if handbrake:
		engine = 0.0
		braking = HANDBRAKE_FORCE

	engine_force = engine
	brake = braking

	var speed_factor := clampf(1.0 - speed_kmh / MAX_SPEED_KMH * 0.65, 0.35, 1.0)
	var target_steer := -steering_input * MAX_STEER_ANGLE * speed_factor
	steering = move_toward(steering, target_steer, STEER_SPEED * delta)

	if is_instance_valid(driver):
		driver.global_position = global_position + Vector3.UP * 0.85
		driver.global_rotation = global_rotation
