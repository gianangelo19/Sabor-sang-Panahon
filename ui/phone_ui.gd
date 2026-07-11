extends Control

const PHONE_SIZE := Vector2(368, 640)
const PHONE_SPRITE := preload("res://images/phone_ui/phone_sprite.png")
const AMBOT_ICON := preload("res://images/phone_ui/ambot_icon.png")
const MAPS_ICON := preload("res://images/phone_ui/maps_icon.png")
const CALENDAR_ICON := preload("res://images/phone_ui/calendar_icon.png")
const CLOCK_ICON := preload("res://images/phone_ui/clock_icon.png")
const NOTES_ICON := preload("res://images/phone_ui/notes_icon.png")
const PHOTOS_ICON := preload("res://images/phone_ui/photos_icon.png")
const CALCULATOR_ICON := preload("res://images/phone_ui/calculator_icon.png")
const MAP_VIEW_SCRIPT := preload("res://ui/map_view.gd")
const PHONE_OPEN_SOUND := preload("res://audio/retro_filipino_pack/phone_open.wav")
const PHONE_CLOSE_SOUND := preload("res://audio/retro_filipino_pack/phone_close.wav")
const PHONE_TAP_SOUND := preload("res://audio/retro_filipino_pack/phone_tap.wav")
const PHONE_BACK_SOUND := preload("res://audio/retro_filipino_pack/phone_back.wav")
const SELECT_APP_SOUND := preload("res://audio/retro_filipino_pack/select_app.wav")
const NOTIFICATION_SOUND := preload("res://audio/retro_filipino_pack/completed_task.wav")
const CLOCK_SOUND := preload("res://audio/clock_sound.mp3")
const AMBOT_TEXT_TICK_1 := preload(
	"res://minigames-main/box_unboxing/assets/audio/ui/sfx_text_tick_01.wav"
)
const AMBOT_TEXT_TICK_2 := preload(
	"res://minigames-main/box_unboxing/assets/audio/ui/sfx_text_tick_02.wav"
)
const AMBOT_CHARACTERS_PER_SECOND := 32.0
const AMBOT_CHARACTERS_PER_TICK := 3
const NAVY := Color("101c2b")
const DEEP_NAVY := Color("09121e")
const CREAM := Color("ffe1a3")
const GOLD := Color("f5a13b")
const ORANGE := Color("ef641d")
const MUTED_CREAM := Color("d9bf91")
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
	"arrival_maps": {
		"opening": "Arrival confirmed. Grandma's old house has been added to Maps and selected as your destination.",
		"questions": [
			{"text": "How do I find the house?", "answer": "Open Maps on your phone. Your position is blue, and the selected destination is marked in amber."},
			{"text": "What is the diamond on screen?", "answer": "It is a subtle destination beacon. It fades when you reach the entrance."},
			{"text": "Will Maps reveal everyone?", "answer": "No. New people and places appear only after evidence makes them relevant."},
		],
		"closing": "Current destination: Grandma's Old House."
	},
	"grandma_clues": {
		"opening": "Grandma's testimony has been recorded: soft noodles, tender meat, a deep salty taste, and a crisp topping.",
		"questions": [
			{"text": "Where do these clues lead?", "answer": "The strongest match is a food prepared near La Paz Market."},
			{"text": "Why are memories useful?", "answer": "Repeated sensory details can connect incomplete records to people and places."},
			{"text": "What is my next step?", "answer": "Speak with a market vendor. Search area added to Maps."},
		],
		"closing": "Search area unlocked: La Paz Market."
	},
	"market_vendor_1_clues": {
		"opening": "Meat acquired. The vendor remembers preparing pork and liver together, but shows the same unexplained memory gap around the dish.",
		"questions": [
			{"text": "Why can nobody name it?", "answer": "The shared pattern is statistically unusual. Multiple local memories appear incomplete in the same place."},
			{"text": "What should I do next?", "answer": "Test the remaining ingredient memories with the second market vendor."},
		],
		"closing": "Next testimony marked: Ginamos Vendor."
	},
	"market_vendor_2_clues": {
		"opening": "Ginamos acquired. The second vendor remembers measuring shrimp paste for a rich broth, but not the dish it seasoned.",
		"questions": [
			{"text": "Could everyone forget at once?", "answer": "Ordinary forgetting would not produce matching gaps across unrelated witnesses. More evidence is required."},
			{"text": "Who should I ask next?", "answer": "The chicharon vendor may recognize the final texture and has been marked in Maps."},
		],
		"closing": "Next testimony marked: Chicharon Vendor."
	},
	"chicharon_clues": {
		"opening": "Crushed chicharon acquired. The vendors recognize the meat, broth seasoning, and crisp topping, yet none remembers the dish itself.",
		"questions": [
			{"text": "What clues do we have now?", "answer": "Meat, ginamos or shrimp paste, and crushed chicharon. Fresh miki noodles are the fourth and final ingredient still needed."},
			{"text": "Why is the name still missing?", "answer": "The identity appears absent from Iloilo's collective memory. Family and physical evidence may restore it."},
		],
		"closing": "Collective memory anomaly recorded. The tindero has been marked for the final noodle ingredient."
	},
	"tindero_miki_clue": {
		"opening": "Fresh miki acquired. All four ingredients are now collected: meat, miki noodles, crushed chicharon, and ginamos or shrimp paste. The dish name remains missing.",
		"questions": [
			{"text": "Do all four ingredients fit?", "answer": "Yes. Meat, fresh miki noodles, ginamos or shrimp paste, and crushed chicharon form a consistent La Paz noodle-bowl profile."},
			{"text": "What should I do next?", "answer": "Return to your family's La Paz house and search around the property for physical evidence. Look closely at anything old or covered."},
		],
		"closing": "Ingredient set complete: 4 of 4. New objective: search the La Paz house for physical evidence."
	},
	"market_evidence": {
		"opening": "All four ingredients are recorded: meat, fresh miki noodles, ginamos or shrimp paste, and crushed chicharon.",
		"questions": [
			{"text": "Do the ingredients match?", "answer": "Yes. They form a coherent noodle-soup profile, but ingredients alone cannot verify the dish's name."},
			{"text": "Where should I search?", "answer": "Return to the La Paz house. Physical evidence on the property may connect the four ingredients to the forgotten dish."},
		],
		"closing": "Next lead: search around the La Paz house."
	},
	"family_house": {
		"opening": "The complete four-ingredient profile now points back to your family's La Paz house.",
		"questions": [
			{"text": "Is our house connected?", "answer": "Possibly. The testimony is consistent, but physical evidence is still required."},
			{"text": "What evidence should I find?", "answer": "Search around the property for old signage or another object that may have been covered or overlooked."},
		],
		"closing": "Search area: the La Paz house and its surroundings."
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
var back_button: Button
var notification_toast: Button
var notification_banner: Button
var phone_open_player: AudioStreamPlayer
var phone_close_player: AudioStreamPlayer
var phone_tap_player: AudioStreamPlayer
var phone_back_player: AudioStreamPlayer
var select_app_player: AudioStreamPlayer
var notification_player: AudioStreamPlayer
var clock_player: AudioStreamPlayer
var ambot_typing_players: Array[AudioStreamPlayer] = []
var ambot_typing_active := false
var ambot_typing_label: Label
var ambot_typing_full_text := ""
var ambot_typing_visible_characters := 0
var ambot_typing_accumulator := 0.0
var ambot_typing_sound_counter := 0
var ambot_typing_sound_index := 0
var ambot_typing_finished_callback: Callable

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_interface()
	_build_audio_players()
	visible = true
	phone_frame.visible = false
	dim.visible = false
	GameState.phone_notification_received.connect(_on_notification_received)
	GameState.ambot_availability_changed.connect(_on_ambot_availability_changed)
	if GameState.has_ambot_notification():
		_on_notification_received(GameState.pending_ambot_notification, false)

func _unhandled_input(event: InputEvent) -> void:
	if phone_open and current_app == "ambot" and ambot_typing_active:
		var skip_typing := event.is_action_pressed("ui_accept")
		if event is InputEventMouseButton:
			var mouse_event := event as InputEventMouseButton
			skip_typing = (
				skip_typing
				or (
					mouse_event.button_index == MOUSE_BUTTON_LEFT
					and mouse_event.pressed
				)
			)
		if skip_typing:
			_finish_ambot_typing()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("phone"):
		if phone_open:
			close_phone()
		else:
			open_phone()
		get_viewport().set_input_as_handled()
	elif phone_open and event.is_action_pressed("ui_cancel"):
		close_phone()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if time_label:
		var now := Time.get_time_dict_from_system()
		time_label.text = "%02d:%02d" % [now.hour, now.minute]
	_update_ambot_typing(delta)

func _build_interface() -> void:
	dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.015, 0.025, 0.045, 0.48)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	notification_banner = Button.new()
	notification_banner.visible = false
	notification_banner.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	notification_banner.position = Vector2(-354, 24)
	notification_banner.size = Vector2(330, 76)
	notification_banner.alignment = HORIZONTAL_ALIGNMENT_LEFT
	notification_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notification_banner.add_theme_color_override("font_color", CREAM)
	notification_banner.add_theme_stylebox_override("normal", _style(Color("142438"), GOLD, 2, 10))
	notification_banner.add_theme_stylebox_override("hover", _style(Color("1c344b"), CREAM, 2, 10))
	notification_banner.pressed.connect(_open_ambot_from_notification)
	add_child(notification_banner)

	phone_frame = PanelContainer.new()
	phone_frame.name = "PhoneFrame"
	phone_frame.custom_minimum_size = PHONE_SIZE
	phone_frame.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	phone_frame.position = Vector2(-PHONE_SIZE.x - 22, -PHONE_SIZE.y / 2.0)
	phone_frame.add_theme_stylebox_override("panel", _style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, 0))
	add_child(phone_frame)

	var phone_art := TextureRect.new()
	phone_art.name = "PhoneArtwork"
	phone_art.texture = _atlas_texture(PHONE_SPRITE, Rect2(240, 0, 600, 1080))
	phone_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	phone_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	phone_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	phone_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	phone_frame.add_child(phone_art)

	var screen_margin := MarginContainer.new()
	screen_margin.name = "ScreenMargin"
	screen_margin.add_theme_constant_override("margin_left", 52)
	screen_margin.add_theme_constant_override("margin_right", 52)
	screen_margin.add_theme_constant_override("margin_top", 50)
	screen_margin.add_theme_constant_override("margin_bottom", 34)
	phone_frame.add_child(screen_margin)

	var screen_surface := PanelContainer.new()
	screen_surface.name = "ScreenSurface"
	screen_surface.theme = _build_phone_theme()
	screen_surface.add_theme_stylebox_override("panel", _style(Color(0.035, 0.075, 0.12, 0.91), Color(1.0, 0.67, 0.25, 0.48), 1, 7, 7))
	screen_margin.add_child(screen_surface)

	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 5)
	screen_surface.add_child(shell)

	var status := HBoxContainer.new()
	status.name = "StatusBar"
	status.custom_minimum_size.y = 20
	status.add_theme_constant_override("separation", 4)
	shell.add_child(status)
	time_label = Label.new()
	time_label.name = "StatusTime"
	time_label.tooltip_text = "Current time"
	time_label.add_theme_font_size_override("font_size", 11)
	time_label.add_theme_color_override("font_color", CREAM)
	time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.add_child(time_label)
	var location_label := Label.new()
	location_label.name = "StatusLocation"
	location_label.text = "LA PAZ"
	location_label.tooltip_text = "Current location: La Paz"
	location_label.add_theme_font_size_override("font_size", 10)
	location_label.add_theme_color_override("font_color", GOLD)
	status.add_child(location_label)
	var signal_label := Label.new()
	signal_label.name = "StatusSignal"
	signal_label.text = "▂▄▆█"
	signal_label.tooltip_text = "Strong mobile signal"
	signal_label.add_theme_font_size_override("font_size", 10)
	signal_label.add_theme_color_override("font_color", CREAM)
	status.add_child(signal_label)
	var battery_label := Label.new()
	battery_label.name = "StatusBattery"
	battery_label.text = "▰ 87%"
	battery_label.tooltip_text = "Battery: 87 percent"
	battery_label.add_theme_font_size_override("font_size", 10)
	battery_label.add_theme_color_override("font_color", CREAM)
	status.add_child(battery_label)

	notification_toast = Button.new()
	notification_toast.visible = false
	notification_toast.alignment = HORIZONTAL_ALIGNMENT_LEFT
	notification_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notification_toast.add_theme_font_size_override("font_size", 11)
	notification_toast.add_theme_stylebox_override("normal", _style(Color("1a3045"), ORANGE, 1, 6, 7))
	notification_toast.pressed.connect(_open_ambot_from_notification)
	shell.add_child(notification_toast)

	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 32
	shell.add_child(header)
	back_button = Button.new()
	back_button.text = "‹"
	back_button.tooltip_text = "Back to apps"
	back_button.custom_minimum_size = Vector2(32, 30)
	back_button.add_theme_font_size_override("font_size", 23)
	back_button.pressed.connect(_on_back_pressed)
	header.add_child(back_button)
	title_label = Label.new()
	title_label.text = "APPS"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", CREAM)
	header.add_child(title_label)
	var close := Button.new()
	close.text = "×"
	close.tooltip_text = "Put phone away"
	close.custom_minimum_size = Vector2(32, 30)
	close.add_theme_font_size_override("font_size", 18)
	close.pressed.connect(close_phone)
	header.add_child(close)

	var separator := HSeparator.new()
	shell.add_child(separator)
	screen_stack = VBoxContainer.new()
	screen_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen_stack.add_theme_constant_override("separation", 6)
	shell.add_child(screen_stack)

	var hint := Label.new()
	hint.text = "P  PUT AWAY"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", MUTED_CREAM)
	shell.add_child(hint)
	show_home()

