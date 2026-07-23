extends Node2D

signal minigame_finished
signal minigame_failed
signal minigame_retry_requested


enum TensionZoneState {
	BELOW,
	INSIDE,
	ABOVE
}


enum ExtremeTensionState {
	NORMAL,
	TOO_LOW,
	TOO_HIGH
}


const ENDING_SCENE: PackedScene = preload(
	"res://features/minigames/ending_sequence/scenes/collectible_ending_scene.tscn"
)

const ENDING_COLLECTIBLE: Texture2D = preload(
	"res://features/minigames/ending_sequence/assets/collectibles/collectible_miki_noodles_bag.png"
)

const FAIL_SCREEN_SCENE: PackedScene = preload(
	"res://features/minigames/fail_screen/scenes/minigame_fail_screen.tscn"
)

const INTRODUCTION_SCENE: PackedScene = preload(
	"res://features/minigames/introduction/scenes/minigame_introduction.tscn"
)

const SHARED_FONT_PATH: String = (
	"res://features/minigames/shared/fonts/VCR_OSD_MONO_1.001.ttf"
)


# Reuse the exact cursor artwork from Box Unboxing.
const CURSOR_NORMAL_PATH: String = (
	"res://features/minigames/box_unboxing/assets/ui/cursor_normal.png"
)

const CURSOR_GRAB_PATH: String = (
	"res://features/minigames/box_unboxing/assets/ui/cursor_grab.png"
)

const CURSOR_DRAGGING_PATH: String = (
	"res://features/minigames/box_unboxing/assets/ui/cursor_dragging.png"
)


# =========================================================
# POLISH ASSET PATHS
# =========================================================

const TIMER_FRAME_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/ui/"
	+ "timer_frame_canvas.png"
)

const TIMER_WARNING_ICON_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/ui/"
	+ "timer_warning_icon.png"
)

const NOODLE_DROP_SHADOW_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/effects/"
	+ "noodle_drop_shadow.png"
)

const FLOUR_PUFF_01_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/effects/"
	+ "flour_puff_01.png"
)

const FLOUR_PUFF_02_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/effects/"
	+ "flour_puff_02.png"
)

const FLOUR_PUFF_03_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/effects/"
	+ "flour_puff_03.png"
)


const NOODLE_COMPLETE_SPARKLE_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/effects/"
	+ "noodle_complete_sparkle.png"
)


const MUSIC_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/music/"
	+ "bgm_miki_crank_loop.ogg"
)

const AMBIENCE_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/ambience/"
	+ "amb_market_machine_loop.ogg"
)

const CRANK_01_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/sfx/"
	+ "sfx_crank_turn_01.wav"
)

const CRANK_02_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/sfx/"
	+ "sfx_crank_turn_02.wav"
)

const CRANK_03_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/sfx/"
	+ "sfx_crank_turn_03.wav"
)

const MACHINE_WOOD_CREAK_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/sfx/"
	+ "sfx_machine_wood_creak.wav"
)

const MACHINE_GEAR_CLICK_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/sfx/"
	+ "sfx_machine_gear_click.wav"
)

const MACHINE_TENSION_HIGH_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/sfx/"
	+ "sfx_machine_tension_high.wav"
)

const MACHINE_TENSION_LOW_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/sfx/"
	+ "sfx_machine_tension_low.wav"
)

const SWEET_SPOT_ENTER_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/sfx/"
	+ "sfx_sweet_spot_enter.wav"
)

const SWEET_SPOT_EXIT_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/sfx/"
	+ "sfx_sweet_spot_exit.wav"
)

const TENSION_TOO_HIGH_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/sfx/"
	+ "sfx_tension_too_high.wav"
)

const TENSION_TOO_LOW_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/sfx/"
	+ "sfx_tension_too_low.wav"
)

const PROGRESS_GAIN_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/sfx/"
	+ "sfx_progress_gain.wav"
)

const PROGRESS_COMPLETE_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/sfx/"
	+ "sfx_progress_complete.wav"
)

const NOODLES_EXTRUDE_LOOP_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/sfx/"
	+ "sfx_noodles_extrude_loop.ogg"
)

const NOODLES_DROP_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/sfx/"
	+ "sfx_noodles_drop.wav"
)

const TIMER_WARNING_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/sfx/"
	+ "sfx_timer_warning.wav"
)

const SUCCESS_TRANSITION_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/sfx/"
	+ "sfx_success_transition.wav"
)

const FAILURE_TRANSITION_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/sfx/"
	+ "sfx_failure_transition.wav"
)

const UI_HOVER_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/ui/"
	+ "sfx_ui_hover.wav"
)

const UI_CLICK_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/ui/"
	+ "sfx_ui_click.wav"
)

const COUNTDOWN_READY_PATH: String = (
	"res://features/minigames/miki_noodle_crank/assets/audio/ui/"
	+ "sfx_countdown_ready.wav"
)


# =========================================================
# REQUIRED EXISTING SCENE NODES
# =========================================================

@onready var crank_pivot: Node2D = $CrankPivot
@onready var needle: Sprite2D = $Needle
@onready var sweet_spot_zone: Sprite2D = $SweetSpotZone
@onready var progress_bar_fill: Sprite2D = $ProgressBarFill
@onready var noodles_output: Sprite2D = $NoodlesOutput


# =========================================================
# GAMEPLAY SETTINGS
# =========================================================

@export_category("Crank")

@export var tension_decay: float = 0.35
@export var crank_boost: float = 0.13
@export var crank_rotation_amount: float = 35.0
@export var crank_rotation_time: float = 0.10

@export_range(0.0, 1.0, 0.01)
var gear_click_chance: float = 0.36

@export_range(0.0, 1.0, 0.01)
var wood_creak_chance: float = 0.12

@export_range(0.0, 1.0, 0.01)
var flour_puff_chance: float = 0.22


@export_category("Needle")

@export var needle_top_y: float = 150.0
@export var needle_bottom_y: float = 500.0

@export_range(0.0, 1.0, 0.01)
var extreme_low_threshold: float = 0.08

@export_range(0.0, 1.0, 0.01)
var extreme_high_threshold: float = 0.92


@export_category("Sweet Spot")

@export var sweet_change_interval_min: float = 0.35
@export var sweet_change_interval_max: float = 0.75
@export var sweet_move_lerp_speed: float = 10.0
@export var sweet_center_min: float = 0.22
@export var sweet_center_max: float = 0.78
@export var sweet_min_size: float = 0.12
@export var sweet_max_size: float = 0.34
@export var sweet_min_scale_y: float = 0.14
@export var sweet_max_scale_y: float = 0.50

@export var tension_state_sound_cooldown: float = 0.22


@export_category("Progress")

@export var progress_speed: float = 0.07
@export var progress_decay: float = 0.0

# Progress gain sound plays at these intervals instead of every frame.
@export_range(0.02, 0.50, 0.01)
var progress_sound_step: float = 0.10


@export_category("Noodles")

