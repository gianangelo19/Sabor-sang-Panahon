extends Node2D

signal minigame_completed
signal minigame_failed
signal minigame_retry_requested

const FAIL_SCREEN_SCENE: PackedScene = preload(
	"res://features/minigames/fail_screen/scenes/minigame_fail_screen.tscn"
)


# ============================================================
# SCREEN AND PLAY AREA
# ============================================================

const SCREEN_SIZE := Vector2(1152, 648)
const SCREEN_CENTER := Vector2(576, 324)

const MEAT_AREA := Rect2(
	Vector2(128.4, 114.7),
	Vector2(895.0, 468.0)
)

const TRASH_RECT := Rect2(
	Vector2(20, 490),
	Vector2(545, 158)
)

const BASKET_RECT := Rect2(
	Vector2(587, 490),
	Vector2(545, 158)
)


# ============================================================
# VISUAL LAYERS
# ============================================================

# Back to front:
# Background
# Dropped meat
# Customer hands
# Trash and basket
# Picked-up meat
# Gameplay UI is drawn in a CanvasLayer above these world elements.

const Z_BACKGROUND := 0
const Z_DROPPED_MEAT_BASE := 10
const Z_HANDS := 40
const Z_DROP_TARGETS := 50
const Z_PICKED_UP_MEAT := 60


# ============================================================
# GENERAL GAME SETTINGS
# ============================================================

const TABLE_MEAT_COUNT := 17
const FAILURE_LIMIT := 5

const MIN_REQUIRED_AMOUNT := 2
const MAX_REQUIRED_AMOUNT := 6

const MEAT_SCALE := Vector2(0.50, 0.50)
const ALPHA_HIT_THRESHOLD := 0.12

const THROW_DURATION := 0.88
const INITIAL_THROW_INTERVAL := 0.16

const TARGET_SLIDE_IN_DURATION := 0.22
const TARGET_SLIDE_OUT_DURATION := 0.18
const GAMEPLAY_HUD_LAYER := 90
const DROP_TARGET_MARGIN := 12.0
const MIN_DROP_OVERLAP_RATIO := 0.20


# ============================================================
# SPAWN AND OVERLAP SETTINGS
# ============================================================

# No pair of meats may overlap by more than 60% of
# either meat's visible rectangular area.
const MAX_PAIR_OVERLAP_RATIO := 0.60

# All overlapping neighbors combined may not cover more
# than 60% of a newly spawned meat.
const MAX_TOTAL_OVERLAP_RATIO := 0.60

# A small amount of overlap is preferred sometimes.
const NATURAL_OVERLAP_CHANCE := 0.22
const TARGET_NATURAL_OVERLAP := 0.16

const PLACEMENT_ATTEMPTS := 500
const GRID_COLUMNS := 26
const GRID_ROWS := 14

const OPTIONAL_SPAWN_WEIGHT := 1.25
const BAD_SPAWN_WEIGHT := 1.00

# Prevent bones, fat scraps, and old meat from slowly filling
# most of the table because customer hands never take them.
const MAX_BAD_MEAT_ON_TABLE := 10

# After this many replacement spawns without a currently needed
# required meat, the next replacement is forced to be required.

# Newly landed meat cannot be targeted immediately by a hand.
const SPAWN_PROTECTION_DURATION := 0.35


# ============================================================
# CUSTOMER HAND SETTINGS — SECTIONS 4 TO 6
# ============================================================

const HAND_SCALE := Vector2(0.60, 0.60)
const HAND_APPROACH_DURATION := 0.34
const HAND_RETREAT_DURATION := 0.28
const HAND_WARNING_DURATION := 0.42

# A hand targeting a currently required meat pauses at the meat.
# It can be slapped only during this pause.
const REQUIRED_HAND_HOLD_DURATION := 0.42

# Short recoil before a slapped hand retreats.
const HAND_SLAP_RECOIL_DISTANCE := 78.0
const HAND_SLAP_RECOIL_DURATION := 0.16
const HAND_SLAP_RETREAT_DURATION := 0.30

# Time-based difficulty phases.
const EARLY_PHASE_END := 18.0
const MID_PHASE_END := 38.0

# Early: quick enough to create pressure without overwhelming the player.
const EARLY_HAND_INTERVAL_MIN := 1.00
const EARLY_HAND_INTERVAL_MAX := 1.35
const EARLY_MAX_ACTIVE_HANDS := 2
const EARLY_REQUIRED_SPAWN_WEIGHT := 0.22
const EARLY_REQUIRED_PITY_LIMIT := 8

# Middle: faster pressure and more frequent double rushes.
const MID_HAND_INTERVAL_MIN := 0.68
const MID_HAND_INTERVAL_MAX := 0.95
const MID_MAX_ACTIVE_HANDS := 3
const MID_REQUIRED_SPAWN_WEIGHT := 0.62
const MID_REQUIRED_PITY_LIMIT := 5

# Late: fast and challenging, while required meat remains obtainable.
const LATE_HAND_INTERVAL_MIN := 0.46
const LATE_HAND_INTERVAL_MAX := 0.70
const LATE_MAX_ACTIVE_HANDS := 4
const LATE_REQUIRED_SPAWN_WEIGHT := 1.05
const LATE_REQUIRED_PITY_LIMIT := 3

# Double-hand rush settings.
const DOUBLE_RUSH_MIN_COOLDOWN := 4.5
const DOUBLE_RUSH_MAX_COOLDOWN := 6.5
const DOUBLE_RUSH_SECOND_HAND_DELAY := 0.06
const MID_DOUBLE_RUSH_CHANCE := 0.80
const LATE_DOUBLE_RUSH_CHANCE := 1.00

# The hand root represents the palm/grab location.
const LEFT_HAND_GRAB_UV := Vector2(0.735, 0.485)
const RIGHT_HAND_GRAB_UV := Vector2(0.735, 0.445)

# Root position when the palm is completely outside the screen.
const HAND_OFFSCREEN_DISTANCE := 230.0


enum HandState {
	APPROACHING,
	HOLDING,
	GRABBING,
	RETREATING,
	SLAPPED,
	CANCELLED,
	FINISHED,
}


# ============================================================
# MEAT DEFINITIONS
# ============================================================

const REQUIRED_MEATS: Array[String] = [
	"belly",
	"liver",
	"spleen",
]

const OPTIONAL_GOOD_MEATS: Array[String] = [
	"pork_chop",
	"pork_hock",
	"pork_ribs",
	"pork_shoulder",
]

const BAD_MEATS: Array[String] = [
	"bone_cut",
	"fat_scraps",
	"old_meat",
]

const ALL_MEATS: Array[String] = [
	"belly",
	"liver",
	"spleen",
	"pork_chop",
	"pork_hock",
	"pork_ribs",
	"pork_shoulder",
	"bone_cut",
	"fat_scraps",
	"old_meat",
]


# ============================================================
# SHARED UI
# ============================================================

const SHARED_FONT := preload(
	"res://features/minigames/shared/fonts/VCR_OSD_MONO_1.001.ttf"
)


# ============================================================
# UI AND HAND TEXTURES
# ============================================================

const BASKET_TEXTURE := preload(
	"res://features/minigames/snatch_battle/assets/ui/basket_ui_topdown.png"
)

const TRASH_TEXTURE := preload(
	"res://features/minigames/snatch_battle/assets/ui/trashcan_ui_topdown.png"
)

const ORDER_PANEL_TEXTURE := preload(
	"res://features/minigames/snatch_battle/assets/ui/snatch_order_panel.png"
)
const MISTAKE_PANEL_TEXTURE := preload(
	"res://features/minigames/snatch_battle/assets/ui/snatch_mistake_limits_panel.png"
)
const NO_MISTAKE_TEXTURE := preload(
	"res://features/minigames/snatch_battle/assets/ui/snatch_no_mistake.png"
)
const YES_MISTAKE_TEXTURE := preload(
	"res://features/minigames/snatch_battle/assets/ui/snatch_yes_mistake.png"
)
const HAND_ATTACK_INDICATOR_TEXTURE := preload(
	"res://features/minigames/snatch_battle/assets/ui/snatch_hand_attack_indicator.png"
)

const LEFT_HAND_TEXTURE := preload(
	"res://features/minigames/snatch_battle/assets/hands/npc_arm_left.png"
)

const RIGHT_HAND_TEXTURE := preload(
	"res://features/minigames/snatch_battle/assets/hands/npc_arm_right.png"
)


# ============================================================
# SECTIONS 4 TO 6 EFFECTS
# ============================================================

const SLAP_IMPACT_TEXTURE := preload(
	"res://features/minigames/snatch_battle/assets/effects/slap_impact.png"
)

const FEEDBACK_TEXTURES := {
	"ordered": preload(
		"res://features/minigames/snatch_battle/assets/feedback/snatch_ordered_feedback.png"
	),
	"good_call": preload(
		"res://features/minigames/snatch_battle/assets/feedback/snatch_good_call_feedback.png"
	),
	"not_ordered": preload(
		"res://features/minigames/snatch_battle/assets/feedback/snatch_not_ordered_feedback.png"
	),
	"wasted": preload(
		"res://features/minigames/snatch_battle/assets/feedback/snatch_wasted_feedback.png"
	),
	"slapped": preload(
		"res://features/minigames/snatch_battle/assets/feedback/snatch_slapped_feedback.png"
	),
	"snatched": preload(
		"res://features/minigames/snatch_battle/assets/feedback/snatch_snatched_feedback.png"
	),
}
const ORDER_COMPLETE_TEXTURE := preload(
	"res://features/minigames/snatch_battle/assets/feedback/snatch_order_complete.png"
)

const ORDER_PANEL_ORIGIN := Vector2(8.0, 8.0)
const MISTAKE_PANEL_ORIGIN := Vector2(851.0, 8.0)
const FEEDBACK_SCALE := Vector2(0.22, 0.22)

const INTRO_DIALOGUE := [
	{
		"text": "Put Pork Belly, Atay, and Lapay in the basket. Throw only spoiled scraps into the trash.",
		"expression": "neutral",
		"character": "vendor_snatch",
	},
	{
		"text": "Customers will reach for the meat. If a hand pauses over something we still need, slap it away!",
		"expression": "concerned",
		"character": "vendor_snatch",
	},
]



# ============================================================
# MEAT TEXTURES
# ============================================================