func _build_audio_players() -> void:
	phone_open_player = _create_sfx_player(PHONE_OPEN_SOUND)
	phone_close_player = _create_sfx_player(PHONE_CLOSE_SOUND)
	phone_tap_player = _create_sfx_player(PHONE_TAP_SOUND)
	phone_back_player = _create_sfx_player(PHONE_BACK_SOUND)
	select_app_player = _create_sfx_player(SELECT_APP_SOUND)
	notification_player = _create_sfx_player(NOTIFICATION_SOUND)
	clock_player = _create_sfx_player(CLOCK_SOUND)
	clock_player.finished.connect(_on_clock_sound_finished)
	ambot_typing_players = [
		_create_sfx_player(AMBOT_TEXT_TICK_1),
		_create_sfx_player(AMBOT_TEXT_TICK_2),
	]
	for player in ambot_typing_players:
		player.volume_db = -10.0

func _create_sfx_player(stream: AudioStream) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "SFX"
	add_child(player)
	return player

func _play_sfx(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	player.stop()
	player.play()

func _style(fill: Color, border: Color, border_width: int, radius: int, margin := 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style

func _build_phone_theme() -> Theme:
	var phone_theme := Theme.new()
	phone_theme.set_color("font_color", "Label", CREAM)
	phone_theme.set_color("font_color", "Button", CREAM)
	phone_theme.set_color("font_hover_color", "Button", Color.WHITE)
	phone_theme.set_color("font_pressed_color", "Button", DEEP_NAVY)
	phone_theme.set_color("font_color", "LineEdit", CREAM)
	phone_theme.set_color("font_color", "TextEdit", CREAM)
	phone_theme.set_color("caret_color", "TextEdit", GOLD)
	phone_theme.set_color("selection_color", "TextEdit", Color(0.93, 0.39, 0.11, 0.55))
	phone_theme.set_font_size("font_size", "Label", 13)
	phone_theme.set_font_size("font_size", "Button", 12)
	phone_theme.set_stylebox("normal", "Button", _style(Color("17283b"), Color("715b3f"), 1, 6, 6))
	phone_theme.set_stylebox("hover", "Button", _style(Color("263d52"), GOLD, 1, 6, 6))
	phone_theme.set_stylebox("pressed", "Button", _style(GOLD, CREAM, 1, 6, 6))
	phone_theme.set_stylebox("focus", "Button", _style(Color.TRANSPARENT, CREAM, 1, 6, 6))
	phone_theme.set_stylebox("normal", "LineEdit", _style(Color("091522"), GOLD, 1, 5, 7))
	phone_theme.set_stylebox("normal", "TextEdit", _style(Color("fff0c9"), GOLD, 1, 5, 7))
	phone_theme.set_color("font_color", "TextEdit", Color("402512"))
	return phone_theme

func _atlas_texture(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas

func _app_icon(texture: Texture2D) -> AtlasTexture:
	return _atlas_texture(texture, Rect2(220, 220, 640, 640))

func open_phone() -> void:
	if get_tree().paused:
		return
	if phone_open:
		return
	_play_sfx(phone_open_player)
	phone_open = true
	dim.visible = true
	phone_frame.visible = true
	previous_mouse_mode = Input.mouse_mode
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_set_player_input(false)
	show_home()

func close_phone() -> void:
	if not phone_open:
		return
	_play_sfx(phone_close_player)
	_stop_clock_sound()
	_cancel_ambot_typing()
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
	_stop_clock_sound()
	_cancel_ambot_typing()
	for child in screen_stack.get_children():
		child.queue_free()


func _stop_clock_sound() -> void:
	if clock_player and clock_player.playing:
		clock_player.stop()


func _on_clock_sound_finished() -> void:
	if current_app == "clock" and phone_open:
		clock_player.play()

func show_home() -> void:
	current_app = "home"
	title_label.text = "APPS"
	back_button.modulate.a = 0.0
	back_button.disabled = true
	_clear_screen()
	var greeting := Label.new()
	greeting.text = "GOOD DAY"
	greeting.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	greeting.add_theme_font_size_override("font_size", 20)
	greeting.add_theme_color_override("font_color", CREAM)
	screen_stack.add_child(greeting)
	var date := Time.get_date_dict_from_system()
	var date_label := Label.new()
	date_label.text = "%s %d, %d" % [_month_name(date.month), date.day, date.year]
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_label.add_theme_font_size_override("font_size", 11)
	date_label.add_theme_color_override("font_color", GOLD)
	screen_stack.add_child(date_label)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 5)
	screen_stack.add_child(grid)
	var ambot_label := "AMBot •" if GameState.has_ambot_notification() else "AMBot"
	_add_app_button(grid, ambot_label, _open_ambot, _app_icon(AMBOT_ICON))
	_add_app_button(grid, "Maps", show_maps, _app_icon(MAPS_ICON))
	_add_app_button(grid, "Calendar", show_calendar, _app_icon(CALENDAR_ICON))
	_add_app_button(grid, "Clock", show_clock, _app_icon(CLOCK_ICON))
	_add_app_button(grid, "Notes", show_notes, _app_icon(NOTES_ICON))
	_add_app_button(grid, "Photos", show_photos, _app_icon(PHOTOS_ICON))
	_add_app_button(grid, "Calculator", show_calculator, _app_icon(CALCULATOR_ICON))

func show_maps() -> void:
	current_app = "maps"
	title_label.text = "Maps"
	_show_back_button()
	_clear_screen()
	var map_view := MAP_VIEW_SCRIPT.new()
	map_view.name = "MapView"
	map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen_stack.add_child(map_view)
	var hint := Label.new()
	hint.text = "Choose a destination to guide the beacon."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", MUTED_CREAM)
	screen_stack.add_child(hint)

func _add_app_button(parent: Control, label_text: String, callback: Callable, icon_texture: Texture2D = null, enabled := true) -> void:
	var app := VBoxContainer.new()
	app.custom_minimum_size = Vector2(76, 84)
	app.add_theme_constant_override("separation", 0)
	parent.add_child(app)
	var button := Button.new()
	button.name = label_text.replace(" •", "") + "AppButton"
	button.custom_minimum_size = Vector2(68, 64)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = "Open " + label_text.replace(" •", "")
	button.disabled = not enabled
	button.focus_mode = Control.FOCUS_ALL
	if icon_texture:
		button.icon = icon_texture
		button.expand_icon = true
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.add_theme_stylebox_override("normal", _style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 7, 2))
		button.add_theme_stylebox_override("hover", _style(Color(0.96, 0.43, 0.12, 0.18), GOLD, 1, 7, 2))
		button.add_theme_stylebox_override("pressed", _style(Color(0.96, 0.43, 0.12, 0.35), CREAM, 1, 7, 2))
	else:
		button.text = "+ −\n× ÷"
		button.add_theme_font_size_override("font_size", 17)
		button.add_theme_color_override("font_color", CREAM)
		button.add_theme_stylebox_override("normal", _style(Color("182a3e"), GOLD, 2, 9, 3))
	button.pressed.connect(func():
		_play_sfx(select_app_player)
		callback.call()
	)
	app.add_child(button)
	var app_label := Label.new()
	app_label.text = label_text
	app_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	app_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	app_label.add_theme_font_size_override("font_size", 10)
	app_label.add_theme_color_override("font_color", CREAM if not label_text.ends_with("•") else GOLD)
	app.add_child(app_label)

func _show_back_button() -> void:
	back_button.disabled = false
	back_button.modulate.a = 1.0

func _on_back_pressed() -> void:
	_play_sfx(phone_back_player)
	show_home()

func show_calculator() -> void:
	current_app = "calculator"
	title_label.text = "Calculator"
	_show_back_button()
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
		button.custom_minimum_size = Vector2(48, 50)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_calculator_key.bind(key, display))
		grid.add_child(button)

