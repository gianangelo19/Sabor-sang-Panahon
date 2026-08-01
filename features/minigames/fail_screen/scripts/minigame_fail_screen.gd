extends CanvasLayer

signal retry_requested
signal exit_requested
signal game_over_revealed


enum FailState {
	IDLE,
	DARKENING,
	SHOWING_DIALOGUE,
	WAITING_FOR_SPACE,
	HIDING_DIALOGUE,
	SHOWING_RESULTS,
	WAITING_FOR_CHOICE,
	FINISHED
}


const SCREEN_SIZE: Vector2 = Vector2(1152, 648)
const SCREEN_CENTER: Vector2 = Vector2(576, 324)

const FONT_PATH: String = (
	"res://features/minigames/shared/fonts/VCR_OSD_MONO_1.001.ttf"
)

const DIALOGUE_TEXTURE_PATH: String = (
	"res://features/minigames/box_unboxing/assets/ui/dialogue_box_memory.png"
)

const GAME_OVER_TEXTURE_PATH: String = (
	"res://features/minigames/fail_screen/assets/ui/game_over_title.png"
)

const RETRY_TEXTURE_PATH: String = (
	"res://features/minigames/fail_screen/assets/ui/retry_button.png"
)

const EXIT_TEXTURE_PATH: String = (
	"res://features/minigames/fail_screen/assets/ui/exit_button.png"
)


const FAIL_AUDIO_ROOT: String = (
	"res://features/minigames/fail_screen/assets/audio/"
)

const BGM_FAIL_SCREEN_PATH: String = (
	FAIL_AUDIO_ROOT
	+ "music/bgm_fail_screen_loop.ogg"
)

const SFX_FAIL_TRIGGER_PATH: String = (
	FAIL_AUDIO_ROOT
	+ "sfx/sfx_fail_trigger.wav"
)

const SFX_FAIL_DARKEN_SWELL_PATH: String = (
	FAIL_AUDIO_ROOT
	+ "sfx/sfx_fail_darken_swell.wav"
)

const SFX_DIALOGUE_APPEAR_PATH: String = (
	FAIL_AUDIO_ROOT
	+ "sfx/sfx_dialogue_appear.wav"
)

const SFX_CONTINUE_PROMPT_PATH: String = (
	FAIL_AUDIO_ROOT
	+ "sfx/sfx_continue_prompt.wav"
)

const SFX_SPACE_CONTINUE_PATH: String = (
	FAIL_AUDIO_ROOT
	+ "sfx/sfx_space_continue.wav"
)

const SFX_GAME_OVER_REVEAL_PATH: String = (
	FAIL_AUDIO_ROOT
	+ "sfx/sfx_game_over_reveal.wav"
)

const SFX_RETRY_SELECTED_PATH: String = (
	FAIL_AUDIO_ROOT
	+ "sfx/sfx_retry_selected.wav"
)

const SFX_EXIT_SELECTED_PATH: String = (
	FAIL_AUDIO_ROOT
	+ "sfx/sfx_exit_selected.wav"
)

const SFX_UI_HOVER_PATH: String = (
	FAIL_AUDIO_ROOT
	+ "ui/sfx_ui_hover.wav"
)

const SFX_UI_BUTTON_DOWN_PATH: String = (
	FAIL_AUDIO_ROOT
	+ "ui/sfx_ui_button_down.wav"
)

const SFX_UI_BUTTON_UP_PATH: String = (
	FAIL_AUDIO_ROOT
	+ "ui/sfx_ui_button_up.wav"
)

const SFX_UI_CLICK_PATH: String = (
	FAIL_AUDIO_ROOT
	+ "ui/sfx_ui_click.wav"
)


@export_category("Canvas")

@export var fail_canvas_layer: int = 200


@export_category("Darkening")

@export_range(0.0, 1.0, 0.05)
var dim_target_alpha: float = 0.82

@export var darken_duration: float = 5.0


@export_category("Dialogue - Same as Box Unboxing")

# Same dialogue panel placement used by Box Unboxing.
@export var dialogue_box_position: Vector2 = Vector2(576, 324)
@export var dialogue_box_scale: Vector2 = Vector2(0.6, 0.6)

# Exact dialogue text placement from Box Unboxing.
@export var dialogue_position: Vector2 = Vector2(265, 475)
@export var dialogue_size: Vector2 = Vector2(625, 90)
@export var dialogue_font_size: int = 22

# Exact continue-label position from Box Unboxing.
@export var continue_position: Vector2 = Vector2(455, 620)
@export var continue_size: Vector2 = Vector2(400, 24)
@export var continue_font_size: int = 18

# Dialogue typewriter speed.
# Higher values reveal the dialogue faster.
@export var dialogue_characters_per_second: float = 42.0
@export var dialogue_typewriter_min_duration: float = 0.35

# The SPACE prompt appears only after the typewriter finishes.
@export var continue_prompt_delay: float = 0.60

@export var dialogue_hide_duration: float = 0.25


@export_category("Game Over Full-Canvas Assets")

