extends CanvasLayer

signal ending_finished

enum EndingState {
	IDLE,
	DARKENING_BACKGROUND,
	POPPING_COLLECTIBLE,
	WAITING_FOR_SPACE,
	BAG_SLIDING_IN,
	DRAGGING_COLLECTIBLE,
	COLLECTING_ITEM,
	BAG_SLIDING_OUT,
	FINAL_FADING,
	FINISHED
}

const SHARED_FONT_PATH: String = (
	"res://features/minigames/shared/fonts/VCR_OSD_MONO_1.001.ttf"
)


const ENDING_AUDIO_ROOT: String = (
	"res://features/minigames/ending_sequence/assets/audio/"
)

const BGM_COLLECTIBLE_ENDING_PATH: String = (
	ENDING_AUDIO_ROOT
	+ "music/bgm_collectible_ending_loop.ogg"
)

const SFX_ENDING_TRIGGER_PATH: String = (
	ENDING_AUDIO_ROOT
	+ "sfx/sfx_ending_trigger.wav"
)

const SFX_ENDING_DARKEN_SWELL_PATH: String = (
	ENDING_AUDIO_ROOT
	+ "sfx/sfx_ending_darken_swell.wav"
)

const SFX_COLLECTIBLE_POP_PATH: String = (
	ENDING_AUDIO_ROOT
	+ "sfx/sfx_collectible_pop.wav"
)

const SFX_PROMPT_APPEAR_PATH: String = (
	ENDING_AUDIO_ROOT
	+ "sfx/sfx_prompt_appear.wav"
)

const SFX_SPACE_CONTINUE_PATH: String = (
	ENDING_AUDIO_ROOT
	+ "sfx/sfx_space_continue.wav"
)

const SFX_BAG_SLIDE_IN_PATH: String = (
	ENDING_AUDIO_ROOT
	+ "sfx/sfx_bag_slide_in.wav"
)

const SFX_COLLECTIBLE_PICKUP_PATH: String = (
	ENDING_AUDIO_ROOT
	+ "sfx/sfx_collectible_pickup.wav"
)

const SFX_COLLECTIBLE_RELEASE_PATH: String = (
	ENDING_AUDIO_ROOT
	+ "sfx/sfx_collectible_release.wav"
)

const SFX_COLLECTIBLE_RETURN_PATH: String = (
	ENDING_AUDIO_ROOT
	+ "sfx/sfx_collectible_return.wav"
)

const SFX_BAG_ACCEPT_PATH: String = (
	ENDING_AUDIO_ROOT
	+ "sfx/sfx_bag_accept.wav"
)

const SFX_COLLECTIBLE_ENTER_BAG_PATH: String = (
	ENDING_AUDIO_ROOT
	+ "sfx/sfx_collectible_enter_bag.wav"
)

const SFX_BAG_SLIDE_OUT_PATH: String = (
	ENDING_AUDIO_ROOT
	+ "sfx/sfx_bag_slide_out.wav"
)

const SFX_FINAL_FADE_SWELL_PATH: String = (
	ENDING_AUDIO_ROOT
	+ "sfx/sfx_final_fade_swell.wav"
)

const SFX_ENDING_COMPLETE_PATH: String = (
	ENDING_AUDIO_ROOT
	+ "sfx/sfx_ending_complete.wav"
)

const SFX_UI_HOVER_PATH: String = (
	ENDING_AUDIO_ROOT
	+ "ui/sfx_ui_hover.wav"
)

const SFX_UI_CLICK_PATH: String = (
	ENDING_AUDIO_ROOT
	+ "ui/sfx_ui_click.wav"
)

@onready var ending_root: Control = $EndingRoot
@onready var dim_overlay: ColorRect = $EndingRoot/DimOverlay

@onready var bag: Node2D = $EndingRoot/Bag
@onready var bag_back: Sprite2D = $EndingRoot/Bag/BagBack
@onready var bag_front: Sprite2D = $EndingRoot/Bag/BagFront

@onready var bag_drop_zone: Area2D = (
	$EndingRoot/Bag/BagDropZone
)

@onready var bag_drop_collision: CollisionShape2D = (
	$EndingRoot/Bag/BagDropZone/CollisionShape2D
)

@onready var bag_mouth: Marker2D = (
	$EndingRoot/Bag/BagMouth
)

@onready var collectible: Area2D = (
	$EndingRoot/DraggableCollectible
)

@onready var final_fade: ColorRect = (
	$EndingRoot/FinalFade
)

var prompt_label: Label = null


@export_category("Canvas")
@export var ending_canvas_layer: int = 100


@export_category("Beginning Darkness")

@export_range(0.0, 1.0, 0.05)
var dim_target_alpha: float = 0.80