func _calculator_key(key: String, display: LineEdit) -> void:
	_play_sfx(phone_tap_player)
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
	_show_back_button()
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
		day_label.custom_minimum_size = Vector2(28, 34)
		day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if day == date.day:
			day_label.add_theme_color_override("font_color", Color("ffd166"))
		grid.add_child(day_label)

func show_clock() -> void:
	current_app = "clock"
	title_label.text = "Clock"
	_show_back_button()
	_clear_screen()
	_play_sfx(clock_player)
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
	_show_back_button()
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
	_show_back_button()
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
	if phone_open:
		_play_sfx(phone_tap_player)
	open_phone()
	_open_ambot()

func show_ambot() -> void:
	current_app = "ambot"
	title_label.text = "AMBot"
	_show_back_button()
	_clear_screen()
	notification_toast.visible = false
	notification_banner.visible = false
	var conversation: Dictionary = AMBOT_CONVERSATIONS.get(current_situation, {})
	if conversation.is_empty():
		var unavailable := Label.new()
		unavailable.text = "This notification is no longer available."
		screen_stack.add_child(unavailable)
		return
	_add_chat_bubble(
		"AMBot",
		conversation.opening,
		false,
		_build_ambot_questions.bind(conversation)
	)

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
		_add_chat_bubble(
			"AMBot",
			conversation.closing,
			false,
			_finish_ambot_conversation
		)