@export var noodles_start_y: float = 250.0
@export var noodles_end_y: float = 620.0

@export var noodle_shadow_offset: Vector2 = Vector2(
	0.0,
	38.0
)

@export var noodle_shadow_scale: Vector2 = Vector2(
	0.72,
	0.72
)

@export var flour_puff_offset: Vector2 = Vector2(
	0.0,
	16.0
)

@export var flour_puff_scale: Vector2 = Vector2(
	0.58,
	0.58
)

@export var noodle_sparkle_offset: Vector2 = Vector2(
	0.0,
	-36.0
)

@export var noodle_sparkle_scale: Vector2 = Vector2(
	0.56,
	0.56
)


@export_category("Time Limit")

@export var time_limit_seconds: float = 60.0
@export var timer_warning_seconds: float = 15.0

# These positions use the 1920 x 1080 reference canvas.
# Change only these two values if the text/icon needs to move
# inside your finished timer_frame_canvas.png.
@export var timer_text_position_reference: Vector2 = Vector2(
	1720.0,
	150.0
)

@export var timer_text_size_reference: Vector2 = Vector2(
	250.0,
	86.0
)

@export var warning_icon_position_reference: Vector2 = Vector2(
	1515.0,
	115.0
)

# Matches the Box Unboxing timer style at 1152 x 648.
@export var hud_font_size: int = 34

@export var timer_warning_icon_scale: Vector2 = Vector2(
	0.58,
	0.58
)

@export var timer_normal_color: Color = Color("f8e5b9")
@export var timer_warning_color: Color = Color("ff786b")


@export_category("Cursor")

# The Miki minigame accepts left-click anywhere as a crank input,
# so the grab cursor is shown throughout active gameplay.
@export var cursor_display_size: Vector2i = Vector2i(64, 64)
@export var cursor_normal_hotspot: Vector2 = Vector2(3, 3)
@export var cursor_grab_hotspot: Vector2 = Vector2(32, 27)
@export var cursor_dragging_hotspot: Vector2 = Vector2(32, 29)


@export_category("Audio")

@export var music_volume_db: float = -14.0
@export var ambience_volume_db: float = -27.0
@export var sfx_volume_db: float = -7.0
@export var ui_volume_db: float = -10.0
@export var extrusion_volume_db: float = -24.0
@export var audio_fade_time: float = 0.65


@export_category("Visual Effects")

@export var effect_layer_z_index: int = 90
@export var hud_canvas_layer: int = 40

@export var reference_canvas_size: Vector2 = Vector2(
	1920.0,
	1080.0
)

@export var completion_effect_duration: float = 0.78


@export_category("Ending Sequence")

@export var ending_collectible_scale: Vector2 = Vector2(
	0.6,
	0.6
)

# Keep these disabled in a release build.
@export var ending_test_key_enabled: bool = false
@export var fail_test_key_enabled: bool = false


# =========================================================
# GAMEPLAY STATE
# =========================================================

var tension: float = 0.5
var progress: float = 0.0
var time_remaining: float = 60.0

var gameplay_started: bool = false
var introduction_started: bool = false

var game_finished: bool = false
var ending_started: bool = false
var fail_screen_started: bool = false
var result_emitted: bool = false

var shared_font: Font = null

var sweet_center: float = 0.5
var sweet_size: float = 0.25
var sweet_target_center: float = 0.5
var sweet_target_size: float = 0.25
var sweet_change_timer: float = 0.0

var previous_tension_state: TensionZoneState = (
	TensionZoneState.BELOW
)

var previous_extreme_state: ExtremeTensionState = (
	ExtremeTensionState.NORMAL
)

var tension_state_sound_timer: float = 0.0
var next_progress_sound_at: float = 0.10
var timer_warning_triggered: bool = false


# =========================================================
# SHARED SCENES
# =========================================================

var ending_sequence: Node = null
var fail_screen: Node = null
var introduction: Node = null


# =========================================================
# DYNAMIC HUD / EFFECT NODES
# =========================================================

var hud_layer: CanvasLayer = null
var timer_frame: Sprite2D = null
var timer_label: Label = null
var timer_warning_icon: Sprite2D = null

var world_effects_root: Node2D = null
var noodle_shadow: Sprite2D = null
var flour_puff: Sprite2D = null
var noodle_complete_sparkle: Sprite2D = null


var flour_puff_textures: Array[Texture2D] = []

var crank_rotation_tween: Tween = null
var warning_pulse_tween: Tween = null
var flour_puff_tween: Tween = null
var flour_puff_animation_id: int = 0
var completion_tween: Tween = null
var audio_fade_tween: Tween = null


# =========================================================
# CUSTOM CURSORS
# =========================================================

var cursor_normal_texture: Texture2D = null
var cursor_grab_texture: Texture2D = null
var cursor_dragging_texture: Texture2D = null
var mouse_crank_held: bool = false


# =========================================================
# AUDIO NODES / STREAMS
# =========================================================

var audio_root: Node = null
var music_player: AudioStreamPlayer = null
var ambience_player: AudioStreamPlayer = null
var extrusion_player: AudioStreamPlayer = null
var one_shot_players: Array[AudioStreamPlayer] = []
var next_one_shot_player_index: int = 0

var music_stream: AudioStream = null
var ambience_stream: AudioStream = null
var extrusion_stream: AudioStream = null

var crank_streams: Array[AudioStream] = []
var stream_machine_wood_creak: AudioStream = null
var stream_machine_gear_click: AudioStream = null
var stream_machine_tension_high: AudioStream = null
var stream_machine_tension_low: AudioStream = null
var stream_sweet_spot_enter: AudioStream = null
var stream_sweet_spot_exit: AudioStream = null
var stream_tension_too_high: AudioStream = null
var stream_tension_too_low: AudioStream = null
var stream_progress_gain: AudioStream = null
var stream_progress_complete: AudioStream = null
var stream_noodles_drop: AudioStream = null
var stream_timer_warning: AudioStream = null
var stream_success_transition: AudioStream = null
var stream_failure_transition: AudioStream = null
var stream_ui_hover: AudioStream = null
var stream_ui_click: AudioStream = null
var stream_countdown_ready: AudioStream = null


# =========================================================
# READY / PROCESS / INPUT
# =========================================================

func _ready() -> void:
	randomize()

	gameplay_started = false
	introduction_started = false
	result_emitted = false

	_load_shared_font()
	_setup_polish_nodes()
	_load_polish_assets()
	_setup_custom_cursors()
	_setup_audio_nodes()
	_load_audio_assets()

	_ensure_ending_sequence()
	_connect_ending_sequence()

	_ensure_fail_screen()
	_connect_fail_screen()

	_ensure_introduction()
	_connect_introduction()

	_reset_miki_gameplay_values()
	_set_cursor_normal()

	print("")
	print("========================================")
	print("POLISHED MIKI NOODLE CRANK READY")
	print("========================================")
	print("Introduction found: ", introduction != null)
	print("Ending node found: ", ending_sequence != null)
	print("Fail screen found: ", fail_screen != null)
	print("Time limit: ", time_limit_seconds, " seconds")
	print("Timer frame loaded: ", timer_frame.texture != null)
	print("Flour puff textures: ", flour_puff_textures.size())
	print("Crank sound variations: ", crank_streams.size())
	print("========================================")
	print("")

	_start_miki_introduction()


