extends Node2D

signal minigame_finished
signal minigame_failed
signal minigame_retry_requested

enum BoxState {
	CLOSED,
	OPEN
}

enum InspectState {
	NONE,
	CLOSEUP_ONLY,
	DIALOGUE_VISIBLE
}

const SCREEN_SIZE: Vector2 = Vector2(1152, 648)
const SCREEN_CENTER: Vector2 = Vector2(576, 324)

const CLOSEUP_ITEM_SCALE: Vector2 = Vector2(1.0, 1.0)

const DIALOGUE_BOX_PATH: String = (
	"res://minigames-main/box_unboxing/assets/ui/dialogue_box_memory.png"
)

const SHARED_FONT_PATH: String = (
	"res://minigames-main/shared/fonts/VCR_OSD_MONO_1.001.ttf"
)

const ENDING_SCENE: PackedScene = preload(
	"res://minigames-main/ending_sequence/scenes/collectible_ending_scene.tscn"
)

const ENDING_COLLECTIBLE: Texture2D = preload(
	"res://minigames-main/ending_sequence/assets/collectibles/collectible_newspaper_clue.png"
)

const FAIL_SCREEN_SCENE: PackedScene = preload(
	"res://minigames-main/fail_screen/scenes/minigame_fail_screen.tscn"
)

const INTRODUCTION_SCENE: PackedScene = preload(
	"res://minigames-main/introduction/scenes/minigame_introduction.tscn"
)


const TIMER_CLUE_FRAME_PATH: String = (
	"res://minigames-main/box_unboxing/assets/ui/timer_clue_frame.png"
)

const TIMER_WARNING_ICON_PATH: String = (
	"res://minigames-main/box_unboxing/assets/ui/timer_warning_icon.png"
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
	"res://minigames-main/box_unboxing/assets/audio/music/bgm_box_memory_loop.ogg"
)

const AMBIENCE_PATH: String = (
	"res://minigames-main/box_unboxing/assets/audio/ambience/amb_old_room_loop.ogg"
)

const SFX_ROOT: String = (
	"res://minigames-main/box_unboxing/assets/audio/sfx/"
)

const UI_SFX_ROOT: String = (
	"res://minigames-main/box_unboxing/assets/audio/ui/"
)

const SFX_BOX_OPEN: String = SFX_ROOT + "sfx_box_open.wav"
const SFX_BOX_CLOSE: String = SFX_ROOT + "sfx_box_close.wav"
const SFX_CARDBOARD_RUSTLE: String = SFX_ROOT + "sfx_cardboard_rustle.wav"
const SFX_ITEM_PICKUP: String = SFX_ROOT + "sfx_item_pickup.wav"
const SFX_ITEM_RETURN: String = SFX_ROOT + "sfx_item_return.wav"
const SFX_CLOSEUP_OPEN: String = SFX_ROOT + "sfx_closeup_open.wav"
const SFX_CLOSEUP_CLOSE: String = SFX_ROOT + "sfx_closeup_close.wav"
const SFX_PAPER_PICKUP_01: String = SFX_ROOT + "sfx_paper_pickup_01.wav"
const SFX_PAPER_PICKUP_02: String = SFX_ROOT + "sfx_paper_pickup_02.wav"
const SFX_METAL_PICKUP: String = SFX_ROOT + "sfx_metal_pickup.wav"
const SFX_CERAMIC_PICKUP: String = SFX_ROOT + "sfx_ceramic_pickup.wav"
const SFX_CLUE_DISCOVERED: String = SFX_ROOT + "sfx_clue_discovered.wav"
const SFX_ALL_CLUES_FOUND: String = SFX_ROOT + "sfx_all_clues_found.wav"
const SFX_TIMER_WARNING: String = SFX_ROOT + "sfx_timer_warning.wav"
const SFX_SUCCESS_TRANSITION: String = SFX_ROOT + "sfx_success_transition.wav"
const SFX_FAILURE_TRANSITION: String = SFX_ROOT + "sfx_failure_transition.wav"

const SFX_DIALOGUE_OPEN: String = UI_SFX_ROOT + "sfx_dialogue_open.wav"
const SFX_DIALOGUE_CONTINUE: String = UI_SFX_ROOT + "sfx_dialogue_continue.wav"
const SFX_UI_HOVER: String = UI_SFX_ROOT + "sfx_ui_hover.wav"
const SFX_UI_CLICK: String = UI_SFX_ROOT + "sfx_ui_click.wav"
const SFX_TEXT_TICK_01: String = UI_SFX_ROOT + "sfx_text_tick_01.wav"
const SFX_TEXT_TICK_02: String = UI_SFX_ROOT + "sfx_text_tick_02.wav"


@export_category("Time Limit")

# 15 minutes = 900 seconds.
@export var time_limit_seconds: float = 900.0
@export var timer_warning_seconds: float = 60.0
@export var timer_critical_seconds: float = 15.0

@export_category("HUD Layout")

# timer_clue_frame.png is a full 1920 x 1080 transparent canvas.
# At 0.6 scale it exactly matches the 1152 x 648 game screen.
@export var hud_layer: int = 40
@export var hud_full_canvas_scale: Vector2 = Vector2(0.6, 0.6)

# These are 1152 x 648 screen-space positions. Adjust only if the
# blank areas in the finished frame artwork use different positions.
@export var timer_label_position: Vector2 = Vector2(40,58)
@export var timer_label_size: Vector2 = Vector2(145,60)
@export var clue_label_position: Vector2 = Vector2(40,188)
@export var clue_label_size: Vector2 = Vector2(145,60)
@export var warning_icon_position: Vector2 = Vector2(183,92)
@export var warning_icon_display_size: Vector2 = Vector2(34,34)
@export var hud_font_size: int = 34

@export_category("Polish")

@export var hover_scale_multiplier: float = 1.05
@export var drag_scale_multiplier: float = 1.08
@export var item_return_duration: float = 0.20
@export var closeup_transition_duration: float = 0.20
@export var typewriter_character_delay: float = 0.026
@export var typewriter_tick_every_characters: int = 3

@export_category("Audio")

@export var music_volume_db: float = -13.0
@export var ambience_volume_db: float = -25.0
@export var general_sfx_volume_db: float = -5.0
@export var ui_sfx_volume_db: float = -10.0
@export var typewriter_sfx_volume_db: float = -24.0
@export var audio_fade_duration: float = 0.8

@export_category("Testing")

@export var success_test_key_enabled: bool = false
@export var fail_test_key_enabled: bool = false

@onready var background: Sprite2D = $Background

@onready var box_closed: Sprite2D = $BoxClosed
@onready var box_open: Sprite2D = $BoxOpen
@onready var box_click_area: Area2D = $BoxClickArea

@onready var top_flap_area: Area2D = (
	$FlapClickAreas/TopFlapArea
)

@onready var bottom_flap_area: Area2D = (
	$FlapClickAreas/BottomFlapArea
)

@onready var left_flap_area: Area2D = (
	$FlapClickAreas/LeftFlapArea
)

@onready var right_flap_area: Area2D = (
	$FlapClickAreas/RightFlapArea
)

@onready var box_contents: Node2D = $BoxContents

@onready var closeup_layer: CanvasLayer = $CloseupLayer
@onready var dim_overlay: ColorRect = $CloseupLayer/DimOverlay
@onready var closeup_sprite: Sprite2D = (
	$CloseupLayer/CloseupSprite
)

@onready var dialogue_box: Sprite2D = (
	$CloseupLayer/DialogueBox
)

@onready var dialogue_text: Label = (
	$CloseupLayer/DialogueText
)

