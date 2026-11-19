extends CharacterBody3D

const MAX_SPEED := 72.22 # 260 km/h
const REVERSE_SPEED := 8.0
const ACCELERATION := 5.56 # 0-100 km/h in approximately 5 seconds
const BRAKE_DECELERATION := 15.0
const COAST_DECELERATION := 3.8
const STEERING_RATE := 1.65

var throttle := 0.0
var steering := 0.0
var speed := 0.0
var driving := false
var driver: CharacterBody3D
var driver_collider: CollisionShape3D
var driver_camera_pivot: Node3D
var driver_mesh: Node3D

func _ready() -> void:
	name = "Toyota_Camry_55"
	_build_car()

func _build_car() -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.05, 1.25, 4.55)
	collision.shape = shape
	collision.position.y = 0.78
	add_child(collision)

	_add_box("Camry 55 body", Vector3(0, 0.67, 0), Vector3(1.92, 0.62, 4.35), Color("#202832"))
	_add_box("Bonnet", Vector3(0, 0.91, -1.28), Vector3(1.82, 0.20, 1.55), Color("#252f3a"))
	_add_box("Roof", Vector3(0, 1.48, 0.05), Vector3(1.55, 0.18, 1.85), Color("#18222c"))
	_add_box("Front windscreen", Vector3(0, 1.22, -0.91), Vector3(1.48, 0.52, 0.075), Color("#527080"))
	_add_box("Rear windscreen", Vector3(0, 1.22, 1.02), Vector3(1.48, 0.48, 0.075), Color("#496474"))
	_add_box("Front grille", Vector3(0, 0.66, -2.19), Vector3(0.92, 0.22, 0.06), Color("#090d12"))
	_add_box("Chrome grille strip", Vector3(0, 0.80, -2.20), Vector3(1.08, 0.045, 0.045), Color("#aeb8c0"))
	_add_box("Front bumper", Vector3(0, 0.43, -2.18), Vector3(1.88, 0.20, 0.16), Color("#171d24"))
	_add_box("Rear bumper", Vector3(0, 0.43, 2.17), Vector3(1.88, 0.20, 0.16), Color("#171d24"))
	_add_box("Left headlight", Vector3(-0.66, 0.84, -2.17), Vector3(0.48, 0.17, 0.07), Color("#e9f0e8"))
	_add_box("Right headlight", Vector3(0.66, 0.84, -2.17), Vector3(0.48, 0.17, 0.07), Color("#e9f0e8"))
	_add_box("Left tail lamp", Vector3(-0.69, 0.82, 2.17), Vector3(0.42, 0.19, 0.07), Color("#a92727"))
	_add_box("Right tail lamp", Vector3(0.69, 0.82, 2.17), Vector3(0.42, 0.19, 0.07), Color("#a92727"))
	_add_box("Left side glass", Vector3(-0.79, 1.25, 0.05), Vector3(0.045, 0.42, 1.63), Color("#405968"))
	_add_box("Right side glass", Vector3(0.79, 1.25, 0.05), Vector3(0.045, 0.42, 1.63), Color("#405968"))

	for side in [-1.0, 1.0]:
		for axle in [-1.0, 1.0]:
			var pivot := Node3D.new()
			pivot.name = "Front" if axle < 0.0 else "Rear"
			pivot.position = Vector3(side * 0.99, 0.43, axle * 1.42)
			add_child(pivot)
			var tyre := MeshInstance3D.new()
			var tyre_mesh := CylinderMesh.new()
			tyre_mesh.top_radius = 0.39
			tyre_mesh.bottom_radius = 0.39
			tyre_mesh.height = 0.22
			tyre_mesh.radial_segments = 20
			tyre.mesh = tyre_mesh
			tyre.rotation.z = PI * 0.5
			tyre.material_override = _mat(Color("#101215"), 0.9, 0.0)
			pivot.add_child(tyre)
			var hub := MeshInstance3D.new()
			var hub_mesh := CylinderMesh.new()
			hub_mesh.top_radius = 0.22
			hub_mesh.bottom_radius = 0.22
			hub_mesh.height = 0.235
			hub_mesh.radial_segments = 16
			hub.mesh = hub_mesh
			hub.rotation.z = PI * 0.5
			hub.material_override = _mat(Color("#9da7ad"), 0.3, 0.65)
			pivot.add_child(hub)
			if axle < 0.0:
				pivot.set_meta("front_wheel", true)

func _mat(color: Color, roughness: float = 0.55, metallic: float = 0.12) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
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
	return not driving and driver != null and global_position.distance_to(driver.global_position) < 5.0

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
		driver.reparent(self, true)
		driver.global_position = global_position
		driver.global_rotation = global_rotation
	else:
		driving = false
		throttle = 0.0
		steering = 0.0
		speed = 0.0
		driver.reparent(get_parent(), true)
		driver.global_position = global_position + global_transform.basis.x * 2.2 + Vector3.UP * 0.15
		driver.global_rotation = Vector3.ZERO
		if driver_collider != null:
			driver_collider.set_deferred("disabled", false)
		if driver_mesh != null:
			driver_mesh.visible = true
		driver.set_physics_process(true)

func set_controls(gas: float, turn: float) -> void:
	throttle = clampf(gas, -1.0, 1.0)
	steering = clampf(turn, -1.0, 1.0)

func get_speed_kmh() -> int:
	return int(round(absf(speed) * 3.6))

func _physics_process(delta: float) -> void:
	# Keep the car recoverable if it ever slips outside the ground collider.
	if global_position.y < -5.0:
		global_position.y = 1.0
		velocity = Vector3.ZERO
		speed = 0.0
	if not driving:
		return
	var limit := MAX_SPEED if throttle >= 0.0 else REVERSE_SPEED
	if throttle > 0.0:
		speed = move_toward(speed, limit, ACCELERATION * delta)
	elif throttle < 0.0:
		if speed > 0.5:
			speed = move_toward(speed, 0.0, BRAKE_DECELERATION * delta)
		else:
			speed = move_toward(speed, -limit, ACCELERATION * delta)
	else:
		speed = move_toward(speed, 0.0, COAST_DECELERATION * delta)

	var speed_ratio := clampf(absf(speed) / MAX_SPEED, 0.0, 1.0)
	var steer_factor := lerpf(0.95, 0.30, speed_ratio)
	if absf(speed) > 0.15:
		rotate_y(-steering * STEERING_RATE * steer_factor * signf(speed) * delta)
	velocity = -global_transform.basis.z * speed
	velocity.y = -1.0
	move_and_slide()
	for child in get_children():
		if child is Node3D and child.has_meta("front_wheel"):
			child.rotation.y = -steering * 0.42
