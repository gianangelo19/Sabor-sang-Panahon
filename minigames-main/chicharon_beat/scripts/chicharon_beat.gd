extends Node2D

signal minigame_finished
signal minigame_failed(score: int)
signal minigame_retry_requested

enum MiniRoundPhase {
	THROWING_BATCH,
	TAKING_OUT,
	ROUND_END,
	GAME_OVER
}

const ENDING_SCENE: PackedScene = preload(
	"res://minigames-main/ending_sequence/scenes/collectible_ending_scene.tscn"
)

const ENDING_COLLECTIBLE: Texture2D = preload(
	"res://minigames-main/ending_sequence/assets/collectibles/collectible_chicharon_bag.png"
)

const FAIL_SCREEN_SCENE: PackedScene = preload(
	"res://minigames-main/fail_screen/scenes/minigame_fail_screen.tscn"
)

const INTRODUCTION_SCENE: PackedScene = preload(
	"res://minigames-main/introduction/scenes/minigame_introduction.tscn"
)


const VCR_FONT_PATH: String = (
	"res://minigames-main/shared/fonts/VCR_OSD_MONO_1.001.ttf"
)

const CHICHARON_SCENE_SEARCH_ROOT: String = (
	"res://minigames-main/chicharon_beat"
)

const CHICHARON_SCENE_COMMON_PATHS: Array[String] = [
	"res://minigames-main/chicharon_beat/scenes/chicharon.tscn",
	"res://minigames-main/chicharon_beat/scenes/chicharon_piece.tscn",
	"res://minigames-main/chicharon_beat/chicharon.tscn",
	"res://minigames-main/chicharon_beat/chicharon_piece.tscn"
]

# =========================================================
# VISUAL POLISH ASSETS
# =========================================================

const OIL_SPLASH_BIG: Texture2D = preload(
	"res://minigames-main/chicharon_beat/assets/effects/oil_splash_big.png"
)

const PERFECT_POPUP: Texture2D = preload(
	"res://minigames-main/chicharon_beat/assets/feedback/perfect_text_popup.png"
)

const TOO_RAW_POPUP: Texture2D = preload(
	"res://minigames-main/chicharon_beat/assets/feedback/too_raw_text_popup.png"
)

const UNDERCOOKED_POPUP: Texture2D = preload(
	"res://minigames-main/chicharon_beat/assets/feedback/undercooked_text_popup.png"
)

const BURNT_POPUP: Texture2D = preload(
	"res://minigames-main/chicharon_beat/assets/feedback/burnt_text_popup.png"
)

const TONGS_BACK_TEXTURE: Texture2D = preload(
	"res://minigames-main/chicharon_beat/assets/tongs/tongs_back.png"
)

const TONGS_FRONT_TEXTURE: Texture2D = preload(
	"res://minigames-main/chicharon_beat/assets/tongs/tongs_front.png"
)

const CHICHARON_UI_PANEL_TEXTURE: Texture2D = preload(
	"res://minigames-main/chicharon_beat/assets/ui/chicharon_ui_panel.png"
)

const ROUND_BANNER_TEXTURE: Texture2D = preload(
	"res://minigames-main/chicharon_beat/assets/ui/round_banner.png"
)

const COMBO_BADGE_TEXTURE: Texture2D = preload(
	"res://minigames-main/chicharon_beat/assets/ui/combo_badge.png"
)

const WARNING_PANEL_TEXTURE: Texture2D = preload(
	"res://minigames-main/chicharon_beat/assets/ui/warning_panel.png"
)

# =========================================================
# AUDIO ASSETS
# =========================================================

const BGM_CHICHARON: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/music/bgm_chicharon_beat_loop.ogg"
)

const AMB_FRYING_OIL: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/ambience/amb_frying_oil_loop.ogg"
)

const SFX_OIL_SPLASH_BIG: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_oil_splash_big.wav"
)

const SFX_TAKEOUT_PERFECT_01: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_takeout_perfect_01.wav"
)

const SFX_TAKEOUT_PERFECT_02: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_takeout_perfect_02.wav"
)

const SFX_TAKEOUT_RAW: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_takeout_raw.wav"
)

const SFX_TAKEOUT_UNDERCOOKED: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_takeout_undercooked.wav"
)

const SFX_TONGS_SNAP: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_tongs_snap.wav"
)

const SFX_TONGS_GRAB: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_tongs_grab.wav"
)

const SFX_TONGS_MISS: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_tongs_miss.wav"
)

const SFX_COMBO_UP: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_combo_up.wav"
)

const SFX_COMBO_BREAK: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_combo_break.wav"
)

const SFX_ROUND_START: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_round_start.wav"
)

const SFX_ROUND_COMPLETE: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_round_complete.wav"
)

const SFX_WARNING_NEAR_FAIL: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_warning_near_fail.wav"
)

const SFX_SUCCESS_TRANSITION: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_success_transition.wav"
)

const SFX_FAILURE_TRANSITION: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_failure_transition.wav"
)

const SFX_COUNTDOWN_READY: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/ui/sfx_countdown_ready.wav"
)

@export_category("Chicharon")
@export var chicharon_scene: PackedScene

@export_category("Timing")
@export var bpm: float = 250.0
@export var travel_beats: float = 12.0
@export var throw_duration: float = 0.55
@export var post_throw_input_delay: float = 0.30

@export_category("Takeout Judgement")

# The visible center of the takeout ring is the real PERFECT zone.
# A chicharon inside this radius is always judged as PERFECT.
@export var perfect_takeout_radius: float = 58.0

# Prevents SPACE from grabbing a completely unrelated raw piece
# from the other side of the pot after the centered piece has left.
@export var takeout_input_radius: float = 180.0

# Used only for early presses outside the perfect radius.
# The piece's own progress decides whether the miss is raw or
# undercooked.
@export_range(0.0, 1.0, 0.01) var raw_takeout_progress_end: float = 0.35

@export_category("Visual Polish")

@export var popup_scale: Vector2 = Vector2(0.22, 0.22)
@export var popup_offset: Vector2 = Vector2(0.0, -95.0)
@export var popup_rise_distance: float = 48.0

@export var big_splash_scale: Vector2 = Vector2(0.16, 0.16)
@export var big_splash_offset: Vector2 = Vector2(0.0, 8.0)

@export var tongs_scale: Vector2 = Vector2(0.20, 0.20)
@export var tongs_rest_offset: Vector2 = Vector2(165.0, -145.0)
@export var tongs_take_offset: Vector2 = Vector2(34.0, -40.0)
@export var tongs_rotation_degrees: float = -43.0
@export var tongs_strike_duration: float = 0.09
@export var tongs_retract_duration: float = 0.16

@export var ui_panel_position: Vector2 = Vector2(118.0, 150.0)
@export var ui_panel_scale: Vector2 = Vector2(0.18, 0.18)

@export var round_banner_position: Vector2 = Vector2(575.0, 48.0)
@export var round_banner_scale: Vector2 = Vector2(0.20, 0.20)

@export_category("HUD Label Layout")

@export var hud_label_font_size: int = 16
@export var round_label_font_size: int = 18
@export var feedback_label_font_size: int = 20

@export var hud_label_size: Vector2 = Vector2(160.0, 42.0)

@export var collected_label_offset: Vector2 = Vector2(-80.0, -105.0)
@export var wasted_label_offset: Vector2 = Vector2(-80.0, -63.0)
@export var combo_label_offset: Vector2 = Vector2(-80.0, -22.0)
@export var score_label_offset: Vector2 = Vector2(-80.0, 23.0)