func _process(delta: float) -> void:
	if tension_state_sound_timer > 0.0:
		tension_state_sound_timer = maxf(
			tension_state_sound_timer - delta,
			0.0
		)

	if not gameplay_started:
		return

	if _gameplay_has_stopped():
		return

	time_remaining -= delta
	time_remaining = maxf(time_remaining, 0.0)

	tension -= tension_decay * delta
	tension = clampf(tension, 0.0, 1.0)

	update_sweet_spot(delta)
	update_progress(delta)
	update_needle()
	update_progress_bar()
	update_noodles()
	_update_timer_ui()
	_update_tension_audio_state()
	_update_extreme_tension_audio_state()
	_update_extrusion_loop()

	# Success has priority when both happen on the same frame.
	if progress >= 1.0:
		win_minigame()
		return

	if time_remaining <= 0.0:
		_start_time_limit_failure()


func _input(event: InputEvent) -> void:
	# Keep the mouse cursor state responsive even when a left-click
	# has just ended.
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = (
			event as InputEventMouseButton
		)

		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			mouse_crank_held = mouse_event.pressed

			if (
				gameplay_started
				and not _gameplay_has_stopped()
			):
				if mouse_crank_held:
					_set_cursor_dragging()
				else:
					_set_cursor_grab()
			else:
				_set_cursor_normal()

	if not gameplay_started:
		return

	if event is InputEventKey:
		if (
			ending_test_key_enabled
			and event.keycode == KEY_T
			and event.pressed
			and not event.echo
		):
			if not _gameplay_has_stopped():
				win_minigame()
				get_viewport().set_input_as_handled()
			return

		if (
			fail_test_key_enabled
			and event.keycode == KEY_F
			and event.pressed
			and not event.echo
		):
			if not _gameplay_has_stopped():
				_start_time_limit_failure()
				get_viewport().set_input_as_handled()
			return

	if _gameplay_has_stopped():
		return

	if event.is_action_pressed("crank"):
		crank()
		get_viewport().set_input_as_handled()


func _gameplay_has_stopped() -> bool:
	return (
		not gameplay_started
		or game_finished
		or ending_started
		or fail_screen_started
	)


# =========================================================
# GAMEPLAY
# =========================================================

func crank() -> void:
	if _gameplay_has_stopped():
		return

	tension += crank_boost
	tension = clampf(tension, 0.0, 1.0)

	_animate_crank_rotation()
	_play_random_crank_sound()

	if randf() <= gear_click_chance:
		_play_one_shot(
			stream_machine_gear_click,
			sfx_volume_db - 3.0,
			randf_range(0.97, 1.04)
		)

	if randf() <= wood_creak_chance:
		_play_one_shot(
			stream_machine_wood_creak,
			sfx_volume_db - 5.0,
			randf_range(0.94, 1.04)
		)

	if randf() <= flour_puff_chance:
		_play_flour_puff()


