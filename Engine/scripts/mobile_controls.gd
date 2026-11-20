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
var chat_toggle: Button
var chat_panel: PanelContainer
var chat_log: Label
var chat_input: LineEdit
var chat_history: Array[String] = []

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
	_create_chat_ui()
	_layout_controls()
	get_viewport().size_changed.connect(_on_viewport_resized)

func _on_viewport_resized() -> void:
	screen_size = get_viewport().get_visible_rect().size
	_layout_controls()
	hud.queue_redraw()

func _layout_controls() -> void:
	var short_side := minf(screen_size.x, screen_size.y)
	var ui_scale := clampf(short_side / 820.0, 0.82, 1.18)
	pad_radius = clampf(short_side * 0.125, 82.0, 116.0)
	pad_center = Vector2(maxf(pad_radius + 30.0, screen_size.x * 0.14), screen_size.y - maxf(pad_radius + 38.0, screen_size.y * 0.18))
	jump_button = Vector2(screen_size.x - 142.0 * ui_scale, screen_size.y - 150.0 * ui_scale)
	sprint_button = Vector2(screen_size.x - 300.0 * ui_scale, screen_size.y - 112.0 * ui_scale)
	vehicle_button = Vector2(screen_size.x - 145.0 * ui_scale, screen_size.y - 420.0 * ui_scale)
	handbrake_button = Vector2(screen_size.x - 145.0 * ui_scale, screen_size.y - 290.0 * ui_scale)
	gas_button = Vector2(screen_size.x - 145.0 * ui_scale, screen_size.y - 150.0 * ui_scale)
	brake_button = Vector2(screen_size.x - 310.0 * ui_scale, screen_size.y - 150.0 * ui_scale)
	if is_instance_valid(chat_toggle):
		chat_toggle.position = Vector2(20.0, 145.0)
	if is_instance_valid(chat_panel):
		chat_panel.position = Vector2(20.0, 195.0)