@export var round_label_offset: Vector2 = Vector2(-185.0, -20.0)
@export var round_label_size: Vector2 = Vector2(370.0, 40.0)

@export var combo_badge_position: Vector2 = Vector2(1000.0, 145.0)
@export var combo_badge_scale: Vector2 = Vector2(0.13, 0.13)

@export var warning_panel_position: Vector2 = Vector2(575.0, 115.0)
@export var warning_panel_scale: Vector2 = Vector2(0.24, 0.24)

@export_category("Chicharon Audio")

@export var music_volume_db: float = -18.0
@export var ambience_volume_db: float = -17.0
@export var sfx_volume_db: float = -4.0
@export var ui_sfx_volume_db: float = -7.0
@export var audio_one_shot_player_count: int = 12

@export_category("Ending Sequence")
@export var ending_collectible_scale: Vector2 = Vector2(0.6, 0.6)

# Keep enabled while testing.
# Press T to immediately force the success ending.
@export var ending_test_key_enabled: bool = true

@export_category("Fail Screen")

# Press F to immediately test the fail screen.
@export var fail_test_key_enabled: bool = true

@onready var chicharon_container: Node2D = $ChicharonContainer
@onready var throw_start_point: Marker2D = $ThrowStartPoint
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var takeout_point: Marker2D = $TakeOutPoint
@onready var takeout_indicator: Node2D = $TakeOutIndicator

@onready var round_label: Label = $UI/RoundLabel
@onready var collected_label: Label = $UI/CollectedLabel
@onready var wasted_label: Label = $UI/WastedLabel
@onready var combo_label: Label = $UI/ComboLabel
@onready var feedback_label: Label = $UI/FeedbackLabel

var music_player: AudioStreamPlayer = null
var ambience_player: AudioStreamPlayer = null
var one_shot_players: Array[AudioStreamPlayer] = []

var tongs_root: Node2D = null
var tongs_back: Sprite2D = null
var tongs_front: Sprite2D = null
var tongs_busy: bool = false

var ui_panel_sprite: Sprite2D = null
var round_banner_sprite: Sprite2D = null
var combo_badge_sprite: Sprite2D = null
var warning_panel_sprite: Sprite2D = null
var warning_label: Label = null
var score_label: Label = null

var feedback_tween: Tween = null
var combo_tween: Tween = null
var warning_tween: Tween = null

var warning_was_active: bool = false
var last_warning_wasted: int = -1

var phase: MiniRoundPhase = MiniRoundPhase.THROWING_BATCH

var round_defs: Array[Dictionary] = [
	{"name": "Round 1", "difficulty": "easy"},
	{"name": "Round 2", "difficulty": "medium"},
	{"name": "Round 3", "difficulty": "medium"},
	{"name": "Round 4", "difficulty": "hard"},
	{"name": "Round 5", "difficulty": "hard"}
]

# These are beat gaps between throws.
# Chicharon count = pattern size + 1.
var easy_patterns: Array = [
	[3, 3, 3],
	[3, 4, 3],
	[4, 3, 3]
]

var medium_patterns: Array = [
	[3, 2, 3, 2],
	[2, 3, 2, 3],
	[3, 3, 2, 2],
	[2, 3, 3, 2],
	[3, 2, 2, 3],
	[2, 2, 3, 3]
]

var hard_patterns: Array = [
	[2, 2, 2, 2],
	[2, 2, 3, 2],
	[2, 3, 2, 2],
	[3, 2, 2, 2],
	[2, 2, 2, 3],
	[2, 3, 2, 3]
]

var current_round_index: int = 0
var current_pattern: Array = []

var round_pieces: Array[Node] = []
var removed_this_round: int = 0

var collected: int = 0
var wasted: int = 0
var combo: int = 0
var score: int = 0

var total_chicharons: int = 24
var required_collected: int = 18
var fail_wasted: int = 7

var ending_sequence: Node = null
var ending_started: bool = false

var fail_screen: Node = null
var fail_screen_started: bool = false

var introduction: Node = null
var introduction_started: bool = false
var gameplay_started: bool = false

var result_emitted: bool = false

var resolved_chicharon_scene_path: String = ""


func _ready() -> void:
	randomize()

	_resolve_chicharon_scene()

	_setup_audio()
	_setup_polish_visuals()

	# Do not let the rhythm game start until the shared
	# introduction slideshow and countdown have finished.
	gameplay_started = false
	introduction_started = false

	_ensure_ending_sequence()
	_connect_ending_sequence()

	_ensure_fail_screen()
	_connect_fail_screen()

	_ensure_introduction()
	_connect_introduction()

	if takeout_indicator != null:
		takeout_indicator.global_position = (
			takeout_point.global_position
		)
		takeout_indicator.visible = false

	clear_remaining_chicharon()
	_reset_gameplay_values()
	update_ui()

	feedback_label.text = "Get ready!"
	feedback_label.modulate = Color.WHITE

	print("")
	print("========================================")
	print("CHICHARON BEAT READY")
	print("========================================")
	print("Introduction found: ", introduction != null)
	print("Ending node found: ", ending_sequence != null)
	print("Fail screen found: ", fail_screen != null)

	if introduction != null:
		print(
			"Introduction has start_introduction(): ",
			introduction.has_method("start_introduction")
		)
		print(
			"Introduction has start_requested: ",
			introduction.has_signal("start_requested")
		)
		print(
			"Introduction has countdown_finished: ",
			introduction.has_signal("countdown_finished")
		)

	if ending_sequence != null:
		print(
			"Ending has start_ending(): ",
			ending_sequence.has_method("start_ending")
		)
		print(
			"Ending has ending_finished signal: ",
			ending_sequence.has_signal("ending_finished")
		)

	print(
		"Chicharon collectible loaded: ",
		ENDING_COLLECTIBLE != null
	)

	if fail_screen != null:
		print(
			"Fail screen has start_fail_screen(): ",
			fail_screen.has_method("start_fail_screen")
		)
		print(
			"Fail screen has retry_requested: ",
			fail_screen.has_signal("retry_requested")
		)
		print(
			"Fail screen has exit_requested: ",
			fail_screen.has_signal("exit_requested")
		)

	print("Press T to test the success ending after countdown.")
	print("Press F to test the fail screen after countdown.")
	print("========================================")
	print("")

	_start_chicharon_introduction()


func _resolve_chicharon_scene() -> bool:
	if (
		chicharon_scene != null
		and _is_valid_chicharon_scene(
			chicharon_scene
		)
	):
		resolved_chicharon_scene_path = (
			chicharon_scene.resource_path
		)

		print(
			"DEBUG CHICHARON: Using assigned piece scene: ",
			resolved_chicharon_scene_path
		)

		return true

	chicharon_scene = null
	resolved_chicharon_scene_path = ""

	for candidate_path in CHICHARON_SCENE_COMMON_PATHS:
		if not ResourceLoader.exists(candidate_path):
			continue

		var candidate_resource: Resource = load(
			candidate_path
		)

		if not candidate_resource is PackedScene:
			continue

		var candidate_scene: PackedScene = (
			candidate_resource as PackedScene
		)

		if not _is_valid_chicharon_scene(
			candidate_scene
		):
			continue

		chicharon_scene = candidate_scene
		resolved_chicharon_scene_path = candidate_path

		print(
			"DEBUG CHICHARON: Auto-loaded piece scene: ",
			resolved_chicharon_scene_path
		)

		return true

	var discovered_paths: Array[String] = []

	_collect_scene_paths_recursive(
		CHICHARON_SCENE_SEARCH_ROOT,
		discovered_paths
	)

	discovered_paths.sort()

	for candidate_path in discovered_paths:
		if candidate_path == scene_file_path:
			continue

		if not ResourceLoader.exists(candidate_path):
			continue

		var candidate_resource: Resource = load(
			candidate_path
		)

		if not candidate_resource is PackedScene:
			continue

		var candidate_scene: PackedScene = (
			candidate_resource as PackedScene
		)

		if not _is_valid_chicharon_scene(
			candidate_scene
		):
			continue

		chicharon_scene = candidate_scene
		resolved_chicharon_scene_path = candidate_path

		print(
			"DEBUG CHICHARON: Found piece scene automatically: ",
			resolved_chicharon_scene_path
		)

		return true

	push_error(
		"CHICHARON: Could not find the individual "
		+ "Chicharon PackedScene. The scene must have a "
		+ "root script with setup_for_batch(), the removed "
		+ "signal, and a direct Sprite2D child."
	)

	return false