func _animate_crank_rotation() -> void:
	if crank_rotation_tween != null:
		crank_rotation_tween.kill()
		crank_rotation_tween = null

	var target_rotation: float = (
		crank_pivot.rotation_degrees
		+ crank_rotation_amount
	)

	crank_rotation_tween = create_tween()
	crank_rotation_tween.tween_property(
		crank_pivot,
		"rotation_degrees",
		target_rotation,
		crank_rotation_time
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


func update_needle() -> void:
	needle.position.y = lerpf(
		needle_bottom_y,
		needle_top_y,
		tension
	)


func update_sweet_spot(delta: float) -> void:
	sweet_change_timer -= delta

	if sweet_change_timer <= 0.0:
		pick_new_sweet_spot_target()

	var lerp_weight: float = clampf(
		sweet_move_lerp_speed * delta,
		0.0,
		1.0
	)

	sweet_center = lerpf(
		sweet_center,
		sweet_target_center,
		lerp_weight
	)

	sweet_size = lerpf(
		sweet_size,
		sweet_target_size,
		lerp_weight
	)

	var size_percent: float = inverse_lerp(
		sweet_min_size,
		sweet_max_size,
		sweet_size
	)

	var scale_y: float = lerpf(
		sweet_min_scale_y,
		sweet_max_scale_y,
		size_percent
	)

	sweet_spot_zone.position.y = lerpf(
		needle_bottom_y,
		needle_top_y,
		sweet_center
	)

	sweet_spot_zone.scale.y = scale_y


func pick_new_sweet_spot_target() -> void:
	sweet_target_center = randf_range(
		sweet_center_min,
		sweet_center_max
	)

	sweet_target_size = randf_range(
		sweet_min_size,
		sweet_max_size
	)

	sweet_change_timer = randf_range(
		sweet_change_interval_min,
		sweet_change_interval_max
	)


func update_progress(delta: float) -> void:
	var previous_progress: float = progress

	if is_tension_in_sweet_spot():
		progress += progress_speed * delta
	else:
		progress -= progress_decay * delta

	progress = clampf(progress, 0.0, 1.0)

	if progress > previous_progress:
		while progress >= next_progress_sound_at:
			_play_one_shot(
				stream_progress_gain,
				sfx_volume_db - 8.0,
				randf_range(0.98, 1.05)
			)

			next_progress_sound_at += progress_sound_step


func update_progress_bar() -> void:
	var material: ShaderMaterial = (
		progress_bar_fill.material as ShaderMaterial
	)

	if material != null:
		material.set_shader_parameter(
			"progress",
			progress
		)


func update_noodles() -> void:
	noodles_output.position.y = lerpf(
		noodles_start_y,
		noodles_end_y,
		progress
	)

	if noodle_shadow != null:
		var shadow_position: Vector2 = Vector2(
			noodles_output.global_position.x
			+ noodle_shadow_offset.x,
			noodles_end_y
			+ noodle_shadow_offset.y
		)

		noodle_shadow.global_position = shadow_position

		noodle_shadow.modulate.a = lerpf(
			0.10,
			0.68,
			progress
		)


func is_tension_in_sweet_spot() -> bool:
	return _get_tension_zone_state() == TensionZoneState.INSIDE


func _get_tension_zone_state() -> TensionZoneState:
	var sweet_minimum: float = (
		sweet_center
		- sweet_size * 0.5
	)

	var sweet_maximum: float = (
		sweet_center
		+ sweet_size * 0.5
	)

	if tension < sweet_minimum:
		return TensionZoneState.BELOW

	if tension > sweet_maximum:
		return TensionZoneState.ABOVE

	return TensionZoneState.INSIDE


func _get_extreme_tension_state() -> ExtremeTensionState:
	if tension <= extreme_low_threshold:
		return ExtremeTensionState.TOO_LOW

	if tension >= extreme_high_threshold:
		return ExtremeTensionState.TOO_HIGH

	return ExtremeTensionState.NORMAL


# =========================================================
# TENSION / EXTRUSION AUDIO STATE
# =========================================================

func _update_tension_audio_state() -> void:
	var new_state: TensionZoneState = (
		_get_tension_zone_state()
	)

	if new_state == previous_tension_state:
		return

	if tension_state_sound_timer > 0.0:
		previous_tension_state = new_state
		return

	if new_state == TensionZoneState.INSIDE:
		_play_one_shot(
			stream_sweet_spot_enter,
			sfx_volume_db - 2.0,
			1.0
		)
	else:
		if previous_tension_state == TensionZoneState.INSIDE:
			_play_one_shot(
				stream_sweet_spot_exit,
				sfx_volume_db - 5.0,
				1.0
			)

			if new_state == TensionZoneState.ABOVE:
				_play_one_shot(
					stream_tension_too_high,
					sfx_volume_db - 4.0,
					1.0
				)
			else:
				_play_one_shot(
					stream_tension_too_low,
					sfx_volume_db - 4.0,
					1.0
				)

	previous_tension_state = new_state
	tension_state_sound_timer = tension_state_sound_cooldown


func _update_extreme_tension_audio_state() -> void:
	var new_state: ExtremeTensionState = (
		_get_extreme_tension_state()
	)

	if new_state == previous_extreme_state:
		return

	if new_state == ExtremeTensionState.TOO_LOW:
		_play_one_shot(
			stream_machine_tension_low,
			sfx_volume_db - 3.0,
			1.0
		)
	elif new_state == ExtremeTensionState.TOO_HIGH:
		_play_one_shot(
			stream_machine_tension_high,
			sfx_volume_db - 3.0,
			1.0
		)

	previous_extreme_state = new_state


func _update_extrusion_loop() -> void:
	if extrusion_player == null:
		return

	var should_play: bool = (
		gameplay_started
		and not _gameplay_has_stopped()
		and is_tension_in_sweet_spot()
	)

	if should_play:
		if not extrusion_player.playing:
			extrusion_player.play()
	else:
		if extrusion_player.playing:
			extrusion_player.stop()


# =========================================================
# TIMER UI
# =========================================================

func _load_shared_font() -> void:
	if not ResourceLoader.exists(SHARED_FONT_PATH):
		push_warning(
			"MIKI POLISH: Missing shared font: "
			+ SHARED_FONT_PATH
		)
		shared_font = null
		return

	shared_font = load(SHARED_FONT_PATH) as Font


func _setup_polish_nodes() -> void:
	_setup_hud_nodes()
	_setup_world_effect_nodes()


func _setup_hud_nodes() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "PolishHUD"
	hud_layer.layer = hud_canvas_layer
	add_child(hud_layer)

	timer_frame = Sprite2D.new()
	timer_frame.name = "TimerFrame"
	timer_frame.centered = true
	timer_frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	timer_frame.z_index = 0
	hud_layer.add_child(timer_frame)

	timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	timer_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)
	timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_label.z_index = 5

	if shared_font != null:
		timer_label.add_theme_font_override(
			"font",
			shared_font
		)

	timer_label.add_theme_color_override(
		"font_color",
		timer_normal_color
	)
	timer_label.add_theme_color_override(
		"font_shadow_color",
		Color(0.08, 0.04, 0.02, 0.95)
	)
	timer_label.add_theme_constant_override(
		"shadow_offset_x",
		3
	)
	timer_label.add_theme_constant_override(
		"shadow_offset_y",
		3
	)
	hud_layer.add_child(timer_label)

	timer_warning_icon = Sprite2D.new()
	timer_warning_icon.name = "TimerWarningIcon"
	timer_warning_icon.centered = true
	timer_warning_icon.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)
	timer_warning_icon.scale = timer_warning_icon_scale
	timer_warning_icon.visible = false
	timer_warning_icon.z_index = 6
	hud_layer.add_child(timer_warning_icon)

	_apply_hud_layout()
	hud_layer.visible = false


func _apply_hud_layout() -> void:
	if hud_layer == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var canvas_scale: Vector2 = Vector2(
		viewport_size.x / reference_canvas_size.x,
		viewport_size.y / reference_canvas_size.y
	)

	timer_frame.position = viewport_size * 0.5
	timer_frame.scale = canvas_scale

	var timer_display_position: Vector2 = Vector2(
		timer_text_position_reference.x * canvas_scale.x,
		timer_text_position_reference.y * canvas_scale.y
	)

	var timer_display_size: Vector2 = Vector2(
		timer_text_size_reference.x * canvas_scale.x,
		timer_text_size_reference.y * canvas_scale.y
	)

	timer_label.position = (
		timer_display_position
		- timer_display_size * 0.5
	)
	timer_label.size = timer_display_size

	var screen_scale: float = (
		viewport_size.y / 648.0
	)

	var scaled_font_size: int = maxi(
		16,
		int(round(
			float(hud_font_size)
			* screen_scale
		))
	)

	timer_label.add_theme_font_size_override(
		"font_size",
		scaled_font_size
	)

	timer_warning_icon.position = Vector2(
		warning_icon_position_reference.x * canvas_scale.x,
		warning_icon_position_reference.y * canvas_scale.y
	)


func _update_timer_ui() -> void:
	if timer_label == null:
		return

	var seconds_total: int = maxi(
		0,
		int(ceil(time_remaining))
	)

	var minutes: int = seconds_total / 60
	var seconds: int = seconds_total % 60

	timer_label.text = "%02d:%02d" % [
		minutes,
		seconds
	]

	if (
		not timer_warning_triggered
		and time_remaining <= timer_warning_seconds
		and time_remaining > 0.0
	):
		_start_timer_warning()


func _start_timer_warning() -> void:
	timer_warning_triggered = true

	timer_label.add_theme_color_override(
		"font_color",
		timer_warning_color
	)

	timer_warning_icon.visible = true
	timer_warning_icon.modulate = Color.WHITE

	_play_one_shot(
		stream_timer_warning,
		sfx_volume_db - 1.0,
		1.0
	)

	if warning_pulse_tween != null:
		warning_pulse_tween.kill()
		warning_pulse_tween = null

	warning_pulse_tween = create_tween()
	warning_pulse_tween.set_loops()
	warning_pulse_tween.tween_property(
		timer_warning_icon,
		"scale",
		timer_warning_icon_scale * 1.16,
		0.30
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)
	warning_pulse_tween.tween_property(
		timer_warning_icon,
		"scale",
		timer_warning_icon_scale,
		0.30
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)


func _reset_timer_ui() -> void:
	timer_warning_triggered = false

	if timer_label != null:
		timer_label.add_theme_color_override(
			"font_color",
			timer_normal_color
		)

	if timer_warning_icon != null:
		timer_warning_icon.visible = false
		timer_warning_icon.scale = timer_warning_icon_scale
		timer_warning_icon.modulate = Color.WHITE

	if warning_pulse_tween != null:
		warning_pulse_tween.kill()
		warning_pulse_tween = null

	_update_timer_ui()


