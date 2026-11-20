extends VehicleBody3D

const MAX_SPEED_KMH := 140.0
const MAX_ENGINE_FORCE := 900.0
const MAX_REVERSE_FORCE := 420.0
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
	linear_damp = 0.12
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
	_add_wheel("FrontLeftWheel", Vector3(-0.79, -0.60, -1.34), true, false)
	_add_wheel("FrontRightWheel", Vector3(0.79, -0.60, -1.34), true, false)
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
	var model_resource := load("res://assets/vehicles/admiral.glb")
	if model_resource is PackedScene:
		var model := (model_resource as PackedScene).instantiate()
		model.name = "Camry_55_Model"
		add_child(model)
		_fit_model_to_wheels.call_deferred(model)
	else:
		push_warning("Could not load vehicle model; using fallback body.")
		_add_box("Fallback body", Vector3(0, -0.02, 0), Vector3(1.9, 0.65, 4.2), Color("#202832"))
		_add_box("Fallback roof", Vector3(0, 0.72, 0.05), Vector3(1.55, 0.18, 1.85), Color("#18222c"))

func _fit_model_to_wheels(model: Node3D) -> void:
	if not is_instance_valid(model):
		return
	var found_mesh := false
	var bounds := AABB()
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var mesh_bounds := mesh_instance.get_aabb()
		var relative_transform := model.global_transform.affine_inverse() * mesh_instance.global_transform
		for corner_index in range(8):
			var point := relative_transform * mesh_bounds.get_endpoint(corner_index)
			if not found_mesh:
				bounds = AABB(point, Vector3.ZERO)
				found_mesh = true
			else:
				bounds = bounds.expand(point)
	if found_mesh:
		# Lift the rendered body slightly above the wheel contact plane so it
		# does not visually clip into the road after suspension settles.
		# Keep the visible car body above the road. The previous offset placed
		# the imported mesh too low relative to the VehicleBody suspension origin.
		model.position.y = -0.48 - bounds.position.y
	else:
		push_warning("Vehicle model has no MeshInstance3D nodes; visual fitting skipped.")

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
	for child in player.get_children():
		if child is MeshInstance3D:
			driver_mesh = child
			break

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
	var braking := 1.0

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