@onready var continue_label: Label = get_node_or_null(
	"CloseupLayer/ContinueLabel"
)

@onready var finish_label: Label = $FinishLabel

var ending_sequence: Node = null
var fail_screen: Node = null
var introduction: CanvasLayer = null

var elapsed_time: float = 0.0

var gameplay_started: bool = false
var introduction_started: bool = false

var ending_started: bool = false
var fail_started: bool = false
var result_emitted: bool = false

var shared_font: Font

var box_state: BoxState = BoxState.CLOSED
var inspect_state: InspectState = InspectState.NONE

var dragged_item: Area2D = null
var dragged_item_id: String = ""
var active_item_id: String = ""
var drag_offset: Vector2 = Vector2.ZERO

var item_nodes: Dictionary = {}
var item_start_positions: Dictionary = {}

var item_original_z_indices: Dictionary = {}
var hovered_item_id: String = ""

var hud_canvas: CanvasLayer = null
var hud_root: Control = null
var timer_clue_frame: Sprite2D = null
var timer_label: Label = null
var clue_label: Label = null
var warning_icon: Sprite2D = null

var music_player: AudioStreamPlayer = null
var ambience_player: AudioStreamPlayer = null
var audio_cache: Dictionary = {}

var cursor_normal_texture: Texture2D = null
var cursor_grab_texture: Texture2D = null
var cursor_dragging_texture: Texture2D = null

var timer_warning_played: bool = false
var timer_critical_played: bool = false
var all_clues_sound_played: bool = false

var typewriter_active: bool = false
var typewriter_full_text: String = ""
var typewriter_accumulator: float = 0.0
var typewriter_visible_characters: int = 0
var typewriter_tick_alternate: bool = false

var closeup_tween: Tween = null
var box_tween: Tween = null
var hud_pulse_time: float = 0.0
var warning_icon_base_scale: Vector2 = Vector2.ONE
var finish_pending: bool = false

var box_closed_base_scale: Vector2 = Vector2.ONE
var box_open_base_scale: Vector2 = Vector2.ONE

var viewed_required_items: Dictionary = {
	"newspaper": false,
	"photo": false,
	"key": false
}

var removed_items: Dictionary = {
	"newspaper": false,
	"photo": false,
	"key": false,
	"spoon": false,
	"bowl_piece": false,
	"receipt": false,
	"letter": false
}

var pile_center: Vector2 = Vector2(576, 330)
var newspaper_base_position: Vector2 = Vector2(576, 390)

var other_item_offsets: Array[Vector2] = [
	Vector2(-70, -35),
	Vector2(65, -30),
	Vector2(-85, 35),
	Vector2(85, 40),
	Vector2(-35, 70),
	Vector2(40, 75)
]

var item_data: Dictionary = {
	"newspaper": {
		"display_name": "NewspaperItem",
		"texture_path": "res://minigames-main/box_unboxing/assets/contents/damaged_newspaper_small.png",
		"closeup_path": "res://minigames-main/box_unboxing/assets/closeups/damaged_newspaper_closeup.png",
		"scale": Vector2(1.0, 1.0),
		"collision_size": Vector2(320, 245),
		"dialogue": "A torn newspaper... La Paz, hot broth, and miki are still readable. The name of the dish is missing.",
		"required": true
	},
	"photo": {
		"display_name": "PhotoItem",
		"texture_path": "res://minigames-main/box_unboxing/assets/contents/old_family_photo_small.png",
		"closeup_path": "res://minigames-main/box_unboxing/assets/closeups/old_family_photo_closeup.png",
		"scale": Vector2(1.0, 1.0),
		"collision_size": Vector2(270, 210),
		"dialogue": "Lola looks happy here. This photo feels warm, like something I should remember.",
		"required": true
	},
	"key": {
		"display_name": "KeyItem",
		"texture_path": "res://minigames-main/box_unboxing/assets/contents/old_key.png",
		"closeup_path": "res://minigames-main/box_unboxing/assets/closeups/old_key_closeup.png",
		"scale": Vector2(1.0, 1.0),
		"collision_size": Vector2(130, 210),
		"dialogue": "An old key. Maybe it opens something Lola kept hidden.",
		"required": true
	},
	"spoon": {
		"display_name": "SpoonItem",
		"texture_path": "res://minigames-main/box_unboxing/assets/contents/old_spoon.png",
		"closeup_path": "res://minigames-main/box_unboxing/assets/closeups/old_spoon_closeup.png",
		"scale": Vector2(1.0, 1.0),
		"collision_size": Vector2(110, 235),
		"dialogue": "An old spoon. The handle is worn from years of use.",
		"required": false
	},
	"bowl_piece": {
		"display_name": "BowlPieceItem",
		"texture_path": "res://minigames-main/box_unboxing/assets/contents/small_bowl_piece.png",
		"closeup_path": "res://minigames-main/box_unboxing/assets/closeups/small_bowl_piece_closeup.png",
		"scale": Vector2(1.0, 1.0),
		"collision_size": Vector2(165, 130),
		"dialogue": "A broken bowl piece. It looks too carefully kept to be ordinary.",
		"required": false
	},
	"receipt": {
		"display_name": "ReceiptItem",
		"texture_path": "res://minigames-main/box_unboxing/assets/contents/market_receipt_small.png",
		"closeup_path": "res://minigames-main/box_unboxing/assets/closeups/market_receipt_closeup.png",
		"scale": Vector2(1.0, 1.0),
		"collision_size": Vector2(145, 215),
		"dialogue": "An old La Paz market receipt. Chicharon is still readable, but the rest has faded.",
		"required": false
	},
	"letter": {
		"display_name": "LetterItem",
		"texture_path": "res://minigames-main/box_unboxing/assets/contents/family_letter_small.png",
		"closeup_path": "res://minigames-main/box_unboxing/assets/closeups/family_letter_closeup.png",
		"scale": Vector2(1.0, 1.0),
		"collision_size": Vector2(180, 210),
		"dialogue": "A letter from Lola. Her words feel like they were waiting for me.",
		"required": false
	}
}


func _ready() -> void:
	print("")
	print("========================================")
	print("BOX UNBOXING READY")
	print("========================================")

	randomize()

	_setup_scene_defaults()
	_setup_hud()
	_setup_audio()
	_setup_custom_cursors()

	_create_content_items()
	_connect_box_clicks()
	_position_content_items()

	_ensure_ending_sequence()
	_connect_ending_sequence()

	_ensure_fail_screen()
	_connect_fail_screen()

	_set_box_state(BoxState.CLOSED)
	_hide_closeup()
	_hide_hud()

	finish_label.visible = false
	elapsed_time = 0.0
	gameplay_started = false
	introduction_started = false
	finish_pending = false

	_set_box_interaction_enabled(false)
	_set_item_interaction_enabled(false)
	_set_cursor_normal()

	_ensure_introduction()
	_connect_introduction()

	print("Introduction found: ", introduction != null)
	print("Ending node found: ", ending_sequence != null)
	print("Fail screen found: ", fail_screen != null)
	print("HUD created: ", hud_canvas != null)
	print("Music loaded: ", music_player != null and music_player.stream != null)
	print("Ambience loaded: ", ambience_player != null and ambience_player.stream != null)
	print("Time limit: ", time_limit_seconds, " seconds")
	print("========================================")
	print("")

	_start_box_introduction()

func _process(delta: float) -> void:
	if not gameplay_started:
		return

	if _gameplay_has_stopped():
		return

	elapsed_time += delta

	_update_typewriter(delta)
	_update_timer_hud(delta)
	_update_hover_state()

	if elapsed_time >= time_limit_seconds:
		_start_time_limit_failure()

