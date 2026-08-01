extends "res://features/minigames/final_cooking/scripts/final_cooking_stage.gd"


# ============================================================
# BACKGROUND AND COOKWARE
# ============================================================

const BACKGROUND_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/backgrounds/bg_prep_station_top.png"
)

const CUTTING_BOARD_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/cookware/cutting/cutting_board.png"
)

const BOWL_EMPTY_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/cookware/cutting/bowl_empty.png"
)

const TRAY_EMPTY_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/cookware/cutting/tray_empty.png"
)

const NAVIGATION_ARROW_TEXTURE: Texture2D = preload(
	"res://features/minigames/snatch_battle/assets/ui/snatch_hand_attack_indicator.png"
)

const INSTRUCTION_PANEL_TEXTURE: Texture2D = preload(
	"res://features/minigames/export_templates/instruction_panel.png"
)

const DIALOGUE_SCENE: PackedScene = preload(
	"res://features/minigames/shared/dialogue/shared_dialogue.tscn"
)

const UI_FONT: Font = preload(
	"res://features/minigames/shared/fonts/VCR_OSD_MONO_1.001.ttf"
)

# ============================================================
# FULL UNCUT CONTAINERS
# ============================================================

const GARLIC_FULL_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/containers_full/garlic_uncut_bowl.png"
)

const ONION_FULL_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/containers_full/onion_uncut_bowl.png"
)

const GINGER_FULL_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/containers_full/ginger_uncut_bowl.png"
)

const GREEN_ONIONS_FULL_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/containers_full/green_onions_uncut_bowl.png"
)

const PORK_BELLY_FULL_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/containers_full/pork_belly_uncut_tray.png"
)

const LIVER_FULL_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/containers_full/liver_uncut_tray.png"
)

const LAPAY_FULL_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/containers_full/heart_uncut_tray.png"
)


# ============================================================
# COMPLETED CUT CONTAINERS
# ============================================================

const GARLIC_CUT_BOWL_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/containers_cut/garlic_cut_bowl.png"
)

const ONION_CUT_BOWL_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/containers_cut/onion_cut_bowl.png"
)

const GINGER_CUT_BOWL_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/containers_cut/ginger_cut_bowl.png"
)

const GREEN_ONIONS_CUT_BOWL_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/containers_cut/green_onions_cut_bowl.png"
)

const PORK_BELLY_CUT_TRAY_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/containers_cut/pork_belly_cut_tray.png"
)

const LIVER_CUT_TRAY_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/containers_cut/liver_cut_tray.png"
)

const LAPAY_CUT_TRAY_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/containers_cut/heart_cut_tray.png"
)


# ============================================================
# RAW INGREDIENTS
# ============================================================

const GARLIC_RAW_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/board/raw/garlic_uncut.png"
)

const ONION_RAW_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/board/raw/onion_uncut.png"
)

const GINGER_RAW_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/board/raw/ginger_uncut.png"
)

const GREEN_ONIONS_RAW_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/board/raw/green_onions_uncut.png"
)

const PORK_BELLY_RAW_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/board/raw/pork_belly_uncut.png"
)

const LIVER_RAW_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/board/raw/liver_uncut.png"
)

const LAPAY_RAW_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/board/raw/heart_uncut.png"
)


# ============================================================
# VEGETABLE CUT PILES
# ============================================================

const GARLIC_CUT_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/board/cut_piles/garlic_cut_pile.png"
)

const ONION_CUT_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/board/cut_piles/onion_cut_pile.png"
)

const GINGER_CUT_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/board/cut_piles/ginger_cut_pile.png"
)

const GREEN_ONIONS_CUT_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/board/cut_piles/green_onions_cut_pile.png"
)


# ============================================================
# MEAT PIECES
# ============================================================

const PORK_BELLY_PIECE_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/board/meat_pieces/pork_belly_piece.png"
)

const LIVER_PIECE_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/board/meat_pieces/liver_piece.png"
)

const LAPAY_PIECE_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/cutting/board/meat_pieces/heart_piece.png"
)


# ============================================================
# SCREEN AND PLACEMENT
# ============================================================

const SCREEN_CENTER := Vector2(576.0, 324.0)

const BOWL_BOTTOM_LEFT := Vector2(959.4, 267.9)
const TRAY_BOTTOM_LEFT := Vector2(777.1, 15.6)

const DEFAULT_RAW_TOP_LEFT := Vector2(181.8, 148.7)

const BOWL_SCALE := Vector2(1.0, 1.0)
const TRAY_SCALE := Vector2(1.2, 1.2)

const MOUSE_DRAG_SCALE := Vector2(0.4, 0.4)
const CUT_PIECE_SCALE := Vector2(1.3, 1.3)

const BOWL_ROTATION_DEGREES: float = 0.0
const TRAY_ROTATION_DEGREES: float = 35.2

const INSTRUCTION_PANEL_POSITION := Vector2(12.0, 12.0)
const INSTRUCTION_PANEL_SIZE := Vector2(293.0, 350.0)
const INSTRUCTION_TEXT_POSITION := Vector2(27.0, 22.0)
const INSTRUCTION_TEXT_SIZE := Vector2(239.0, 105.0)

# ============================================================
# COLLECTION AREA SETTINGS
# ============================================================

const BOWL_COLLECTION_RADIUS: float = 78.0
const BOWL_COLLECTION_OFFSET := Vector2(0.0, -6.0)

const TRAY_COLLECTION_SIZE := Vector2(235.0, 125.0)
const TRAY_COLLECTION_OFFSET := Vector2(0.0, 0.0)


# ============================================================
# Z INDEX
# ============================================================

const BACKGROUND_Z_INDEX: int = -10
const CUTTING_BOARD_Z_INDEX: int = 0

const CUT_RESULT_Z_INDEX: int = 3
const RAW_INGREDIENT_Z_INDEX: int = 4

const CONTAINER_Z_INDEX: int = 5
const CUT_GUIDE_Z_INDEX: int = 10
const BUTTON_Z_INDEX: int = 20

const DRAG_PREVIEW_Z_INDEX: int = 30
const DRAGGED_PIECE_Z_INDEX: int = 31
const UI_Z_INDEX: int = 50

# ============================================================
# ANIMATION
# ============================================================

const SLIDE_OUT_DURATION: float = 0.35
const SLIDE_IN_DURATION: float = 0.35
const INGREDIENT_CHANGE_DELAY: float = 0.5

const EMPTY_CONTAINER_POP_DURATION: float = 0.22

const CONTAINER_PULSE_SCALE: float = 1.10
const CONTAINER_PULSE_OUT_DURATION: float = 0.10
const CONTAINER_PULSE_RETURN_DURATION: float = 0.12

const OFFSCREEN_PADDING: float = 100.0
const NEXT_BUTTON_GAP: float = 12.0
const PREVIOUS_BUTTON_GAP: float = 12.0


# ============================================================
# CUTTING SETTINGS
# ============================================================

const GUIDE_WIDTH: float = 6.0
const GUIDE_START_TOLERANCE: float = 35.0
const GUIDE_HORIZONTAL_TOLERANCE: float = 45.0
const GUIDE_REQUIRED_COVERAGE: float = 0.65

const GUIDE_TOP_PADDING: float = 8.0
const GUIDE_BOTTOM_PADDING: float = 8.0

const VEGETABLE_MIN_SPAWN: int = 2
const VEGETABLE_MAX_SPAWN: int = 3

const MEAT_MIN_SPAWN: int = 3
const MEAT_MAX_SPAWN: int = 5