@export var initial_dim_duration: float = 5.0


@export_category("Collectible")

@export var collectible_final_position: Vector2 = Vector2(
	576,
	324
)

@export var collectible_pop_duration: float = 0.45

@export var collectible_collision_size: Vector2 = Vector2(
	260,
	180
)


@export_category("Prompt")

@export_multiline var prompt_text: String = (
	"Press SPACE to place the clue in your bag"
)

@export var prompt_position: Vector2 = Vector2(
	176,
	485
)

@export var prompt_size: Vector2 = Vector2(
	800,
	60
)

@export var prompt_font_size: int = 22
@export var prompt_fade_duration: float = 0.30


@export_category("Bag")

# The full-canvas bag asset is shown at this position.
@export var bag_final_position: Vector2 = Vector2(
	576,
	324
)

@export var bag_display_scale: Vector2 = Vector2(
	0.6,
	0.6
)

@export var bag_hidden_offset: Vector2 = Vector2(
	0,
	700
)

@export var bag_slide_in_duration: float = 0.75
@export var bag_slide_out_duration: float = 0.75


@export_category("Bag Acceptance Area")

# Screen coordinate of the visible bag opening.
# This is intentionally near the bottom because your logs show
# the collectible being released around Y 580 to 690.
@export var bag_drop_screen_center: Vector2 = Vector2(
	576,
	620
)

# Actual acceptance size in screen pixels.
@export var bag_drop_screen_size: Vector2 = Vector2(
	700,
	300
)

# The collectible shrinks toward this screen position.
@export var bag_mouth_screen_position: Vector2 = Vector2(
	576,
	600
)


@export_category("Collecting")

@export var item_enter_bag_duration: float = 0.45

@export var item_inside_bag_scale: Vector2 = Vector2(
	0.18,
	0.18
)


@export_category("Final Darkness")

@export var final_fade_duration: float = 5.0


@export_category("Audio")

@export var ending_music_volume_db: float = -16.0
@export var ending_sfx_volume_db: float = -3.0
@export var ending_ui_volume_db: float = -10.0

@export var ending_music_fade_in_time: float = 2.0
@export var ending_music_fade_out_time: float = 3.5

# Keeps the final completion chime audible before the parent
# scene changes after ending_finished is emitted.
@export var ending_finished_signal_delay: float = 0.35

@export var audio_one_shot_player_count: int = 10


var current_state: EndingState = EndingState.IDLE

var bag_hidden_position: Vector2 = Vector2.ZERO
var active_tween: Tween = null


var ending_music_player: AudioStreamPlayer = null
var ending_one_shot_players: Array[AudioStreamPlayer] = []
var ending_one_shot_index: int = 0
var ending_music_tween: Tween = null

var stream_bgm_collectible_ending: AudioStream = null

var stream_ending_trigger: AudioStream = null
var stream_ending_darken_swell: AudioStream = null
var stream_collectible_pop: AudioStream = null
var stream_prompt_appear: AudioStream = null
var stream_space_continue: AudioStream = null
var stream_bag_slide_in: AudioStream = null
var stream_collectible_pickup: AudioStream = null
var stream_collectible_release: AudioStream = null
var stream_collectible_return: AudioStream = null
var stream_bag_accept: AudioStream = null
var stream_collectible_enter_bag: AudioStream = null
var stream_bag_slide_out: AudioStream = null
var stream_final_fade_swell: AudioStream = null
var stream_ending_complete: AudioStream = null

var stream_ui_hover: AudioStream = null
var stream_ui_click: AudioStream = null

var collectible_hovered: bool = false
var collectible_mouse_pressed: bool = false

# Direct polling drag system.
# This does not depend on Area2D.input_event, CollisionShape2D,
# or GUI event propagation.
var collectible_sprite: Sprite2D = null
var manual_drag_active: bool = false
var manual_drag_offset: Vector2 = Vector2.ZERO
var previous_left_mouse_down: bool = false


func _ready() -> void:
	layer = ending_canvas_layer
	process_mode = Node.PROCESS_MODE_ALWAYS

	_create_or_find_prompt_label()

	_setup_control_nodes()
	_setup_layer_order()
	_setup_bag()
	_setup_bag_acceptance_area()
	_setup_collectible_collision()
	_setup_prompt()

	_load_audio_assets()
	_setup_audio_players()

	_cache_collectible_sprite()
	_connect_collectible_signal()

	_reset_visuals()

	print("")
	print("========================================")
	print("ENDING SCENE READY")
	print("========================================")
	print("Canvas layer: ", layer)
	print("Initial darkness duration: ", initial_dim_duration)
	print("Final darkness duration: ", final_fade_duration)
	print("Bag final position: ", bag_final_position)
	print("Bag scale: ", bag_display_scale)
	print("Drop screen center: ", bag_drop_screen_center)
	print("Drop screen size: ", bag_drop_screen_size)
	print("Bag mouth screen position: ", bag_mouth_screen_position)
	print("========================================")
	print("")