func _draw_hud() -> void:
	var font := ThemeDB.fallback_font
	var ui_scale := clampf(minf(screen_size.x, screen_size.y) / 820.0, 0.82, 1.18)
	var driving_now := vehicle != null and bool(vehicle.get("driving"))

	# Roleplay-style player card with clear hierarchy and larger status bars.
	var card := Rect2(20.0, 20.0, 326.0 * ui_scale, 112.0 * ui_scale)
	hud.draw_rect(card.grow(4.0), Color(0.0, 0.0, 0.0, 0.22), true, 15.0)
	hud.draw_rect(card, Color(0.025, 0.055, 0.085, 0.91), true, 14.0)
	hud.draw_rect(Rect2(card.position, Vector2(5.0, card.size.y)), Color("#d8a84f"), true)
	hud.draw_string(font, card.position + Vector2(20.0, 31.0) * ui_scale, "KOKBORI", HORIZONTAL_ALIGNMENT_LEFT, -1, int(22 * ui_scale), Color("#f5f8fb"))
	hud.draw_string(font, card.position + Vector2(20.0, 53.0) * ui_scale, "ASTANA  •  ГОРОДСКАЯ ЖИЗНЬ", HORIZONTAL_ALIGNMENT_LEFT, -1, int(11 * ui_scale), Color("#9db5c7"))
	hud.draw_string(font, card.position + Vector2(20.0, 78.0) * ui_scale, "ЗДОРОВЬЕ", HORIZONTAL_ALIGNMENT_LEFT, -1, int(11 * ui_scale), Color("#dce7ef"))
	hud.draw_rect(Rect2(card.position + Vector2(104.0, 66.0) * ui_scale, Vector2(196.0, 13.0) * ui_scale), Color("#182b38"), true, 6.0)
	hud.draw_rect(Rect2(card.position + Vector2(104.0, 66.0) * ui_scale, Vector2(180.0, 13.0) * ui_scale), Color("#54c58b"), true, 6.0)
	hud.draw_string(font, card.position + Vector2(20.0, 99.0) * ui_scale, "ВЫНОСЛИВОСТЬ", HORIZONTAL_ALIGNMENT_LEFT, -1, int(10 * ui_scale), Color("#dce7ef"))
	hud.draw_rect(Rect2(card.position + Vector2(120.0, 88.0) * ui_scale, Vector2(180.0, 9.0) * ui_scale), Color("#182b38"), true, 5.0)
	hud.draw_rect(Rect2(card.position + Vector2(120.0, 88.0) * ui_scale, Vector2(145.0, 9.0) * ui_scale), Color("#56aee8"), true, 5.0)

	# Larger minimap panel in the upper-right corner.
	var map_radius := 78.0 * ui_scale
	var map_center := Vector2(screen_size.x - map_radius - 26.0, map_radius + 27.0)
	hud.draw_circle(map_center, map_radius + 8.0, Color(0.0, 0.0, 0.0, 0.24))
	hud.draw_circle(map_center, map_radius, Color(0.018, 0.045, 0.065, 0.94))
	hud.draw_arc(map_center, map_radius - 4.0, 0.0, TAU, 72, Color("#d2b16e"), 3.0, true)
	hud.draw_line(map_center + Vector2(-48, 0) * ui_scale, map_center + Vector2(48, 0) * ui_scale, Color("#527286", 0.9), 5.0 * ui_scale)
	hud.draw_line(map_center + Vector2(0, -48) * ui_scale, map_center + Vector2(0, 48) * ui_scale, Color("#527286", 0.9), 5.0 * ui_scale)
	hud.draw_circle(map_center, 7.0 * ui_scale, Color("#f3c66c"))
	hud.draw_string(font, map_center + Vector2(-5.0, -map_radius - 7.0), "N", HORIZONTAL_ALIGNMENT_CENTER, 12.0, int(13 * ui_scale), Color("#f5f8fb"))

	# Chat is a local in-game console until multiplayer networking is added.
	# Left-side movement pad.
	hud.draw_circle(pad_center, pad_radius + 13.0, Color(0.0, 0.0, 0.0, 0.24))
	hud.draw_circle(pad_center, pad_radius, Color(0.025, 0.065, 0.095, 0.72))
	hud.draw_arc(pad_center, pad_radius, 0.0, TAU, 72, Color("#d2b16e", 0.95), 3.0, true)
	var knob := pad_center + stick_vector * pad_radius * 0.70
	hud.draw_circle(knob, 37.0 * ui_scale, Color("#b8cbd8", 0.96))
	hud.draw_arc(knob, 37.0 * ui_scale, 0.0, TAU, 48, Color("#ffffff"), 2.0, true)
	hud.draw_string(font, pad_center + Vector2(-25.0, pad_radius + 27.0), "MOVE", HORIZONTAL_ALIGNMENT_CENTER, 50.0, int(11 * ui_scale), Color("#e3edf4", 0.9))

	# Right-side actions use larger, high-contrast hit targets.
	if driving_now:
		_draw_action_button(gas_button, 82.0 * ui_scale, "ГАЗ", Color("#269d61"))
		_draw_action_button(brake_button, 72.0 * ui_scale, "ТОРМОЗ", Color("#bd4e4b"))
		_draw_action_button(handbrake_button, 63.0 * ui_scale, "РУЧНИК", Color("#bd8742"))
	else:
		_draw_action_button(jump_button, 66.0 * ui_scale, "ВВЕРХ" if (player != null and bool(player.get("flying"))) else "ПРЫЖОК", Color("#398bc2"))
		_draw_action_button(sprint_button, 54.0 * ui_scale, "ВНИЗ" if (player != null and bool(player.get("flying"))) else "БЕГ", Color("#269d72"))
	if vehicle != null and (driving_now or bool(vehicle.call("can_enter"))):
		_draw_action_button(vehicle_button, 66.0 * ui_scale, "ВЫЙТИ" if driving_now else "АВТО", Color("#bd9148"))

	if driving_now:
		# Dedicated speed panel, visually separated from the pedals.
		var panel_size := Vector2(224.0, 112.0) * ui_scale
		var panel_pos := Vector2(screen_size.x * 0.5 - panel_size.x * 0.5, 148.0 * ui_scale)
		hud.draw_rect(Rect2(panel_pos + Vector2(0, 5), panel_size), Color(0.0, 0.0, 0.0, 0.25), true, 13.0)
		hud.draw_rect(Rect2(panel_pos, panel_size), Color(0.02, 0.055, 0.08, 0.92), true, 13.0)
		hud.draw_rect(Rect2(panel_pos, Vector2(4.0, panel_size.y)), Color("#d8a84f"), true)
		hud.draw_string(font, panel_pos + Vector2(18.0, 27.0) * ui_scale, "СКОРОСТЬ", HORIZONTAL_ALIGNMENT_LEFT, -1, int(12 * ui_scale), Color("#a9bfce"))
		hud.draw_string(font, panel_pos + Vector2(16.0, 80.0) * ui_scale, str(vehicle.call("get_speed_kmh")), HORIZONTAL_ALIGNMENT_LEFT, 110.0 * ui_scale, int(43 * ui_scale), Color("#ffffff"))
		hud.draw_string(font, panel_pos + Vector2(128.0, 77.0) * ui_scale, "КМ/Ч", HORIZONTAL_ALIGNMENT_LEFT, 55.0, int(13 * ui_scale), Color("#d8b66d"))
		hud.draw_string(font, panel_pos + Vector2(18.0, 101.0) * ui_scale, "GAS АКТИВЕН" if gas_pressed else "KOKBORI MOTOR", HORIZONTAL_ALIGNMENT_LEFT, -1, int(9 * ui_scale), Color("#65d49a" if gas_pressed else "#8098a8"))
	else:
		hud.draw_string(font, Vector2(screen_size.x * 0.5 - 65.0, 34.0), "СВОБОДНЫЙ РЕЖИМ", HORIZONTAL_ALIGNMENT_CENTER, 150.0, int(12 * ui_scale), Color("#e4edf4", 0.9))
	var can_enter_now := vehicle != null and bool(vehicle.call("can_enter"))
	var driving_state := vehicle != null and bool(vehicle.get("driving"))
	var throttle_state := float(vehicle.get("throttle")) if vehicle != null else 0.0
	var speed_state := int(vehicle.call("get_speed_kmh")) if vehicle != null else 0
	var wheel_contacts := int(vehicle.call("get_wheel_contact_count")) if vehicle != null else 0
	var engine_output := float(vehicle.get("engine_force")) if vehicle != null else 0.0
	var diagnostic := "CAR %s | DRIVE %s | GAS %s | THR %.1f | WHL %d/4 | ENG %.0f | %d KM/H" % [
		("OK" if vehicle != null else "NULL"),
		("ON" if driving_state else "OFF"),
		("ON" if gas_pressed else "OFF"),
		throttle_state,
		wheel_contacts,
		engine_output,
		speed_state
	]
	hud.draw_string(font, Vector2(18.0, screen_size.y - 16.0), diagnostic, HORIZONTAL_ALIGNMENT_LEFT, screen_size.x - 36.0, 12, Color("#ffffff", 0.92))