func _input(event: InputEvent) -> void:
	if not gameplay_started:
		return

	if event is InputEventKey:
		if (
			success_test_key_enabled
			and event.keycode == KEY_T
			and event.pressed
			and not event.echo
		):
			if not _gameplay_has_stopped():
				_finish_minigame()
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

	if event.is_action_pressed("ui_accept"):
		_handle_space_pressed()
		get_viewport().set_input_as_handled()
		return

	if dragged_item != null and event is InputEventMouseMotion:
		dragged_item.global_position = (
			get_global_mouse_position()
			+ drag_offset
		)
		_set_cursor_dragging()

	if dragged_item != null and event is InputEventMouseButton:
		if (
			event.button_index == MOUSE_BUTTON_LEFT
			and not event.pressed
		):
			_finish_drag()
			get_viewport().set_input_as_handled()

func _gameplay_has_stopped() -> bool:
	return (
		not gameplay_started
		or ending_started
		or fail_started
	)


func _start_time_limit_failure() -> void:
	if _gameplay_has_stopped():
		return

	fail_started = true
	finish_pending = false

	dragged_item = null
	dragged_item_id = ""
	active_item_id = ""
	drag_offset = Vector2.ZERO

	_reset_hovered_item()
	_stop_typewriter()
	_hide_closeup()
	_hide_hud()
	_set_cursor_normal()
	_set_box_interaction_enabled(false)
	_set_item_interaction_enabled(false)

	_play_sound(
		SFX_FAILURE_TRANSITION,
		general_sfx_volume_db
	)
	_fade_out_background_audio()

	if fail_screen == null:
		_ensure_fail_screen()
		_connect_fail_screen()

	if fail_screen == null:
		push_error(
			"BOX UNBOXING: The shared fail screen is missing."
		)
		return

	if not fail_screen.has_method("start_fail_screen"):
		push_error(
			"BOX UNBOXING: The fail screen is missing "
			+ "start_fail_screen()."
		)
		return

	var dialogue: String = (
		"It's getting late. I searched this box all day.\n"
		+ "I should rest and try again tomorrow."
	)

	var reason: String = (
		"The important clues were not found before "
		+ "the time limit ended."
	)

	print("")
	print("========================================")
	print("BOX UNBOXING FAILED")
	print("Reason: Time limit reached.")
	print("Elapsed time: ", elapsed_time)
	print("========================================")
	print("")

	fail_screen.call(
		"start_fail_screen",
		dialogue,
		reason,
		0,
		false
	)

func _ensure_introduction() -> void:
	var existing_node: Node = get_node_or_null(
		"MinigameIntroduction"
	)

	if existing_node != null:
		var existing_is_valid: bool = (
			existing_node.has_method("start_introduction")
			and existing_node.has_signal("start_requested")
			and existing_node.has_signal("countdown_finished")
		)

		if existing_is_valid:
			introduction = existing_node as CanvasLayer

			if introduction != null:
				introduction.set(
					"auto_start_for_testing",
					false
				)

			return

		remove_child(existing_node)
		existing_node.queue_free()

	if INTRODUCTION_SCENE == null:
		push_error("BOX UNBOXING: Introduction scene could not be loaded.")
		return

	var new_introduction: Node = INTRODUCTION_SCENE.instantiate()

	if new_introduction == null:
		push_error("BOX UNBOXING: Introduction could not be instantiated.")
		return

	new_introduction.name = "MinigameIntroduction"
	new_introduction.set("auto_start_for_testing", false)
	add_child(new_introduction)
	introduction = new_introduction as CanvasLayer


func _connect_introduction() -> void:
	if introduction == null:
		push_error("BOX UNBOXING: Introduction is missing.")
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


func _start_box_introduction() -> void:
	if introduction_started:
		return

	if introduction == null:
		push_error(
			"BOX UNBOXING: Introduction is missing. "
			+ "Starting gameplay directly."
		)
		_start_box_gameplay()
		return

	introduction_started = true
	gameplay_started = false
	elapsed_time = 0.0
	finish_pending = false

	dragged_item = null
	dragged_item_id = ""
	active_item_id = ""
	drag_offset = Vector2.ZERO

	_reset_hovered_item()
	_stop_background_audio_immediately()
	_stop_typewriter()
	_hide_hud()
	_hide_closeup()
	_set_cursor_normal()
	_set_box_state(BoxState.CLOSED)
	_set_box_interaction_enabled(false)
	_set_item_interaction_enabled(false)

	introduction.call(
		"start_introduction",
		"box_unboxing"
	)

func _on_introduction_start_requested() -> void:
	# Show the closed box behind the transparent countdown,
	# but keep every interaction disabled.
	box_closed.visible = true
	box_open.visible = false
	box_contents.visible = false

	_hide_hud()
	_set_cursor_normal()
	_set_box_interaction_enabled(false)
	_set_item_interaction_enabled(false)

func _on_introduction_countdown_finished() -> void:
	_start_box_gameplay()


func _start_box_gameplay() -> void:
	if gameplay_started:
		return

	gameplay_started = true
	elapsed_time = 0.0
	finish_pending = false

	timer_warning_played = false
	timer_critical_played = false
	all_clues_sound_played = false
	hud_pulse_time = 0.0

	dragged_item = null
	dragged_item_id = ""
	active_item_id = ""
	drag_offset = Vector2.ZERO
	inspect_state = InspectState.NONE

	_hide_closeup()
	_set_box_state(BoxState.CLOSED)
	_set_box_interaction_enabled(true)
	_set_item_interaction_enabled(false)
	_show_hud()
	_update_timer_hud(0.0)
	_update_clue_hud()
	_start_background_audio()
	_set_cursor_normal()

	print("")
	print("========================================")
	print("BOX UNBOXING GAMEPLAY STARTED")
	print("Time limit: ", time_limit_seconds)
	print("========================================")
	print("")

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
				"DEBUG BOX: Existing fail screen is valid."
			)

			return

		print(
			"DEBUG BOX: Removing incorrect "
			+ "MinigameFailScreen node."
		)

		remove_child(existing_node)
		existing_node.queue_free()

	if FAIL_SCREEN_SCENE == null:
		push_error(
			"BOX UNBOXING: Fail-screen scene "
			+ "could not be loaded."
		)
		return

	var new_fail_screen: Node = (
		FAIL_SCREEN_SCENE.instantiate()
	)

	if new_fail_screen == null:
		push_error(
			"BOX UNBOXING: Fail screen could not "
			+ "be instantiated."
		)
		return

	new_fail_screen.name = "MinigameFailScreen"
	add_child(new_fail_screen)

	fail_screen = new_fail_screen

	print(
		"DEBUG BOX: Fail screen instantiated automatically."
	)


func _connect_fail_screen() -> void:
	if fail_screen == null:
		push_error(
			"BOX UNBOXING: Fail screen is missing."
		)
		return

	if not fail_screen.has_signal("retry_requested"):
		push_error(
			"BOX UNBOXING: Fail screen is missing "
			+ "retry_requested."
		)
		return

	if not fail_screen.has_signal("exit_requested"):
		push_error(
			"BOX UNBOXING: Fail screen is missing "
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
		"DEBUG BOX: Fail-screen signals connected."
	)