func _is_valid_chicharon_scene(
	packed_scene: PackedScene
) -> bool:
	if packed_scene == null:
		return false

	var test_piece: Node = packed_scene.instantiate()

	if test_piece == null:
		return false

	var valid_piece: bool = (
		test_piece.has_method("setup_for_batch")
		and test_piece.has_signal("removed")
		and test_piece.get_node_or_null("Sprite2D") != null
	)

	test_piece.free()

	return valid_piece


func _collect_scene_paths_recursive(
	directory_path: String,
	output_paths: Array[String]
) -> void:
	var directory: DirAccess = DirAccess.open(
		directory_path
	)

	if directory == null:
		return

	directory.list_dir_begin()

	var entry_name: String = directory.get_next()

	while not entry_name.is_empty():
		var entry_path: String = (
			directory_path.path_join(entry_name)
		)

		if directory.current_is_dir():
			if not entry_name.begins_with("."):
				_collect_scene_paths_recursive(
					entry_path,
					output_paths
				)

		elif entry_name.to_lower().ends_with(".tscn"):
			output_paths.append(entry_path)

		entry_name = directory.get_next()

	directory.list_dir_end()

func _process(_delta: float) -> void:
	if takeout_indicator == null:
		return

	if (
		not gameplay_started
		or phase != MiniRoundPhase.TAKING_OUT
		or _gameplay_has_stopped()
	):
		if takeout_indicator.has_method("clear_target_timing"):
			takeout_indicator.call("clear_target_timing")
		return

	var target: Node = get_current_input_target()

	if target == null:
		if takeout_indicator.has_method("clear_target_timing"):
			takeout_indicator.call("clear_target_timing")
		return

	var progress: float = 0.0
	var cook_state_name: String = "raw"

	if target.has_method("get_float_progress"):
		progress = float(
			target.call("get_float_progress")
		)

	if target.has_method("get_cook_state_name"):
		cook_state_name = str(
			target.call("get_cook_state_name")
		)

	if takeout_indicator.has_method("set_target_timing"):
		takeout_indicator.call(
			"set_target_timing",
			progress,
			cook_state_name
		)


func _input(event: InputEvent) -> void:
	# The introduction owns all input until the countdown ends.
	# Its arrows and Start button are mouse-only.
	if not gameplay_started:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			print("DEBUG CHICHARON INPUT: F detected.")
		elif event.keycode == KEY_T:
			print("DEBUG CHICHARON INPUT: T detected.")

	if event is InputEventKey:
		if (
			ending_test_key_enabled
			and event.keycode == KEY_T
			and event.pressed
			and not event.echo
		):
			if not _gameplay_has_stopped():
				print(
					"DEBUG CHICHARON: T pressed. "
					+ "Forcing success ending."
				)

				end_game(true)
				get_viewport().set_input_as_handled()

			return

		if (
			fail_test_key_enabled
			and event.keycode == KEY_F
			and event.pressed
			and not event.echo
		):
			if not _gameplay_has_stopped():
				print(
					"DEBUG CHICHARON: F pressed. "
					+ "Forcing fail screen."
				)

				end_game(false, "too_many_wasted")
				get_viewport().set_input_as_handled()

			return

	if _gameplay_has_stopped():
		return

	if event.is_action_pressed("ui_accept"):
		try_take_chicharon()
		get_viewport().set_input_as_handled()


func _gameplay_has_stopped() -> bool:
	return (
		not gameplay_started
		or phase == MiniRoundPhase.GAME_OVER
		or ending_started
		or fail_screen_started
	)


func start_round() -> void:
	if not gameplay_started:
		return

	if ending_started:
		return

	if phase == MiniRoundPhase.GAME_OVER:
		return

	if current_round_index >= round_defs.size():
		end_game(collected >= required_collected)
		return

	phase = MiniRoundPhase.THROWING_BATCH

	round_pieces.clear()
	removed_this_round = 0

	var round_data: Dictionary = round_defs[current_round_index]
	var difficulty: String = str(round_data["difficulty"])
	var round_name: String = str(round_data["name"])

	current_pattern = choose_pattern(difficulty)

	show_feedback(
		round_name
		+ " - "
		+ difficulty.capitalize()
	)

	_play_one_shot(
		SFX_ROUND_START,
		ui_sfx_volume_db,
		1.0
	)

	_pulse_round_banner()

	update_ui()

	throw_batch()

func choose_pattern(difficulty: String) -> Array:
	var patterns: Array = []

	if difficulty == "easy":
		patterns = easy_patterns
	elif difficulty == "medium":
		patterns = medium_patterns
	else:
		patterns = hard_patterns

	var index: int = randi() % patterns.size()
	var chosen_pattern: Array = patterns[index] as Array

	return chosen_pattern.duplicate()


func throw_batch() -> void:
	if not gameplay_started:
		return

	if ending_started:
		return

	if phase == MiniRoundPhase.GAME_OVER:
		return

	if (
		chicharon_scene == null
		or not _is_valid_chicharon_scene(
			chicharon_scene
		)
	):
		if not _resolve_chicharon_scene():
			show_feedback(
				"Chicharon scene missing!"
			)
			return

	var seconds_per_beat: float = 60.0 / bpm
	var piece_float_duration: float = (
		travel_beats * seconds_per_beat
	)

	# Pattern is the gaps between throws.
	# So 3 gaps = 4 chicharons, 4 gaps = 5 chicharons.
	var batch_count: int = current_pattern.size() + 1

	for index in range(batch_count):
		if ending_started:
			return

		if phase == MiniRoundPhase.GAME_OVER:
			return

		var piece: Node = chicharon_scene.instantiate()

		if piece == null:
			push_error(
				"CHICHARON: Failed to instantiate piece from: "
				+ resolved_chicharon_scene_path
			)
			return

		if not piece.has_method("setup_for_batch"):
			push_error(
				"CHICHARON: Spawned scene is not a valid "
				+ "Chicharon piece. Missing setup_for_batch()."
			)
			piece.free()
			return

		chicharon_container.add_child(piece)

		print(
			"DEBUG CHICHARON: Spawned piece ",
			index + 1,
			" / ",
			batch_count,
			" from ",
			resolved_chicharon_scene_path
		)

		# Keep X the same so all chicharons travel
		# the same distance and speed.
		# Only Y changes slightly so they are not stacked.
		var land_offset: Vector2 = Vector2(
			0.0,
			randf_range(-10.0, 10.0)
		)

		var land_position: Vector2 = (
			spawn_point.global_position
			+ land_offset
		)

		piece.call(
			"setup_for_batch",
			throw_start_point.global_position,
			land_position,
			takeout_point.global_position,
			piece_float_duration,
			throw_duration
		)

		var removed_callable: Callable = Callable(
			self,
			"_on_chicharon_removed"
		).bind(piece)

		if piece.has_signal("removed"):
			piece.connect(
				"removed",
				removed_callable
			)
		else:
			push_warning(
				"Spawned chicharon is missing "
				+ "the removed signal."
			)

		round_pieces.append(piece)

		if index < current_pattern.size():
			var gap_beats: float = float(
				current_pattern[index]
			)

			var wait_time: float = (
				gap_beats * seconds_per_beat
			)

			await get_tree().create_timer(
				wait_time,
				false,
			).timeout

			if ending_started:
				return

			if phase == MiniRoundPhase.GAME_OVER:
				return

	# Wait until the last chicharon has landed
	# before input begins.
	await get_tree().create_timer(
		throw_duration + post_throw_input_delay,
		false,
	).timeout

	if ending_started:
		return

	if phase == MiniRoundPhase.GAME_OVER:
		return

	start_takeout_phase()


