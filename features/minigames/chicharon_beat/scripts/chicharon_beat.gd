extends Node2D

signal minigame_finished
signal minigame_failed(score: int)
signal minigame_retry_requested

enum RoundPhase {
	WAITING,
	ACTIVE,
	ROUND_END,
	GAME_OVER,
}

const CHICHARON_SCENE: PackedScene = preload(
	"res://features/minigames/chicharon_beat/scenes/chicharon_piece.tscn"
)
const VCR_FONT: Font = preload(
	"res://features/minigames/shared/fonts/VCR_OSD_MONO_1.001.ttf"
)
const FAIL_SCREEN_SCENE: PackedScene = preload(
	"res://features/minigames/fail_screen/scenes/minigame_fail_screen.tscn"
)

const PERFORMANCE_PANEL: Texture2D = preload(
	"res://features/minigames/chicharon_beat/assets/ui/chicharon_performance_panel.png"
)
const ROUND_PANEL: Texture2D = preload(
	"res://features/minigames/chicharon_beat/assets/ui/chicharon_round_panel.png"
)
const ROUND_COMPLETE: Texture2D = preload(
	"res://features/minigames/chicharon_beat/assets/ui/chicharon_round_complete.png"
)
const COMBO_COUNTER: Texture2D = preload(
	"res://features/minigames/chicharon_beat/assets/ui/chicharon_combo_counter.png"
)

const PERFECT_POPUP: Texture2D = preload(
	"res://features/minigames/chicharon_beat/assets/feedback/perfect_text_popup.png"
)
const TOO_RAW_POPUP: Texture2D = preload(
	"res://features/minigames/chicharon_beat/assets/feedback/too_raw_text_popup.png"
)
const UNDERCOOKED_POPUP: Texture2D = preload(
	"res://features/minigames/chicharon_beat/assets/feedback/undercooked_text_popup.png"
)
const BURNT_POPUP: Texture2D = preload(
	"res://features/minigames/chicharon_beat/assets/feedback/burnt_text_popup.png"
)
const TONGS_BACK: Texture2D = preload(
	"res://features/minigames/chicharon_beat/assets/tongs/tongs_back.png"
)
const TONGS_FRONT: Texture2D = preload(
	"res://features/minigames/chicharon_beat/assets/tongs/tongs_front.png"
)

const BGM: AudioStream = preload(
	"res://features/minigames/chicharon_beat/assets/audio/music/bgm_chicharon_beat_loop.ogg"
)
const AMBIENCE: AudioStream = preload(
	"res://features/minigames/chicharon_beat/assets/audio/ambience/amb_frying_oil_loop.ogg"
)
const SFX_PERFECT_1: AudioStream = preload(
	"res://features/minigames/chicharon_beat/assets/audio/sfx/sfx_takeout_perfect_01.wav"
)
const SFX_PERFECT_2: AudioStream = preload(
	"res://features/minigames/chicharon_beat/assets/audio/sfx/sfx_takeout_perfect_02.wav"
)
const SFX_RAW: AudioStream = preload(
	"res://features/minigames/chicharon_beat/assets/audio/sfx/sfx_takeout_raw.wav"
)
const SFX_UNDERCOOKED: AudioStream = preload(
	"res://features/minigames/chicharon_beat/assets/audio/sfx/sfx_takeout_undercooked.wav"
)
const SFX_TONGS_SNAP: AudioStream = preload(
	"res://features/minigames/chicharon_beat/assets/audio/sfx/sfx_tongs_snap.wav"
)
const SFX_TONGS_GRAB: AudioStream = preload(
	"res://features/minigames/chicharon_beat/assets/audio/sfx/sfx_tongs_grab.wav"
)
const SFX_TONGS_MISS: AudioStream = preload(
	"res://features/minigames/chicharon_beat/assets/audio/sfx/sfx_tongs_miss.wav"
)
const SFX_COMBO_UP: AudioStream = preload(
	"res://features/minigames/chicharon_beat/assets/audio/sfx/sfx_combo_up.wav"
)
const SFX_COMBO_BREAK: AudioStream = preload(
	"res://features/minigames/chicharon_beat/assets/audio/sfx/sfx_combo_break.wav"
)
const SFX_ROUND_START: AudioStream = preload(
	"res://features/minigames/chicharon_beat/assets/audio/sfx/sfx_round_start.wav"
)
const SFX_ROUND_COMPLETE: AudioStream = preload(
	"res://features/minigames/chicharon_beat/assets/audio/sfx/sfx_round_complete.wav"
)
const SFX_WARNING: AudioStream = preload(
	"res://features/minigames/chicharon_beat/assets/audio/sfx/sfx_warning_near_fail.wav"
)
const SFX_SUCCESS: AudioStream = preload(
	"res://features/minigames/chicharon_beat/assets/audio/sfx/sfx_success_transition.wav"
)
const SFX_FAILURE: AudioStream = preload(
	"res://features/minigames/chicharon_beat/assets/audio/sfx/sfx_failure_transition.wav"
)

