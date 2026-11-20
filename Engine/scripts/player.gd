extends CharacterBody3D

@export var move_speed: float = 5.2
@export var acceleration: float = 18.0
@export var gravity: float = 18.0
var camera_pivot: Node3D
var camera: Camera3D
var sprinting := false
var jump_requested := false
var flying := false
var flight_vertical_input := 0.0
var flight_speed := 12.0
var left_arm_pivot: Node3D
var right_arm_pivot: Node3D
var left_leg_pivot: Node3D
var right_leg_pivot: Node3D
var animation_clock := 0.0
var visual_root: Node3D
const MIN_FLIGHT_SPEED := 2.0
const MAX_FLIGHT_SPEED := 80.0

func _ready() -> void:
	name = "Player"
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)

	_build_character_visual()

	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	camera_pivot.position = Vector3(0, 1.45, 0)
	camera_pivot.rotation.x = deg_to_rad(-10.0)
	add_child(camera_pivot)
	var arm := SpringArm3D.new()
	arm.spring_length = 5.5
	arm.margin = 0.2
	camera_pivot.add_child(arm)
	camera = Camera3D.new()
	camera.position = Vector3.ZERO
	arm.add_child(camera)
	camera.current = true


func _build_character_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "CharacterVisuals"
	add_child(visual_root)
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color("#c58f70")
	skin.roughness = 0.82
	var jacket := StandardMaterial3D.new()
	jacket.albedo_color = Color("#263f59")
	jacket.roughness = 0.72
	var trousers := StandardMaterial3D.new()
	trousers.albedo_color = Color("#202a35")
	trousers.roughness = 0.9
	var shoes := StandardMaterial3D.new()
	shoes.albedo_color = Color("#111820")
	shoes.roughness = 0.86

	var torso := MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.29
	torso_mesh.height = 0.92
	torso.mesh = torso_mesh
	torso.position = Vector3(0.0, 1.13, 0.0)
	torso.material_override = jacket
	visual_root.add_child(torso)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.44
	head.mesh = head_mesh
	head.position = Vector3(0.0, 1.78, 0.0)
	head.material_override = skin
	visual_root.add_child(head)

	var hair := MeshInstance3D.new()
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.225
	hair_mesh.height = 0.22
	hair.mesh = hair_mesh
	hair.position = Vector3(0.0, 1.91, 0.015)
	var hair_material := StandardMaterial3D.new()
	hair_material.albedo_color = Color("#242329")
	hair.material_override = hair_material
	visual_root.add_child(hair)

	left_arm_pivot = _make_limb_pivot("LeftArm", Vector3(-0.34, 1.43, 0.0), 0.13, 0.62, jacket)
	right_arm_pivot = _make_limb_pivot("RightArm", Vector3(0.34, 1.43, 0.0), 0.13, 0.62, jacket)
	left_leg_pivot = _make_limb_pivot("LeftLeg", Vector3(-0.16, 0.72, 0.0), 0.15, 0.72, trousers)
	right_leg_pivot = _make_limb_pivot("RightLeg", Vector3(0.16, 0.72, 0.0), 0.15, 0.72, trousers)
	for side in [-1.0, 1.0]:
		var shoe := MeshInstance3D.new()
		var shoe_mesh := BoxMesh.new()
		shoe_mesh.size = Vector3(0.25, 0.13, 0.38)
		shoe.mesh = shoe_mesh
		shoe.position = Vector3(side * 0.16, 0.10, -0.07)
		shoe.material_override = shoes
		visual_root.add_child(shoe)

func _make_limb_pivot(limb_name: String, pivot_position: Vector3, radius: float, length: float, material: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = limb_name
	pivot.position = pivot_position
	visual_root.add_child(pivot)
	var limb := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = length
	limb.mesh = capsule
	limb.position.y = -length * 0.5
	limb.material_override = material
	pivot.add_child(limb)
	return pivot

func _process(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > 0.35 and is_on_floor() and not flying:
		animation_clock += delta * (8.0 if sprinting else 6.0)
		var swing := sin(animation_clock) * 0.48
		left_leg_pivot.rotation.x = swing
		right_leg_pivot.rotation.x = -swing
		left_arm_pivot.rotation.x = -swing * 0.65
		right_arm_pivot.rotation.x = swing * 0.65
	else:
		left_leg_pivot.rotation.x = move_toward(left_leg_pivot.rotation.x, 0.0, delta * 4.0)
		right_leg_pivot.rotation.x = move_toward(right_leg_pivot.rotation.x, 0.0, delta * 4.0)
		left_arm_pivot.rotation.x = move_toward(left_arm_pivot.rotation.x, 0.0, delta * 4.0)
		right_arm_pivot.rotation.x = move_toward(right_arm_pivot.rotation.x, 0.0, delta * 4.0)


func _physics_process(delta: float) -> void:
	if global_position.y < -5.0:
		global_position = Vector3(global_position.x, 1.0, global_position.z)
		velocity = Vector3.ZERO
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	var forward := -camera_pivot.global_transform.basis.z
	var right := camera_pivot.global_transform.basis.x
	var direction := (right * input_dir.x + forward * -input_dir.y).normalized()
	var current_speed := flight_speed if flying else move_speed * (1.55 if sprinting else 1.0)
	var target := direction * current_speed
	velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * delta)

	if flying:
		var keyboard_vertical := Input.get_action_strength("ui_accept") - Input.get_action_strength("ui_down")
		var vertical := flight_vertical_input if absf(flight_vertical_input) > 0.01 else keyboard_vertical
		velocity.y = move_toward(velocity.y, vertical * flight_speed, acceleration * delta)
	else:
		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			velocity.y = 0.0
			if jump_requested:
				velocity.y = 6.2
	jump_requested = false
	move_and_slide()

func apply_look(screen_delta: Vector2) -> void:
	camera_pivot.rotation.y -= screen_delta.x * 0.006
	camera_pivot.rotation.x = clampf(
		camera_pivot.rotation.x - screen_delta.y * 0.0045,
		deg_to_rad(-65.0),
		deg_to_rad(35.0)
	)

func jump_now() -> void:
	if not flying:
		jump_requested = true

func set_sprinting(enabled: bool) -> void:
	sprinting = enabled

func set_flying(enabled: bool) -> void:
	flying = enabled
	flight_vertical_input = 0.0
	if not flying and velocity.y > 0.0:
		velocity.y = 0.0

func set_flight_vertical(direction: float) -> void:
	flight_vertical_input = clampf(direction, -1.0, 1.0) if flying else 0.0

func set_flight_speed(value: float) -> float:
	flight_speed = clampf(value, MIN_FLIGHT_SPEED, MAX_FLIGHT_SPEED)
	return flight_speed