func start_takeout_phase() -> void:
	if not gameplay_started:
		return

	if ending_started:
		return

	if phase == MiniRoundPhase.GAME_OVER:
		return

	phase = MiniRoundPhase.TAKING_OUT
	show_feedback("Take them out!")


func _get_takeout_center_position() -> Vector2:
	if (
		takeout_indicator != null
		and takeout_indicator.has_method(
			"get_takeout_center_global_position"
		)
	):
		return Vector2(
			takeout_indicator.call(
				"get_takeout_center_global_position"
			)
		)

	return takeout_point.global_position


func try_take_chicharon() -> void:
	if not gameplay_started:
		return

	if ending_started:
		return

	if tongs_busy:
		return

	if phase != MiniRoundPhase.TAKING_OUT:
		show_feedback("Wait for the batch!")
		return

	var target: Node = get_current_input_target()

	if target == null:
		show_feedback("Wait!")

		if combo > 0:
			combo = 0

			_play_one_shot(
				SFX_COMBO_BREAK,
				sfx_volume_db,
				1.0
			)

			_pulse_combo_badge()

		update_ui()

		if takeout_indicator.has_method("flash_result"):
			takeout_indicator.call(
				"flash_result",
				"miss"
			)

		return

	# Judge immediately on the exact frame SPACE was pressed.
	# The tong animation must never be allowed to change a
	# PERFECT press into BURNT or RAW.
	var take_result: String = (
		_get_takeout_result(target)
	)

	# Freeze the selected chicharon immediately so it cannot keep
	# cooking during the short tong strike animation.
	if target.has_method("lock_for_takeout"):
		var locked: bool = bool(
			target.call("lock_for_takeout")
		)

		if not locked:
			return

	_animate_tongs_and_take(
		target,
		take_result
	)


func _get_takeout_result(
	target: Node
) -> String:
	var target_2d: Node2D = target as Node2D

	if target_2d == null:
		return "raw"

	var takeout_center: Vector2 = (
		_get_takeout_center_position()
	)

	var distance_to_center: float = (
		target_2d.global_position.distance_to(
			takeout_center
		)
	)

	# The ring center is authoritative.
	# Inside the ring's perfect radius = PERFECT.
	if distance_to_center <= perfect_takeout_radius:
		return "perfect"

	var progress: float = 0.0

	if target.has_method("get_float_progress"):
		progress = float(
			target.call("get_float_progress")
		)

	if progress < raw_takeout_progress_end:
		return "raw"

	return "slightly_cooked"

func get_current_input_target() -> Node:
	var best_piece: Node = null
	var best_distance: float = INF

	for piece in round_pieces:
		if not is_instance_valid(piece):
			continue

		if not piece.has_method("is_active_for_input"):
			continue

		var is_active: bool = bool(
			piece.call("is_active_for_input")
		)

		if not is_active:
			continue

		var piece_2d: Node2D = piece as Node2D

		if piece_2d == null:
			continue

		var distance: float = (
			piece_2d.global_position.distance_to(
				_get_takeout_center_position()
			)
		)

		# Do not select raw pieces that are still far across the pot.
		# This prevents the old problem where the centered piece burnt
		# and SPACE immediately targeted the next raw piece instead.
		if distance > takeout_input_radius:
			continue

		if distance < best_distance:
			best_distance = distance
			best_piece = piece

	return best_piece

func _on_chicharon_removed(
	reason: String,
	piece: Node
) -> void:
	if not gameplay_started:
		return

	if ending_started:
		return

	if phase == MiniRoundPhase.GAME_OVER:
		return

	removed_this_round += 1

	var previous_combo: int = combo

	if reason == "collected":
		collected += 1
		combo += 1
		score += 300 + combo * 10

		_play_one_shot(
			SFX_COMBO_UP,
			sfx_volume_db - 3.0,
			1.0 + minf(float(combo - 1) * 0.04, 0.20)
		)

		_pulse_combo_badge()

	elif reason == "wasted_raw":
		wasted += 1
		combo = 0
		score = maxi(score - 50, 0)

	elif reason == "wasted_slightly":
		wasted += 1
		combo = 0
		score = maxi(score - 25, 0)

	elif reason == "burnt":
		wasted += 1
		combo = 0

	if previous_combo > 0 and combo == 0:
		_play_one_shot(
			SFX_COMBO_BREAK,
			sfx_volume_db,
			1.0
		)

		_pulse_combo_badge()

	update_ui()
	_update_warning_ui()

	if wasted >= fail_wasted:
		end_game(false, "too_many_wasted")
		return

	if removed_this_round >= round_pieces.size():
		finish_round()

func finish_round() -> void:
	if not gameplay_started:
		return

	if ending_started:
		return

	if phase == MiniRoundPhase.GAME_OVER:
		return

	phase = MiniRoundPhase.ROUND_END

	_play_one_shot(
		SFX_ROUND_COMPLETE,
		sfx_volume_db,
		1.0
	)

	current_round_index += 1

	if current_round_index >= round_defs.size():
		end_game(collected >= required_collected)
		return

	show_feedback("Next batch...")

	await get_tree().create_timer(1.2, false).timeout

	if ending_started:
		return

	if phase == MiniRoundPhase.GAME_OVER:
		return

	start_round()

func end_game(
	success: bool,
	failure_type: String = "not_enough_collected"
) -> void:
	if ending_started or fail_screen_started:
		return

	if phase == MiniRoundPhase.GAME_OVER:
		return

	phase = MiniRoundPhase.GAME_OVER
	clear_remaining_chicharon()
	_hide_tongs()
	_fade_out_game_audio()

	if success:
		_play_one_shot(
			SFX_SUCCESS_TRANSITION,
			sfx_volume_db,
			1.0
		)
		show_feedback("Success! Enough chicharon!")
		update_ui()

		print("")
		print("========================================")
		print("CHICHARON BEAT SUCCESS")
		print("Collected: ", collected)
		print("Wasted: ", wasted)
		print("Score: ", score)
		print("========================================")
		print("")

		_start_success_ending()
		return

	_play_one_shot(
		SFX_FAILURE_TRANSITION,
		sfx_volume_db,
		1.0
	)

	show_feedback("Failed! Vendor got angry!")
	update_ui()

	print("")
	print("========================================")
	print("CHICHARON BEAT FAILED")
	print("Failure type: ", failure_type)
	print("Collected: ", collected)
	print("Wasted: ", wasted)
	print("Score: ", score)
	print("========================================")
	print("")

	_start_failure_screen(failure_type)


