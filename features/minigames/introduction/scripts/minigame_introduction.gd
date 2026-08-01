extends CanvasLayer

signal introduction_started(minigame_id: String)
signal start_requested
signal countdown_started
signal countdown_finished


enum IntroductionState {
	IDLE,
	OPENING,
	VIEWING_SLIDES,
	CHANGING_SLIDE,
	STARTING_COUNTDOWN,
	COUNTDOWN,
	FINISHED
}


const SCREEN_SIZE: Vector2 = Vector2(1152, 648)
const SCREEN_CENTER: Vector2 = Vector2(576, 324)

const INTRO_ASSET_ROOT: String = (
	"res://features/minigames/introduction/assets/"
)

const LEFT_ARROW_PATH: String = (
	"res://features/minigames/introduction/assets/"
	+ "navigation/arrow_left.png"
)

const RIGHT_ARROW_PATH: String = (
	"res://features/minigames/introduction/assets/"
	+ "navigation/arrow_right.png"
)

const START_BUTTON_PATH: String = (
	"res://features/minigames/introduction/assets/"
	+ "navigation/start_button.png"
)

const COUNTDOWN_3_PATH: String = (
	"res://features/minigames/introduction/assets/"
	+ "countdown/countdown_3.png"
)

const COUNTDOWN_2_PATH: String = (
	"res://features/minigames/introduction/assets/"
	+ "countdown/countdown_2.png"
)

const COUNTDOWN_1_PATH: String = (
	"res://features/minigames/introduction/assets/"
	+ "countdown/countdown_1.png"
)


const AUDIO_ROOT: String = (
	"res://features/minigames/introduction/assets/audio/"
)

const BGM_INSTRUCTION_PATH: String = (
	AUDIO_ROOT
	+ "music/bgm_instruction_loop.ogg"
)

const SFX_INTRO_OPEN_PATH: String = (
	AUDIO_ROOT
	+ "sfx/sfx_intro_open.wav"
)

const SFX_SLIDE_NEXT_PATH: String = (
	AUDIO_ROOT
	+ "sfx/sfx_slide_next.wav"
)

const SFX_SLIDE_PREVIOUS_PATH: String = (
	AUDIO_ROOT
	+ "sfx/sfx_slide_previous.wav"
)

const SFX_START_PRESSED_PATH: String = (
	AUDIO_ROOT
	+ "sfx/sfx_start_pressed.wav"
)

const SFX_COUNTDOWN_3_PATH: String = (
	AUDIO_ROOT
	+ "sfx/sfx_countdown_3.wav"
)

const SFX_COUNTDOWN_2_PATH: String = (
	AUDIO_ROOT
	+ "sfx/sfx_countdown_2.wav"
)

const SFX_COUNTDOWN_1_PATH: String = (
	AUDIO_ROOT
	+ "sfx/sfx_countdown_1.wav"
)

const SFX_COUNTDOWN_GO_PATH: String = (
	AUDIO_ROOT
	+ "sfx/sfx_countdown_go.wav"
)

const SFX_UI_HOVER_PATH: String = (
	AUDIO_ROOT
	+ "ui/sfx_ui_hover.wav"
)

const SFX_UI_CLICK_PATH: String = (
	AUDIO_ROOT
	+ "ui/sfx_ui_click.wav"
)


@export_category("Canvas")

@export var introduction_canvas_layer: int = 150


@export_category("Testing")

# Enable only when running the introduction scene by itself.
# Keep this disabled when the introduction is connected
# to Box Unboxing.
@export var auto_start_for_testing: bool = false

@export_enum(
	"box_unboxing",
	"chicharon_beat",
	"miki_noodle_crank",
	"guinamos_jar_pick",
	"snatch_battle"
)
var testing_minigame_id: String = "box_unboxing"


@export_category("Opening")

@export var opening_black_hold: float = 0.30
@export var opening_fade_duration: float = 0.40


@export_category("Slide Panel")

# The finished instruction panels are 1152 × 648.
# They are displayed at 80% size and remain centered.
@export var slide_panel_scale: Vector2 = Vector2(0.8, 0.8)

@export var slide_transition_duration: float = 0.20
@export var slide_transition_distance: float = 70.0


@export_category("Full Canvas Navigation")

# Navigation PNG files are also 1152 × 648.
@export var full_canvas_position: Vector2 = Vector2(576, 324)
@export var navigation_asset_scale: Vector2 = Vector2.ONE
@export var start_button_asset_scale: Vector2 = Vector2(0.8, 0.8)

@export_category("Clickable Areas")

