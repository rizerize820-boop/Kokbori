extends CharacterBody3D

@export var move_speed: float = 5.2
@export var acceleration: float = 18.0
@export var gravity: float = 18.0
var camera_pivot: Node3D
var camera: Camera3D
var sprinting := false
var jump_requested := false

func _ready() -> void:
	name = "Player"
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)

	var body_mesh := MeshInstance3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.38
	body.height = 1.8
	body_mesh.mesh = body
	body_mesh.position.y = 0.9
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.34, 0.72)
	body_mesh.material_override = material
	add_child(body_mesh)

	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.45, 0)
	camera_pivot.rotation.x = deg_to_rad(-10.0)
	add_child(camera_pivot)
	var arm := SpringArm3D.new()
	arm.spring_length = 5.5
	arm.margin = 0.2
	camera_pivot.add_child(arm)
	camera = Camera3D.new()
	camera.position = Vector3(0, 0, 0)
	arm.add_child(camera)
	camera.current = true

func _physics_process(delta: float) -> void:
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	var forward := -camera_pivot.global_transform.basis.z
	var right := camera_pivot.global_transform.basis.x
	var direction := (right * input_dir.x + forward * -input_dir.y).normalized()
	var current_speed := move_speed * (1.55 if sprinting else 1.0)
	var target := direction * current_speed
	velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
		if jump_requested:
			velocity.y = 6.2
	jump_requested = false
	if direction.length() > 0.08:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 8.0)
	move_and_slide()

func apply_look(screen_delta: Vector2) -> void:
	# Dragging on the right half of the touchscreen rotates the camera.
	camera_pivot.rotation.y -= screen_delta.x * 0.006
	camera_pivot.rotation.x = clampf(
		camera_pivot.rotation.x - screen_delta.y * 0.0045,
		deg_to_rad(-65.0),
		deg_to_rad(35.0)
	)

func jump_now() -> void:
	jump_requested = true

func set_sprinting(enabled: bool) -> void:
	sprinting = enabled