# =========================================================
# AUDIO
# =========================================================

func _load_audio_assets() -> void:
	stream_bgm_collectible_ending = _load_audio_stream(
		BGM_COLLECTIBLE_ENDING_PATH
	)

	stream_ending_trigger = _load_audio_stream(
		SFX_ENDING_TRIGGER_PATH
	)

	stream_ending_darken_swell = _load_audio_stream(
		SFX_ENDING_DARKEN_SWELL_PATH
	)

	stream_collectible_pop = _load_audio_stream(
		SFX_COLLECTIBLE_POP_PATH
	)

	stream_prompt_appear = _load_audio_stream(
		SFX_PROMPT_APPEAR_PATH
	)

	stream_space_continue = _load_audio_stream(
		SFX_SPACE_CONTINUE_PATH
	)

	stream_bag_slide_in = _load_audio_stream(
		SFX_BAG_SLIDE_IN_PATH
	)

	stream_collectible_pickup = _load_audio_stream(
		SFX_COLLECTIBLE_PICKUP_PATH
	)

	stream_collectible_release = _load_audio_stream(
		SFX_COLLECTIBLE_RELEASE_PATH
	)

	stream_collectible_return = _load_audio_stream(
		SFX_COLLECTIBLE_RETURN_PATH
	)

	stream_bag_accept = _load_audio_stream(
		SFX_BAG_ACCEPT_PATH
	)

	stream_collectible_enter_bag = _load_audio_stream(
		SFX_COLLECTIBLE_ENTER_BAG_PATH
	)

	stream_bag_slide_out = _load_audio_stream(
		SFX_BAG_SLIDE_OUT_PATH
	)

	stream_final_fade_swell = _load_audio_stream(
		SFX_FINAL_FADE_SWELL_PATH
	)

	stream_ending_complete = _load_audio_stream(
		SFX_ENDING_COMPLETE_PATH
	)

	stream_ui_hover = _load_audio_stream(
		SFX_UI_HOVER_PATH
	)

	stream_ui_click = _load_audio_stream(
		SFX_UI_CLICK_PATH
	)

	_enable_ending_music_loop(
		stream_bgm_collectible_ending
	)


func _load_audio_stream(
	path: String
) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning(
			"ENDING AUDIO: Missing audio: "
			+ path
		)

		return null

	var loaded_stream: AudioStream = (
		load(path) as AudioStream
	)

	if loaded_stream == null:
		push_warning(
			"ENDING AUDIO: Failed to load: "
			+ path
		)

	return loaded_stream


func _enable_ending_music_loop(
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
	ending_music_player = AudioStreamPlayer.new()
	ending_music_player.name = "EndingMusicPlayer"
	ending_music_player.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)
	ending_music_player.stream = (
		stream_bgm_collectible_ending
	)
	ending_music_player.volume_db = -80.0

	add_child(
		ending_music_player
	)

	ending_one_shot_players.clear()
	ending_one_shot_index = 0

	var player_count: int = maxi(
		1,
		audio_one_shot_player_count
	)

	for index in range(player_count):
		var player: AudioStreamPlayer = (
			AudioStreamPlayer.new()
		)

		player.name = (
			"EndingOneShot"
			+ str(index + 1)
		)

		player.process_mode = (
			Node.PROCESS_MODE_ALWAYS
		)

		add_child(player)

		ending_one_shot_players.append(
			player
		)


func _play_ending_one_shot(
	stream: AudioStream,
	volume_db: float,
	pitch_scale: float = 1.0
) -> void:
	if stream == null:
		return

	if ending_one_shot_players.is_empty():
		return

	var player: AudioStreamPlayer = (
		ending_one_shot_players[
			ending_one_shot_index
		]
	)

	ending_one_shot_index = (
		ending_one_shot_index + 1
	) % ending_one_shot_players.size()

	player.stop()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


func _start_ending_music() -> void:
	if ending_music_player == null:
		return

	if stream_bgm_collectible_ending == null:
		return

	_kill_ending_music_tween()

	ending_music_player.stream = (
		stream_bgm_collectible_ending
	)

	ending_music_player.volume_db = -80.0
	ending_music_player.play()

	ending_music_tween = create_tween()
	ending_music_tween.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)

	ending_music_tween.tween_property(
		ending_music_player,
		"volume_db",
		ending_music_volume_db,
		ending_music_fade_in_time
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_OUT
	)

	ending_music_tween.finished.connect(
		func() -> void:
			ending_music_tween = null
	)