# Measured directly from arrow_left.png:
# Visible arrow bounds are approximately:
# X: 36–101
# Y: 282–353
# Center: 69, 318
@export var left_arrow_click_center: Vector2 = Vector2(
	69,
	318
)

# Measured directly from arrow_right.png:
# Visible arrow bounds are approximately:
# X: 1051–1116
# Y: 294–365
# Center: 1084, 330
@export var right_arrow_click_center: Vector2 = Vector2(
	1084,
	330
)

# Adjust this after checking the Start button image.
@export var start_button_click_center: Vector2 = Vector2(
	576,
	550
)

# Slightly larger than the visible arrow for easier clicking.
@export var arrow_click_size: Vector2 = Vector2(
	110,
	110
)

@export var start_click_size: Vector2 = Vector2(
	360,
	120
)


@export_category("Countdown")

@export_range(0.0, 1.0, 0.05)
var countdown_dim_alpha: float = 0.72

@export var countdown_number_hold_time: float = 0.70
@export var countdown_number_enter_time: float = 0.18
@export var countdown_number_exit_time: float = 0.15
@export var countdown_between_numbers: float = 0.05

@export var countdown_start_scale: Vector2 = Vector2(
	1.15,
	1.15
)

@export var countdown_normal_scale: Vector2 = Vector2.ONE


@export_category("Audio")

@export var instruction_music_volume_db: float = -15.0
@export var introduction_sfx_volume_db: float = -3.0
@export var introduction_ui_volume_db: float = -8.0

@export var instruction_music_fade_in_time: float = 0.55
@export var instruction_music_fade_out_time: float = 0.40

@export var audio_one_shot_player_count: int = 8


var root: Control = null
var black_background: ColorRect = null
var slide_image: TextureRect = null

var left_arrow_group: Node2D = null
var left_arrow_sprite: Sprite2D = null
var left_arrow_button: Button = null

var right_arrow_group: Node2D = null
var right_arrow_sprite: Sprite2D = null
var right_arrow_button: Button = null

var start_button_group: Node2D = null
var start_button_sprite: Sprite2D = null
var start_button: Button = null

var countdown_layer: Control = null
var countdown_dim: ColorRect = null
var countdown_number: TextureRect = null


var current_state: IntroductionState = (
	IntroductionState.IDLE
)

var current_minigame_id: String = ""
var current_slide_index: int = 0

var slides: Array[Texture2D] = []
var countdown_textures: Array[Texture2D] = []

var slide_base_position: Vector2 = Vector2.ZERO

var active_slide_tween: Tween = null
var opening_tween: Tween = null
var countdown_tween: Tween = null


var instruction_music_player: AudioStreamPlayer = null
var audio_one_shot_players: Array[AudioStreamPlayer] = []
var audio_one_shot_index: int = 0
var instruction_music_tween: Tween = null

var stream_bgm_instruction: AudioStream = null

var stream_intro_open: AudioStream = null
var stream_slide_next: AudioStream = null
var stream_slide_previous: AudioStream = null
var stream_start_pressed: AudioStream = null

var stream_countdown_3: AudioStream = null
var stream_countdown_2: AudioStream = null
var stream_countdown_1: AudioStream = null
var stream_countdown_go: AudioStream = null

var stream_ui_hover: AudioStream = null
var stream_ui_click: AudioStream = null


func _ready() -> void:
	layer = introduction_canvas_layer
	process_mode = Node.PROCESS_MODE_ALWAYS

	if not _cache_scene_nodes():
		push_error(
			"INTRODUCTION: Required nodes are missing."
		)
		return

	_setup_fullscreen_controls()
	_load_shared_assets()
	_load_audio_assets()
	_setup_audio_players()
	_setup_full_canvas_navigation()
	_setup_buttons()
	_setup_layer_order()
	_connect_buttons()
	_connect_audio_hover_signals()
	_reset_introduction()

	print("")
	print("========================================")
	print("MINIGAME INTRODUCTION READY")
	print("========================================")
	print("Screen size: ", SCREEN_SIZE)
	print("Slide scale: ", slide_panel_scale)
	print(
		"Left arrow click center: ",
		left_arrow_click_center
	)
	print(
		"Right arrow click center: ",
		right_arrow_click_center
	)
	print("Static arrows: true")
	print("Mouse-only navigation: true")
	print("========================================")
	print("")

	if auto_start_for_testing:
		call_deferred(
			"start_introduction",
			testing_minigame_id
		)


# =========================================================
# SCENE NODE CACHE
# =========================================================