func _start_failure_screen(failure_type: String) -> void:
	if fail_screen_started or ending_started:
		return

	if fail_screen == null:
		_ensure_fail_screen()
		_connect_fail_screen()

	if fail_screen == null:
		push_error(
			"Cannot start the Chicharon fail screen "
			+ "because it is missing."
		)
		return

	if not fail_screen.has_method("start_fail_screen"):
		push_error(
			"Chicharon fail screen is missing "
			+ "start_fail_screen()."
		)
		return

	fail_screen_started = true
	phase = MiniRoundPhase.GAME_OVER
	clear_remaining_chicharon()

	var dialogue: String
	var reason: String

	if failure_type == "too_many_wasted":
		dialogue = (
			"Why are you wasting so much food? "
			+ "This whole batch is ruined! "
			+ "Be more careful next time."
		)
		reason = "Too much chicharon was wasted."
	else:
		dialogue = (
			"That's not enough chicharon for the order. "
			+ "Get a new batch and try again."
		)
		reason = (
			"Not enough properly cooked chicharon "
			+ "was collected."
		)

	print("DEBUG CHICHARON: Starting shared fail screen.")

	fail_screen.call(
		"start_fail_screen",
		dialogue,
		reason,
		score,
		true
	)


# =========================================================
# SHARED INTRODUCTION
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
			and existing_node.has_signal("countdown_finished")
		)

		if has_required_structure and has_required_script:
			introduction = existing_node
			introduction.set("auto_start_for_testing", false)

			print(
				"DEBUG CHICHARON: Existing introduction is valid."
			)
			return

		print(
			"DEBUG CHICHARON: Existing introduction is "
			+ "incomplete. Replacing it."
		)

		remove_child(existing_node)
		existing_node.queue_free()

	if INTRODUCTION_SCENE == null:
		push_error(
			"CHICHARON: Introduction scene could not be loaded."
		)
		return

	var new_introduction: Node = INTRODUCTION_SCENE.instantiate()

	if new_introduction == null:
		push_error(
			"CHICHARON: Introduction could not be instantiated."
		)
		return

	new_introduction.name = "MinigameIntroduction"

	# Set this before add_child(), because the introduction's
	# _ready() runs as soon as it enters the scene tree.
	new_introduction.set("auto_start_for_testing", false)

	add_child(new_introduction)
	introduction = new_introduction

	print(
		"DEBUG CHICHARON: Introduction instantiated automatically."
	)


func _connect_introduction() -> void:
	if introduction == null:
		push_error("CHICHARON: Introduction is missing.")
		return

	if not introduction.has_signal("start_requested"):
		push_error(
			"CHICHARON: Introduction is missing start_requested."
		)
		return

	if not introduction.has_signal("countdown_finished"):
		push_error(
			"CHICHARON: Introduction is missing "
			+ "countdown_finished."
		)
		return

	var start_callable: Callable = Callable(
		self,
		"_on_introduction_start_requested"
	)

	var countdown_callable: Callable = Callable(
		self,
		"_on_introduction_countdown_finished"
	)

	if not introduction.is_connected(
		"start_requested",
		start_callable
	):
		introduction.connect(
			"start_requested",
			start_callable
		)

	if not introduction.is_connected(
		"countdown_finished",
		countdown_callable
	):
		introduction.connect(
			"countdown_finished",
			countdown_callable
		)

	print("DEBUG CHICHARON: Introduction signals connected.")


func _start_chicharon_introduction() -> void:
	if introduction_started:
		return

	if introduction == null:
		push_error(
			"CHICHARON: Cannot start introduction because it is missing."
		)
		_start_chicharon_gameplay()
		return

	if not introduction.has_method("start_introduction"):
		push_error(
			"CHICHARON: Introduction is missing start_introduction()."
		)
		_start_chicharon_gameplay()
		return

	introduction_started = true
	gameplay_started = false

	clear_remaining_chicharon()
	_reset_gameplay_values()
	update_ui()

	if takeout_indicator != null:
		takeout_indicator.visible = false

	feedback_label.text = "Get ready!"
	feedback_label.modulate = Color.WHITE

	print("")
	print("========================================")
	print("CHICHARON INTRODUCTION STARTING")
	print("Introduction ID: chicharon_beat")
	print("========================================")
	print("")

	introduction.call(
		"start_introduction",
		"chicharon_beat"
	)


func _on_introduction_start_requested() -> void:
	print("")
	print("========================================")
	print("CHICHARON START BUTTON PRESSED")
	print("Showing the game behind the countdown.")
	print("Gameplay remains locked until 1 disappears.")
	print("========================================")
	print("")

	# The minigame scene already exists underneath the
	# introduction. Reveal its normal indicator and UI while
	# keeping all rhythm input and round logic disabled.
	if takeout_indicator != null:
		takeout_indicator.visible = true

	update_ui()
	feedback_label.text = "Get ready!"
	feedback_label.modulate = Color.WHITE


func _on_introduction_countdown_finished() -> void:
	_play_one_shot(
		SFX_COUNTDOWN_READY,
		ui_sfx_volume_db,
		1.0
	)

	print("")
	print("========================================")
	print("CHICHARON COUNTDOWN FINISHED")
	print("Starting the first batch now.")
	print("========================================")
	print("")

	_start_chicharon_gameplay()


func _start_chicharon_gameplay() -> void:
	if gameplay_started:
		return

	clear_remaining_chicharon()
	_reset_gameplay_values()

	gameplay_started = true
	phase = MiniRoundPhase.THROWING_BATCH

	_start_game_audio()

	if (
		takeout_indicator != null
		and takeout_indicator.has_method("set_bpm")
	):
		takeout_indicator.call(
			"set_bpm",
			bpm
		)

	if takeout_indicator != null:
		takeout_indicator.visible = true
		takeout_indicator.global_position = (
			takeout_point.global_position
		)

	update_ui()
	show_feedback("Get ready!")

	print("")
	print("========================================")
	print("CHICHARON BEAT GAMEPLAY STARTED")
	print("Round: 1 / 5")
	print("Required collected: ", required_collected)
	print("Waste failure limit: ", fail_wasted)
	print("========================================")
	print("")

	# Start on the next frame so the introduction can finish
	# hiding its CanvasLayer before the first throw begins.
	call_deferred("start_round")


func _reset_gameplay_values() -> void:
	phase = MiniRoundPhase.THROWING_BATCH

	current_round_index = 0
	current_pattern.clear()

	round_pieces.clear()
	removed_this_round = 0

	collected = 0
	wasted = 0
	combo = 0
	score = 0

	ending_started = false
	fail_screen_started = false
	result_emitted = false

	tongs_busy = false
	warning_was_active = false
	last_warning_wasted = -1

	_hide_tongs()
	_update_warning_ui()


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
			print(
				"DEBUG CHICHARON: "
				+ "Existing fail screen is valid."
			)
			return

		print(
			"DEBUG CHICHARON: Removing incorrect "
			+ "MinigameFailScreen node."
		)

		remove_child(existing_node)
		existing_node.queue_free()

	if FAIL_SCREEN_SCENE == null:
		push_error(
			"Chicharon fail-screen PackedScene "
			+ "could not be loaded."
		)
		return

	var new_fail_screen: Node = FAIL_SCREEN_SCENE.instantiate()

	if new_fail_screen == null:
		push_error(
			"Chicharon fail screen could not "
			+ "be instantiated."
		)
		return

	new_fail_screen.name = "MinigameFailScreen"
	add_child(new_fail_screen)
	fail_screen = new_fail_screen

	print(
		"DEBUG CHICHARON: Fail screen "
		+ "instantiated automatically."
	)