func _ask_ambot_question(index: int, question: Dictionary, conversation: Dictionary) -> void:
	_play_sfx(phone_tap_player)
	asked_questions.append(index)
	_clear_screen()
	_add_chat_bubble("You", question.text, true)
	_add_chat_bubble(
		"AMBot",
		question.answer,
		false,
		_build_ambot_questions.bind(conversation)
	)


func _finish_ambot_conversation() -> void:
	GameState.complete_ambot_conversation(current_situation)
	var done := Button.new()
	done.text = "Close conversation"
	done.pressed.connect(func():
		_play_sfx(phone_back_player)
		show_home()
	)
	screen_stack.add_child(done)


func _add_chat_bubble(
	speaker: String,
	message: String,
	from_player: bool,
	on_typing_finished: Callable = Callable()
) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color("31566b") if from_player else Color("29363d"), Color("6f8d8e"), 1, 6))
	var label := Label.new()
	label.text = speaker + "\n" + message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(label)
	screen_stack.add_child(panel)
	if from_player:
		if on_typing_finished.is_valid():
			on_typing_finished.call()
		return
	_start_ambot_typing(label, speaker.length() + 1, on_typing_finished)


func _start_ambot_typing(
	label: Label,
	initial_visible_characters: int,
	on_finished: Callable
) -> void:
	_cancel_ambot_typing()
	ambot_typing_label = label
	ambot_typing_full_text = label.text
	ambot_typing_visible_characters = initial_visible_characters
	ambot_typing_accumulator = 0.0
	ambot_typing_sound_counter = 0
	ambot_typing_finished_callback = on_finished
	ambot_typing_label.visible_characters = initial_visible_characters
	ambot_typing_active = true