func _cache_scene_nodes() -> bool:
	root = get_node_or_null(
		"Root"
	) as Control

	black_background = get_node_or_null(
		"Root/BlackBackground"
	) as ColorRect

	slide_image = get_node_or_null(
		"Root/SlideImage"
	) as TextureRect


	left_arrow_group = get_node_or_null(
		"Root/LeftArrowGroup"
	) as Node2D

	left_arrow_sprite = get_node_or_null(
		"Root/LeftArrowGroup/LeftArrowSprite"
	) as Sprite2D

	left_arrow_button = get_node_or_null(
		"Root/LeftArrowGroup/LeftArrowButton"
	) as Button


	right_arrow_group = get_node_or_null(
		"Root/RightArrowGroup"
	) as Node2D

	right_arrow_sprite = get_node_or_null(
		"Root/RightArrowGroup/RightArrowSprite"
	) as Sprite2D

	right_arrow_button = get_node_or_null(
		"Root/RightArrowGroup/RightArrowButton"
	) as Button


	start_button_group = get_node_or_null(
		"Root/StartButtonGroup"
	) as Node2D

	start_button_sprite = get_node_or_null(
		"Root/StartButtonGroup/StartButtonSprite"
	) as Sprite2D

	start_button = get_node_or_null(
		"Root/StartButtonGroup/StartButton"
	) as Button


	countdown_layer = get_node_or_null(
		"Root/CountdownLayer"
	) as Control

	countdown_dim = get_node_or_null(
		"Root/CountdownLayer/CountdownDim"
	) as ColorRect

	countdown_number = get_node_or_null(
		"Root/CountdownLayer/CountdownNumber"
	) as TextureRect


	var nodes_are_valid: bool = (
		root != null
		and black_background != null
		and slide_image != null
		and left_arrow_group != null
		and left_arrow_sprite != null
		and left_arrow_button != null
		and right_arrow_group != null
		and right_arrow_sprite != null
		and right_arrow_button != null
		and start_button_group != null
		and start_button_sprite != null
		and start_button != null
		and countdown_layer != null
		and countdown_dim != null
		and countdown_number != null
	)

	if not nodes_are_valid:
		_print_missing_nodes()
		return false

	return true


func _print_missing_nodes() -> void:
	var required_paths: Array[String] = [
		"Root",
		"Root/BlackBackground",
		"Root/SlideImage",
		"Root/LeftArrowGroup",
		"Root/LeftArrowGroup/LeftArrowSprite",
		"Root/LeftArrowGroup/LeftArrowButton",
		"Root/RightArrowGroup",
		"Root/RightArrowGroup/RightArrowSprite",
		"Root/RightArrowGroup/RightArrowButton",
		"Root/StartButtonGroup",
		"Root/StartButtonGroup/StartButtonSprite",
		"Root/StartButtonGroup/StartButton",
		"Root/CountdownLayer",
		"Root/CountdownLayer/CountdownDim",
		"Root/CountdownLayer/CountdownNumber"
	]

	for path in required_paths:
		if get_node_or_null(path) == null:
			push_error(
				"INTRODUCTION: Missing node: "
				+ path
			)


# =========================================================
# CONTROL SETUP
# =========================================================

func _setup_fullscreen_controls() -> void:
	_set_full_rect(root)
	_set_full_rect(black_background)
	_set_full_rect(slide_image)
	_set_full_rect(countdown_layer)
	_set_full_rect(countdown_dim)
	_set_full_rect(countdown_number)

	root.mouse_filter = Control.MOUSE_FILTER_STOP

	black_background.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	slide_image.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	countdown_layer.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	countdown_dim.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	countdown_number.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	slide_image.expand_mode = (
		TextureRect.EXPAND_IGNORE_SIZE
	)

	slide_image.stretch_mode = (
		TextureRect.STRETCH_SCALE
	)

	slide_image.pivot_offset = SCREEN_CENTER
	slide_image.position = Vector2.ZERO
	slide_image.scale = slide_panel_scale

	slide_base_position = Vector2.ZERO


	countdown_number.expand_mode = (
		TextureRect.EXPAND_IGNORE_SIZE
	)

	countdown_number.stretch_mode = (
		TextureRect.STRETCH_SCALE
	)

	countdown_number.pivot_offset = SCREEN_CENTER


func _set_full_rect(control: Control) -> void:
	control.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)


