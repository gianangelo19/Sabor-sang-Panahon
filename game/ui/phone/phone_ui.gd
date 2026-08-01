extends Control

signal open_state_changed(is_open: bool)

const PHONE_SIZE := Vector2(304, 640)
const PHONE_FRAME := preload("res://assets/art/images/phone_ui/phone_frame_v2.png")
const PHONE_WALLPAPER := preload("res://assets/art/images/phone_ui/phone_wallpaper_cow_dolphin.png")
const PHONE_GLASS_CRACKS := preload("res://assets/art/images/phone_ui/phone_glass_cracks.png")
const AMBOT_ICON := preload("res://assets/art/images/phone_ui/ambot_icon_v2.png")
const MAPS_ICON := preload("res://assets/art/images/phone_ui/maps_icon_v2.png")
const CALENDAR_ICON := preload("res://assets/art/images/phone_ui/calendar_icon_v2.png")
const CLOCK_ICON := preload("res://assets/art/images/phone_ui/clock_icon_v2.png")
const NOTES_ICON := preload("res://assets/art/images/phone_ui/notes_icon_v2.png")
const CALCULATOR_ICON := preload("res://assets/art/images/phone_ui/calculator_icon_v2.png")
const MAP_VIEW_SCRIPT := preload("res://game/ui/phone/map_view.gd")
const PHONE_OPEN_SOUND := preload("res://assets/audio/retro_filipino_pack/phone_open.wav")
const PHONE_CLOSE_SOUND := preload("res://assets/audio/retro_filipino_pack/phone_close.wav")
const PHONE_TAP_SOUND := preload("res://assets/audio/retro_filipino_pack/phone_tap.wav")
const PHONE_BACK_SOUND := preload("res://assets/audio/retro_filipino_pack/phone_back.wav")
const SELECT_APP_SOUND := preload("res://assets/audio/retro_filipino_pack/select_app.wav")
const NOTIFICATION_SOUND := preload("res://assets/audio/retro_filipino_pack/completed_task.wav")
const CLOCK_SOUND := preload("res://assets/audio/clock_sound.mp3")
const AMBOT_TEXT_TICK_1 := preload(
	"res://features/minigames/box_unboxing/assets/audio/ui/sfx_text_tick_01.wav"
)
const AMBOT_TEXT_TICK_2 := preload(
	"res://features/minigames/box_unboxing/assets/audio/ui/sfx_text_tick_02.wav"
)
const NOTIFICATION_BOUNCE_SOUND := preload(
	"res://features/minigames/box_unboxing/assets/audio/ui/sfx_ui_hover.wav"
)
const AMBOT_CHARACTERS_PER_SECOND := 32.0
const AMBOT_CHARACTERS_PER_TICK := 3
const UNIFIED_NOTIFICATION_TEXT := "You have a new notification!"
const NOTIFICATION_BOUNCE_INTERVAL := 3.0
const NOTIFICATION_BANNER_SIZE := Vector2(370, 76)
const NOTIFICATION_BANNER_MARGIN := Vector2(24, 24)
const ITEM_SCAN_DESTINATIONS := {
	"damaged_newspaper": "grandma_house",
	"pork_and_liver": "market_vendor_2",
	"ginamos": "herbs_vendor",
	"fresh_herbs": "seasoning_vendor",
	"seasoning": "egg_vendor",
	"fresh_egg": "chicharon_vendor",
	"crushed_chicharon": "tindero",
}
const NAVY := Color("101c2b")
const DEEP_NAVY := Color("09121e")
const CREAM := Color("ffe1a3")
const GOLD := Color("f5a13b")
const ORANGE := Color("ef641d")
const MUTED_CREAM := Color("d9bf91")
const AMBOT_CONVERSATIONS := {
	"casual": {
		"opening": "No new clues right now. I checked twice because I calculated a 92 percent chance you would ask me to check again.",
		"questions": [
			{"text": "Can you check again?", "answer": "There. A third check. Still nothing. I hope the ceremony was comforting."},
			{"text": "What should I do now?", "answer": "Continue your current objective. Look closely, ask people questions, and try not to interpret every spoon as destiny."},
			{"text": "How are you, AMBot?", "answer": "All systems are normal. Thank you for asking. I was not designed to enjoy that question, which makes this response inconvenient."},
		],
		"closing": "I will notify you when something changes. Until then, please generate evidence by leaving this screen."
	},
	"newspaper_scan": {
		"opening": "Damaged newspaper detected. Dish identity: unknown. Correct: my name remains appropriate.",
		"questions": [
			{"text": "What can you read?", "answer": "Readable fragments: 'La Paz,' 'broth,' 'fresh miki,' and 'served for generations.' The title and recipe are incomprehensible."},
			{"text": "Why can't you name it?", "answer": "The provided clues match more than one noodle dish. A witness or physical record will be stronger evidence."},
			{"text": "What should I do?", "answer": "Given the context, ask contact: Lola Lynn. I have marked the jeepney route to her location."},
		],
		"closing": "Evidence file created: Unknown La Paz Dish. My name means 'I do not know.' This is branding, not permission to guess."
	},
	"arrival_maps": {
		"opening": "Arrival confirmed. Grandma's old house destination is active. I selected it for you because wandering aimlessly is already well represented in your skill set.",
		"questions": [
			{"text": "How do I find the house?", "answer": "Follow the amber destination diamond on screen. If it enters the river, reconsider your route."},
			{"text": "What is the diamond on screen?", "answer": "A destination beacon. It fades at the entrance, unlike your tendency to walk past obvious doors."},
			{"text": "Do I need to open Maps?", "answer": "No. Scanning a relevant item activates its supported destination beacon automatically. Maps remains available for orientation."},
		],
		"closing": "Current destination: Grandma's Old House. Try saying hello before beginning the interrogation."
	},
	"grandma_clues": {
		"opening": "Seven clues recorded: soft noodles, tender meat, salty depth, a crisp topping, a fresh egg, fragrant herbs, and warm seasoning.",
		"questions": [
			{"text": "What did Lola Lynn remember?", "answer": "Soft noodles, tender meat, salty depth, a crisp topping, a fresh egg, fragrant herbs, and warm seasoning. Seven ingredient slots are open."},
			{"text": "Where do I begin?", "answer": "Start with Ate Telyn. Chat history suggests she worked with Lola Lynn and still runs the meat stall."},
			{"text": "What is in my backpack?", "answer": "The damaged newspaper, family keepsakes, and seven empty ingredient slots."},
		],
		"closing": "Ate Telyn marked. Probability that she knows embarrassing stories about you: high."
	},
	"market_vendor_1_clues": {
		"opening": "Meat acquired. The vendor remembers every cut but not the dish—proof that hands can keep a secret from the brain.",
		"questions": [
			{"text": "Why can nobody name it?", "answer": "Matching memory gaps across unrelated people are statistically abnormal. Either the city forgot together, or reality has developed poor filing habits."},
			{"text": "What should I do next?", "answer": "Ask the ginamos vendor about the broth. Preferably before opening any suspicious jar yourself."},
		],
		"closing": "Ginamos Vendor marked. Your inventory now contains meat and an increasingly uncomfortable mystery."
	},
	"market_vendor_2_clues": {
		"opening": "Ginamos acquired. The vendor remembers the exact spoonful but not the recipe. Human memory continues to preserve the strangest save files.",
		"questions": [
			{"text": "Could everyone forget at once?", "answer": "Ordinary forgetting is messy. This is precise: same dish, same blank space. I dislike patterns that behave more neatly than my code."},
			{"text": "Who should I ask next?", "answer": "Ate Mila. Lola Lynn's memory includes an aroma that should lead to her herb stall."},
		],
		"closing": "Ate Mila marked. Your backpack now contains food, evidence, and one preventable odor."
	},
	"herbs_clues": {
		"opening": "Fresh herbs recorded: spring onion and toasted garlic. Aroma remains one of the more reliable forms of human indexing.",
		"questions": [
			{"text": "What did Ate Mila remember?", "answer": "Lola Lynn smelled every bundle before buying it. The herbs were added near the end to keep the aroma bright."},
			{"text": "Where next?", "answer": "Kuya Jun's seasoning stall. The broth still needs warm balance without more salt."},
		],
		"closing": "Kuya Jun marked. Please allow him to measure before offering an opinion."
	},
	"seasoning_clues": {
		"opening": "Warm seasoning acquired. Black pepper wakes the broth; restraint prevents it from hiding the meat.",
		"questions": [
			{"text": "Why not add more salt?", "answer": "Ginamos already supplies salty depth. Kuya Jun's testimony emphasizes balance, not volume."},
			{"text": "Who is next?", "answer": "Nang Cora. Lola Lynn remembers one soft ingredient cooking gently in the hot broth."},
		],
		"closing": "Nang Cora marked. Egg handling confidence remains unverified."
	},
	"egg_clues": {
		"opening": "Fresh egg acquired. Nang Cora remembers the yolk remaining slightly soft in the center of the bowl.",
		"questions": [
			{"text": "How many clues remain?", "answer": "Two ingredient clues remain: crushed chicharon, then fresh miki."},
			{"text": "Where do I go next?", "answer": "Ask the chicharon vendor about the crisp topping. Subtlety has never been chicharon's primary function."},
		],
		"closing": "Chicharon Vendor marked. Please resist eating the evidence before it becomes evidence."
	},
	"chicharon_clues": {
		"opening": "Crushed chicharon acquired. Meat, ginamos, herbs, seasoning, egg, and crisp topping now agree with each other. The witnesses remain less cooperative.",
		"questions": [
			{"text": "What clue remains?", "answer": "Fresh miki is the seventh and final ingredient clue."},
			{"text": "Where do I find it?", "answer": "Ask Tito Bobet at the miki stall. His machine may require a missing crank before it cooperates."},
		],
		"closing": "Tito Bobet marked. Progress is sometimes a circle with better inventory."
	},
	"tindero_miki_clue": {
		"opening": "Ingredient set recorded: pork and liver, ginamos, fresh herbs, seasoning, a fresh egg, crushed chicharon, and fresh miki.",
		"questions": [
			{"text": "Can you name the dish now?", "answer": "Not responsibly. Seven ingredients are strong evidence, but ingredient evidence alone cannot confirm the dish name."},
			{"text": "What kind of evidence do we need?", "answer": "A sign, menu, bowl, recipe, photograph, or other physical record."},
			{"text": "Where should I search?", "answer": "Lola Lynn's house and entrance, where the newspaper and family keepsakes originated."},
		],
		"closing": "Seven familiar faces, two missing tools, and one ginamos-smelling backpack later: return to the house."
	},
	"market_evidence": {
		"opening": "All seven ingredients are recorded. The recipe has shape now, even if its name is still behaving like classified information.",
		"questions": [
			{"text": "Do the ingredients match?", "answer": "Yes. Meat, ginamos, herbs, seasoning, egg, chicharon, and miki form one coherent bowl. Ingredients still cannot prove its history."},
			{"text": "Where should I search?", "answer": "The family house. If the dish mattered there, something physical may have survived the forgetting."},
		],
		"closing": "Next lead: the La Paz house. Return home and look at it like a place you have never seen before."
	},
	"family_house": {
		"opening": "Every ingredient points back to your family's La Paz house. Families are efficient that way: even their mysteries eventually come home.",
		"questions": [
			{"text": "Is our house connected?", "answer": "Probably, but testimony is not proof. The house needs to speak for itself, preferably through an object and not structural damage."},
			{"text": "What evidence should I find?", "answer": "Old signs, bowls, tools—anything covered, misplaced, or treated as ordinary for so long that nobody sees it anymore."},
		],
		"closing": "Search area: the house and its surroundings. Familiar places are excellent at hiding in plain sight."
	},
	"memory_bowl": {
		"opening": "Ingredient profile complete. Final identification requires the old Batchoy Bowl. Apparently dinner now has an artifact requirement.",
		"questions": [
			{"text": "Where is the bowl?", "answer": "Somewhere on the origin property. Follow the Cultural Echoes; they are louder than my current certainty."},
			{"text": "Can you identify the dish now?", "answer": "Not responsibly. The physical artifact is the last link between ingredients, family, and place."},
		],
		"closing": "Token allowance exhausted. Manual search required. Yes, even I recognize the timing is rude."
	},
	"cultural_echoes": {
		"opening": "Cultural Echo search active. The signal is audible, but the house is bending its direction.",
		"questions": [
			{"text": "What am I listening for?", "answer": "A faint bowl-clink, market chatter, or broth simmer. Move slowly and follow whichever sound grows clearer."},
			{"text": "Can you point to it?", "answer": "Not precisely. The signal bends around the house. I can confirm whether you are getting warmer."},
		],
		"closing": "Search slowly. Stronger echoes mean you are closer to the Batchoy Bowl."
	},
}