const MEAT_TEXTURES: Dictionary = {
	"belly": preload(
		"res://features/minigames/snatch_battle/assets/meats/meat_required_belly.png"
	),

	"liver": preload(
		"res://features/minigames/snatch_battle/assets/meats/meat_required_liver_atay.png"
	),

	"spleen": preload(
		"res://features/minigames/snatch_battle/assets/meats/meat_required_spleen_lapay.png"
	),

	"pork_chop": preload(
		"res://features/minigames/snatch_battle/assets/meats/meat_extra_pork_chop.png"
	),

	"pork_hock": preload(
		"res://features/minigames/snatch_battle/assets/meats/meat_extra_pork_hock.png"
	),

	"pork_ribs": preload(
		"res://features/minigames/snatch_battle/assets/meats/meat_extra_pork_ribs.png"
	),

	"pork_shoulder": preload(
		"res://features/minigames/snatch_battle/assets/meats/meat_extra_pork_shoulder.png"
	),

	"bone_cut": preload(
		"res://features/minigames/snatch_battle/assets/meats/meat_bad_bone_cut.png"
	),

	"fat_scraps": preload(
		"res://features/minigames/snatch_battle/assets/meats/meat_bad_fat_scraps.png"
	),

	"old_meat": preload(
		"res://features/minigames/snatch_battle/assets/meats/meat_bad_old_meat.png"
	),
}


# ============================================================
# AUDIO
# ============================================================

const MUSIC := preload(
	"res://features/minigames/snatch_battle/assets/audio/music/bgm_snatch_battle_loop.ogg"
)

const AMBIENCE := preload(
	"res://features/minigames/snatch_battle/assets/audio/ambience/amb_meat_market_stall_loop.ogg"
)

const SFX_PICKUP := preload(
	"res://features/minigames/snatch_battle/assets/audio/sfx/sfx_meat_pickup_01.wav"
)

const SFX_ACCEPT := preload(
	"res://features/minigames/snatch_battle/assets/audio/sfx/sfx_basket_accept.wav"
)

const SFX_WRONG := preload(
	"res://features/minigames/snatch_battle/assets/audio/sfx/sfx_basket_wrong.wav"
)

const SFX_TRASH := preload(
	"res://features/minigames/snatch_battle/assets/audio/sfx/sfx_trash_accept.wav"
)

const SFX_STOLEN := preload(
	"res://features/minigames/snatch_battle/assets/audio/sfx/sfx_meat_stolen.wav"
)



const SFX_HAND_WHOOSH_LEFT := preload(
	"res://features/minigames/snatch_battle/assets/audio/sfx/sfx_hand_whoosh_left.wav"
)

const SFX_HAND_WHOOSH_RIGHT := preload(
	"res://features/minigames/snatch_battle/assets/audio/sfx/sfx_hand_whoosh_right.wav"
)

const SFX_HAND_SLAP := preload(
	"res://features/minigames/snatch_battle/assets/audio/sfx/sfx_hand_slap.wav"
)

const SFX_HAND_RECOIL := preload(
	"res://features/minigames/snatch_battle/assets/audio/sfx/sfx_hand_recoil.wav"
)

const SFX_REQUIRED_HAND_PAUSE := preload(
	"res://features/minigames/snatch_battle/assets/audio/sfx/sfx_required_hand_pause.wav"
)

const SFX_DOUBLE_HAND_RUSH := preload(
	"res://features/minigames/snatch_battle/assets/audio/sfx/sfx_double_hand_rush.wav"
)
const SFX_ORDER_COMPLETE := preload(
	"res://features/minigames/snatch_battle/assets/audio/sfx/sfx_order_complete.wav"
)
const SFX_WARNING := preload(
	"res://features/minigames/snatch_battle/assets/audio/sfx/sfx_warning_limit_near.wav"
)
const SFX_SUCCESS := preload(
	"res://features/minigames/snatch_battle/assets/audio/sfx/sfx_success_transition.wav"
)
const SFX_FAILURE := preload(
	"res://features/minigames/snatch_battle/assets/audio/sfx/sfx_failure_transition.wav"
)


# ============================================================
# SCENE REFERENCES
# ============================================================

@onready var active_items: Node2D = $ActiveItems
@onready var dialogue: SharedDialogue = $SharedDialogue


# ============================================================
# GAME STATE
# ============================================================

var pieces: Array[Node2D] = []

var required_amounts: Dictionary = {}
var collected_amounts: Dictionary = {}

var wasted_good_meat := 0
var suspicious_basket_attempts := 0

var dragged_piece: Node2D = null
var drag_offset := Vector2.ZERO
var drag_start_position := Vector2.ZERO

var gameplay_active := false
var result_emitted := false
var dialogue_context := ""
var dialogue_is_blocking := false
var warning_level_shown := 0
var dialogue_seen: Dictionary = {}
var announced_difficulty_phase := 0

var gameplay_elapsed := 0.0

var customer_elapsed := 0.0
var customer_interval := EARLY_HAND_INTERVAL_MIN
var active_hand_count := 0

var double_rush_cooldown := 0.0
var double_rush_in_progress := false

# Counts only replacement spawns, not the initial table fill.
var replacement_spawns_without_needed := 0

# Each dictionary stores one hand, its target, state, and tweens.
# This prepares the existing hands for warning, interception,
# and slapping without changing their current appearance.
var active_hand_attacks: Array[Dictionary] = []


# ============================================================
# PIXEL-PERFECT DATA
# ============================================================

var meat_images: Dictionary = {}
var meat_alpha_rects: Dictionary = {}


# ============================================================
# UI REFERENCES
# ============================================================

var basket_sprite: Sprite2D
var trash_sprite: Sprite2D
var order_board: Sprite2D
var mistake_board: Sprite2D
var ui_layer: CanvasLayer
var ui_root: Control
var order_value_labels: Dictionary = {}
var wasted_markers: Array[TextureRect] = []
var suspicion_markers: Array[TextureRect] = []
var order_complete_layer: CanvasLayer
var order_complete_root: Control

var basket_target_position := SCREEN_CENTER
var trash_target_position := SCREEN_CENTER

var basket_hidden_position := Vector2.ZERO
var trash_hidden_position := Vector2.ZERO

var target_tween: Tween


# ============================================================
# AUDIO PLAYERS
# ============================================================

var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var fail_screen: Node
var sfx_player: AudioStreamPlayer


# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	randomize()

	_setup_visual_layers()
	_cache_meat_alpha_data()
	_generate_random_order()
	_setup_targets_and_hud()
	_setup_audio()
	_setup_order_complete_overlay()
	_setup_fail_screen()
	dialogue.dialogue_started.connect(_on_dialogue_started)
	dialogue.dialogue_finished.connect(_on_dialogue_finished)

	_hide_drop_targets_immediately()


func _setup_visual_layers() -> void:
	var background := get_node_or_null("Background") as CanvasItem

	if background != null:
		background.z_as_relative = false
		background.z_index = Z_BACKGROUND

	active_items.z_as_relative = false
	active_items.z_index = 0


func _process(delta: float) -> void:
	if not gameplay_active:
		return

	gameplay_elapsed += delta
	customer_elapsed += delta
	double_rush_cooldown = maxf(0.0, double_rush_cooldown - delta)
	_announce_difficulty_phase()

	if (
		_get_difficulty_phase() > 0
		and not double_rush_in_progress
		and double_rush_cooldown <= 0.0
		and active_hand_count <= _get_current_max_active_hands() - 2
	):
		var rush_chance := (
			MID_DOUBLE_RUSH_CHANCE
			if _get_difficulty_phase() == 1
			else LATE_DOUBLE_RUSH_CHANCE
		)

		if randf() <= rush_chance and _can_start_double_hand_rush():
			_start_double_hand_rush()
		else:
			_reset_double_rush_cooldown()

	if customer_elapsed >= customer_interval:
		customer_elapsed = 0.0
		customer_interval = _get_random_customer_interval()
		_send_customer_hand()


func _input(event: InputEvent) -> void:
	if dialogue_is_blocking:
		return
	if not gameplay_active:
		return

	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return

		if event.pressed:
			if _try_slap_required_hand(event.position):
				return

			_begin_drag(event.position)
		else:
			_end_drag(event.position)

	elif event is InputEventMouseMotion:
		if dragged_piece != null and is_instance_valid(dragged_piece):
			dragged_piece.position = event.position + drag_offset


# ============================================================
# PIXEL-PERFECT CACHE
# ============================================================

func _cache_meat_alpha_data() -> void:
	meat_images.clear()
	meat_alpha_rects.clear()

	for id_value in MEAT_TEXTURES.keys():
		var meat_id := String(id_value)
		var texture := MEAT_TEXTURES[meat_id] as Texture2D

		if texture == null:
			continue

		var image := texture.get_image()

		if image == null or image.is_empty():
			continue

		meat_images[meat_id] = image
		meat_alpha_rects[meat_id] = _calculate_alpha_rect(image)


func _calculate_alpha_rect(image: Image) -> Rect2i:
	var minimum_x := image.get_width()
	var minimum_y := image.get_height()

	var maximum_x := -1
	var maximum_y := -1

	for pixel_y in range(image.get_height()):
		for pixel_x in range(image.get_width()):
			var alpha := image.get_pixel(pixel_x, pixel_y).a

			if alpha <= ALPHA_HIT_THRESHOLD:
				continue

			minimum_x = mini(minimum_x, pixel_x)
			minimum_y = mini(minimum_y, pixel_y)

			maximum_x = maxi(maximum_x, pixel_x)
			maximum_y = maxi(maximum_y, pixel_y)

	if maximum_x < minimum_x or maximum_y < minimum_y:
		return Rect2i(
			0,
			0,
			image.get_width(),
			image.get_height()
		)

	return Rect2i(
		minimum_x,
		minimum_y,
		maximum_x - minimum_x + 1,
		maximum_y - minimum_y + 1
	)


# ============================================================
# ORDER GENERATION
# ============================================================

func _generate_random_order() -> void:
	required_amounts.clear()
	collected_amounts.clear()

	for meat_id in REQUIRED_MEATS:
		required_amounts[meat_id] = randi_range(
			MIN_REQUIRED_AMOUNT,
			MAX_REQUIRED_AMOUNT
		)

		collected_amounts[meat_id] = 0


# ============================================================
# GAME START
# ============================================================

func _start_game_without_introduction() -> void:
	_on_countdown_finished()


func _on_countdown_finished() -> void:
	music_player.play()
	ambience_player.play()

	await _fill_initial_table()

	if result_emitted:
		return

	gameplay_active = true
	gameplay_elapsed = 0.0
	customer_elapsed = 0.0
	customer_interval = _get_random_customer_interval()
	_reset_double_rush_cooldown()
	_show_vendor_line(
		"The table is ready. Watch the order and keep an eye on those hands.",
		"neutral",
		"passive"
	)


