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

@export_category("Chicharon")
@export var chicharon_scene: PackedScene

@export_category("Timing")
@export var bpm: float = 250.0
@export var travel_beats: float = 12.0
@export var throw_duration: float = 0.55
@export var post_throw_input_delay: float = 0.30

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


func _ready() -> void:
	randomize()

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

	if chicharon_scene == null:
		push_warning("Chicharon scene is not assigned.")
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
		chicharon_container.add_child(piece)

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
			piece_float_duration
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
				wait_time
			).timeout

			if ending_started:
				return

			if phase == MiniRoundPhase.GAME_OVER:
				return

	# Wait until the last chicharon has landed
	# before input begins.
	await get_tree().create_timer(
		throw_duration + post_throw_input_delay
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


func try_take_chicharon() -> void:
	if not gameplay_started:
		return

	if ending_started:
		return

	if phase != MiniRoundPhase.TAKING_OUT:
		show_feedback("Wait for the batch!")
		return

	var target: Node = get_current_input_target()

	if target == null:
		show_feedback("Wait!")
		combo = 0
		update_ui()
		return

	if target.has_method("try_take"):
		target.call("try_take")


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
				takeout_point.global_position
			)
		)

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

	if reason == "collected":
		collected += 1
		combo += 1
		score += 300 + combo * 10
		show_feedback("Perfect!")

	elif reason == "wasted_raw":
		wasted += 1
		combo = 0
		score = maxi(score - 50, 0)
		show_feedback("Too raw!")

	elif reason == "wasted_slightly":
		wasted += 1
		combo = 0
		score = maxi(score - 25, 0)
		show_feedback("Undercooked!")

	elif reason == "burnt":
		wasted += 1
		combo = 0
		show_feedback("Burnt!")

	update_ui()

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
	current_round_index += 1

	if current_round_index >= round_defs.size():
		end_game(collected >= required_collected)
		return

	show_feedback("Next batch...")

	await get_tree().create_timer(1.2).timeout

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

	if success:
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
	round_label.text = (
		"Round: "
		+ str(mini(current_round_index + 1, 5))
		+ " / 5"
	)

	collected_label.text = (
		"Collected: "
		+ str(collected)
		+ " / "
		+ str(required_collected)
	)

	wasted_label.text = (
		"Wasted: "
		+ str(wasted)
		+ " / "
		+ str(fail_wasted)
	)

	combo_label.text = (
		"Combo: "
		+ str(combo)
		+ " | Score: "
		+ str(score)
	)


func show_feedback(message: String) -> void:
	feedback_label.text = message
	feedback_label.modulate.a = 1.0

	var feedback_tween: Tween = create_tween()

	feedback_tween.tween_property(
		feedback_label,
		"modulate:a",
		0.0,
		1.0
	)