var phone_open := false
var current_app := "home"
var current_situation := ""
var calculator_value := "0"
var calculator_stored := 0.0
var calculator_operation := ""
var calculator_waiting_for_value := false
var previous_mouse_mode := Input.MOUSE_MODE_CAPTURED
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
var notification_bounce_player: AudioStreamPlayer
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
var ambot_scroll: ScrollContainer
var ambot_chat_stack: VBoxContainer
var ambot_autoscroll_pending := false
var ambot_autoscroll_generation := 0
var dialogue_hud_hidden := false
var _hud_visible := true
var dialogue_notification_tween: Tween
var notification_bounce_timer: Timer
var notification_bounce_tween: Tween
var unread_notification_count := 0
var ambot_notification_badge: Label

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
	_layout_notification_banner()
	_update_ambot_typing(delta)

func _build_interface() -> void:
	dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.015, 0.025, 0.045, 0.48)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	notification_banner = Button.new()
	notification_banner.visible = false
	notification_banner.set_anchors_preset(Control.PRESET_TOP_LEFT)
	notification_banner.size = NOTIFICATION_BANNER_SIZE
	notification_banner.pivot_offset = notification_banner.size * 0.5
	notification_banner.alignment = HORIZONTAL_ALIGNMENT_LEFT
	notification_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notification_banner.text = UNIFIED_NOTIFICATION_TEXT
	notification_banner.icon = AMBOT_ICON
	notification_banner.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	notification_banner.expand_icon = true
	notification_banner.tooltip_text = "Open AMBot"
	notification_banner.add_theme_color_override("font_color", CREAM)
	notification_banner.add_theme_font_size_override("font_size", 16)
	notification_banner.add_theme_constant_override("icon_max_width", 46)
	notification_banner.add_theme_stylebox_override("normal", _style(Color("142438"), GOLD, 2, 10))
	notification_banner.add_theme_stylebox_override("hover", _style(Color("1c344b"), CREAM, 2, 10))
	notification_banner.pressed.connect(_open_ambot_from_notification)
	add_child(notification_banner)
	_layout_notification_banner()

	notification_bounce_timer = Timer.new()
	notification_bounce_timer.wait_time = NOTIFICATION_BOUNCE_INTERVAL
	notification_bounce_timer.autostart = true
	notification_bounce_timer.timeout.connect(_bounce_notification_banner)
	add_child(notification_bounce_timer)

	phone_frame = PanelContainer.new()
	phone_frame.name = "PhoneFrame"
	phone_frame.custom_minimum_size = PHONE_SIZE
	phone_frame.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	phone_frame.position = Vector2(-PHONE_SIZE.x - 22, -PHONE_SIZE.y / 2.0)
	phone_frame.add_theme_stylebox_override("panel", _style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, 0))
	add_child(phone_frame)

	var phone_art := TextureRect.new()
	phone_art.name = "PhoneArtwork"
	phone_art.texture = PHONE_FRAME
	phone_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	phone_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	phone_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	phone_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	phone_frame.add_child(phone_art)

	var screen_margin := MarginContainer.new()
	screen_margin.name = "ScreenMargin"
	screen_margin.add_theme_constant_override("margin_left", 28)
	screen_margin.add_theme_constant_override("margin_right", 28)
	screen_margin.add_theme_constant_override("margin_top", 73)
	screen_margin.add_theme_constant_override("margin_bottom", 73)
	phone_frame.add_child(screen_margin)

	var screen_surface := Control.new()
	screen_surface.name = "ScreenSurface"
	screen_surface.theme = _build_phone_theme()
	screen_margin.add_child(screen_surface)

	var wallpaper := TextureRect.new()
	wallpaper.name = "ScreenWallpaper"
	wallpaper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wallpaper.texture = PHONE_WALLPAPER
	wallpaper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wallpaper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	wallpaper.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	wallpaper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_surface.add_child(wallpaper)

	var screen_tint := ColorRect.new()
	screen_tint.name = "ScreenTint"
	screen_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_tint.color = Color(0.015, 0.045, 0.075, 0.42)
	screen_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_surface.add_child(screen_tint)

	var shell_margin := MarginContainer.new()
	shell_margin.name = "ScreenContentMargin"
	shell_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell_margin.add_theme_constant_override("margin_left", 5)
	shell_margin.add_theme_constant_override("margin_right", 5)
	shell_margin.add_theme_constant_override("margin_top", 4)
	shell_margin.add_theme_constant_override("margin_bottom", 4)
	screen_surface.add_child(shell_margin)

	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 5)
	shell_margin.add_child(shell)

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
	notification_toast.text = UNIFIED_NOTIFICATION_TEXT
	notification_toast.icon = AMBOT_ICON
	notification_toast.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	notification_toast.expand_icon = true
	notification_toast.add_theme_font_size_override("font_size", 11)
	notification_toast.add_theme_constant_override("icon_max_width", 24)
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
	hint.text = "E  PUT AWAY"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", MUTED_CREAM)
	shell.add_child(hint)

	var glass_margin := MarginContainer.new()
	glass_margin.name = "PhoneGlassLayer"
	glass_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glass_margin.add_theme_constant_override("margin_left", 28)
	glass_margin.add_theme_constant_override("margin_right", 28)
	glass_margin.add_theme_constant_override("margin_top", 73)
	glass_margin.add_theme_constant_override("margin_bottom", 73)
	phone_frame.add_child(glass_margin)

	var cracked_glass := TextureRect.new()
	cracked_glass.name = "CrackedGlassOverlay"
	cracked_glass.texture = PHONE_GLASS_CRACKS
	cracked_glass.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cracked_glass.stretch_mode = TextureRect.STRETCH_SCALE
	cracked_glass.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cracked_glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cracked_glass.modulate = Color(1.0, 1.0, 1.0, 0.36)
	glass_margin.add_child(cracked_glass)
	show_home()

