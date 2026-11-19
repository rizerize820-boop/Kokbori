extends CanvasLayer

var hud: Control
var player: Node3D
var vehicle: Node3D
var vehicle_button := Vector2.ZERO
var gas_button := Vector2.ZERO
var brake_button := Vector2.ZERO
var handbrake_button := Vector2.ZERO
var gas_pressed := false
var brake_pressed := false
var handbrake_pressed := false
var touches: Dictionary = {}
var pad_center := Vector2.ZERO
var pad_radius := 88.0
var stick_vector := Vector2.ZERO
var screen_size := Vector2.ZERO
var jump_button := Vector2.ZERO
var sprint_button := Vector2.ZERO
var sprinting := false

func _ready() -> void:
	player = get_parent().get_node_or_null("Player") as Node3D
	vehicle = get_parent().get_node_or_null("Toyota_Camry_55") as Node3D
	if vehicle == null:
		vehicle = get_parent().get_node_or_null("Vehicle") as Node3D
	screen_size = get_viewport().get_visible_rect().size
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.draw.connect(_draw_hud)
	add_child(hud)
	_layout_controls()
	get_viewport().size_changed.connect(_on_viewport_resized)

func _on_viewport_resized() -> void:
	screen_size = get_viewport().get_visible_rect().size
	_layout_controls()
	hud.queue_redraw()

func _layout_controls() -> void:
	var short_side := minf(screen_size.x, screen_size.y)
	pad_radius = clampf(short_side * 0.105, 68.0, 94.0)
	pad_center = Vector2(maxf(pad_radius + 26.0, screen_size.x * 0.12), screen_size.y - maxf(pad_radius + 34.0, screen_size.y * 0.17))
	jump_button = Vector2(screen_size.x - 104.0, screen_size.y - 112.0)
	sprint_button = Vector2(screen_size.x - 235.0, screen_size.y - 86.0)
	vehicle_button = Vector2(screen_size.x - 112.0, screen_size.y - 345.0)
	handbrake_button = Vector2(screen_size.x - 105.0, screen_size.y - 235.0)
	gas_button = Vector2(screen_size.x - 105.0, screen_size.y - 115.0)
	brake_button = Vector2(screen_size.x - 220.0, screen_size.y - 115.0)