const VIEWPORT_SIZE := Vector2(1152.0, 648.0)
const HUD_CANVAS_LAYER := 90
const PERFORMANCE_ORIGIN := Vector2(8.0, 8.0)
const ROUND_ORIGIN := Vector2(369.0, 4.0)
const COMBO_ORIGIN := Vector2(940.0, 42.0)
const TAKEOUT_CENTER := Vector2(576.0, 287.0)

const ROUND_LINES := [
	{
		"text": "Good start. Keep your eyes on the needles; the next batch is quicker.",
		"expression": "happy",
	},
	{
		"text": "Nice rhythm. The pieces will come closer together now.",
		"expression": "happy",
	},
	{
		"text": "Halfway through. Stay calm when two needles are close.",
		"expression": "concerned",
	},
	{
		"text": "One batch left. Watch the bar and do not rush the tongs.",
		"expression": "concerned",
	},
]

const RESULT_LINES := {
	"wasted_raw": {
		"text": "Too soon. Let the green reach the needle before taking it out.",
		"expression": "concerned",
	},
	"wasted_slightly": {
		"text": "Almost there, but it still needed a little more time in the oil.",
		"expression": "concerned",
	},
	"burnt": {
		"text": "Too late! Once the green reaches a needle, take that piece out.",
		"expression": "angry",
	},
}

@export_category("Round Timing")
@export var bpm := 250.0
@export var travel_beats := 12.0
@export var throw_duration := 0.55
@export var end_padding := 0.70
@export var perfect_window_seconds := 0.42
@export var raw_early_seconds := 0.75

@export_category("Goals")
@export var required_collected := 18
@export var fail_wasted := 7

@export_category("Visuals")
@export var popup_scale := Vector2(0.22, 0.22)
@export var tongs_scale := Vector2(0.20, 0.20)
@export var tongs_rotation_degrees := -43.0

@onready var chicharon_container: Node2D = $ChicharonContainer
@onready var throw_start_point: Marker2D = $ThrowStartPoint
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var takeout_point: Marker2D = $TakeOutPoint
@onready var takeout_indicator: Node2D = $TakeOutIndicator
@onready var ui: CanvasLayer = $UI
@onready var round_label: Label = $UI/RoundLabel
@onready var collected_label: Label = $UI/CollectedLabel
@onready var wasted_label: Label = $UI/WastedLabel
@onready var highest_combo_label: Label = $UI/ComboLabel
@onready var feedback_label: Label = $UI/FeedbackLabel
@onready var dialogue: SharedDialogue = $SharedDialogue

var round_defs: Array[Dictionary] = [
	{"difficulty": "easy"},
	{"difficulty": "medium"},
	{"difficulty": "medium"},
	{"difficulty": "hard"},
	{"difficulty": "hard"},
]
var easy_patterns: Array = [[3, 3, 3], [3, 4, 3], [4, 3, 3]]
var medium_patterns: Array = [
	[3, 2, 3, 2], [2, 3, 2, 3], [3, 3, 2, 2],
	[2, 3, 3, 2], [3, 2, 2, 3], [2, 2, 3, 3],
]
var hard_patterns: Array = [
	[2, 2, 2, 2], [2, 2, 3, 2], [2, 3, 2, 2],
	[3, 2, 2, 2], [2, 2, 2, 3], [2, 3, 2, 3],
]

var phase := RoundPhase.WAITING
var current_round_index := 0
var current_pattern: Array = []
var round_pieces: Array[Node] = []
var piece_indices: Dictionary = {}
var target_times: Array[float] = []
var resolved_indices: Dictionary = {}
var expected_pieces := 0
var removed_this_round := 0