func _setup_full_canvas_navigation() -> void:
	# The arrow and Start assets are full 1152 × 648 images.
	# Their groups remain centered at the screen center.
	left_arrow_group.position = full_canvas_position
	right_arrow_group.position = full_canvas_position
	start_button_group.position = full_canvas_position

	left_arrow_group.scale = Vector2.ONE
	right_arrow_group.scale = Vector2.ONE
	start_button_group.scale = Vector2.ONE

	left_arrow_sprite.centered = true
	right_arrow_sprite.centered = true
	start_button_sprite.centered = true

	left_arrow_sprite.position = Vector2.ZERO
	right_arrow_sprite.position = Vector2.ZERO
	start_button_sprite.position = Vector2.ZERO

	left_arrow_sprite.scale = navigation_asset_scale
	right_arrow_sprite.scale = navigation_asset_scale
	start_button_sprite.scale = start_button_asset_scale

func _setup_layer_order() -> void:
	black_background.z_index = 0
	slide_image.z_index = 10

	left_arrow_group.z_index = 20
	right_arrow_group.z_index = 20
	start_button_group.z_index = 20

	left_arrow_sprite.z_index = 0
	right_arrow_sprite.z_index = 0
	start_button_sprite.z_index = 0

	left_arrow_button.z_index = 5
	right_arrow_button.z_index = 5
	start_button.z_index = 5

	countdown_layer.z_index = 100
	countdown_dim.z_index = 0
	countdown_number.z_index = 5


# =========================================================
# ASSET LOADING
# =========================================================

func _load_shared_assets() -> void:
	left_arrow_sprite.texture = _load_texture(
		LEFT_ARROW_PATH
	)

	right_arrow_sprite.texture = _load_texture(
		RIGHT_ARROW_PATH
	)

	start_button_sprite.texture = _load_texture(
		START_BUTTON_PATH
	)

	countdown_textures.clear()

	var countdown_paths: Array[String] = [
		COUNTDOWN_3_PATH,
		COUNTDOWN_2_PATH,
		COUNTDOWN_1_PATH
	]

	for path in countdown_paths:
		var texture: Texture2D = _load_texture(path)

		if texture != null:
			countdown_textures.append(texture)

	if countdown_textures.size() != 3:
		push_error(
			"INTRODUCTION: Three countdown "
			+ "textures are required."
		)




# =========================================================
# AUDIO
# =========================================================

func _load_audio_assets() -> void:
	stream_bgm_instruction = _load_audio_stream(
		BGM_INSTRUCTION_PATH
	)

	stream_intro_open = _load_audio_stream(
		SFX_INTRO_OPEN_PATH
	)

	stream_slide_next = _load_audio_stream(
		SFX_SLIDE_NEXT_PATH
	)

	stream_slide_previous = _load_audio_stream(
		SFX_SLIDE_PREVIOUS_PATH
	)

	stream_start_pressed = _load_audio_stream(
		SFX_START_PRESSED_PATH
	)

	stream_countdown_3 = _load_audio_stream(
		SFX_COUNTDOWN_3_PATH
	)

	stream_countdown_2 = _load_audio_stream(
		SFX_COUNTDOWN_2_PATH
	)

	stream_countdown_1 = _load_audio_stream(
		SFX_COUNTDOWN_1_PATH
	)

	stream_countdown_go = _load_audio_stream(
		SFX_COUNTDOWN_GO_PATH
	)

	stream_ui_hover = _load_audio_stream(
		SFX_UI_HOVER_PATH
	)

	stream_ui_click = _load_audio_stream(
		SFX_UI_CLICK_PATH
	)

	_enable_music_loop(
		stream_bgm_instruction
	)


func _load_audio_stream(
	path: String
) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning(
			"INTRODUCTION AUDIO: Missing audio: "
			+ path
		)

		return null

	var loaded_stream: AudioStream = (
		load(path) as AudioStream
	)

	if loaded_stream == null:
		push_warning(
			"INTRODUCTION AUDIO: Failed to load: "
			+ path
		)

	return loaded_stream


func _enable_music_loop(
	stream: AudioStream
) -> void:
	if stream == null:
		return

	if stream is AudioStreamOggVorbis:
		var ogg_stream: AudioStreamOggVorbis = (
			stream as AudioStreamOggVorbis
		)

		ogg_stream.loop = true

	elif stream is AudioStreamWAV:
		var wav_stream: AudioStreamWAV = (
			stream as AudioStreamWAV
		)

		wav_stream.loop_mode = (
			AudioStreamWAV.LOOP_FORWARD
		)


func _setup_audio_players() -> void:
	instruction_music_player = AudioStreamPlayer.new()
	instruction_music_player.name = (
		"InstructionMusicPlayer"
	)
	instruction_music_player.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)
	instruction_music_player.stream = (
		stream_bgm_instruction
	)
	instruction_music_player.volume_db = (
		-80.0
	)

	add_child(
		instruction_music_player
	)

	audio_one_shot_players.clear()
	audio_one_shot_index = 0

	var player_count: int = maxi(
		1,
		audio_one_shot_player_count
	)

	for index in range(player_count):
		var player: AudioStreamPlayer = (
			AudioStreamPlayer.new()
		)

		player.name = (
			"IntroductionOneShot"
			+ str(index + 1)
		)

		player.process_mode = (
			Node.PROCESS_MODE_ALWAYS
		)

		add_child(player)

		audio_one_shot_players.append(
			player
		)