const CUT_PIECE_MIN_ROTATION: float = -22.0
const CUT_PIECE_MAX_ROTATION: float = 22.0

const BOARD_SPAWN_DISTANCE: float = 18.0
const BOARD_SPAWN_ATTEMPTS: int = 20

const ALPHA_THRESHOLD: float = 0.1

const GUIDE_COLOR := Color(0.82, 0.06, 0.04, 0.96)
const GUIDE_ACTIVE_COLOR := Color(1.0, 0.24, 0.16, 1.0)


enum ContainerType {
	BOWL,
	TRAY
}


enum IngredientType {
	VEGETABLE,
	MEAT
}


enum DragMode {
	NONE,
	FROM_CONTAINER,
	ON_BOARD,
	CUT_PIECE
}


# ============================================================
# MAIN NODES
# ============================================================

var background_sprite: Sprite2D
var cutting_board_sprite: Sprite2D

var ingredient_container_sprite: Sprite2D
var raw_ingredient_sprite: Sprite2D
var drag_preview_sprite: Sprite2D

var cut_result_container: Node2D
var cut_guide_container: Node2D

var previous_button: TextureButton
var next_button: TextureButton

var instruction_panel: TextureRect
var dialogue: SharedDialogue


# ============================================================
# COLLECTION DROP AREA
# ============================================================

var collection_zone_center := Vector2.ZERO
var collection_zone_size := Vector2.ZERO
var collection_zone_is_circle: bool = false


# ============================================================
# INGREDIENT DATA AND STATE
# ============================================================

var ingredient_data: Array[Dictionary] = []

var current_ingredient_index: int = 0
var selected_ingredient_index: int = 0
var displayed_collection_type: int = ContainerType.BOWL
var completed_ingredient_count: int = 0

var ingredient_is_on_board: bool = false
var ingredient_is_locked: bool = false
var ingredient_cut_complete: bool = false
var ingredient_transfer_complete: bool = false

var is_switching_ingredient: bool = false
var transfer_animation_running: bool = false
var stage_is_finished: bool = false
var stage_completion_emitted: bool = false

var bowl_target_position := Vector2.ZERO
var tray_target_position := Vector2.ZERO

var current_drag_mode: DragMode = DragMode.NONE

var board_drag_start_position := Vector2.ZERO
var board_drag_mouse_offset := Vector2.ZERO

var raw_ingredient_top_left := DEFAULT_RAW_TOP_LEFT


# ============================================================
# CUTTING STATE
# ============================================================

var raw_opaque_bounds := Rect2i()

var cut_boundaries: Array[float] = []
var cut_guides: Array[Line2D] = []

var current_cut_index: int = 0
var current_visible_right: float = 0.0

var is_swiping_cut: bool = false
var swipe_start_position := Vector2.ZERO
var swipe_min_y: float = 0.0
var swipe_max_y: float = 0.0

var spawned_cut_sprites: Array[Sprite2D] = []

var dragged_cut_piece: Sprite2D
var dragged_cut_piece_start_position := Vector2.ZERO
var dragged_cut_piece_mouse_offset := Vector2.ZERO
var dragged_cut_piece_original_z_index: int = CUT_RESULT_Z_INDEX

var random_number_generator := RandomNumberGenerator.new()


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	random_number_generator.randomize()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	SharedCursor.install()

	_create_ingredient_data()
	_create_layout()

	set_process_input(true)

	stage_started.emit()


# ============================================================
# INGREDIENT DATA
# ============================================================

func _create_ingredient_data() -> void:
	ingredient_data = [
		{
			"id": "garlic",
			"display_name": "Garlic",
			"full_texture": GARLIC_FULL_TEXTURE,
			"raw_texture": GARLIC_RAW_TEXTURE,
			"result_texture": GARLIC_CUT_TEXTURE,
			"cut_container_texture": GARLIC_CUT_BOWL_TEXTURE,
			"container_type": ContainerType.BOWL,
			"ingredient_type": IngredientType.VEGETABLE,
			"cut_count": 4
		},
		{
			"id": "onion",
			"display_name": "Onion",
			"full_texture": ONION_FULL_TEXTURE,
			"raw_texture": ONION_RAW_TEXTURE,
			"result_texture": ONION_CUT_TEXTURE,
			"cut_container_texture": ONION_CUT_BOWL_TEXTURE,
			"container_type": ContainerType.BOWL,
			"ingredient_type": IngredientType.VEGETABLE,
			"cut_count": 4
		},
		{
			"id": "ginger",
			"display_name": "Ginger",
			"full_texture": GINGER_FULL_TEXTURE,
			"raw_texture": GINGER_RAW_TEXTURE,
			"result_texture": GINGER_CUT_TEXTURE,
			"cut_container_texture": GINGER_CUT_BOWL_TEXTURE,
			"container_type": ContainerType.BOWL,
			"ingredient_type": IngredientType.VEGETABLE,
			"cut_count": 4
		},
		{
			"id": "green_onions",
			"display_name": "Green Onions",
			"full_texture": GREEN_ONIONS_FULL_TEXTURE,
			"raw_texture": GREEN_ONIONS_RAW_TEXTURE,
			"result_texture": GREEN_ONIONS_CUT_TEXTURE,
			"cut_container_texture": GREEN_ONIONS_CUT_BOWL_TEXTURE,
			"container_type": ContainerType.BOWL,
			"ingredient_type": IngredientType.VEGETABLE,
			"cut_count": 5
		},
		{
			"id": "pork_belly",
			"display_name": "Pork Belly",
			"full_texture": PORK_BELLY_FULL_TEXTURE,
			"raw_texture": PORK_BELLY_RAW_TEXTURE,
			"result_texture": PORK_BELLY_PIECE_TEXTURE,
			"cut_container_texture": PORK_BELLY_CUT_TRAY_TEXTURE,
			"container_type": ContainerType.TRAY,
			"ingredient_type": IngredientType.MEAT,
			"cut_count": 3
		},
		{
			"id": "liver",
			"display_name": "Liver",
			"full_texture": LIVER_FULL_TEXTURE,
			"raw_texture": LIVER_RAW_TEXTURE,
			"result_texture": LIVER_PIECE_TEXTURE,
			"cut_container_texture": LIVER_CUT_TRAY_TEXTURE,
			"container_type": ContainerType.TRAY,
			"ingredient_type": IngredientType.MEAT,
			"cut_count": 3
		},
		{
		"id": "lapay",
		"display_name": "Lapay",
			"full_texture": LAPAY_FULL_TEXTURE,
			"raw_texture": LAPAY_RAW_TEXTURE,
			"result_texture": LAPAY_PIECE_TEXTURE,
			"cut_container_texture": LAPAY_CUT_TRAY_TEXTURE,
			"container_type": ContainerType.TRAY,
			"ingredient_type": IngredientType.MEAT,
			"cut_count": 3
		}
	]


# ============================================================
# CREATE LAYOUT
# ============================================================

