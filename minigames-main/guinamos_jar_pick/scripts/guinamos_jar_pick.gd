extends Node2D

signal minigame_completed(score: int)
signal minigame_failed(score: int)
signal minigame_retry_requested

const SCREEN_SCALE: float = 0.6

const ENDING_SCENE: PackedScene = preload(
	"res://minigames-main/ending_sequence/scenes/collectible_ending_scene.tscn"
)

const ENDING_COLLECTIBLE: Texture2D = preload(
	"res://minigames-main/ending_sequence/assets/collectibles/collectible_guinamos_bag.png"
)

const FAIL_SCREEN_SCENE: PackedScene = preload(
	"res://minigames-main/fail_screen/scenes/minigame_fail_screen.tscn"
)


const INTRODUCTION_SCENE: PackedScene = preload(
	"res://minigames-main/introduction/scenes/minigame_introduction.tscn"
)


const CURSOR_NORMAL_PATH: String = (
	"res://minigames-main/box_unboxing/assets/ui/cursor_normal.png"
)

const CURSOR_GRAB_PATH: String = (
	"res://minigames-main/box_unboxing/assets/ui/cursor_grab.png"
)

const CURSOR_DRAGGING_PATH: String = (
	"res://minigames-main/box_unboxing/assets/ui/cursor_dragging.png"
)

const MUSIC_PATH: String = (
	"res://minigames-main/guinamos_jar_pick/assets/audio/music/"
	+ "bgm_guinamos_deduction_loop.ogg"
)

const AMBIENCE_PATH: String = (
	"res://minigames-main/guinamos_jar_pick/assets/audio/ambience/"
	+ "amb_guinamos_market_stall_loop.ogg"
)

const SFX_ROOT: String = (
	"res://minigames-main/guinamos_jar_pick/assets/audio/sfx/"
)

const UI_SFX_ROOT: String = (
	"res://minigames-main/guinamos_jar_pick/assets/audio/ui/"
)

const SFX_POINTER_MOVE_01: String = SFX_ROOT + "sfx_pointer_move_01.wav"
const SFX_POINTER_MOVE_02: String = SFX_ROOT + "sfx_pointer_move_02.wav"
const SFX_JAR_DETAIL_OPEN: String = SFX_ROOT + "sfx_jar_detail_open.wav"
const SFX_JAR_DETAIL_CLOSE: String = SFX_ROOT + "sfx_jar_detail_close.wav"
const SFX_JAR_HOVER: String = SFX_ROOT + "sfx_jar_hover.wav"
const SFX_JAR_CONFIRM: String = SFX_ROOT + "sfx_jar_confirm.wav"

const SFX_SENSE_SIGHT: String = SFX_ROOT + "sfx_sense_sight.wav"
const SFX_SENSE_SMELL: String = SFX_ROOT + "sfx_sense_smell.wav"
const SFX_SENSE_TOUCH: String = SFX_ROOT + "sfx_sense_touch.wav"
const SFX_SENSE_SOUND: String = SFX_ROOT + "sfx_sense_sound.wav"
const SFX_SENSE_TASTE: String = SFX_ROOT + "sfx_sense_taste.wav"

const SFX_HINT_REVEAL: String = SFX_ROOT + "sfx_hint_reveal.wav"
const SFX_SIGHT_COLOR_REVEAL: String = SFX_ROOT + "sfx_sight_color_reveal.wav"
const SFX_SCORE_PENALTY: String = SFX_ROOT + "sfx_score_penalty.wav"
const SFX_WRONG_GUESS: String = SFX_ROOT + "sfx_wrong_guess.wav"
const SFX_CORRECT_JAR: String = SFX_ROOT + "sfx_correct_jar.wav"
const SFX_SCORE_WARNING: String = SFX_ROOT + "sfx_score_warning.wav"
const SFX_SUCCESS_TRANSITION: String = SFX_ROOT + "sfx_success_transition.wav"
const SFX_FAILURE_TRANSITION: String = SFX_ROOT + "sfx_failure_transition.wav"

const SFX_UI_HOVER: String = UI_SFX_ROOT + "sfx_ui_hover.wav"
const SFX_UI_CLICK: String = UI_SFX_ROOT + "sfx_ui_click.wav"
const SFX_COUNTDOWN_READY: String = UI_SFX_ROOT + "sfx_countdown_ready.wav"

@onready var main_jar_slots: Node2D = $MainJarSlots
@onready var selected_pointer: Sprite2D = $SelectedPointer
@onready var score_label: Label = $ScoreFrame/ScoreLabel
@onready var score_frame: Node = $ScoreFrame

@onready var detail_view: Node2D = $DetailView
@onready var big_jar: Sprite2D = $DetailView/BigJar
@onready var hint_label: Label = $DetailView/HintLabel
@onready var back_button: BaseButton = $DetailView/BackButton
@onready var select_button: BaseButton = $DetailView/SelectButton

@onready var sense_sound_button: BaseButton = $DetailView/SenseSoundButton
@onready var sense_touch_button: BaseButton = $DetailView/SenseTouchButton
@onready var sense_taste_button: BaseButton = $DetailView/SenseTasteButton
@onready var sense_smell_button: BaseButton = $DetailView/SenseSmellButton
@onready var sense_sight_button: BaseButton = $DetailView/SenseSightButton

@export_category("Main Jar Screen")
@export var main_jar_scale: float = 0.6
@export var pointer_scale: float = 0.6
@export var pointer_offset_design: Vector2 = Vector2(0, -290)

@export_category("Ending Sequence")
@export var ending_collectible_scale: Vector2 = Vector2(0.6, 0.6)

# Guinamos uses a tall jar-shaped ending collectible.
# The shared ending default click area is only 260 x 180,
# which is too short for this jar and makes most of the
# visible collectible impossible to click.
@export var ending_collectible_collision_size: Vector2 = Vector2(
	500,
	500
)

@export var ending_test_key_enabled: bool = true

@export_category("Fail Screen")
@export var fail_test_key_enabled: bool = true

# Press G while testing to set the score to 0.
# After that, press any sense button to test the
# excessive-handling failure.
@export var hint_overuse_test_key_enabled: bool = true


@export_category("Audio")
@export var music_volume_db: float = -15.0
@export var ambience_volume_db: float = -27.0
@export var sfx_volume_db: float = -5.0
@export var ui_sfx_volume_db: float = -10.0
@export var audio_fade_duration: float = 0.8
@export var score_warning_threshold: int = 25

@export_category("Cursor")
@export var cursor_display_size: Vector2i = Vector2i(64, 64)
@export var cursor_normal_hotspot: Vector2 = Vector2(3, 3)
@export var cursor_grab_hotspot: Vector2 = Vector2(32, 27)
@export var cursor_dragging_hotspot: Vector2 = Vector2(32, 29)

@export_category("Polish")
@export var selected_jar_scale_multiplier: float = 1.05
@export var selected_jar_lift_design: float = 20.0
@export var jar_selection_duration: float = 0.16
@export var grayscale_reveal_duration: float = 0.42
@export var hint_typewriter_character_delay: float = 0.026
@export var score_feedback_duration: float = 0.55
@export var score_penalty_label_offset: Vector2 = Vector2(0, 72)

var hint_font := preload(
	"res://minigames-main/shared/fonts/VCR_OSD_MONO_1.001.ttf"
)

var grayscale_shader := preload(
	"res://minigames-main/guinamos_jar_pick/assets/shaders/grayscale.gdshader"
)