# The Game Over, Retry, and Exit images are treated as
# full 1920x1080 canvas assets.
@export var result_asset_position: Vector2 = Vector2(576, 324)
@export var result_asset_scale: Vector2 = Vector2(0.6, 0.6)

# Results now appear in this order:
# GAME OVER -> reason -> score -> buttons.
@export var game_over_appear_duration: float = 0.35
@export var reason_appear_duration: float = 0.28
@export var score_appear_duration: float = 0.25
@export var buttons_appear_duration: float = 0.30
@export var result_reveal_gap: float = 0.12

@export var game_over_start_scale_multiplier: float = 1.08


@export_category("Result Text")

@export var reason_position: Vector2 = Vector2(176, 315)
@export var reason_size: Vector2 = Vector2(800, 70)
@export var reason_font_size: int = 24

@export var score_position: Vector2 = Vector2(376, 395)
@export var score_size: Vector2 = Vector2(400, 45)
@export var score_font_size: int = 26


@export_category("Invisible Button Areas")

# These are screen positions for the clickable button centers.
# The visible PNG assets themselves stay centered at 576,324
# with a scale of 0.6.
@export var retry_click_center: Vector2 = Vector2(390, 530)
@export var exit_click_center: Vector2 = Vector2(762, 530)

@export var action_button_size: Vector2 = Vector2(280, 90)

@export var button_hover_scale: Vector2 = Vector2(1.03, 1.03)
@export var button_pressed_scale: Vector2 = Vector2(0.98, 0.98)
@export var button_animation_duration: float = 0.10


@export_category("Audio")

@export var fail_music_volume_db: float = -18.0
@export var fail_sfx_volume_db: float = -3.0
@export var fail_ui_volume_db: float = -10.0

@export var fail_music_fade_in_time: float = 2.20
@export var retry_music_fade_out_time: float = 0.22
@export var exit_music_fade_out_time: float = 0.45

# Small delays let Retry/Exit confirmation audio begin before
# the parent minigame reloads or exits after the emitted signal.
@export var retry_signal_delay: float = 0.32
@export var exit_signal_delay: float = 0.38

@export var audio_one_shot_player_count: int = 10


var current_state: FailState = FailState.IDLE

var current_dialogue: String = ""
var current_reason: String = ""
var current_score: int = 0
var should_show_score: bool = true


var fail_root: Control
var dim_overlay: ColorRect

var dialogue_group: Control
var dialogue_box: Sprite2D
var dialogue_label: Label
var continue_label: Label

var result_group: Control
var game_over_title: Sprite2D
var reason_label: Label
var score_label: Label

var retry_group: Node2D
var retry_sprite: Sprite2D
var retry_button: Button

var exit_group: Node2D
var exit_sprite: Sprite2D
var exit_button: Button


var active_tween: Tween
var continue_tween: Tween
var retry_button_tween: Tween
var exit_button_tween: Tween


var fail_music_player: AudioStreamPlayer = null
var fail_one_shot_players: Array[AudioStreamPlayer] = []
var fail_one_shot_index: int = 0
var fail_music_tween: Tween = null

var stream_bgm_fail_screen: AudioStream = null

var stream_fail_trigger: AudioStream = null
var stream_fail_darken_swell: AudioStream = null
var stream_dialogue_appear: AudioStream = null
var stream_continue_prompt: AudioStream = null
var stream_space_continue: AudioStream = null
var stream_game_over_reveal: AudioStream = null
var stream_retry_selected: AudioStream = null
var stream_exit_selected: AudioStream = null

var stream_ui_hover: AudioStream = null
var stream_ui_button_down: AudioStream = null
var stream_ui_button_up: AudioStream = null
var stream_ui_click: AudioStream = null


func _ready() -> void:
	layer = fail_canvas_layer
	process_mode = Node.PROCESS_MODE_ALWAYS

	_build_or_find_interface()
	_load_interface_assets()
	_load_audio_assets()
	_setup_audio_players()
	_setup_labels()
	_setup_buttons()
	_setup_layer_order()
	_connect_buttons()
	_reset_visuals()

	print("")
	print("========================================")
	print("MINIGAME FAIL SCREEN READY")
	print("========================================")
	print("Speaker label used: false")
	print("Dialogue box position: ", dialogue_box_position)
	print("Dialogue text position: ", dialogue_position)
	print("Continue position: ", continue_position)
	print("Result asset position: ", result_asset_position)
	print("Result asset scale: ", result_asset_scale)
	print("========================================")
	print("")


func _input(event: InputEvent) -> void:
	if current_state != FailState.WAITING_FOR_SPACE:
		return

	if not event is InputEventKey:
		return

	if not event.pressed:
		return

	if event.echo:
		return

	if event.keycode != KEY_SPACE:
		return

	get_viewport().set_input_as_handled()

	_play_fail_one_shot(
		stream_space_continue,
		fail_sfx_volume_db,
		1.0
	)

	_show_game_over_results()