func _build_audio_players() -> void:
	phone_open_player = _create_sfx_player(PHONE_OPEN_SOUND)
	phone_close_player = _create_sfx_player(PHONE_CLOSE_SOUND)
	phone_tap_player = _create_sfx_player(PHONE_TAP_SOUND)
	phone_back_player = _create_sfx_player(PHONE_BACK_SOUND)
	select_app_player = _create_sfx_player(SELECT_APP_SOUND)
	notification_player = _create_sfx_player(NOTIFICATION_SOUND)
	notification_bounce_player = _create_sfx_player(NOTIFICATION_BOUNCE_SOUND)
	notification_bounce_player.volume_db = -16.0
	notification_bounce_player.pitch_scale = 1.06
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

func _app_icon(texture: Texture2D) -> Texture2D:
	return texture

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
	show_home()
	notification_banner.visible = false
	_reset_notification_bounce()
	open_state_changed.emit(true)

func close_phone() -> void:
	if not phone_open:
		return
	_play_sfx(phone_close_player)
	_stop_clock_sound()
	_cancel_ambot_typing()
	phone_open = false
	dim.visible = false
	phone_frame.visible = false
	notification_banner.visible = (
		_hud_visible
		and _has_unified_notification()
		and not dialogue_hud_hidden
	)
	Input.set_mouse_mode(previous_mouse_mode)
	open_state_changed.emit(false)