func _connect_fail_screen() -> void:
	if fail_screen == null:
		push_error("Chicharon fail screen is missing.")
		return

	if not fail_screen.has_signal("retry_requested"):
		push_error(
			"Chicharon fail screen is missing "
			+ "retry_requested."
		)
		return

	if not fail_screen.has_signal("exit_requested"):
		push_error(
			"Chicharon fail screen is missing "
			+ "exit_requested."
		)
		return

	var retry_callable: Callable = Callable(
		self,
		"_on_fail_retry_requested"
	)

	var exit_callable: Callable = Callable(
		self,
		"_on_fail_exit_requested"
	)

	if not fail_screen.is_connected(
		"retry_requested",
		retry_callable
	):
		fail_screen.connect(
			"retry_requested",
			retry_callable
		)

	if not fail_screen.is_connected(
		"exit_requested",
		exit_callable
	):
		fail_screen.connect(
			"exit_requested",
			exit_callable
		)

	print("DEBUG CHICHARON: Fail-screen signals connected.")


func _on_fail_retry_requested() -> void:
	print("DEBUG CHICHARON: Retry requested.")
	if get_tree().current_scene == self:
		get_tree().reload_current_scene()
	else:
		minigame_retry_requested.emit()


func _on_fail_exit_requested() -> void:
	if result_emitted:
		return

	result_emitted = true

	print("")
	print("========================================")
	print("DEBUG CHICHARON: EXIT AFTER FAILURE")
	print("Final score: ", score)
	print("========================================")
	print("")

	minigame_failed.emit(score)


func clear_remaining_chicharon() -> void:
	for piece in round_pieces:
		if is_instance_valid(piece):
			piece.queue_free()

	round_pieces.clear()

	for child in chicharon_container.get_children():
		if is_instance_valid(child):
			child.queue_free()


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

			print(
				"DEBUG CHICHARON: "
				+ "Existing ending scene is valid."
			)

			return

		print(
			"DEBUG CHICHARON: Removing incorrect "
			+ "CollectibleEndingScene node."
		)

		remove_child(existing_node)
		existing_node.queue_free()

	if ENDING_SCENE == null:
		push_error(
			"Chicharon ending PackedScene "
			+ "could not be loaded."
		)

		return

	var new_ending_scene: Node = (
		ENDING_SCENE.instantiate()
	)

	if new_ending_scene == null:
		push_error(
			"Chicharon ending scene "
			+ "could not be instantiated."
		)

		return

	new_ending_scene.name = "CollectibleEndingScene"
	add_child(new_ending_scene)

	ending_sequence = new_ending_scene

	print(
		"DEBUG CHICHARON: Ending scene "
		+ "instantiated automatically."
	)


func _connect_ending_sequence() -> void:
	if ending_sequence == null:
		push_error(
			"Chicharon ending sequence is missing."
		)

		return

	if not ending_sequence.has_method("start_ending"):
		push_error(
			"Chicharon ending scene is missing "
			+ "start_ending()."
		)

		return

	if not ending_sequence.has_signal("ending_finished"):
		push_error(
			"Chicharon ending scene is missing "
			+ "ending_finished."
		)

		return

	var finished_callable: Callable = Callable(
		self,
		"_on_ending_sequence_finished"
	)

	if not ending_sequence.is_connected(
		"ending_finished",
		finished_callable
	):
		ending_sequence.connect(
			"ending_finished",
			finished_callable
		)

		print(
			"DEBUG CHICHARON: ending_finished "
			+ "signal connected."
		)


func _start_success_ending() -> void:
	if ending_started or fail_screen_started:
		return

	if ending_sequence == null:
		_ensure_ending_sequence()
		_connect_ending_sequence()

	if ending_sequence == null:
		push_error(
			"Cannot start the Chicharon ending "
			+ "because the ending scene is missing."
		)
		return

	if not ending_sequence.has_method("start_ending"):
		push_error(
			"Cannot start the Chicharon ending "
			+ "because start_ending() is missing."
		)
		return

	if ENDING_COLLECTIBLE == null:
		push_error(
			"Chicharon ending collectible "
			+ "texture is missing."
		)
		return

	ending_started = true
	phase = MiniRoundPhase.GAME_OVER

	clear_remaining_chicharon()

	print("")
	print("========================================")
	print("DEBUG CHICHARON: STARTING SUCCESS ENDING")
	print("========================================")
	print("")

	ending_sequence.call(
		"start_ending",
		ENDING_COLLECTIBLE,
		ending_collectible_scale
	)


func _on_ending_sequence_finished() -> void:
	if result_emitted:
		return

	result_emitted = true

	print("")
	print("========================================")
	print("DEBUG CHICHARON: ENDING COMPLETED")
	print("Final score: ", score)
	print("========================================")
	print("")

	minigame_finished.emit()


func update_ui() -> void:
	var round_data_index: int = mini(
		current_round_index,
		round_defs.size() - 1
	)

	var difficulty: String = str(
		round_defs[round_data_index]["difficulty"]
	)

	round_label.text = (
		"ROUND "
		+ str(mini(current_round_index + 1, 5))
		+ " / 5  -  "
		+ difficulty.to_upper()
	)

	collected_label.text = (
		"COLLECTED\n"
		+ str(collected)
		+ " / "
		+ str(required_collected)
	)

	wasted_label.text = (
		"WASTED\n"
		+ str(wasted)
		+ " / "
		+ str(fail_wasted)
	)

	combo_label.text = (
		"COMBO\n"
		+ "x"
		+ str(combo)
	)

	if score_label != null:
		score_label.text = (
			"SCORE\n"
			+ str(score)
		)

	if combo_badge_sprite != null:
		combo_badge_sprite.visible = combo > 0

func show_feedback(message: String) -> void:
	feedback_label.text = message
	feedback_label.modulate.a = 1.0

	if (
		feedback_tween != null
		and feedback_tween.is_valid()
	):
		feedback_tween.kill()

	feedback_tween = create_tween()

	feedback_tween.tween_interval(0.20)

	feedback_tween.tween_property(
		feedback_label,
		"modulate:a",
		0.0,
		0.80
	)


# =========================================================
# CHICHARON VISUAL POLISH
# =========================================================

func _setup_polish_visuals() -> void:
	_setup_tongs()
	_setup_ui_polish()

	if (
		takeout_indicator != null
		and takeout_indicator.has_method("set_bpm")
	):
		takeout_indicator.call(
			"set_bpm",
			bpm
		)


func _setup_tongs() -> void:
	tongs_root = Node2D.new()
	tongs_root.name = "RuntimeTongs"
	tongs_root.z_index = 20
	add_child(tongs_root)

	tongs_back = Sprite2D.new()
	tongs_back.name = "TongsBack"
	tongs_back.texture = TONGS_BACK_TEXTURE
	tongs_back.z_index = 0
	tongs_root.add_child(tongs_back)

	tongs_front = Sprite2D.new()
	tongs_front.name = "TongsFront"
	tongs_front.texture = TONGS_FRONT_TEXTURE
	tongs_front.z_index = 2
	tongs_root.add_child(tongs_front)

	tongs_root.scale = tongs_scale
	tongs_root.rotation_degrees = tongs_rotation_degrees

	_hide_tongs()


