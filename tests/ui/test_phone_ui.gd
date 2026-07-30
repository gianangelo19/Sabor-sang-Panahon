extends SceneTree

class MockPlayer extends Node3D:
	var can_move := true

	func _unhandled_input(_event: InputEvent) -> void:
		pass


var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.reset()
	_check(InputMap.has_action("phone"), "Phone input action exists")
	var phone_uses_e := false
	var phone_uses_p := false
	for event: InputEvent in InputMap.action_get_events("phone"):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			phone_uses_e = (
				phone_uses_e
				or key_event.physical_keycode == KEY_E
				or key_event.keycode == KEY_E
			)
			phone_uses_p = (
				phone_uses_p
				or key_event.physical_keycode == KEY_P
				or key_event.keycode == KEY_P
			)
	_check(phone_uses_e and not phone_uses_p, "Phone action is bound to E instead of P")
	_check(not game_state.has_ambot_notification(), "AMBot starts without new information")
	_check(game_state.collected_ingredients.is_empty(), "Ingredient inventory starts empty")

	var phone_scene := load("res://game/ui/phone/phone_ui.tscn") as PackedScene
	_check(phone_scene != null, "Phone scene loads")
	if phone_scene == null:
		_finish()
		return

	var mock_player := MockPlayer.new()
	mock_player.name = "ProtoController"
	root.add_child(mock_player)
	var phone := phone_scene.instantiate()
	root.add_child(phone)
	await process_frame
	_check(phone.current_app == "home", "Phone starts on the app launcher")
	_check(not phone.phone_frame.visible, "Phone starts put away")
	_check(phone.phone_frame.find_child("PhoneArtwork", true, false) != null, "Phone uses the illustrated phone artwork")
	_check(phone.phone_frame.find_child("ScreenWallpaper", true, false) != null, "Phone uses the cow and dolphin wallpaper")
	var screen_margin := phone.phone_frame.find_child("ScreenMargin", true, false) as MarginContainer
	var glass_layer := phone.phone_frame.find_child("PhoneGlassLayer", true, false) as MarginContainer
	var cracked_glass := phone.phone_frame.find_child("CrackedGlassOverlay", true, false) as TextureRect
	_check(glass_layer != null and cracked_glass != null, "Phone has a separate cracked-glass layer")
	_check(
		glass_layer != null
		and screen_margin != null
		and glass_layer.get_index() > screen_margin.get_index(),
		"Cracked glass renders above the interactive screen"
	)
	_check(
		cracked_glass != null and cracked_glass.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"Cracked glass does not block app input"
	)
	_check(phone.phone_frame.find_child("StatusTime", true, false) != null, "Phone status bar shows the time")
	var location_label := phone.phone_frame.find_child("StatusLocation", true, false) as Label
	_check(location_label != null and location_label.text == "LA PAZ", "Phone status bar shows the location")
	_check(phone.phone_frame.find_child("StatusSignal", true, false) != null, "Phone status bar shows signal strength")
	_check(phone.phone_frame.find_child("StatusBattery", true, false) != null, "Phone status bar shows the battery")
	var ambot_app_button := phone.phone_frame.find_child("AMBotAppButton", true, false) as Button
	_check(ambot_app_button != null and ambot_app_button.icon != null, "Phone launcher uses the supplied app icons")
	var initial_ambot_badge := phone.phone_frame.find_child(
		"AMBotNotificationBadge",
		true,
		false,
	) as Label
	_check(
		initial_ambot_badge != null and not initial_ambot_badge.visible,
		"AMBot badge starts hidden when no notifications are waiting",
	)
	var calculator_app_button := phone.phone_frame.find_child("CalculatorAppButton", true, false) as Button
	_check(calculator_app_button != null and calculator_app_button.icon != null, "Calculator uses its matching generated icon")
	_check(phone.phone_frame.find_child("PhotosAppButton", true, false) == null, "Unused Photos app is removed")
	phone._open_ambot()
	_check(phone.current_app == "ambot", "AMBot can open without a notification")
	_check(phone.current_situation == "casual", "AMBot uses casual dialogue when no clues are new")
	_check(phone.ambot_typing_active, "AMBot begins its opening message with a typing effect")
	_check(phone.ambot_typing_players.size() == 2, "AMBot has alternating typing-sound players")
	var visible_before_tick: int = phone.ambot_typing_label.visible_characters
	phone._update_ambot_typing(0.2)
	_check(
		phone.ambot_typing_label.visible_characters > visible_before_tick,
		"AMBot reveals additional characters over time"
	)
	var typing_sound_playing := false
	for player in phone.ambot_typing_players:
		if player.playing:
			typing_sound_playing = true
	_check(typing_sound_playing, "AMBot plays text ticks while characters appear")
	_check(not game_state.has_ambot_notification(), "Casual chat does not create story information")
	phone.show_home()

	phone.show_objective_notification()
	game_state.push_ambot_notification(
		"newspaper_scan",
		"Damaged article detected",
		"I can scan the surviving text."
	)
	game_state.push_ambot_notification(
		"newspaper_scan",
		"Route updated",
		"Grandma's house is ready.",
	)
	await process_frame
	_check(game_state.has_ambot_notification(), "Story API delivers new AMBot information")
	_check(
		phone.unread_notification_count == 2,
		"Paired objective and AMBot updates count once while a second update increments the total",
	)
	_check(phone.notification_banner.visible, "Notification appears while phone is put away")
	_check(
		phone.notification_banner.text == "You have a new notification!"
		and phone.notification_banner.icon != null,
		"Notification uses the generic copy and AMBot app icon",
	)
	_check(
		is_equal_approx(phone.notification_bounce_timer.wait_time, 3.0),
		"Unread notification bounce repeats every three seconds",
	)
	var notification_rest_scale: Vector2 = phone.notification_banner.scale
	phone._bounce_notification_banner()
	_check(
		phone.notification_bounce_player != null
			and phone.notification_bounce_player.stream.resource_path.ends_with(
				"sfx_ui_hover.wav"
			)
			and phone.notification_bounce_player.volume_db <= -14.0
			and phone.notification_bounce_player.playing,
		"The notification bounce plays a subtle retro audio cue",
	)
	_check(
		phone.notification_bounce_tween != null
		and phone.notification_bounce_tween.is_valid(),
		"Unread notification starts its bounce animation",
	)
	await create_timer(0.4).timeout
	_check(
		phone.notification_banner.scale.is_equal_approx(notification_rest_scale),
		"Notification returns to its resting position after the bounce",
	)

	phone.open_phone()
	_check(phone.phone_open, "Phone can be opened")
	var ambot_badge := phone.phone_frame.find_child(
		"AMBotNotificationBadge",
		true,
		false,
	) as Label
	var badge_style := (
		ambot_badge.get_theme_stylebox("normal") as StyleBoxFlat
		if ambot_badge != null
		else null
	)
	_check(
		ambot_badge != null
		and ambot_badge.visible
		and ambot_badge.text == "2",
		"AMBot app icon displays the number of unchecked notifications",
	)
	_check(
		badge_style != null
		and badge_style.bg_color.r > badge_style.bg_color.g
		and badge_style.corner_radius_top_left >= 10,
		"Unread count uses a red circular badge",
	)
	_check(mock_player.can_move, "Player can keep walking while the phone is open")
	_check(
		mock_player.is_processing_unhandled_input(),
		"Phone leaves the player controller's input processing enabled"
	)
	phone._open_ambot()
	_check(phone.current_app == "ambot", "Notification opens the AMBot chat")
	_check(phone.current_situation == "newspaper_scan", "Correct authored situation is selected")
	_check(not game_state.has_ambot_notification(), "Opening AMBot marks new information as read")
	_check(phone.unread_notification_count == 0, "Opening AMBot clears the unread badge count")
	_check(phone.ambot_typing_active, "Story dialogue starts typing before questions appear")
	var question_count := _count_ambot_question_buttons(phone)
	_check(question_count == 0, "Player questions wait for AMBot to finish typing")
	phone._finish_ambot_typing()
	question_count = _count_ambot_question_buttons(phone)
	_check(question_count == 3, "Situation presents its three predefined player questions")
	var chat_bubbles_before_question := _count_ambot_chat_bubbles(phone)
	var history_before_question: int = game_state.ambot_chat_history.size()
	var first_question := _first_ambot_question_button(phone)
	_check(first_question != null, "AMBot exposes a selectable player message")
	if first_question != null:
		first_question.pressed.emit()
		_check(
			phone.ambot_typing_active
			and phone.ambot_typing_label.text.begins_with("You\n"),
			"Player messages use the chat typewriter effect",
		)
		_check(
			_count_ambot_chat_bubbles(phone) == chat_bubbles_before_question + 1,
			"Sending a player message keeps earlier chat bubbles visible",
		)
		_check(
			game_state.ambot_chat_history.size() == history_before_question + 2,
			"Player messages and AMBot replies are appended to chat history",
		)
		phone._finish_ambot_typing()
		_check(
			phone.ambot_typing_active
			and phone.ambot_typing_label.text.begins_with("AMBot\n"),
			"AMBot replies after the player's typing effect finishes",
		)
		_check(
			_count_ambot_chat_bubbles(phone) == chat_bubbles_before_question + 2,
			"AMBot replies append without resetting the thread",
		)
		phone._finish_ambot_typing()
		_check(
			_count_ambot_question_buttons(phone) == 2,
			"Answered questions disappear while unanswered questions remain",
		)
		var preserved_bubble_count := _count_ambot_chat_bubbles(phone)
		phone.show_home()
		phone.current_situation = "newspaper_scan"
		phone.show_ambot()
		_check(
			phone.ambot_scroll != null and phone.ambot_chat_stack != null,
			"AMBot history uses a scrollable chat thread",
		)
		_check(
			_count_ambot_chat_bubbles(phone) == preserved_bubble_count,
			"Reopening AMBot restores the existing chat history",
		)
		_check(
			_count_ambot_question_buttons(phone) == 2,
			"Reopening AMBot preserves answered-question state",
		)
		for index in range(8):
			phone._add_chat_bubble(
				"You",
				"Autoscroll verification message %d with enough text to fill the phone thread." % index,
				true,
				Callable(),
				false,
			)
		await process_frame
		phone.ambot_scroll.scroll_vertical = 0
		phone._add_chat_bubble(
			"You",
			"This is the newest player message.",
			true,
			Callable(),
			false,
		)
		await process_frame
		await process_frame
		await process_frame
		_check(
			_is_ambot_scrolled_to_bottom(phone),
			"Sending a player message scrolls the AMBot thread to the latest chat",
		)

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
	phone.close_phone()
	_check(not phone.phone_open, "Phone can be put away")
	_check(mock_player.can_move, "Closing the phone leaves player movement unchanged")
	phone.open_phone()
	_check(phone.current_app == "home", "Reopening the phone always returns to the home screen")
	phone.close_phone()

	phone.free()
	mock_player.free()
	_finish()