func is_point_over_phone(viewport_position: Vector2) -> bool:
	return phone_open and phone_frame.get_global_rect().has_point(viewport_position)

func set_dialogue_hud_hidden(hidden: bool, duration: float = 0.24) -> void:
	dialogue_hud_hidden = hidden
	if dialogue_notification_tween != null and dialogue_notification_tween.is_valid():
		dialogue_notification_tween.kill()
	if hidden:
		if not notification_banner.visible:
			notification_banner.modulate.a = 0.0
			return
		dialogue_notification_tween = create_tween()
		dialogue_notification_tween.set_trans(Tween.TRANS_SINE)
		dialogue_notification_tween.set_ease(Tween.EASE_IN_OUT)
		dialogue_notification_tween.tween_property(
			notification_banner,
			"modulate:a",
			0.0,
			maxf(duration, 0.0),
		)
		dialogue_notification_tween.tween_callback(func():
			if dialogue_hud_hidden:
				notification_banner.visible = false
		)
		return

	if not _hud_visible or phone_open or not _has_unified_notification():
		notification_banner.visible = false
		notification_banner.modulate.a = 1.0
		_reset_notification_bounce()
		return
	notification_banner.visible = true
	notification_banner.modulate.a = 0.0
	dialogue_notification_tween = create_tween()
	dialogue_notification_tween.set_trans(Tween.TRANS_SINE)
	dialogue_notification_tween.set_ease(Tween.EASE_IN_OUT)
	dialogue_notification_tween.tween_property(
		notification_banner,
		"modulate:a",
		1.0,
		maxf(duration, 0.0),
	)