func _update_ambot_typing(delta: float) -> void:
	if not ambot_typing_active:
		return
	if ambot_typing_label == null or not is_instance_valid(ambot_typing_label):
		_cancel_ambot_typing()
		return

	ambot_typing_accumulator += delta * AMBOT_CHARACTERS_PER_SECOND
	while ambot_typing_accumulator >= 1.0 and ambot_typing_active:
		ambot_typing_accumulator -= 1.0
		ambot_typing_visible_characters += 1
		ambot_typing_label.visible_characters = ambot_typing_visible_characters
		var typed_character := ambot_typing_full_text.substr(
			ambot_typing_visible_characters - 1,
			1
		)
		if not typed_character.strip_edges().is_empty():
			ambot_typing_sound_counter += 1
			if ambot_typing_sound_counter >= AMBOT_CHARACTERS_PER_TICK:
				ambot_typing_sound_counter = 0
				_play_ambot_typing_sound()

		if ambot_typing_visible_characters >= ambot_typing_full_text.length():
			_finish_ambot_typing()


func _play_ambot_typing_sound() -> void:
	if ambot_typing_players.is_empty():
		return
	var player := ambot_typing_players[
		ambot_typing_sound_index % ambot_typing_players.size()
	]
	ambot_typing_sound_index += 1
	player.stop()
	player.pitch_scale = randf_range(0.96, 1.04)
	player.play()