func _build_or_find_interface() -> void:
	fail_root = get_node_or_null("FailRoot") as Control

	if fail_root == null:
		_remove_wrong_child(self, "FailRoot")

		fail_root = Control.new()
		fail_root.name = "FailRoot"
		add_child(fail_root)

	_set_full_rect(fail_root)
	fail_root.mouse_filter = Control.MOUSE_FILTER_IGNORE


	dim_overlay = fail_root.get_node_or_null(
		"DimOverlay"
	) as ColorRect

	if dim_overlay == null:
		_remove_wrong_child(fail_root, "DimOverlay")

		dim_overlay = ColorRect.new()
		dim_overlay.name = "DimOverlay"
		fail_root.add_child(dim_overlay)

	_set_full_rect(dim_overlay)
	dim_overlay.color = Color(0, 0, 0, 0)
	dim_overlay.mouse_filter = Control.MOUSE_FILTER_STOP


	dialogue_group = fail_root.get_node_or_null(
		"DialogueGroup"
	) as Control

	if dialogue_group == null:
		_remove_wrong_child(fail_root, "DialogueGroup")

		dialogue_group = Control.new()
		dialogue_group.name = "DialogueGroup"
		fail_root.add_child(dialogue_group)

	_set_full_rect(dialogue_group)
	dialogue_group.mouse_filter = Control.MOUSE_FILTER_IGNORE


	dialogue_box = dialogue_group.get_node_or_null(
		"DialogueBox"
	) as Sprite2D

	if dialogue_box == null:
		_remove_wrong_child(dialogue_group, "DialogueBox")

		dialogue_box = Sprite2D.new()
		dialogue_box.name = "DialogueBox"
		dialogue_group.add_child(dialogue_box)


	# This fail screen goes directly to the dialogue.
	# Remove an older SpeakerLabel node if it still exists in the scene.
	_remove_wrong_child(dialogue_group, "SpeakerLabel")


	dialogue_label = dialogue_group.get_node_or_null(
		"DialogueLabel"
	) as Label

	if dialogue_label == null:
		_remove_wrong_child(dialogue_group, "DialogueLabel")

		dialogue_label = Label.new()
		dialogue_label.name = "DialogueLabel"
		dialogue_group.add_child(dialogue_label)


	continue_label = dialogue_group.get_node_or_null(
		"ContinueLabel"
	) as Label

	if continue_label == null:
		_remove_wrong_child(dialogue_group, "ContinueLabel")

		continue_label = Label.new()
		continue_label.name = "ContinueLabel"
		dialogue_group.add_child(continue_label)


	result_group = fail_root.get_node_or_null(
		"ResultGroup"
	) as Control

	if result_group == null:
		_remove_wrong_child(fail_root, "ResultGroup")

		result_group = Control.new()
		result_group.name = "ResultGroup"
		fail_root.add_child(result_group)

	_set_full_rect(result_group)
	result_group.mouse_filter = Control.MOUSE_FILTER_IGNORE


	game_over_title = result_group.get_node_or_null(
		"GameOverTitle"
	) as Sprite2D

	if game_over_title == null:
		_remove_wrong_child(result_group, "GameOverTitle")

		game_over_title = Sprite2D.new()
		game_over_title.name = "GameOverTitle"
		result_group.add_child(game_over_title)


	reason_label = result_group.get_node_or_null(
		"ReasonLabel"
	) as Label

	if reason_label == null:
		_remove_wrong_child(result_group, "ReasonLabel")

		reason_label = Label.new()
		reason_label.name = "ReasonLabel"
		result_group.add_child(reason_label)


	score_label = result_group.get_node_or_null(
		"ScoreLabel"
	) as Label

	if score_label == null:
		_remove_wrong_child(result_group, "ScoreLabel")

		score_label = Label.new()
		score_label.name = "ScoreLabel"
		result_group.add_child(score_label)


	retry_group = result_group.get_node_or_null(
		"RetryGroup"
	) as Node2D

	if retry_group == null:
		_remove_wrong_child(result_group, "RetryGroup")

		retry_group = Node2D.new()
		retry_group.name = "RetryGroup"
		result_group.add_child(retry_group)


	retry_sprite = retry_group.get_node_or_null(
		"RetrySprite"
	) as Sprite2D

	if retry_sprite == null:
		_remove_wrong_child(retry_group, "RetrySprite")

		retry_sprite = Sprite2D.new()
		retry_sprite.name = "RetrySprite"
		retry_group.add_child(retry_sprite)


	retry_button = retry_group.get_node_or_null(
		"RetryButton"
	) as Button

	if retry_button == null:
		_remove_wrong_child(retry_group, "RetryButton")

		retry_button = Button.new()
		retry_button.name = "RetryButton"
		retry_group.add_child(retry_button)


	exit_group = result_group.get_node_or_null(
		"ExitGroup"
	) as Node2D

	if exit_group == null:
		_remove_wrong_child(result_group, "ExitGroup")

		exit_group = Node2D.new()
		exit_group.name = "ExitGroup"
		result_group.add_child(exit_group)


	exit_sprite = exit_group.get_node_or_null(
		"ExitSprite"
	) as Sprite2D

	if exit_sprite == null:
		_remove_wrong_child(exit_group, "ExitSprite")

		exit_sprite = Sprite2D.new()
		exit_sprite.name = "ExitSprite"
		exit_group.add_child(exit_sprite)


	exit_button = exit_group.get_node_or_null(
		"ExitButton"
	) as Button

	if exit_button == null:
		_remove_wrong_child(exit_group, "ExitButton")

		exit_button = Button.new()
		exit_button.name = "ExitButton"
		exit_group.add_child(exit_button)