func set_hud_visible(should_show: bool) -> void:
	_hud_visible = should_show
	if not should_show:
		notification_banner.visible = false
		_reset_notification_bounce()
		return
	notification_banner.visible = (
		not phone_open
		and not dialogue_hud_hidden
		and _has_unified_notification()
	)
	notification_banner.modulate.a = 1.0

func analyze_inventory_item(item_id: String) -> void:
	if item_id.is_empty():
		return
	if not phone_open:
		open_phone()
	var definition := GameState.get_item_definition(item_id)
	current_app = "ambot"
	current_situation = "inventory_scan_" + item_id
	title_label.text = "AMBot • ITEM SCAN"
	_show_back_button()
	_clear_screen()
	notification_toast.visible = false
	notification_banner.visible = false

	var heading := Label.new()
	heading.text = "OBJECT RECOGNITION COMPLETE"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 11)
	heading.add_theme_color_override("font_color", GOLD)
	screen_stack.add_child(heading)

	var preview_panel := PanelContainer.new()
	preview_panel.name = "ScannedItemPreviewPanel"
	preview_panel.custom_minimum_size.y = 104.0
	preview_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_panel.add_theme_stylebox_override(
		"panel",
		_style(Color("101c2bdd"), GOLD, 1, 7, 5),
	)
	screen_stack.add_child(preview_panel)

	var preview := TextureRect.new()
	preview.name = "ScannedItemPreview"
	preview.set_meta("item_id", item_id)
	preview.set_meta("source_icon_path", str(definition.get("icon", "")))
	preview.tooltip_text = str(
		definition.get("display_name", item_id.capitalize())
	)
	preview.texture = _inventory_item_texture(definition)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_panel.add_child(preview)

	var details_scroll := ScrollContainer.new()
	details_scroll.name = "ScannedItemDetailsScroll"
	details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	screen_stack.add_child(details_scroll)

	var details_stack := VBoxContainer.new()
	details_stack.name = "ScannedItemDetails"
	details_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_scroll.add_child(details_stack)
	_add_chat_bubble(
		"AMBot",
		"%s\nCategory: %s\n\n%s" % [
			str(definition.get("display_name", item_id.capitalize())),
			str(definition.get("category", "Item")),
			str(definition.get("ambot", "No reference information is available.")),
		],
		false,
		_finish_inventory_item_scan.bind(item_id),
		true,
		details_stack,
	)