func _create_layout() -> void:
	background_sprite = _create_sprite(
		"Background",
		BACKGROUND_TEXTURE,
		SCREEN_CENTER,
		Vector2.ONE,
		0.0,
		BACKGROUND_Z_INDEX
	)

	cutting_board_sprite = _create_sprite(
		"CuttingBoard",
		CUTTING_BOARD_TEXTURE,
		Vector2(576.0, 320.0),
		Vector2.ONE,
		0.0,
		CUTTING_BOARD_Z_INDEX
	)

	bowl_target_position = _get_center_from_bottom_left(
		BOWL_EMPTY_TEXTURE,
		BOWL_BOTTOM_LEFT,
		deg_to_rad(BOWL_ROTATION_DEGREES),
		BOWL_SCALE
	)

	tray_target_position = _get_center_from_bottom_left(
		TRAY_EMPTY_TEXTURE,
		TRAY_BOTTOM_LEFT,
		deg_to_rad(TRAY_ROTATION_DEGREES),
		TRAY_SCALE
	)

	ingredient_container_sprite = Sprite2D.new()
	ingredient_container_sprite.name = "IngredientContainer"
	ingredient_container_sprite.centered = true
	ingredient_container_sprite.z_index = CONTAINER_Z_INDEX
	add_child(ingredient_container_sprite)

	cut_result_container = Node2D.new()
	cut_result_container.name = "CutResults"
	add_child(cut_result_container)

	raw_ingredient_sprite = Sprite2D.new()
	raw_ingredient_sprite.name = "RawIngredient"
	raw_ingredient_sprite.centered = true
	raw_ingredient_sprite.z_index = RAW_INGREDIENT_Z_INDEX
	raw_ingredient_sprite.visible = false
	add_child(raw_ingredient_sprite)

	drag_preview_sprite = Sprite2D.new()
	drag_preview_sprite.name = "DragPreview"
	drag_preview_sprite.centered = true
	drag_preview_sprite.z_index = DRAG_PREVIEW_Z_INDEX
	drag_preview_sprite.visible = false
	add_child(drag_preview_sprite)

	cut_guide_container = Node2D.new()
	cut_guide_container.name = "CutGuides"
	cut_guide_container.z_index = CUT_GUIDE_Z_INDEX
	add_child(cut_guide_container)

	_create_navigation_buttons()
	_create_instruction_panel()
	_create_dialogue()

	_apply_current_ingredient_immediately()
	_announce_current_request()


func _create_sprite(
	node_name: String,
	sprite_texture: Texture2D,
	sprite_position: Vector2,
	sprite_scale: Vector2,
	sprite_rotation: float,
	sprite_z_index: int
) -> Sprite2D:
	var sprite := Sprite2D.new()

	sprite.name = node_name
	sprite.texture = sprite_texture
	sprite.position = sprite_position
	sprite.scale = sprite_scale
	sprite.rotation = sprite_rotation
	sprite.centered = true
	sprite.z_index = sprite_z_index

	add_child(sprite)

	return sprite


# ============================================================
# COLLECTION DROP AREA
# ============================================================


func _update_collection_zone() -> void:
	var container_type: int = displayed_collection_type

	if container_type == ContainerType.BOWL:
		collection_zone_is_circle = true
		collection_zone_center = (
			bowl_target_position
			+ BOWL_COLLECTION_OFFSET
		)

		var diameter: float = BOWL_COLLECTION_RADIUS * 2.0
		collection_zone_size = Vector2(diameter, diameter)
	else:
		collection_zone_is_circle = false
		collection_zone_center = (
			tray_target_position
			+ TRAY_COLLECTION_OFFSET
		)
		collection_zone_size = TRAY_COLLECTION_SIZE

func _is_point_in_collection_zone(
	point: Vector2
) -> bool:
	if collection_zone_is_circle:
		return (
			point.distance_to(collection_zone_center)
			<= BOWL_COLLECTION_RADIUS
		)

	var zone_rect := Rect2(
		collection_zone_center
			- collection_zone_size * 0.5,
		collection_zone_size
	)

	return zone_rect.has_point(point)


func _create_instruction_panel() -> void:
	instruction_panel = TextureRect.new()
	instruction_panel.name = "InstructionPanel"
	instruction_panel.texture = INSTRUCTION_PANEL_TEXTURE
	instruction_panel.position = INSTRUCTION_PANEL_POSITION
	instruction_panel.size = INSTRUCTION_PANEL_SIZE
	instruction_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	instruction_panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	instruction_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	instruction_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	instruction_panel.z_index = UI_Z_INDEX
	add_child(instruction_panel)

	var instructions := Label.new()
	instructions.name = "InstructionText"
	instructions.text = (
		"CHOOSE LOLA'S INGREDIENT.\n"
		+ "CUT THE RED LINES.\n"
		+ "PUT AWAY EVERY PIECE."
	)
	instructions.position = INSTRUCTION_TEXT_POSITION
	instructions.size = INSTRUCTION_TEXT_SIZE
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	instructions.add_theme_font_override("font", UI_FONT)
	instructions.add_theme_font_size_override("font_size", 15)
	instructions.add_theme_color_override("font_color", Color(1.0, 0.91, 0.68))
	instructions.add_theme_color_override("font_shadow_color", Color(0.08, 0.03, 0.01, 1.0))
	instructions.add_theme_constant_override("shadow_offset_x", 1)
	instructions.add_theme_constant_override("shadow_offset_y", 1)
	instructions.add_theme_constant_override("line_spacing", 5)
	instruction_panel.add_child(instructions)

func _create_dialogue() -> void:
	dialogue = DIALOGUE_SCENE.instantiate() as SharedDialogue
	dialogue.name = "SharedDialogue"
	dialogue.accept_mouse_click = false
	dialogue.accept_ui_accept = false
	add_child(dialogue)
	dialogue.set_character("lola", "neutral")


func _say_lola(
	text: String,
	expression: String = "neutral",
	auto_hide: float = 3.2
) -> void:
	if dialogue == null:
		return
	dialogue.say(text, expression, auto_hide, "lola")


func _announce_current_request() -> void:
	var requested := _get_current_ingredient()
	_say_lola(
		"Apo, let us prepare the %s next. Place it on the board when you find it."
		% str(requested["display_name"]),
		"neutral",
		4.0
	)


# ============================================================
# INGREDIENT / CONTAINER NAVIGATION
# ============================================================

func _create_navigation_buttons() -> void:
	previous_button = _create_navigation_button(
		"PreviousSelectionButton",
		"←",
		_on_previous_button_pressed
	)
	next_button = _create_navigation_button(
		"NextSelectionButton",
		"→",
		_on_next_button_pressed
	)


func _create_navigation_button(
	node_name: String,
	_button_text: String,
	pressed_callback: Callable
) -> TextureButton:
	var button := TextureButton.new()
	button.name = node_name
	button.texture_normal = NAVIGATION_ARROW_TEXTURE
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.flip_h = node_name == "PreviousSelectionButton"
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.size = Vector2(48.0, 48.0)
	button.custom_minimum_size = button.size
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.z_index = BUTTON_Z_INDEX
	button.pressed.connect(pressed_callback)
	add_child(button)
	return button


func _update_navigation_button_positions() -> void:
	if previous_button == null or next_button == null:
		return
	if ingredient_container_sprite == null or ingredient_container_sprite.texture == null:
		return

	var bounds := _get_sprite_bounds(ingredient_container_sprite)
	var button_y := bounds.position.y + bounds.size.y * 0.5 - previous_button.size.y * 0.5
	previous_button.position = Vector2(
		bounds.position.x - previous_button.size.x - PREVIOUS_BUTTON_GAP,
		button_y
	)
	next_button.position = Vector2(
		bounds.end.x + NEXT_BUTTON_GAP,
		button_y
	)


func _set_navigation_enabled(enabled: bool) -> void:
	previous_button.visible = enabled
	next_button.visible = enabled
	previous_button.disabled = not enabled
	next_button.disabled = not enabled