func _connect_audio_hover_signals() -> void:
	left_arrow_button.mouse_entered.connect(
		_on_navigation_hovered.bind(
			left_arrow_button
		)
	)

	right_arrow_button.mouse_entered.connect(
		_on_navigation_hovered.bind(
			right_arrow_button
		)
	)

	start_button.mouse_entered.connect(
		_on_navigation_hovered.bind(
			start_button
		)
	)


func _on_navigation_hovered(
	button: Button
) -> void:
	if button == null:
		return

	if button.disabled:
		return

	if current_state != IntroductionState.VIEWING_SLIDES:
		return

	_play_one_shot(
		stream_ui_hover,
		introduction_ui_volume_db,
		1.0
	)


func _play_one_shot(
	stream: AudioStream,
	volume_db: float,
	pitch_scale: float = 1.0
) -> void:
	if stream == null:
		return

	if audio_one_shot_players.is_empty():
		return

	var player: AudioStreamPlayer = (
		audio_one_shot_players[
			audio_one_shot_index
		]
	)

	audio_one_shot_index = (
		audio_one_shot_index + 1
	) % audio_one_shot_players.size()

	player.stop()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


func _start_instruction_music() -> void:
	if instruction_music_player == null:
		return

	if stream_bgm_instruction == null:
		return

	_kill_instruction_music_tween()

	instruction_music_player.stream = (
		stream_bgm_instruction
	)

	instruction_music_player.volume_db = -80.0
	instruction_music_player.play()

	instruction_music_tween = create_tween()
	instruction_music_tween.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)

	instruction_music_tween.tween_property(
		instruction_music_player,
		"volume_db",
		instruction_music_volume_db,
		instruction_music_fade_in_time
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_OUT
	)

	instruction_music_tween.finished.connect(
		func() -> void:
			instruction_music_tween = null
	)


func _fade_out_instruction_music() -> void:
	if instruction_music_player == null:
		return

	if not instruction_music_player.playing:
		return

	_kill_instruction_music_tween()

	instruction_music_tween = create_tween()
	instruction_music_tween.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)

	instruction_music_tween.tween_property(
		instruction_music_player,
		"volume_db",
		-80.0,
		instruction_music_fade_out_time
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN
	)

	instruction_music_tween.finished.connect(
		func() -> void:
			if instruction_music_player != null:
				instruction_music_player.stop()

			instruction_music_tween = null
	)


func _kill_instruction_music_tween() -> void:
	if instruction_music_tween != null:
		instruction_music_tween.kill()
		instruction_music_tween = null


func _stop_introduction_audio() -> void:
	_kill_instruction_music_tween()

	if instruction_music_player != null:
		instruction_music_player.stop()
		instruction_music_player.volume_db = -80.0

	for player in audio_one_shot_players:
		if player != null:
			player.stop()

	audio_one_shot_index = 0


func _play_countdown_audio(
	countdown_index: int
) -> void:
	match countdown_index:
		0:
			_play_one_shot(
				stream_countdown_3,
				introduction_sfx_volume_db,
				1.0
			)

		1:
			_play_one_shot(
				stream_countdown_2,
				introduction_sfx_volume_db,
				1.0
			)

		2:
			_play_one_shot(
				stream_countdown_1,
				introduction_sfx_volume_db,
				1.0
			)


func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		push_error(
			"INTRODUCTION: Missing texture: "
			+ path
		)
		return null

	var loaded_texture: Texture2D = (
		load(path) as Texture2D
	)

	if loaded_texture == null:
		push_error(
			"INTRODUCTION: Failed to load: "
			+ path
		)

	return loaded_texture


func _load_minigame_slides(
	minigame_id: String
) -> Array[Texture2D]:
	var folder_path: String = (
		INTRO_ASSET_ROOT
		+ minigame_id
		+ "/"
	)

	var slide_paths: Array[String] = [
		folder_path + "01_title.png",
		folder_path + "02_objective.png",
		folder_path + "03_how_to_play.png",
		folder_path + "04_how_to_win.png",
		folder_path + "05_when_you_lose.png"
	]

	var loaded_slides: Array[Texture2D] = []

	for path in slide_paths:
		var texture: Texture2D = _load_texture(path)

		if texture != null:
			loaded_slides.append(texture)

	return loaded_slides