func _freeze_timer_hud() -> void:
	# The timer remains visible at the exact value reached
	# when the minigame ends. Only the warning animation stops.
	_update_timer_ui()

	if warning_pulse_tween != null:
		warning_pulse_tween.kill()
		warning_pulse_tween = null

	if timer_warning_icon != null:
		timer_warning_icon.scale = timer_warning_icon_scale

	if hud_layer != null:
		hud_layer.visible = true


# =========================================================
# WORLD EFFECTS
# =========================================================

func _setup_world_effect_nodes() -> void:
	world_effects_root = Node2D.new()
	world_effects_root.name = "PolishWorldEffects"
	world_effects_root.z_index = 0
	add_child(world_effects_root)

	noodle_shadow = Sprite2D.new()
	noodle_shadow.name = "NoodleDropShadow"
	noodle_shadow.centered = true
	noodle_shadow.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)
	noodle_shadow.scale = noodle_shadow_scale
	noodle_shadow.modulate.a = 0.10
	noodle_shadow.z_index = noodles_output.z_index - 1
	world_effects_root.add_child(noodle_shadow)

	flour_puff = Sprite2D.new()
	flour_puff.name = "FlourPuff"
	flour_puff.centered = true
	flour_puff.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)
	flour_puff.scale = flour_puff_scale
	flour_puff.visible = false
	flour_puff.z_index = effect_layer_z_index
	world_effects_root.add_child(flour_puff)

	noodle_complete_sparkle = Sprite2D.new()
	noodle_complete_sparkle.name = "NoodleCompleteSparkle"
	noodle_complete_sparkle.centered = true
	noodle_complete_sparkle.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)
	noodle_complete_sparkle.scale = noodle_sparkle_scale
	noodle_complete_sparkle.visible = false
	noodle_complete_sparkle.z_index = effect_layer_z_index + 1
	world_effects_root.add_child(noodle_complete_sparkle)


func _play_flour_puff() -> void:
	if flour_puff == null:
		return

	flour_puff_animation_id += 1
	var this_animation_id: int = flour_puff_animation_id

	if flour_puff_textures.is_empty():
		return

	if flour_puff_tween != null:
		flour_puff_tween.kill()
		flour_puff_tween = null

	flour_puff.texture = flour_puff_textures.pick_random()
	flour_puff.global_position = (
		noodles_output.global_position
		+ flour_puff_offset
	)
	flour_puff.rotation = randf_range(-0.14, 0.14)
	flour_puff.scale = flour_puff_scale * 0.70
	flour_puff.modulate = Color(1, 1, 1, 0)
	flour_puff.visible = true

	var travel_offset: Vector2 = Vector2(
		randf_range(-16.0, 16.0),
		randf_range(-28.0, -18.0)
	)

	flour_puff_tween = create_tween()
	flour_puff_tween.set_parallel(true)
	flour_puff_tween.tween_property(
		flour_puff,
		"global_position",
		flour_puff.global_position + travel_offset,
		0.46
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)
	flour_puff_tween.tween_property(
		flour_puff,
		"scale",
		flour_puff_scale,
		0.24
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)
	flour_puff_tween.tween_property(
		flour_puff,
		"modulate:a",
		1.0,
		0.12
	)

	await get_tree().create_timer(0.20, false).timeout

	if flour_puff == null:
		return

	if this_animation_id != flour_puff_animation_id:
		return

	var fade_tween: Tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(
		flour_puff,
		"modulate:a",
		0.0,
		0.26
	)
	fade_tween.tween_property(
		flour_puff,
		"scale",
		flour_puff_scale * 1.12,
		0.26
	)

	await fade_tween.finished

	if this_animation_id != flour_puff_animation_id:
		return

	if flour_puff != null:
		flour_puff.visible = false


func _play_completion_effects() -> void:
	_stop_extrusion_loop()

	_play_one_shot(
		stream_progress_complete,
		sfx_volume_db,
		1.0
	)
	_play_one_shot(
		stream_noodles_drop,
		sfx_volume_db - 1.0,
		1.0
	)
	_play_one_shot(
		stream_success_transition,
		sfx_volume_db - 2.0,
		1.0
	)

	if noodle_complete_sparkle == null:
		await get_tree().create_timer(
			completion_effect_duration,
			false,
		).timeout
		return

	noodle_complete_sparkle.global_position = (
		noodles_output.global_position
		+ noodle_sparkle_offset
	)
	noodle_complete_sparkle.scale = (
		noodle_sparkle_scale * 0.55
	)
	noodle_complete_sparkle.modulate = Color(
		1,
		1,
		1,
		0
	)
	noodle_complete_sparkle.visible = true

	if completion_tween != null:
		completion_tween.kill()
		completion_tween = null

	completion_tween = create_tween()
	completion_tween.set_parallel(true)
	completion_tween.tween_property(
		noodle_complete_sparkle,
		"scale",
		noodle_sparkle_scale,
		0.30
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)
	completion_tween.tween_property(
		noodle_complete_sparkle,
		"modulate:a",
		1.0,
		0.14
	)

	await get_tree().create_timer(
		completion_effect_duration,
		false,
	).timeout

	if noodle_complete_sparkle == null:
		return

	var sparkle_fade: Tween = create_tween()
	sparkle_fade.set_parallel(true)
	sparkle_fade.tween_property(
		noodle_complete_sparkle,
		"modulate:a",
		0.0,
		0.24
	)
	sparkle_fade.tween_property(
		noodle_complete_sparkle,
		"scale",
		noodle_sparkle_scale * 1.16,
		0.24
	)

	await sparkle_fade.finished

	if noodle_complete_sparkle != null:
		noodle_complete_sparkle.visible = false


func _reset_effects() -> void:
	flour_puff_animation_id += 1

	if flour_puff_tween != null:
		flour_puff_tween.kill()
		flour_puff_tween = null

	if noodle_shadow != null:
		noodle_shadow.visible = true
		noodle_shadow.scale = noodle_shadow_scale
		noodle_shadow.modulate.a = 0.10

	if flour_puff != null:
		flour_puff.visible = false
		flour_puff.modulate = Color.WHITE
		flour_puff.scale = flour_puff_scale

	if noodle_complete_sparkle != null:
		noodle_complete_sparkle.visible = false
		noodle_complete_sparkle.modulate = Color.WHITE
		noodle_complete_sparkle.scale = noodle_sparkle_scale



# =========================================================
# ASSET LOADING
# =========================================================