func _on_fail_retry_requested() -> void:
	print(
		"DEBUG BOX: Retry requested."
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
	print("DEBUG BOX: EXIT AFTER FAILURE")
	print("========================================")
	print("")

	minigame_failed.emit()

func _ensure_ending_sequence() -> void:
	print("")
	print("DEBUG: Checking ending scene.")

	var existing_node: Node = get_node_or_null(
		"CollectibleEndingScene"
	)

	if existing_node != null:
		print(
			"DEBUG: Existing CollectibleEndingScene found."
		)

		var existing_is_valid: bool = (
			existing_node.has_method("start_ending")
			and existing_node.has_signal("ending_finished")
		)

		if existing_is_valid:
			ending_sequence = existing_node

			print(
				"DEBUG: Existing ending scene is valid."
			)

			return

		print(
			"DEBUG: Existing node is only an empty or "
			+ "incorrect CanvasLayer."
		)

		remove_child(existing_node)
		existing_node.queue_free()

	if ENDING_SCENE == null:
		push_error(
			"DEBUG: Ending PackedScene could not be loaded."
		)
		return

	var new_ending_scene: Node = ENDING_SCENE.instantiate()

	if new_ending_scene == null:
		push_error(
			"DEBUG: Ending scene could not be instantiated."
		)
		return

	new_ending_scene.name = "CollectibleEndingScene"

	add_child(new_ending_scene)

	ending_sequence = new_ending_scene

	print(
		"DEBUG: Ending scene automatically instantiated."
	)

	print(
		"DEBUG: New ending path: ",
		ending_sequence.get_path()
	)

	print(
		"DEBUG: New ending type: ",
		ending_sequence.get_class()
	)

	print(
		"DEBUG: New ending has start_ending(): ",
		ending_sequence.has_method("start_ending")
	)

	print(
		"DEBUG: New ending has ending_finished signal: ",
		ending_sequence.has_signal("ending_finished")
	)

	print("")


func _connect_ending_sequence() -> void:
	if ending_sequence == null:
		push_error(
			"DEBUG: Ending sequence could not be created."
		)
		return

	if not ending_sequence.has_method("start_ending"):
		push_error(
			"DEBUG: Ending scene does not contain "
			+ "start_ending(). Check the script attached to "
			+ "collectible_ending_scene.tscn."
		)
		return

	if not ending_sequence.has_signal("ending_finished"):
		push_error(
			"DEBUG: Ending scene does not contain "
			+ "the ending_finished signal."
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
			"DEBUG: Connected ending_finished signal."
		)


func _setup_scene_defaults() -> void:
	box_contents.visible = false
	closeup_layer.visible = false
	closeup_layer.layer = 80

	box_closed.visible = true
	box_open.visible = false

	background.z_index = 0
	box_closed.z_index = 2
	box_open.z_index = 2
	box_contents.z_index = 5

	box_closed_base_scale = box_closed.scale
	box_open_base_scale = box_open.scale

	shared_font = load(SHARED_FONT_PATH)

	dim_overlay.position = Vector2.ZERO
	dim_overlay.size = SCREEN_SIZE
	dim_overlay.color = Color(0, 0, 0, 0.75)

	closeup_sprite.position = SCREEN_CENTER
	closeup_sprite.scale = CLOSEUP_ITEM_SCALE
	closeup_sprite.z_index = 5

	dialogue_box.texture = load(DIALOGUE_BOX_PATH)
	dialogue_box.position = SCREEN_CENTER
	dialogue_box.scale = Vector2(0.6, 0.6)
	dialogue_box.z_index = 10

	dialogue_text.position = Vector2(265, 475)
	dialogue_text.size = Vector2(625, 90)
	dialogue_text.z_index = 11
	dialogue_text.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)
	dialogue_text.visible_characters = -1

	dialogue_text.add_theme_font_override(
		"font",
		shared_font
	)

	dialogue_text.add_theme_font_size_override(
		"font_size",
		22
	)

	dialogue_text.add_theme_color_override(
		"font_color",
		Color(0.16, 0.10, 0.06, 1.0)
	)

	if continue_label != null:
		continue_label.position = Vector2(455, 620)
		continue_label.text = "Press SPACE to continue..."
		continue_label.z_index = 11

		continue_label.add_theme_font_override(
			"font",
			shared_font
		)

		continue_label.add_theme_font_size_override(
			"font_size",
			18
		)

		continue_label.add_theme_color_override(
			"font_color",
			Color.WHITE
		)

	finish_label.add_theme_font_override(
		"font",
		shared_font
	)

	finish_label.add_theme_font_size_override(
		"font_size",
		24
	)

	finish_label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

func _connect_box_clicks() -> void:
	box_click_area.input_event.connect(
		_on_box_click_area_input_event
	)

	top_flap_area.input_event.connect(
		_on_flap_area_input_event
	)

	bottom_flap_area.input_event.connect(
		_on_flap_area_input_event
	)

	left_flap_area.input_event.connect(
		_on_flap_area_input_event
	)

	right_flap_area.input_event.connect(
		_on_flap_area_input_event
	)


func _create_content_items() -> void:
	for item_id_value in item_data.keys():
		var item_id: String = str(item_id_value)
		var data: Dictionary = item_data[item_id]

		var item_area: Area2D = Area2D.new()

		item_area.name = str(data["display_name"])
		item_area.input_pickable = true
		item_area.monitoring = true
		item_area.monitorable = true
		item_area.z_index = 5

		var item_sprite: Sprite2D = Sprite2D.new()

		item_sprite.name = "Sprite2D"
		item_sprite.texture = load(
			str(data["texture_path"])
		)

		item_sprite.scale = data["scale"]
		item_sprite.centered = true
		item_sprite.z_index = 1

		var collision: CollisionShape2D = (
			CollisionShape2D.new()
		)

		collision.name = "CollisionShape2D"

		var rectangle_shape: RectangleShape2D = (
			RectangleShape2D.new()
		)

		rectangle_shape.size = data["collision_size"]
		collision.shape = rectangle_shape

		item_area.add_child(item_sprite)
		item_area.add_child(collision)

		box_contents.add_child(item_area)

		item_area.input_event.connect(
			_on_item_input_event.bind(item_id)
		)

		item_nodes[item_id] = item_area


func _position_content_items() -> void:
	var newspaper_node: Area2D = item_nodes["newspaper"]

	newspaper_node.global_position = newspaper_base_position
	newspaper_node.z_index = 3

	item_start_positions["newspaper"] = (
		newspaper_node.global_position
	)
	item_original_z_indices["newspaper"] = newspaper_node.z_index

	var other_ids: Array[String] = []

	for item_id_value in item_data.keys():
		var item_id: String = str(item_id_value)

		if item_id != "newspaper":
			other_ids.append(item_id)

	other_ids.shuffle()

	var offset_pool: Array = other_item_offsets.duplicate()
	offset_pool.shuffle()

	for index in range(other_ids.size()):
		var item_id: String = other_ids[index]
		var item_node: Area2D = item_nodes[item_id]
		var item_offset: Vector2 = offset_pool[index]

		var jitter: Vector2 = Vector2(
			randf_range(-14.0, 14.0),
			randf_range(-12.0, 12.0)
		)

		item_node.global_position = (
			pile_center
			+ item_offset
			+ jitter
		)

		item_node.z_index = 5 + index

		item_start_positions[item_id] = (
			item_node.global_position
		)
		item_original_z_indices[item_id] = item_node.z_index

func _on_box_click_area_input_event(
	_viewport: Node,
	event: InputEvent,
	_shape_index: int
) -> void:
	if not gameplay_started:
		return

	if _gameplay_has_stopped():
		return

	if not _is_left_mouse_press(event):
		return

	if (
		box_state == BoxState.CLOSED
		and inspect_state == InspectState.NONE
	):
		_open_box()


func _on_flap_area_input_event(
	_viewport: Node,
	event: InputEvent,
	_shape_index: int
) -> void:
	if not gameplay_started:
		return

	if _gameplay_has_stopped():
		return

	if not _is_left_mouse_press(event):
		return

	if (
		box_state == BoxState.OPEN
		and inspect_state == InspectState.NONE
	):
		_close_box()