func _remove_wrong_child(
	parent_node: Node,
	child_name: String
) -> void:
	var wrong_child: Node = parent_node.get_node_or_null(
		child_name
	)

	if wrong_child == null:
		return

	parent_node.remove_child(wrong_child)
	wrong_child.queue_free()


func _set_full_rect(control: Control) -> void:
	control.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)


func _load_interface_assets() -> void:
	dialogue_box.texture = _load_texture(
		DIALOGUE_TEXTURE_PATH
	)

	dialogue_box.centered = true
	dialogue_box.position = dialogue_box_position
	dialogue_box.scale = dialogue_box_scale


	game_over_title.texture = _load_texture(
		GAME_OVER_TEXTURE_PATH
	)

	game_over_title.centered = true
	game_over_title.position = result_asset_position
	game_over_title.scale = result_asset_scale


	retry_sprite.texture = _load_texture(
		RETRY_TEXTURE_PATH
	)

	retry_sprite.centered = true
	retry_sprite.position = Vector2.ZERO
	retry_sprite.scale = result_asset_scale


	exit_sprite.texture = _load_texture(
		EXIT_TEXTURE_PATH
	)

	exit_sprite.centered = true
	exit_sprite.position = Vector2.ZERO
	exit_sprite.scale = result_asset_scale




# =========================================================
# AUDIO
# =========================================================

func _load_audio_assets() -> void:
	stream_bgm_fail_screen = _load_audio_stream(
		BGM_FAIL_SCREEN_PATH
	)

	stream_fail_trigger = _load_audio_stream(
		SFX_FAIL_TRIGGER_PATH
	)

	stream_fail_darken_swell = _load_audio_stream(
		SFX_FAIL_DARKEN_SWELL_PATH
	)

	stream_dialogue_appear = _load_audio_stream(
		SFX_DIALOGUE_APPEAR_PATH
	)

	stream_continue_prompt = _load_audio_stream(
		SFX_CONTINUE_PROMPT_PATH
	)

	stream_space_continue = _load_audio_stream(
		SFX_SPACE_CONTINUE_PATH
	)

	stream_game_over_reveal = _load_audio_stream(
		SFX_GAME_OVER_REVEAL_PATH
	)

	stream_retry_selected = _load_audio_stream(
		SFX_RETRY_SELECTED_PATH
	)

	stream_exit_selected = _load_audio_stream(
		SFX_EXIT_SELECTED_PATH
	)

	stream_ui_hover = _load_audio_stream(
		SFX_UI_HOVER_PATH
	)

	stream_ui_button_down = _load_audio_stream(
		SFX_UI_BUTTON_DOWN_PATH
	)

	stream_ui_button_up = _load_audio_stream(
		SFX_UI_BUTTON_UP_PATH
	)

	stream_ui_click = _load_audio_stream(
		SFX_UI_CLICK_PATH
	)

	_enable_fail_music_loop(
		stream_bgm_fail_screen
	)


func _load_audio_stream(
	path: String
) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning(
			"FAIL SCREEN AUDIO: Missing audio: "
			+ path
		)

		return null

	var loaded_stream: AudioStream = (
		load(path) as AudioStream
	)

	if loaded_stream == null:
		push_warning(
			"FAIL SCREEN AUDIO: Failed to load: "
			+ path
		)

	return loaded_stream


func _enable_fail_music_loop(
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
	fail_music_player = AudioStreamPlayer.new()
	fail_music_player.name = "FailMusicPlayer"
	fail_music_player.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)
	fail_music_player.stream = (
		stream_bgm_fail_screen
	)
	fail_music_player.volume_db = -80.0

	add_child(
		fail_music_player
	)

	fail_one_shot_players.clear()
	fail_one_shot_index = 0

	var player_count: int = maxi(
		1,
		audio_one_shot_player_count
	)

	for index in range(player_count):
		var player: AudioStreamPlayer = (
			AudioStreamPlayer.new()
		)

		player.name = (
			"FailOneShot"
			+ str(index + 1)
		)

		player.process_mode = (
			Node.PROCESS_MODE_ALWAYS
		)

		add_child(player)

		fail_one_shot_players.append(
			player
		)


func _play_fail_one_shot(
	stream: AudioStream,
	volume_db: float,
	pitch_scale: float = 1.0
) -> void:
	if stream == null:
		return

	if fail_one_shot_players.is_empty():
		return

	var player: AudioStreamPlayer = (
		fail_one_shot_players[
			fail_one_shot_index
		]
	)

	fail_one_shot_index = (
		fail_one_shot_index + 1
	) % fail_one_shot_players.size()

	player.stop()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