# =========================================================
# CLICKABLE AREAS
# =========================================================

func _setup_buttons() -> void:
	_setup_invisible_button(
		left_arrow_button,
		left_arrow_click_center,
		arrow_click_size
	)

	_setup_invisible_button(
		right_arrow_button,
		right_arrow_click_center,
		arrow_click_size
	)

	_setup_invisible_button(
		start_button,
		start_button_click_center,
		start_click_size
	)


func _setup_invisible_button(
	button: Button,
	screen_center_position: Vector2,
	button_size: Vector2
) -> void:
	button.text = ""
	button.flat = true

	# The parent group is centered at 576,324.
	# Convert the screen-space button center into
	# the group's local coordinates.
	var local_center: Vector2 = (
		screen_center_position
		- full_canvas_position
	)

	button.position = (
		local_center
		- button_size * 0.5
	)

	button.size = button_size
	button.pivot_offset = button_size * 0.5

	# Mouse only. Space and Enter cannot activate it.
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP

	button.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND
	)

	button.disabled = true

	var empty_style: StyleBoxEmpty = (
		StyleBoxEmpty.new()
	)

	button.add_theme_stylebox_override(
		"normal",
		empty_style
	)

	button.add_theme_stylebox_override(
		"hover",
		empty_style
	)

	button.add_theme_stylebox_override(
		"pressed",
		empty_style
	)

	button.add_theme_stylebox_override(
		"focus",
		empty_style
	)

	button.add_theme_stylebox_override(
		"disabled",
		empty_style
	)


func _connect_buttons() -> void:
	left_arrow_button.pressed.connect(
		_on_left_arrow_pressed
	)

	right_arrow_button.pressed.connect(
		_on_right_arrow_pressed
	)

	start_button.pressed.connect(
		_on_start_button_pressed
	)


# =========================================================
# START INTRODUCTION
# =========================================================

func start_introduction(minigame_id: String) -> void:
	if (
		current_state != IntroductionState.IDLE
		and current_state != IntroductionState.FINISHED
	):
		return

	_kill_all_tweens()
	_reset_introduction()

	current_minigame_id = minigame_id

	slides = _load_minigame_slides(
		current_minigame_id
	)

	if slides.size() != 5:
		push_error(
			"INTRODUCTION: Exactly five slides "
			+ "are required for "
			+ current_minigame_id
			+ ". Loaded: "
			+ str(slides.size())
		)
		return

	current_slide_index = 0
	current_state = IntroductionState.OPENING

	_play_one_shot(
		stream_intro_open,
		introduction_sfx_volume_db,
		1.0
	)

	_start_instruction_music()

	root.visible = true
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	black_background.visible = true
	black_background.color = Color.BLACK

	slide_image.visible = true
	slide_image.texture = slides[0]
	slide_image.position = slide_base_position
	slide_image.scale = slide_panel_scale
	slide_image.modulate = Color(1, 1, 1, 0)

	left_arrow_group.visible = false
	right_arrow_group.visible = false
	start_button_group.visible = false

	countdown_layer.visible = false

	introduction_started.emit(
		current_minigame_id
	)

	print("")
	print("========================================")
	print("INTRODUCTION STARTED")
	print("Minigame: ", current_minigame_id)
	print("Slides loaded: ", slides.size())
	print("========================================")
	print("")

	if opening_black_hold > 0.0:
		await get_tree().create_timer(
			opening_black_hold
		).timeout

	if current_state != IntroductionState.OPENING:
		return

	opening_tween = create_tween()

	opening_tween.tween_property(
		slide_image,
		"modulate:a",
		1.0,
		opening_fade_duration
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)

	await opening_tween.finished
	opening_tween = null

	if current_state != IntroductionState.OPENING:
		return

	current_state = IntroductionState.VIEWING_SLIDES

	_update_navigation_visibility()


func reset_introduction() -> void:
	_kill_all_tweens()
	_reset_introduction()


func is_introduction_active() -> bool:
	return (
		current_state != IntroductionState.IDLE
		and current_state != IntroductionState.FINISHED
	)


# =========================================================
# SLIDE NAVIGATION
# =========================================================

func _on_left_arrow_pressed() -> void:
	if current_state != IntroductionState.VIEWING_SLIDES:
		return

	if current_slide_index <= 0:
		return

	_play_one_shot(
		stream_ui_click,
		introduction_ui_volume_db,
		1.0
	)

	_play_one_shot(
		stream_slide_previous,
		introduction_sfx_volume_db,
		1.0
	)

	await _change_slide(
		current_slide_index - 1,
		-1
	)


