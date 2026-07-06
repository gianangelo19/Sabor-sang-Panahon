extends Control

const PHONE_SIZE := Vector2(360, 620)
const AMBOT_CONVERSATIONS := {
	"casual": {
		"opening": "Hello. I have no new clues or objective updates to analyze right now.",
		"questions": [
			{"text": "Can you check again?", "answer": "Check complete. No new evidence has been recorded since our last conversation."},
			{"text": "What should I do now?", "answer": "Continue your current objective and inspect anything that may connect to the investigation."},
			{"text": "How are you, AMBot?", "answer": "All mapping functions are normal. Thank you for asking. That question was not map-related, but it was acceptable."},
		],
		"closing": "I will notify you when new information is available."
	},
	"newspaper_scan": {
		"opening": "I detected severe damage in the newspaper. Document integrity is 24 percent. I can still recover several useful details.",
		"questions": [
			{"text": "What can you read?", "answer": "Readable data: La Paz, Iloilo City. Food category. Historical article."},
			{"text": "Can you identify the dish?", "answer": "Not yet. The name and most of the photograph are damaged. More evidence is required."},
			{"text": "Where should I start?", "answer": "A family source may recognize the surviving details. Your saved route records include Grandma's old house."},
		],
		"closing": "Evidence file created: Unknown La Paz Dish."
	},
	"grandma_clues": {
		"opening": "Grandma's testimony has been recorded: hot broth, soft noodles, garlic, and a crisp topping.",
		"questions": [
			{"text": "Where do these clues lead?", "answer": "The strongest match is a food prepared near La Paz Market."},
			{"text": "Why are memories useful?", "answer": "Repeated sensory details can connect incomplete records to people and places."},
			{"text": "What is my next step?", "answer": "Speak with a market vendor. Search area added to Maps."},
		],
		"closing": "Search area unlocked: La Paz Market."
	},
	"market_evidence": {
		"opening": "New ingredients recorded: fresh miki, pork broth, pork meat, and liver.",
		"questions": [
			{"text": "Do the ingredients match?", "answer": "Yes. They form a coherent noodle-soup profile, but the dish name remains unverified."},
			{"text": "Who else might remember?", "answer": "Travel patterns may reveal where customers went. A retired driver is marked near the old terminal."},
		],
		"closing": "Next lead marked: old jeepney terminal."
	},
	"family_house": {
		"opening": "Multiple testimonies now connect the lost dish to Grandma's neighborhood.",
		"questions": [
			{"text": "Is our house connected?", "answer": "Possibly. Testimony is consistent, but physical evidence is still required."},
			{"text": "What evidence should I find?", "answer": "Search for a serving object, recipe note, sign, photograph, or marks left by cooking."},
		],
		"closing": "Origin property marked: Grandma's old house."
	},
	"memory_bowl": {
		"opening": "Ingredient profile complete. Final identification requires the Memory Bowl.",
		"questions": [
			{"text": "Where is the bowl?", "answer": "Search the origin property. Cultural Echoes may reveal its hiding place."},
			{"text": "Can you identify the dish now?", "answer": "Not without the physical heritage artifact."},
		],
		"closing": "Token allowance exhausted. Manual search required."
	},
}

var phone_open := false
var current_app := "home"
var current_situation := ""
var asked_questions: Array[int] = []
var calculator_value := "0"
var calculator_stored := 0.0
var calculator_operation := ""
var calculator_waiting_for_value := false
var previous_mouse_mode := Input.MOUSE_MODE_CAPTURED
var player_was_enabled := true
var notes_text := "Things to remember:\n\n- Visit Grandma\n- Find something to eat"