func _finish_ambot_typing() -> void:
	if not ambot_typing_active:
		return
	ambot_typing_active = false
	if ambot_typing_label != null and is_instance_valid(ambot_typing_label):
		ambot_typing_label.visible_characters = -1
	var callback := ambot_typing_finished_callback
	ambot_typing_label = null
	ambot_typing_full_text = ""
	ambot_typing_finished_callback = Callable()
	if callback.is_valid():
		callback.call()


func _cancel_ambot_typing() -> void:
	ambot_typing_active = false
	ambot_typing_label = null
	ambot_typing_full_text = ""
	ambot_typing_finished_callback = Callable()
	for player in ambot_typing_players:
		if player.playing:
			player.stop()

func _on_notification_received(notification: Dictionary, play_sound := true) -> void:
	notification_toast.text = "AMBot - %s\n%s" % [notification.get("title", "New message"), notification.get("preview", "Tap to open")]
	notification_toast.visible = true
	notification_banner.text = notification_toast.text
	notification_banner.visible = true
	if play_sound:
		_play_sfx(notification_player)

func _on_ambot_availability_changed(_available: bool) -> void:
	if current_app == "home" and phone_open:
		show_home()

func _month_name(month: int) -> String:
	return ["", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][clampi(month, 1, 12)]

func _days_in_month(month: int, year: int) -> int:
	if month == 2:
		return 29 if (year % 400 == 0 or (year % 4 == 0 and year % 100 != 0)) else 28
	return 30 if month in [4, 6, 9, 11] else 31
