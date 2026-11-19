extends CanvasLayer

var pad: Control
var player: Node3D
var move_touch := -1
var look_touch := -1
var pad_center := Vector2.ZERO
var pad_radius := 88.0
var stick_vector := Vector2.ZERO
var screen_size := Vector2.ZERO

func _ready() -> void:
	player = get_parent().get_node_or_null("Player") as Node3D
	screen_size = get_viewport().get_visible_rect().size
	_layout_controls()
	pad = Control.new()
	pad.position = Vector2.ZERO
	pad.size = screen_size
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.draw.connect(_draw_controls)
	add_child(pad)
	get_viewport().size_changed.connect(_on_viewport_resized)

func _on_viewport_resized() -> void:
	screen_size = get_viewport().get_visible_rect().size
	pad.size = screen_size
	pad_center = Vector2(142.0, screen_size.y - 150.0)
	pad.queue_redraw()

func _layout_controls() -> void:
	var short_side := minf(screen_size.x, screen_size.y)
	pad_radius = clampf(short_side * 0.105, 64.0, 92.0)
	pad_center = Vector2(maxf(pad_radius + 24.0, screen_size.x * 0.13), screen_size.y - maxf(pad_radius + 30.0, screen_size.y * 0.18))

func _draw_controls() -> void:
	pad.draw_circle(pad_center, pad_radius + 13.0, Color(0.02, 0.04, 0.07, 0.22))
	pad.draw_circle(pad_center, pad_radius, Color(0.06, 0.10, 0.16, 0.50))
	pad.draw_arc(pad_center, pad_radius, 0.0, TAU, 72, Color(0.78, 0.86, 0.94, 0.82), 3.0, true)
	var knob := pad_center + stick_vector * pad_radius * 0.72
	pad.draw_circle(knob, 37.0, Color(0.76, 0.84, 0.92, 0.88))
	pad.draw_arc(knob, 37.0, 0.0, TAU, 48, Color(1, 1, 1, 0.9), 2.0, true)
	pad.draw_string(ThemeDB.fallback_font, Vector2(28, 38), "KOKBORI RP", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color(1, 1, 1, 0.88))
	pad.draw_string(ThemeDB.fallback_font, Vector2(34, screen_size.y - 28), "MOVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.65))
	pad.draw_string(ThemeDB.fallback_font, Vector2(screen_size.x - 170, screen_size.y - 28), "LOOK AROUND", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.65))

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < screen_size.x * 0.40 and move_touch == -1:
				move_touch = event.index
				_update_stick(event.position)
			elif event.position.x > screen_size.x * 0.42 and look_touch == -1:
				look_touch = event.index
		else:
			if event.index == move_touch:
				move_touch = -1
				stick_vector = Vector2.ZERO
				_apply_movement(Vector2.ZERO)
				pad.queue_redraw()
			if event.index == look_touch:
				look_touch = -1
	elif event is InputEventScreenDrag:
		if event.index == move_touch:
			_update_stick(event.position)
		elif event.index == look_touch and player != null:
			player.call("apply_look", event.relative)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if event.position.x < screen_size.x * 0.40:
				move_touch = 999
				_update_stick(event.position)
			else:
				look_touch = 999
		else:
			if move_touch == 999:
				move_touch = -1
				stick_vector = Vector2.ZERO
				_apply_movement(Vector2.ZERO)
				pad.queue_redraw()
			if look_touch == 999:
				look_touch = -1
	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and look_touch == 999 and player != null:
			player.call("apply_look", event.relative)

func _update_stick(screen_pos: Vector2) -> void:
	stick_vector = ((screen_pos - pad_center) / pad_radius).limit_length(1.0)
	_apply_movement(stick_vector)
	pad.queue_redraw()

func _apply_movement(v: Vector2) -> void:
	_set_action("move_left", v.x < -0.18)
	_set_action("move_right", v.x > 0.18)
	_set_action("move_forward", v.y < -0.18)
	_set_action("move_back", v.y > 0.18)

func _set_action(action_name: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action_name)
	else:
		Input.action_release(action_name)