func _on_right_arrow_pressed() -> void:
	if current_state != IntroductionState.VIEWING_SLIDES:
		return

	if current_slide_index >= slides.size() - 1:
		return

	_play_one_shot(
		stream_ui_click,
		introduction_ui_volume_db,
		1.0
	)

	_play_one_shot(
		stream_slide_next,
		introduction_sfx_volume_db,
		1.0
	)

	await _change_slide(
		current_slide_index + 1,
		1
	)


func _change_slide(
	new_slide_index: int,
	direction: int
) -> void:
	if current_state != IntroductionState.VIEWING_SLIDES:
		return

	current_state = IntroductionState.CHANGING_SLIDE
	_set_navigation_enabled(false)

	var original_position: Vector2 = slide_base_position

	active_slide_tween = create_tween()
	active_slide_tween.set_parallel(true)

	active_slide_tween.tween_property(
		slide_image,
		"position:x",
		original_position.x
		- slide_transition_distance * direction,
		slide_transition_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	active_slide_tween.tween_property(
		slide_image,
		"modulate:a",
		0.0,
		slide_transition_duration
	)

	await active_slide_tween.finished
	active_slide_tween = null

	if current_state != IntroductionState.CHANGING_SLIDE:
		return

	current_slide_index = new_slide_index
	slide_image.texture = slides[current_slide_index]

	slide_image.position = Vector2(
		original_position.x
		+ slide_transition_distance * direction,
		original_position.y
	)

	slide_image.scale = slide_panel_scale
	slide_image.modulate.a = 0.0

	active_slide_tween = create_tween()
	active_slide_tween.set_parallel(true)

	active_slide_tween.tween_property(
		slide_image,
		"position",
		original_position,
		slide_transition_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	active_slide_tween.tween_property(
		slide_image,
		"modulate:a",
		1.0,
		slide_transition_duration
	)

	await active_slide_tween.finished
	active_slide_tween = null

	if current_state != IntroductionState.CHANGING_SLIDE:
		return

	current_state = IntroductionState.VIEWING_SLIDES

	_update_navigation_visibility()


func _update_navigation_visibility() -> void:
	if slides.is_empty():
		return

	var is_first_slide: bool = (
		current_slide_index == 0
	)

	var is_last_slide: bool = (
		current_slide_index == slides.size() - 1
	)

	left_arrow_group.visible = not is_first_slide
	right_arrow_group.visible = not is_last_slide
	start_button_group.visible = is_last_slide

	_set_navigation_enabled(true)


func _set_navigation_enabled(enabled: bool) -> void:
	left_arrow_button.disabled = (
		not enabled
		or not left_arrow_group.visible
	)

	right_arrow_button.disabled = (
		not enabled
		or not right_arrow_group.visible
	)

	start_button.disabled = (
		not enabled
		or not start_button_group.visible
	)


# =========================================================
# START BUTTON AND COUNTDOWN
# =========================================================

func _on_start_button_pressed() -> void:
	if current_state != IntroductionState.VIEWING_SLIDES:
		return

	if current_slide_index != slides.size() - 1:
		return

	current_state = IntroductionState.STARTING_COUNTDOWN
	_set_navigation_enabled(false)

	_play_one_shot(
		stream_start_pressed,
		introduction_sfx_volume_db,
		1.0
	)

	_fade_out_instruction_music()

	start_requested.emit()

	print("")
	print("========================================")
	print("INTRODUCTION START BUTTON PRESSED")
	print("Preparing countdown.")
	print("========================================")
	print("")

	await get_tree().process_frame

	if current_state != IntroductionState.STARTING_COUNTDOWN:
		return

	await _begin_countdown()


func _begin_countdown() -> void:
	current_state = IntroductionState.COUNTDOWN

	slide_image.visible = false

	left_arrow_group.visible = false
	right_arrow_group.visible = false
	start_button_group.visible = false

	# Reveal the minigame behind the transparent overlay.
	black_background.visible = false

	countdown_layer.visible = true
	countdown_layer.modulate = Color.WHITE

	countdown_dim.visible = true
	countdown_dim.color = Color(
		0.0,
		0.0,
		0.0,
		countdown_dim_alpha
	)

	countdown_number.visible = false
	countdown_number.position = Vector2.ZERO
	countdown_number.pivot_offset = SCREEN_CENTER

	countdown_started.emit()

	if countdown_textures.size() != 3:
		push_error(
			"INTRODUCTION: Countdown textures "
			+ "are missing."
		)
		return

	for countdown_index in range(
		countdown_textures.size()
	):
		if current_state != IntroductionState.COUNTDOWN:
			return

		var texture: Texture2D = (
			countdown_textures[
				countdown_index
			]
		)

		await _play_countdown_number(
			texture,
			countdown_index
		)

		if countdown_between_numbers > 0.0:
			await get_tree().create_timer(
				countdown_between_numbers
			).timeout

	if current_state != IntroductionState.COUNTDOWN:
		return

	countdown_number.visible = false

	var dim_fade: Tween = create_tween()

	dim_fade.tween_property(
		countdown_dim,
		"color:a",
		0.0,
		0.18
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_OUT
	)

	await dim_fade.finished

	if current_state != IntroductionState.COUNTDOWN:
		return

	countdown_layer.visible = false
	root.visible = false
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	current_state = IntroductionState.FINISHED

	print("")
	print("========================================")
	print("INTRODUCTION COUNTDOWN FINISHED")
	print("Minigame: ", current_minigame_id)
	print("========================================")
	print("")

	_play_one_shot(
		stream_countdown_go,
		introduction_sfx_volume_db,
		1.0
	)

	countdown_finished.emit()


func _play_countdown_number(
	number_texture: Texture2D,
	countdown_index: int
) -> void:
	countdown_number.texture = number_texture

	_play_countdown_audio(
		countdown_index
	)
	countdown_number.visible = true

	countdown_number.position = Vector2.ZERO
	countdown_number.scale = countdown_start_scale
	countdown_number.modulate = Color(1, 1, 1, 0)

	countdown_tween = create_tween()
	countdown_tween.set_parallel(true)

	countdown_tween.tween_property(
		countdown_number,
		"scale",
		countdown_normal_scale,
		countdown_number_enter_time
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	countdown_tween.tween_property(
		countdown_number,
		"modulate:a",
		1.0,
		countdown_number_enter_time
	)

	await countdown_tween.finished
	countdown_tween = null

	if current_state != IntroductionState.COUNTDOWN:
		return

	await get_tree().create_timer(
		countdown_number_hold_time
	).timeout

	if current_state != IntroductionState.COUNTDOWN:
		return

	countdown_tween = create_tween()
	countdown_tween.set_parallel(true)

	countdown_tween.tween_property(
		countdown_number,
		"scale",
		Vector2(0.90, 0.90),
		countdown_number_exit_time
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	countdown_tween.tween_property(
		countdown_number,
		"modulate:a",
		0.0,
		countdown_number_exit_time
	)

	await countdown_tween.finished
	countdown_tween = null

	countdown_number.visible = false


# =========================================================
# RESET AND CLEANUP
# =========================================================

func _reset_introduction() -> void:
	_stop_introduction_audio()

	current_state = IntroductionState.IDLE
	current_minigame_id = ""

	slides.clear()
	current_slide_index = 0

	if root == null:
		return

	root.visible = false
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	black_background.visible = true
	black_background.color = Color.BLACK

	slide_image.visible = false
	slide_image.texture = null
	slide_image.position = slide_base_position
	slide_image.scale = slide_panel_scale
	slide_image.modulate = Color.WHITE

	left_arrow_group.visible = false
	right_arrow_group.visible = false
	start_button_group.visible = false

	left_arrow_group.position = full_canvas_position
	right_arrow_group.position = full_canvas_position
	start_button_group.position = full_canvas_position

	left_arrow_group.scale = Vector2.ONE
	right_arrow_group.scale = Vector2.ONE
	start_button_group.scale = Vector2.ONE

	left_arrow_group.modulate = Color.WHITE
	right_arrow_group.modulate = Color.WHITE
	start_button_group.modulate = Color.WHITE

	left_arrow_button.disabled = true
	right_arrow_button.disabled = true
	start_button.disabled = true

	left_arrow_button.release_focus()
	right_arrow_button.release_focus()
	start_button.release_focus()

	countdown_layer.visible = false
	countdown_layer.modulate = Color.WHITE

	countdown_dim.visible = true
	countdown_dim.color = Color(
		0.0,
		0.0,
		0.0,
		countdown_dim_alpha
	)

	countdown_number.visible = false
	countdown_number.texture = null
	countdown_number.position = Vector2.ZERO
	countdown_number.scale = countdown_normal_scale
	countdown_number.modulate = Color.WHITE


func _kill_all_tweens() -> void:
	_kill_instruction_music_tween()

	if active_slide_tween != null:
		active_slide_tween.kill()
		active_slide_tween = null

	if opening_tween != null:
		opening_tween.kill()
		opening_tween = null

	if countdown_tween != null:
		countdown_tween.kill()
		countdown_tween = null