func _fade_out_ending_music() -> void:
	if ending_music_player == null:
		return

	if not ending_music_player.playing:
		return

	_kill_ending_music_tween()

	ending_music_tween = create_tween()
	ending_music_tween.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)

	ending_music_tween.tween_property(
		ending_music_player,
		"volume_db",
		-80.0,
		maxf(
			ending_music_fade_out_time,
			0.01
		)
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN
	)

	ending_music_tween.finished.connect(
		func() -> void:
			if ending_music_player != null:
				ending_music_player.stop()

			ending_music_tween = null
	)


func _kill_ending_music_tween() -> void:
	if ending_music_tween != null:
		ending_music_tween.kill()
		ending_music_tween = null


func _stop_ending_audio() -> void:
	_kill_ending_music_tween()

	if ending_music_player != null:
		ending_music_player.stop()
		ending_music_player.volume_db = -80.0

	for player in ending_one_shot_players:
		if player != null:
			player.stop()

	ending_one_shot_index = 0


func _create_or_find_prompt_label() -> void:
	var existing_prompt: Node = ending_root.get_node_or_null(
		"PromptLabel"
	)

	if existing_prompt is Label:
		prompt_label = existing_prompt as Label
		return

	if existing_prompt != null:
		existing_prompt.queue_free()

	prompt_label = Label.new()
	prompt_label.name = "PromptLabel"

	ending_root.add_child(prompt_label)


func _setup_control_nodes() -> void:
	_set_control_full_rect(ending_root)
	_set_control_full_rect(dim_overlay)
	_set_control_full_rect(final_fade)

	ending_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	final_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if prompt_label != null:
		prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _set_control_full_rect(control: Control) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0

	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func _setup_layer_order() -> void:
	dim_overlay.z_index = 0

	bag_back.z_index = 20
	collectible.z_index = 30
	bag_front.z_index = 40

	if prompt_label != null:
		prompt_label.z_index = 60

	final_fade.z_index = 100


func _setup_bag() -> void:
	bag_back.position = Vector2.ZERO
	bag_front.position = Vector2.ZERO

	bag_back.scale = Vector2.ONE
	bag_front.scale = Vector2.ONE

	bag_back.centered = true
	bag_front.centered = true

	bag.position = bag_final_position
	bag.scale = bag_display_scale

	bag_hidden_position = (
		bag_final_position
		+ bag_hidden_offset
	)


func _setup_bag_acceptance_area() -> void:
	bag_drop_zone.monitoring = true
	bag_drop_zone.monitorable = true
	bag_drop_zone.input_pickable = false

	# Convert the desired screen position into the Bag node's
	# local coordinate system.
	var screen_delta: Vector2 = (
		bag_drop_screen_center
		- bag_final_position
	)

	var safe_scale_x: float = maxf(
		absf(bag_display_scale.x),
		0.001
	)

	var safe_scale_y: float = maxf(
		absf(bag_display_scale.y),
		0.001
	)

	bag_drop_zone.position = Vector2(
		screen_delta.x / safe_scale_x,
		screen_delta.y / safe_scale_y
	)

	# Convert the desired screen-sized rectangle into local size.
	var local_drop_size: Vector2 = Vector2(
		bag_drop_screen_size.x / safe_scale_x,
		bag_drop_screen_size.y / safe_scale_y
	)

	var rectangle_shape := RectangleShape2D.new()
	rectangle_shape.size = local_drop_size

	bag_drop_collision.position = Vector2.ZERO
	bag_drop_collision.shape = rectangle_shape
	bag_drop_collision.disabled = false

	# Position BagMouth using a screen position as well.
	var mouth_delta: Vector2 = (
		bag_mouth_screen_position
		- bag_final_position
	)

	bag_mouth.position = Vector2(
		mouth_delta.x / safe_scale_x,
		mouth_delta.y / safe_scale_y
	)

	print(
		"DEBUG ENDING: Bag drop local position: ",
		bag_drop_zone.position
	)

	print(
		"DEBUG ENDING: Bag drop local size: ",
		local_drop_size
	)

	print(
		"DEBUG ENDING: Bag mouth local position: ",
		bag_mouth.position
	)


func _setup_collectible_collision() -> void:
	var collectible_collision: CollisionShape2D = (
		collectible.get_node_or_null("CollisionShape2D")
	)

	if collectible_collision == null:
		collectible_collision = CollisionShape2D.new()
		collectible_collision.name = "CollisionShape2D"

		collectible.add_child(collectible_collision)

	var rectangle_shape := RectangleShape2D.new()
	rectangle_shape.size = collectible_collision_size

	collectible_collision.position = Vector2.ZERO
	collectible_collision.shape = rectangle_shape
	collectible_collision.disabled = false


