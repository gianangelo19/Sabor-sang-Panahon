extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.reset()
	_check(InputMap.has_action("phone"), "Phone input action exists")
	_check(not game_state.has_ambot_notification(), "AMBot starts without new information")
	_check(game_state.collected_ingredients.is_empty(), "Ingredient inventory starts empty")

	var phone_scene := load("res://ui/phone_ui.tscn") as PackedScene
	_check(phone_scene != null, "Phone scene loads")
	if phone_scene == null:
		_finish()
		return

	var phone := phone_scene.instantiate()
	root.add_child(phone)
	await process_frame
	_check(phone.current_app == "home", "Phone starts on the app launcher")
	_check(not phone.phone_frame.visible, "Phone starts put away")
	phone._open_ambot()
	_check(phone.current_app == "ambot", "AMBot can open without a notification")
	_check(phone.current_situation == "casual", "AMBot uses casual dialogue when no clues are new")
	_check(not game_state.has_ambot_notification(), "Casual chat does not create story information")
	phone.show_home()

	game_state.push_ambot_notification(
		"newspaper_scan",
		"Damaged article detected",
		"I can scan the surviving text."
	)
	await process_frame
	_check(game_state.has_ambot_notification(), "Story API delivers new AMBot information")
	_check(phone.notification_banner.visible, "Notification appears while phone is put away")

	phone.open_phone()
	_check(phone.phone_open, "Phone can be opened")
	phone._open_ambot()
	_check(phone.current_app == "ambot", "Notification opens the AMBot chat")
	_check(phone.current_situation == "newspaper_scan", "Correct authored situation is selected")
	_check(not game_state.has_ambot_notification(), "Opening AMBot marks new information as read")
	var question_count := 0
	for child in phone.screen_stack.get_children():
		if child is Button:
			question_count += 1
	_check(question_count == 3, "Situation presents its three predefined player questions")

	phone.show_calculator()
	_check(phone.current_app == "calculator", "Calculator app opens")
	var calculator_display := phone.screen_stack.find_child("CalculatorDisplay", true, false) as LineEdit
	phone._calculator_key("2", calculator_display)
	phone._calculator_key("+", calculator_display)
	phone._calculator_key("3", calculator_display)
	phone._calculator_key("=", calculator_display)
	_check(calculator_display.text == "5.0", "Calculator performs arithmetic")
	phone.show_maps()
	await process_frame
	_check(phone.current_app == "maps", "Maps app opens")
	_check(phone.screen_stack.find_child("MapView", true, false) != null, "Maps app creates the La Paz map view")
	phone.show_calendar()
	_check(phone.current_app == "calendar", "Calendar app opens")
	phone.show_clock()
	_check(phone.current_app == "clock", "Clock app opens")
	phone.show_notes()
	_check(phone.current_app == "notes", "Notes app opens")
	var note: TextEdit
	for child in phone.screen_stack.get_children():
		if child is TextEdit:
			note = child
	if note:
		note.text = "Buy medicine"
		note.text_changed.emit()
	phone.show_home()
	phone.show_notes()
	var reopened_note: TextEdit
	for child in phone.screen_stack.get_children():
		if child is TextEdit:
			reopened_note = child
	_check(reopened_note != null and reopened_note.text == "Buy medicine", "Notes persist while the game is running")
	phone.show_photos()
	_check(phone.current_app == "photos", "Photos app opens")
	phone.close_phone()
	_check(not phone.phone_open, "Phone can be put away")

	phone.queue_free()
	_finish()

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)

func _finish() -> void:
	if failures.is_empty():
		print("Phone UI verification passed.")
		quit(0)
	else:
		print("Phone UI verification failed: " + ", ".join(failures))
		quit(1)