func _can_change_selection() -> bool:
	return (
		not stage_is_finished
		and not is_switching_ingredient
		and not transfer_animation_running
		and current_drag_mode == DragMode.NONE
		and not is_swiping_cut
	)


func _on_previous_button_pressed() -> void:
	_change_selection(-1)


func _on_next_button_pressed() -> void:
	_change_selection(1)


func _change_selection(direction: int) -> void:
	if not _can_change_selection():
		return
	play_cooking_sfx("ui_navigate", -8.0, 1.0 + direction * 0.04)

	if ingredient_is_on_board:
		displayed_collection_type = (
			ContainerType.TRAY
			if displayed_collection_type == ContainerType.BOWL
			else ContainerType.BOWL
		)
	else:
		selected_ingredient_index = wrapi(
			selected_ingredient_index + direction,
			0,
			ingredient_data.size()
		)

	_refresh_displayed_container(true)


# ============================================================
# APPLY CURRENT INGREDIENT
# ============================================================

func _apply_current_ingredient_immediately() -> void:
	_clear_cutting_state()

	selected_ingredient_index = current_ingredient_index
	displayed_collection_type = int(
		_get_current_ingredient()["container_type"]
	)

	raw_ingredient_sprite.visible = false
	raw_ingredient_sprite.texture = null
	raw_ingredient_sprite.region_enabled = false

	drag_preview_sprite.visible = false
	drag_preview_sprite.texture = null

	ingredient_is_on_board = false
	ingredient_is_locked = false
	ingredient_cut_complete = false
	ingredient_transfer_complete = false

	current_drag_mode = DragMode.NONE
	raw_ingredient_top_left = DEFAULT_RAW_TOP_LEFT

	_refresh_displayed_container(false)
	_set_navigation_enabled(true)


func _refresh_displayed_container(with_pop: bool) -> void:
	var texture: Texture2D
	var container_type: int

	if ingredient_is_on_board:
		container_type = displayed_collection_type
		texture = (
			BOWL_EMPTY_TEXTURE
			if container_type == ContainerType.BOWL
			else TRAY_EMPTY_TEXTURE
		)
	else:
		var selected := ingredient_data[selected_ingredient_index]
		container_type = int(selected["container_type"])
		if selected_ingredient_index < current_ingredient_index:
			texture = selected["cut_container_texture"] as Texture2D
		else:
			texture = selected["full_texture"] as Texture2D

	ingredient_container_sprite.texture = texture
	ingredient_container_sprite.position = (
		bowl_target_position
		if container_type == ContainerType.BOWL
		else tray_target_position
	)
	ingredient_container_sprite.scale = (
		BOWL_SCALE
		if container_type == ContainerType.BOWL
		else TRAY_SCALE
	)
	ingredient_container_sprite.rotation_degrees = (
		BOWL_ROTATION_DEGREES
		if container_type == ContainerType.BOWL
		else TRAY_ROTATION_DEGREES
	)
	ingredient_container_sprite.visible = true

	if with_pop:
		var normal_scale := ingredient_container_sprite.scale
		ingredient_container_sprite.scale = normal_scale * 0.86
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(
			ingredient_container_sprite,
			"scale",
			normal_scale,
			0.16
		)

	if ingredient_is_on_board:
		_update_collection_zone()

	_update_navigation_button_positions()


# ============================================================
# INPUT
# ============================================================

func _input(event: InputEvent) -> void:
	# Space must never advance this stage.
	if event is InputEventKey:
		var key_event := event as InputEventKey

		if key_event.keycode == KEY_SPACE:
			get_viewport().set_input_as_handled()
			return

	if stage_is_finished:
		return

	if is_switching_ingredient:
		return

	if transfer_animation_running:
		return

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton

		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return

		if mouse_button.pressed:
			_handle_mouse_pressed(mouse_button.position)
		else:
			_handle_mouse_released(mouse_button.position)

	elif event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		_handle_mouse_motion(mouse_motion.position)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey

		if key_event.keycode == KEY_SPACE:
			get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()


func _handle_mouse_pressed(mouse_position: Vector2) -> void:
	if current_drag_mode != DragMode.NONE:
		return

	if ingredient_cut_complete and not ingredient_transfer_complete:
		var selected_piece: Sprite2D = (
			_find_topmost_cut_piece_at(mouse_position)
		)

		if selected_piece != null:
			_start_cut_piece_drag(
				selected_piece,
				mouse_position
			)

		return

	if ingredient_is_on_board and not ingredient_cut_complete:
		if _try_start_cut_swipe(mouse_position):
			return

		if (
			not ingredient_is_locked
			and _is_point_on_sprite_opaque(
				raw_ingredient_sprite,
				mouse_position
			)
		):
			_start_board_drag(mouse_position)

		return

	if ingredient_is_on_board:
		return

	if _is_point_on_sprite_opaque(
		ingredient_container_sprite,
		mouse_position
	):
		if selected_ingredient_index < current_ingredient_index:
			var requested := _get_current_ingredient()
			_say_lola(
				"We finished that one already, apo. Let us look for the %s."
				% str(requested["display_name"]),
				"neutral"
			)
			return
		_start_container_drag(mouse_position)


func _handle_mouse_motion(mouse_position: Vector2) -> void:
	if is_swiping_cut:
		swipe_min_y = minf(
			swipe_min_y,
			mouse_position.y
		)

		swipe_max_y = maxf(
			swipe_max_y,
			mouse_position.y
		)

		return

	match current_drag_mode:
		DragMode.FROM_CONTAINER:
			drag_preview_sprite.position = mouse_position

		DragMode.ON_BOARD:
			raw_ingredient_sprite.position = (
				mouse_position
				+ board_drag_mouse_offset
			)

			_update_raw_top_left_from_sprite()
			_update_cut_guide_positions()

		DragMode.CUT_PIECE:
			if dragged_cut_piece != null:
				dragged_cut_piece.position = (
					mouse_position
					+ dragged_cut_piece_mouse_offset
				)

		DragMode.NONE:
			pass


func _handle_mouse_released(mouse_position: Vector2) -> void:
	if is_swiping_cut:
		_finish_cut_swipe(mouse_position)
		return

	match current_drag_mode:
		DragMode.FROM_CONTAINER:
			_finish_container_drag(mouse_position)

		DragMode.ON_BOARD:
			_finish_board_drag()

		DragMode.CUT_PIECE:
			_finish_cut_piece_drag(mouse_position)

		DragMode.NONE:
			pass


# ============================================================
# CONTAINER TO BOARD
# ============================================================

func _start_container_drag(
	mouse_position: Vector2
) -> void:
	play_cooking_sfx("item_pickup", -7.0)
	var ingredient: Dictionary = ingredient_data[selected_ingredient_index]

	var full_texture: Texture2D = (
		ingredient["full_texture"] as Texture2D
	)

	var container_type: int = int(
		ingredient["container_type"]
	)

	drag_preview_sprite.texture = full_texture
	drag_preview_sprite.position = mouse_position
	drag_preview_sprite.scale = MOUSE_DRAG_SCALE
	drag_preview_sprite.visible = true

	if container_type == ContainerType.TRAY:
		drag_preview_sprite.rotation_degrees = (
			TRAY_ROTATION_DEGREES
		)
	else:
		drag_preview_sprite.rotation_degrees = (
			BOWL_ROTATION_DEGREES
		)

	ingredient_container_sprite.visible = false
	_set_navigation_enabled(false)
	SharedCursor.set_dragging()
	current_drag_mode = DragMode.FROM_CONTAINER