func _draw_action_button(center: Vector2, radius: float, label: String, tint: Color) -> void:
	hud.draw_circle(center, radius + 9.0, Color(0.0, 0.0, 0.0, 0.28))
	hud.draw_circle(center, radius, Color(tint, 0.84))
	hud.draw_arc(center, radius - 2.0, 0.0, TAU, 56, Color("#f4f7f8", 0.92), 3.0, true)
	hud.draw_arc(center, radius - 8.0, 0.0, TAU, 56, Color(1.0, 1.0, 1.0, 0.20), 1.0, true)
	hud.draw_string(ThemeDB.fallback_font, center + Vector2(-radius * 0.82, 6.0), label, HORIZONTAL_ALIGNMENT_CENTER, radius * 1.64, int(clampf(radius * 0.25, 12.0, 19.0)), Color("#ffffff"))

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
	# Check driving controls before the joystick so compact screens cannot swallow GAS.
	if vehicle != null and bool(vehicle.get("driving")) and pos.distance_to(gas_button) <= 100.0:
		touches[index] = "gas"
		gas_pressed = true
		_update_vehicle_controls()
	elif vehicle != null and bool(vehicle.get("driving")) and pos.distance_to(brake_button) <= 90.0:
		touches[index] = "brake"
		brake_pressed = true
		_update_vehicle_controls()
	elif vehicle != null and bool(vehicle.get("driving")) and pos.distance_to(handbrake_button) <= 80.0:
		touches[index] = "handbrake"
		handbrake_pressed = true
		vehicle.call("set_handbrake", true)
	elif vehicle != null and (bool(vehicle.get("driving")) or bool(vehicle.call("can_enter"))) and pos.distance_to(vehicle_button) <= 84.0:
		touches[index] = "vehicle"
		vehicle.call("toggle_player")
		gas_pressed = false
		brake_pressed = false
		handbrake_pressed = false
		if vehicle != null:
			vehicle.call("set_handbrake", false)
		_update_vehicle_controls()
		hud.queue_redraw()
	elif pos.distance_to(pad_center) <= pad_radius * 1.65 and not touches.values().has("move"):
		touches[index] = "move"
		_update_stick(pos)
	elif pos.distance_to(jump_button) <= 84.0:
		touches[index] = "jump"
		if player != null:
			if bool(player.get("flying")):
				player.call("set_flight_vertical", 1.0)
			else:
				player.call("jump_now")
	elif pos.distance_to(sprint_button) <= 68.0:
		touches[index] = "run"
		sprinting = true
		if player != null:
			if bool(player.get("flying")):
				player.call("set_flight_vertical", -1.0)
			else:
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
	elif role == "jump" and player != null and bool(player.get("flying")):
		player.call("set_flight_vertical", 0.0)
	elif role == "run":
		sprinting = false
		if player != null:
			if bool(player.get("flying")):
				player.call("set_flight_vertical", 0.0)
			else:
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
		var throttle_value := 1.0 if gas_pressed else (-1.0 if brake_pressed else 0.0)
		var steering_value := 0.0 if absf(stick_vector.x) < 0.12 else stick_vector.x
		vehicle.call("set_controls", throttle_value, steering_value)