var collected := 0
var wasted := 0
var combo := 0
var highest_combo := 0
var score := 0

var gameplay_active := false
var dialogue_paused := false
var dialogue_is_blocking := false
var dialogue_context := ""
var trial_active := false
var trial_result := ""
var waiting_for_round_continue := false
var countdown_active := false
var result_dialogue_seen: Dictionary = {}
var warning_level_shown := 0
var result_emitted := false
var tongs_busy := false

var score_label: Label
var difficulty_label: Label
var combo_counter_label: Label
var performance_sprite: Sprite2D
var round_panel_sprite: Sprite2D
var round_complete_sprite: Sprite2D
var round_complete_layer: CanvasLayer
var round_complete_root: Control
var combo_counter_sprite: Sprite2D
var tongs_root: Node2D
var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var fail_screen: Node


func _ready() -> void:
	randomize()
	SharedCursor.install()
	# The shared minigame session renders gameplay on CanvasLayer 80. Keep the
	# performance HUD above it and below SharedDialogue on layer 100.
	ui.layer = HUD_CANVAS_LAYER
	_setup_hud()
	_setup_tongs()
	_setup_audio()
	_setup_fail_screen()
	dialogue.dialogue_started.connect(_on_dialogue_started)
	dialogue.dialogue_finished.connect(_on_dialogue_finished)
	takeout_indicator.position = TAKEOUT_CENTER
	takeout_indicator.visible = false
	feedback_label.visible = false
	_reset_game()


func _input(event: InputEvent) -> void:
	if dialogue_is_blocking or not gameplay_active:
		return
	if waiting_for_round_continue:
		var continue_pressed := event.is_action_pressed("ui_accept")
		if event is InputEventMouseButton:
			continue_pressed = (
				event.button_index == MOUSE_BUTTON_LEFT
				and event.pressed
			)
		if continue_pressed:
			_start_round_countdown()
			get_viewport().set_input_as_handled()
		return
	if phase != RoundPhase.ACTIVE or tongs_busy:
		return

	var take_pressed := event.is_action_pressed("ui_accept")
	if event is InputEventMouseButton:
		take_pressed = (
			event.button_index == MOUSE_BUTTON_LEFT
			and event.pressed
		)
	if take_pressed:
		_try_take_chicharon()
		get_viewport().set_input_as_handled()


func _reset_game() -> void:
	_clear_pieces()
	phase = RoundPhase.WAITING
	current_round_index = 0
	current_pattern.clear()
	target_times.clear()
	resolved_indices.clear()
	expected_pieces = 0
	removed_this_round = 0
	collected = 0
	wasted = 0
	combo = 0
	highest_combo = 0
	score = 0
	gameplay_active = false
	dialogue_paused = false
	dialogue_is_blocking = false
	dialogue_context = ""
	trial_active = false
	trial_result = ""
	waiting_for_round_continue = false
	countdown_active = false
	result_dialogue_seen.clear()
	warning_level_shown = 0
	result_emitted = false
	tongs_busy = false
	takeout_indicator.call("reset_indicator")
	takeout_indicator.visible = false
	round_complete_root.visible = false
	_hide_tongs()
	_update_ui()


func _begin_gameplay() -> void:
	gameplay_active = true
	phase = RoundPhase.WAITING
	_start_audio()
	_start_trial_run()


func _start_trial_run() -> void:
	trial_active = true
	trial_result = ""
	phase = RoundPhase.ACTIVE
	round_pieces.clear()
	piece_indices.clear()
	resolved_indices.clear()
	target_times.clear()
	removed_this_round = 0
	expected_pieces = 1

	var seconds_per_beat := 60.0 / maxf(bpm, 1.0)
	var float_duration := travel_beats * seconds_per_beat
	var target_time := throw_duration + float_duration
	var trial_duration := target_time + end_padding
	target_times.append(target_time)
	takeout_indicator.call(
		"configure_round", [target_time / trial_duration], trial_duration
	)
	takeout_indicator.visible = true
	takeout_indicator.call("start_sweep")
	round_label.text = "TRIAL RUN"
	difficulty_label.text = "PRACTICE"
	_play_sound(SFX_ROUND_START, -6.0)
	_spawn_piece(0, float_duration)