var phone_frame: PanelContainer
var dim: ColorRect
var screen_stack: VBoxContainer
var title_label: Label
var time_label: Label
var notification_toast: Button
var notification_banner: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_interface()
	visible = true
	phone_frame.visible = false
	dim.visible = false
	GameState.phone_notification_received.connect(_on_notification_received)
	GameState.ambot_availability_changed.connect(_on_ambot_availability_changed)
	if GameState.has_ambot_notification():
		_on_notification_received(GameState.pending_ambot_notification)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("phone"):
		if phone_open:
			close_phone()
		else:
			open_phone()
		get_viewport().set_input_as_handled()
	elif phone_open and event.is_action_pressed("ui_cancel"):
		close_phone()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if time_label:
		var now := Time.get_time_dict_from_system()
		time_label.text = "%02d:%02d" % [now.hour, now.minute]

func _build_interface() -> void:
	dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.04, 0.35)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	notification_banner = Button.new()
	notification_banner.visible = false
	notification_banner.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	notification_banner.position = Vector2(-354, 24)
	notification_banner.size = Vector2(330, 76)
	notification_banner.alignment = HORIZONTAL_ALIGNMENT_LEFT
	notification_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notification_banner.add_theme_stylebox_override("normal", _style(Color("20343d"), Color("d8c49d"), 2, 6))
	notification_banner.pressed.connect(_open_ambot_from_notification)
	add_child(notification_banner)

	phone_frame = PanelContainer.new()
	phone_frame.custom_minimum_size = PHONE_SIZE
	phone_frame.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	phone_frame.position = Vector2(-PHONE_SIZE.x - 36, -PHONE_SIZE.y / 2.0)
	phone_frame.add_theme_stylebox_override("panel", _style(Color("18232b"), Color("d8c49d"), 8, 5))
	add_child(phone_frame)

	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 8)
	phone_frame.add_child(shell)

	var status := HBoxContainer.new()
	shell.add_child(status)
	time_label = Label.new()
	time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.add_child(time_label)
	var signal_label := Label.new()
	signal_label.text = "ILO  4G  87%"
	status.add_child(signal_label)

	notification_toast = Button.new()
	notification_toast.visible = false
	notification_toast.alignment = HORIZONTAL_ALIGNMENT_LEFT
	notification_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notification_toast.pressed.connect(_open_ambot_from_notification)
	shell.add_child(notification_toast)

	var header := HBoxContainer.new()
	shell.add_child(header)
	var back := Button.new()
	back.text = "<"
	back.tooltip_text = "Back to apps"
	back.custom_minimum_size = Vector2(42, 38)
	back.pressed.connect(show_home)
	header.add_child(back)
	title_label = Label.new()
	title_label.text = "My Phone"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	header.add_child(title_label)
	var close := Button.new()
	close.text = "X"
	close.tooltip_text = "Put phone away"
	close.custom_minimum_size = Vector2(42, 38)
	close.pressed.connect(close_phone)
	header.add_child(close)

	var separator := HSeparator.new()
	shell.add_child(separator)
	screen_stack = VBoxContainer.new()
	screen_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen_stack.add_theme_constant_override("separation", 8)
	shell.add_child(screen_stack)

	var hint := Label.new()
	hint.text = "P: put away"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(0.75, 0.78, 0.76)
	shell.add_child(hint)
	show_home()

func _style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func open_phone() -> void:
	if get_tree().paused:
		return
	phone_open = true
	dim.visible = true
	phone_frame.visible = true
	previous_mouse_mode = Input.mouse_mode
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_set_player_input(false)
	if current_app == "home":
		show_home()

func close_phone() -> void:
	phone_open = false
	dim.visible = false
	phone_frame.visible = false
	_set_player_input(player_was_enabled)
	Input.set_mouse_mode(previous_mouse_mode)

func _set_player_input(enabled: bool) -> void:
	var player := get_tree().root.find_child("ProtoController", true, false)
	if not player:
		return
	if not enabled:
		player_was_enabled = player.can_move
	player.can_move = enabled
	player.set_process_unhandled_input(enabled)

func _clear_screen() -> void:
	for child in screen_stack.get_children():
		child.queue_free()