func _process(_delta: float) -> void:
	# Keep touch states applied even if the joystick and pedal are held together.
	_update_vehicle_controls()
	if hud != null:
		hud.queue_redraw()

func _set_action(action_name: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action_name)
	else:
		Input.action_release(action_name)

func _create_chat_ui() -> void:
	chat_toggle = Button.new()
	chat_toggle.text = "ЧАТ / КОМАНДЫ"
	chat_toggle.position = Vector2(20.0, 145.0)
	chat_toggle.size = Vector2(190.0, 42.0)
	chat_toggle.pressed.connect(_toggle_chat)
	hud.add_child(chat_toggle)

	chat_panel = PanelContainer.new()
	chat_panel.position = Vector2(20.0, 195.0)
	chat_panel.size = Vector2(390.0, 205.0)
	chat_panel.visible = false
	hud.add_child(chat_panel)

	var layout := VBoxContainer.new()
	chat_panel.add_child(layout)
	chat_log = Label.new()
	chat_log.text = "Локальный чат KOKBORI. Введи /help для списка команд."
	chat_log.custom_minimum_size = Vector2(360.0, 125.0)
	chat_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(chat_log)

	chat_input = LineEdit.new()
	chat_input.placeholder_text = "Сообщение или команда..."
	chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_input.text_submitted.connect(_submit_chat)
	layout.add_child(chat_input)

	var send_button := Button.new()
	send_button.text = "ОТПРАВИТЬ"
	send_button.pressed.connect(func(): _submit_chat(chat_input.text))
	layout.add_child(send_button)

func _toggle_chat() -> void:
	chat_panel.visible = not chat_panel.visible
	if chat_panel.visible:
		chat_input.grab_focus()
	else:
		chat_input.release_focus()

func _submit_chat(raw_text: String) -> void:
	var message := raw_text.strip_edges()
	if message.is_empty():
		return
	chat_input.clear()
	if message.begins_with("/"):
		_execute_command(message)
	else:
		_add_chat_line("Ты: " + message)

func _execute_command(raw_command: String) -> void:
	var parts := raw_command.split(" ", false, 1)
	var command := str(parts[0]).to_lower()
	match command:
		"/help":
			_add_chat_line("Команды: /fly, /unfly, /help")
			_add_chat_line("В полёте: джойстик — движение, ПРЫЖОК — вверх, БЕГ — вниз.")
		"/fly":
			if player != null:
				player.call("set_flying", true)
				_add_chat_line("Режим полёта включён.")
			else:
				_add_chat_line("Игрок не найден.")
		"/unfly":
			if player != null:
				player.call("set_flying", false)
				_add_chat_line("Режим полёта выключен.")
		_:
			_add_chat_line("Неизвестная команда. Напиши /help.")

func _add_chat_line(line: String) -> void:
	chat_history.append(line)
	while chat_history.size() > 6:
		chat_history.pop_front()
	chat_log.text = "\n".join(chat_history)
