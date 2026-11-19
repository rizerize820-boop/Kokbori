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
	# Keep a simple physics collider independent from the imported visual model.
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.05, 1.25, 4.55)
	collision.shape = shape
	collision.position.y = 0.78
	add_child(collision)

	var model_resource := load("res://assets/vehicles/admiral.glb")
	if model_resource is PackedScene:
		var model := (model_resource as PackedScene).instantiate()
		model.name = "Camry_55_Model"
		model.position = Vector3(0.0, 0.45, 0.0)
		add_child(model)
	else:
		push_warning("Could not load res://assets/vehicles/admiral.glb; using fallback car body.")
		_add_box("Fallback Camry body", Vector3(0, 0.67, 0), Vector3(1.92, 0.62, 4.35), Color("#202832"))
		_add_box("Fallback roof", Vector3(0, 1.48, 0.05), Vector3(1.55, 0.18, 1.85), Color("#18222c"))

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