func _finish_trial_run(result: String) -> void:
	if not trial_active:
		return
	trial_active = false
	trial_result = result
	phase = RoundPhase.WAITING
	takeout_indicator.call("stop_sweep")
	var text := "You felt the timing. Now follow every needle in the real batches."
	var expression := "concerned"
	if result == "collected":
		text = "That's it! Now keep that rhythm through the real batches."
		expression = "happy"
	_prepare_round_continue(text, expression)


func _prepare_round_continue(vendor_text: String, expression: String) -> void:
	phase = RoundPhase.WAITING
	waiting_for_round_continue = true
	countdown_active = false
	takeout_indicator.call("stop_sweep")
	takeout_indicator.visible = false
	round_label.text = "ROUND %d / %d" % [
		current_round_index + 1,
		round_defs.size(),
	]
	difficulty_label.text = "CLICK / SPACE"
	_show_vendor_line(vendor_text, expression, "passive")


func _start_round_countdown() -> void:
	if not waiting_for_round_continue or countdown_active:
		return
	waiting_for_round_continue = false
	countdown_active = true
	phase = RoundPhase.WAITING
	for count: int in [3, 2, 1]:
		round_label.text = str(count)
		difficulty_label.text = "GET READY"
		_play_sound(
			SFX_ROUND_START,
			-6.0,
			0.88 + float(3 - count) * 0.08
		)
		await get_tree().create_timer(0.42).timeout
		if phase == RoundPhase.GAME_OVER:
			countdown_active = false
			return
	countdown_active = false
	_start_round()


func _start_round() -> void:
	if not gameplay_active or current_round_index >= round_defs.size():
		return
	phase = RoundPhase.ACTIVE
	round_pieces.clear()
	piece_indices.clear()
	resolved_indices.clear()
	target_times.clear()
	removed_this_round = 0

	var difficulty := str(round_defs[current_round_index]["difficulty"])
	current_pattern = _choose_pattern(difficulty)
	var seconds_per_beat := 60.0 / maxf(bpm, 1.0)
	var float_duration := travel_beats * seconds_per_beat
	var spawn_offsets: Array[float] = [0.0]
	var running_offset := 0.0
	for gap: Variant in current_pattern:
		running_offset += float(gap) * seconds_per_beat
		spawn_offsets.append(running_offset)

	for spawn_offset: float in spawn_offsets:
		target_times.append(spawn_offset + throw_duration + float_duration)
	expected_pieces = target_times.size()
	var round_duration := target_times[-1] + end_padding
	var normalized_targets: Array[float] = []
	for target_time: float in target_times:
		normalized_targets.append(target_time / round_duration)

	takeout_indicator.call(
		"configure_round", normalized_targets, round_duration
	)
	takeout_indicator.visible = true
	takeout_indicator.call("start_sweep")
	_update_ui()
	_spawn_round_pieces(spawn_offsets, float_duration)


func _spawn_round_pieces(
	spawn_offsets: Array[float],
	float_duration: float
) -> void:
	var previous_offset := 0.0
	for index: int in range(spawn_offsets.size()):
		var wait_duration := spawn_offsets[index] - previous_offset
		if wait_duration > 0.0:
			await _wait_active_seconds(wait_duration)
		if phase != RoundPhase.ACTIVE or not gameplay_active:
			return
		_spawn_piece(index, float_duration)
		previous_offset = spawn_offsets[index]


func _wait_active_seconds(seconds: float) -> void:
	var remaining := seconds
	while remaining > 0.0 and phase == RoundPhase.ACTIVE:
		await get_tree().process_frame
		if not dialogue_paused:
			remaining -= get_process_delta_time()


func _spawn_piece(index: int, float_duration: float) -> void:
	var piece := CHICHARON_SCENE.instantiate()
	chicharon_container.add_child(piece)
	var land_position := spawn_point.global_position + Vector2(
		0.0, randf_range(-10.0, 10.0)
	)
	piece.call(
		"setup_for_batch",
		throw_start_point.global_position,
		land_position,
		takeout_point.global_position,
		float_duration,
		throw_duration
	)
	piece.connect(
		"removed",
		Callable(self, "_on_chicharon_removed").bind(piece)
	)
	round_pieces.append(piece)
	piece_indices[piece.get_instance_id()] = index


