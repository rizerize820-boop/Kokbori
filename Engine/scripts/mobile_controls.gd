extends CanvasLayer

var pad: Control
var knob: Control
var active_touch := -1
var look_touch := -1
var player: Node3D
var pad_center := Vector2.ZERO
var pad_radius := 92.0

func _ready() -> void:
	player = get_parent().get_node_or_null("Player") as Node3D
	pad = Control.new()
	pad.position = Vector2(42, get_viewport().get_visible_rect().size.y - 260)
	pad.size = Vector2(220, 220)
	pad.mouse_filter = Control.MOUSE_FILTER_STOP
	pad.draw.connect(_draw_pad)
	pad.gui_input.connect(_on_pad_input)
	add_child(pad)
	pad_center = pad.size * 0.5

	var hint := Label.new()
	hint.text = "KOKBORI RP  •  ASTANA TEST BUILD"
	hint.position = Vector2(24, 22)
	hint.add_theme_font_size_override("font_size", 22)
	add_child(hint)

	var note := Label.new()
	note.text = "Левый джойстик — движение"
	note.position = Vector2(42, get_viewport().get_visible_rect().size.y - 32)
	note.add_theme_font_size_override("font_size", 16)
	add_child(note)

	var look_note := Label.new()
	look_note.text = "Правая часть экрана — обзор камеры"
	look_note.position = Vector2(get_viewport().get_visible_rect().size.x - 330, get_viewport().get_visible_rect().size.y - 32)
	look_note.add_theme_font_size_override("font_size", 16)
	look_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(look_note)

func _draw_pad() -> void:
	pad.draw_circle(pad_center, pad_radius, Color(0.04, 0.08, 0.14, 0.42))
	pad.draw_arc(pad_center, pad_radius, 0, TAU, 64, Color(0.75, 0.84, 0.95, 0.8), 3.0)
	var knob_pos := pad_center
	if active_touch != -1:
		knob_pos = pad_center + _last_vector * pad_radius
	pad.draw_circle(knob_pos, 38, Color(0.78, 0.86, 0.96, 0.72))

var _last_vector := Vector2.ZERO

func _on_pad_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			active_touch = event.index
			_update_stick(event.position)
		else:
			if event.index == active_touch:
				active_touch = -1
				_last_vector = Vector2.ZERO
				_apply_actions(Vector2.ZERO)
				pad.queue_redraw()
	elif event is InputEventScreenDrag and event.index == active_touch:
		_update_stick(event.position)

func _update_stick(local_pos: Vector2) -> void:
	var vector := (local_pos - pad_center) / pad_radius
	_last_vector = vector.limit_length(1.0)
	_apply_actions(_last_vector)
	pad.queue_redraw()

func _apply_actions(v: Vector2) -> void:
	_set_action("move_left", v.x < -0.2)
	_set_action("move_right", v.x > 0.2)
	_set_action("move_forward", v.y < -0.2)
	_set_action("move_back", v.y > 0.2)

func _set_action(action_name: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action_name)
	else:
		Input.action_release(action_name)

func _input(event: InputEvent) -> void:
	var screen_width := get_viewport().get_visible_rect().size.x
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x > screen_width * 0.42 and look_touch == -1:
				look_touch = event.index
		else:
			if event.index == look_touch:
				look_touch = -1
	elif event is InputEventScreenDrag and event.index == look_touch:
		if player != null and player.has_method("apply_look"):
			player.call("apply_look", event.relative)