func _finish_container_drag(
	mouse_position: Vector2
) -> void:
	var dropped_on_board: bool = (
		_is_point_on_sprite_opaque(
			cutting_board_sprite,
			mouse_position
		)
	)

	drag_preview_sprite.visible = false
	drag_preview_sprite.texture = null
	drag_preview_sprite.rotation = 0.0
	drag_preview_sprite.scale = MOUSE_DRAG_SCALE

	current_drag_mode = DragMode.NONE
	SharedCursor.set_grab()

	if dropped_on_board:
		if selected_ingredient_index != current_ingredient_index:
			_restore_full_container()
			_set_navigation_enabled(true)
			var requested := _get_current_ingredient()
			_say_lola(
				"Not that one yet, apo. Lola needs the %s first."
				% str(requested["display_name"]),
				"concerned"
			)
			return

		await _place_current_ingredient_on_board()
	else:
		_restore_full_container()
		_set_navigation_enabled(true)


func _restore_full_container() -> void:
	_refresh_displayed_container(false)


func _place_current_ingredient_on_board() -> void:
	var ingredient: Dictionary = _get_current_ingredient()

	var raw_texture: Texture2D = (
		ingredient["raw_texture"] as Texture2D
	)

	raw_ingredient_top_left = DEFAULT_RAW_TOP_LEFT

	raw_ingredient_sprite.texture = raw_texture
	raw_ingredient_sprite.scale = Vector2.ONE
	raw_ingredient_sprite.rotation = 0.0
	raw_ingredient_sprite.region_enabled = false

	raw_ingredient_sprite.position = (
		raw_ingredient_top_left
		+ raw_texture.get_size() * 0.5
	)

	raw_ingredient_sprite.visible = true

	ingredient_is_on_board = true
	ingredient_is_locked = false
	ingredient_cut_complete = false
	ingredient_transfer_complete = false

	_setup_cutting_for_current_ingredient()

	await _show_empty_container()
	_set_navigation_enabled(true)
	_say_lola(
		"That is the one, apo. Follow the red lines carefully, then gather the pieces.",
		"happy"
	)


func _show_empty_container() -> void:
	var ingredient: Dictionary = _get_current_ingredient()
	displayed_collection_type = int(ingredient["container_type"])
	_refresh_displayed_container(true)
	await get_tree().create_timer(EMPTY_CONTAINER_POP_DURATION).timeout


# ============================================================
# CUTTING SETUP
# ============================================================

func _setup_cutting_for_current_ingredient() -> void:
	_clear_cut_guides()

	raw_opaque_bounds = _get_texture_opaque_bounds(
		raw_ingredient_sprite.texture
	)

	if raw_opaque_bounds.size == Vector2i.ZERO:
		return

	var ingredient: Dictionary = _get_current_ingredient()
	var cut_count: int = int(
		ingredient["cut_count"]
	)

	var opaque_left: float = float(
		raw_opaque_bounds.position.x
	)

	var opaque_right: float = float(
		raw_opaque_bounds.position.x
		+ raw_opaque_bounds.size.x
	)

	current_visible_right = opaque_right
	current_cut_index = 0
	cut_boundaries.clear()

	for index: int in range(cut_count):
		var fraction: float = (
			float(cut_count - index)
			/ float(cut_count + 1)
		)

		var boundary: float = lerpf(
			opaque_left,
			opaque_right,
			fraction
		)

		cut_boundaries.append(boundary)

	_create_cut_guides()


func _create_cut_guides() -> void:
	_clear_cut_guides()

	for boundary: float in cut_boundaries:
		var guide := Line2D.new()

		guide.name = "CutGuide"
		guide.width = GUIDE_WIDTH
		guide.default_color = GUIDE_COLOR
		guide.antialiased = false
		guide.z_index = CUT_GUIDE_Z_INDEX

		cut_guide_container.add_child(guide)
		cut_guides.append(guide)

	_update_cut_guide_positions()
	_update_cut_guide_visibility()


func _update_cut_guide_positions() -> void:
	if raw_ingredient_sprite.texture == null:
		return

	if raw_opaque_bounds.size == Vector2i.ZERO:
		return

	var texture_size: Vector2 = (
		raw_ingredient_sprite.texture.get_size()
	)

	var half_size: Vector2 = texture_size * 0.5

	var top_y: float = (
		float(raw_opaque_bounds.position.y)
		+ GUIDE_TOP_PADDING
	)

	var bottom_y: float = (
		float(
			raw_opaque_bounds.position.y
			+ raw_opaque_bounds.size.y
		)
		- GUIDE_BOTTOM_PADDING
	)

	for index: int in range(cut_guides.size()):
		var boundary: float = cut_boundaries[index]

		var start_position: Vector2 = (
			raw_ingredient_sprite.to_global(
				Vector2(boundary, top_y) - half_size
			)
		)

		var end_position: Vector2 = (
			raw_ingredient_sprite.to_global(
				Vector2(boundary, bottom_y) - half_size
			)
		)

		cut_guides[index].points = PackedVector2Array([
			start_position,
			end_position
		])


func _update_cut_guide_visibility() -> void:
	for index: int in range(cut_guides.size()):
		var is_current: bool = (
			index == current_cut_index
		)

		cut_guides[index].visible = (
			is_current
			and not ingredient_cut_complete
		)

		if is_current:
			cut_guides[index].default_color = (
				GUIDE_ACTIVE_COLOR
			)
		else:
			cut_guides[index].default_color = GUIDE_COLOR


# ============================================================
# CUT SWIPE
# ============================================================

func _try_start_cut_swipe(
	mouse_position: Vector2
) -> bool:
	if ingredient_cut_complete:
		return false

	if current_cut_index >= cut_guides.size():
		return false

	var guide: Line2D = cut_guides[current_cut_index]

	if not guide.visible:
		return false

	if guide.points.size() < 2:
		return false

	var guide_start: Vector2 = guide.points[0]
	var guide_end: Vector2 = guide.points[1]

	var distance: float = _distance_point_to_segment(
		mouse_position,
		guide_start,
		guide_end
	)

	if distance > GUIDE_START_TOLERANCE:
		return false

	is_swiping_cut = true
	swipe_start_position = mouse_position
	swipe_min_y = mouse_position.y
	swipe_max_y = mouse_position.y

	return true


func _finish_cut_swipe(
	mouse_position: Vector2
) -> void:
	if not is_swiping_cut:
		return

	is_swiping_cut = false

	swipe_min_y = minf(
		swipe_min_y,
		mouse_position.y
	)

	swipe_max_y = maxf(
		swipe_max_y,
		mouse_position.y
	)

	if current_cut_index >= cut_guides.size():
		return

	var guide: Line2D = cut_guides[current_cut_index]

	if guide.points.size() < 2:
		return

	var guide_start: Vector2 = guide.points[0]
	var guide_end: Vector2 = guide.points[1]

	var start_error: float = absf(
		swipe_start_position.x
		- guide_start.x
	)

	var end_error: float = absf(
		mouse_position.x
		- guide_start.x
	)

	var horizontal_error: float = maxf(
		start_error,
		end_error
	)

	var guide_height: float = absf(
		guide_end.y - guide_start.y
	)

	var swipe_height: float = (
		swipe_max_y - swipe_min_y
	)

	var coverage: float = 0.0

	if guide_height > 0.0:
		coverage = swipe_height / guide_height

	if (
		horizontal_error <= GUIDE_HORIZONTAL_TOLERANCE
		and coverage >= GUIDE_REQUIRED_COVERAGE
	):
		_complete_current_cut()