func _try_take_chicharon() -> void:
	var target := _get_input_target()
	if target == null:
		_play_sound(SFX_TONGS_MISS, -5.0)
		if combo > 0:
			combo = 0
			_play_sound(SFX_COMBO_BREAK, -5.0)
			_update_ui()
		return

	var piece_id := target.get_instance_id()
	var needle_index := int(piece_indices.get(piece_id, -1))
	if needle_index < 0 or needle_index >= target_times.size():
		return
	var result := _judge_takeout(target_times[needle_index])
	if not bool(target.call("lock_for_takeout")):
		return
	_animate_tongs_and_resolve(target, result, needle_index)


func _get_input_target() -> Node:
	var best_piece: Node
	var best_difference := INF
	var elapsed := float(takeout_indicator.call("get_elapsed_time"))
	for piece: Node in round_pieces:
		if not is_instance_valid(piece):
			continue
		if not bool(piece.call("is_active_for_input")):
			continue
		var index := int(piece_indices.get(piece.get_instance_id(), -1))
		if index < 0 or resolved_indices.has(index):
			continue
		var difference := absf(target_times[index] - elapsed)
		if difference < best_difference:
			best_difference = difference
			best_piece = piece
	return best_piece


func _judge_takeout(target_time: float) -> String:
	var elapsed := float(takeout_indicator.call("get_elapsed_time"))
	var difference := elapsed - target_time
	if absf(difference) <= perfect_window_seconds:
		return "perfect"
	if difference < -raw_early_seconds:
		return "raw"
	if difference < 0.0:
		return "slightly_cooked"
	return "burnt"


func _animate_tongs_and_resolve(
	target: Node,
	result: String,
	needle_index: int
) -> void:
	tongs_busy = true
	_play_sound(SFX_TONGS_SNAP, -4.0)
	var target_2d := target as Node2D
	var target_position := target_2d.global_position
	tongs_root.global_position = target_position + Vector2(150.0, -125.0)
	tongs_root.visible = true
	var strike := create_tween()
	strike.tween_property(
		tongs_root,
		"global_position",
		target_position + Vector2(25.0, -30.0),
		0.09
	)
	await strike.finished
	if not is_instance_valid(target):
		_hide_tongs()
		tongs_busy = false
		return

	takeout_indicator.call("flash_result", result, needle_index)
	resolved_indices[needle_index] = true
	_show_result_popup(result, target_position)
	_play_result_sound(result)
	target.call("resolve_take_result", result)

	var retract := create_tween()
	retract.tween_property(
		tongs_root,
		"global_position",
		target_position + Vector2(165.0, -145.0),
		0.16
	)
	await retract.finished
	_hide_tongs()
	tongs_busy = false


func _on_chicharon_removed(reason: String, piece: Node) -> void:
	var piece_id := piece.get_instance_id()
	var needle_index := int(piece_indices.get(piece_id, -1))
	var was_manually_resolved := resolved_indices.has(needle_index)
	if reason == "burnt" and not was_manually_resolved:
		var burnt_piece := piece as Node2D
		if burnt_piece != null:
			_show_result_popup("burnt", burnt_piece.global_position)
		if needle_index >= 0:
			takeout_indicator.call(
				"flash_result", "burnt", needle_index
			)
	if needle_index >= 0:
		resolved_indices[needle_index] = true
		takeout_indicator.call("mark_resolved", needle_index)
	removed_this_round += 1
	if trial_active:
		_finish_trial_run(reason)
		return
	var previous_combo := combo

	match reason:
		"collected":
			collected += 1
			combo += 1
			highest_combo = maxi(highest_combo, combo)
			score += 300 + combo * 10
			_play_sound(SFX_COMBO_UP, -7.0, 1.0 + minf(combo * 0.03, 0.18))
		"wasted_raw":
			wasted += 1
			combo = 0
			score = maxi(score - 50, 0)
		"wasted_slightly":
			wasted += 1
			combo = 0
			score = maxi(score - 25, 0)
		"burnt":
			wasted += 1
			combo = 0

	if previous_combo > 0 and combo == 0:
		_play_sound(SFX_COMBO_BREAK, -5.0)
	_update_ui()

	if wasted >= fail_wasted:
		_end_game(false, "too_many_wasted")
		return
	if removed_this_round >= expected_pieces:
		_finish_round()
		return
	_show_result_or_warning_dialogue(reason)