func _inventory_item_texture(definition: Dictionary) -> Texture2D:
	var icon_path := str(definition.get("icon", ""))
	if icon_path.is_empty():
		return null
	var texture := load(icon_path) as Texture2D
	if texture == null:
		return null
	var inventory_ui := get_parent().get_node_or_null("InventoryUI")
	if inventory_ui != null and inventory_ui.has_method("prepare_item_texture"):
		return inventory_ui.prepare_item_texture(texture)
	return texture


func _finish_inventory_item_scan(item_id: String) -> void:
	_reveal_scanned_item_destination(item_id)
	var done := Button.new()
	done.text = "Scan complete • drag another item"
	done.tooltip_text = "Return to the app launcher"
	done.pressed.connect(func():
		_play_sfx(phone_back_player)
		show_home()
	)
	screen_stack.add_child(done)
	GameState.set_ambot_status("Scanned " + str(GameState.get_item_definition(item_id).get("display_name", item_id.capitalize())))


func _reveal_scanned_item_destination(item_id: String) -> void:
	var destination_id := str(ITEM_SCAN_DESTINATIONS.get(item_id, ""))
	if destination_id.is_empty():
		return

	# The newspaper establishes Grandma's house as the first destination before
	# the player reaches La Paz. Later vendor rewards already unlock their leads.
	if item_id == "damaged_newspaper":
		GameState.unlock_destination(destination_id)
	if (
		not GameState.is_destination_unlocked(destination_id)
		or GameState.is_destination_completed(destination_id)
	):
		return
	if not GameState.select_destination(destination_id):
		return
	if GameState.active_destination == destination_id:
		GameState.mark_active_destination_seen_in_maps()


func _clear_screen() -> void:
	_stop_clock_sound()
	_cancel_ambot_typing()
	ambot_autoscroll_generation += 1
	ambot_autoscroll_pending = false
	ambot_scroll = null
	ambot_chat_stack = null
	ambot_notification_badge = null
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
	_add_app_button(
		grid,
		"AMBot",
		_open_ambot,
		_app_icon(AMBOT_ICON),
		true,
		_unread_badge_count(),
	)
	_add_app_button(grid, "Maps", show_maps, _app_icon(MAPS_ICON))
	_add_app_button(grid, "Calendar", show_calendar, _app_icon(CALENDAR_ICON))
	_add_app_button(grid, "Clock", show_clock, _app_icon(CLOCK_ICON))
	_add_app_button(grid, "Notes", show_notes, _app_icon(NOTES_ICON))
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

func _add_app_button(
	parent: Control,
	label_text: String,
	callback: Callable,
	icon_texture: Texture2D = null,
	enabled := true,
	badge_count := -1,
) -> void:
	var app := VBoxContainer.new()
	app.custom_minimum_size = Vector2(76, 84)
	app.add_theme_constant_override("separation", 0)
	parent.add_child(app)
	var icon_slot := Control.new()
	icon_slot.custom_minimum_size = Vector2(68, 64)
	icon_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	app.add_child(icon_slot)
	var button := Button.new()
	button.name = label_text.replace(" •", "") + "AppButton"
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	icon_slot.add_child(button)
	if badge_count >= 0:
		ambot_notification_badge = Label.new()
		ambot_notification_badge.name = "AMBotNotificationBadge"
		ambot_notification_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		ambot_notification_badge.offset_left = -22.0
		ambot_notification_badge.offset_top = -5.0
		ambot_notification_badge.offset_right = 1.0
		ambot_notification_badge.offset_bottom = 18.0
		ambot_notification_badge.z_index = 2
		ambot_notification_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ambot_notification_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ambot_notification_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ambot_notification_badge.add_theme_font_size_override("font_size", 11)
		ambot_notification_badge.add_theme_color_override("font_color", Color.WHITE)
		ambot_notification_badge.add_theme_stylebox_override(
			"normal",
			_style(Color("f04438"), Color("ffafa8"), 1, 12, 2),
		)
		icon_slot.add_child(ambot_notification_badge)
		_refresh_ambot_notification_badge()
	var app_label := Label.new()
	app_label.text = label_text
	app_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	app_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	app_label.add_theme_font_size_override("font_size", 10)
	app_label.add_theme_color_override("font_color", CREAM)
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

func _open_ambot() -> void:
	_clear_unread_notifications()
	current_situation = GameState.consume_ambot_notification() if GameState.has_ambot_notification() else "casual"
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
	_build_ambot_chat_view()
	notification_toast.visible = false
	notification_banner.visible = false
	_reset_notification_bounce()
	var conversation: Dictionary = AMBOT_CONVERSATIONS.get(current_situation, {})
	if conversation.is_empty():
		var unavailable := Label.new()
		unavailable.text = "This notification is no longer available."
		ambot_chat_stack.add_child(unavailable)
		return
	for entry: Dictionary in GameState.get_ambot_chat_history():
		_add_chat_bubble(
			str(entry.get("speaker", "AMBot")),
			str(entry.get("message", "")),
			bool(entry.get("from_player", false)),
			Callable(),
			false,
		)
	if GameState.has_ambot_chat_entry(current_situation, "opening"):
		_build_ambot_questions(conversation)
		return
	GameState.append_ambot_chat_message(
		"AMBot",
		str(conversation.opening),
		false,
		current_situation,
		"opening",
	)
	_add_chat_bubble(
		"AMBot",
		conversation.opening,
		false,
		_build_ambot_questions.bind(conversation)
	)