# ============================================================
# INITIAL TABLE FILL
# ============================================================

func _fill_initial_table() -> void:
	# Always make the order actionable immediately. The remaining cuts stay
	# randomized, but the player never has to wait for a hand replacement just
	# to see the first Pork Belly, Atay, or Lapay.
	var guaranteed_required: Array[String] = REQUIRED_MEATS.duplicate()
	while pieces.size() < TABLE_MEAT_COUNT:
		var meat_id: String = (
			guaranteed_required.pop_front()
			if not guaranteed_required.is_empty()
			else _choose_spawn_id(false)
		)
		_spawn_piece(
			meat_id,
			true,
			false
		)

		await get_tree().create_timer(
			INITIAL_THROW_INTERVAL
		).timeout

	await get_tree().create_timer(
		THROW_DURATION + 0.05
	).timeout


# ============================================================
# SPAWN TYPE SELECTION AND FAIRNESS
# ============================================================

func _choose_spawn_id(is_replacement: bool = false) -> String:
	var unfinished_required := _get_unfinished_required_meats()

	# Pity rule: after eight replacement spawns without producing
	# a meat that is still needed, force one unfinished type.
	if (
		is_replacement
		and replacement_spawns_without_needed >= _get_current_required_pity_limit()
		and not unfinished_required.is_empty()
	):
		return String(unfinished_required.pick_random())

	var possible_ids: Array[String] = []
	var weights: Array[float] = []
	var bad_limit_reached := (
		_count_bad_meat_on_table() >= MAX_BAD_MEAT_ON_TABLE
	)

	for meat_id in ALL_MEATS:
		if REQUIRED_MEATS.has(meat_id):
			if _remaining_required(meat_id) <= 0:
				continue

			possible_ids.append(meat_id)
			weights.append(_get_current_required_spawn_weight())

		elif OPTIONAL_GOOD_MEATS.has(meat_id):
			possible_ids.append(meat_id)
			weights.append(OPTIONAL_SPAWN_WEIGHT)

		elif BAD_MEATS.has(meat_id):
			# Once ten bad pieces are present, temporarily remove
			# every bad type from the spawn pool.
			if bad_limit_reached:
				continue

			possible_ids.append(meat_id)
			weights.append(BAD_SPAWN_WEIGHT)

	if possible_ids.is_empty():
		# Optional good meat is always a safe fallback. This also
		# avoids bypassing the bad-meat cap through ALL_MEATS.
		return String(OPTIONAL_GOOD_MEATS.pick_random())

	var total_weight := 0.0

	for weight in weights:
		total_weight += weight

	var random_value := randf() * total_weight

	for index in range(possible_ids.size()):
		random_value -= weights[index]

		if random_value <= 0.0:
			return possible_ids[index]

	return possible_ids.back()


func _get_unfinished_required_meats() -> Array[String]:
	var unfinished: Array[String] = []

	for meat_id in REQUIRED_MEATS:
		if _remaining_required(meat_id) > 0:
			unfinished.append(meat_id)

	return unfinished


func _is_currently_needed_required_meat(meat_id: String) -> bool:
	return (
		REQUIRED_MEATS.has(meat_id)
		and _remaining_required(meat_id) > 0
	)


func _count_bad_meat_on_table() -> int:
	var bad_count := 0

	for piece in pieces:
		if not is_instance_valid(piece):
			continue

		var meat_id := String(piece.get_meta("meat_id", ""))

		if BAD_MEATS.has(meat_id):
			bad_count += 1

	return bad_count


func _record_replacement_spawn(meat_id: String) -> void:
	if _is_currently_needed_required_meat(meat_id):
		replacement_spawns_without_needed = 0
	else:
		replacement_spawns_without_needed += 1


# ============================================================
# MEAT SPAWNING
# ============================================================

func _spawn_piece(
	meat_id: String,
	animate_throw: bool = true,
	counts_for_pity: bool = false
) -> Node2D:
	if not MEAT_TEXTURES.has(meat_id):
		return null

	if counts_for_pity:
		_record_replacement_spawn(meat_id)

	var piece := Node2D.new()

	piece.name = "Meat_" + meat_id
	piece.set_meta("meat_id", meat_id)
	piece.set_meta("reserved", animate_throw)
	piece.set_meta("spawn_protected", true)
	piece.z_as_relative = false

	var sprite := Sprite2D.new()

	sprite.name = "Sprite"
	sprite.texture = MEAT_TEXTURES[meat_id]
	sprite.scale = MEAT_SCALE
	sprite.centered = true
	sprite.offset = Vector2.ZERO

	piece.add_child(sprite)

	var final_rotation := randf_range(-0.20, 0.20)

	var landing_position := _find_landing_position(
		meat_id,
		sprite,
		final_rotation
	)

	piece.set_meta("landing_position", landing_position)
	piece.set_meta("final_rotation", final_rotation)

	active_items.add_child(piece)
	pieces.append(piece)

	_move_piece_to_top_of_dropped_stack(piece)

	if animate_throw:
		_throw_piece_onto_table(
			piece,
			sprite,
			landing_position,
			final_rotation
		)
	else:
		piece.position = landing_position
		piece.rotation = final_rotation
		piece.set_meta("reserved", false)
		_begin_spawn_protection(piece)

	return piece


# ============================================================
# SPAWN POSITION ANALYSIS
# ============================================================

func _find_landing_position(
	meat_id: String,
	sprite: Sprite2D,
	rotation_value: float
) -> Vector2:
	var allowed_centers := _get_allowed_center_rect(
		meat_id,
		sprite,
		rotation_value
	)

	if pieces.is_empty():
		return _random_point_in_rect(allowed_centers)

	var spread_position := allowed_centers.get_center()
	var spread_score := -INF
	var found_spread := false

	var overlap_position := allowed_centers.get_center()
	var overlap_score := -INF
	var found_overlap := false

	for _attempt in range(PLACEMENT_ATTEMPTS):
		var candidate := _random_point_in_rect(allowed_centers)

		var evaluation := _evaluate_spawn_position(
			meat_id,
			sprite,
			candidate,
			rotation_value
		)

		if not bool(evaluation["valid"]):
			continue

		var total_overlap := float(
			evaluation["total_overlap_ratio"]
		)

		var minimum_distance := float(
			evaluation["minimum_distance"]
		)

		var current_spread_score := (
			minimum_distance
			- total_overlap * 850.0
			+ randf_range(-8.0, 8.0)
		)

		if current_spread_score > spread_score:
			spread_score = current_spread_score
			spread_position = candidate
			found_spread = true

		if int(evaluation["overlap_count"]) > 0:
			var difference := absf(
				total_overlap - TARGET_NATURAL_OVERLAP
			)

			var current_overlap_score := (
				-difference * 1000.0
				+ minimum_distance * 0.03
			)

			if current_overlap_score > overlap_score:
				overlap_score = current_overlap_score
				overlap_position = candidate
				found_overlap = true

	if found_overlap and randf() < NATURAL_OVERLAP_CHANCE:
		return overlap_position

	if found_spread:
		return spread_position

	if found_overlap:
		return overlap_position

	return _find_grid_position(
		meat_id,
		sprite,
		rotation_value,
		allowed_centers
	)


func _find_grid_position(
	meat_id: String,
	sprite: Sprite2D,
	rotation_value: float,
	allowed_centers: Rect2
) -> Vector2:
	var best_position := allowed_centers.get_center()
	var best_score := -INF

	for row in range(GRID_ROWS):
		for column in range(GRID_COLUMNS):
			var x_ratio := (
				(float(column) + 0.5)
				/ float(GRID_COLUMNS)
			)

			var y_ratio := (
				(float(row) + 0.5)
				/ float(GRID_ROWS)
			)

			var candidate := Vector2(
				lerpf(
					allowed_centers.position.x,
					allowed_centers.end.x,
					x_ratio
				),

				lerpf(
					allowed_centers.position.y,
					allowed_centers.end.y,
					y_ratio
				)
			)

			var evaluation := _evaluate_spawn_position(
				meat_id,
				sprite,
				candidate,
				rotation_value
			)

			if not bool(evaluation["valid"]):
				continue

			var candidate_score := (
				float(evaluation["minimum_distance"])
				- float(
					evaluation["total_overlap_ratio"]
				) * 850.0
			)

			if candidate_score > best_score:
				best_score = candidate_score
				best_position = candidate

	return best_position


func _evaluate_spawn_position(
	meat_id: String,
	sprite: Sprite2D,
	candidate_position: Vector2,
	rotation_value: float
) -> Dictionary:
	var candidate_aabb := _get_visible_aabb_at_position(
		meat_id,
		sprite,
		candidate_position,
		rotation_value
	)

	var candidate_area := _rect_area(candidate_aabb)

	var valid := candidate_area > 0.0
	var overlap_count := 0
	var total_overlap_ratio := 0.0
	var maximum_pair_ratio := 0.0
	var minimum_distance := INF

	for existing_piece in pieces:
		if not is_instance_valid(existing_piece):
			continue

		var existing_aabb := _get_piece_planned_aabb(
			existing_piece
		)

		var distance := candidate_aabb.get_center().distance_to(
			existing_aabb.get_center()
		)

		minimum_distance = minf(
			minimum_distance,
			distance
		)

		if not candidate_aabb.intersects(existing_aabb):
			continue

		var intersection := candidate_aabb.intersection(
			existing_aabb
		)

		if not intersection.has_area():
			continue

		var intersection_area := _rect_area(intersection)
		var existing_area := _rect_area(existing_aabb)

		if candidate_area <= 0.0 or existing_area <= 0.0:
			continue

		var candidate_ratio := (
			intersection_area / candidate_area
		)

		var existing_ratio := (
			intersection_area / existing_area
		)

		var pair_ratio := maxf(
			candidate_ratio,
			existing_ratio
		)

		overlap_count += 1
		total_overlap_ratio += candidate_ratio

		maximum_pair_ratio = maxf(
			maximum_pair_ratio,
			pair_ratio
		)

		if pair_ratio > MAX_PAIR_OVERLAP_RATIO:
			valid = false

	if total_overlap_ratio > MAX_TOTAL_OVERLAP_RATIO:
		valid = false

	if minimum_distance == INF:
		minimum_distance = 999999.0

	return {
		"valid": valid,
		"aabb": candidate_aabb,
		"overlap_count": overlap_count,
		"total_overlap_ratio": total_overlap_ratio,
		"maximum_pair_ratio": maximum_pair_ratio,
		"minimum_distance": minimum_distance,
	}