func _setup_prompt() -> void:
	if prompt_label == null:
		push_error("PromptLabel could not be created.")
		return

	prompt_label.position = prompt_position
	prompt_label.size = prompt_size
	prompt_label.text = prompt_text

	prompt_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	prompt_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	prompt_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	prompt_label.add_theme_font_size_override(
		"font_size",
		prompt_font_size
	)

	prompt_label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	prompt_label.add_theme_color_override(
		"font_shadow_color",
		Color(0, 0, 0, 0.95)
	)

	prompt_label.add_theme_constant_override(
		"shadow_offset_x",
		2
	)

	prompt_label.add_theme_constant_override(
		"shadow_offset_y",
		2
	)

	if ResourceLoader.exists(SHARED_FONT_PATH):
		var shared_font: Font = load(
			SHARED_FONT_PATH
		)

		prompt_label.add_theme_font_override(
			"font",
			shared_font
		)

		print(
			"DEBUG ENDING: Shared VCR font applied."
		)
	else:
		push_error(
			"Shared font could not be found: "
			+ SHARED_FONT_PATH
		)


func _connect_collectible_signal() -> void:
	if not collectible.has_signal("released"):
		push_error(
			"DraggableCollectible is missing its released signal."
		)
		return

	var release_callable: Callable = Callable(
		self,
		"_on_collectible_released"
	)

	if not collectible.is_connected(
		"released",
		release_callable
	):
		collectible.connect(
			"released",
			release_callable
		)




func _cache_collectible_sprite() -> void:
	collectible_sprite = _find_collectible_sprite(
		collectible
	)

	if collectible_sprite == null:
		push_error(
			"ENDING: No Sprite2D was found under "
			+ "DraggableCollectible."
		)


func _find_collectible_sprite(
	parent_node: Node
) -> Sprite2D:
	for child in parent_node.get_children():
		if child is Sprite2D:
			return child as Sprite2D

		var nested_sprite: Sprite2D = (
			_find_collectible_sprite(child)
		)

		if nested_sprite != null:
			return nested_sprite

	return null


func _process(_delta: float) -> void:
	var left_mouse_down: bool = (
		Input.is_mouse_button_pressed(
			MOUSE_BUTTON_LEFT
		)
	)

	if (
		current_state
		!= EndingState.DRAGGING_COLLECTIBLE
	):
		manual_drag_active = false
		manual_drag_offset = Vector2.ZERO
		collectible_hovered = false
		collectible_mouse_pressed = false

		previous_left_mouse_down = (
			left_mouse_down
		)

		return

	var mouse_position: Vector2 = (
		get_viewport().get_mouse_position()
	)

	if manual_drag_active:
		collectible.global_position = (
			mouse_position
			+ manual_drag_offset
		)

		if (
			not left_mouse_down
			and previous_left_mouse_down
		):
			_finish_direct_collectible_drag()

	else:
		_update_direct_collectible_hover(
			mouse_position
		)

		if (
			left_mouse_down
			and not previous_left_mouse_down
		):
			_try_start_direct_collectible_drag(
				mouse_position
			)

	previous_left_mouse_down = left_mouse_down


func _try_start_direct_collectible_drag(
	mouse_position: Vector2
) -> void:
	if manual_drag_active:
		return

	if not _is_mouse_on_visible_collectible_pixel(
		mouse_position
	):
		print(
			"DEBUG ENDING: Click missed visible "
			+ "collectible pixels at ",
			mouse_position
		)

		return

	manual_drag_active = true
	collectible_mouse_pressed = true
	collectible_hovered = true

	manual_drag_offset = (
		collectible.global_position
		- mouse_position
	)

	_play_ending_one_shot(
		stream_ui_click,
		ending_ui_volume_db - 4.0,
		1.0
	)

	_play_ending_one_shot(
		stream_collectible_pickup,
		ending_sfx_volume_db,
		1.0
	)

	print("")
	print("========================================")
	print("ENDING DIRECT PIXEL DRAG STARTED")
	print("Mouse: ", mouse_position)
	print(
		"Collectible position: ",
		collectible.global_position
	)
	print(
		"Drag offset: ",
		manual_drag_offset
	)
	print("========================================")
	print("")


func _finish_direct_collectible_drag() -> void:
	if not manual_drag_active:
		return

	manual_drag_active = false
	collectible_mouse_pressed = false
	collectible_hovered = false
	manual_drag_offset = Vector2.ZERO

	var release_position: Vector2 = (
		collectible.global_position
	)

	print(
		"DEBUG ENDING: Direct pixel drag released at: ",
		release_position
	)

	_on_collectible_released(
		release_position
	)