func _load_polish_assets() -> void:
	timer_frame.texture = _load_texture(TIMER_FRAME_PATH)
	timer_warning_icon.texture = _load_texture(
		TIMER_WARNING_ICON_PATH
	)

	noodle_shadow.texture = _load_texture(
		NOODLE_DROP_SHADOW_PATH
	)

	flour_puff_textures.clear()

	for path in [
		FLOUR_PUFF_01_PATH,
		FLOUR_PUFF_02_PATH,
		FLOUR_PUFF_03_PATH
	]:
		var texture: Texture2D = _load_texture(path)
		if texture != null:
			flour_puff_textures.append(texture)


	noodle_complete_sparkle.texture = _load_texture(
		NOODLE_COMPLETE_SPARKLE_PATH
	)


func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		push_warning(
			"MIKI POLISH: Missing texture: "
			+ path
		)
		return null

	var texture: Texture2D = load(path) as Texture2D

	if texture == null:
		push_warning(
			"MIKI POLISH: Could not load texture: "
			+ path
		)

	return texture


# =========================================================
# CUSTOM CURSORS
# =========================================================

func _setup_custom_cursors() -> void:
	cursor_normal_texture = _load_resized_cursor(
		CURSOR_NORMAL_PATH,
		cursor_display_size
	)
	cursor_grab_texture = _load_resized_cursor(
		CURSOR_GRAB_PATH,
		cursor_display_size
	)
	cursor_dragging_texture = _load_resized_cursor(
		CURSOR_DRAGGING_PATH,
		cursor_display_size
	)


func _load_resized_cursor(
	path: String,
	target_size: Vector2i
) -> Texture2D:
	if not ResourceLoader.exists(path):
		push_warning(
			"MIKI CURSOR: Missing cursor texture: "
			+ path
		)
		return null

	var source_texture: Texture2D = load(path) as Texture2D

	if source_texture == null:
		return null

	var image: Image = source_texture.get_image()

	if image == null:
		return source_texture

	image.resize(
		target_size.x,
		target_size.y,
		Image.INTERPOLATE_NEAREST
	)

	return ImageTexture.create_from_image(image)


func _set_cursor_normal() -> void:
	mouse_crank_held = false

	if cursor_normal_texture != null:
		Input.set_custom_mouse_cursor(
			cursor_normal_texture,
			Input.CURSOR_ARROW,
			cursor_normal_hotspot
		)


func _set_cursor_grab() -> void:
	if cursor_grab_texture != null:
		Input.set_custom_mouse_cursor(
			cursor_grab_texture,
			Input.CURSOR_ARROW,
			cursor_grab_hotspot
		)


func _set_cursor_dragging() -> void:
	if cursor_dragging_texture != null:
		Input.set_custom_mouse_cursor(
			cursor_dragging_texture,
			Input.CURSOR_ARROW,
			cursor_dragging_hotspot
		)


# =========================================================
# AUDIO SETUP / LOADING / PLAYBACK
# =========================================================

func _setup_audio_nodes() -> void:
	audio_root = Node.new()
	audio_root.name = "PolishAudio"
	add_child(audio_root)

	music_player = _create_audio_player(
		"MusicPlayer",
		"Master"
	)

	ambience_player = _create_audio_player(
		"AmbiencePlayer",
		"Ambience"
	)

	extrusion_player = _create_audio_player(
		"NoodleExtrusionPlayer",
		"SFX"
	)

	for index in range(8):
		var player: AudioStreamPlayer = _create_audio_player(
			"OneShotPlayer%02d" % index,
			"SFX"
		)
		one_shot_players.append(player)


func _create_audio_player(
	player_name: String,
	preferred_bus: String
) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.name = player_name
	player.process_mode = Node.PROCESS_MODE_ALWAYS

	if AudioServer.get_bus_index(preferred_bus) >= 0:
		player.bus = preferred_bus
	else:
		player.bus = "Master"

	audio_root.add_child(player)
	return player


func _load_audio_assets() -> void:
	music_stream = _load_audio_stream(MUSIC_PATH, true)
	ambience_stream = _load_audio_stream(AMBIENCE_PATH, true)
	extrusion_stream = _load_audio_stream(
		NOODLES_EXTRUDE_LOOP_PATH,
		true
	)

	music_player.stream = music_stream
	ambience_player.stream = ambience_stream
	extrusion_player.stream = extrusion_stream

	crank_streams.clear()

	for path in [
		CRANK_01_PATH,
		CRANK_02_PATH,
		CRANK_03_PATH
	]:
		var stream: AudioStream = _load_audio_stream(
			path,
			false
		)
		if stream != null:
			crank_streams.append(stream)

	stream_machine_wood_creak = _load_audio_stream(
		MACHINE_WOOD_CREAK_PATH,
		false
	)
	stream_machine_gear_click = _load_audio_stream(
		MACHINE_GEAR_CLICK_PATH,
		false
	)
	stream_machine_tension_high = _load_audio_stream(
		MACHINE_TENSION_HIGH_PATH,
		false
	)
	stream_machine_tension_low = _load_audio_stream(
		MACHINE_TENSION_LOW_PATH,
		false
	)
	stream_sweet_spot_enter = _load_audio_stream(
		SWEET_SPOT_ENTER_PATH,
		false
	)
	stream_sweet_spot_exit = _load_audio_stream(
		SWEET_SPOT_EXIT_PATH,
		false
	)
	stream_tension_too_high = _load_audio_stream(
		TENSION_TOO_HIGH_PATH,
		false
	)
	stream_tension_too_low = _load_audio_stream(
		TENSION_TOO_LOW_PATH,
		false
	)
	stream_progress_gain = _load_audio_stream(
		PROGRESS_GAIN_PATH,
		false
	)
	stream_progress_complete = _load_audio_stream(
		PROGRESS_COMPLETE_PATH,
		false
	)
	stream_noodles_drop = _load_audio_stream(
		NOODLES_DROP_PATH,
		false
	)
	stream_timer_warning = _load_audio_stream(
		TIMER_WARNING_PATH,
		false
	)
	stream_success_transition = _load_audio_stream(
		SUCCESS_TRANSITION_PATH,
		false
	)
	stream_failure_transition = _load_audio_stream(
		FAILURE_TRANSITION_PATH,
		false
	)
	stream_ui_hover = _load_audio_stream(
		UI_HOVER_PATH,
		false
	)
	stream_ui_click = _load_audio_stream(
		UI_CLICK_PATH,
		false
	)
	stream_countdown_ready = _load_audio_stream(
		COUNTDOWN_READY_PATH,
		false
	)


func _load_audio_stream(
	path: String,
	should_loop: bool
) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning(
			"MIKI POLISH: Missing audio: "
			+ path
		)
		return null

	var stream: AudioStream = load(path) as AudioStream

	if stream == null:
		push_warning(
			"MIKI POLISH: Could not load audio: "
			+ path
		)
		return null

	if should_loop:
		if stream is AudioStreamOggVorbis:
			var ogg_stream: AudioStreamOggVorbis = (
				stream as AudioStreamOggVorbis
			)
			ogg_stream.loop = true
		elif stream is AudioStreamWAV:
			var wav_stream: AudioStreamWAV = (
				stream as AudioStreamWAV
			)
			wav_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

	return stream