func _draw_hud() -> void:
	var font := ThemeDB.fallback_font
	# Top identity/status panel.
	hud.draw_rect(Rect2(22, 18, 300, 66), Color(0.025, 0.055, 0.09, 0.78), true, 12.0)
	hud.draw_string(font, Vector2(42, 46), "KOKBORI  /  ASTANA", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#f3f7fb"))
	hud.draw_string(font, Vector2(42, 70), "CITIZEN  •  LEVEL 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#a9c4d8"))
	# Health and stamina indicators.
	hud.draw_rect(Rect2(344, 28, 170, 12), Color(0.02, 0.04, 0.07, 0.72), true, 6.0)
	hud.draw_rect(Rect2(344, 28, 148, 12), Color("#55c98b"), true, 6.0)
	hud.draw_string(font, Vector2(344, 62), "HEALTH  100", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#eaf2f7"))
	hud.draw_rect(Rect2(344, 68, 170, 7), Color(0.02, 0.04, 0.07, 0.72), true, 4.0)
	hud.draw_rect(Rect2(344, 68, 130, 7), Color("#5bb8ed"), true, 4.0)
	# Compact minimap.
	var map_center := Vector2(screen_size.x - 104.0, 104.0)
	hud.draw_circle(map_center, 76.0, Color(0.015, 0.035, 0.055, 0.78))
	hud.draw_arc(map_center, 72.0, 0.0, TAU, 64, Color("#a9c5d8", 0.9), 3.0, true)
	hud.draw_line(map_center + Vector2(-48, 0), map_center + Vector2(48, 0), Color("#66859a", 0.8), 5.0)
	hud.draw_line(map_center + Vector2(0, -48), map_center + Vector2(0, 48), Color("#66859a", 0.8), 5.0)
	hud.draw_circle(map_center, 7.0, Color("#ffd36b"))
	hud.draw_string(font, map_center + Vector2(-5, -83), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#f3f7fb"))
	# Movement joystick.
	hud.draw_circle(pad_center, pad_radius + 12.0, Color(0.015, 0.035, 0.06, 0.24))
	hud.draw_circle(pad_center, pad_radius, Color(0.035, 0.075, 0.12, 0.62))
	hud.draw_arc(pad_center, pad_radius, 0.0, TAU, 72, Color("#c4d8e8", 0.9), 3.0, true)
	var knob := pad_center + stick_vector * pad_radius * 0.70
	hud.draw_circle(knob, 34.0, Color("#b8cbdc", 0.94))
	hud.draw_arc(knob, 34.0, 0.0, TAU, 48, Color("#f5f9fc"), 2.0, true)
	# Action buttons.
	var driving_now := vehicle != null and bool(vehicle.get("driving"))
	if driving_now:
		_draw_action_button(gas_button, 49.0, "GAS", Color("#35b96f"))
		_draw_action_button(brake_button, 43.0, "BRAKE", Color("#d45b55"))
		_draw_action_button(handbrake_button, 38.0, "HANDBRK", Color("#bd8742"))
	else:
		_draw_action_button(jump_button, 48.0, "JUMP", Color("#4aa8e8"))
		_draw_action_button(sprint_button, 37.0, "RUN", Color("#54b98a"))
	if vehicle != null and (driving_now or bool(vehicle.call("can_enter"))):
		_draw_action_button(vehicle_button, 43.0, "EXIT" if driving_now else "CAR", Color("#d6a84e"))
		if driving_now:
			hud.draw_string(font, Vector2(screen_size.x * 0.5 - 55.0, 66), str(vehicle.call("get_speed_kmh")) + " KM/H", HORIZONTAL_ALIGNMENT_CENTER, 150, 22, Color("#ffffff"))
	hud.draw_string(font, Vector2(screen_size.x * 0.50 - 46.0, 34), "FREE CAMERA", HORIZONTAL_ALIGNMENT_CENTER, 140, 13, Color("#e4edf4", 0.78))

func _draw_action_button(center: Vector2, radius: float, label: String, tint: Color) -> void:
	hud.draw_circle(center, radius + 7.0, Color(0.015, 0.035, 0.06, 0.35))
	hud.draw_circle(center, radius, Color(tint, 0.72))
	hud.draw_arc(center, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.85), 2.0, true)
	hud.draw_string(ThemeDB.fallback_font, center + Vector2(-radius * 0.55, 5.0), label, HORIZONTAL_ALIGNMENT_CENTER, radius * 1.1, 14, Color("#ffffff"))

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_touch(event.index, event.position)
		else:
			_end_touch(event.index)
	elif event is InputEventScreenDrag:
		var role: String = str(touches.get(event.index, ""))
		if role == "move":
			_update_stick(event.position)
		elif role == "look" and player != null:
			player.call("apply_look", event.relative)
	elif OS.has_feature("editor") and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_touch(999, event.position)
		else:
			_end_touch(999)
	elif OS.has_feature("editor") and event is InputEventMouseMotion and touches.has(999):
		var role: String = str(touches[999])
		if role == "move":
			_update_stick(event.position)
		elif role == "look" and player != null:
			player.call("apply_look", event.relative)

func _begin_touch(index: int, pos: Vector2) -> void:
	if touches.has(index):
		return
	if pos.distance_to(pad_center) <= pad_radius * 1.65 and not touches.values().has("move"):
		touches[index] = "move"
		_update_stick(pos)
	elif vehicle != null and bool(vehicle.get("driving")) and pos.distance_to(gas_button) <= 58.0:
		touches[index] = "gas"
		gas_pressed = true
		_update_vehicle_controls()
	elif vehicle != null and bool(vehicle.get("driving")) and pos.distance_to(brake_button) <= 55.0:
		touches[index] = "brake"
		brake_pressed = true
		_update_vehicle_controls()
	elif vehicle != null and bool(vehicle.get("driving")) and pos.distance_to(handbrake_button) <= 52.0:
		touches[index] = "handbrake"
		handbrake_pressed = true
		vehicle.call("set_handbrake", true)
	elif vehicle != null and (bool(vehicle.get("driving")) or bool(vehicle.call("can_enter"))) and pos.distance_to(vehicle_button) <= 55.0:
		touches[index] = "vehicle"
		vehicle.call("toggle_player")
		gas_pressed = false
		brake_pressed = false
		handbrake_pressed = false
		if vehicle != null:
			vehicle.call("set_handbrake", false)
		_update_vehicle_controls()
		hud.queue_redraw()
	elif pos.distance_to(jump_button) <= 58.0:
		touches[index] = "jump"
		if player != null:
			player.call("jump_now")
	elif pos.distance_to(sprint_button) <= 48.0:
		touches[index] = "run"
		sprinting = true
		if player != null:
			player.call("set_sprinting", true)
	elif pos.x > screen_size.x * 0.52 and pos.y < screen_size.y * 0.78 and not touches.values().has("look"):
		touches[index] = "look"

func _end_touch(index: int) -> void:
	var role: String = str(touches.get(index, ""))
	touches.erase(index)
	if role == "move":
		stick_vector = Vector2.ZERO
		_apply_movement(Vector2.ZERO)
		hud.queue_redraw()
	elif role == "run":
		sprinting = false
		if player != null:
			player.call("set_sprinting", false)
	elif role == "gas":
		gas_pressed = false
		_update_vehicle_controls()
	elif role == "brake":
		brake_pressed = false
		_update_vehicle_controls()
	elif role == "handbrake":
		handbrake_pressed = false
		if vehicle != null:
			vehicle.call("set_handbrake", false)

func _update_stick(pos: Vector2) -> void:
	stick_vector = ((pos - pad_center) / pad_radius).limit_length(1.0)
	_apply_movement(stick_vector)
	hud.queue_redraw()

func _apply_movement(v: Vector2) -> void:
	if vehicle != null and bool(vehicle.get("driving")):
		vehicle.call("set_controls", (1.0 if gas_pressed else (-1.0 if brake_pressed else 0.0)), v.x)
		return
	_set_action("move_left", v.x < -0.18)
	_set_action("move_right", v.x > 0.18)
	_set_action("move_forward", v.y < -0.18)
	_set_action("move_back", v.y > 0.18)

func _update_vehicle_controls() -> void:
	if vehicle != null and bool(vehicle.get("driving")):
		vehicle.call("set_controls", 1.0 if gas_pressed else (-1.0 if brake_pressed else 0.0), stick_vector.x)

func _set_action(action_name: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action_name)
	else:
		Input.action_release(action_name)