func _on_item_input_event(
	_viewport: Node,
	event: InputEvent,
	_shape_index: int,
	item_id: String
) -> void:
	if not gameplay_started:
		return

	if _gameplay_has_stopped():
		return

	if box_state != BoxState.OPEN:
		return

	if inspect_state != InspectState.NONE:
		return

	if bool(removed_items[item_id]):
		return

	if not _is_left_mouse_press(event):
		return

	if not _is_topmost_item_at_mouse(item_id):
		return

	_start_drag(item_id)


func _is_topmost_item_at_mouse(item_id: String) -> bool:
	var mouse_position: Vector2 = (
		get_global_mouse_position()
	)

	var top_item_id: String = ""
	var top_z_index: int = -999999

	for check_id_value in item_nodes.keys():
		var check_id: String = str(check_id_value)

		if bool(removed_items[check_id]):
			continue

		var item_node: Area2D = item_nodes[check_id]

		if not item_node.visible:
			continue

		if not _mouse_inside_item_collision(
			item_node,
			mouse_position
		):
			continue

		if item_node.z_index > top_z_index:
			top_z_index = item_node.z_index
			top_item_id = check_id

	return top_item_id == item_id


func _mouse_inside_item_collision(
	item_node: Area2D,
	mouse_position: Vector2
) -> bool:
	var collision: CollisionShape2D = (
		item_node.get_node_or_null("CollisionShape2D")
	)

	if collision == null:
		return false

	if collision.shape == null:
		return false

	if collision.shape is RectangleShape2D:
		var rectangle_shape: RectangleShape2D = (
			collision.shape
		)

		var local_mouse: Vector2 = (
			item_node.to_local(mouse_position)
		)

		var half_size: Vector2 = (
			rectangle_shape.size * 0.5
		)

		var collision_rectangle: Rect2 = Rect2(
			-half_size,
			rectangle_shape.size
		)

		return collision_rectangle.has_point(local_mouse)

	return false


func _start_drag(item_id: String) -> void:
	var item_node: Area2D = item_nodes[item_id]

	_reset_hovered_item()

	dragged_item = item_node
	dragged_item_id = item_id
	active_item_id = item_id

	drag_offset = (
		item_node.global_position
		- get_global_mouse_position()
	)

	_move_item_to_front(item_node)

	var sprite: Sprite2D = item_node.get_node("Sprite2D")
	var original_scale: Vector2 = item_data[item_id]["scale"]

	sprite.scale = original_scale * drag_scale_multiplier
	_set_cursor_dragging()

	_play_sound(
		SFX_UI_CLICK,
		ui_sfx_volume_db - 4.0
	)
	_play_sound(
		SFX_ITEM_PICKUP,
		general_sfx_volume_db - 7.0
	)
	_play_material_pickup_sound(item_id)

func _finish_drag() -> void:
	if dragged_item == null:
		return

	var item_id: String = dragged_item_id

	var sprite: Sprite2D = dragged_item.get_node("Sprite2D")
	sprite.scale = item_data[item_id]["scale"]

	if _is_mouse_outside_box():
		_show_closeup(item_id)
	else:
		_return_item_to_box(item_id)

	dragged_item = null
	dragged_item_id = ""
	drag_offset = Vector2.ZERO
	_set_cursor_normal()

func _is_mouse_outside_box() -> bool:
	var mouse_position: Vector2 = (
		get_global_mouse_position()
	)

	var box_inside_rectangle: Rect2 = Rect2(
		Vector2(365, 120),
		Vector2(425, 405)
	)

	return not box_inside_rectangle.has_point(
		mouse_position
	)