func _play_random_crank_sound() -> void:
	if crank_streams.is_empty():
		return

	_play_one_shot(
		crank_streams.pick_random(),
		sfx_volume_db,
		randf_range(0.96, 1.05)
	)


func _play_one_shot(
	stream: AudioStream,
	volume_db: float,
	pitch_scale: float = 1.0
) -> void:
	if stream == null:
		return

	if one_shot_players.is_empty():
		return

	var selected_player: AudioStreamPlayer = null

	for player in one_shot_players:
		if not player.playing:
			selected_player = player
			break

	if selected_player == null:
		selected_player = one_shot_players[
			next_one_shot_player_index
		]
		next_one_shot_player_index = (
			(next_one_shot_player_index + 1)
			% one_shot_players.size()
		)

	selected_player.stop()
	selected_player.stream = stream
	selected_player.volume_db = volume_db
	selected_player.pitch_scale = pitch_scale
	selected_player.play()


func _start_gameplay_audio() -> void:
	_stop_gameplay_audio_immediately()

	if music_player != null and music_stream != null:
		music_player.stream = music_stream
		music_player.volume_db = -60.0
		music_player.play()

	if ambience_player != null and ambience_stream != null:
		ambience_player.stream = ambience_stream
		ambience_player.volume_db = -60.0
		ambience_player.play()

	if audio_fade_tween != null:
		audio_fade_tween.kill()
		audio_fade_tween = null

	audio_fade_tween = create_tween()
	audio_fade_tween.set_parallel(true)

	if music_player != null and music_player.playing:
		audio_fade_tween.tween_property(
			music_player,
			"volume_db",
			music_volume_db,
			audio_fade_time
		)

	if ambience_player != null and ambience_player.playing:
		audio_fade_tween.tween_property(
			ambience_player,
			"volume_db",
			ambience_volume_db,
			audio_fade_time
		)


func _fade_out_gameplay_audio() -> void:
	_stop_extrusion_loop()

	if audio_fade_tween != null:
		audio_fade_tween.kill()
		audio_fade_tween = null

	audio_fade_tween = create_tween()
	audio_fade_tween.set_parallel(true)

	if music_player != null and music_player.playing:
		audio_fade_tween.tween_property(
			music_player,
			"volume_db",
			-60.0,
			audio_fade_time
		)

	if ambience_player != null and ambience_player.playing:
		audio_fade_tween.tween_property(
			ambience_player,
			"volume_db",
			-60.0,
			audio_fade_time
		)

	await audio_fade_tween.finished

	if music_player != null:
		music_player.stop()

	if ambience_player != null:
		ambience_player.stop()


func _stop_gameplay_audio_immediately() -> void:
	if music_player != null:
		music_player.stop()

	if ambience_player != null:
		ambience_player.stop()

	_stop_extrusion_loop()


func _stop_extrusion_loop() -> void:
	if extrusion_player != null:
		extrusion_player.stop()


func play_ui_hover_sound() -> void:
	_play_one_shot(
		stream_ui_hover,
		ui_volume_db,
		1.0
	)


func play_ui_click_sound() -> void:
	_play_one_shot(
		stream_ui_click,
		ui_volume_db,
		1.0
	)


# =========================================================
# SUCCESS / FAILURE
# =========================================================

func win_minigame() -> void:
	if _gameplay_has_stopped():
		return

	game_finished = true
	progress = 1.0

	update_progress_bar()
	update_noodles()
	_freeze_timer_hud()
	_set_cursor_normal()

	_play_completion_and_start_ending()


func _play_completion_and_start_ending() -> void:
	_fade_out_gameplay_audio()
	await _play_completion_effects()
	_start_success_ending()


func _start_time_limit_failure() -> void:
	if _gameplay_has_stopped():
		return

	game_finished = true
	fail_screen_started = true
	time_remaining = 0.0

	_update_timer_ui()
	_freeze_timer_hud()
	_set_cursor_normal()
	_stop_extrusion_loop()
	_play_one_shot(
		stream_failure_transition,
		sfx_volume_db - 1.0,
		1.0
	)
	_fade_out_gameplay_audio()

	if fail_screen == null:
		_ensure_fail_screen()
		_connect_fail_screen()

	if fail_screen == null:
		push_error(
			"Cannot start the Miki fail screen "
			+ "because it is missing."
		)
		return

	if not fail_screen.has_method("start_fail_screen"):
		push_error(
			"Miki fail screen is missing "
			+ "start_fail_screen()."
		)
		return

	var dialogue: String = (
		"You're taking too long; the dough is drying out.\n"
		+ "Keep this up and you'll ruin the whole batch."
	)

	var reason: String = (
		"The noodles were not finished before "
		+ "the dough dried out."
	)

	fail_screen.call(
		"start_fail_screen",
		dialogue,
		reason,
		0,
		false
	)


# =========================================================
# INTRODUCTION
# =========================================================

func _ensure_introduction() -> void:
	var existing_node: Node = get_node_or_null(
		"MinigameIntroduction"
	)

	if existing_node != null:
		var has_required_structure: bool = (
			existing_node.get_node_or_null("Root") != null
			and existing_node.get_node_or_null(
				"Root/BlackBackground"
			) != null
			and existing_node.get_node_or_null(
				"Root/SlideImage"
			) != null
			and existing_node.get_node_or_null(
				"Root/LeftArrowGroup"
			) != null
			and existing_node.get_node_or_null(
				"Root/RightArrowGroup"
			) != null
			and existing_node.get_node_or_null(
				"Root/StartButtonGroup"
			) != null
			and existing_node.get_node_or_null(
				"Root/CountdownLayer"
			) != null
		)

		var has_required_script: bool = (
			existing_node.has_method("start_introduction")
			and existing_node.has_signal("start_requested")
			and existing_node.has_signal(
				"countdown_finished"
			)
		)

		if has_required_structure and has_required_script:
			introduction = existing_node
			introduction.set(
				"auto_start_for_testing",
				false
			)
			return

		remove_child(existing_node)
		existing_node.queue_free()

	if INTRODUCTION_SCENE == null:
		push_error(
			"MIKI: Introduction scene could not be loaded."
		)
		return

	var new_introduction: Node = (
		INTRODUCTION_SCENE.instantiate()
	)

	if new_introduction == null:
		push_error(
			"MIKI: Introduction could not be instantiated."
		)
		return

	new_introduction.name = "MinigameIntroduction"
	new_introduction.set(
		"auto_start_for_testing",
		false
	)

	add_child(new_introduction)
	introduction = new_introduction