# ============================================================
# COMPLETE CUT
# ============================================================

func _complete_current_cut() -> void:
	if current_cut_index >= cut_boundaries.size():
		return
	play_cooking_sfx("cut_slice", -3.5, randf_range(0.94, 1.06))

	ingredient_is_locked = true

	var new_right: float = (
		cut_boundaries[current_cut_index]
	)

	var old_right: float = current_visible_right

	var removed_rect: Rect2 = (
		_get_global_texture_section_rect(
			new_right,
			old_right
		)
	)

	_spawn_cut_results(removed_rect)

	current_visible_right = new_right

	_crop_raw_ingredient(new_right)

	current_cut_index += 1

	if current_cut_index >= cut_boundaries.size():
		_finish_cutting()
	else:
		_update_cut_guide_visibility()


func _finish_cutting() -> void:
	var opaque_left: float = float(
		raw_opaque_bounds.position.x
	)

	var remaining_rect: Rect2 = (
		_get_global_texture_section_rect(
			opaque_left,
			current_visible_right
		)
	)

	_spawn_cut_results(remaining_rect)

	raw_ingredient_sprite.visible = false
	raw_ingredient_sprite.region_enabled = false

	ingredient_cut_complete = true
	ingredient_transfer_complete = false

	_clear_cut_guides()

	_say_lola(
		"Ay, nicely cut! Now place the pieces in the right bowl or tray.",
		"neutral",
		4.0
	)


# ============================================================
# RAW INGREDIENT CROPPING
# ============================================================

func _crop_raw_ingredient(
	new_right: float
) -> void:
	if raw_ingredient_sprite.texture == null:
		return

	var texture_size: Vector2 = (
		raw_ingredient_sprite.texture.get_size()
	)

	var crop_width: float = clampf(
		new_right,
		1.0,
		texture_size.x
	)

	raw_ingredient_sprite.region_enabled = true
	raw_ingredient_sprite.region_rect = Rect2(
		0.0,
		0.0,
		crop_width,
		texture_size.y
	)

	raw_ingredient_sprite.position = (
		raw_ingredient_top_left
		+ Vector2(
			crop_width * 0.5,
			texture_size.y * 0.5
		)
	)


func _get_global_texture_section_rect(
	left_x: float,
	right_x: float
) -> Rect2:
	var top_y: float = float(
		raw_opaque_bounds.position.y
	)

	var bottom_y: float = float(
		raw_opaque_bounds.position.y
		+ raw_opaque_bounds.size.y
	)

	return Rect2(
		raw_ingredient_top_left
			+ Vector2(left_x, top_y),

		Vector2(
			right_x - left_x,
			bottom_y - top_y
		)
	)


# ============================================================
# SPAWN CUT RESULTS ON BOARD
# ============================================================

func _spawn_cut_results(
	spawn_rect: Rect2
) -> void:
	var ingredient: Dictionary = _get_current_ingredient()

	var texture: Texture2D = (
		ingredient["result_texture"] as Texture2D
	)

	var ingredient_type: int = int(
		ingredient["ingredient_type"]
	)

	var spawn_count: int = 0

	if ingredient_type == IngredientType.MEAT:
		spawn_count = random_number_generator.randi_range(
			MEAT_MIN_SPAWN,
			MEAT_MAX_SPAWN
		)
	else:
		spawn_count = random_number_generator.randi_range(
			VEGETABLE_MIN_SPAWN,
			VEGETABLE_MAX_SPAWN
		)

	var positions_for_cut: Array[Vector2] = []

	for index: int in range(spawn_count):
		var piece := Sprite2D.new()

		piece.name = "CutPiece_%d_%d" % [
			current_cut_index,
			index
		]

		piece.texture = texture
		piece.centered = true
		piece.scale = CUT_PIECE_SCALE

		piece.rotation_degrees = (
			random_number_generator.randf_range(
				CUT_PIECE_MIN_ROTATION,
				CUT_PIECE_MAX_ROTATION
			)
		)

		piece.position = _find_board_spawn_position(
			spawn_rect,
			positions_for_cut
		)

		positions_for_cut.append(piece.position)

		piece.z_index = CUT_RESULT_Z_INDEX

		cut_result_container.add_child(piece)
		spawned_cut_sprites.append(piece)


func _find_board_spawn_position(
	spawn_rect: Rect2,
	existing_positions: Array[Vector2]
) -> Vector2:
	var selected_position: Vector2 = (
		spawn_rect.get_center()
	)

	for attempt: int in range(BOARD_SPAWN_ATTEMPTS):
		var candidate := Vector2(
			random_number_generator.randf_range(
				spawn_rect.position.x,
				spawn_rect.end.x
			),
			random_number_generator.randf_range(
				spawn_rect.position.y,
				spawn_rect.end.y
			)
		)

		var far_enough: bool = true

		for existing_position: Vector2 in existing_positions:
			if (
				candidate.distance_to(existing_position)
				< BOARD_SPAWN_DISTANCE
			):
				far_enough = false
				break

		selected_position = candidate

		if far_enough:
			break

	return selected_position


# ============================================================
# CUT PIECE DRAGGING
# ============================================================

func _find_topmost_cut_piece_at(
	mouse_position: Vector2
) -> Sprite2D:
	for index: int in range(
		spawned_cut_sprites.size() - 1,
		-1,
		-1
	):
		var piece: Sprite2D = spawned_cut_sprites[index]

		if not is_instance_valid(piece):
			continue

		if not piece.visible:
			continue

		if _is_point_on_sprite_opaque(
			piece,
			mouse_position
		):
			return piece

	return null


func _start_cut_piece_drag(
	piece: Sprite2D,
	mouse_position: Vector2
) -> void:
	play_cooking_sfx("item_pickup", -9.0, 1.08)
	current_drag_mode = DragMode.CUT_PIECE

	dragged_cut_piece = piece
	dragged_cut_piece_start_position = piece.position

	dragged_cut_piece_mouse_offset = (
		piece.position - mouse_position
	)

	dragged_cut_piece_original_z_index = piece.z_index
	piece.z_index = DRAGGED_PIECE_Z_INDEX
	SharedCursor.set_dragging()


func _finish_cut_piece_drag(
	mouse_position: Vector2
) -> void:
	if dragged_cut_piece == null:
		current_drag_mode = DragMode.NONE
		return

	var piece: Sprite2D = dragged_cut_piece

	dragged_cut_piece = null
	current_drag_mode = DragMode.NONE
	SharedCursor.set_grab()

	var required_container_type := int(
		_get_current_ingredient()["container_type"]
	)
	var dropped_in_displayed_container := _is_point_in_collection_zone(
		mouse_position
	)
	if (
		dropped_in_displayed_container
		and displayed_collection_type != required_container_type
	):
		play_cooking_sfx("wrong", -5.0)
		piece.position = dragged_cut_piece_start_position
		piece.z_index = dragged_cut_piece_original_z_index
		_say_lola(
			"Those go in the %s, apo. We will keep everything neat."
			% (
				"bowl"
				if required_container_type == ContainerType.BOWL
				else "tray"
			),
			"concerned"
		)
		return

	if dropped_in_displayed_container:
		await _accept_cut_piece(piece)
	else:
		piece.position = dragged_cut_piece_start_position
		piece.z_index = dragged_cut_piece_original_z_index