func _show_result_or_warning_dialogue(reason: String) -> void:
	if wasted >= 6 and warning_level_shown < 6:
		warning_level_shown = 6
		_play_sound(SFX_WARNING, -4.0)
		_show_vendor_line(
			"One more mistake and this entire batch is ruined!",
			"super_angry",
			"warning"
		)
		return
	if wasted >= 5 and warning_level_shown < 5:
		warning_level_shown = 5
		_play_sound(SFX_WARNING, -4.0)
		_show_vendor_line(
			"Five pieces wasted already. You only have two chances left.",
			"angry",
			"warning"
		)
		return
	if reason == "collected" and combo == 3 and not result_dialogue_seen.has("combo"):
		result_dialogue_seen["combo"] = true
		_show_vendor_line("That's the rhythm! Keep following the needles.", "happy", "feedback")
		return
	if RESULT_LINES.has(reason) and not result_dialogue_seen.has(reason):
		result_dialogue_seen[reason] = true
		var line: Dictionary = RESULT_LINES[reason]
		_show_vendor_line(str(line["text"]), str(line["expression"]), "feedback")


func _finish_round() -> void:
	if phase != RoundPhase.ACTIVE:
		return
	phase = RoundPhase.ROUND_END
	takeout_indicator.call("stop_sweep")
	round_complete_root.visible = true
	_play_sound(SFX_ROUND_COMPLETE, -4.0)
	_finish_round_sequence(current_round_index)


func _finish_round_sequence(completed_round_index: int) -> void:
	await get_tree().create_timer(1.15).timeout
	if phase != RoundPhase.ROUND_END:
		return
	round_complete_root.visible = false

	if completed_round_index >= round_defs.size() - 1:
		if collected >= required_collected:
			_end_game(true)
		else:
			_end_game(false, "not_enough_collected")
		return

	current_round_index += 1
	var line: Dictionary = ROUND_LINES[completed_round_index]
	_prepare_round_continue(
		str(line["text"]),
		str(line["expression"])
	)


func _end_game(success: bool, failure_type := "not_enough_collected") -> void:
	if phase == RoundPhase.GAME_OVER:
		return
	phase = RoundPhase.GAME_OVER
	gameplay_active = false
	waiting_for_round_continue = false
	countdown_active = false
	takeout_indicator.call("stop_sweep")
	_clear_pieces()
	_hide_tongs()
	_stop_audio()
	if success:
		_play_sound(SFX_SUCCESS, -4.0)
		_show_vendor_line(
			"Excellent work! Crisp, golden, and barely a piece wasted.",
			"happy",
			"success"
		)
		return

	_play_sound(SFX_FAILURE, -4.0)
	var fail_dialogue := "There isn't enough good chicharon for the order. We have to start again."
	var fail_reason := "You did not collect enough good chicharon for the order."
	if failure_type == "too_many_wasted":
		fail_dialogue = "That's enough! Too much chicharon was wasted. This batch is ruined."
		fail_reason = "Too many pieces of chicharon were wasted."
	fail_screen.call(
		"start_fail_screen",
		fail_dialogue,
		fail_reason,
		score,
		true
	)