func _build_ambot_questions(conversation: Dictionary) -> void:
	if ambot_chat_stack == null or not is_instance_valid(ambot_chat_stack):
		return
	_clear_ambot_question_controls()
	var questions: Array = conversation.get("questions", [])
	var asked_questions := GameState.get_ambot_asked_questions(current_situation)
	var remaining := false
	for index in range(questions.size()):
		if asked_questions.has(index):
			continue
		remaining = true
		var question: Dictionary = questions[index]
		var button := Button.new()
		button.text = question.text
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.set_meta("ambot_question_button", true)
		button.pressed.connect(_ask_ambot_question.bind(index, question, conversation))
		ambot_chat_stack.add_child(button)
	if not remaining:
		if GameState.has_ambot_chat_entry(current_situation, "closing"):
			_finish_ambot_conversation()
			return
		GameState.append_ambot_chat_message(
			"AMBot",
			str(conversation.closing),
			false,
			current_situation,
			"closing",
		)
		_add_chat_bubble(
			"AMBot",
			conversation.closing,
			false,
			_finish_ambot_conversation
		)
	_request_ambot_autoscroll()

func _ask_ambot_question(index: int, question: Dictionary, conversation: Dictionary) -> void:
	if GameState.get_ambot_asked_questions(current_situation).has(index):
		return
	_play_sfx(phone_tap_player)
	GameState.record_ambot_question(current_situation, index)
	_clear_ambot_question_controls()
	GameState.append_ambot_chat_message(
		"You",
		str(question.text),
		true,
		current_situation,
		"question_%d" % index,
	)
	GameState.append_ambot_chat_message(
		"AMBot",
		str(question.answer),
		false,
		current_situation,
		"answer_%d" % index,
	)
	_add_chat_bubble(
		"You",
		question.text,
		true,
		_show_ambot_answer.bind(question, conversation),
	)


func _show_ambot_answer(question: Dictionary, conversation: Dictionary) -> void:
	_add_chat_bubble(
		"AMBot",
		question.answer,
		false,
		_build_ambot_questions.bind(conversation)
	)


func _finish_ambot_conversation() -> void:
	GameState.complete_ambot_conversation(current_situation)
	if ambot_chat_stack == null or not is_instance_valid(ambot_chat_stack):
		return
	if ambot_chat_stack.find_child("AMBotCloseConversation", false, false) != null:
		return
	var done := Button.new()
	done.name = "AMBotCloseConversation"
	done.text = "Close conversation"
	done.pressed.connect(func():
		_play_sfx(phone_back_player)
		show_home()
	)
	ambot_chat_stack.add_child(done)
	_request_ambot_autoscroll()


func _build_ambot_chat_view() -> void:
	ambot_scroll = ScrollContainer.new()
	ambot_scroll.name = "AMBotHistoryScroll"
	ambot_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ambot_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ambot_scroll.follow_focus = true
	screen_stack.add_child(ambot_scroll)

	ambot_chat_stack = VBoxContainer.new()
	ambot_chat_stack.name = "AMBotChatHistory"
	ambot_chat_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ambot_chat_stack.add_theme_constant_override("separation", 6)
	ambot_scroll.add_child(ambot_chat_stack)


func _clear_ambot_question_controls() -> void:
	if ambot_chat_stack == null or not is_instance_valid(ambot_chat_stack):
		return
	for child: Node in ambot_chat_stack.get_children():
		if child is Button and child.has_meta("ambot_question_button"):
			ambot_chat_stack.remove_child(child)
			child.queue_free()


func _scroll_ambot_to_bottom() -> void:
	if ambot_scroll == null or not is_instance_valid(ambot_scroll):
		return
	var scroll_bar := ambot_scroll.get_v_scroll_bar()
	var bottom := int(scroll_bar.max_value)
	ambot_scroll.scroll_vertical = bottom
	scroll_bar.value = scroll_bar.max_value


func _request_ambot_autoscroll() -> void:
	if ambot_scroll == null or not is_instance_valid(ambot_scroll):
		return
	if ambot_autoscroll_pending:
		return
	ambot_autoscroll_pending = true
	var request_generation := ambot_autoscroll_generation
	_scroll_ambot_after_layout.call_deferred(request_generation)