func _update_direct_collectible_hover(
	mouse_position: Vector2
) -> void:
	var hovering_now: bool = (
		_is_mouse_on_visible_collectible_pixel(
			mouse_position
		)
	)

	if (
		hovering_now
		and not collectible_hovered
	):
		collectible_hovered = true

		_play_ending_one_shot(
			stream_ui_hover,
			ending_ui_volume_db,
			1.0
		)

	elif (
		not hovering_now
		and collectible_hovered
	):
		collectible_hovered = false


func _is_mouse_on_visible_collectible_pixel(
	screen_point: Vector2
) -> bool:
	if collectible_sprite == null:
		_cache_collectible_sprite()

	if collectible_sprite == null:
		return false

	if not collectible.visible:
		return false

	if not collectible_sprite.is_visible_in_tree():
		return false

	if collectible_sprite.texture == null:
		return false

	# Convert viewport coordinates directly into the Sprite2D's
	# real local coordinates. This correctly includes the
	# CanvasLayer, parent transforms, sprite position, scale,
	# centering, and the collectible's own transform.
	var local_point: Vector2 = (
		collectible_sprite.make_canvas_position_local(
			screen_point
		)
	)

	if not collectible_sprite.get_rect().has_point(
		local_point
	):
		return false

	# Use the Sprite2D texture alpha itself as the hit test.
	# This is critical for Guinamos because its collectible is a
	# 1920x1080 canvas with the jar occupying only part of it.
	return collectible_sprite.is_pixel_opaque(
		local_point
	)


func _enable_direct_collectible_drag() -> void:
	manual_drag_active = false
	manual_drag_offset = Vector2.ZERO
	collectible_mouse_pressed = false
	collectible_hovered = false

	previous_left_mouse_down = (
		Input.is_mouse_button_pressed(
			MOUSE_BUTTON_LEFT
		)
	)

	# The shared ending owns dragging completely.
	# Keep the child Area2D drag code disabled.
	if collectible.has_method("set_drag_enabled"):
		collectible.call(
			"set_drag_enabled",
			false
		)

	collectible.input_pickable = false

	print("")
	print("========================================")
	print("ENDING DIRECT PIXEL DRAG ENABLED")
	print("Collectible: ", collectible.name)
	print(
		"Sprite found: ",
		collectible_sprite != null
	)

	if collectible_sprite != null:
		print(
			"Sprite texture size: ",
			collectible_sprite.texture.get_size()
			if collectible_sprite.texture != null
			else Vector2.ZERO
		)

		print(
			"Sprite local rect: ",
			collectible_sprite.get_rect()
		)

		print(
			"Sprite global-with-canvas transform: ",
			collectible_sprite.get_global_transform_with_canvas()
		)

	print("========================================")
	print("")


func _disable_direct_collectible_drag() -> void:
	manual_drag_active = false
	manual_drag_offset = Vector2.ZERO
	collectible_mouse_pressed = false
	collectible_hovered = false

	previous_left_mouse_down = (
		Input.is_mouse_button_pressed(
			MOUSE_BUTTON_LEFT
		)
	)

	if collectible.has_method("set_drag_enabled"):
		collectible.call(
			"set_drag_enabled",
			false
		)

	collectible.input_pickable = false

func _reset_visuals() -> void:
	_stop_ending_audio()

	current_state = EndingState.IDLE

	collectible_hovered = false
	collectible_mouse_pressed = false
	manual_drag_active = false
	manual_drag_offset = Vector2.ZERO

	previous_left_mouse_down = (
		Input.is_mouse_button_pressed(
			MOUSE_BUTTON_LEFT
		)
	)

	ending_root.visible = false

	dim_overlay.visible = true
	dim_overlay.color = Color(0, 0, 0, 0)

	final_fade.visible = true
	final_fade.color = Color(0, 0, 0, 0)

	bag.visible = false
	bag.position = bag_hidden_position
	bag.scale = bag_display_scale

	collectible.visible = false
	collectible.global_position = collectible_final_position
	collectible.scale = Vector2.ONE
	collectible.modulate = Color.WHITE
	collectible.rotation = 0.0

	_disable_direct_collectible_drag()

	if prompt_label != null:
		prompt_label.visible = false
		prompt_label.modulate = Color(1, 1, 1, 0)