var ending_sequence: Node = null
var fail_screen: Node = null
var introduction: Node = null

var gameplay_started: bool = false
var introduction_started: bool = false

var ending_started: bool = false
var fail_screen_started: bool = false
var result_emitted: bool = false

var current_index: int = 2
var slot_nodes: Array[Node2D] = []

var pointer_base_position: Vector2
var pointer_float_time: float = 0.0
var pointer_float_amount_design: float = 16.0
var pointer_float_speed: float = 4.0

var jars: Array[Dictionary] = []
var selected_jar: Dictionary = {}

var score: int = 100
var hints_used: Dictionary = {}
var wrong_guesses: int = 0
var max_wrong_guesses: int = 2


var music_player: AudioStreamPlayer = null
var ambience_player: AudioStreamPlayer = null
var audio_cache: Dictionary = {}

var cursor_normal_texture: Texture2D = null
var cursor_grab_texture: Texture2D = null
var cursor_dragging_texture: Texture2D = null
var mouse_left_down: bool = false
var hovered_jar_index: int = -1
var hovered_button: BaseButton = null

var pointer_sound_alternate: bool = false
var score_warning_played: bool = false

var jar_selection_tween: Tween = null
var score_feedback_tween: Tween = null
var score_label_base_position: Vector2 = Vector2.ZERO
var score_label_base_scale: Vector2 = Vector2.ONE

var hint_typewriter_active: bool = false
var hint_typewriter_full_text: String = ""
var hint_typewriter_visible_characters: int = 0
var hint_typewriter_accumulator: float = 0.0


func _ready() -> void:
	randomize()

	gameplay_started = false
	introduction_started = false

	slot_nodes = [
		$MainJarSlots/JarSlot1,
		$MainJarSlots/JarSlot2,
		$MainJarSlots/JarSlot3,
		$MainJarSlots/JarSlot4,
		$MainJarSlots/JarSlot5
	]

	setup_jars()
	setup_jar_positions()
	randomize_jars()
	setup_detail_view()
	setup_sense_buttons()
	setup_score_label()

	_setup_audio()
	_setup_custom_cursors()

	score = 100
	wrong_guesses = 0
	selected_jar = {}
	score_warning_played = false

	update_score_label()

	_ensure_ending_sequence()
	_connect_ending_sequence()

	_ensure_fail_screen()
	_connect_fail_screen()

	_ensure_introduction()
	_connect_introduction()

	selected_pointer.visible = true
	selected_pointer.centered = true
	selected_pointer.scale = Vector2(
		pointer_scale,
		pointer_scale
	)
	selected_pointer.z_index = 5

	current_index = 2
	pointer_float_time = 0.0
	update_pointer()
	_apply_jar_selection_visuals(true)

	_prepare_guinamos_start_state(true)
	_set_guinamos_interaction_enabled(false)
	_set_cursor_normal()

	print("")
	print("========================================")
	print("GUINAMOS JAR PICK READY")
	print("========================================")
	print("Introduction found: ", introduction != null)
	print("Ending node found: ", ending_sequence != null)
	print("Fail screen found: ", fail_screen != null)
	print(
		"Guinamos collectible loaded: ",
		ENDING_COLLECTIBLE != null
	)
	print(
		"Music loaded: ",
		music_player != null and music_player.stream != null
	)
	print(
		"Ambience loaded: ",
		ambience_player != null and ambience_player.stream != null
	)
	print("Press T to test the success ending.")
	print("Press F to test a wrong-jar failure.")
	print(
		"Press G to set score to 0, then use any "
		+ "sense to test excessive handling."
	)
	print("========================================")
	print("")

	_start_guinamos_introduction()


func _process(delta: float) -> void:
	if not gameplay_started:
		_set_cursor_normal()
		return

	if _gameplay_has_stopped():
		_set_cursor_normal()
		return

	_update_hint_typewriter(delta)
	_update_hover_and_cursor()

	if detail_view.visible:
		return

	pointer_float_time += delta

	selected_pointer.global_position = (
		pointer_base_position
		+ Vector2(
			0,
			sin(pointer_float_time * pointer_float_speed)
			* pointer_float_amount_design
			* SCREEN_SCALE
		)
	)


func _input(event: InputEvent) -> void:
	# The introduction handles its own mouse input.
	# Guinamos gameplay stays locked until the countdown ends.
	if not gameplay_started:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			mouse_left_down = event.pressed

			if _gameplay_has_stopped():
				_set_cursor_normal()
				return

			if event.pressed and not detail_view.visible:
				var clicked_jar_index: int = (
					_get_jar_index_at_mouse()
				)

				if clicked_jar_index >= 0:
					_play_sound(
						SFX_UI_CLICK,
						ui_sfx_volume_db - 2.0
					)

					if clicked_jar_index == current_index:
						open_selected_jar_detail()
					else:
						_set_current_index(
							clicked_jar_index,
							true
						)

					get_viewport().set_input_as_handled()
					return

	if event is InputEventKey:
		if (
			ending_test_key_enabled
			and event.keycode == KEY_T
			and event.pressed
			and not event.echo
		):
			if not _gameplay_has_stopped():
				print(
					"DEBUG GUINAMOS: T pressed. "
					+ "Forcing success ending."
				)

				_start_success_ending()
				get_viewport().set_input_as_handled()

			return

		if (
			fail_test_key_enabled
			and event.keycode == KEY_F
			and event.pressed
			and not event.echo
		):
			if not _gameplay_has_stopped():
				var test_jar: Dictionary = (
					_get_test_wrong_jar()
				)

				if not test_jar.is_empty():
					print(
						"DEBUG GUINAMOS: F pressed. "
						+ "Forcing wrong-jar failure for: "
						+ str(test_jar["id"])
					)

					_play_sound(
						SFX_WRONG_GUESS,
						sfx_volume_db
					)
					_start_failure_for_jar(test_jar)
					get_viewport().set_input_as_handled()

			return

		if (
			hint_overuse_test_key_enabled
			and event.keycode == KEY_G
			and event.pressed
			and not event.echo
		):
			if not _gameplay_has_stopped():
				score = 0
				update_score_label()

				print(
					"DEBUG GUINAMOS: G pressed. "
					+ "Score set to 0. Press any sense "
					+ "button to test the hint-overuse failure."
				)

				get_viewport().set_input_as_handled()

			return

	if _gameplay_has_stopped():
		return

	if detail_view.visible:
		return

	if event.is_action_pressed("guinamos_left"):
		move_pointer(-1)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("guinamos_right"):
		move_pointer(1)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("guinamos_confirm"):
		_play_sound(
			SFX_UI_CLICK,
			ui_sfx_volume_db - 2.0
		)
		open_selected_jar_detail()
		get_viewport().set_input_as_handled()