func _count_ambot_chat_bubbles(phone: Node) -> int:
	if phone.ambot_chat_stack == null:
		return 0
	var count := 0
	for child: Node in phone.ambot_chat_stack.get_children():
		if child.has_meta("ambot_chat_bubble"):
			count += 1
	return count


func _count_ambot_question_buttons(phone: Node) -> int:
	if phone.ambot_chat_stack == null:
		return 0
	var count := 0
	for child: Node in phone.ambot_chat_stack.get_children():
		if child is Button and child.has_meta("ambot_question_button"):
			count += 1
	return count


func _first_ambot_question_button(phone: Node) -> Button:
	if phone.ambot_chat_stack == null:
		return null
	for child: Node in phone.ambot_chat_stack.get_children():
		if child is Button and child.has_meta("ambot_question_button"):
			return child as Button
	return null


func _is_ambot_scrolled_to_bottom(phone: Node) -> bool:
	if phone.ambot_scroll == null:
		return false
	var scroll_bar: VScrollBar = phone.ambot_scroll.get_v_scroll_bar()
	var expected_bottom := maxf(scroll_bar.max_value - scroll_bar.page, 0.0)
	return (
		expected_bottom > 0.0
		and absf(float(phone.ambot_scroll.scroll_vertical) - expected_bottom) <= 1.0
	)


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