func _return_item_to_box(item_id: String) -> void:
	if bool(removed_items[item_id]):
		return

	var item_node: Area2D = item_nodes[item_id]
	var start_position: Vector2 = item_start_positions[item_id]
	var original_z: int = int(
		item_original_z_indices.get(item_id, 5)
	)

	_play_sound(
		SFX_ITEM_RETURN,
		general_sfx_volume_db - 3.0
	)

	item_node.z_index = 20
	_set_area_enabled(item_node, false)

	var return_tween: Tween = create_tween()
	return_tween.set_parallel(false)

	return_tween.tween_property(
		item_node,
		"global_position",
		start_position + Vector2(0, -10),
		item_return_duration * 0.55
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	return_tween.tween_property(
		item_node,
		"global_position",
		start_position,
		item_return_duration * 0.45
	).set_trans(
		Tween.TRANS_BOUNCE
	).set_ease(
		Tween.EASE_OUT
	)

	return_tween.finished.connect(
		func() -> void:
			if not is_instance_valid(item_node):
				return

			item_node.z_index = original_z

			if (
				gameplay_started
				and not _gameplay_has_stopped()
				and box_state == BoxState.OPEN
				and inspect_state == InspectState.NONE
			):
				_set_area_enabled(item_node, true)
	)

func _show_closeup(item_id: String) -> void:
	print("DEBUG: Showing close-up for: ", item_id)

	active_item_id = item_id
	inspect_state = InspectState.CLOSEUP_ONLY

	_reset_hovered_item()
	_set_cursor_normal()
	_set_box_interaction_enabled(false)
	_set_item_interaction_enabled(false)

	closeup_layer.visible = true
	dim_overlay.visible = true
	closeup_sprite.visible = true

	dialogue_box.visible = false
	dialogue_text.visible = false
	dialogue_text.visible_characters = -1

	if continue_label != null:
		continue_label.visible = true
		continue_label.text = "Press SPACE to read..."

	var closeup_path: String = str(
		item_data[item_id]["closeup_path"]
	)

	if (
		closeup_path != ""
		and ResourceLoader.exists(closeup_path)
	):
		closeup_sprite.texture = load(closeup_path)
	else:
		var item_node: Area2D = item_nodes[item_id]
		var item_sprite: Sprite2D = item_node.get_node(
			"Sprite2D"
		)
		closeup_sprite.texture = item_sprite.texture

	closeup_sprite.position = SCREEN_CENTER
	closeup_sprite.scale = CLOSEUP_ITEM_SCALE * 0.86
	closeup_sprite.modulate = Color(1, 1, 1, 0)
	dim_overlay.color.a = 0.0

	_play_sound(
		SFX_CLOSEUP_OPEN,
		general_sfx_volume_db - 2.0
	)

	if closeup_tween != null:
		closeup_tween.kill()

	closeup_tween = create_tween()
	closeup_tween.set_parallel(true)
	closeup_tween.tween_property(
		dim_overlay,
		"color:a",
		0.75,
		closeup_transition_duration
	)
	closeup_tween.tween_property(
		closeup_sprite,
		"modulate:a",
		1.0,
		closeup_transition_duration
	)
	closeup_tween.tween_property(
		closeup_sprite,
		"scale",
		CLOSEUP_ITEM_SCALE,
		closeup_transition_duration
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	_remove_item_from_box(item_id)

func _remove_item_from_box(item_id: String) -> void:
	removed_items[item_id] = true

	var item_node: Area2D = item_nodes[item_id]

	item_node.visible = false
	_set_area_enabled(item_node, false)

	print("DEBUG: Removed item from box: ", item_id)


func _handle_space_pressed() -> void:
	match inspect_state:
		InspectState.NONE:
			return

		InspectState.CLOSEUP_ONLY:
			_show_dialogue()

		InspectState.DIALOGUE_VISIBLE:
			if typewriter_active:
				_complete_typewriter()
				_play_sound(
					SFX_DIALOGUE_CONTINUE,
					ui_sfx_volume_db
				)
			else:
				_close_inspection()

func _show_dialogue() -> void:
	inspect_state = InspectState.DIALOGUE_VISIBLE

	dialogue_box.visible = true
	dialogue_text.visible = true
	dialogue_box.modulate.a = 0.0
	dialogue_text.modulate.a = 0.0

	_play_sound(
		SFX_DIALOGUE_OPEN,
		ui_sfx_volume_db
	)

	var dialogue_tween: Tween = create_tween()
	dialogue_tween.set_parallel(true)
	dialogue_tween.tween_property(
		dialogue_box,
		"modulate:a",
		1.0,
		0.14
	)
	dialogue_tween.tween_property(
		dialogue_text,
		"modulate:a",
		1.0,
		0.14
	)

	_start_typewriter(
		str(item_data[active_item_id]["dialogue"])
	)

	if continue_label != null:
		continue_label.visible = true
		continue_label.text = "Press SPACE to complete..."

func _close_inspection() -> void:
	if inspect_state == InspectState.NONE:
		return

	var completed_item_id: String = active_item_id

	print(
		"DEBUG: Closing inspection for: ",
		completed_item_id
	)

	inspect_state = InspectState.NONE
	_stop_typewriter()

	var discovered_new_clue: bool = false

	if viewed_required_items.has(completed_item_id):
		if not bool(viewed_required_items[completed_item_id]):
			viewed_required_items[completed_item_id] = true
			discovered_new_clue = true
			_update_clue_hud()

	if discovered_new_clue:
		_play_sound(
			SFX_CLUE_DISCOVERED,
			general_sfx_volume_db
		)

		if _get_required_clue_count() >= 3:
			all_clues_sound_played = true
			_play_sound(
				SFX_ALL_CLUES_FOUND,
				general_sfx_volume_db
			)

	_play_sound(
		SFX_DIALOGUE_CONTINUE,
		ui_sfx_volume_db - 2.0
	)
	_play_sound(
		SFX_CLOSEUP_CLOSE,
		general_sfx_volume_db - 2.0
	)

	if closeup_tween != null:
		closeup_tween.kill()

	closeup_tween = create_tween()
	closeup_tween.set_parallel(true)
	closeup_tween.tween_property(
		dim_overlay,
		"color:a",
		0.0,
		closeup_transition_duration
	)
	closeup_tween.tween_property(
		closeup_sprite,
		"modulate:a",
		0.0,
		closeup_transition_duration
	)
	closeup_tween.tween_property(
		closeup_sprite,
		"scale",
		CLOSEUP_ITEM_SCALE * 0.90,
		closeup_transition_duration
	)
	closeup_tween.tween_property(
		dialogue_box,
		"modulate:a",
		0.0,
		closeup_transition_duration * 0.75
	)
	closeup_tween.tween_property(
		dialogue_text,
		"modulate:a",
		0.0,
		closeup_transition_duration * 0.75
	)

	closeup_tween.finished.connect(
		_complete_close_inspection.bind(completed_item_id),
		CONNECT_ONE_SHOT
	)

func _hide_closeup() -> void:
	if closeup_tween != null:
		closeup_tween.kill()
		closeup_tween = null

	_stop_typewriter()

	closeup_layer.visible = false
	dim_overlay.visible = false
	dim_overlay.color.a = 0.75
	closeup_sprite.visible = false
	closeup_sprite.scale = CLOSEUP_ITEM_SCALE
	closeup_sprite.modulate = Color.WHITE
	dialogue_box.visible = false
	dialogue_box.modulate = Color.WHITE
	dialogue_text.visible = false
	dialogue_text.modulate = Color.WHITE
	dialogue_text.visible_characters = -1

	if continue_label != null:
		continue_label.visible = false

func _open_box() -> void:
	_play_sound(
		SFX_UI_CLICK,
		ui_sfx_volume_db - 5.0
	)
	_play_sound(
		SFX_BOX_OPEN,
		general_sfx_volume_db
	)
	_play_sound(
		SFX_CARDBOARD_RUSTLE,
		general_sfx_volume_db - 8.0,
		randf_range(0.96, 1.04)
	)

	_set_box_state(BoxState.OPEN)
	_animate_box_sprite(
		box_open,
		box_open_base_scale
	)

func _close_box() -> void:
	_reset_hovered_item()
	_play_sound(
		SFX_UI_CLICK,
		ui_sfx_volume_db - 5.0
	)
	_play_sound(
		SFX_BOX_CLOSE,
		general_sfx_volume_db
	)
	_play_sound(
		SFX_CARDBOARD_RUSTLE,
		general_sfx_volume_db - 10.0,
		randf_range(0.94, 1.02)
	)

	_set_box_state(BoxState.CLOSED)
	_animate_box_sprite(
		box_closed,
		box_closed_base_scale
	)

func _set_box_state(new_state: BoxState) -> void:
	box_state = new_state

	match box_state:
		BoxState.CLOSED:
			box_closed.visible = true
			box_open.visible = false
			box_contents.visible = false

			_set_area_enabled(box_click_area, true)

			_set_area_enabled(top_flap_area, false)
			_set_area_enabled(bottom_flap_area, false)
			_set_area_enabled(left_flap_area, false)
			_set_area_enabled(right_flap_area, false)

			_set_item_interaction_enabled(false)

		BoxState.OPEN:
			box_closed.visible = false
			box_open.visible = true
			box_contents.visible = true

			_set_area_enabled(box_click_area, false)

			_set_area_enabled(top_flap_area, true)
			_set_area_enabled(bottom_flap_area, true)
			_set_area_enabled(left_flap_area, true)
			_set_area_enabled(right_flap_area, true)

			_set_item_interaction_enabled(true)


func _set_box_interaction_enabled(enabled: bool) -> void:
	if box_state == BoxState.CLOSED:
		_set_area_enabled(box_click_area, enabled)
	else:
		_set_area_enabled(top_flap_area, enabled)
		_set_area_enabled(bottom_flap_area, enabled)
		_set_area_enabled(left_flap_area, enabled)
		_set_area_enabled(right_flap_area, enabled)


func _set_item_interaction_enabled(enabled: bool) -> void:
	for item_id_value in item_nodes.keys():
		var item_id: String = str(item_id_value)
		var item_node: Area2D = item_nodes[item_id]

		if bool(removed_items[item_id]):
			_set_area_enabled(item_node, false)
			continue

		_set_area_enabled(item_node, enabled)


func _set_area_enabled(
	area: Area2D,
	enabled: bool
) -> void:
	area.monitoring = enabled
	area.monitorable = enabled
	area.input_pickable = enabled

	for child in area.get_children():
		if child is CollisionShape2D:
			child.set_deferred(
				"disabled",
				not enabled
			)


func _move_item_to_front(item_node: Area2D) -> void:
	item_node.z_index = 20


func _check_finish_condition() -> void:
	if _gameplay_has_stopped():
		return

	var newspaper_viewed: bool = bool(
		viewed_required_items["newspaper"]
	)

	var photo_viewed: bool = bool(
		viewed_required_items["photo"]
	)

	var key_viewed: bool = bool(
		viewed_required_items["key"]
	)

	print("")
	print("DEBUG: Checking finish condition.")
	print("DEBUG: Newspaper viewed: ", newspaper_viewed)
	print("DEBUG: Photo viewed: ", photo_viewed)
	print("DEBUG: Key viewed: ", key_viewed)
	print("DEBUG: Full required status: ", viewed_required_items)

	if newspaper_viewed and photo_viewed and key_viewed:
		if finish_pending:
			return

		finish_pending = true

		if not all_clues_sound_played:
			all_clues_sound_played = true
			_play_sound(
				SFX_ALL_CLUES_FOUND,
				general_sfx_volume_db
			)

		_begin_finish_after_delay()
	else:
		print("DEBUG: Required items are still missing.")

	print("")

func _finish_minigame() -> void:
	if _gameplay_has_stopped():
		return

	print("")
	print("========================================")
	print("DEBUG: _finish_minigame called.")
	print("========================================")

	if ending_sequence == null:
		_ensure_ending_sequence()
		_connect_ending_sequence()

	if ending_sequence == null:
		push_error(
			"DEBUG: Ending scene still could not be created."
		)
		return

	if not ending_sequence.has_method("start_ending"):
		push_error(
			"DEBUG: Ending scene is missing start_ending()."
		)
		return

	if ENDING_COLLECTIBLE == null:
		push_error(
			"DEBUG: Ending collectible texture is missing."
		)
		return

	ending_started = true
	finish_pending = false

	finish_label.visible = false

	dragged_item = null
	dragged_item_id = ""
	active_item_id = ""
	drag_offset = Vector2.ZERO

	_reset_hovered_item()
	_stop_typewriter()
	_hide_closeup()
	_hide_hud()
	_set_cursor_normal()
	_set_box_interaction_enabled(false)
	_set_item_interaction_enabled(false)

	_play_sound(
		SFX_SUCCESS_TRANSITION,
		general_sfx_volume_db
	)
	_fade_out_background_audio()

	print(
		"DEBUG: Calling ending_sequence.start_ending()."
	)

	ending_sequence.call(
		"start_ending",
		ENDING_COLLECTIBLE,
		Vector2(0.6, 0.6)
	)

func _on_ending_sequence_finished() -> void:
	if result_emitted:
		return

	result_emitted = true
	_stop_background_audio_immediately()
	_set_cursor_normal()

	print("")
	print("========================================")
	print("DEBUG: BOX ENDING COMPLETELY FINISHED")
	print("========================================")
	print("")

	minigame_finished.emit()


# =========================================================
# POLISHED HUD
# =========================================================

func _setup_hud() -> void:
	hud_canvas = CanvasLayer.new()
	hud_canvas.name = "PolishHUD"
	hud_canvas.layer = hud_layer
	add_child(hud_canvas)

	hud_root = Control.new()
	hud_root.name = "HUDRoot"
	hud_root.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_canvas.add_child(hud_root)

	timer_clue_frame = Sprite2D.new()
	timer_clue_frame.name = "TimerClueFrame"
	timer_clue_frame.centered = true
	timer_clue_frame.position = SCREEN_CENTER
	timer_clue_frame.scale = hud_full_canvas_scale
	timer_clue_frame.z_index = 0

	if ResourceLoader.exists(TIMER_CLUE_FRAME_PATH):
		timer_clue_frame.texture = load(TIMER_CLUE_FRAME_PATH)
	else:
		push_warning(
			"Missing HUD frame: " + TIMER_CLUE_FRAME_PATH
		)

	hud_root.add_child(timer_clue_frame)

	timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.position = timer_label_position
	timer_label.size = timer_label_size
	_style_hud_label(timer_label)
	hud_root.add_child(timer_label)

	clue_label = Label.new()
	clue_label.name = "ClueLabel"
	clue_label.position = clue_label_position
	clue_label.size = clue_label_size
	_style_hud_label(clue_label)
	hud_root.add_child(clue_label)

	warning_icon = Sprite2D.new()
	warning_icon.name = "TimerWarningIcon"
	warning_icon.centered = true
	warning_icon.position = warning_icon_position
	warning_icon.z_index = 3
	warning_icon.visible = false

	if ResourceLoader.exists(TIMER_WARNING_ICON_PATH):
		warning_icon.texture = load(TIMER_WARNING_ICON_PATH)
		warning_icon_base_scale = _get_sprite_fit_scale(
			warning_icon.texture,
			warning_icon_display_size
		)
		warning_icon.scale = warning_icon_base_scale
	else:
		push_warning(
			"Missing warning icon: "
			+ TIMER_WARNING_ICON_PATH
		)

	hud_root.add_child(warning_icon)
	_hide_hud()


func _style_hud_label(label: Label) -> void:
	label.z_index = 2
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	if shared_font != null:
		label.add_theme_font_override("font", shared_font)

	label.add_theme_font_size_override(
		"font_size",
		hud_font_size
	)
	label.add_theme_color_override(
		"font_color",
		Color("f8e5b9")
	)
	label.add_theme_color_override(
		"font_shadow_color",
		Color(0.08, 0.04, 0.02, 0.95)
	)
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)


func _show_hud() -> void:
	if hud_canvas != null:
		hud_canvas.visible = true


func _hide_hud() -> void:
	if hud_canvas != null:
		hud_canvas.visible = false


func _update_timer_hud(delta: float) -> void:
	if timer_label == null:
		return

	var remaining: float = maxf(
		time_limit_seconds - elapsed_time,
		0.0
	)

	var minutes: int = int(int(remaining) / 60)
	var seconds: int = int(remaining) % 60

	timer_label.text = "%02d:%02d" % [minutes, seconds]

	if remaining <= timer_critical_seconds:
		timer_label.add_theme_color_override(
			"font_color",
			Color("ff786b")
		)
	elif remaining <= timer_warning_seconds:
		timer_label.add_theme_color_override(
			"font_color",
			Color("ffd36a")
		)
	else:
		timer_label.add_theme_color_override(
			"font_color",
			Color("f8e5b9")
		)

	if warning_icon != null:
		warning_icon.visible = (
			remaining <= timer_warning_seconds
		)

		if warning_icon.visible:
			hud_pulse_time += delta
			var pulse_amount: float = 1.0 + (
				sin(hud_pulse_time * 6.0) * 0.08
			)
			warning_icon.scale = (
				warning_icon_base_scale
				* pulse_amount
			)
		else:
			warning_icon.scale = warning_icon_base_scale

	if (
		remaining <= timer_warning_seconds
		and not timer_warning_played
	):
		timer_warning_played = true
		_play_sound(
			SFX_TIMER_WARNING,
			general_sfx_volume_db - 2.0
		)

	if (
		remaining <= timer_critical_seconds
		and not timer_critical_played
	):
		timer_critical_played = true
		_play_sound(
			SFX_TIMER_WARNING,
			general_sfx_volume_db,
			1.12
		)


func _update_clue_hud() -> void:
	if clue_label == null:
		return

	clue_label.text = (
		str(_get_required_clue_count())
		+ " / 3"
	)


func _get_required_clue_count() -> int:
	var count: int = 0

	for item_id_value in viewed_required_items.keys():
		var item_id: String = str(item_id_value)

		if bool(viewed_required_items[item_id]):
			count += 1

	return count


func _get_sprite_fit_scale(
	texture: Texture2D,
	target_size: Vector2
) -> Vector2:
	if texture == null:
		return Vector2.ONE

	var texture_size: Vector2 = texture.get_size()

	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Vector2.ONE

	return Vector2(
		target_size.x / texture_size.x,
		target_size.y / texture_size.y
	)


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

	if music_player != null:
		fade_tween.tween_property(
			music_player,
			"volume_db",
			music_volume_db,
			audio_fade_duration
		)

	if ambience_player != null:
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


func _play_material_pickup_sound(item_id: String) -> void:
	match item_id:
		"newspaper", "photo", "receipt", "letter":
			var paper_path: String = (
				SFX_PAPER_PICKUP_01
				if randi() % 2 == 0
				else SFX_PAPER_PICKUP_02
			)
			_play_sound(
				paper_path,
				general_sfx_volume_db - 1.0,
				randf_range(0.96, 1.04)
			)

		"key", "spoon":
			_play_sound(
				SFX_METAL_PICKUP,
				general_sfx_volume_db - 1.0,
				randf_range(0.97, 1.04)
			)

		"bowl_piece":
			_play_sound(
				SFX_CERAMIC_PICKUP,
				general_sfx_volume_db - 1.0,
				randf_range(0.97, 1.03)
			)


# =========================================================
# CUSTOM CURSORS AND HOVER
# =========================================================

func _setup_custom_cursors() -> void:
	cursor_normal_texture = _load_resized_cursor(
		CURSOR_NORMAL_PATH,
		Vector2i(64, 64)
	)
	cursor_grab_texture = _load_resized_cursor(
		CURSOR_GRAB_PATH,
		Vector2i(64, 64)
	)
	cursor_dragging_texture = _load_resized_cursor(
		CURSOR_DRAGGING_PATH,
		Vector2i(64, 64)
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
			Vector2(3, 3)
		)


func _set_cursor_grab() -> void:
	if cursor_grab_texture != null:
		Input.set_custom_mouse_cursor(
			cursor_grab_texture,
			Input.CURSOR_ARROW,
			Vector2(32, 27)
		)


func _set_cursor_dragging() -> void:
	if cursor_dragging_texture != null:
		Input.set_custom_mouse_cursor(
			cursor_dragging_texture,
			Input.CURSOR_ARROW,
			Vector2(32, 29)
		)


func _update_hover_state() -> void:
	if dragged_item != null:
		_set_cursor_dragging()
		return

	if inspect_state != InspectState.NONE:
		_reset_hovered_item()
		_set_cursor_normal()
		return

	if box_state == BoxState.CLOSED:
		var closed_box_rect: Rect2 = Rect2(
			Vector2(365, 120),
			Vector2(425, 405)
		)

		var mouse_over_closed_box: bool = (
			closed_box_rect.has_point(
				get_global_mouse_position()
			)
		)

		if mouse_over_closed_box:
			if hovered_item_id != "__box__":
				_reset_hovered_item()
				hovered_item_id = "__box__"
				_play_sound(
					SFX_UI_HOVER,
					ui_sfx_volume_db - 5.0
				)
			_set_cursor_grab()
		else:
			if hovered_item_id != "":
				_reset_hovered_item()
			_set_cursor_normal()

		return

	var new_hovered_id: String = (
		_get_topmost_item_id_at_mouse()
	)

	if new_hovered_id == hovered_item_id:
		if new_hovered_id == "":
			_set_cursor_normal()
		else:
			_set_cursor_grab()
		return

	_reset_hovered_item()

	if new_hovered_id == "":
		_set_cursor_normal()
		return

	hovered_item_id = new_hovered_id

	var item_node: Area2D = item_nodes[new_hovered_id]
	var sprite: Sprite2D = item_node.get_node("Sprite2D")
	var original_scale: Vector2 = item_data[new_hovered_id]["scale"]

	sprite.scale = original_scale * hover_scale_multiplier
	_set_cursor_grab()
	_play_sound(
		SFX_UI_HOVER,
		ui_sfx_volume_db - 5.0
	)


func _reset_hovered_item() -> void:
	if item_nodes.has(hovered_item_id):
		var item_node: Area2D = item_nodes[hovered_item_id]

		if is_instance_valid(item_node):
			var sprite: Sprite2D = item_node.get_node_or_null(
				"Sprite2D"
			) as Sprite2D

			if sprite != null:
				sprite.scale = item_data[hovered_item_id]["scale"]

	hovered_item_id = ""


func _get_topmost_item_id_at_mouse() -> String:
	if box_state != BoxState.OPEN:
		return ""

	var mouse_position: Vector2 = get_global_mouse_position()
	var top_item_id: String = ""
	var top_z_index: int = -999999

	for item_id_value in item_nodes.keys():
		var item_id: String = str(item_id_value)

		if bool(removed_items[item_id]):
			continue

		var item_node: Area2D = item_nodes[item_id]

		if not item_node.visible or not item_node.input_pickable:
			continue

		if not _mouse_inside_item_collision(
			item_node,
			mouse_position
		):
			continue

		if item_node.z_index > top_z_index:
			top_z_index = item_node.z_index
			top_item_id = item_id

	return top_item_id


# =========================================================
# TYPEWRITER DIALOGUE
# =========================================================

func _start_typewriter(text: String) -> void:
	typewriter_full_text = text
	typewriter_visible_characters = 0
	typewriter_accumulator = 0.0
	typewriter_active = true

	dialogue_text.text = typewriter_full_text
	dialogue_text.visible_characters = 0


func _update_typewriter(delta: float) -> void:
	if not typewriter_active:
		return

	if typewriter_character_delay <= 0.0:
		_complete_typewriter()
		return

	typewriter_accumulator += delta

	while (
		typewriter_accumulator >= typewriter_character_delay
		and typewriter_active
	):
		typewriter_accumulator -= typewriter_character_delay
		typewriter_visible_characters += 1

		if (
			typewriter_visible_characters
			>= typewriter_full_text.length()
		):
			_complete_typewriter()
			return

		dialogue_text.visible_characters = (
			typewriter_visible_characters
		)

		if (
			typewriter_tick_every_characters > 0
			and typewriter_visible_characters
			% typewriter_tick_every_characters == 0
		):
			var character: String = typewriter_full_text.substr(
				typewriter_visible_characters - 1,
				1
			)

			if character.strip_edges() != "":
				typewriter_tick_alternate = (
					not typewriter_tick_alternate
				)
				_play_sound(
					SFX_TEXT_TICK_01
					if typewriter_tick_alternate
					else SFX_TEXT_TICK_02,
					typewriter_sfx_volume_db,
					randf_range(0.97, 1.03)
				)


func _complete_typewriter() -> void:
	if dialogue_text == null:
		return

	typewriter_active = false
	typewriter_visible_characters = typewriter_full_text.length()
	dialogue_text.visible_characters = -1

	if continue_label != null:
		continue_label.text = "Press SPACE to return..."


func _stop_typewriter() -> void:
	typewriter_active = false
	typewriter_full_text = ""
	typewriter_accumulator = 0.0
	typewriter_visible_characters = 0

	if dialogue_text != null:
		dialogue_text.visible_characters = -1


# =========================================================
# SMALL POLISH HELPERS
# =========================================================

func _animate_box_sprite(
	sprite: Sprite2D,
	base_scale: Vector2
) -> void:
	if box_tween != null:
		box_tween.kill()

	sprite.scale = base_scale * 0.94
	sprite.modulate = Color(1, 1, 1, 0.55)

	box_tween = create_tween()
	box_tween.set_parallel(true)
	box_tween.tween_property(
		sprite,
		"scale",
		base_scale,
		0.18
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)
	box_tween.tween_property(
		sprite,
		"modulate",
		Color.WHITE,
		0.12
	)


func _complete_close_inspection(
	completed_item_id: String
) -> void:
	_hide_closeup()
	active_item_id = ""

	if _gameplay_has_stopped():
		return

	_set_box_interaction_enabled(true)
	_set_item_interaction_enabled(true)
	_set_cursor_normal()
	_check_finish_condition()


func _begin_finish_after_delay() -> void:
	await get_tree().create_timer(0.55, false).timeout

	if _gameplay_has_stopped():
		return

	_finish_minigame()


func _is_left_mouse_press(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return (
			event.button_index == MOUSE_BUTTON_LEFT
			and event.pressed
		)

	return false