func _start_fail_music() -> void:
	if fail_music_player == null:
		return

	if stream_bgm_fail_screen == null:
		return

	_kill_fail_music_tween()

	fail_music_player.stream = (
		stream_bgm_fail_screen
	)

	fail_music_player.volume_db = -80.0
	fail_music_player.play()

	fail_music_tween = create_tween()
	fail_music_tween.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)

	fail_music_tween.tween_property(
		fail_music_player,
		"volume_db",
		fail_music_volume_db,
		fail_music_fade_in_time
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_OUT
	)

	fail_music_tween.finished.connect(
		func() -> void:
			fail_music_tween = null
	)


func _fade_out_fail_music(
	fade_time: float
) -> void:
	if fail_music_player == null:
		return

	if not fail_music_player.playing:
		return

	_kill_fail_music_tween()

	fail_music_tween = create_tween()
	fail_music_tween.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)

	fail_music_tween.tween_property(
		fail_music_player,
		"volume_db",
		-80.0,
		maxf(
			fade_time,
			0.01
		)
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN
	)

	fail_music_tween.finished.connect(
		func() -> void:
			if fail_music_player != null:
				fail_music_player.stop()

			fail_music_tween = null
	)


func _kill_fail_music_tween() -> void:
	if fail_music_tween != null:
		fail_music_tween.kill()
		fail_music_tween = null


func _stop_fail_audio() -> void:
	_kill_fail_music_tween()

	if fail_music_player != null:
		fail_music_player.stop()
		fail_music_player.volume_db = -80.0

	for player in fail_one_shot_players:
		if player != null:
			player.stop()

	fail_one_shot_index = 0


func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		push_error(
			"Fail-screen texture does not exist: "
			+ path
		)

		return null

	return load(path) as Texture2D


func _setup_labels() -> void:
	var shared_font: Font = null

	if ResourceLoader.exists(FONT_PATH):
		shared_font = load(FONT_PATH) as Font
	else:
		push_error(
			"Fail-screen font does not exist: "
			+ FONT_PATH
		)


	_setup_label(
		dialogue_label,
		dialogue_position,
		dialogue_size,
		dialogue_font_size,
		shared_font
	)

	_setup_label(
		continue_label,
		continue_position,
		continue_size,
		continue_font_size,
		shared_font
	)

	_setup_label(
		reason_label,
		reason_position,
		reason_size,
		reason_font_size,
		shared_font
	)

	_setup_label(
		score_label,
		score_position,
		score_size,
		score_font_size,
		shared_font
	)


	dialogue_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT
	)

	dialogue_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_TOP
	)

	dialogue_label.add_theme_color_override(
		"font_color",
		Color(0.16, 0.10, 0.06, 1.0)
	)


	continue_label.text = (
		"Press SPACE to continue..."
	)

	continue_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT
	)

	continue_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	continue_label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)


	reason_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	reason_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	reason_label.add_theme_color_override(
		"font_color",
		Color("#f8e5b9")
	)


	score_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	score_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	score_label.add_theme_color_override(
		"font_color",
		Color("#f8e5b9")
	)


	_add_dark_outline(reason_label)
	_add_dark_outline(score_label)


func _setup_label(
	label: Label,
	label_position: Vector2,
	label_size: Vector2,
	font_size: int,
	font: Font
) -> void:
	label.position = label_position
	label.size = label_size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	label.add_theme_font_size_override(
		"font_size",
		font_size
	)

	if font != null:
		label.add_theme_font_override(
			"font",
			font
		)


func _add_dark_outline(label: Label) -> void:
	label.add_theme_color_override(
		"font_outline_color",
		Color("#1a0d08")
	)

	label.add_theme_constant_override(
		"outline_size",
		4
	)


func _setup_buttons() -> void:
	# Both visible button assets are full-canvas PNGs.
	# Their parent groups are centered at 576,324.
	retry_group.position = result_asset_position
	exit_group.position = result_asset_position

	retry_group.scale = Vector2.ONE
	exit_group.scale = Vector2.ONE

	_setup_invisible_button(
		retry_button,
		retry_click_center
	)

	_setup_invisible_button(
		exit_button,
		exit_click_center
	)


func _setup_invisible_button(
	button: Button,
	screen_center_position: Vector2
) -> void:
	button.text = ""
	button.flat = true

	var local_center: Vector2 = (
		screen_center_position
		- result_asset_position
	)

	button.position = (
		local_center
		- action_button_size * 0.5
	)

	button.size = action_button_size
	button.pivot_offset = action_button_size * 0.5

	button.focus_mode = Control.FOCUS_ALL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
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


func _setup_layer_order() -> void:
	dim_overlay.z_index = 0

	dialogue_group.z_index = 20
	result_group.z_index = 30

	dialogue_box.z_index = 0
	dialogue_label.z_index = 1
	continue_label.z_index = 2

	game_over_title.z_index = 0
	reason_label.z_index = 2
	score_label.z_index = 2

	retry_group.z_index = 1
	exit_group.z_index = 1

	retry_sprite.z_index = 0
	exit_sprite.z_index = 0

	retry_button.z_index = 5
	exit_button.z_index = 5