func _connect_introduction() -> void:
	if introduction == null:
		return

	var start_callable: Callable = Callable(
		self,
		"_on_introduction_start_requested"
	)

	var countdown_started_callable: Callable = Callable(
		self,
		"_on_introduction_countdown_started"
	)

	var countdown_finished_callable: Callable = Callable(
		self,
		"_on_introduction_countdown_finished"
	)

	if introduction.has_signal("start_requested"):
		if not introduction.is_connected(
			"start_requested",
			start_callable
		):
			introduction.connect(
				"start_requested",
				start_callable
			)

	if introduction.has_signal("countdown_started"):
		if not introduction.is_connected(
			"countdown_started",
			countdown_started_callable
		):
			introduction.connect(
				"countdown_started",
				countdown_started_callable
			)

	if introduction.has_signal("countdown_finished"):
		if not introduction.is_connected(
			"countdown_finished",
			countdown_finished_callable
		):
			introduction.connect(
				"countdown_finished",
				countdown_finished_callable
			)


func _start_miki_introduction() -> void:
	if introduction_started:
		return

	if introduction == null:
		_start_miki_gameplay()
		return

	if not introduction.has_method("start_introduction"):
		_start_miki_gameplay()
		return

	introduction_started = true
	gameplay_started = false

	_reset_miki_gameplay_values()
	_set_cursor_normal()

	introduction.call(
		"start_introduction",
		"miki_noodle_crank"
	)


func _on_introduction_start_requested() -> void:
	gameplay_started = false
	_reset_miki_gameplay_values()
	_set_cursor_normal()

	if hud_layer != null:
		hud_layer.visible = true

	play_ui_click_sound()


func _on_introduction_countdown_started() -> void:
	_play_one_shot(
		stream_countdown_ready,
		ui_volume_db,
		1.0
	)


func _on_introduction_countdown_finished() -> void:
	_start_miki_gameplay()


func _start_miki_gameplay() -> void:
	if gameplay_started:
		return

	_reset_miki_gameplay_values()
	gameplay_started = true

	if hud_layer != null:
		hud_layer.visible = true

	mouse_crank_held = false
	_set_cursor_grab()
	_start_gameplay_audio()


func _reset_miki_gameplay_values() -> void:
	time_remaining = time_limit_seconds
	tension = 0.5
	progress = 0.0

	game_finished = false
	ending_started = false
	fail_screen_started = false

	sweet_center = 0.5
	sweet_size = 0.25
	sweet_target_center = 0.5
	sweet_target_size = 0.25
	sweet_change_timer = 0.0

	pick_new_sweet_spot_target()

	crank_pivot.rotation_degrees = 0.0

	previous_tension_state = _get_tension_zone_state()
	previous_extreme_state = _get_extreme_tension_state()
	tension_state_sound_timer = 0.0
	next_progress_sound_at = progress_sound_step

	update_needle()
	update_sweet_spot(0.0)
	update_progress_bar()
	update_noodles()

	_reset_timer_ui()
	_reset_effects()
	_stop_gameplay_audio_immediately()

	if hud_layer != null:
		hud_layer.visible = false

	_set_cursor_normal()


# =========================================================
# FAIL SCREEN
# =========================================================

func _ensure_fail_screen() -> void:
	var existing_node: Node = get_node_or_null(
		"MinigameFailScreen"
	)

	if existing_node != null:
		var existing_is_valid: bool = (
			existing_node.has_method("start_fail_screen")
			and existing_node.has_signal("retry_requested")
			and existing_node.has_signal("exit_requested")
		)

		if existing_is_valid:
			fail_screen = existing_node
			return

		remove_child(existing_node)
		existing_node.queue_free()

	if FAIL_SCREEN_SCENE == null:
		push_error(
			"Miki fail-screen PackedScene could not be loaded."
		)
		return

	var new_fail_screen: Node = (
		FAIL_SCREEN_SCENE.instantiate()
	)

	if new_fail_screen == null:
		push_error(
			"Miki fail screen could not be instantiated."
		)
		return

	new_fail_screen.name = "MinigameFailScreen"
	add_child(new_fail_screen)
	fail_screen = new_fail_screen


func _connect_fail_screen() -> void:
	if fail_screen == null:
		return

	var retry_callable: Callable = Callable(
		self,
		"_on_fail_retry_requested"
	)

	var exit_callable: Callable = Callable(
		self,
		"_on_fail_exit_requested"
	)

	if fail_screen.has_signal("retry_requested"):
		if not fail_screen.is_connected(
			"retry_requested",
			retry_callable
		):
			fail_screen.connect(
				"retry_requested",
				retry_callable
			)

	if fail_screen.has_signal("exit_requested"):
		if not fail_screen.is_connected(
			"exit_requested",
			exit_callable
		):
			fail_screen.connect(
				"exit_requested",
				exit_callable
			)


func _on_fail_retry_requested() -> void:
	if get_tree().current_scene == self:
		get_tree().reload_current_scene()
	else:
		minigame_retry_requested.emit()


func _on_fail_exit_requested() -> void:
	if result_emitted:
		return

	result_emitted = true
	_set_cursor_normal()
	minigame_failed.emit()


# =========================================================
# ENDING SEQUENCE
# =========================================================

func _ensure_ending_sequence() -> void:
	var existing_node: Node = get_node_or_null(
		"CollectibleEndingScene"
	)

	if existing_node != null:
		var existing_scene_is_valid: bool = (
			existing_node.has_method("start_ending")
			and existing_node.has_signal("ending_finished")
		)

		if existing_scene_is_valid:
			ending_sequence = existing_node
			return

		remove_child(existing_node)
		existing_node.queue_free()

	if ENDING_SCENE == null:
		push_error(
			"Miki ending PackedScene could not be loaded."
		)
		return

	var new_ending_scene: Node = ENDING_SCENE.instantiate()

	if new_ending_scene == null:
		push_error(
			"Miki ending scene could not be instantiated."
		)
		return

	new_ending_scene.name = "CollectibleEndingScene"
	add_child(new_ending_scene)
	ending_sequence = new_ending_scene


func _connect_ending_sequence() -> void:
	if ending_sequence == null:
		return

	var finished_callable: Callable = Callable(
		self,
		"_on_ending_sequence_finished"
	)

	if ending_sequence.has_signal("ending_finished"):
		if not ending_sequence.is_connected(
			"ending_finished",
			finished_callable
		):
			ending_sequence.connect(
				"ending_finished",
				finished_callable
			)


func _start_success_ending() -> void:
	if ending_started or fail_screen_started:
		return

	if ending_sequence == null:
		_ensure_ending_sequence()
		_connect_ending_sequence()

	if ending_sequence == null:
		push_error(
			"Cannot start the Miki ending because "
			+ "the ending scene is missing."
		)
		return

	if not ending_sequence.has_method("start_ending"):
		push_error(
			"Cannot start the Miki ending because "
			+ "start_ending() is missing."
		)
		return

	if ENDING_COLLECTIBLE == null:
		push_error(
			"Miki ending collectible texture is missing."
		)
		return

	ending_started = true

	ending_sequence.call(
		"start_ending",
		ENDING_COLLECTIBLE,
		ending_collectible_scale
	)


func _on_ending_sequence_finished() -> void:
	if result_emitted:
		return

	result_emitted = true
	_set_cursor_normal()
	minigame_finished.emit()