func start_ending(
	new_collectible_texture: Texture2D,
	new_collectible_scale: Vector2 = Vector2(0.6, 0.6)
) -> void:
	if new_collectible_texture == null:
		push_error(
			"Cannot start ending because the texture is null."
		)
		return

	if (
		current_state != EndingState.IDLE
		and current_state != EndingState.FINISHED
	):
		return

	_kill_active_tween()
	_reset_visuals()

	ending_root.visible = true

	dim_overlay.visible = true
	dim_overlay.color = Color(0, 0, 0, 0)

	final_fade.visible = true
	final_fade.color = Color(0, 0, 0, 0)

	bag.visible = false
	bag.position = bag_hidden_position
	bag.scale = bag_display_scale

	if not collectible.has_method("configure_collectible"):
		push_error(
			"DraggableCollectible is missing "
			+ "configure_collectible()."
		)
		return

	collectible.call(
		"configure_collectible",
		new_collectible_texture,
		new_collectible_scale,
		collectible_collision_size
	)

	# Re-cache after configure_collectible() in case the
	# collectible implementation changed or recreated its sprite.
	_cache_collectible_sprite()

	if collectible.has_method("set_home_position"):
		collectible.call(
			"set_home_position",
			collectible_final_position
		)
	else:
		collectible.global_position = collectible_final_position

	collectible.visible = false
	collectible.scale = Vector2.ZERO
	collectible.modulate = Color.WHITE

	_disable_direct_collectible_drag()

	prompt_label.visible = false
	prompt_label.modulate = Color(1, 1, 1, 0)

	current_state = EndingState.DARKENING_BACKGROUND

	_play_ending_one_shot(
		stream_ending_trigger,
		ending_sfx_volume_db,
		1.0
	)

	_play_ending_one_shot(
		stream_ending_darken_swell,
		ending_sfx_volume_db - 6.0,
		1.0
	)

	_start_ending_music()

	print(
		"DEBUG ENDING: Gradually darkening for ",
		initial_dim_duration,
		" seconds."
	)

	active_tween = create_tween()

	active_tween.tween_property(
		dim_overlay,
		"color:a",
		dim_target_alpha,
		initial_dim_duration
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)

	await active_tween.finished
	active_tween = null

	if current_state != EndingState.DARKENING_BACKGROUND:
		return

	_pop_collectible()