func _accept_cut_piece(
	piece: Sprite2D
) -> void:
	play_cooking_sfx("ingredient_drop", -7.0, randf_range(0.96, 1.05))
	transfer_animation_running = true

	spawned_cut_sprites.erase(piece)

	if is_instance_valid(piece):
		piece.visible = false
		piece.queue_free()

	await _pulse_container()

	if spawned_cut_sprites.is_empty():
		await _finish_current_ingredient()

	transfer_animation_running = false


# ============================================================
# CONTAINER PULSE
# ============================================================

func _pulse_container() -> void:
	var ingredient: Dictionary = _get_current_ingredient()

	var container_type: int = int(
		ingredient["container_type"]
	)

	var normal_scale := BOWL_SCALE

	if container_type == ContainerType.TRAY:
		normal_scale = TRAY_SCALE

	ingredient_container_sprite.scale = normal_scale

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		ingredient_container_sprite,
		"scale",
		normal_scale * CONTAINER_PULSE_SCALE,
		CONTAINER_PULSE_OUT_DURATION
	)

	tween.tween_property(
		ingredient_container_sprite,
		"scale",
		normal_scale,
		CONTAINER_PULSE_RETURN_DURATION
	)

	await tween.finished


# ============================================================
# FINISH CURRENT INGREDIENT
# ============================================================

func _finish_current_ingredient() -> void:
	play_cooking_sfx("ingredient_ready", -4.0)
	var ingredient: Dictionary = _get_current_ingredient()
	ingredient_container_sprite.texture = (
		ingredient["cut_container_texture"] as Texture2D
	)

	ingredient_transfer_complete = true
	ingredient_is_on_board = false

	completed_ingredient_count += 1
	_set_navigation_enabled(false)

	await _pulse_container()

	if completed_ingredient_count >= ingredient_data.size():
		stage_is_finished = true
		_say_lola(
			"Very good, apo. Everything is ready. Now let us make the broth.",
			"happy",
			2.2
		)
		await get_tree().create_timer(1.35).timeout
		_finish_stage_permanently()
		return

	_say_lola(
		"Well done, apo. That makes %d of %d ready. Let us see what comes next."
		% [completed_ingredient_count, ingredient_data.size()],
		"happy",
		1.8
	)
	await get_tree().create_timer(0.85).timeout
	await _show_next_ingredient()


# ============================================================
# NEXT INGREDIENT
# ============================================================

func _show_next_ingredient() -> void:
	if not ingredient_transfer_complete:
		return

	if completed_ingredient_count <= current_ingredient_index:
		return

	if current_ingredient_index >= ingredient_data.size() - 1:
		return

	is_switching_ingredient = true
	_set_navigation_enabled(false)

	await _slide_current_container_out()

	await get_tree().create_timer(
		INGREDIENT_CHANGE_DELAY
	).timeout

	current_ingredient_index += 1
	selected_ingredient_index = current_ingredient_index

	_clear_cutting_state()

	_prepare_next_container_offscreen()

	await _slide_current_container_in()

	ingredient_is_on_board = false
	ingredient_is_locked = false
	ingredient_cut_complete = false
	ingredient_transfer_complete = false

	is_switching_ingredient = false
	_set_navigation_enabled(true)
	_update_navigation_button_positions()
	_announce_current_request()


func _slide_current_container_out() -> void:
	var half_height: float = _get_sprite_half_height(
		ingredient_container_sprite
	)

	var target_position := Vector2(
		ingredient_container_sprite.position.x,
		-half_height - OFFSCREEN_PADDING
	)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(
		ingredient_container_sprite,
		"position",
		target_position,
		SLIDE_OUT_DURATION
	)

	await tween.finished


func _prepare_next_container_offscreen() -> void:
	var ingredient: Dictionary = _get_current_ingredient()

	var full_texture: Texture2D = (
		ingredient["full_texture"] as Texture2D
	)

	var container_type: int = int(
		ingredient["container_type"]
	)

	ingredient_container_sprite.texture = full_texture

	var target_position: Vector2 = (
		_get_current_target_position()
	)

	if container_type == ContainerType.BOWL:
		ingredient_container_sprite.scale = BOWL_SCALE
		ingredient_container_sprite.rotation_degrees = (
			BOWL_ROTATION_DEGREES
		)
	else:
		ingredient_container_sprite.scale = TRAY_SCALE
		ingredient_container_sprite.rotation_degrees = (
			TRAY_ROTATION_DEGREES
		)

	var viewport_width: float = (
		get_viewport_rect().size.x
	)

	ingredient_container_sprite.position = Vector2(
		viewport_width
			+ _get_sprite_half_width(
				ingredient_container_sprite
			)
			+ OFFSCREEN_PADDING,
		target_position.y
	)

	ingredient_container_sprite.visible = true


func _slide_current_container_in() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		ingredient_container_sprite,
		"position",
		_get_current_target_position(),
		SLIDE_IN_DURATION
	)

	await tween.finished


# ============================================================
# FINAL STAGE COMPLETION
# ============================================================

func _finish_stage_permanently() -> void:
	if not stage_is_finished:
		return

	if completed_ingredient_count < ingredient_data.size():
		return

	if stage_completion_emitted:
		return

	stage_completion_emitted = true

	_set_navigation_enabled(false)

	set_process_input(false)
	complete_stage()


# ============================================================
# MOVE RAW INGREDIENT BEFORE FIRST CUT
# ============================================================

func _start_board_drag(
	mouse_position: Vector2
) -> void:
	if ingredient_is_locked:
		return

	current_drag_mode = DragMode.ON_BOARD

	board_drag_start_position = raw_ingredient_sprite.position

	board_drag_mouse_offset = (
		raw_ingredient_sprite.position
		- mouse_position
	)

	raw_ingredient_sprite.z_index = DRAG_PREVIEW_Z_INDEX


func _finish_board_drag() -> void:
	current_drag_mode = DragMode.NONE
	raw_ingredient_sprite.z_index = RAW_INGREDIENT_Z_INDEX

	if not _is_raw_ingredient_inside_board():
		raw_ingredient_sprite.position = (
			board_drag_start_position
		)

	_update_raw_top_left_from_sprite()
	_update_cut_guide_positions()


func _update_raw_top_left_from_sprite() -> void:
	if raw_ingredient_sprite.texture == null:
		return

	var texture_size: Vector2 = (
		raw_ingredient_sprite.texture.get_size()
	)

	raw_ingredient_top_left = (
		raw_ingredient_sprite.position
		- texture_size * 0.5
	)


# ============================================================
# BOARD CONTAINMENT
# ============================================================

func _is_raw_ingredient_inside_board() -> bool:
	if raw_ingredient_sprite.texture == null:
		return false

	var opaque_bounds: Rect2i = _get_texture_opaque_bounds(
		raw_ingredient_sprite.texture
	)

	if opaque_bounds.size == Vector2i.ZERO:
		return false

	var half_texture: Vector2 = (
		raw_ingredient_sprite.texture.get_size()
		* 0.5
	)

	var left: float = float(
		opaque_bounds.position.x
	)

	var top: float = float(
		opaque_bounds.position.y
	)

	var right: float = float(
		opaque_bounds.position.x
		+ opaque_bounds.size.x
		- 1
	)

	var bottom: float = float(
		opaque_bounds.position.y
		+ opaque_bounds.size.y
		- 1
	)

	var center_x: float = (left + right) * 0.5
	var center_y: float = (top + bottom) * 0.5

	var sample_points: Array[Vector2] = [
		Vector2(left, top),
		Vector2(right, top),
		Vector2(left, bottom),
		Vector2(right, bottom),
		Vector2(center_x, top),
		Vector2(center_x, bottom),
		Vector2(left, center_y),
		Vector2(right, center_y),
		Vector2(center_x, center_y)
	]

	for texture_point: Vector2 in sample_points:
		var local_point: Vector2 = (
			texture_point - half_texture
		)

		var global_point: Vector2 = (
			raw_ingredient_sprite.to_global(
				local_point
			)
		)

		if not _is_point_on_sprite_opaque(
			cutting_board_sprite,
			global_point
		):
			return false

	return true