func show_home() -> void:
	current_app = "home"
	title_label.text = "My Phone"
	_clear_screen()
	var greeting := Label.new()
	greeting.text = "Good day"
	greeting.add_theme_font_size_override("font_size", 26)
	screen_stack.add_child(greeting)
	var date := Time.get_date_dict_from_system()
	var date_label := Label.new()
	date_label.text = "%s %d, %d" % [_month_name(date.month), date.day, date.year]
	date_label.modulate = Color(0.75, 0.82, 0.80)
	screen_stack.add_child(date_label)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	screen_stack.add_child(grid)
	var ambot_label := "AMBot\nNew information" if GameState.has_ambot_notification() else "AMBot"
	_add_app_button(grid, ambot_label, _open_ambot)
	_add_app_button(grid, "Calculator", show_calculator)
	_add_app_button(grid, "Calendar", show_calendar)
	_add_app_button(grid, "Clock", show_clock)
	_add_app_button(grid, "Notes", show_notes)
	_add_app_button(grid, "Photos", show_photos)

func _add_app_button(parent: Control, label_text: String, callback: Callable, enabled := true) -> void:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(145, 80)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.disabled = not enabled
	button.tooltip_text = "Open " + label_text
	button.pressed.connect(callback)
	parent.add_child(button)

func show_calculator() -> void:
	current_app = "calculator"
	title_label.text = "Calculator"
	_clear_screen()
	var display := LineEdit.new()
	display.name = "CalculatorDisplay"
	display.text = calculator_value
	display.editable = false
	display.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	display.add_theme_font_size_override("font_size", 28)
	screen_stack.add_child(display)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen_stack.add_child(grid)
	for key in ["7", "8", "9", "/", "4", "5", "6", "*", "1", "2", "3", "-", "C", "0", "=", "+"]:
		var button := Button.new()
		button.text = key
		button.custom_minimum_size = Vector2(70, 58)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_calculator_key.bind(key, display))
		grid.add_child(button)

func _calculator_key(key: String, display: LineEdit) -> void:
	if key == "C":
		calculator_value = "0"
		calculator_stored = 0.0
		calculator_operation = ""
		calculator_waiting_for_value = false
	elif key in ["+", "-", "*", "/"]:
		calculator_stored = calculator_value.to_float()
		calculator_operation = key
		calculator_waiting_for_value = true
	elif key == "=":
		var right := calculator_value.to_float()
		var result := calculator_stored
		match calculator_operation:
			"+": result += right
			"-": result -= right
			"*": result *= right
			"/": result = 0.0 if is_zero_approx(right) else result / right
		calculator_value = str(result)
		calculator_operation = ""
		calculator_waiting_for_value = true
	else:
		if calculator_waiting_for_value or calculator_value == "0":
			calculator_value = key
			calculator_waiting_for_value = false
		else:
			calculator_value += key
	display.text = calculator_value

func show_calendar() -> void:
	current_app = "calendar"
	title_label.text = "Calendar"
	_clear_screen()
	var date := Time.get_date_dict_from_system()
	var heading := Label.new()
	heading.text = "%s %d" % [_month_name(date.month), date.year]
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 24)
	screen_stack.add_child(heading)
	var grid := GridContainer.new()
	grid.columns = 7
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen_stack.add_child(grid)
	for day_name in ["S", "M", "T", "W", "T", "F", "S"]:
		var label := Label.new()
		label.text = day_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(label)
	var first_date := Time.get_datetime_dict_from_datetime_string("%04d-%02d-01T00:00:00" % [date.year, date.month], false)
	var first_weekday: int = int(first_date.get("weekday", 0))
	for _blank in range(first_weekday):
		grid.add_child(Label.new())
	for day in range(1, _days_in_month(date.month, date.year) + 1):
		var day_label := Label.new()
		day_label.text = str(day)
		day_label.custom_minimum_size = Vector2(38, 38)
		day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if day == date.day:
			day_label.add_theme_color_override("font_color", Color("ffd166"))
		grid.add_child(day_label)