func _get_piece_planned_aabb(piece: Node2D) -> Rect2:
	var sprite := piece.get_node_or_null("Sprite") as Sprite2D

	if sprite == null:
		return Rect2(
			piece.position - Vector2(25, 25),
			Vector2(50, 50)
		)

	var meat_id := String(piece.get_meta("meat_id"))

	var planned_position := piece.position
	var planned_rotation := piece.rotation

	if piece.has_meta("landing_position"):
		planned_position = piece.get_meta("landing_position")

	if piece.has_meta("final_rotation"):
		planned_rotation = float(
			piece.get_meta("final_rotation")
		)

	return _get_visible_aabb_at_position(
		meat_id,
		sprite,
		planned_position,
		planned_rotation
	)


func _rect_area(rectangle: Rect2) -> float:
	return (
		maxf(0.0, rectangle.size.x)
		* maxf(0.0, rectangle.size.y)
	)


# ============================================================
# VISIBLE MEAT BOUNDS
# ============================================================

func _get_allowed_center_rect(
	meat_id: String,
	sprite: Sprite2D,
	rotation_value: float
) -> Rect2:
	var offsets := _get_rotated_visible_offsets(
		meat_id,
		sprite,
		rotation_value
	)

	var minimum_offset_x := INF
	var maximum_offset_x := -INF
	var minimum_offset_y := INF
	var maximum_offset_y := -INF

	for offset in offsets:
		minimum_offset_x = minf(minimum_offset_x, offset.x)
		maximum_offset_x = maxf(maximum_offset_x, offset.x)

		minimum_offset_y = minf(minimum_offset_y, offset.y)
		maximum_offset_y = maxf(maximum_offset_y, offset.y)

	var minimum_center := Vector2(
		MEAT_AREA.position.x - minimum_offset_x,
		MEAT_AREA.position.y - minimum_offset_y
	)

	var maximum_center := Vector2(
		MEAT_AREA.end.x - maximum_offset_x,
		MEAT_AREA.end.y - maximum_offset_y
	)

	return Rect2(
		minimum_center,
		maximum_center - minimum_center
	)


func _random_point_in_rect(rectangle: Rect2) -> Vector2:
	return Vector2(
		randf_range(
			rectangle.position.x,
			rectangle.end.x
		),

		randf_range(
			rectangle.position.y,
			rectangle.end.y
		)
	)


func _get_visible_aabb_at_position(
	meat_id: String,
	sprite: Sprite2D,
	center_position: Vector2,
	rotation_value: float
) -> Rect2:
	var offsets := _get_rotated_visible_offsets(
		meat_id,
		sprite,
		rotation_value
	)

	var minimum_x := INF
	var maximum_x := -INF
	var minimum_y := INF
	var maximum_y := -INF

	for offset in offsets:
		var point := center_position + offset

		minimum_x = minf(minimum_x, point.x)
		maximum_x = maxf(maximum_x, point.x)

		minimum_y = minf(minimum_y, point.y)
		maximum_y = maxf(maximum_y, point.y)

	return Rect2(
		Vector2(minimum_x, minimum_y),

		Vector2(
			maximum_x - minimum_x,
			maximum_y - minimum_y
		)
	)


func _get_rotated_visible_offsets(
	meat_id: String,
	sprite: Sprite2D,
	rotation_value: float
) -> Array[Vector2]:
	var visible_rect := _get_visible_sprite_rect(
		meat_id,
		sprite
	)

	var corners: Array[Vector2] = [
		visible_rect.position,

		Vector2(
			visible_rect.end.x,
			visible_rect.position.y
		),

		visible_rect.end,

		Vector2(
			visible_rect.position.x,
			visible_rect.end.y
		),
	]

	var offsets: Array[Vector2] = []

	for corner in corners:
		var scaled_corner := Vector2(
			corner.x * sprite.scale.x,
			corner.y * sprite.scale.y
		)

		offsets.append(
			scaled_corner.rotated(rotation_value)
		)

	return offsets


func _get_visible_sprite_rect(
	meat_id: String,
	sprite: Sprite2D
) -> Rect2:
	if (
		not meat_alpha_rects.has(meat_id)
		or not meat_images.has(meat_id)
		or sprite.texture == null
	):
		var full_size := (
			sprite.texture.get_size()
			if sprite.texture != null
			else Vector2(50, 50)
		)

		return Rect2(
			-full_size * 0.5,
			full_size
		)

	var alpha_rect := meat_alpha_rects[meat_id] as Rect2i
	var image := meat_images[meat_id] as Image

	var texture_size := sprite.texture.get_size()

	var image_size := Vector2(
		image.get_width(),
		image.get_height()
	)

	var alpha_end := (
		alpha_rect.position + alpha_rect.size
	)

	var normalized_start := Vector2(
		alpha_rect.position
	) / image_size

	var normalized_end := Vector2(
		alpha_end
	) / image_size

	var texture_start := (
		normalized_start
		* texture_size
		- texture_size * 0.5
	)

	var texture_end := (
		normalized_end
		* texture_size
		- texture_size * 0.5
	)

	return Rect2(
		texture_start,
		texture_end - texture_start
	)


# ============================================================
# MEAT FALLING
# ============================================================