# ============================================================
# PIXEL COLLISION
# ============================================================

func _is_point_on_sprite_opaque(
	sprite: Sprite2D,
	global_point: Vector2
) -> bool:
	if sprite == null:
		return false

	if sprite.texture == null:
		return false

	if not sprite.visible:
		return false

	var texture_size: Vector2 = sprite.texture.get_size()

	var texture_point: Vector2 = (
		sprite.to_local(global_point)
	)

	if sprite.centered:
		texture_point += texture_size * 0.5

	var pixel_x: int = int(
		floorf(texture_point.x)
	)

	var pixel_y: int = int(
		floorf(texture_point.y)
	)

	if pixel_x < 0 or pixel_y < 0:
		return false

	if pixel_x >= int(texture_size.x):
		return false

	if pixel_y >= int(texture_size.y):
		return false

	var image: Image = sprite.texture.get_image()

	if image == null:
		return false

	return (
		image.get_pixel(pixel_x, pixel_y).a
		>= ALPHA_THRESHOLD
	)


func _get_texture_opaque_bounds(
	texture: Texture2D
) -> Rect2i:
	if texture == null:
		return Rect2i()

	var image: Image = texture.get_image()

	if image == null:
		return Rect2i()

	var minimum_x: int = image.get_width()
	var minimum_y: int = image.get_height()

	var maximum_x: int = -1
	var maximum_y: int = -1

	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if (
				image.get_pixel(x, y).a
				>= ALPHA_THRESHOLD
			):
				minimum_x = mini(minimum_x, x)
				minimum_y = mini(minimum_y, y)

				maximum_x = maxi(maximum_x, x)
				maximum_y = maxi(maximum_y, y)

	if maximum_x < minimum_x:
		return Rect2i()

	if maximum_y < minimum_y:
		return Rect2i()

	return Rect2i(
		minimum_x,
		minimum_y,
		maximum_x - minimum_x + 1,
		maximum_y - minimum_y + 1
	)


# ============================================================
# GUIDE MATH
# ============================================================

func _distance_point_to_segment(
	point: Vector2,
	segment_start: Vector2,
	segment_end: Vector2
) -> float:
	var segment: Vector2 = (
		segment_end - segment_start
	)

	var segment_length_squared: float = (
		segment.length_squared()
	)

	if segment_length_squared <= 0.0001:
		return point.distance_to(segment_start)

	var projection: float = (
		(point - segment_start).dot(segment)
		/ segment_length_squared
	)

	projection = clampf(
		projection,
		0.0,
		1.0
	)

	var closest_point: Vector2 = (
		segment_start
		+ segment * projection
	)

	return point.distance_to(closest_point)


# ============================================================
# CLEARING
# ============================================================

func _clear_cutting_state() -> void:
	_clear_cut_guides()

	for piece: Sprite2D in spawned_cut_sprites:
		if is_instance_valid(piece):
			piece.queue_free()

	spawned_cut_sprites.clear()
	cut_boundaries.clear()

	current_cut_index = 0
	current_visible_right = 0.0

	is_swiping_cut = false

	ingredient_is_locked = false
	ingredient_cut_complete = false
	ingredient_transfer_complete = false

	dragged_cut_piece = null


func _clear_cut_guides() -> void:
	for guide: Line2D in cut_guides:
		if is_instance_valid(guide):
			guide.queue_free()

	cut_guides.clear()


# ============================================================
# GENERAL HELPERS
# ============================================================

func _get_current_ingredient() -> Dictionary:
	return ingredient_data[current_ingredient_index]


func _get_current_target_position() -> Vector2:
	var ingredient: Dictionary = _get_current_ingredient()

	var container_type: int = int(
		ingredient["container_type"]
	)

	if container_type == ContainerType.BOWL:
		return bowl_target_position

	return tray_target_position


func _get_center_from_bottom_left(
	texture: Texture2D,
	bottom_left: Vector2,
	rotation_value: float,
	scale_value: Vector2
) -> Vector2:
	var texture_size: Vector2 = texture.get_size()

	var local_bottom_left := Vector2(
		-texture_size.x * 0.5,
		texture_size.y * 0.5
	)

	local_bottom_left *= scale_value

	var transformed_bottom_left: Vector2 = (
		local_bottom_left.rotated(rotation_value)
	)

	return (
		bottom_left
		- transformed_bottom_left
	)


func _get_sprite_bounds(
	sprite: Sprite2D
) -> Rect2:
	if sprite == null:
		return Rect2()

	if sprite.texture == null:
		return Rect2()

	var texture_size: Vector2 = sprite.texture.get_size()
	var half_size: Vector2 = texture_size * 0.5

	var local_corners: Array[Vector2] = [
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	]

	var first_corner: Vector2 = (
		(local_corners[0] * sprite.scale)
		.rotated(sprite.rotation)
		+ sprite.position
	)

	var minimum: Vector2 = first_corner
	var maximum: Vector2 = first_corner

	for local_corner: Vector2 in local_corners:
		var transformed_corner: Vector2 = (
			(local_corner * sprite.scale)
			.rotated(sprite.rotation)
			+ sprite.position
		)

		minimum.x = minf(
			minimum.x,
			transformed_corner.x
		)

		minimum.y = minf(
			minimum.y,
			transformed_corner.y
		)

		maximum.x = maxf(
			maximum.x,
			transformed_corner.x
		)

		maximum.y = maxf(
			maximum.y,
			transformed_corner.y
		)

	return Rect2(
		minimum,
		maximum - minimum
	)


func _get_sprite_half_width(
	sprite: Sprite2D
) -> float:
	if sprite == null:
		return 0.0

	if sprite.texture == null:
		return 0.0

	return (
		float(sprite.texture.get_width())
		* absf(sprite.scale.x)
		* 0.5
	)


func _get_sprite_half_height(
	sprite: Sprite2D
) -> float:
	if sprite == null:
		return 0.0

	if sprite.texture == null:
		return 0.0

	return (
		float(sprite.texture.get_height())
		* absf(sprite.scale.y)
		* 0.5
	)


# ============================================================
# RESTART
# ============================================================

func restart_stage() -> void:
	current_ingredient_index = 0
	selected_ingredient_index = 0
	displayed_collection_type = ContainerType.BOWL
	completed_ingredient_count = 0

	ingredient_is_on_board = false
	ingredient_is_locked = false
	ingredient_cut_complete = false
	ingredient_transfer_complete = false

	is_switching_ingredient = false
	transfer_animation_running = false
	stage_is_finished = false
	stage_completion_emitted = false

	current_drag_mode = DragMode.NONE
	is_swiping_cut = false

	set_process_input(true)
	_apply_current_ingredient_immediately()
	_announce_current_request()
	stage_restarted.emit()


func _exit_tree() -> void:
	SharedCursor.set_normal()