func _setup_fail_screen() -> void:
	fail_screen = FAIL_SCREEN_SCENE.instantiate()
	fail_screen.name = "MinigameFailScreen"
	add_child(fail_screen)
	fail_screen.connect(
		"retry_requested",
		Callable(self, "_on_fail_retry_requested")
	)
	fail_screen.connect(
		"exit_requested",
		Callable(self, "_on_fail_exit_requested")
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
	minigame_failed.emit(score)


func _show_vendor_line(text: String, expression: String, context: String) -> void:
	dialogue_context = context
	var auto_hide := -1.0
	if context in ["passive", "feedback", "warning"]:
		auto_hide = 2.8
	dialogue.say(text, expression, auto_hide, "vendor_chicharon")


func _on_dialogue_started() -> void:
	dialogue_is_blocking = not dialogue_context in [
		"passive", "feedback", "warning"
	]
	dialogue_paused = dialogue_is_blocking
	if dialogue_is_blocking:
		_set_gameplay_processing(false)


func _on_dialogue_finished() -> void:
	var context := dialogue_context
	dialogue_context = ""
	var was_blocking := dialogue_is_blocking
	dialogue_is_blocking = false
	match context:
		"intro":
			_set_gameplay_processing(true)
			dialogue_paused = false
			_begin_gameplay()
		"success":
			dialogue_paused = false
			if not result_emitted:
				result_emitted = true
				$CollectibleEnding.play()
		"fail":
			dialogue_paused = false
			_on_fail_exit_requested()
		_:
			if was_blocking:
				_set_gameplay_processing(true)
				dialogue_paused = false


func _set_gameplay_processing(enabled: bool) -> void:
	var mode := Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
	takeout_indicator.process_mode = mode
	for piece: Node in round_pieces:
		if is_instance_valid(piece):
			piece.process_mode = mode


func _choose_pattern(difficulty: String) -> Array:
	var patterns := easy_patterns
	if difficulty == "medium":
		patterns = medium_patterns
	elif difficulty == "hard":
		patterns = hard_patterns
	return (patterns.pick_random() as Array).duplicate()


func _update_ui() -> void:
	var shown_round := mini(current_round_index + 1, round_defs.size())
	var difficulty := str(round_defs[mini(current_round_index, round_defs.size() - 1)]["difficulty"])
	round_label.text = "ROUND %d / %d" % [shown_round, round_defs.size()]
	difficulty_label.text = difficulty.to_upper()
	collected_label.text = "%d / %d" % [collected, required_collected]
	wasted_label.text = "%d / %d" % [wasted, fail_wasted]
	highest_combo_label.text = "x%d" % highest_combo
	score_label.text = str(score)
	combo_counter_label.text = "x%d" % combo
	combo_counter_sprite.visible = combo > 0
	combo_counter_label.visible = combo > 0


func _setup_hud() -> void:
	performance_sprite = _add_ui_sprite(
		"PerformancePanel", PERFORMANCE_PANEL,
		PERFORMANCE_ORIGIN + Vector2(146.5, 175.0), 0
	)
	round_panel_sprite = _add_ui_sprite(
		"RoundPanel", ROUND_PANEL,
		ROUND_ORIGIN + Vector2(207.0, 88.5), 0
	)
	_setup_round_complete_overlay()
	combo_counter_sprite = _add_ui_sprite(
		"ComboCounter", COMBO_COUNTER,
		COMBO_ORIGIN + Vector2(86.0, 86.0), 0
	)

	_configure_label(collected_label, PERFORMANCE_ORIGIN + Vector2(164.2, 45.1), Vector2(94.0, 27.6), 18)
	_configure_label(wasted_label, PERFORMANCE_ORIGIN + Vector2(164.2, 91.0), Vector2(94.0, 27.6), 18)
	_configure_label(highest_combo_label, PERFORMANCE_ORIGIN + Vector2(164.2, 137.0), Vector2(94.0, 27.6), 18)

	score_label = Label.new()
	score_label.name = "ScoreValue"
	ui.add_child(score_label)
	_configure_label(score_label, PERFORMANCE_ORIGIN + Vector2(164.2, 183.1), Vector2(94.0, 27.6), 18)

	_configure_label(round_label, ROUND_ORIGIN + Vector2(39.9, 49.6), Vector2(332.7, 75.7), 38)
	round_label.add_theme_constant_override("outline_size", 1)
	round_label.add_theme_color_override("font_outline_color", Color("2b160a"))
	difficulty_label = Label.new()
	difficulty_label.name = "DifficultyValue"
	ui.add_child(difficulty_label)
	_configure_label(difficulty_label, ROUND_ORIGIN + Vector2(73.4, 139.5), Vector2(275.2, 27.6), 17)

	combo_counter_label = Label.new()
	combo_counter_label.name = "ComboCounterValue"
	ui.add_child(combo_counter_label)
	_configure_label(combo_counter_label, COMBO_ORIGIN + Vector2(43.1, 67.7), Vector2(85.8, 51.6), 34)
	combo_counter_label.add_theme_constant_override("outline_size", 1)
	combo_counter_label.add_theme_color_override("font_outline_color", Color("2b160a"))


func _setup_round_complete_overlay() -> void:
	round_complete_layer = CanvasLayer.new()
	round_complete_layer.name = "RoundCompleteLayer"
	round_complete_layer.layer = 150
	add_child(round_complete_layer)
	round_complete_root = Control.new()
	round_complete_root.name = "Root"
	round_complete_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	round_complete_layer.add_child(round_complete_root)
	var dim := ColorRect.new()
	dim.name = "DimBackground"
	dim.position = Vector2.ZERO
	dim.size = VIEWPORT_SIZE
	dim.color = Color(0.0, 0.0, 0.0, 0.76)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.z_index = 0
	round_complete_root.add_child(dim)
	round_complete_sprite = Sprite2D.new()
	round_complete_sprite.name = "RoundComplete"
	round_complete_sprite.texture = ROUND_COMPLETE
	round_complete_sprite.position = VIEWPORT_SIZE * 0.5
	round_complete_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	round_complete_sprite.z_index = 1
	round_complete_root.add_child(round_complete_sprite)
	round_complete_root.visible = false


func _add_ui_sprite(
	node_name: String,
	texture: Texture2D,
	position: Vector2,
	z_layer: int
) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.position = position
	sprite.z_index = z_layer
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ui.add_child(sprite)
	return sprite


func _configure_label(
	label: Label,
	position: Vector2,
	size: Vector2,
	font_size: int
) -> void:
	label.position = position
	label.size = size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", VCR_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("f5ddb0"))
	label.add_theme_color_override("font_shadow_color", Color("241209"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.z_index = 10


func _setup_tongs() -> void:
	tongs_root = Node2D.new()
	tongs_root.name = "RuntimeTongs"
	tongs_root.z_index = 60
	add_child(tongs_root)
	var back := Sprite2D.new()
	back.texture = TONGS_BACK
	back.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tongs_root.add_child(back)
	var front := Sprite2D.new()
	front.texture = TONGS_FRONT
	front.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	front.z_index = 2
	tongs_root.add_child(front)
	tongs_root.scale = tongs_scale
	tongs_root.rotation_degrees = tongs_rotation_degrees
	_hide_tongs()


func _hide_tongs() -> void:
	if tongs_root != null:
		tongs_root.visible = false


func _show_result_popup(result: String, position: Vector2) -> void:
	var texture := TOO_RAW_POPUP
	match result:
		"perfect":
			texture = PERFECT_POPUP
		"slightly_cooked":
			texture = UNDERCOOKED_POPUP
		"burnt":
			texture = BURNT_POPUP
	var popup := Sprite2D.new()
	popup.name = "%sFeedbackPopup" % result.capitalize().replace(" ", "")
	popup.texture = texture
	popup.position = position + Vector2(0.0, -85.0)
	popup.scale = popup_scale * 0.8
	popup.z_index = 70
	popup.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(popup)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 42.0, 0.55)
	tween.tween_property(popup, "scale", popup_scale, 0.12)
	tween.tween_property(popup, "modulate:a", 0.0, 0.25).set_delay(0.45)
	tween.finished.connect(popup.queue_free)


func _play_result_sound(result: String) -> void:
	match result:
		"perfect":
			_play_sound(SFX_PERFECT_1 if randf() < 0.5 else SFX_PERFECT_2, -4.0)
		"slightly_cooked":
			_play_sound(SFX_UNDERCOOKED, -4.0)
		"raw":
			_play_sound(SFX_RAW, -4.0)
		"burnt":
			_play_sound(SFX_TONGS_MISS, -4.0)
	_play_sound(SFX_TONGS_GRAB, -7.0)


func _setup_audio() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "Music"
	music_player.stream = BGM
	music_player.volume_db = -18.0
	add_child(music_player)
	ambience_player = AudioStreamPlayer.new()
	ambience_player.name = "FryingAmbience"
	ambience_player.stream = AMBIENCE
	ambience_player.volume_db = -17.0
	add_child(ambience_player)


func _start_audio() -> void:
	if not music_player.playing:
		music_player.play()
	if not ambience_player.playing:
		ambience_player.play()


func _stop_audio() -> void:
	music_player.stop()
	ambience_player.stop()


func _play_sound(stream: AudioStream, volume_db := -4.0, pitch := 1.0) -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _clear_pieces() -> void:
	for child: Node in chicharon_container.get_children():
		if is_instance_valid(child):
			child.queue_free()
	round_pieces.clear()
	piece_indices.clear()