func _gameplay_has_stopped() -> bool:
	return (
		not gameplay_started
		or ending_started
		or fail_screen_started
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

			print(
				"DEBUG GUINAMOS: "
				+ "Existing introduction is valid."
			)

			return

		print(
			"DEBUG GUINAMOS: Existing introduction "
			+ "is incomplete. Replacing it."
		)

		remove_child(existing_node)
		existing_node.queue_free()

	if INTRODUCTION_SCENE == null:
		push_error(
			"GUINAMOS: Introduction scene "
			+ "could not be loaded."
		)
		return

	var new_introduction: Node = (
		INTRODUCTION_SCENE.instantiate()
	)

	if new_introduction == null:
		push_error(
			"GUINAMOS: Introduction could not "
			+ "be instantiated."
		)
		return

	new_introduction.name = "MinigameIntroduction"

	new_introduction.set(
		"auto_start_for_testing",
		false
	)

	add_child(new_introduction)
	introduction = new_introduction

	print(
		"DEBUG GUINAMOS: Introduction "
		+ "instantiated automatically."
	)


func _connect_introduction() -> void:
	if introduction == null:
		push_error(
			"GUINAMOS: Introduction is missing."
		)
		return

	if not introduction.has_signal("start_requested"):
		push_error(
			"GUINAMOS: Introduction is missing "
			+ "start_requested."
		)
		return

	if not introduction.has_signal("countdown_finished"):
		push_error(
			"GUINAMOS: Introduction is missing "
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

	print(
		"DEBUG GUINAMOS: Introduction signals connected."
	)


func _start_guinamos_introduction() -> void:
	if introduction_started:
		return

	if introduction == null:
		push_error(
			"GUINAMOS: Cannot start introduction "
			+ "because it is missing."
		)

		_start_guinamos_gameplay()
		return

	if not introduction.has_method("start_introduction"):
		push_error(
			"GUINAMOS: Introduction is missing "
			+ "start_introduction()."
		)

		_start_guinamos_gameplay()
		return

	introduction_started = true
	gameplay_started = false
	mouse_left_down = false

	_stop_hint_typewriter()
	_stop_background_audio_immediately()
	_prepare_guinamos_start_state(true)
	_set_guinamos_interaction_enabled(false)
	_set_cursor_normal()

	print("")
	print("========================================")
	print("GUINAMOS INTRODUCTION STARTING")
	print("Introduction ID: guinamos_jar_pick")
	print("========================================")
	print("")

	introduction.call(
		"start_introduction",
		"guinamos_jar_pick"
	)


func _on_introduction_start_requested() -> void:
	print("")
	print("========================================")
	print("GUINAMOS START BUTTON PRESSED")
	print("Countdown is about to begin.")
	print("Gameplay remains locked.")
	print("========================================")
	print("")

	gameplay_started = false
	mouse_left_down = false
	_prepare_guinamos_start_state(false)
	_set_guinamos_interaction_enabled(false)
	_set_cursor_normal()


func _on_introduction_countdown_finished() -> void:
	print("")
	print("========================================")
	print("GUINAMOS COUNTDOWN FINISHED")
	print("Starting Guinamos Jar Pick gameplay.")
	print("========================================")
	print("")

	_play_sound(
		SFX_COUNTDOWN_READY,
		ui_sfx_volume_db
	)
	_start_guinamos_gameplay()


func _start_guinamos_gameplay() -> void:
	if gameplay_started:
		return

	_prepare_guinamos_start_state(false)

	gameplay_started = true
	mouse_left_down = false
	score_warning_played = score <= score_warning_threshold

	_set_guinamos_interaction_enabled(true)
	_apply_jar_selection_visuals(true)
	_start_background_audio()
	_update_hover_and_cursor()

	print("")
	print("========================================")
	print("GUINAMOS JAR PICK GAMEPLAY STARTED")
	print("Score: ", score)
	print("========================================")
	print("")


func _prepare_guinamos_start_state(
	reset_score_and_hints: bool
) -> void:
	main_jar_slots.visible = true
	detail_view.visible = false
	selected_pointer.visible = true

	selected_jar = {}
	current_index = 2
	pointer_float_time = 0.0
	mouse_left_down = false
	hovered_jar_index = -1
	hovered_button = null

	_stop_hint_typewriter()
	hint_label.text = ""
	hint_label.visible_characters = -1

	if reset_score_and_hints:
		score = 100
		wrong_guesses = 0
		score_warning_played = false

		hints_used.clear()

		for jar_data in jars:
			var jar_id: String = str(
				jar_data["id"]
			)

			hints_used[jar_id] = {}

		for slot in slot_nodes:
			var jar_sprite: Sprite2D = (
				slot.get_node("JarSprite")
			)

			set_grayscale_amount(
				jar_sprite,
				1.0
			)

	update_score_label()
	update_pointer()
	_apply_jar_selection_visuals(true)


func _set_guinamos_interaction_enabled(
	enabled: bool
) -> void:
	back_button.disabled = not enabled
	select_button.disabled = not enabled

	sense_sound_button.disabled = not enabled
	sense_touch_button.disabled = not enabled
	sense_taste_button.disabled = not enabled
	sense_smell_button.disabled = not enabled
	sense_sight_button.disabled = not enabled


func _get_test_wrong_jar() -> Dictionary:
	if (
		not selected_jar.is_empty()
		and not bool(selected_jar["is_correct"])
	):
		return selected_jar

	if current_index >= 0 and current_index < slot_nodes.size():
		var current_slot: Node2D = slot_nodes[current_index]
		var current_jar: Dictionary = (
			current_slot.get_meta("jar_data")
		)

		if not bool(current_jar["is_correct"]):
			return current_jar

	for jar_data in jars:
		if not bool(jar_data["is_correct"]):
			return jar_data

	return {}


func _ensure_ending_sequence() -> void:
	var existing_node: Node = get_node_or_null(
		"CollectibleEndingScene"
	)

	if existing_node != null:
		var valid_existing_scene: bool = (
			existing_node.has_method("start_ending")
			and existing_node.has_signal("ending_finished")
		)

		if valid_existing_scene:
			ending_sequence = existing_node
			print(
				"DEBUG GUINAMOS: Existing ending scene is valid."
			)
			return

		print(
			"DEBUG GUINAMOS: Removing incorrect "
			+ "CollectibleEndingScene node."
		)

		remove_child(existing_node)
		existing_node.queue_free()

	if ENDING_SCENE == null:
		push_error(
			"Guinamos ending PackedScene could not be loaded."
		)
		return

	var new_ending_scene: Node = ENDING_SCENE.instantiate()

	if new_ending_scene == null:
		push_error(
			"Guinamos ending scene could not be instantiated."
		)
		return

	new_ending_scene.name = "CollectibleEndingScene"
	add_child(new_ending_scene)

	ending_sequence = new_ending_scene

	print(
		"DEBUG GUINAMOS: Ending scene instantiated automatically."
	)


func _connect_ending_sequence() -> void:
	if ending_sequence == null:
		push_error(
			"Guinamos ending sequence is missing."
		)
		return

	if not ending_sequence.has_method("start_ending"):
		push_error(
			"Guinamos ending scene is missing start_ending()."
		)
		return

	if not ending_sequence.has_signal("ending_finished"):
		push_error(
			"Guinamos ending scene is missing ending_finished."
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
			"DEBUG GUINAMOS: ending_finished signal connected."
		)


func _ensure_fail_screen() -> void:
	var existing_node: Node = get_node_or_null(
		"MinigameFailScreen"
	)

	if existing_node != null:
		var valid_existing_scene: bool = (
			existing_node.has_method("start_fail_screen")
			and existing_node.has_signal("retry_requested")
			and existing_node.has_signal("exit_requested")
		)

		if valid_existing_scene:
			fail_screen = existing_node

			print(
				"DEBUG GUINAMOS: Existing fail screen is valid."
			)

			return

		print(
			"DEBUG GUINAMOS: Removing incorrect "
			+ "MinigameFailScreen node."
		)

		remove_child(existing_node)
		existing_node.queue_free()

	if FAIL_SCREEN_SCENE == null:
		push_error(
			"Guinamos fail-screen scene could not be loaded."
		)
		return

	var new_fail_screen: Node = (
		FAIL_SCREEN_SCENE.instantiate()
	)

	if new_fail_screen == null:
		push_error(
			"Guinamos fail screen could not be instantiated."
		)
		return

	new_fail_screen.name = "MinigameFailScreen"
	add_child(new_fail_screen)

	fail_screen = new_fail_screen

	print(
		"DEBUG GUINAMOS: Fail screen "
		+ "instantiated automatically."
	)


func _connect_fail_screen() -> void:
	if fail_screen == null:
		push_error(
			"Guinamos fail screen is missing."
		)
		return

	if not fail_screen.has_method("start_fail_screen"):
		push_error(
			"Guinamos fail screen is missing "
			+ "start_fail_screen()."
		)
		return

	if not fail_screen.has_signal("retry_requested"):
		push_error(
			"Guinamos fail screen is missing "
			+ "retry_requested."
		)
		return

	if not fail_screen.has_signal("exit_requested"):
		push_error(
			"Guinamos fail screen is missing "
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

	print(
		"DEBUG GUINAMOS: Fail-screen signals connected."
	)


func _start_failure_for_jar(
	jar_data: Dictionary
) -> void:
	if _gameplay_has_stopped():
		return

	if jar_data.is_empty():
		push_error(
			"Guinamos failure could not start "
			+ "because the jar data is empty."
		)
		return

	if fail_screen == null:
		_ensure_fail_screen()
		_connect_fail_screen()

	if fail_screen == null:
		push_error(
			"Guinamos failure could not start "
			+ "because the fail screen is missing."
		)
		return

	fail_screen_started = true
	_disable_gameplay_after_failure()

	_stop_hint_typewriter()
	mouse_left_down = false
	_set_cursor_normal()

	_play_sound(
		SFX_FAILURE_TRANSITION,
		sfx_volume_db
	)
	_fade_out_background_audio()

	var dialogue: String = str(
		jar_data.get(
			"wrong_dialogue",
			"I chose the wrong guinamos.\n"
			+ "I should have inspected it more carefully."
		)
	)

	var reason: String = str(
		jar_data.get(
			"wrong_reason",
			"The wrong guinamos jar was selected."
		)
	)

	print("")
	print("========================================")
	print("GUINAMOS JAR PICK FAILED")
	print("Wrong jar: ", jar_data["id"])
	print("Dialogue: ", dialogue)
	print("Reason: ", reason)
	print("Score: ", score)
	print("========================================")
	print("")

	fail_screen.call(
		"start_fail_screen",
		dialogue,
		reason,
		score,
		true
	)


func _start_hint_overuse_failure() -> void:
	if _gameplay_has_stopped():
		return

	if fail_screen == null:
		_ensure_fail_screen()
		_connect_fail_screen()

	if fail_screen == null:
		push_error(
			"Guinamos hint-overuse failure could not start "
			+ "because the fail screen is missing."
		)
		return

	if not fail_screen.has_method("start_fail_screen"):
		push_error(
			"Guinamos fail screen is missing "
			+ "start_fail_screen()."
		)
		return

	fail_screen_started = true
	_disable_gameplay_after_failure()

	_stop_hint_typewriter()
	mouse_left_down = false
	_set_cursor_normal()

	_play_sound(
		SFX_FAILURE_TRANSITION,
		sfx_volume_db
	)
	_fade_out_background_audio()

	var dialogue: String = (
		"You're handling the jars too much. Are you really going to buy one?"
	)

	var reason: String = (
		"You ran out of score by inspecting "
		+ "the jars too many times."
	)

	print("")
	print("========================================")
	print("GUINAMOS JAR PICK FAILED")
	print("Failure type: Too many hints at 0 score")
	print("Dialogue: ", dialogue)
	print("Reason: ", reason)
	print("Score: ", score)
	print("========================================")
	print("")

	fail_screen.call(
		"start_fail_screen",
		dialogue,
		reason,
		score,
		true
	)


func _on_fail_retry_requested() -> void:
	print(
		"DEBUG GUINAMOS: Retry requested."
	)

	if get_tree().current_scene == self:
		get_tree().reload_current_scene()
	else:
		minigame_retry_requested.emit()


func _on_fail_exit_requested() -> void:
	if result_emitted:
		return

	result_emitted = true

	_stop_background_audio_immediately()
	_set_cursor_normal()

	print("")
	print("========================================")
	print("DEBUG GUINAMOS: EXIT AFTER FAILURE")
	print("Final score: ", score)
	print("========================================")
	print("")

	minigame_failed.emit(score)


func _start_success_ending() -> void:
	if _gameplay_has_stopped():
		return

	if ending_sequence == null:
		_ensure_ending_sequence()
		_connect_ending_sequence()

	if ending_sequence == null:
		push_error(
			"Cannot start Guinamos ending because "
			+ "the ending scene is missing."
		)
		return

	if not ending_sequence.has_method("start_ending"):
		push_error(
			"Cannot start Guinamos ending because "
			+ "start_ending() is missing."
		)
		return

	if ENDING_COLLECTIBLE == null:
		push_error(
			"Guinamos ending collectible texture is missing."
		)
		return

	ending_started = true
	_disable_gameplay_for_ending()

	_stop_hint_typewriter()
	mouse_left_down = false
	_set_cursor_normal()

	_play_sound(
		SFX_CORRECT_JAR,
		sfx_volume_db
	)
	_play_sound(
		SFX_SUCCESS_TRANSITION,
		sfx_volume_db - 1.0
	)
	_fade_out_background_audio()

	print("")
	print("========================================")
	print("DEBUG GUINAMOS: STARTING SUCCESS ENDING")
	print("Score: ", score)
	print("========================================")
	print("")

	await get_tree().create_timer(0.45, false).timeout

	if not is_inside_tree():
		return

	ending_sequence.call(
		"start_ending",
		ENDING_COLLECTIBLE,
		ending_collectible_scale
	)


func _disable_gameplay_for_ending() -> void:
	selected_pointer.visible = false

	back_button.disabled = true
	select_button.disabled = true

	sense_sound_button.disabled = true
	sense_touch_button.disabled = true
	sense_taste_button.disabled = true
	sense_smell_button.disabled = true
	sense_sight_button.disabled = true

	# Disabled BaseButtons can still sit over the ending scene as
	# Controls with MOUSE_FILTER_STOP. Guinamos is the only game
	# with several invisible full/detail-view buttons left visible
	# underneath the shared ending, so explicitly stop every one
	# from intercepting mouse input.
	var ending_blocking_controls: Array[Control] = [
		back_button,
		select_button,
		sense_sound_button,
		sense_touch_button,
		sense_taste_button,
		sense_smell_button,
		sense_sight_button,
		hint_label
	]

	for control in ending_blocking_controls:
		if control == null:
			continue

		control.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE
		)

		control.release_focus()

	hovered_jar_index = -1
	hovered_button = null
	mouse_left_down = false

	_set_cursor_normal()

	print(
		"DEBUG GUINAMOS: Gameplay controls no longer "
		+ "intercept ending mouse input."
	)


func _on_ending_sequence_finished() -> void:
	if result_emitted:
		return

	result_emitted = true

	_stop_background_audio_immediately()
	_set_cursor_normal()

	print("")
	print("========================================")
	print("DEBUG GUINAMOS: ENDING COMPLETED")
	print("Final score: ", score)
	print("========================================")
	print("")

	minigame_completed.emit(score)


func design_pos(pos: Vector2) -> Vector2:
	return pos * SCREEN_SCALE


func setup_jars() -> void:
	jars = [
		{
			"id": "too_fresh",
			"name": "Pale Fresh Guinamos",
			"main_texture": preload(
				"res://minigames-main/guinamos_jar_pick/assets/jars/main_jar_too_fresh.png"
			),
			"detail_texture": preload(
				"res://minigames-main/guinamos_jar_pick/assets/jars/guinamos_jar_too_fresh.png"
			),
			"is_correct": false,
			"wrong_dialogue": (
				"This guinamos is too fresh; I chose too quickly.\n"
				+ "It won't give the broth enough depth."
			),
			"wrong_reason": (
				"The selected guinamos was too fresh "
				+ "for the broth."
			),
			"hints": {
				"sight": "The color is light and clean.",
				"smell": "The scent is sharp and simple.",
				"touch": "The paste feels soft and smooth.",
				"sound": "It shifts easily inside the jar.",
				"taste": "The flavor is salty and direct."
			}
		},
		{
			"id": "too_salty",
			"name": "Salt-Crusted Guinamos",
			"main_texture": preload(
				"res://minigames-main/guinamos_jar_pick/assets/jars/main_jar_too_salty.png"
			),
			"detail_texture": preload(
				"res://minigames-main/guinamos_jar_pick/assets/jars/guinamos_jar_too_salty.png"
			),
			"is_correct": false,
			"wrong_dialogue": (
				"I picked one that's far too salty.\n"
				+ "It could overpower the whole broth."
			),
			"wrong_reason": (
				"The selected guinamos was too salty "
				+ "for the broth."
			),
			"hints": {
				"sight": "Tiny pale crystals sit near the lid.",
				"smell": "The aroma is dry and mineral-like.",
				"touch": "The paste feels coarse between fingers.",
				"sound": "It moves with a rough, heavy scrape.",
				"taste": "The first taste is very bright and salty."
			}
		},
		{
			"id": "spoiled",
			"name": "Spoiled Guinamos",
			"main_texture": preload(
				"res://minigames-main/guinamos_jar_pick/assets/jars/main_jar_spoiled.png"
			),
			"detail_texture": preload(
				"res://minigames-main/guinamos_jar_pick/assets/jars/guinamos_jar_spoiled.png"
			),
			"is_correct": false,
			"wrong_dialogue": (
				"Oh no, this guinamos has already spoiled.\n"
				+ "I shouldn't have trusted this jar."
			),
			"wrong_reason": (
				"The selected guinamos had already spoiled."
			),
			"hints": {
				"sight": "The color has deep uneven patches.",
				"smell": "The scent is strong and sour at the edge.",
				"touch": "The texture feels sticky in some spots.",
				"sound": "It moves thickly, with little separation.",
				"taste": "The flavor turns bitter after a moment."
			}
		},
		{
			"id": "watery",
			"name": "Watery Guinamos",
			"main_texture": preload(
				"res://minigames-main/guinamos_jar_pick/assets/jars/main_jar_watery.png"
			),
			"detail_texture": preload(
				"res://minigames-main/guinamos_jar_pick/assets/jars/guinamos_jar_watery.png"
			),
			"is_correct": false,
			"wrong_dialogue": (
				"This guinamos is too watery; I chose poorly.\n"
				+ "It won't give the broth enough flavor."
			),
			"wrong_reason": (
				"The selected guinamos was too watery "
				+ "for the broth."
			),
			"hints": {
				"sight": "A thin layer rests above the paste.",
				"smell": "The aroma spreads lightly and fades fast.",
				"touch": "The paste slips quickly when pressed.",
				"sound": "It gives a soft slosh when moved.",
				"taste": "The flavor arrives lightly, then fades."
			}
		},
		{
			"id": "aged",
			"name": "Aged Guinamos",
			"main_texture": preload(
				"res://minigames-main/guinamos_jar_pick/assets/jars/main_jar_aged.png"
			),
			"detail_texture": preload(
				"res://minigames-main/guinamos_jar_pick/assets/jars/guinamos_jar_aged.png"
			),
			"is_correct": true,
			"hints": {
				"sight": "The paste has a deep warm red tone.",
				"smell": "The scent is rounded and savory.",
				"touch": "The texture feels thick and grainy.",
				"sound": "It shifts with a slow, dense movement.",
				"taste": "The taste is salty with lasting depth."
			}
		}
	]


func setup_jar_positions() -> void:
	slot_nodes[0].position = design_pos(Vector2(430, 770))
	slot_nodes[1].position = design_pos(Vector2(700, 790))
	slot_nodes[2].position = design_pos(Vector2(960, 810))
	slot_nodes[3].position = design_pos(Vector2(1220, 790))
	slot_nodes[4].position = design_pos(Vector2(1490, 770))


func randomize_jars() -> void:
	var shuffled_jars := jars.duplicate(true)
	shuffled_jars.shuffle()

	hints_used.clear()

	for index in range(slot_nodes.size()):
		var slot: Node2D = slot_nodes[index]
		var jar_data: Dictionary = shuffled_jars[index]
		var jar_sprite: Sprite2D = slot.get_node("JarSprite")

		slot.set_meta("jar_data", jar_data)

		jar_sprite.texture = jar_data["main_texture"]
		jar_sprite.centered = true
		jar_sprite.position = Vector2.ZERO
		jar_sprite.scale = Vector2(
			main_jar_scale,
			main_jar_scale
		)
		jar_sprite.z_index = 2

		apply_grayscale(jar_sprite, 1.0)

		hints_used[jar_data["id"]] = {}


func setup_detail_view() -> void:
	detail_view.visible = false

	back_button.pressed.connect(_on_back_button_pressed)
	select_button.pressed.connect(_on_select_button_pressed)

	hint_label.text = ""
	hint_label.visible_characters = -1
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	hint_label.add_theme_font_override(
		"font",
		hint_font
	)

	hint_label.add_theme_font_size_override(
		"font_size",
		26
	)

	hint_label.add_theme_color_override(
		"font_color",
		Color("#1A120B")
	)

	hint_label.add_theme_constant_override(
		"line_spacing",
		6
	)


func setup_sense_buttons() -> void:
	setup_invisible_button(sense_sound_button)
	setup_invisible_button(sense_touch_button)
	setup_invisible_button(sense_taste_button)
	setup_invisible_button(sense_smell_button)
	setup_invisible_button(sense_sight_button)

	sense_sound_button.pressed.connect(
		_on_sense_button_pressed.bind("sound")
	)

	sense_touch_button.pressed.connect(
		_on_sense_button_pressed.bind("touch")
	)

	sense_taste_button.pressed.connect(
		_on_sense_button_pressed.bind("taste")
	)

	sense_smell_button.pressed.connect(
		_on_sense_button_pressed.bind("smell")
	)

	sense_sight_button.pressed.connect(
		_on_sense_button_pressed.bind("sight")
	)


func setup_invisible_button(button: BaseButton) -> void:
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.modulate.a = 0.01
	button.z_index = 30

	if button is Button:
		button.flat = true


func move_pointer(direction: int) -> void:
	if _gameplay_has_stopped():
		return

	var new_index: int = current_index + direction

	if new_index < 0:
		new_index = slot_nodes.size() - 1

	if new_index >= slot_nodes.size():
		new_index = 0

	_set_current_index(new_index, true)


func _set_current_index(
	new_index: int,
	play_move_sound: bool
) -> void:
	if new_index < 0 or new_index >= slot_nodes.size():
		return

	if new_index == current_index:
		update_pointer()
		_apply_jar_selection_visuals(false)
		return

	current_index = new_index
	pointer_float_time = 0.0

	if play_move_sound:
		pointer_sound_alternate = not pointer_sound_alternate

		_play_sound(
			SFX_POINTER_MOVE_01
			if pointer_sound_alternate
			else SFX_POINTER_MOVE_02,
			sfx_volume_db - 3.0,
			randf_range(0.98, 1.02)
		)

	update_pointer()
	_apply_jar_selection_visuals(false)


func update_pointer() -> void:
	var current_slot: Node2D = slot_nodes[current_index]

	pointer_base_position = (
		current_slot.global_position
		+ design_pos(pointer_offset_design)
	)

	selected_pointer.global_position = pointer_base_position


func open_selected_jar_detail() -> void:
	if _gameplay_has_stopped():
		return

	var current_slot: Node2D = slot_nodes[current_index]
	selected_jar = current_slot.get_meta("jar_data")

	_stop_hint_typewriter()
	hovered_jar_index = -1
	hovered_button = null
	mouse_left_down = false

	_play_sound(
		SFX_JAR_DETAIL_OPEN,
		sfx_volume_db
	)

	detail_view.visible = true
	main_jar_slots.visible = false
	selected_pointer.visible = false

	big_jar.texture = selected_jar["detail_texture"]
	big_jar.centered = true
	big_jar.position = design_pos(Vector2(960, 540))
	big_jar.scale = Vector2(0.6, 0.6)
	big_jar.z_index = 3

	if has_used_sight(selected_jar["id"]):
		apply_grayscale(big_jar, 0.0)
	else:
		apply_grayscale(big_jar, 1.0)

	hint_label.text = "Choose a sense to inspect this jar."
	hint_label.visible_characters = -1

	_update_hover_and_cursor()

	print("Opened detail view for: ", selected_jar["name"])


func _on_sense_button_pressed(sense_name: String) -> void:
	if _gameplay_has_stopped():
		return

	if not detail_view.visible:
		return

	_play_sound(
		SFX_UI_CLICK,
		ui_sfx_volume_db
	)
	_play_sense_sound(sense_name)

	if score <= 0:
		_start_hint_overuse_failure()
		return

	show_hint(sense_name)


func show_hint(sense_name: String) -> void:
	if _gameplay_has_stopped():
		return

	if selected_jar.is_empty():
		return

	var jar_id: String = str(selected_jar["id"])
	var was_new_hint: bool = (
		not hints_used[jar_id].has(sense_name)
	)

	_start_hint_typewriter(
		str(selected_jar["hints"][sense_name])
	)

	_play_sound(
		SFX_HINT_REVEAL,
		sfx_volume_db - 5.0,
		randf_range(0.98, 1.02)
	)

	if was_new_hint:
		hints_used[jar_id][sense_name] = true
		apply_hint_score_penalty()

	if sense_name == "sight":
		reveal_selected_jar_color()


func reveal_selected_jar_color() -> void:
	var current_slot: Node2D = slot_nodes[current_index]
	var main_sprite: Sprite2D = current_slot.get_node("JarSprite")

	var main_amount: float = _get_grayscale_amount(main_sprite)
	var detail_amount: float = _get_grayscale_amount(big_jar)

	if main_amount <= 0.001 and detail_amount <= 0.001:
		return

	_play_sound(
		SFX_SIGHT_COLOR_REVEAL,
		sfx_volume_db - 1.0
	)

	_animate_grayscale_reveal(main_sprite)
	_animate_grayscale_reveal(big_jar)


func has_used_sight(jar_id: String) -> bool:
	if not hints_used.has(jar_id):
		return false

	return hints_used[jar_id].has("sight")


func apply_grayscale(
	sprite: CanvasItem,
	amount: float
) -> void:
	var material := ShaderMaterial.new()
	material.shader = grayscale_shader
	material.set_shader_parameter("amount", amount)

	sprite.material = material


func set_grayscale_amount(
	sprite: CanvasItem,
	amount: float
) -> void:
	if sprite.material is ShaderMaterial:
		sprite.material.set_shader_parameter("amount", amount)
	else:
		apply_grayscale(sprite, amount)


func _on_back_button_pressed() -> void:
	if _gameplay_has_stopped():
		return

	_play_sound(
		SFX_UI_CLICK,
		ui_sfx_volume_db
	)
	_play_sound(
		SFX_JAR_DETAIL_CLOSE,
		sfx_volume_db
	)

	_stop_hint_typewriter()

	detail_view.visible = false
	main_jar_slots.visible = true
	selected_pointer.visible = true
	hint_label.text = ""
	hint_label.visible_characters = -1

	hovered_button = null
	mouse_left_down = false

	update_pointer()
	_apply_jar_selection_visuals(true)
	_update_hover_and_cursor()


func _on_select_button_pressed() -> void:
	if _gameplay_has_stopped():
		return

	if selected_jar.is_empty():
		return

	_play_sound(
		SFX_UI_CLICK,
		ui_sfx_volume_db
	)
	_play_sound(
		SFX_JAR_CONFIRM,
		sfx_volume_db
	)

	if bool(selected_jar["is_correct"]):
		_start_hint_typewriter(
			"Correct. This guinamos has the depth "
			+ "needed for the broth."
		)

		_start_success_ending()
		return

	wrong_guesses += 1
	_change_score(-25)

	_play_sound(
		SFX_WRONG_GUESS,
		sfx_volume_db
	)
	_shake_big_jar()

	var regret_dialogue: String = str(
		selected_jar.get(
			"wrong_dialogue",
			"I chose the wrong guinamos.\n"
			+ "I should inspect the jars more carefully."
		)
	)

	_start_hint_typewriter(regret_dialogue)

	if wrong_guesses >= max_wrong_guesses:
		_start_failure_for_jar(selected_jar)


func _disable_gameplay_after_failure() -> void:
	selected_pointer.visible = false

	back_button.disabled = true
	select_button.disabled = true

	sense_sound_button.disabled = true
	sense_touch_button.disabled = true
	sense_taste_button.disabled = true
	sense_smell_button.disabled = true
	sense_sight_button.disabled = true

	hovered_jar_index = -1
	hovered_button = null
	mouse_left_down = false
	_set_cursor_normal()


func apply_hint_score_penalty() -> void:
	var total_hints: int = get_total_unique_hints_used()

	if total_hints > 3:
		_change_score(-5)


func get_total_unique_hints_used() -> int:
	var count: int = 0

	for jar_id in hints_used.keys():
		count += hints_used[jar_id].size()

	return count


func update_score_label() -> void:
	score_label.text = str(score)


func setup_score_label() -> void:
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.pivot_offset = score_label.size * 0.5

	score_label.add_theme_font_override(
		"font",
		hint_font
	)

	score_label.add_theme_font_size_override(
		"font_size",
		70
	)

	score_label.add_theme_color_override(
		"font_color",
		Color("f8e5b9ff")
	)

	score_label.add_theme_color_override(
		"font_shadow_color",
		Color("#1A120B")
	)

	score_label.add_theme_constant_override(
		"shadow_offset_x",
		4
	)

	score_label.add_theme_constant_override(
		"shadow_offset_y",
		4
	)

	score_label_base_position = score_label.position
	score_label_base_scale = score_label.scale

# =========================================================
# AUDIO
# =========================================================

func _setup_audio() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.volume_db = -60.0
	music_player.stream = _load_audio_stream(MUSIC_PATH)
	_set_audio_stream_loop(music_player.stream, true)
	add_child(music_player)

	ambience_player = AudioStreamPlayer.new()
	ambience_player.name = "AmbiencePlayer"
	ambience_player.process_mode = Node.PROCESS_MODE_ALWAYS
	ambience_player.volume_db = -60.0
	ambience_player.stream = _load_audio_stream(AMBIENCE_PATH)
	_set_audio_stream_loop(ambience_player.stream, true)
	add_child(ambience_player)


func _load_audio_stream(path: String) -> AudioStream:
	if audio_cache.has(path):
		return audio_cache[path] as AudioStream

	if not ResourceLoader.exists(path):
		push_warning("Missing audio file: " + path)
		return null

	var stream: AudioStream = load(path) as AudioStream

	if stream != null:
		audio_cache[path] = stream

	return stream


func _set_audio_stream_loop(
	stream: AudioStream,
	enabled: bool
) -> void:
	if stream == null:
		return

	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = enabled
	elif stream is AudioStreamWAV:
		var wav_stream: AudioStreamWAV = stream as AudioStreamWAV
		wav_stream.loop_mode = (
			AudioStreamWAV.LOOP_FORWARD
			if enabled
			else AudioStreamWAV.LOOP_DISABLED
		)


func _start_background_audio() -> void:
	if music_player != null and music_player.stream != null:
		music_player.stop()
		music_player.volume_db = -60.0
		music_player.play()

	if ambience_player != null and ambience_player.stream != null:
		ambience_player.stop()
		ambience_player.volume_db = -60.0
		ambience_player.play()

	var fade_tween: Tween = create_tween()
	fade_tween.set_parallel(true)

	if music_player != null and music_player.stream != null:
		fade_tween.tween_property(
			music_player,
			"volume_db",
			music_volume_db,
			audio_fade_duration
		)

	if ambience_player != null and ambience_player.stream != null:
		fade_tween.tween_property(
			ambience_player,
			"volume_db",
			ambience_volume_db,
			audio_fade_duration
		)


func _fade_out_background_audio() -> void:
	var fade_tween: Tween = create_tween()
	fade_tween.set_parallel(true)

	if music_player != null and music_player.playing:
		fade_tween.tween_property(
			music_player,
			"volume_db",
			-60.0,
			audio_fade_duration
		)

	if ambience_player != null and ambience_player.playing:
		fade_tween.tween_property(
			ambience_player,
			"volume_db",
			-60.0,
			audio_fade_duration
		)

	fade_tween.chain().tween_callback(
		_stop_background_audio_immediately
	)


func _stop_background_audio_immediately() -> void:
	if music_player != null:
		music_player.stop()

	if ambience_player != null:
		ambience_player.stop()


func _play_sound(
	path: String,
	volume_db: float = 0.0,
	pitch_scale: float = 1.0
) -> void:
	var stream: AudioStream = _load_audio_stream(path)

	if stream == null:
		return

	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)

	player.finished.connect(
		player.queue_free,
		CONNECT_ONE_SHOT
	)
	player.play()


func _play_sense_sound(sense_name: String) -> void:
	var sound_path: String = ""

	match sense_name:
		"sight":
			sound_path = SFX_SENSE_SIGHT
		"smell":
			sound_path = SFX_SENSE_SMELL
		"touch":
			sound_path = SFX_SENSE_TOUCH
		"sound":
			sound_path = SFX_SENSE_SOUND
		"taste":
			sound_path = SFX_SENSE_TASTE

	if sound_path != "":
		_play_sound(
			sound_path,
			sfx_volume_db - 1.0,
			randf_range(0.98, 1.02)
		)


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
		push_warning("Missing cursor: " + path)
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


func _update_hover_and_cursor() -> void:
	if not gameplay_started or _gameplay_has_stopped():
		_set_cursor_normal()
		return

	var new_hovered_jar: int = -1
	var new_hovered_button: BaseButton = null

	if detail_view.visible:
		new_hovered_button = _get_hovered_game_button()
	else:
		new_hovered_jar = _get_jar_index_at_mouse()

	if new_hovered_jar != hovered_jar_index:
		hovered_jar_index = new_hovered_jar

		if hovered_jar_index >= 0:
			_play_sound(
				SFX_JAR_HOVER,
				sfx_volume_db - 8.0
			)

	if new_hovered_button != hovered_button:
		hovered_button = new_hovered_button

		if hovered_button != null:
			_play_sound(
				SFX_UI_HOVER,
				ui_sfx_volume_db - 3.0
			)

	var over_interactive: bool = (
		hovered_jar_index >= 0
		or hovered_button != null
	)

	if over_interactive and mouse_left_down:
		_set_cursor_dragging()
	elif over_interactive:
		_set_cursor_grab()
	else:
		_set_cursor_normal()


func _get_hovered_game_button() -> BaseButton:
	var hovered_control: Control = (
		get_viewport().gui_get_hovered_control()
	)

	var current_node: Node = hovered_control

	while current_node != null:
		if current_node == back_button:
			return back_button
		if current_node == select_button:
			return select_button
		if current_node == sense_sound_button:
			return sense_sound_button
		if current_node == sense_touch_button:
			return sense_touch_button
		if current_node == sense_taste_button:
			return sense_taste_button
		if current_node == sense_smell_button:
			return sense_smell_button
		if current_node == sense_sight_button:
			return sense_sight_button

		current_node = current_node.get_parent()

	return null


func _get_jar_index_at_mouse() -> int:
	if detail_view.visible or not main_jar_slots.visible:
		return -1

	var mouse_position: Vector2 = get_global_mouse_position()
	var best_index: int = -1
	var best_z_index: int = -999999

	for index in range(slot_nodes.size()):
		var slot: Node2D = slot_nodes[index]
		var jar_sprite: Sprite2D = slot.get_node("JarSprite")

		if not jar_sprite.visible or jar_sprite.texture == null:
			continue

		var local_mouse: Vector2 = jar_sprite.to_local(
			mouse_position
		)

		var texture_size: Vector2 = jar_sprite.texture.get_size()
		var jar_rect: Rect2 = Rect2(
			-texture_size * 0.5,
			texture_size
		)

		if not jar_rect.has_point(local_mouse):
			continue

		if jar_sprite.z_index >= best_z_index:
			best_z_index = jar_sprite.z_index
			best_index = index

	return best_index


# =========================================================
# JAR SELECTION POLISH
# =========================================================

func _apply_jar_selection_visuals(
	immediate: bool
) -> void:
	if jar_selection_tween != null:
		jar_selection_tween.kill()
		jar_selection_tween = null

	if immediate:
		for index in range(slot_nodes.size()):
			var sprite: Sprite2D = (
				slot_nodes[index].get_node("JarSprite")
			)

			var is_selected: bool = index == current_index

			sprite.position = Vector2(
				0,
				-selected_jar_lift_design
				* SCREEN_SCALE
				if is_selected
				else 0
			)

			var scale_value: float = (
				main_jar_scale * selected_jar_scale_multiplier
				if is_selected
				else main_jar_scale
			)

			sprite.scale = Vector2(
				scale_value,
				scale_value
			)

		return

	jar_selection_tween = create_tween()
	jar_selection_tween.set_parallel(true)

	for index in range(slot_nodes.size()):
		var sprite: Sprite2D = (
			slot_nodes[index].get_node("JarSprite")
		)

		var is_selected: bool = index == current_index

		var target_position: Vector2 = Vector2(
			0,
			-selected_jar_lift_design
			* SCREEN_SCALE
			if is_selected
			else 0
		)

		var target_scale_value: float = (
			main_jar_scale * selected_jar_scale_multiplier
			if is_selected
			else main_jar_scale
		)

		jar_selection_tween.tween_property(
			sprite,
			"position",
			target_position,
			jar_selection_duration
		).set_trans(
			Tween.TRANS_QUAD
		).set_ease(
			Tween.EASE_OUT
		)

		jar_selection_tween.tween_property(
			sprite,
			"scale",
			Vector2(
				target_scale_value,
				target_scale_value
			),
			jar_selection_duration
		).set_trans(
			Tween.TRANS_BACK
		).set_ease(
			Tween.EASE_OUT
		)


func _shake_big_jar() -> void:
	var base_position: Vector2 = design_pos(
		Vector2(960, 540)
	)

	big_jar.position = base_position

	var shake_tween: Tween = create_tween()
	shake_tween.tween_property(
		big_jar,
		"position",
		base_position + Vector2(-10, 0),
		0.05
	)
	shake_tween.tween_property(
		big_jar,
		"position",
		base_position + Vector2(10, 0),
		0.06
	)
	shake_tween.tween_property(
		big_jar,
		"position",
		base_position + Vector2(-7, 0),
		0.05
	)
	shake_tween.tween_property(
		big_jar,
		"position",
		base_position + Vector2(7, 0),
		0.05
	)
	shake_tween.tween_property(
		big_jar,
		"position",
		base_position,
		0.06
	)


# =========================================================
# SMOOTH SIGHT REVEAL
# =========================================================

func _get_grayscale_amount(sprite: CanvasItem) -> float:
	if sprite.material is ShaderMaterial:
		var shader_material: ShaderMaterial = (
			sprite.material as ShaderMaterial
		)

		var value: Variant = shader_material.get_shader_parameter(
			"amount"
		)

		if value != null:
			return float(value)

	return 0.0


func _animate_grayscale_reveal(sprite: CanvasItem) -> void:
	if not sprite.material is ShaderMaterial:
		apply_grayscale(sprite, 1.0)

	var shader_material: ShaderMaterial = (
		sprite.material as ShaderMaterial
	)

	var start_amount: float = _get_grayscale_amount(sprite)

	var update_grayscale: Callable = func(value: float) -> void:
		if is_instance_valid(sprite):
			shader_material.set_shader_parameter(
				"amount",
				value
			)

	var reveal_tween: Tween = create_tween()
	reveal_tween.tween_method(
		update_grayscale,
		start_amount,
		0.0,
		grayscale_reveal_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


# =========================================================
# HINT TYPEWRITER
# =========================================================

func _start_hint_typewriter(text: String) -> void:
	hint_typewriter_full_text = text
	hint_typewriter_visible_characters = 0
	hint_typewriter_accumulator = 0.0
	hint_typewriter_active = true

	hint_label.text = hint_typewriter_full_text
	hint_label.visible_characters = 0


func _update_hint_typewriter(delta: float) -> void:
	if not hint_typewriter_active:
		return

	if hint_typewriter_character_delay <= 0.0:
		_complete_hint_typewriter()
		return

	hint_typewriter_accumulator += delta

	while (
		hint_typewriter_accumulator
		>= hint_typewriter_character_delay
		and hint_typewriter_active
	):
		hint_typewriter_accumulator -= (
			hint_typewriter_character_delay
		)

		hint_typewriter_visible_characters += 1

		if (
			hint_typewriter_visible_characters
			>= hint_typewriter_full_text.length()
		):
			_complete_hint_typewriter()
			return

		hint_label.visible_characters = (
			hint_typewriter_visible_characters
		)


func _complete_hint_typewriter() -> void:
	hint_typewriter_active = false
	hint_typewriter_visible_characters = (
		hint_typewriter_full_text.length()
	)
	hint_label.visible_characters = -1


func _stop_hint_typewriter() -> void:
	hint_typewriter_active = false
	hint_typewriter_full_text = ""
	hint_typewriter_visible_characters = 0
	hint_typewriter_accumulator = 0.0

	if hint_label != null:
		hint_label.visible_characters = -1


# =========================================================
# SCORE FEEDBACK
# =========================================================

func _change_score(amount: int) -> void:
	if amount == 0:
		return

	var old_score: int = score
	score = clampi(score + amount, 0, 100)

	if score == old_score:
		return

	update_score_label()

	if amount < 0:
		_play_sound(
			SFX_SCORE_PENALTY,
			sfx_volume_db - 1.0
		)

		_animate_score_penalty()
		_show_score_penalty_text(amount)

		if (
			score <= score_warning_threshold
			and not score_warning_played
		):
			score_warning_played = true

			_play_sound(
				SFX_SCORE_WARNING,
				sfx_volume_db
			)


func _animate_score_penalty() -> void:
	if score_feedback_tween != null:
		score_feedback_tween.kill()

	score_label.position = score_label_base_position
	score_label.scale = score_label_base_scale
	score_label.modulate = Color(1.0, 0.55, 0.48, 1.0)

	score_feedback_tween = create_tween()

	score_feedback_tween.tween_property(
		score_label,
		"position",
		score_label_base_position + Vector2(-7, 0),
		0.05
	)

	score_feedback_tween.tween_property(
		score_label,
		"position",
		score_label_base_position + Vector2(7, 0),
		0.06
	)

	score_feedback_tween.tween_property(
		score_label,
		"position",
		score_label_base_position + Vector2(-5, 0),
		0.05
	)

	score_feedback_tween.tween_property(
		score_label,
		"position",
		score_label_base_position,
		0.07
	)

	score_feedback_tween.parallel().tween_property(
		score_label,
		"modulate",
		Color.WHITE,
		score_feedback_duration
	)


func _show_score_penalty_text(amount: int) -> void:
	var penalty_label: Label = Label.new()
	penalty_label.text = str(amount)
	penalty_label.size = Vector2(120, 60)
	penalty_label.position = (
		score_label.position
		+ score_penalty_label_offset
	)
	penalty_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	penalty_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)
	penalty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	penalty_label.z_index = 100

	penalty_label.add_theme_font_override(
		"font",
		hint_font
	)
	penalty_label.add_theme_font_size_override(
		"font_size",
		34
	)
	penalty_label.add_theme_color_override(
		"font_color",
		Color("ff786b")
	)
	penalty_label.add_theme_color_override(
		"font_shadow_color",
		Color("#1A120B")
	)
	penalty_label.add_theme_constant_override(
		"shadow_offset_x",
		3
	)
	penalty_label.add_theme_constant_override(
		"shadow_offset_y",
		3
	)

	score_frame.add_child(penalty_label)

	var start_position: Vector2 = penalty_label.position

	var penalty_tween: Tween = create_tween()
	penalty_tween.set_parallel(true)

	penalty_tween.tween_property(
		penalty_label,
		"position",
		start_position + Vector2(0, -42),
		score_feedback_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	penalty_tween.tween_property(
		penalty_label,
		"modulate:a",
		0.0,
		score_feedback_duration
	)

	penalty_tween.finished.connect(
		penalty_label.queue_free,
		CONNECT_ONE_SHOT
	)