func _connect_buttons() -> void:
	retry_button.pressed.connect(
		_on_retry_button_pressed
	)

	exit_button.pressed.connect(
		_on_exit_button_pressed
	)

	retry_button.mouse_entered.connect(
		_on_retry_hover_started
	)

	retry_button.mouse_exited.connect(
		_on_retry_hover_ended
	)

	exit_button.mouse_entered.connect(
		_on_exit_hover_started
	)

	exit_button.mouse_exited.connect(
		_on_exit_hover_ended
	)

	retry_button.button_down.connect(
		_on_retry_button_down
	)

	retry_button.button_up.connect(
		_on_retry_button_up
	)

	exit_button.button_down.connect(
		_on_exit_button_down
	)

	exit_button.button_up.connect(
		_on_exit_button_up
	)


func start_fail_screen(
	dialogue: String,
	reason: String,
	score: int = 0,
	show_score: bool = true
) -> void:
	if (
		current_state != FailState.IDLE
		and current_state != FailState.FINISHED
	):
		return

	_kill_all_tweens()
	_reset_visuals()

	current_dialogue = dialogue
	current_reason = reason
	current_score = score
	should_show_score = show_score

	dialogue_label.text = current_dialogue
	reason_label.text = current_reason

	score_label.text = (
		"Score: "
		+ str(current_score)
	)

	fail_root.visible = true

	dim_overlay.visible = true
	dim_overlay.color = Color(0, 0, 0, 0)

	current_state = FailState.DARKENING

	_play_fail_one_shot(
		stream_fail_trigger,
		fail_sfx_volume_db,
		1.0
	)

	_play_fail_one_shot(
		stream_fail_darken_swell,
		fail_sfx_volume_db - 5.0,
		1.0
	)

	_start_fail_music()

	print("")
	print("========================================")
	print("FAIL SCREEN STARTED")
	print("========================================")
	print("Dialogue: ", current_dialogue)
	print("Reason: ", current_reason)
	print("Score: ", current_score)
	print("========================================")
	print("")

	active_tween = create_tween()

	active_tween.tween_property(
		dim_overlay,
		"color:a",
		dim_target_alpha,
		darken_duration
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)

	await active_tween.finished
	active_tween = null

	if current_state != FailState.DARKENING:
		return

	_show_dialogue_instantly()


func _show_dialogue_instantly() -> void:
	current_state = FailState.SHOWING_DIALOGUE

	_play_fail_one_shot(
		stream_dialogue_appear,
		fail_sfx_volume_db,
		1.0
	)

	# The panel appears immediately, but the dialogue is typed.
	dialogue_group.visible = true
	dialogue_group.modulate = Color.WHITE

	dialogue_box.visible = true
	dialogue_label.visible = true

	continue_label.visible = false
	continue_label.modulate = Color.WHITE

	dialogue_label.visible_ratio = 0.0

	var character_count: int = (
		dialogue_label.text.length()
	)

	var typewriter_duration: float = maxf(
		dialogue_typewriter_min_duration,
		float(character_count)
		/ maxf(
			dialogue_characters_per_second,
			1.0
		)
	)

	active_tween = create_tween()

	active_tween.tween_property(
		dialogue_label,
		"visible_ratio",
		1.0,
		typewriter_duration
	).set_trans(
		Tween.TRANS_LINEAR
	).set_ease(
		Tween.EASE_IN_OUT
	)

	await active_tween.finished
	active_tween = null

	if current_state != FailState.SHOWING_DIALOGUE:
		return

	dialogue_label.visible_ratio = 1.0

	if continue_prompt_delay > 0.0:
		await get_tree().create_timer(
			continue_prompt_delay
		).timeout

	if current_state != FailState.SHOWING_DIALOGUE:
		return

	continue_label.visible = true

	_play_fail_one_shot(
		stream_continue_prompt,
		fail_ui_volume_db,
		1.0
	)

	current_state = FailState.WAITING_FOR_SPACE

	_start_continue_pulse()

	print(
		"DEBUG FAIL SCREEN: Waiting for SPACE."
	)