func _setup_ui_polish() -> void:
	var ui_node: Node = get_node_or_null("UI")

	if ui_node == null:
		push_warning(
			"CHICHARON: UI node is missing. "
			+ "Polish frames were not created."
		)

		return

	ui_panel_sprite = Sprite2D.new()
	ui_panel_sprite.name = "RuntimeChicharonUIPanel"
	ui_panel_sprite.texture = CHICHARON_UI_PANEL_TEXTURE
	ui_panel_sprite.position = ui_panel_position
	ui_panel_sprite.scale = ui_panel_scale
	ui_panel_sprite.z_index = -20
	ui_node.add_child(ui_panel_sprite)

	round_banner_sprite = Sprite2D.new()
	round_banner_sprite.name = "RuntimeRoundBanner"
	round_banner_sprite.texture = ROUND_BANNER_TEXTURE
	round_banner_sprite.position = round_banner_position
	round_banner_sprite.scale = round_banner_scale
	round_banner_sprite.z_index = -20
	ui_node.add_child(round_banner_sprite)

	combo_badge_sprite = Sprite2D.new()
	combo_badge_sprite.name = "RuntimeComboBadge"
	combo_badge_sprite.texture = COMBO_BADGE_TEXTURE
	combo_badge_sprite.position = combo_badge_position
	combo_badge_sprite.scale = combo_badge_scale
	combo_badge_sprite.z_index = -20
	combo_badge_sprite.visible = false
	ui_node.add_child(combo_badge_sprite)

	warning_panel_sprite = Sprite2D.new()
	warning_panel_sprite.name = "RuntimeWarningPanel"
	warning_panel_sprite.texture = WARNING_PANEL_TEXTURE
	warning_panel_sprite.position = warning_panel_position
	warning_panel_sprite.scale = warning_panel_scale
	warning_panel_sprite.z_index = 40
	warning_panel_sprite.visible = false
	ui_node.add_child(warning_panel_sprite)

	# -----------------------------------------------------
	# HUD LABELS
	# -----------------------------------------------------

	_configure_hud_label(
		collected_label,
		ui_panel_position + collected_label_offset,
		hud_label_size,
		hud_label_font_size
	)

	_configure_hud_label(
		wasted_label,
		ui_panel_position + wasted_label_offset,
		hud_label_size,
		hud_label_font_size
	)

	_configure_hud_label(
		combo_label,
		ui_panel_position + combo_label_offset,
		hud_label_size,
		hud_label_font_size
	)

	score_label = Label.new()
	score_label.name = "RuntimeScoreLabel"

	_configure_hud_label(
		score_label,
		ui_panel_position + score_label_offset,
		hud_label_size,
		hud_label_font_size
	)

	ui_node.add_child(score_label)

	_configure_hud_label(
		round_label,
		round_banner_position + round_label_offset,
		round_label_size,
		round_label_font_size
	)

	round_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	round_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	# Feedback keeps its scene position but uses the shared VCR font.
	_apply_vcr_font_to_label(
		feedback_label,
		feedback_label_font_size
	)

	feedback_label.z_index = 30

	# -----------------------------------------------------
	# WARNING LABEL
	# -----------------------------------------------------

	warning_label = Label.new()
	warning_label.name = "RuntimeWarningLabel"
	warning_label.text = (
		"CAREFUL! TOO MUCH IS BEING WASTED!"
	)
	warning_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	warning_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)
	warning_label.position = (
		warning_panel_position
		+ Vector2(-250.0, -20.0)
	)
	warning_label.size = Vector2(500.0, 70.0)
	warning_label.z_index = 41
	warning_label.visible = false

	_apply_vcr_font_to_label(
		warning_label,
		20
	)

	warning_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.88, 0.55, 1.0)
	)

	ui_node.add_child(warning_label)


func _configure_hud_label(
	label: Label,
	new_position: Vector2,
	new_size: Vector2,
	font_size: int
) -> void:
	if label == null:
		return

	label.position = new_position
	label.size = new_size

	label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	label.autowrap_mode = (
		TextServer.AUTOWRAP_OFF
	)

	label.z_index = 10

	_apply_vcr_font_to_label(
		label,
		font_size
	)


func _apply_vcr_font_to_label(
	label: Label,
	font_size: int
) -> void:
	if label == null:
		return

	var vcr_font: Font = (
		load(VCR_FONT_PATH) as Font
	)

	if vcr_font != null:
		label.add_theme_font_override(
			"font",
			vcr_font
		)

	label.add_theme_font_size_override(
		"font_size",
		font_size
	)

	label.add_theme_color_override(
		"font_color",
		Color(0.97, 0.90, 0.73, 1.0)
	)

	label.add_theme_color_override(
		"font_shadow_color",
		Color(0.08, 0.04, 0.02, 1.0)
	)

	label.add_theme_constant_override(
		"shadow_offset_x",
		2
	)

	label.add_theme_constant_override(
		"shadow_offset_y",
		2
	)