func _scroll_ambot_after_layout(request_generation: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if request_generation != ambot_autoscroll_generation:
		return
	ambot_autoscroll_pending = false
	_scroll_ambot_to_bottom()


func _add_chat_bubble(
	speaker: String,
	message: String,
	from_player: bool,
	on_typing_finished: Callable = Callable(),
	animate := true,
	parent_override: Control = null,
) -> void:
	var panel := PanelContainer.new()
	panel.name = "PlayerChatBubble" if from_player else "AMBotChatBubble"
	panel.set_meta("ambot_chat_bubble", true)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(Color("31566b") if from_player else Color("29363d"), Color("6f8d8e"), 1, 6))
	var label := Label.new()
	label.text = speaker + "\n" + message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(label)
	var parent: Control = parent_override
	if parent == null or not is_instance_valid(parent):
		parent = screen_stack
	if (
		parent_override == null
		and ambot_chat_stack != null
		and is_instance_valid(ambot_chat_stack)
	):
		parent = ambot_chat_stack
	parent.add_child(panel)
	_request_ambot_autoscroll()
	if not animate:
		label.visible_characters = -1
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
	_request_ambot_autoscroll()


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
	_request_ambot_autoscroll()
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

func _on_notification_received(_notification: Dictionary, play_sound := true) -> void:
	_register_unread_notification()
	_show_unified_notification(play_sound)

func _register_unread_notification() -> void:
	unread_notification_count = mini(unread_notification_count + 1, 999)
	_refresh_ambot_notification_badge()

func _clear_unread_notifications() -> void:
	unread_notification_count = 0
	_refresh_ambot_notification_badge()

func _unread_badge_count() -> int:
	return unread_notification_count

func _refresh_ambot_notification_badge() -> void:
	if (
		ambot_notification_badge == null
		or not is_instance_valid(ambot_notification_badge)
	):
		return
	var badge_count := _unread_badge_count()
	ambot_notification_badge.visible = badge_count > 0
	ambot_notification_badge.text = (
		str(badge_count) if badge_count < 100 else "99+"
	)
	ambot_notification_badge.offset_left = -28.0 if badge_count >= 100 else -22.0

func _show_unified_notification(play_sound: bool) -> void:
	notification_toast.text = UNIFIED_NOTIFICATION_TEXT
	notification_toast.visible = true
	notification_banner.text = UNIFIED_NOTIFICATION_TEXT
	notification_banner.visible = (
		_hud_visible
		and not phone_open
		and not dialogue_hud_hidden
	)
	notification_banner.modulate.a = 1.0
	_layout_notification_banner()
	if notification_bounce_timer:
		notification_bounce_timer.start(NOTIFICATION_BOUNCE_INTERVAL)
	if play_sound:
		_play_sfx(notification_player)

func _has_unified_notification() -> bool:
	return _unread_badge_count() > 0 or GameState.has_ambot_notification()

func _bounce_notification_banner() -> void:
	if (
		not _hud_visible
		or not notification_banner.visible
		or phone_open
		or dialogue_hud_hidden
	):
		return
	_play_sfx(notification_bounce_player)
	if notification_bounce_tween != null and notification_bounce_tween.is_valid():
		notification_bounce_tween.kill()
	notification_banner.scale = Vector2.ONE
	notification_bounce_tween = create_tween()
	notification_bounce_tween.set_trans(Tween.TRANS_QUAD)
	notification_bounce_tween.set_ease(Tween.EASE_OUT)
	notification_bounce_tween.tween_property(
		notification_banner,
		"scale",
		Vector2(1.04, 1.1),
		0.12,
	)
	notification_bounce_tween.set_ease(Tween.EASE_IN)
	notification_bounce_tween.tween_property(
		notification_banner,
		"scale",
		Vector2(0.99, 0.96),
		0.1,
	)
	notification_bounce_tween.set_ease(Tween.EASE_OUT)
	notification_bounce_tween.tween_property(
		notification_banner,
		"scale",
		Vector2.ONE,
		0.12,
	)

func _reset_notification_bounce() -> void:
	if notification_bounce_tween != null and notification_bounce_tween.is_valid():
		notification_bounce_tween.kill()
	notification_banner.scale = Vector2.ONE

func _layout_notification_banner() -> void:
	if notification_banner == null:
		return
	var viewport_size := get_viewport_rect().size
	notification_banner.position = Vector2(
		maxf(NOTIFICATION_BANNER_MARGIN.x, viewport_size.x - NOTIFICATION_BANNER_SIZE.x - NOTIFICATION_BANNER_MARGIN.x),
		NOTIFICATION_BANNER_MARGIN.y,
	)

func _on_ambot_availability_changed(_available: bool) -> void:
	if current_app == "home" and phone_open:
		show_home()

func _month_name(month: int) -> String:
	return ["", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][clampi(month, 1, 12)]

func _days_in_month(month: int, year: int) -> int:
	if month == 2:
		return 29 if (year % 400 == 0 or (year % 4 == 0 and year % 100 != 0)) else 28
	return 30 if month in [4, 6, 9, 11] else 31