func _show_game_over_results() -> void:
	if current_state != FailState.WAITING_FOR_SPACE:
		return

	current_state = FailState.HIDING_DIALOGUE

	_kill_continue_tween()

	active_tween = create_tween()

	active_tween.tween_property(
		dialogue_group,
		"modulate:a",
		0.0,
		dialogue_hide_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	await active_tween.finished
	active_tween = null

	if current_state != FailState.HIDING_DIALOGUE:
		return

	dialogue_group.visible = false
	result_group.visible = true

	current_state = FailState.SHOWING_RESULTS

	# Prepare all result elements hidden.
	game_over_title.visible = true
	reason_label.visible = true
	score_label.visible = should_show_score

	retry_group.visible = true
	exit_group.visible = true

	game_over_title.position = result_asset_position
	game_over_title.scale = (
		result_asset_scale
		* game_over_start_scale_multiplier
	)

	retry_group.position = result_asset_position
	exit_group.position = result_asset_position

	retry_group.scale = Vector2.ONE
	exit_group.scale = Vector2.ONE

	retry_sprite.scale = result_asset_scale
	exit_sprite.scale = result_asset_scale

	game_over_title.modulate = Color(1, 1, 1, 0)
	reason_label.modulate = Color(1, 1, 1, 0)
	score_label.modulate = Color(1, 1, 1, 0)
	retry_group.modulate = Color(1, 1, 1, 0)
	exit_group.modulate = Color(1, 1, 1, 0)

	retry_button.disabled = true
	exit_button.disabled = true

	# =====================================================
	# 1. GAME OVER TITLE
	# =====================================================

	game_over_revealed.emit()

	_play_fail_one_shot(
		stream_game_over_reveal,
		fail_sfx_volume_db,
		1.0
	)

	active_tween = create_tween()
	active_tween.set_parallel(true)

	active_tween.tween_property(
		game_over_title,
		"modulate:a",
		1.0,
		game_over_appear_duration
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_OUT
	)

	active_tween.tween_property(
		game_over_title,
		"scale",
		result_asset_scale,
		game_over_appear_duration
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	await active_tween.finished
	active_tween = null

	if current_state != FailState.SHOWING_RESULTS:
		return

	await _wait_result_reveal_gap()

	if current_state != FailState.SHOWING_RESULTS:
		return

	# =====================================================
	# 2. REASON
	# =====================================================

	active_tween = create_tween()

	active_tween.tween_property(
		reason_label,
		"modulate:a",
		1.0,
		reason_appear_duration
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_OUT
	)

	await active_tween.finished
	active_tween = null

	if current_state != FailState.SHOWING_RESULTS:
		return

	await _wait_result_reveal_gap()

	if current_state != FailState.SHOWING_RESULTS:
		return

	# =====================================================
	# 3. SCORE
	# =====================================================

	if should_show_score:
		active_tween = create_tween()

		active_tween.tween_property(
			score_label,
			"modulate:a",
			1.0,
			score_appear_duration
		).set_trans(
			Tween.TRANS_SINE
		).set_ease(
			Tween.EASE_OUT
		)

		await active_tween.finished
		active_tween = null

		if current_state != FailState.SHOWING_RESULTS:
			return

		await _wait_result_reveal_gap()

		if current_state != FailState.SHOWING_RESULTS:
			return

	# =====================================================
	# 4. RETRY + EXIT BUTTONS
	# =====================================================

	active_tween = create_tween()
	active_tween.set_parallel(true)

	active_tween.tween_property(
		retry_group,
		"modulate:a",
		1.0,
		buttons_appear_duration
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_OUT
	)

	active_tween.tween_property(
		exit_group,
		"modulate:a",
		1.0,
		buttons_appear_duration
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_OUT
	)

	await active_tween.finished
	active_tween = null

	if current_state != FailState.SHOWING_RESULTS:
		return

	current_state = FailState.WAITING_FOR_CHOICE

	retry_button.disabled = false
	exit_button.disabled = false

	retry_button.grab_focus()

	print(
		"DEBUG FAIL SCREEN: "
		+ "Waiting for Retry or Exit."
	)


func _wait_result_reveal_gap() -> void:
	if result_reveal_gap <= 0.0:
		return

	await get_tree().create_timer(
		result_reveal_gap
	).timeout


func _on_retry_button_pressed() -> void:
	if current_state != FailState.WAITING_FOR_CHOICE:
		return

	current_state = FailState.FINISHED

	retry_button.disabled = true
	exit_button.disabled = true

	_play_fail_one_shot(
		stream_ui_click,
		fail_ui_volume_db - 3.0,
		1.0
	)

	_play_fail_one_shot(
		stream_retry_selected,
		fail_sfx_volume_db,
		1.0
	)

	_fade_out_fail_music(
		retry_music_fade_out_time
	)

	print(
		"DEBUG FAIL SCREEN: Retry selected."
	)

	if retry_signal_delay > 0.0:
		await get_tree().create_timer(
			retry_signal_delay
		).timeout

	retry_requested.emit()


func _on_exit_button_pressed() -> void:
	if current_state != FailState.WAITING_FOR_CHOICE:
		return

	current_state = FailState.FINISHED

	retry_button.disabled = true
	exit_button.disabled = true

	_play_fail_one_shot(
		stream_ui_click,
		fail_ui_volume_db - 3.0,
		1.0
	)

	_play_fail_one_shot(
		stream_exit_selected,
		fail_sfx_volume_db,
		1.0
	)

	_fade_out_fail_music(
		exit_music_fade_out_time
	)

	print(
		"DEBUG FAIL SCREEN: Exit selected."
	)

	if exit_signal_delay > 0.0:
		await get_tree().create_timer(
			exit_signal_delay
		).timeout

	exit_requested.emit()


func _on_retry_hover_started() -> void:
	if current_state != FailState.WAITING_FOR_CHOICE:
		return

	_play_fail_one_shot(
		stream_ui_hover,
		fail_ui_volume_db,
		1.0
	)

	_tween_button_group(
		retry_group,
		button_hover_scale,
		true
	)


func _on_retry_hover_ended() -> void:
	if current_state != FailState.WAITING_FOR_CHOICE:
		return

	_tween_button_group(
		retry_group,
		Vector2.ONE,
		true
	)


func _on_exit_hover_started() -> void:
	if current_state != FailState.WAITING_FOR_CHOICE:
		return

	_play_fail_one_shot(
		stream_ui_hover,
		fail_ui_volume_db,
		1.0
	)

	_tween_button_group(
		exit_group,
		button_hover_scale,
		false
	)


func _on_exit_hover_ended() -> void:
	if current_state != FailState.WAITING_FOR_CHOICE:
		return

	_tween_button_group(
		exit_group,
		Vector2.ONE,
		false
	)


func _on_retry_button_down() -> void:
	if current_state != FailState.WAITING_FOR_CHOICE:
		return

	_play_fail_one_shot(
		stream_ui_button_down,
		fail_ui_volume_db,
		1.0
	)

	_tween_button_group(
		retry_group,
		button_pressed_scale,
		true
	)


func _on_retry_button_up() -> void:
	if current_state != FailState.WAITING_FOR_CHOICE:
		return

	_play_fail_one_shot(
		stream_ui_button_up,
		fail_ui_volume_db,
		1.0
	)

	var target_scale: Vector2 = Vector2.ONE

	if (
		retry_button.is_hovered()
		or retry_button.has_focus()
	):
		target_scale = button_hover_scale

	_tween_button_group(
		retry_group,
		target_scale,
		true
	)


func _on_exit_button_down() -> void:
	if current_state != FailState.WAITING_FOR_CHOICE:
		return

	_play_fail_one_shot(
		stream_ui_button_down,
		fail_ui_volume_db,
		1.0
	)

	_tween_button_group(
		exit_group,
		button_pressed_scale,
		false
	)


func _on_exit_button_up() -> void:
	if current_state != FailState.WAITING_FOR_CHOICE:
		return

	_play_fail_one_shot(
		stream_ui_button_up,
		fail_ui_volume_db,
		1.0
	)

	var target_scale: Vector2 = Vector2.ONE

	if (
		exit_button.is_hovered()
		or exit_button.has_focus()
	):
		target_scale = button_hover_scale

	_tween_button_group(
		exit_group,
		target_scale,
		false
	)


func _tween_button_group(
	button_group: Node2D,
	target_scale: Vector2,
	is_retry: bool
) -> void:
	if is_retry:
		if retry_button_tween != null:
			retry_button_tween.kill()

		retry_button_tween = create_tween()

		retry_button_tween.tween_property(
			button_group,
			"scale",
			target_scale,
			button_animation_duration
		).set_trans(
			Tween.TRANS_QUAD
		).set_ease(
			Tween.EASE_OUT
		)

	else:
		if exit_button_tween != null:
			exit_button_tween.kill()

		exit_button_tween = create_tween()

		exit_button_tween.tween_property(
			button_group,
			"scale",
			target_scale,
			button_animation_duration
		).set_trans(
			Tween.TRANS_QUAD
		).set_ease(
			Tween.EASE_OUT
		)


func _start_continue_pulse() -> void:
	_kill_continue_tween()

	continue_label.modulate.a = 1.0

	continue_tween = create_tween()
	continue_tween.set_loops()

	continue_tween.tween_property(
		continue_label,
		"modulate:a",
		0.35,
		0.55
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)

	continue_tween.tween_property(
		continue_label,
		"modulate:a",
		1.0,
		0.55
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)


func reset_fail_screen() -> void:
	_kill_all_tweens()
	_reset_visuals()


func _reset_visuals() -> void:
	_stop_fail_audio()

	current_state = FailState.IDLE

	if fail_root == null:
		return

	fail_root.visible = false

	dim_overlay.visible = true
	dim_overlay.color = Color(0, 0, 0, 0)

	dialogue_group.visible = false
	dialogue_group.modulate = Color.WHITE

	dialogue_box.visible = true
	dialogue_label.visible = true
	dialogue_label.visible_ratio = 1.0
	continue_label.visible = false

	result_group.visible = false

	game_over_title.visible = false
	game_over_title.position = result_asset_position
	game_over_title.scale = result_asset_scale
	game_over_title.modulate = Color.WHITE

	reason_label.visible = false
	reason_label.modulate = Color.WHITE

	score_label.visible = false
	score_label.modulate = Color.WHITE

	retry_group.visible = false
	exit_group.visible = false

	retry_group.position = result_asset_position
	exit_group.position = result_asset_position

	retry_group.scale = Vector2.ONE
	exit_group.scale = Vector2.ONE

	retry_sprite.scale = result_asset_scale
	exit_sprite.scale = result_asset_scale

	retry_group.modulate = Color.WHITE
	exit_group.modulate = Color.WHITE

	retry_button.disabled = true
	exit_button.disabled = true

	retry_button.release_focus()
	exit_button.release_focus()


func _kill_all_tweens() -> void:
	_kill_fail_music_tween()

	if active_tween != null:
		active_tween.kill()
		active_tween = null

	if retry_button_tween != null:
		retry_button_tween.kill()
		retry_button_tween = null

	if exit_button_tween != null:
		exit_button_tween.kill()
		exit_button_tween = null

	_kill_continue_tween()


func _kill_continue_tween() -> void:
	if continue_tween != null:
		continue_tween.kill()
		continue_tween = null