func _animate_tongs_and_take(
	target: Node,
	take_result: String
) -> void:
	if tongs_busy:
		return

	if not is_instance_valid(target):
		return

	tongs_busy = true

	var target_2d: Node2D = target as Node2D

	if target_2d != null:
		target_2d.z_index = 21

	var takeout_center: Vector2 = (
		_get_takeout_center_position()
	)

	tongs_root.global_position = (
		takeout_center
		+ tongs_rest_offset
	)

	tongs_root.scale = tongs_scale
	tongs_root.rotation_degrees = (
		tongs_rotation_degrees
	)
	tongs_root.visible = true

	_play_one_shot(
		SFX_TONGS_SNAP,
		sfx_volume_db,
		1.0
	)

	var strike_tween: Tween = create_tween()

	strike_tween.tween_property(
		tongs_root,
		"global_position",
		takeout_center
		+ tongs_take_offset,
		tongs_strike_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	await strike_tween.finished

	if not is_instance_valid(target):
		_hide_tongs()
		tongs_busy = false
		return

	# Feedback and gameplay resolution use the SAME result that was
	# captured on the input frame.
	_show_take_result(
		take_result
	)

	if take_result == "burnt":
		_play_one_shot(
			SFX_TONGS_MISS,
			sfx_volume_db,
			1.0
		)
	else:
		_play_one_shot(
			SFX_TONGS_GRAB,
			sfx_volume_db - 2.0,
			1.0
		)

	if target.has_method("resolve_take_result"):
		target.call(
			"resolve_take_result",
			take_result
		)

	elif target.has_method("try_take"):
		# Compatibility fallback for an older piece script.
		target.call("try_take")

	var retract_tween: Tween = create_tween()

	retract_tween.tween_property(
		tongs_root,
		"global_position",
		takeout_center
		+ tongs_rest_offset,
		tongs_retract_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	await retract_tween.finished

	_hide_tongs()
	tongs_busy = false

func _show_take_result(
	cook_state_name: String
) -> void:
	match cook_state_name:
		"perfect":
			_spawn_feedback_popup(
				PERFECT_POPUP
			)

			_spawn_big_oil_splash()

			var perfect_stream: AudioStream = (
				SFX_TAKEOUT_PERFECT_01
				if randi() % 2 == 0
				else SFX_TAKEOUT_PERFECT_02
			)

			_play_one_shot(
				perfect_stream,
				sfx_volume_db,
				1.0
			)

			if takeout_indicator.has_method("flash_result"):
				takeout_indicator.call(
					"flash_result",
					"perfect"
				)

		"slightly_cooked":
			_spawn_feedback_popup(
				UNDERCOOKED_POPUP
			)

			_play_one_shot(
				SFX_TAKEOUT_UNDERCOOKED,
				sfx_volume_db,
				1.0
			)

			if takeout_indicator.has_method("flash_result"):
				takeout_indicator.call(
					"flash_result",
					"miss"
				)

		"burnt":
			_spawn_feedback_popup(
				BURNT_POPUP
			)

			if takeout_indicator.has_method("flash_result"):
				takeout_indicator.call(
					"flash_result",
					"burnt"
				)

		_:
			_spawn_feedback_popup(
				TOO_RAW_POPUP
			)

			_play_one_shot(
				SFX_TAKEOUT_RAW,
				sfx_volume_db,
				1.0
			)

			if takeout_indicator.has_method("flash_result"):
				takeout_indicator.call(
					"flash_result",
					"miss"
				)


func _spawn_feedback_popup(
	texture: Texture2D
) -> void:
	if texture == null:
		return

	var popup: Sprite2D = Sprite2D.new()

	popup.texture = texture
	popup.global_position = (
		_get_takeout_center_position()
		+ popup_offset
	)
	popup.scale = popup_scale * 0.70
	popup.modulate = Color.WHITE
	popup.z_index = 100

	add_child(popup)

	var target_position: Vector2 = (
		popup.global_position
		+ Vector2(
			0.0,
			-popup_rise_distance
		)
	)

	var tween: Tween = create_tween()

	tween.tween_property(
		popup,
		"scale",
		popup_scale * 1.10,
		0.10
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		popup,
		"scale",
		popup_scale,
		0.07
	)

	tween.set_parallel(true)

	tween.tween_property(
		popup,
		"global_position",
		target_position,
		0.45
	)

	tween.tween_property(
		popup,
		"modulate:a",
		0.0,
		0.45
	).set_delay(
		0.12
	)

	await tween.finished

	if is_instance_valid(popup):
		popup.queue_free()


func _spawn_big_oil_splash() -> void:
	var splash: Sprite2D = Sprite2D.new()

	splash.texture = OIL_SPLASH_BIG
	splash.global_position = (
		_get_takeout_center_position()
		+ big_splash_offset
	)
	splash.scale = big_splash_scale * 0.50
	splash.modulate = Color.WHITE
	splash.z_index = 19

	add_child(splash)

	_play_one_shot(
		SFX_OIL_SPLASH_BIG,
		sfx_volume_db - 2.0,
		1.0
	)

	var tween: Tween = create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		splash,
		"scale",
		big_splash_scale * 1.10,
		0.24
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		splash,
		"modulate:a",
		0.0,
		0.32
	).set_delay(
		0.08
	)

	await tween.finished

	if is_instance_valid(splash):
		splash.queue_free()


func _hide_tongs() -> void:
	if tongs_root == null:
		return

	tongs_root.visible = false


func _pulse_round_banner() -> void:
	if round_banner_sprite == null:
		return

	round_banner_sprite.scale = (
		round_banner_scale * 0.92
	)

	var tween: Tween = create_tween()

	tween.tween_property(
		round_banner_sprite,
		"scale",
		round_banner_scale * 1.06,
		0.12
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		round_banner_sprite,
		"scale",
		round_banner_scale,
		0.10
	)


func _pulse_combo_badge() -> void:
	if combo_badge_sprite == null:
		return

	combo_badge_sprite.visible = combo > 0

	if (
		combo_tween != null
		and combo_tween.is_valid()
	):
		combo_tween.kill()

	combo_badge_sprite.scale = combo_badge_scale

	combo_tween = create_tween()

	combo_tween.tween_property(
		combo_badge_sprite,
		"scale",
		combo_badge_scale * 1.25,
		0.09
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	combo_tween.tween_property(
		combo_badge_sprite,
		"scale",
		combo_badge_scale * 0.95,
		0.06
	)

	combo_tween.tween_property(
		combo_badge_sprite,
		"scale",
		combo_badge_scale,
		0.06
	)


func _update_warning_ui() -> void:
	if (
		warning_panel_sprite == null
		or warning_label == null
	):
		return

	var warning_active: bool = (
		wasted >= 5
		and wasted < fail_wasted
	)

	warning_panel_sprite.visible = warning_active
	warning_label.visible = warning_active

	if not warning_active:
		warning_was_active = false
		return

	if (
		not warning_was_active
		or last_warning_wasted != wasted
	):
		_play_one_shot(
			SFX_WARNING_NEAR_FAIL,
			sfx_volume_db,
			1.0
		)

	warning_was_active = true
	last_warning_wasted = wasted

	if (
		warning_tween != null
		and warning_tween.is_valid()
	):
		warning_tween.kill()

	var pulse_strength: float = (
		1.12
		if wasted >= 6
		else 1.06
	)

	warning_panel_sprite.scale = warning_panel_scale

	warning_tween = create_tween()
	warning_tween.set_loops(2)

	warning_tween.tween_property(
		warning_panel_sprite,
		"scale",
		warning_panel_scale * pulse_strength,
		0.12
	)

	warning_tween.tween_property(
		warning_panel_sprite,
		"scale",
		warning_panel_scale,
		0.12
	)


# =========================================================
# CHICHARON AUDIO
# =========================================================

func _setup_audio() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "RuntimeMusicPlayer"
	music_player.stream = BGM_CHICHARON

	if music_player.stream is AudioStreamOggVorbis:
		(
			music_player.stream
			as AudioStreamOggVorbis
		).loop = true

	music_player.volume_db = music_volume_db
	add_child(music_player)

	ambience_player = AudioStreamPlayer.new()
	ambience_player.name = "RuntimeAmbiencePlayer"
	ambience_player.stream = AMB_FRYING_OIL

	if ambience_player.stream is AudioStreamOggVorbis:
		(
			ambience_player.stream
			as AudioStreamOggVorbis
		).loop = true

	ambience_player.volume_db = ambience_volume_db
	add_child(ambience_player)

	one_shot_players.clear()

	for index in range(
		maxi(
			audio_one_shot_player_count,
			1
		)
	):
		var player: AudioStreamPlayer = (
			AudioStreamPlayer.new()
		)

		player.name = (
			"RuntimeOneShot"
			+ str(index + 1)
		)

		add_child(player)

		one_shot_players.append(player)


func _start_game_audio() -> void:
	if music_player != null:
		music_player.volume_db = music_volume_db

		if not music_player.playing:
			music_player.play()

	if ambience_player != null:
		ambience_player.volume_db = ambience_volume_db

		if not ambience_player.playing:
			ambience_player.play()


func _fade_out_game_audio() -> void:
	for player in [
		music_player,
		ambience_player
	]:
		if player == null:
			continue

		if not player.playing:
			continue

		var tween: Tween = create_tween()

		tween.tween_property(
			player,
			"volume_db",
			-60.0,
			0.80
		)

		tween.tween_callback(
			Callable(
				player,
				"stop"
			)
		)


func _play_one_shot(
	stream: AudioStream,
	volume_db: float,
	pitch_scale: float = 1.0
) -> void:
	if stream == null:
		return

	var selected_player: AudioStreamPlayer = null

	for player in one_shot_players:
		if not player.playing:
			selected_player = player
			break

	if selected_player == null:
		selected_player = one_shot_players[0]

	selected_player.stop()
	selected_player.stream = stream
	selected_player.volume_db = volume_db
	selected_player.pitch_scale = pitch_scale
	selected_player.play()