func show_clock() -> void:
	current_app = "clock"
	title_label.text = "Clock"
	_clear_screen()
	var center := VBoxContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	screen_stack.add_child(center)
	var large_time := Label.new()
	large_time.add_theme_font_size_override("font_size", 48)
	large_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(large_time)
	var date_label := Label.new()
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(date_label)
	var timer := Timer.new()
	timer.wait_time = 0.25
	timer.autostart = true
	timer.timeout.connect(func():
		if is_instance_valid(large_time):
			var now := Time.get_time_dict_from_system()
			large_time.text = "%02d:%02d:%02d" % [now.hour, now.minute, now.second]
			var today := Time.get_date_dict_from_system()
			date_label.text = "%s %d, %d" % [_month_name(today.month), today.day, today.year]
	)
	center.add_child(timer)
	timer.timeout.emit()

func show_notes() -> void:
	current_app = "notes"
	title_label.text = "Notes"
	_clear_screen()
	var note := TextEdit.new()
	note.text = notes_text
	note.placeholder_text = "Write a note..."
	note.size_flags_vertical = Control.SIZE_EXPAND_FILL
	note.text_changed.connect(func(): notes_text = note.text)
	screen_stack.add_child(note)

func show_photos() -> void:
	current_app = "photos"
	title_label.text = "Photos"
	_clear_screen()
	var empty := Label.new()
	empty.text = "No recent photos.\n\nRecovered story images will appear here."
	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen_stack.add_child(empty)

func _open_ambot() -> void:
	current_situation = GameState.consume_ambot_notification() if GameState.has_ambot_notification() else "casual"
	asked_questions.clear()
	show_ambot()

func _open_ambot_from_notification() -> void:
	open_phone()
	_open_ambot()

func show_ambot() -> void:
	current_app = "ambot"
	title_label.text = "AMBot"
	_clear_screen()
	notification_toast.visible = false
	notification_banner.visible = false
	var conversation: Dictionary = AMBOT_CONVERSATIONS.get(current_situation, {})
	if conversation.is_empty():
		var unavailable := Label.new()
		unavailable.text = "This notification is no longer available."
		screen_stack.add_child(unavailable)
		return
	_add_chat_bubble("AMBot", conversation.opening, false)
	_build_ambot_questions(conversation)

func _build_ambot_questions(conversation: Dictionary) -> void:
	var questions: Array = conversation.get("questions", [])
	var remaining := false
	for index in range(questions.size()):
		if asked_questions.has(index):
			continue
		remaining = true
		var question: Dictionary = questions[index]
		var button := Button.new()
		button.text = question.text
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_ask_ambot_question.bind(index, question, conversation))
		screen_stack.add_child(button)
	if not remaining:
		_add_chat_bubble("AMBot", conversation.closing, false)
		GameState.complete_ambot_conversation(current_situation)
		var done := Button.new()
		done.text = "Close conversation"
		done.pressed.connect(show_home)
		screen_stack.add_child(done)

func _ask_ambot_question(index: int, question: Dictionary, conversation: Dictionary) -> void:
	asked_questions.append(index)
	_clear_screen()
	_add_chat_bubble("You", question.text, true)
	_add_chat_bubble("AMBot", question.answer, false)
	_build_ambot_questions(conversation)

func _add_chat_bubble(speaker: String, message: String, from_player: bool) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color("31566b") if from_player else Color("29363d"), Color("6f8d8e"), 1, 6))
	var label := Label.new()
	label.text = speaker + "\n" + message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(label)
	screen_stack.add_child(panel)

func _on_notification_received(notification: Dictionary) -> void:
	notification_toast.text = "AMBot - %s\n%s" % [notification.get("title", "New message"), notification.get("preview", "Tap to open")]
	notification_toast.visible = true
	notification_banner.text = notification_toast.text
	notification_banner.visible = true

func _on_ambot_availability_changed(_available: bool) -> void:
	if current_app == "home" and phone_open:
		show_home()

func _month_name(month: int) -> String:
	return ["", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][clampi(month, 1, 12)]

func _days_in_month(month: int, year: int) -> int:
	if month == 2:
		return 29 if (year % 400 == 0 or (year % 4 == 0 and year % 100 != 0)) else 28
	return 30 if month in [4, 6, 9, 11] else 31