func _pop_collectible() -> void:
	current_state = EndingState.POPPING_COLLECTIBLE

	_play_ending_one_shot(
		stream_collectible_pop,
		ending_sfx_volume_db,
		1.0
	)

	collectible.visible = true
	collectible.global_position = collectible_final_position
	collectible.scale = Vector2.ZERO
	collectible.modulate = Color.WHITE

	active_tween = create_tween()

	active_tween.tween_property(
		collectible,
		"scale",
		Vector2.ONE,
		collectible_pop_duration
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	await active_tween.finished
	active_tween = null

	if current_state != EndingState.POPPING_COLLECTIBLE:
		return

	current_state = EndingState.WAITING_FOR_SPACE

	_show_space_prompt()


func _show_space_prompt() -> void:
	_play_ending_one_shot(
		stream_prompt_appear,
		ending_ui_volume_db,
		1.0
	)

	prompt_label.text = prompt_text
	prompt_label.visible = true
	prompt_label.modulate = Color(1, 1, 1, 0)

	active_tween = create_tween()

	active_tween.tween_property(
		prompt_label,
		"modulate:a",
		1.0,
		prompt_fade_duration
	)

	await active_tween.finished
	active_tween = null

	print("DEBUG ENDING: Waiting for SPACE.")


func _unhandled_input(event: InputEvent) -> void:
	if current_state != EndingState.WAITING_FOR_SPACE:
		return

	if event is InputEventKey:
		if (
			event.keycode == KEY_SPACE
			and event.pressed
			and not event.echo
		):
			get_viewport().set_input_as_handled()
			_slide_bag_up()


func _slide_bag_up() -> void:
	if current_state != EndingState.WAITING_FOR_SPACE:
		return

	current_state = EndingState.BAG_SLIDING_IN

	_play_ending_one_shot(
		stream_space_continue,
		ending_sfx_volume_db,
		1.0
	)

	_disable_direct_collectible_drag()

	active_tween = create_tween()

	active_tween.tween_property(
		prompt_label,
		"modulate:a",
		0.0,
		prompt_fade_duration
	)

	await active_tween.finished
	active_tween = null

	prompt_label.visible = false

	bag.position = bag_hidden_position
	bag.scale = bag_display_scale
	bag.visible = true

	_play_ending_one_shot(
		stream_bag_slide_in,
		ending_sfx_volume_db - 2.0,
		1.0
	)

	active_tween = create_tween()

	active_tween.tween_property(
		bag,
		"position",
		bag_final_position,
		bag_slide_in_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	await active_tween.finished
	active_tween = null

	if current_state != EndingState.BAG_SLIDING_IN:
		return

	bag.position = bag_final_position
	bag.scale = bag_display_scale
	bag.visible = true

	current_state = EndingState.DRAGGING_COLLECTIBLE

	_enable_direct_collectible_drag()

	print(
		"DEBUG ENDING: Bag is ready and direct "
		+ "pixel dragging is active."
	)

func _on_collectible_released(
	release_position: Vector2
) -> void:
	if current_state != EndingState.DRAGGING_COLLECTIBLE:
		return

	manual_drag_active = false
	manual_drag_offset = Vector2.ZERO
	collectible_mouse_pressed = false
	collectible_hovered = false

	_play_ending_one_shot(
		stream_collectible_release,
		ending_sfx_volume_db - 3.0,
		1.0
	)

	var inside_bag: bool = (
		_is_point_inside_bag_acceptance_area(
			release_position
		)
	)

	print("")
	print(
		"DEBUG ENDING: Collectible center released at: ",
		release_position
	)

	print(
		"DEBUG ENDING: Accepted by bag: ",
		inside_bag
	)

	if inside_bag:
		_play_ending_one_shot(
			stream_bag_accept,
			ending_sfx_volume_db,
			1.0
		)

		_collect_item()

	else:
		_play_ending_one_shot(
			stream_collectible_return,
			ending_sfx_volume_db - 2.0,
			1.0
		)

		var return_tween: Tween = create_tween()

		return_tween.tween_property(
			collectible,
			"global_position",
			collectible_final_position,
			0.18
		).set_trans(
			Tween.TRANS_QUAD
		).set_ease(
			Tween.EASE_OUT
		)

func _is_point_inside_bag_acceptance_area(
	screen_point: Vector2
) -> bool:
	var half_size: Vector2 = (
		bag_drop_screen_size * 0.5
	)

	var screen_rectangle := Rect2(
		bag_drop_screen_center - half_size,
		bag_drop_screen_size
	)

	print(
		"DEBUG ENDING: Acceptance rectangle: ",
		screen_rectangle
	)

	return screen_rectangle.has_point(screen_point)


func _collect_item() -> void:
	if current_state != EndingState.DRAGGING_COLLECTIBLE:
		return

	current_state = EndingState.COLLECTING_ITEM

	_disable_direct_collectible_drag()

	_play_ending_one_shot(
		stream_collectible_enter_bag,
		ending_sfx_volume_db,
		1.0
	)

	print(
		"DEBUG ENDING: Collectible accepted by bag."
	)

	active_tween = create_tween()
	active_tween.set_parallel(true)

	active_tween.tween_property(
		collectible,
		"global_position",
		bag_mouth_screen_position,
		item_enter_bag_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	active_tween.tween_property(
		collectible,
		"scale",
		item_inside_bag_scale,
		item_enter_bag_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	active_tween.tween_property(
		collectible,
		"modulate:a",
		0.0,
		item_enter_bag_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	await active_tween.finished
	active_tween = null

	if current_state != EndingState.COLLECTING_ITEM:
		return

	collectible.visible = false

	_slide_bag_down()

func _slide_bag_down() -> void:
	current_state = EndingState.BAG_SLIDING_OUT

	_play_ending_one_shot(
		stream_bag_slide_out,
		ending_sfx_volume_db - 2.0,
		1.0
	)

	active_tween = create_tween()

	active_tween.tween_property(
		bag,
		"position",
		bag_hidden_position,
		bag_slide_out_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	await active_tween.finished
	active_tween = null

	if current_state != EndingState.BAG_SLIDING_OUT:
		return

	bag.visible = false

	_fade_screen_to_black()


func _fade_screen_to_black() -> void:
	current_state = EndingState.FINAL_FADING

	_play_ending_one_shot(
		stream_final_fade_swell,
		ending_sfx_volume_db - 6.0,
		1.0
	)

	_fade_out_ending_music()

	final_fade.visible = true
	final_fade.color = Color(0, 0, 0, 0)

	print(
		"DEBUG ENDING: Final fade duration: ",
		final_fade_duration,
		" seconds."
	)

	active_tween = create_tween()

	active_tween.tween_property(
		final_fade,
		"color:a",
		1.0,
		final_fade_duration
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)

	await active_tween.finished
	active_tween = null

	if current_state != EndingState.FINAL_FADING:
		return

	current_state = EndingState.FINISHED

	print("")
	print("========================================")
	print("DEBUG ENDING: ENDING FINISHED")
	print("========================================")
	print("")

	_play_ending_one_shot(
		stream_ending_complete,
		ending_sfx_volume_db,
		1.0
	)

	if ending_finished_signal_delay > 0.0:
		await get_tree().create_timer(
			ending_finished_signal_delay
		).timeout

	ending_finished.emit()


func reset_ending() -> void:
	_kill_active_tween()
	_reset_visuals()


func _kill_active_tween() -> void:
	_kill_ending_music_tween()

	if active_tween != null:
		active_tween.kill()
		active_tween = null