func _throw_piece_onto_table(
	piece: Node2D,
	sprite: Sprite2D,
	landing_position: Vector2,
	final_rotation: float
) -> void:
	var displayed_height := 80.0

	if sprite.texture != null:
		displayed_height = (
			sprite.texture.get_size().y
			* absf(sprite.scale.y)
		)

	var starting_position := Vector2(
		clampf(
			landing_position.x + randf_range(-160.0, 160.0),
			40.0,
			SCREEN_SIZE.x - 40.0
		),

		-displayed_height - randf_range(60.0, 150.0)
	)

	piece.position = starting_position

	piece.rotation = (
		final_rotation
		+ randf_range(-0.65, 0.65)
	)

	piece.scale = Vector2(0.92, 0.92)

	var movement_tween := create_tween()

	movement_tween.tween_property(
		piece,
		"position",
		landing_position,
		THROW_DURATION
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	var appearance_tween := create_tween()
	appearance_tween.set_parallel(true)

	appearance_tween.tween_property(
		piece,
		"rotation",
		final_rotation,
		THROW_DURATION
	)

	appearance_tween.tween_property(
		piece,
		"scale",
		Vector2.ONE,
		THROW_DURATION
	)

	movement_tween.finished.connect(
		func() -> void:
			if not is_instance_valid(piece):
				return

			piece.position = landing_position
			piece.rotation = final_rotation
			piece.scale = Vector2.ONE
			piece.set_meta("reserved", false)

			_play_landing_bounce(piece)
			_begin_spawn_protection(piece)
	)


func _begin_spawn_protection(piece: Node2D) -> void:
	if not is_instance_valid(piece):
		return

	piece.set_meta("spawn_protected", true)

	await get_tree().create_timer(
		SPAWN_PROTECTION_DURATION
	).timeout

	if is_instance_valid(piece):
		piece.set_meta("spawn_protected", false)


func _play_landing_bounce(piece: Node2D) -> void:
	if not is_instance_valid(piece):
		return

	var bounce_tween := create_tween()

	bounce_tween.tween_property(
		piece,
		"scale",
		Vector2(1.035, 0.965),
		0.055
	)

	bounce_tween.tween_property(
		piece,
		"scale",
		Vector2.ONE,
		0.075
	)


func _maintain_table_count() -> void:
	if not gameplay_active:
		return

	while pieces.size() < TABLE_MEAT_COUNT:
		var next_meat_id := _choose_spawn_id(true)

		_spawn_piece(
			next_meat_id,
			true,
			true
		)


# ============================================================
# MEAT LAYERING
# ============================================================

func _move_piece_to_top_of_dropped_stack(piece: Node2D) -> void:
	if not pieces.has(piece):
		return

	pieces.erase(piece)
	pieces.append(piece)

	_normalize_dropped_meat_layers()


func _normalize_dropped_meat_layers() -> void:
	var dropped_index := 0

	for piece in pieces:
		if not is_instance_valid(piece):
			continue

		if piece == dragged_piece:
			piece.z_index = Z_PICKED_UP_MEAT
		else:
			piece.z_index = (
				Z_DROPPED_MEAT_BASE + dropped_index
			)

			dropped_index += 1


# ============================================================
# PIXEL-PERFECT SELECTION
# ============================================================

func _is_mouse_on_visible_meat(
	piece: Node2D,
	mouse_position: Vector2
) -> bool:
	if not is_instance_valid(piece):
		return false

	var sprite := piece.get_node_or_null("Sprite") as Sprite2D

	if sprite == null or sprite.texture == null:
		return false

	var meat_id := String(piece.get_meta("meat_id"))

	if not meat_images.has(meat_id):
		return false

	var image := meat_images[meat_id] as Image
	var local_mouse := sprite.to_local(mouse_position)
	var texture_size := sprite.texture.get_size()

	var texture_pixel := (
		local_mouse + texture_size * 0.5
	)

	if (
		texture_pixel.x < 0.0
		or texture_pixel.y < 0.0
		or texture_pixel.x >= texture_size.x
		or texture_pixel.y >= texture_size.y
	):
		return false

	var image_x := int(
		floor(
			texture_pixel.x
			/ texture_size.x
			* image.get_width()
		)
	)

	var image_y := int(
		floor(
			texture_pixel.y
			/ texture_size.y
			* image.get_height()
		)
	)

	image_x = clampi(
		image_x,
		0,
		image.get_width() - 1
	)

	image_y = clampi(
		image_y,
		0,
		image.get_height() - 1
	)

	return (
		image.get_pixel(image_x, image_y).a
		> ALPHA_HIT_THRESHOLD
	)


# ============================================================
# DRAGGING
# ============================================================

func _begin_drag(mouse_position: Vector2) -> void:
	if dragged_piece != null:
		return

	var selected_piece: Node2D = null
	var selected_z := -999999

	for piece in pieces:
		if not is_instance_valid(piece):
			continue

		# A meat already targeted by a customer cannot be dragged.
		if bool(piece.get_meta("reserved", false)):
			continue

		if not _is_mouse_on_visible_meat(
			piece,
			mouse_position
		):
			continue

		if piece.z_index > selected_z:
			selected_piece = piece
			selected_z = piece.z_index

	if selected_piece == null:
		return

	dragged_piece = selected_piece
	drag_start_position = selected_piece.position
	drag_offset = selected_piece.position - mouse_position

	selected_piece.z_index = Z_PICKED_UP_MEAT

	_show_drop_targets()
	_play_sfx(SFX_PICKUP)


func _end_drag(mouse_position: Vector2) -> void:
	if dragged_piece == null:
		_hide_drop_targets()
		return

	if not is_instance_valid(dragged_piece):
		dragged_piece = null
		_hide_drop_targets()
		return

	var piece := dragged_piece
	dragged_piece = null

	_hide_drop_targets()

	if _piece_hits_drop_target(piece, mouse_position, BASKET_RECT):
		_drop_in_basket(piece)
		return

	if _piece_hits_drop_target(piece, mouse_position, TRASH_RECT):
		_drop_in_trash(piece)
		return

	# The meat remains at the exact drop position when it is
	# completely inside the table.
	if _is_visible_meat_fully_inside_area(piece):
		piece.set_meta("landing_position", piece.position)
		piece.set_meta("final_rotation", piece.rotation)

		_move_piece_to_top_of_dropped_stack(piece)
		return

	_return_piece_to_pickup_position(piece)


func _piece_hits_drop_target(
	piece: Node2D,
	release_position: Vector2,
	target_rect: Rect2
) -> bool:
	var forgiving_target := target_rect.grow(DROP_TARGET_MARGIN)
	if forgiving_target.has_point(release_position):
		return true

	var sprite := piece.get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		return false

	var meat_id := String(piece.get_meta("meat_id", ""))
	var visible_bounds := _get_visible_aabb_at_position(
		meat_id,
		sprite,
		piece.position,
		piece.rotation
	)
	var overlap := visible_bounds.intersection(forgiving_target)
	var meat_area := _rect_area(visible_bounds)
	return (
		meat_area > 0.0
		and overlap.has_area()
		and _rect_area(overlap) / meat_area >= MIN_DROP_OVERLAP_RATIO
	)


func _return_piece_to_pickup_position(piece: Node2D) -> void:
	if not is_instance_valid(piece):
		return

	_move_piece_to_top_of_dropped_stack(piece)

	var return_tween := create_tween()

	return_tween.tween_property(
		piece,
		"position",
		drag_start_position,
		0.20
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)


func _is_visible_meat_fully_inside_area(piece: Node2D) -> bool:
	var sprite := piece.get_node_or_null("Sprite") as Sprite2D

	if sprite == null:
		return false

	var meat_id := String(piece.get_meta("meat_id"))

	var visible_rect := _get_visible_sprite_rect(
		meat_id,
		sprite
	)

	var corners: Array[Vector2] = [
		visible_rect.position,

		Vector2(
			visible_rect.end.x,
			visible_rect.position.y
		),

		visible_rect.end,

		Vector2(
			visible_rect.position.x,
			visible_rect.end.y
		),
	]

	for corner in corners:
		if not MEAT_AREA.has_point(
			sprite.to_global(corner)
		):
			return false

	return true


# ============================================================
# BASKET AND TRASH
# ============================================================

func _drop_in_basket(piece: Node2D) -> void:
	var meat_id := String(piece.get_meta("meat_id"))

	var is_still_required := (
		REQUIRED_MEATS.has(meat_id)
		and _remaining_required(meat_id) > 0
	)

	if is_still_required:
		collected_amounts[meat_id] = (
			int(collected_amounts[meat_id]) + 1
		)

		_show_action_feedback("ordered", piece.global_position)
		if not dialogue_seen.has("first_ordered"):
			dialogue_seen["first_ordered"] = true
			_show_vendor_line(
				"That's part of the order. Keep protecting the pieces we still need.",
				"happy",
				"feedback"
			)
		_play_sfx(SFX_ACCEPT)

		var order_complete := _is_order_complete()

		_remove_piece(
			piece,
			not order_complete
		)

		_update_hud()

		if order_complete:
			_start_success_ending()

		return

	suspicious_basket_attempts += 1
	_show_action_feedback("not_ordered", piece.global_position)
	_play_sfx(SFX_WRONG)
	_return_piece_to_pickup_position(piece)

	_update_hud()
	_show_mistake_dialogue("suspicion")
	_check_failure_conditions()


func _drop_in_trash(piece: Node2D) -> void:
	var meat_id := String(piece.get_meta("meat_id"))

	if BAD_MEATS.has(meat_id):
		_show_action_feedback("good_call", piece.global_position)
		if not dialogue_seen.has("first_good_call"):
			dialogue_seen["first_good_call"] = true
			_show_vendor_line(
				"Good call. That scrap did not belong with the usable cuts.",
				"happy",
				"feedback"
			)
		_play_sfx(SFX_TRASH)
		_remove_piece(piece, true)
		_update_hud()
		return

	wasted_good_meat += 1
	_show_action_feedback("wasted", piece.global_position)
	_play_sfx(SFX_WRONG)

	var reached_failure_limit := (
		wasted_good_meat >= FAILURE_LIMIT
	)

	_remove_piece(
		piece,
		not reached_failure_limit
	)

	_update_hud()
	_show_mistake_dialogue("wasted")
	_check_failure_conditions()


func _remove_piece(
	piece: Node2D,
	replenish: bool
) -> void:
	if not is_instance_valid(piece):
		return

	# A hand may still be holding an attack reference while the player
	# places this meat in the basket or trash. Cancel that attack first
	# so delayed hold callbacks never try to cast a freed meat object.
	_cancel_hand_attacks_targeting_piece(piece)

	pieces.erase(piece)
	piece.queue_free()

	_normalize_dropped_meat_layers()

	if replenish:
		_maintain_table_count()


# ============================================================
# CUSTOMER HANDS — SECTIONS 4 TO 6
# ============================================================

func _get_difficulty_phase() -> int:
	if gameplay_elapsed < EARLY_PHASE_END:
		return 0

	if gameplay_elapsed < MID_PHASE_END:
		return 1

	return 2


func _announce_difficulty_phase() -> void:
	var phase := _get_difficulty_phase()
	if phase <= announced_difficulty_phase:
		return
	announced_difficulty_phase = phase
	if phase == 1:
		_show_vendor_line(
			"More hands are coming now. Do not let the crowd distract you from the order.",
			"concerned",
			"warning"
		)
	else:
		_show_vendor_line(
			"This is the rush! Sort quickly, but do not throw away good meat.",
			"angry",
			"warning"
		)


func _get_random_customer_interval() -> float:
	match _get_difficulty_phase():
		0:
			return randf_range(
				EARLY_HAND_INTERVAL_MIN,
				EARLY_HAND_INTERVAL_MAX
			)
		1:
			return randf_range(
				MID_HAND_INTERVAL_MIN,
				MID_HAND_INTERVAL_MAX
			)
		_:
			return randf_range(
				LATE_HAND_INTERVAL_MIN,
				LATE_HAND_INTERVAL_MAX
			)


func _get_current_max_active_hands() -> int:
	match _get_difficulty_phase():
		0:
			return EARLY_MAX_ACTIVE_HANDS
		1:
			return MID_MAX_ACTIVE_HANDS
		_:
			return LATE_MAX_ACTIVE_HANDS


func _get_current_required_spawn_weight() -> float:
	match _get_difficulty_phase():
		0:
			return EARLY_REQUIRED_SPAWN_WEIGHT
		1:
			return MID_REQUIRED_SPAWN_WEIGHT
		_:
			return LATE_REQUIRED_SPAWN_WEIGHT


func _get_current_required_pity_limit() -> int:
	match _get_difficulty_phase():
		0:
			return EARLY_REQUIRED_PITY_LIMIT
		1:
			return MID_REQUIRED_PITY_LIMIT
		_:
			return LATE_REQUIRED_PITY_LIMIT


func _reset_double_rush_cooldown() -> void:
	double_rush_cooldown = randf_range(
		DOUBLE_RUSH_MIN_COOLDOWN,
		DOUBLE_RUSH_MAX_COOLDOWN
	)


func _get_valid_hand_targets(
	side_filter: int = 0
) -> Array[Node2D]:
	var required_candidates: Array[Node2D] = []
	var optional_candidates: Array[Node2D] = []

	for piece in pieces:
		if not is_instance_valid(piece):
			continue

		if piece == dragged_piece:
			continue

		if bool(piece.get_meta("reserved", false)):
			continue

		if bool(piece.get_meta("spawn_protected", false)):
			continue

		var meat_id := String(piece.get_meta("meat_id", ""))

		if BAD_MEATS.has(meat_id):
			continue

		var target_center := _get_piece_planned_aabb(
			piece
		).get_center()

		if side_filter < 0 and target_center.x >= SCREEN_CENTER.x:
			continue

		if side_filter > 0 and target_center.x < SCREEN_CENTER.x:
			continue

		if _is_currently_needed_required_meat(meat_id):
			required_candidates.append(piece)
		else:
			optional_candidates.append(piece)

	if not required_candidates.is_empty():
		return required_candidates

	return optional_candidates


func _send_customer_hand() -> void:
	if active_hand_count >= _get_current_max_active_hands():
		return

	var candidates := _get_valid_hand_targets()

	if candidates.is_empty():
		return

	var target: Node2D = candidates.pick_random()
	_create_customer_hand_attack(target)


func _can_start_double_hand_rush() -> bool:
	if _get_difficulty_phase() == 0:
		return false

	if active_hand_count > _get_current_max_active_hands() - 2:
		return false

	return (
		not _get_valid_hand_targets(-1).is_empty()
		and not _get_valid_hand_targets(1).is_empty()
	)


func _start_double_hand_rush() -> void:
	if double_rush_in_progress:
		return

	double_rush_in_progress = true
	_reset_double_rush_cooldown()
	_play_one_shot_sfx(SFX_DOUBLE_HAND_RUSH, -5.0)

	var left_candidates := _get_valid_hand_targets(-1)
	var right_candidates := _get_valid_hand_targets(1)

	if left_candidates.is_empty() or right_candidates.is_empty():
		double_rush_in_progress = false
		return

	var left_target: Node2D = left_candidates.pick_random()
	_create_customer_hand_attack(left_target, true)

	await get_tree().create_timer(
		DOUBLE_RUSH_SECOND_HAND_DELAY
	).timeout

	if (
		gameplay_active
		and active_hand_count < _get_current_max_active_hands()
	):
		right_candidates = _get_valid_hand_targets(1)

		if not right_candidates.is_empty():
			var right_target: Node2D = right_candidates.pick_random()
			_create_customer_hand_attack(right_target, false)

	double_rush_in_progress = false


func _create_customer_hand_attack(
	target: Node2D,
	forced_left_side: Variant = null
) -> void:
	if target == null or not is_instance_valid(target):
		return

	if bool(target.get_meta("reserved", false)):
		return

	if active_hand_count >= _get_current_max_active_hands():
		return

	var meat_id := String(target.get_meta("meat_id", ""))
	var is_required_target := _is_currently_needed_required_meat(
		meat_id
	)

	target.set_meta("reserved", true)
	target.set_meta("snatch_targeted", true)

	var target_aabb := _get_piece_planned_aabb(target)
	var grab_position := target_aabb.get_center()
	var comes_from_left := grab_position.x < SCREEN_CENTER.x

	if forced_left_side is bool:
		comes_from_left = bool(forced_left_side)

	var hand_root := Node2D.new()
	hand_root.name = (
		"CustomerHandLeft"
		if comes_from_left
		else "CustomerHandRight"
	)
	hand_root.z_as_relative = false
	hand_root.z_index = Z_HANDS

	var hand_sprite := Sprite2D.new()

	if comes_from_left:
		hand_sprite.texture = LEFT_HAND_TEXTURE
		hand_sprite.flip_h = false
	else:
		hand_sprite.texture = RIGHT_HAND_TEXTURE
		hand_sprite.flip_h = true

	hand_sprite.scale = HAND_SCALE
	hand_sprite.centered = true
	hand_root.add_child(hand_sprite)

	var grab_uv := (
		LEFT_HAND_GRAB_UV
		if comes_from_left
		else RIGHT_HAND_GRAB_UV
	)

	_align_hand_palm_to_root(hand_sprite, grab_uv)
	add_child(hand_root)

	var offscreen_x := (
		-HAND_OFFSCREEN_DISTANCE
		if comes_from_left
		else SCREEN_SIZE.x + HAND_OFFSCREEN_DISTANCE
	)

	hand_root.position = Vector2(
		offscreen_x,
		grab_position.y
	)

	var attack: Dictionary = {
		"root": hand_root,
		"sprite": hand_sprite,
		"target": target,
		"comes_from_left": comes_from_left,
		"grab_position": grab_position,
		"offscreen_x": offscreen_x,
		"state": HandState.APPROACHING,
		"has_meat": false,
		"is_required_target": is_required_target,
		"can_be_slapped": false,
		"indicator": null,
		"approach_tween": null,
		"retreat_tween": null,
		"recoil_tween": null,
	}

	active_hand_attacks.append(attack)
	active_hand_count = active_hand_attacks.size()
	_show_hand_attack_warning(attack)


func _show_hand_attack_warning(attack: Dictionary) -> void:
	if not _is_hand_attack_active(attack):
		return
	var comes_from_left := bool(attack.get("comes_from_left", true))
	var grab_position := attack.get("grab_position", SCREEN_CENTER) as Vector2
	var indicator := Sprite2D.new()
	indicator.name = "HandAttackIndicator"
	indicator.texture = HAND_ATTACK_INDICATOR_TEXTURE
	indicator.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	indicator.position = Vector2(
		30.0 if comes_from_left else SCREEN_SIZE.x - 30.0,
		clampf(grab_position.y, 42.0, SCREEN_SIZE.y - 42.0)
	)
	indicator.flip_h = not comes_from_left
	indicator.scale = Vector2(0.78, 0.78)
	indicator.z_as_relative = false
	indicator.z_index = Z_HANDS + 4
	add_child(indicator)
	attack["indicator"] = indicator
	var pulse := create_tween().set_loops()
	pulse.tween_property(indicator, "scale", Vector2.ONE, 0.10)
	pulse.tween_property(indicator, "scale", Vector2(0.78, 0.78), 0.10)
	await get_tree().create_timer(HAND_WARNING_DURATION).timeout
	pulse.kill()
	if is_instance_valid(indicator):
		indicator.queue_free()
	attack["indicator"] = null
	if _is_hand_attack_active(attack) and gameplay_active:
		_begin_hand_approach(attack)


func _begin_hand_approach(attack: Dictionary) -> void:
	if not _is_hand_attack_active(attack):
		return

	var hand_root := attack.get("root") as Node2D
	var target := _get_attack_target(attack)

	if (
		hand_root == null
		or not is_instance_valid(hand_root)
		or target == null
		or not is_instance_valid(target)
	):
		_cancel_hand_attack(attack)
		return

	var grab_position := _get_piece_planned_aabb(
		target
	).get_center()

	attack["grab_position"] = grab_position

	var comes_from_left := bool(
		attack.get("comes_from_left", true)
	)

	_play_one_shot_sfx(
		SFX_HAND_WHOOSH_LEFT
		if comes_from_left
		else SFX_HAND_WHOOSH_RIGHT,
		-5.0
	)

	var approach_tween := create_tween()
	attack["approach_tween"] = approach_tween

	approach_tween.tween_property(
		hand_root,
		"position",
		grab_position,
		HAND_APPROACH_DURATION
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	approach_tween.finished.connect(
		func() -> void:
			_on_hand_approach_finished(attack)
	)


func _on_hand_approach_finished(attack: Dictionary) -> void:
	if not _is_hand_attack_active(attack):
		return

	if int(attack.get("state")) != HandState.APPROACHING:
		return

	attack["approach_tween"] = null

	if not gameplay_active:
		_cancel_hand_attack(attack)
		return

	var target := _get_attack_target(attack)

	if (
		target == null
		or not is_instance_valid(target)
		or not pieces.has(target)
	):
		_cancel_hand_attack(attack)
		return

	if bool(attack.get("is_required_target", false)):
		_start_required_hand_hold(attack)
	else:
		attack["state"] = HandState.GRABBING
		_grab_hand_target(attack)


func _start_required_hand_hold(attack: Dictionary) -> void:
	if not _is_hand_attack_active(attack):
		return

	attack["state"] = HandState.HOLDING
	attack["can_be_slapped"] = true

	_play_one_shot_sfx(SFX_REQUIRED_HAND_PAUSE, -8.0)

	await get_tree().create_timer(
		REQUIRED_HAND_HOLD_DURATION
	).timeout

	if not _is_hand_attack_active(attack):
		return

	if int(attack.get("state")) != HandState.HOLDING:
		return

	attack["can_be_slapped"] = false
	attack["state"] = HandState.GRABBING
	_grab_hand_target(attack)


func _try_slap_required_hand(
	mouse_position: Vector2
) -> bool:
	for index in range(
		active_hand_attacks.size() - 1,
		-1,
		-1
	):
		var attack := active_hand_attacks[index]

		if int(
			attack.get("state", HandState.FINISHED)
		) != HandState.HOLDING:
			continue

		if not bool(attack.get("can_be_slapped", false)):
			continue

		if not bool(attack.get("is_required_target", false)):
			continue

		if not _is_mouse_on_visible_hand(
			attack,
			mouse_position
		):
			continue

		_slap_hand_attack(attack)
		return true

	return false


func _is_mouse_on_visible_hand(
	attack: Dictionary,
	mouse_position: Vector2
) -> bool:
	var sprite := attack.get("sprite") as Sprite2D

	if (
		sprite == null
		or not is_instance_valid(sprite)
		or sprite.texture == null
	):
		return false

	var local_mouse := sprite.to_local(mouse_position)
	var texture_size := sprite.texture.get_size()
	var texture_pixel := local_mouse + texture_size * 0.5

	if (
		texture_pixel.x < 0.0
		or texture_pixel.y < 0.0
		or texture_pixel.x >= texture_size.x
		or texture_pixel.y >= texture_size.y
	):
		return false

	var image := sprite.texture.get_image()

	if image == null or image.is_empty():
		return true

	var image_x := clampi(
		int(
			floor(
				texture_pixel.x
				/ texture_size.x
				* image.get_width()
			)
		),
		0,
		image.get_width() - 1
	)

	var image_y := clampi(
		int(
			floor(
				texture_pixel.y
				/ texture_size.y
				* image.get_height()
			)
		),
		0,
		image.get_height() - 1
	)

	if sprite.flip_h:
		image_x = image.get_width() - 1 - image_x

	return (
		image.get_pixel(image_x, image_y).a
		> ALPHA_HIT_THRESHOLD
	)


func _slap_hand_attack(attack: Dictionary) -> void:
	if not _is_hand_attack_active(attack):
		return

	if int(attack.get("state")) != HandState.HOLDING:
		return

	attack["state"] = HandState.SLAPPED
	attack["can_be_slapped"] = false
	_kill_hand_attack_tweens(attack)

	var target := _get_attack_target(attack)

	if is_instance_valid(target):
		target.set_meta("reserved", false)
		target.set_meta("snatch_targeted", false)

	var hand_root := attack.get("root") as Node2D
	_show_action_feedback(
		"slapped",
		hand_root.global_position if hand_root != null else SCREEN_CENTER
	)
	if not dialogue_seen.has("first_slap"):
		dialogue_seen["first_slap"] = true
		_show_vendor_line(
			"Good! Stop them when they reach for something in our order.",
			"happy",
			"feedback"
		)
	_play_one_shot_sfx(SFX_HAND_SLAP, -2.0)
	_play_one_shot_sfx(SFX_HAND_RECOIL, -5.0)
	_show_slap_effects(attack)
	_start_slapped_hand_recoil(attack)


func _show_slap_effects(attack: Dictionary) -> void:
	var hand_root := attack.get("root") as Node2D

	if hand_root == null or not is_instance_valid(hand_root):
		return

	var impact := Sprite2D.new()
	impact.texture = SLAP_IMPACT_TEXTURE
	impact.position = hand_root.position
	impact.scale = Vector2(0.72, 0.72)
	impact.z_as_relative = false
	impact.z_index = Z_HANDS + 3
	add_child(impact)

	var impact_tween := create_tween()
	impact_tween.set_parallel(true)
	impact_tween.tween_property(
		impact,
		"scale",
		Vector2(1.02, 1.02),
		0.18
	)
	impact_tween.tween_property(
		impact,
		"modulate:a",
		0.0,
		0.18
	)
	impact_tween.finished.connect(
		func() -> void:
			if is_instance_valid(impact):
				impact.queue_free()
	)



func _start_slapped_hand_recoil(attack: Dictionary) -> void:
	if not _is_hand_attack_active(attack):
		return

	var hand_root := attack.get("root") as Node2D

	if hand_root == null or not is_instance_valid(hand_root):
		_finish_hand_attack(attack)
		return

	var direction := (
		-1.0
		if bool(attack.get("comes_from_left", true))
		else 1.0
	)

	var recoil_position := hand_root.position + Vector2(
		HAND_SLAP_RECOIL_DISTANCE * direction,
		0.0
	)

	var recoil_tween := create_tween()
	attack["recoil_tween"] = recoil_tween

	recoil_tween.tween_property(
		hand_root,
		"position",
		recoil_position,
		HAND_SLAP_RECOIL_DURATION
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	recoil_tween.finished.connect(
		func() -> void:
			attack["recoil_tween"] = null
			_start_slapped_hand_retreat(attack)
	)


func _start_slapped_hand_retreat(attack: Dictionary) -> void:
	if not _is_hand_attack_active(attack):
		return

	var hand_root := attack.get("root") as Node2D

	if hand_root == null or not is_instance_valid(hand_root):
		_finish_hand_attack(attack)
		return

	var exit_position := Vector2(
		float(attack.get("offscreen_x", 0.0)),
		hand_root.position.y
	)

	var retreat_tween := create_tween()
	attack["retreat_tween"] = retreat_tween

	retreat_tween.tween_property(
		hand_root,
		"position",
		exit_position,
		HAND_SLAP_RETREAT_DURATION
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	retreat_tween.finished.connect(
		func() -> void:
			attack["retreat_tween"] = null
			_finish_hand_attack(attack)
	)


func _grab_hand_target(attack: Dictionary) -> void:
	if not _is_hand_attack_active(attack):
		return

	if int(attack.get("state")) != HandState.GRABBING:
		return

	var hand_root := attack.get("root") as Node2D
	var target := _get_attack_target(attack)

	if (
		hand_root == null
		or not is_instance_valid(hand_root)
		or target == null
		or not is_instance_valid(target)
		or not pieces.has(target)
	):
		_cancel_hand_attack(attack)
		return

	var stolen_id := String(target.get_meta("meat_id"))

	_show_action_feedback("snatched", target.global_position)
	if not dialogue_seen.has("first_snatch"):
		dialogue_seen["first_snatch"] = true
		_show_vendor_line(
			"Too slow. Watch for the warning and slap a hand before it escapes.",
			"angry" if _is_currently_needed_required_meat(stolen_id) else "concerned",
			"feedback"
		)
	_play_sfx(SFX_STOLEN)

	pieces.erase(target)
	target.set_meta("reserved", false)
	target.set_meta("snatch_targeted", false)

	target.reparent(hand_root, true)
	target.z_as_relative = true
	target.z_index = -1
	attack["has_meat"] = true

	_normalize_dropped_meat_layers()
	_maintain_table_count()
	_start_hand_retreat(attack)


func _start_hand_retreat(attack: Dictionary) -> void:
	if not _is_hand_attack_active(attack):
		return

	var hand_root := attack.get("root") as Node2D

	if hand_root == null or not is_instance_valid(hand_root):
		_finish_hand_attack(attack)
		return

	attack["state"] = HandState.RETREATING
	attack["can_be_slapped"] = false

	var exit_position := Vector2(
		float(attack.get("offscreen_x", 0.0)),
		hand_root.position.y
	)

	var retreat_tween := create_tween()
	attack["retreat_tween"] = retreat_tween

	retreat_tween.tween_property(
		hand_root,
		"position",
		exit_position,
		HAND_RETREAT_DURATION
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	retreat_tween.finished.connect(
		func() -> void:
			attack["retreat_tween"] = null
			_finish_hand_attack(attack)
	)


func _get_attack_target(attack: Dictionary) -> Node2D:
	var target_value: Variant = attack.get("target", null)

	# Do not cast first. Godot throws "Trying to cast a freed object"
	# when a queued/freed meat is still stored inside the dictionary.
	if target_value == null or not is_instance_valid(target_value):
		return null

	if not target_value is Node2D:
		return null

	return target_value as Node2D


func _cancel_hand_attacks_targeting_piece(piece: Node2D) -> void:
	if piece == null or not is_instance_valid(piece):
		return

	var attacks_to_cancel: Array[Dictionary] = []

	for attack in active_hand_attacks:
		var target := _get_attack_target(attack)

		if target == piece:
			attacks_to_cancel.append(attack)

	for attack in attacks_to_cancel:
		_cancel_hand_attack(attack)


func _is_hand_attack_active(attack: Dictionary) -> bool:
	return (
		active_hand_attacks.has(attack)
		and int(
			attack.get("state", HandState.FINISHED)
		) != HandState.FINISHED
	)


func _cancel_hand_attack(attack: Dictionary) -> void:
	if not active_hand_attacks.has(attack):
		return

	if int(
		attack.get("state", HandState.FINISHED)
	) == HandState.FINISHED:
		return

	attack["state"] = HandState.CANCELLED
	attack["can_be_slapped"] = false
	_kill_hand_attack_tweens(attack)

	var target := _get_attack_target(attack)
	var has_meat := bool(attack.get("has_meat", false))

	if is_instance_valid(target):
		target.set_meta("snatch_targeted", false)

		if has_meat and gameplay_active:
			target.reparent(active_items, true)
			target.z_as_relative = false
			target.set_meta("reserved", false)
			target.set_meta("landing_position", target.position)
			target.set_meta("final_rotation", target.rotation)

			if not pieces.has(target):
				pieces.append(target)

			attack["has_meat"] = false
			_normalize_dropped_meat_layers()
		else:
			target.set_meta("reserved", false)

	_finish_hand_attack(attack)


func _cancel_all_hand_attacks() -> void:
	var attacks_to_cancel: Array[Dictionary] = []

	for attack in active_hand_attacks:
		attacks_to_cancel.append(attack)

	for attack in attacks_to_cancel:
		_cancel_hand_attack(attack)


func _kill_hand_attack_tweens(attack: Dictionary) -> void:
	for key in [
		"approach_tween",
		"retreat_tween",
		"recoil_tween",
	]:
		var tween_value: Variant = attack.get(key)

		if tween_value is Tween:
			var tween := tween_value as Tween

			if tween != null and tween.is_valid():
				tween.kill()

		attack[key] = null


# Makes the hand root's origin line up with the palm/grab point.
func _align_hand_palm_to_root(
	hand_sprite: Sprite2D,
	grab_uv: Vector2
) -> void:
	if hand_sprite.texture == null:
		hand_sprite.position = Vector2.ZERO
		return

	var texture_size := hand_sprite.texture.get_size()

	var grab_from_center := Vector2(
		(grab_uv.x - 0.5) * texture_size.x,
		(grab_uv.y - 0.5) * texture_size.y
	)

	if hand_sprite.flip_h:
		grab_from_center.x *= -1.0

	var scaled_grab_offset := Vector2(
		grab_from_center.x * hand_sprite.scale.x,
		grab_from_center.y * hand_sprite.scale.y
	)

	hand_sprite.position = -scaled_grab_offset


func _finish_hand_attack(attack: Dictionary) -> void:
	if not active_hand_attacks.has(attack):
		return

	_kill_hand_attack_tweens(attack)
	var indicator := attack.get("indicator") as Sprite2D
	if is_instance_valid(indicator):
		indicator.queue_free()
	attack["indicator"] = null

	var target := _get_attack_target(attack)
	var has_meat := bool(attack.get("has_meat", false))

	if is_instance_valid(target) and not has_meat:
		target.set_meta("reserved", false)
		target.set_meta("snatch_targeted", false)

	var hand_root := attack.get("root") as Node2D

	attack["state"] = HandState.FINISHED
	active_hand_attacks.erase(attack)
	active_hand_count = active_hand_attacks.size()

	if is_instance_valid(hand_root):
		hand_root.queue_free()


# ============================================================
# UI SETUP
# ============================================================

func _setup_targets_and_hud() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "GameplayUI"
	# The shared story session renders gameplay on layer 80. Keep the order and
	# mistake panels above that canvas, but below dialogue and ending overlays.
	ui_layer.layer = GAMEPLAY_HUD_LAYER
	add_child(ui_layer)
	ui_root = Control.new()
	ui_root.name = "Root"
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(ui_root)
	order_board = _add_ui_sprite(
		"OrderPanel",
		ORDER_PANEL_TEXTURE,
		ORDER_PANEL_ORIGIN + Vector2(146.5, 175.0)
	)
	mistake_board = _add_ui_sprite(
		"MistakeLimitsPanel",
		MISTAKE_PANEL_TEXTURE,
		MISTAKE_PANEL_ORIGIN + Vector2(146.5, 175.0)
	)
	var order_areas := {
		"belly": Rect2(Vector2(39.1, 91.5), Vector2(61.8, 39.8)),
		"liver": Rect2(Vector2(114.9, 91.5), Vector2(61.8, 39.8)),
		"spleen": Rect2(Vector2(191.2, 91.5), Vector2(61.8, 39.8)),
	}
	for meat_id: String in REQUIRED_MEATS:
		var area: Rect2 = order_areas[meat_id]
		order_value_labels[meat_id] = _make_ui_label(
			ORDER_PANEL_ORIGIN + area.position,
			area.size,
			18
		)
	wasted_markers = _create_mistake_markers(Vector2(44.4, 79.0))
	suspicion_markers = _create_mistake_markers(Vector2(44.4, 139.0))

	basket_sprite = Sprite2D.new()
	basket_sprite.texture = BASKET_TEXTURE
	basket_sprite.scale = Vector2(0.6, 0.6)
	basket_sprite.z_as_relative = false
	basket_sprite.z_index = Z_DROP_TARGETS
	add_child(basket_sprite)

	trash_sprite = Sprite2D.new()
	trash_sprite.texture = TRASH_TEXTURE
	trash_sprite.scale = Vector2(0.6, 0.6)
	trash_sprite.z_as_relative = false
	trash_sprite.z_index = Z_DROP_TARGETS
	add_child(trash_sprite)

	basket_hidden_position = _get_hidden_target_position(
		basket_sprite,
		basket_target_position
	)

	trash_hidden_position = _get_hidden_target_position(
		trash_sprite,
		trash_target_position
	)

	_update_hud()


func _add_ui_sprite(
	node_name: String,
	texture: Texture2D,
	position_value: Vector2
) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.position = position_value
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ui_root.add_child(sprite)
	return sprite


func _make_ui_label(
	position_value: Vector2,
	size_value: Vector2,
	font_size: int
) -> Label:
	var label := Label.new()
	label.position = position_value
	label.size = size_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", SHARED_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("fff0c2"))
	label.add_theme_color_override("font_shadow_color", Color("28130b"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	ui_root.add_child(label)
	return label


func _create_mistake_markers(local_position: Vector2) -> Array[TextureRect]:
	var markers: Array[TextureRect] = []
	var step := (196.7 - 21.0) / 4.0
	for index: int in range(FAILURE_LIMIT):
		var marker := TextureRect.new()
		marker.name = "Mistake%d" % (index + 1)
		marker.position = MISTAKE_PANEL_ORIGIN + local_position + Vector2(step * index, 0.0)
		marker.size = Vector2(21.0, 21.0)
		marker.pivot_offset = Vector2(10.5, 10.5)
		marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		marker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.texture = NO_MISTAKE_TEXTURE
		ui_root.add_child(marker)
		markers.append(marker)
	return markers


func _get_hidden_target_position(
	sprite: Sprite2D,
	target_position: Vector2
) -> Vector2:
	var displayed_height := 300.0

	if sprite.texture != null:
		displayed_height = (
			sprite.texture.get_size().y
			* absf(sprite.scale.y)
		)

	return Vector2(
		target_position.x,
		SCREEN_SIZE.y + displayed_height * 0.5 + 30.0
	)


func _show_drop_targets() -> void:
	if target_tween != null:
		target_tween.kill()

	basket_sprite.position = basket_hidden_position
	trash_sprite.position = trash_hidden_position

	basket_sprite.visible = true
	trash_sprite.visible = true

	target_tween = create_tween()
	target_tween.set_parallel(true)

	target_tween.tween_property(
		basket_sprite,
		"position",
		basket_target_position,
		TARGET_SLIDE_IN_DURATION
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	target_tween.tween_property(
		trash_sprite,
		"position",
		trash_target_position,
		TARGET_SLIDE_IN_DURATION
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)


func _hide_drop_targets() -> void:
	if target_tween != null:
		target_tween.kill()

	target_tween = create_tween()
	target_tween.set_parallel(true)

	target_tween.tween_property(
		basket_sprite,
		"position",
		basket_hidden_position,
		TARGET_SLIDE_OUT_DURATION
	)

	target_tween.tween_property(
		trash_sprite,
		"position",
		trash_hidden_position,
		TARGET_SLIDE_OUT_DURATION
	)

	target_tween.chain().tween_callback(
		func() -> void:
			basket_sprite.visible = false
			trash_sprite.visible = false
	)


func _hide_drop_targets_immediately() -> void:
	if target_tween != null:
		target_tween.kill()

	basket_sprite.position = basket_hidden_position
	trash_sprite.position = trash_hidden_position

	basket_sprite.visible = false
	trash_sprite.visible = false


# ============================================================
# HUD STATE
# ============================================================


func _update_hud() -> void:
	for meat_id: String in REQUIRED_MEATS:
		var label := order_value_labels.get(meat_id) as Label
		if label != null:
			label.text = "%d/%d" % [
				int(collected_amounts[meat_id]),
				int(required_amounts[meat_id]),
			]
	_set_mistake_markers(wasted_markers, wasted_good_meat)
	_set_mistake_markers(suspicion_markers, suspicious_basket_attempts)


func _set_mistake_markers(markers: Array[TextureRect], count: int) -> void:
	for index: int in range(markers.size()):
		var marker := markers[index]
		var should_show_mistake := index < count
		if should_show_mistake and marker.texture != YES_MISTAKE_TEXTURE:
			marker.texture = YES_MISTAKE_TEXTURE
			_pulse_mistake_marker(marker)
		elif not should_show_mistake:
			marker.texture = NO_MISTAKE_TEXTURE
			marker.scale = Vector2.ONE
			marker.modulate = Color.WHITE


func _pulse_mistake_marker(marker: TextureRect) -> void:
	marker.scale = Vector2(0.45, 0.45)
	marker.modulate = Color(1.35, 1.15, 1.05, 1.0)
	var tween := create_tween()
	tween.tween_property(marker, "scale", Vector2(1.38, 1.38), 0.12).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(marker, "modulate", Color.WHITE, 0.12)
	tween.tween_property(marker, "scale", Vector2(0.88, 0.88), 0.08)
	tween.tween_property(marker, "scale", Vector2.ONE, 0.08)


func _show_action_feedback(key: String, screen_position: Vector2) -> void:
	var texture := FEEDBACK_TEXTURES.get(key) as Texture2D
	if texture == null:
		return
	var popup := Sprite2D.new()
	popup.name = "%sFeedbackPopup" % key.capitalize().replace(" ", "")
	popup.texture = texture
	popup.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	popup.position = Vector2(
		clampf(screen_position.x, 180.0, SCREEN_SIZE.x - 180.0),
		clampf(screen_position.y - 55.0, 120.0, SCREEN_SIZE.y - 110.0)
	)
	popup.scale = FEEDBACK_SCALE * 0.80
	popup.z_index = 30
	ui_root.add_child(popup)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 38.0, 0.55)
	tween.tween_property(popup, "scale", FEEDBACK_SCALE, 0.12)
	tween.tween_property(popup, "modulate:a", 0.0, 0.25).set_delay(0.45)
	tween.finished.connect(popup.queue_free)


func _show_mistake_dialogue(kind: String) -> void:
	var count := wasted_good_meat if kind == "wasted" else suspicious_basket_attempts
	if count >= FAILURE_LIMIT:
		return
	if count == 4 and warning_level_shown < 4:
		warning_level_shown = 4
		_play_one_shot_sfx(SFX_WARNING, -4.0)
		_show_vendor_line(
			"One more mistake and I am stopping this order!",
			"super_angry",
			"warning"
		)
	elif count == 2 and not dialogue_seen.has("%s_two" % kind):
		dialogue_seen["%s_two" % kind] = true
		_show_vendor_line(
			"Be careful. Check the meat and the destination before letting go.",
			"angry",
			"feedback"
		)


# ============================================================
# ORDER, FAILURE, AND SUCCESS
# ============================================================

func _remaining_required(meat_id: String) -> int:
	return maxi(
		0,
		int(required_amounts[meat_id])
		- int(collected_amounts[meat_id])
	)


func _is_order_complete() -> bool:
	for meat_id in REQUIRED_MEATS:
		if _remaining_required(meat_id) > 0:
			return false

	return true


func _check_failure_conditions() -> void:
	if wasted_good_meat >= FAILURE_LIMIT:
		_start_failure("wasted")

	elif suspicious_basket_attempts >= FAILURE_LIMIT:
		_start_failure("suspicion")


func _start_failure(failure_type: String) -> void:
	if not gameplay_active:
		return

	gameplay_active = false
	dragged_piece = null

	_cancel_all_hand_attacks()
	_hide_drop_targets_immediately()
	_stop_audio()
	var fail_dialogue := "Enough! You kept putting unrequested meat in the basket. I cannot accept this order."
	var fail_reason := "You placed unrequested meat in the basket five times."
	if failure_type == "wasted":
		fail_dialogue = "Enough! You wasted too much usable meat. We cannot fill the order now."
		fail_reason = "You threw away five usable meat cuts."
	fail_screen.call(
		"start_fail_screen",
		fail_dialogue,
		fail_reason,
		0,
		false
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
	minigame_failed.emit()


func _start_success_ending() -> void:
	if not gameplay_active:
		return

	gameplay_active = false
	dragged_piece = null

	_cancel_all_hand_attacks()
	_hide_drop_targets_immediately()
	_stop_audio()
	order_complete_root.visible = true
	_play_one_shot_sfx(SFX_ORDER_COMPLETE, -3.0)
	await get_tree().create_timer(1.20).timeout
	order_complete_root.visible = false
	_play_one_shot_sfx(SFX_SUCCESS, -4.0)
	_show_vendor_line(
		"Order complete! You protected every cut we needed. Well done.",
		"happy",
		"success"
	)


func _show_vendor_line(text: String, expression: String, context: String) -> void:
	dialogue_context = context
	var auto_hide := -1.0
	if context in ["passive", "feedback", "warning"]:
		auto_hide = 2.8
	dialogue.say(text, expression, auto_hide, "vendor_snatch")


func _on_dialogue_started() -> void:
	dialogue_is_blocking = not dialogue_context in [
		"passive", "feedback", "warning"
	]


func _on_dialogue_finished() -> void:
	var context := dialogue_context
	dialogue_context = ""
	dialogue_is_blocking = false
	match context:
		"intro":
			_start_game_without_introduction()
		"success":
			if not result_emitted:
				result_emitted = true
				$CollectibleEnding.play()
		"fail":
			_on_fail_exit_requested()


func _setup_order_complete_overlay() -> void:
	order_complete_layer = CanvasLayer.new()
	order_complete_layer.name = "OrderCompleteLayer"
	order_complete_layer.layer = 150
	add_child(order_complete_layer)
	order_complete_root = Control.new()
	order_complete_root.name = "Root"
	order_complete_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	order_complete_layer.add_child(order_complete_root)
	var dim := ColorRect.new()
	dim.name = "DimBackground"
	dim.position = Vector2.ZERO
	dim.size = SCREEN_SIZE
	dim.color = Color(0.0, 0.0, 0.0, 0.76)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	order_complete_root.add_child(dim)
	var complete := Sprite2D.new()
	complete.name = "OrderComplete"
	complete.texture = ORDER_COMPLETE_TEXTURE
	complete.position = SCREEN_CENTER
	complete.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	complete.z_index = 1
	order_complete_root.add_child(complete)
	order_complete_root.visible = false


# ============================================================
# DISPLAY NAMES
# ============================================================

func _display_name(meat_id: String) -> String:
	match meat_id:
		"belly":
			return "Pork belly"

		"liver":
			return "Atay"

		"spleen":
			return "Lapay"

		"pork_chop":
			return "Pork chop"

		"pork_hock":
			return "Pork hock"

		"pork_ribs":
			return "Pork ribs"

		"pork_shoulder":
			return "Pork shoulder"

		"bone_cut":
			return "Bone"

		"fat_scraps":
			return "Fat scraps"

		"old_meat":
			return "Old meat"

		_:
			return meat_id.replace("_", " ").capitalize()


# ============================================================
# AUDIO
# ============================================================

func _setup_audio() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.stream = MUSIC
	music_player.volume_db = -14.0
	add_child(music_player)

	ambience_player = AudioStreamPlayer.new()
	ambience_player.stream = AMBIENCE
	ambience_player.volume_db = -20.0
	add_child(ambience_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.volume_db = -4.0
	add_child(sfx_player)


func _play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return

	sfx_player.stream = stream
	sfx_player.play()


func _play_one_shot_sfx(
	stream: AudioStream,
	volume_db: float = -4.0
) -> void:
	if stream == null:
		return

	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	player.play()

	player.finished.connect(
		func() -> void:
			if is_instance_valid(player):
				player.queue_free()
	)


func _stop_audio() -> void:
	music_player.stop()
	ambience_player.stop()
