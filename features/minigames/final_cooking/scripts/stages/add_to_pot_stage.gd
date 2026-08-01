extends "res://features/minigames/final_cooking/scripts/final_cooking_stage.gd"


# ============================================================
# BACKGROUND
# ============================================================

const BACKGROUND_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/backgrounds/bg_cooking_station_front.png"
)

const INSTRUCTION_PANEL_TEXTURE: Texture2D = preload(
	"res://features/minigames/export_templates/instruction_panel.png"
)

const NAVIGATION_ARROW_TEXTURE: Texture2D = preload(
	"res://features/minigames/snatch_battle/assets/ui/snatch_hand_attack_indicator.png"
)

const DIALOGUE_SCENE: PackedScene = preload(
	"res://features/minigames/shared/dialogue/shared_dialogue.tscn"
)

const UI_FONT: Font = preload(
	"res://features/minigames/shared/fonts/VCR_OSD_MONO_1.001.ttf"
)


# ============================================================
# COOKWARE
# ============================================================

const BURNER_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/cookware/add_to_pot/burner.png"
)

const BURNER_KNOB_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/cookware/add_to_pot/burner_knob.png"
)

const FOAM_PATCH_01_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/add_to_pot/foam/foam_patch_01.png"
)

const FOAM_PATCH_02_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/add_to_pot/foam/foam_patch_02.png"
)

const FOAM_PATCH_03_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/add_to_pot/foam/foam_patch_03.png"
)

const POT_EMPTY_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/cookware/add_to_pot/pot_empty.png"
)

const POT_WITH_WATER_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/cookware/add_to_pot/pot_with_water.png"
)

const POT_WITH_WATER_PORK_BELLY_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/cookware/add_to_pot/pot_with_water_pork_belly.png"
)

const POT_WITH_WATER_PORK_BELLY_LAPAY_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/cookware/add_to_pot/pot_with_water_pork_belly_heart.png"
)

const POT_WITH_MEAT_AND_ONION_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/cookware/add_to_pot/pot_with_meat_and_onion.png"
)

const POT_WITH_MEAT_ONION_GINGER_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/cookware/add_to_pot/pot_with_meat_onion_ginger.png"
)

const POT_WITH_MEAT_AROMATICS_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/cookware/add_to_pot/pot_with_meat_aromatics.png"
)

const POT_WITH_ALL_INGREDIENTS_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/cookware/add_to_pot/pot_with_all_ingredients.png"
)


# ============================================================
# FULL CONTAINERS
# ============================================================

const WATER_PITCHER_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/ingredients/add_to_pot/containers_full/water_pitcher.png")

const PORK_BELLY_TRAY_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/add_to_pot/containers_full/pork_belly_cut_tray.png"
)

const LAPAY_TRAY_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/add_to_pot/containers_full/heart_cut_tray.png"
)

const ONION_BOWL_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/add_to_pot/containers_full/onion_cut_bowl.png"
)

const GINGER_BOWL_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/add_to_pot/containers_full/ginger_cut_bowl.png"
)

const GARLIC_BOWL_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/add_to_pot/containers_full/garlic_cut_bowl.png"
)

const LIVER_TRAY_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/add_to_pot/containers_full/liver_cut_tray.png"
)


# ============================================================
# EMPTY CONTAINERS
# ============================================================

const PITCHER_EMPTY_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/add_to_pot/containers_empty/pitcher_empty.png"
)

const BOWL_EMPTY_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/add_to_pot/containers_empty/bowl_empty.png"
)

const TRAY_EMPTY_TEXTURE: Texture2D = preload(
	"res://features/minigames/final_cooking/assets/ingredients/add_to_pot/containers_empty/tray_empty.png"
)


# ============================================================
# SCREEN AND MAIN POSITIONS
# ============================================================

const SCREEN_SIZE := Vector2(1152.0, 648.0)
const SCREEN_CENTER := Vector2(576.0, 324.0)

# The burner stays in its original position.
const BURNER_POSITION := Vector2(576.0, 324.0)

# Only the pot is moved upward.
# Make the Y value more negative to move the pot higher.
const POT_BASE_POSITION := Vector2(576.0, 324.0)
const POT_OFFSET := Vector2(15.0, -90.0)
const POT_POSITION: Vector2 = POT_BASE_POSITION + POT_OFFSET

const BURNER_SCALE := Vector2.ONE
const POT_SCALE := Vector2.ONE

const INSTRUCTION_PANEL_POSITION := Vector2(12.0, 12.0)
const INSTRUCTION_PANEL_SIZE := Vector2(293.0, 350.0)
const INSTRUCTION_TEXT_POSITION := Vector2(27.0, 22.0)
const INSTRUCTION_TEXT_SIZE := Vector2(239.0, 105.0)


# ============================================================
# CONTAINER TOP-LEFT POSITIONS
# ============================================================

const BOWL_TOP_LEFT := Vector2(893.5, 402.1)
const TRAY_TOP_LEFT := Vector2(876.7, 406.6)
const PITCHER_TOP_LEFT := Vector2(854.9, 349.2)

const BOWL_SCALE := Vector2.ONE
const TRAY_SCALE := Vector2.ONE
const PITCHER_SCALE := Vector2.ONE

const MOUSE_DRAG_SCALE := Vector2(0.4, 0.4)


# ============================================================
# POT DROP AREA
# ============================================================

# The collision follows the pot, while the burner remains still.
const POT_DROP_BASE_CENTER := Vector2(576.0, 220.0)
const POT_DROP_EXTRA_OFFSET := Vector2(0.0, 20.0)

const POT_DROP_CENTER: Vector2 = (
	POT_DROP_BASE_CENTER
	+ POT_OFFSET
	+ POT_DROP_EXTRA_OFFSET
)
const POT_DROP_RADIUS := Vector2(190.0, 95.0)


const SHOW_POT_DROP_DEBUG: bool = false
const POT_DROP_DEBUG_COLOR := Color(0.0, 1.0, 0.0, 0.18)
const POT_DROP_BORDER_COLOR := Color(0.0, 1.0, 0.0, 0.95)
const POT_DROP_BORDER_WIDTH: float = 4.0
const POT_DROP_CIRCLE_POINTS: int = 64


# ============================================================
# HEAT AND FOAM MECHANIC
# ============================================================

# Burner knob uses a top-left position at scale 1.
const BURNER_KNOB_TOP_LEFT := Vector2(544.6, 556.1)
const BURNER_KNOB_SCALE := Vector2.ONE

# Placeholder temperature gauge drawn in code.
const HEAT_GAUGE_POSITION := Vector2(315.0, 250.0)
const HEAT_GAUGE_SIZE := Vector2(46.0, 230.0)
const HEAT_SAFE_MIN: float = 0.38
const HEAT_SAFE_MAX: float = 0.72

# Knob settings: OFF, LOW, MEDIUM, HIGH.
const HEAT_SETTING_OFF: int = 0
const HEAT_SETTING_LOW: int = 1
const HEAT_SETTING_MEDIUM: int = 2
const HEAT_SETTING_HIGH: int = 3

const KNOB_ROTATION_OFF: float = deg_to_rad(-90.0)
const KNOB_ROTATION_LOW: float = deg_to_rad(-35.0)
const KNOB_ROTATION_MEDIUM: float = deg_to_rad(15.0)
const KNOB_ROTATION_HIGH: float = deg_to_rad(65.0)

# Temperature behavior.
const TEMPERATURE_RISE_LOW: float = 0.045
const TEMPERATURE_RISE_MEDIUM: float = 0.085
const TEMPERATURE_RISE_HIGH: float = 0.135
const TEMPERATURE_FALL_OFF: float = 0.10
const REQUIRED_SAFE_COOK_TIME: float = 18.0

# Foam behavior.
const MAX_ACTIVE_FOAM: int = 3
const FOAM_SPAWN_DELAY_MIN: float = 1.8
const FOAM_SPAWN_DELAY_MAX: float = 4.0
const FOAM_CLEAN_DISTANCE_REQUIRED: float = 150.0
const FOAM_MIN_SCALE: float = 0.45
const FOAM_MAX_SCALE: float = 0.70
const FOAM_Z_INDEX: int = 16
const KNOB_Z_INDEX: int = 18
const HEAT_UI_Z_INDEX: int = 35


# ============================================================
# ANIMATION SETTINGS
# ============================================================

const SLIDE_OUT_DURATION: float = 0.35
const SLIDE_IN_DURATION: float = 0.35
const INGREDIENT_CHANGE_DELAY: float = 0.35

const EMPTY_CONTAINER_POP_DURATION: float = 0.20
const EMPTY_CONTAINER_POP_START_SCALE: float = 0.72

const POT_PULSE_MULTIPLIER: float = 1.08
const POT_PULSE_OUT_DURATION: float = 0.10
const POT_PULSE_RETURN_DURATION: float = 0.13

const OFFSCREEN_PADDING: float = 120.0
const NEXT_INGREDIENT_ARROW_POSITION := Vector2(1090.0, 490.0)


# ============================================================
# COLLISION
# ============================================================

const ALPHA_THRESHOLD: float = 0.1


# ============================================================
# Z INDEX
# ============================================================

const BACKGROUND_Z_INDEX: int = -20
const BURNER_Z_INDEX: int = -5
const POT_Z_INDEX: int = 0

const CONTAINER_Z_INDEX: int = 10
const POT_DROP_DEBUG_Z_INDEX: int = 15

const BUTTON_Z_INDEX: int = 20
const DRAG_PREVIEW_Z_INDEX: int = 30
const UI_Z_INDEX: int = 40


enum ContainerType {
	PITCHER,
	BOWL,
	TRAY
}


enum DragMode {
	NONE,
	CONTAINER
}


enum CookingPhase {
	ADDING_INGREDIENTS,
	WAITING_FOR_HEAT,
	HEATING_AND_SKIMMING,
	COMPLETE
}


# ============================================================
# NODES
# ============================================================

var background_sprite: Sprite2D
var burner_sprite: Sprite2D
var pot_sprite: Sprite2D

var current_container_sprite: Sprite2D
var drag_preview_sprite: Sprite2D

var next_button: TextureButton

var instruction_panel: TextureRect
var dialogue: SharedDialogue

var pot_drop_fill: Polygon2D
var pot_drop_outline: Line2D

var burner_knob_sprite: Sprite2D
var heat_gauge_root: Node2D
var heat_gauge_needle: Line2D
var heat_value_label: Label

var foam_sprites: Array[Sprite2D] = []
var foam_clean_values: Dictionary = {}


# ============================================================
# INGREDIENT DATA AND STATE
# ============================================================

var ingredient_data: Array[Dictionary] = []

var selected_ingredient_index: int = 0
var required_ingredient_index: int = 0

var current_drag_mode: DragMode = DragMode.NONE

var is_switching_ingredient: bool = false
var transfer_animation_running: bool = false
var stage_is_complete: bool = false
var stage_completion_emitted: bool = false

var cooking_phase: CookingPhase = CookingPhase.ADDING_INGREDIENTS
var heat_setting: int = HEAT_SETTING_OFF
var temperature_value: float = 0.0
var safe_cook_progress: float = 0.0
var foam_spawn_countdown: float = 0.0
var heating_has_started: bool = false
var mouse_is_swiping: bool = false
var previous_swipe_position := Vector2.ZERO
var heat_feedback_state: int = 99
var foam_guidance_given: bool = false

var random_number_generator := RandomNumberGenerator.new()


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	random_number_generator.randomize()

	_create_ingredient_data()
	_create_layout()

	set_process_input(true)
	set_process(true)

	stage_started.emit()


# ============================================================
# INGREDIENT DATA
# ============================================================

func _create_ingredient_data() -> void:
	ingredient_data = [
		{
			"id": "water",
			"display_name": "Water",
			"full_texture": WATER_PITCHER_TEXTURE,
			"empty_texture": PITCHER_EMPTY_TEXTURE,
			"pot_texture": POT_WITH_WATER_TEXTURE,
			"container_type": ContainerType.PITCHER,
			"completed": false
		},
		{
			"id": "pork_belly",
			"display_name": "Pork Belly",
			"full_texture": PORK_BELLY_TRAY_TEXTURE,
			"empty_texture": TRAY_EMPTY_TEXTURE,
			"pot_texture": POT_WITH_WATER_PORK_BELLY_TEXTURE,
			"container_type": ContainerType.TRAY,
			"completed": false
		},
		{
			"id": "lapay",
			"display_name": "Lapay",
			"full_texture": LAPAY_TRAY_TEXTURE,
			"empty_texture": TRAY_EMPTY_TEXTURE,
			"pot_texture": POT_WITH_WATER_PORK_BELLY_LAPAY_TEXTURE,
			"container_type": ContainerType.TRAY,
			"completed": false
		},
		{
			"id": "onion",
			"display_name": "Onion",
			"full_texture": ONION_BOWL_TEXTURE,
			"empty_texture": BOWL_EMPTY_TEXTURE,
			"pot_texture": POT_WITH_MEAT_AND_ONION_TEXTURE,
			"container_type": ContainerType.BOWL,
			"completed": false
		},
		{
			"id": "ginger",
			"display_name": "Ginger",
			"full_texture": GINGER_BOWL_TEXTURE,
			"empty_texture": BOWL_EMPTY_TEXTURE,
			"pot_texture": POT_WITH_MEAT_ONION_GINGER_TEXTURE,
			"container_type": ContainerType.BOWL,
			"completed": false
		},
		{
			"id": "garlic",
			"display_name": "Garlic",
			"full_texture": GARLIC_BOWL_TEXTURE,
			"empty_texture": BOWL_EMPTY_TEXTURE,
			"pot_texture": POT_WITH_MEAT_AROMATICS_TEXTURE,
			"container_type": ContainerType.BOWL,
			"completed": false
		},
		{
			"id": "liver",
			"display_name": "Liver",
			"full_texture": LIVER_TRAY_TEXTURE,
			"empty_texture": TRAY_EMPTY_TEXTURE,
			"pot_texture": POT_WITH_ALL_INGREDIENTS_TEXTURE,
			"container_type": ContainerType.TRAY,
			"completed": false
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

	burner_sprite = _create_sprite(
		"Burner",
		BURNER_TEXTURE,
		BURNER_POSITION,
		BURNER_SCALE,
		0.0,
		BURNER_Z_INDEX
	)

	pot_sprite = _create_sprite(
		"Pot",
		POT_EMPTY_TEXTURE,
		POT_POSITION,
		POT_SCALE,
		0.0,
		POT_Z_INDEX
	)

	_create_burner_knob()
	_create_heat_gauge()

	current_container_sprite = Sprite2D.new()
	current_container_sprite.name = "CurrentContainer"
	current_container_sprite.centered = true
	current_container_sprite.z_index = CONTAINER_Z_INDEX
	add_child(current_container_sprite)

	drag_preview_sprite = Sprite2D.new()
	drag_preview_sprite.name = "ContainerDragPreview"
	drag_preview_sprite.centered = true
	drag_preview_sprite.z_index = DRAG_PREVIEW_Z_INDEX
	drag_preview_sprite.visible = false
	add_child(drag_preview_sprite)

	_create_pot_drop_debug()
	_create_navigation_buttons()
	_create_instruction_panel()
	_create_dialogue()

	_apply_selected_ingredient_immediately()
	_announce_required_ingredient()


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
# POT DROP DEBUG AREA
# ============================================================

func _create_pot_drop_debug() -> void:
	pot_drop_fill = Polygon2D.new()
	pot_drop_fill.name = "PotDropDebugFill"
	pot_drop_fill.color = POT_DROP_DEBUG_COLOR
	pot_drop_fill.z_index = POT_DROP_DEBUG_Z_INDEX
	pot_drop_fill.visible = SHOW_POT_DROP_DEBUG
	add_child(pot_drop_fill)

	pot_drop_outline = Line2D.new()
	pot_drop_outline.name = "PotDropDebugOutline"
	pot_drop_outline.default_color = POT_DROP_BORDER_COLOR
	pot_drop_outline.width = POT_DROP_BORDER_WIDTH
	pot_drop_outline.closed = true
	pot_drop_outline.antialiased = false
	pot_drop_outline.z_index = POT_DROP_DEBUG_Z_INDEX + 1
	pot_drop_outline.visible = SHOW_POT_DROP_DEBUG
	add_child(pot_drop_outline)

	var points := PackedVector2Array()

	for index: int in range(POT_DROP_CIRCLE_POINTS):
		var fraction: float = (
			float(index)
			/ float(POT_DROP_CIRCLE_POINTS)
		)

		var angle: float = fraction * TAU

		points.append(
			POT_DROP_CENTER
			+ Vector2(
				cos(angle) * POT_DROP_RADIUS.x,
				sin(angle) * POT_DROP_RADIUS.y
			)
		)

	pot_drop_fill.polygon = points
	pot_drop_outline.points = points


func _is_point_inside_pot_drop_area(
	point: Vector2
) -> bool:
	var relative_point: Vector2 = point - POT_DROP_CENTER

	var normalized_x: float = (
		relative_point.x / POT_DROP_RADIUS.x
	)

	var normalized_y: float = (
		relative_point.y / POT_DROP_RADIUS.y
	)

	return (
		normalized_x * normalized_x
		+ normalized_y * normalized_y
		<= 1.0
	)


# ============================================================
# INSTRUCTIONS AND LOLA DIALOGUE
# ============================================================

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
		"ADD WHAT LOLA ASKS FOR.\n"
		+ "TURN THE KNOB TO BOIL.\n"
		+ "SWIPE AWAY THE FOAM."
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


func _announce_required_ingredient() -> void:
	if required_ingredient_index >= ingredient_data.size():
		return

	var ingredient := ingredient_data[required_ingredient_index]
	_say_lola(
		"Apo, add the %s next."
		% str(ingredient["display_name"]),
		"neutral",
		3.6
	)


# ============================================================
# NAVIGATION BUTTONS
# ============================================================

func _create_navigation_buttons() -> void:
	next_button = TextureButton.new()
	next_button.name = "NextIngredientButton"
	next_button.texture_normal = NAVIGATION_ARROW_TEXTURE
	next_button.ignore_texture_size = true
	next_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	next_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	next_button.tooltip_text = "Next ingredient"
	next_button.size = Vector2(48.0, 48.0)
	next_button.focus_mode = Control.FOCUS_NONE
	next_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	next_button.z_index = BUTTON_Z_INDEX
	next_button.pressed.connect(
		_on_next_button_pressed
	)
	add_child(next_button)


func _update_navigation_button_positions() -> void:
	# Ingredient art keeps its authored position. The arrows use fixed,
	# always-visible screen positions because several container sprites
	# extend beyond the bottom or right edge of the viewport.
	next_button.position = NEXT_INGREDIENT_ARROW_POSITION


func _on_next_button_pressed() -> void:
	if not _can_change_selected_ingredient():
		return
	play_cooking_sfx("ui_navigate", -8.0)

	var target_index: int = selected_ingredient_index + 1

	if target_index >= ingredient_data.size():
		target_index = 0

	await _switch_to_ingredient(target_index)


func _can_change_selected_ingredient() -> bool:
	if stage_is_complete:
		return false

	if is_switching_ingredient:
		return false

	if current_drag_mode != DragMode.NONE:
		return false

	return true


# ============================================================
# APPLY SELECTED INGREDIENT
# ============================================================

func _apply_selected_ingredient_immediately() -> void:
	var ingredient: Dictionary = _get_selected_ingredient()

	var display_texture: Texture2D = (
		_get_selected_container_texture()
	)

	current_container_sprite.texture = display_texture
	current_container_sprite.scale = (
		_get_container_scale(ingredient)
	)

	current_container_sprite.rotation = 0.0
	current_container_sprite.position = (
		_get_container_center_position(
			ingredient,
			display_texture
		)
	)

	current_container_sprite.visible = true

	drag_preview_sprite.visible = false
	drag_preview_sprite.texture = null

	_update_navigation_button_positions()


func _get_selected_container_texture() -> Texture2D:
	var ingredient: Dictionary = _get_selected_ingredient()

	var completed: bool = bool(
		ingredient["completed"]
	)

	if completed:
		return ingredient["empty_texture"] as Texture2D

	return ingredient["full_texture"] as Texture2D


# ============================================================
# INGREDIENT SWITCHING
# ============================================================

func _switch_to_ingredient(
	target_index: int
) -> void:
	if target_index == selected_ingredient_index:
		return

	is_switching_ingredient = true

	next_button.disabled = true

	await _slide_current_container_down()

	current_container_sprite.visible = false

	await get_tree().create_timer(
		INGREDIENT_CHANGE_DELAY
	).timeout

	selected_ingredient_index = target_index

	_prepare_selected_container_offscreen_right()

	current_container_sprite.visible = true

	await _slide_selected_container_in()

	is_switching_ingredient = false

	next_button.disabled = false

	_update_navigation_button_positions()


func _slide_current_container_down() -> void:
	var half_height: float = _get_sprite_half_height(
		current_container_sprite
	)

	var viewport_height: float = (
		get_viewport_rect().size.y
	)

	var target_position := Vector2(
		current_container_sprite.position.x,
		viewport_height
			+ half_height
			+ OFFSCREEN_PADDING
	)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(
		current_container_sprite,
		"position",
		target_position,
		SLIDE_OUT_DURATION
	)

	await tween.finished


func _prepare_selected_container_offscreen_right() -> void:
	var ingredient: Dictionary = _get_selected_ingredient()
	var display_texture: Texture2D = (
		_get_selected_container_texture()
	)

	current_container_sprite.texture = display_texture
	current_container_sprite.scale = (
		_get_container_scale(ingredient)
	)
	current_container_sprite.rotation = 0.0

	var target_position: Vector2 = (
		_get_container_center_position(
			ingredient,
			display_texture
		)
	)

	var half_width: float = _get_sprite_half_width(
		current_container_sprite
	)

	current_container_sprite.position = Vector2(
		get_viewport_rect().size.x
			+ half_width
			+ OFFSCREEN_PADDING,
		target_position.y
	)


func _slide_selected_container_in() -> void:
	var ingredient: Dictionary = _get_selected_ingredient()

	var target_position: Vector2 = (
		_get_container_center_position(
			ingredient,
			current_container_sprite.texture
		)
	)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		current_container_sprite,
		"position",
		target_position,
		SLIDE_IN_DURATION
	)

	await tween.finished


# ============================================================
# INPUT
# ============================================================

func _input(event: InputEvent) -> void:
	# Prevent Space from advancing the outer stage manager.
	if event is InputEventKey:
		var key_event := event as InputEventKey

		if key_event.keycode == KEY_SPACE:
			get_viewport().set_input_as_handled()
			return

	if stage_is_complete:
		return

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton

		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return

		if (
			next_button.visible
			and next_button.get_global_rect().has_point(mouse_button.position)
		):
			return

		if cooking_phase == CookingPhase.WAITING_FOR_HEAT:
			if mouse_button.pressed:
				if _is_point_on_sprite_opaque(
					burner_knob_sprite,
					mouse_button.position
				):
					_adjust_heat_from_click(
						mouse_button.position
					)
			return

		if cooking_phase == CookingPhase.HEATING_AND_SKIMMING:
			if (
				mouse_button.pressed
				and _is_point_on_sprite_opaque(
					burner_knob_sprite,
					mouse_button.position
				)
			):
				_adjust_heat_from_click(
					mouse_button.position
				)
				mouse_is_swiping = false
				return

			mouse_is_swiping = mouse_button.pressed
			previous_swipe_position = mouse_button.position
			return

		if is_switching_ingredient:
			return

		if transfer_animation_running:
			return

		if mouse_button.pressed:
			_handle_mouse_pressed(mouse_button.position)
		else:
			_handle_mouse_released(mouse_button.position)

	elif event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion

		if (
			cooking_phase == CookingPhase.HEATING_AND_SKIMMING
			and mouse_is_swiping
		):
			_clean_foam_along_swipe(
				previous_swipe_position,
				mouse_motion.position
			)
			previous_swipe_position = mouse_motion.position
			return

		if is_switching_ingredient:
			return

		if transfer_animation_running:
			return

		if current_drag_mode == DragMode.CONTAINER:
			drag_preview_sprite.position = (
				mouse_motion.position
			)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey

		if key_event.keycode == KEY_SPACE:
			get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()


func _handle_mouse_pressed(
	mouse_position: Vector2
) -> void:
	if cooking_phase != CookingPhase.ADDING_INGREDIENTS:
		return

	if current_drag_mode != DragMode.NONE:
		return

	var ingredient: Dictionary = _get_selected_ingredient()

	if bool(ingredient["completed"]):
		_say_lola(
			"We already added that one, apo. Its container is empty now.",
			"neutral"
		)
		return

	if _is_point_on_sprite_opaque(
		current_container_sprite,
		mouse_position
	):
		_start_container_drag(mouse_position)


func _handle_mouse_released(
	mouse_position: Vector2
) -> void:
	if current_drag_mode != DragMode.CONTAINER:
		return

	_finish_container_drag(mouse_position)


# ============================================================
# CONTAINER DRAGGING
# ============================================================

func _start_container_drag(
	mouse_position: Vector2
) -> void:
	play_cooking_sfx("item_pickup", -7.0)
	var ingredient: Dictionary = _get_selected_ingredient()

	var full_texture: Texture2D = (
		ingredient["full_texture"] as Texture2D
	)

	current_drag_mode = DragMode.CONTAINER

	drag_preview_sprite.texture = full_texture
	drag_preview_sprite.position = mouse_position
	drag_preview_sprite.scale = MOUSE_DRAG_SCALE
	drag_preview_sprite.rotation = 0.0
	drag_preview_sprite.visible = true

	current_container_sprite.visible = false

	next_button.visible = false


func _finish_container_drag(
	mouse_position: Vector2
) -> void:
	current_drag_mode = DragMode.NONE

	drag_preview_sprite.visible = false
	drag_preview_sprite.texture = null
	drag_preview_sprite.scale = MOUSE_DRAG_SCALE

	var dropped_in_pot: bool = (
		_is_point_inside_pot_drop_area(
			mouse_position
		)
	)

	if not dropped_in_pot:
		_restore_selected_container()
		return

	if selected_ingredient_index != required_ingredient_index:
		play_cooking_sfx("wrong", -5.0)
		_restore_selected_container()
		var required := ingredient_data[required_ingredient_index]
		_say_lola(
			"Not that one yet, apo. Add the %s first."
			% str(required["display_name"]),
			"concerned"
		)

		return

	await _accept_selected_ingredient()


func _restore_selected_container() -> void:
	var ingredient: Dictionary = _get_selected_ingredient()

	var display_texture: Texture2D = (
		_get_selected_container_texture()
	)

	current_container_sprite.texture = display_texture
	current_container_sprite.scale = (
		_get_container_scale(ingredient)
	)

	current_container_sprite.position = (
		_get_container_center_position(
			ingredient,
			display_texture
		)
	)

	current_container_sprite.visible = true

	next_button.visible = true

	_update_navigation_button_positions()


# ============================================================
# ACCEPT CORRECT INGREDIENT
# ============================================================

func _accept_selected_ingredient() -> void:
	transfer_animation_running = true

	next_button.disabled = true

	var ingredient: Dictionary = _get_selected_ingredient()
	play_cooking_sfx(
		"water_pour" if str(ingredient["id"]) == "water" else "ingredient_drop",
		-4.0
	)

	ingredient["completed"] = true
	ingredient_data[selected_ingredient_index] = ingredient

	var updated_pot_texture: Texture2D = (
		ingredient["pot_texture"] as Texture2D
	)

	pot_sprite.texture = updated_pot_texture

	await _pulse_pot()

	await _show_empty_container_with_pop()

	required_ingredient_index += 1

	# After Lapay, pause ingredient adding and begin heat control.
	if required_ingredient_index == 3:
		await _begin_heat_phase()

		transfer_animation_running = false
		_restore_ingredient_navigation()
		return

	if required_ingredient_index >= ingredient_data.size():
		await _finish_add_to_pot_stage()

		transfer_animation_running = false
		return

	await get_tree().create_timer(0.15).timeout

	await _switch_to_ingredient(
		required_ingredient_index
	)

	transfer_animation_running = false
	_restore_ingredient_navigation()
	_announce_required_ingredient()


func _restore_ingredient_navigation() -> void:
	if stage_is_complete:
		return
	next_button.visible = true
	next_button.disabled = false


func _show_empty_container_with_pop() -> void:
	var ingredient: Dictionary = _get_selected_ingredient()

	var empty_texture: Texture2D = (
		ingredient["empty_texture"] as Texture2D
	)

	var normal_scale: Vector2 = (
		_get_container_scale(ingredient)
	)

	current_container_sprite.texture = empty_texture

	current_container_sprite.position = (
		_get_container_center_position(
			ingredient,
			empty_texture
		)
	)

	current_container_sprite.scale = (
		normal_scale
		* EMPTY_CONTAINER_POP_START_SCALE
	)

	current_container_sprite.visible = true

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		current_container_sprite,
		"scale",
		normal_scale,
		EMPTY_CONTAINER_POP_DURATION
	)

	await tween.finished


func _pulse_pot() -> void:
	var normal_scale: Vector2 = POT_SCALE

	pot_sprite.scale = normal_scale

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		pot_sprite,
		"scale",
		normal_scale * POT_PULSE_MULTIPLIER,
		POT_PULSE_OUT_DURATION
	)

	tween.tween_property(
		pot_sprite,
		"scale",
		normal_scale,
		POT_PULSE_RETURN_DURATION
	)

	await tween.finished


# ============================================================
# BURNER KNOB, HEAT GAUGE, AND FOAM
# ============================================================

func _create_burner_knob() -> void:
	burner_knob_sprite = Sprite2D.new()
	burner_knob_sprite.name = "BurnerKnob"
	burner_knob_sprite.texture = BURNER_KNOB_TEXTURE
	burner_knob_sprite.centered = true
	burner_knob_sprite.scale = BURNER_KNOB_SCALE
	burner_knob_sprite.rotation = KNOB_ROTATION_OFF
	burner_knob_sprite.z_index = KNOB_Z_INDEX
	burner_knob_sprite.position = (
		BURNER_KNOB_TOP_LEFT
		+ BURNER_KNOB_TEXTURE.get_size() * BURNER_KNOB_SCALE * 0.5
	)
	burner_knob_sprite.visible = true
	add_child(burner_knob_sprite)


func _create_heat_gauge() -> void:
	heat_gauge_root = Node2D.new()
	heat_gauge_root.name = "HeatGaugePlaceholder"
	heat_gauge_root.position = HEAT_GAUGE_POSITION
	heat_gauge_root.z_index = HEAT_UI_Z_INDEX
	heat_gauge_root.visible = false
	add_child(heat_gauge_root)

	var background := Polygon2D.new()
	background.name = "GaugeBackground"
	background.color = Color(0.08, 0.07, 0.06, 0.90)
	background.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(HEAT_GAUGE_SIZE.x, 0.0),
		HEAT_GAUGE_SIZE,
		Vector2(0.0, HEAT_GAUGE_SIZE.y)
	])
	heat_gauge_root.add_child(background)

	var safe_zone := Polygon2D.new()
	safe_zone.name = "SafeZone"
	safe_zone.color = Color(0.20, 0.75, 0.30, 0.65)

	var safe_top: float = (
		HEAT_GAUGE_SIZE.y
		* (1.0 - HEAT_SAFE_MAX)
	)
	var safe_bottom: float = (
		HEAT_GAUGE_SIZE.y
		* (1.0 - HEAT_SAFE_MIN)
	)

	safe_zone.polygon = PackedVector2Array([
		Vector2(4.0, safe_top),
		Vector2(HEAT_GAUGE_SIZE.x - 4.0, safe_top),
		Vector2(HEAT_GAUGE_SIZE.x - 4.0, safe_bottom),
		Vector2(4.0, safe_bottom)
	])
	heat_gauge_root.add_child(safe_zone)

	heat_gauge_needle = Line2D.new()
	heat_gauge_needle.name = "Needle"
	heat_gauge_needle.width = 5.0
	heat_gauge_needle.default_color = Color.WHITE
	heat_gauge_needle.points = PackedVector2Array([
		Vector2(-10.0, HEAT_GAUGE_SIZE.y),
		Vector2(HEAT_GAUGE_SIZE.x + 10.0, HEAT_GAUGE_SIZE.y)
	])
	heat_gauge_root.add_child(heat_gauge_needle)

	var gauge_title := Label.new()
	gauge_title.name = "GaugeTitle"
	gauge_title.text = "HEAT"
	gauge_title.position = Vector2(-4.0, -30.0)
	gauge_title.size = Vector2(70.0, 25.0)
	gauge_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gauge_title.add_theme_font_size_override("font_size", 16)
	gauge_title.add_theme_color_override("font_color", Color.WHITE)
	gauge_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heat_gauge_root.add_child(gauge_title)

	heat_value_label = Label.new()
	heat_value_label.name = "HeatValueLabel"
	heat_value_label.position = Vector2(-35.0, HEAT_GAUGE_SIZE.y + 8.0)
	heat_value_label.size = Vector2(120.0, 28.0)
	heat_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heat_value_label.add_theme_font_size_override("font_size", 15)
	heat_value_label.add_theme_color_override("font_color", Color.WHITE)
	heat_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heat_gauge_root.add_child(heat_value_label)

	_update_heat_gauge()


func _begin_heat_phase() -> void:
	cooking_phase = CookingPhase.WAITING_FOR_HEAT

	# Browsing stays available during heat control. Used ingredients show
	# their empty pitcher, bowl, or tray and cannot be dragged again.
	next_button.visible = true
	next_button.disabled = false
	current_container_sprite.visible = true
	drag_preview_sprite.visible = false

	burner_knob_sprite.visible = true
	heat_gauge_root.visible = true

	heat_setting = HEAT_SETTING_OFF
	temperature_value = 0.0
	safe_cook_progress = 0.0
	heating_has_started = false
	foam_spawn_countdown = 0.0
	mouse_is_swiping = false
	heat_feedback_state = 99
	foam_guidance_given = false

	_set_knob_rotation()
	_update_heat_gauge()
	_say_lola(
		"Now turn the knob, apo. Keep the heat steady and skim away the foam.",
		"neutral",
		4.5
	)


func _adjust_heat_from_click(
	mouse_position: Vector2
) -> void:
	play_cooking_sfx("burner_knob", -5.0, randf_range(0.96, 1.04))
	var direction: int = 1

	# Click the left half of the knob to lower the heat.
	# Click the right half to raise the heat.
	if mouse_position.x < burner_knob_sprite.position.x:
		direction = -1

	heat_setting = clampi(
		heat_setting + direction,
		HEAT_SETTING_OFF,
		HEAT_SETTING_HIGH
	)

	_set_knob_rotation()

	if heat_setting != HEAT_SETTING_OFF:
		heating_has_started = true
		cooking_phase = CookingPhase.HEATING_AND_SKIMMING


func _set_knob_rotation() -> void:
	match heat_setting:
		HEAT_SETTING_OFF:
			burner_knob_sprite.rotation = KNOB_ROTATION_OFF

		HEAT_SETTING_LOW:
			burner_knob_sprite.rotation = KNOB_ROTATION_LOW

		HEAT_SETTING_MEDIUM:
			burner_knob_sprite.rotation = KNOB_ROTATION_MEDIUM

		HEAT_SETTING_HIGH:
			burner_knob_sprite.rotation = KNOB_ROTATION_HIGH


func _process(delta: float) -> void:
	if cooking_phase != CookingPhase.HEATING_AND_SKIMMING:
		return

	_update_temperature(delta)
	_update_foam_spawning(delta)
	_update_heat_gauge()

	if (
		safe_cook_progress >= REQUIRED_SAFE_COOK_TIME
		and foam_sprites.is_empty()
	):
		_complete_heat_phase()


func _update_temperature(delta: float) -> void:
	var temperature_change: float = 0.0

	match heat_setting:
		HEAT_SETTING_OFF:
			temperature_change = -TEMPERATURE_FALL_OFF

		HEAT_SETTING_LOW:
			temperature_change = TEMPERATURE_RISE_LOW

		HEAT_SETTING_MEDIUM:
			temperature_change = TEMPERATURE_RISE_MEDIUM

		HEAT_SETTING_HIGH:
			temperature_change = TEMPERATURE_RISE_HIGH

	temperature_value = clampf(
		temperature_value + temperature_change * delta,
		0.0,
		1.0
	)

	var is_safe: bool = (
		temperature_value >= HEAT_SAFE_MIN
		and temperature_value <= HEAT_SAFE_MAX
	)

	if is_safe:
		safe_cook_progress = minf(
			safe_cook_progress + delta,
			REQUIRED_SAFE_COOK_TIME
		)

	var new_feedback_state: int = 0
	if temperature_value < HEAT_SAFE_MIN:
		new_feedback_state = -1
	elif temperature_value > HEAT_SAFE_MAX:
		new_feedback_state = 1

	if new_feedback_state == heat_feedback_state:
		return
	heat_feedback_state = new_feedback_state

	match heat_feedback_state:
		-1:
			_say_lola(
				"A little more heat, apo. Turn the knob up.",
				"concerned"
			)
		0:
			_say_lola(
				"There, apo. Keep the heat just like that.",
				"happy"
			)
		1:
			_say_lola(
				"Too hot, apo. Turn it down before the broth suffers.",
				"concerned"
			)


func _update_heat_gauge() -> void:
	if heat_gauge_needle == null:
		return

	var needle_y: float = (
		HEAT_GAUGE_SIZE.y
		* (1.0 - temperature_value)
	)

	heat_gauge_needle.points = PackedVector2Array([
		Vector2(-10.0, needle_y),
		Vector2(HEAT_GAUGE_SIZE.x + 10.0, needle_y)
	])

	if heat_value_label != null:
		var heat_name: String = "OFF"

		match heat_setting:
			HEAT_SETTING_LOW:
				heat_name = "LOW"
			HEAT_SETTING_MEDIUM:
				heat_name = "MEDIUM"
			HEAT_SETTING_HIGH:
				heat_name = "HIGH"

		heat_value_label.text = heat_name


func _update_foam_spawning(delta: float) -> void:
	if not heating_has_started:
		return

	if temperature_value < HEAT_SAFE_MIN:
		return

	if safe_cook_progress >= REQUIRED_SAFE_COOK_TIME:
		return

	foam_spawn_countdown -= delta

	if foam_spawn_countdown > 0.0:
		return

	if foam_sprites.size() < MAX_ACTIVE_FOAM:
		_spawn_random_foam_patch()

	foam_spawn_countdown = random_number_generator.randf_range(
		FOAM_SPAWN_DELAY_MIN,
		FOAM_SPAWN_DELAY_MAX
	)


func _spawn_random_foam_patch() -> void:
	var foam_textures: Array[Texture2D] = [
		FOAM_PATCH_01_TEXTURE,
		FOAM_PATCH_02_TEXTURE,
		FOAM_PATCH_03_TEXTURE
	]

	var texture_index: int = random_number_generator.randi_range(
		0,
		foam_textures.size() - 1
	)

	var foam_texture: Texture2D = foam_textures[texture_index]

	var random_angle: float = random_number_generator.randf_range(
		0.0,
		TAU
	)

	var random_radius: float = sqrt(
		random_number_generator.randf()
	)

	var local_offset := Vector2(
		cos(random_angle)
			* POT_DROP_RADIUS.x
			* 0.62
			* random_radius,
		sin(random_angle)
			* POT_DROP_RADIUS.y
			* 0.55
			* random_radius
	)

	var foam := Sprite2D.new()
	foam.name = "FoamPatch"
	foam.texture = foam_texture
	foam.centered = true
	foam.position = POT_DROP_CENTER + local_offset

	var random_scale_value: float = (
		random_number_generator.randf_range(
			FOAM_MIN_SCALE,
			FOAM_MAX_SCALE
		)
	)

	foam.scale = Vector2.ONE * random_scale_value
	foam.rotation = random_number_generator.randf_range(
		-deg_to_rad(10.0),
		deg_to_rad(10.0)
	)
	foam.z_index = FOAM_Z_INDEX

	add_child(foam)

	foam_sprites.append(foam)
	foam_clean_values[foam] = 0.0

	if not foam_guidance_given:
		foam_guidance_given = true
		_say_lola(
			"The foam is rising, apo. Swipe it away gently.",
			"concerned",
			3.8
		)


func _clean_foam_along_swipe(
	from_position: Vector2,
	to_position: Vector2
) -> void:
	var swipe_distance: float = from_position.distance_to(
		to_position
	)

	if swipe_distance <= 0.0:
		return

	var foam_copy: Array[Sprite2D] = foam_sprites.duplicate()

	for foam: Sprite2D in foam_copy:
		if not is_instance_valid(foam):
			continue

		if not _segment_touches_foam(
			from_position,
			to_position,
			foam
		):
			continue

		var clean_value: float = float(
			foam_clean_values.get(foam, 0.0)
		)

		clean_value += swipe_distance
		foam_clean_values[foam] = clean_value

		var clean_fraction: float = clampf(
			clean_value / FOAM_CLEAN_DISTANCE_REQUIRED,
			0.0,
			1.0
		)

		foam.modulate.a = 1.0 - clean_fraction
		foam.scale *= maxf(
			0.82,
			1.0 - clean_fraction * 0.06
		)

		if clean_fraction >= 1.0:
			_remove_foam_patch(foam)


func _segment_touches_foam(
	from_position: Vector2,
	to_position: Vector2,
	foam: Sprite2D
) -> bool:
	if foam.texture == null:
		return false

	var segment: Vector2 = to_position - from_position
	var segment_length_squared: float = segment.length_squared()

	var closest_point: Vector2 = from_position

	if segment_length_squared > 0.0:
		var projection: float = clampf(
			(foam.position - from_position).dot(segment)
				/ segment_length_squared,
			0.0,
			1.0
		)

		closest_point = from_position + segment * projection

	var foam_radius: float = (
		minf(
			float(foam.texture.get_width()),
			float(foam.texture.get_height())
		)
		* maxf(absf(foam.scale.x), absf(foam.scale.y))
		* 0.42
	)

	return closest_point.distance_to(foam.position) <= foam_radius


func _remove_foam_patch(foam: Sprite2D) -> void:
	play_cooking_sfx("foam_skim", -8.0, randf_range(0.97, 1.05))
	foam_sprites.erase(foam)
	foam_clean_values.erase(foam)
	foam.queue_free()


func _clear_all_foam() -> void:
	for foam: Sprite2D in foam_sprites:
		if is_instance_valid(foam):
			foam.queue_free()

	foam_sprites.clear()
	foam_clean_values.clear()


func _complete_heat_phase() -> void:
	if cooking_phase != CookingPhase.HEATING_AND_SKIMMING:
		return
	play_cooking_sfx("correct", -5.0)

	cooking_phase = CookingPhase.ADDING_INGREDIENTS
	heat_setting = HEAT_SETTING_LOW
	mouse_is_swiping = false

	burner_knob_sprite.visible = true
	heat_gauge_root.visible = false

	selected_ingredient_index = required_ingredient_index

	_prepare_selected_container_offscreen_right()
	current_container_sprite.visible = true

	await _slide_selected_container_in()

	next_button.visible = true
	next_button.disabled = false

	_update_navigation_button_positions()
	_say_lola(
		"Beautiful, apo. The broth is clear. Now add the %s."
		% str(ingredient_data[required_ingredient_index]["display_name"]),
		"happy",
		4.0
	)


# ============================================================
# FINISH STAGE
# ============================================================

func _finish_add_to_pot_stage() -> void:
	cooking_phase = CookingPhase.COMPLETE
	stage_is_complete = true

	next_button.visible = false

	_say_lola(
		"Very good, apo. Everything is in the pot. Let us season the broth next.",
		"happy",
		3.0
	)
	await get_tree().create_timer(1.6).timeout

	if stage_completion_emitted:
		return
	stage_completion_emitted = true
	set_process_input(false)
	complete_stage()


# ============================================================
# CONTAINER POSITION HELPERS
# ============================================================

func _get_container_center_position(
	ingredient: Dictionary,
	texture: Texture2D
) -> Vector2:
	var container_type: int = int(
		ingredient["container_type"]
	)

	var top_left := Vector2.ZERO
	var container_scale := Vector2.ONE

	match container_type:
		ContainerType.PITCHER:
			top_left = PITCHER_TOP_LEFT
			container_scale = PITCHER_SCALE

		ContainerType.BOWL:
			top_left = BOWL_TOP_LEFT
			container_scale = BOWL_SCALE

		ContainerType.TRAY:
			top_left = TRAY_TOP_LEFT
			container_scale = TRAY_SCALE

	var texture_size: Vector2 = (
		texture.get_size() * container_scale
	)

	return (
		top_left
		+ texture_size * 0.5
	)


func _get_container_scale(
	ingredient: Dictionary
) -> Vector2:
	var container_type: int = int(
		ingredient["container_type"]
	)

	match container_type:
		ContainerType.PITCHER:
			return PITCHER_SCALE

		ContainerType.BOWL:
			return BOWL_SCALE

		ContainerType.TRAY:
			return TRAY_SCALE

	return Vector2.ONE


# ============================================================
# GENERAL HELPERS
# ============================================================

func _get_selected_ingredient() -> Dictionary:
	return ingredient_data[selected_ingredient_index]


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

	var pixel_color: Color = image.get_pixel(
		pixel_x,
		pixel_y
	)

	return pixel_color.a >= ALPHA_THRESHOLD


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
	if stage_completion_emitted:
		return

	selected_ingredient_index = 0
	required_ingredient_index = 0

	current_drag_mode = DragMode.NONE

	is_switching_ingredient = false
	transfer_animation_running = false
	stage_is_complete = false
	cooking_phase = CookingPhase.ADDING_INGREDIENTS

	heat_setting = HEAT_SETTING_OFF
	temperature_value = 0.0
	safe_cook_progress = 0.0
	foam_spawn_countdown = 0.0
	heating_has_started = false
	mouse_is_swiping = false
	heat_feedback_state = 99
	foam_guidance_given = false

	_clear_all_foam()

	for index: int in range(ingredient_data.size()):
		var ingredient: Dictionary = ingredient_data[index]
		ingredient["completed"] = false
		ingredient_data[index] = ingredient

	pot_sprite.texture = POT_EMPTY_TEXTURE
	pot_sprite.position = POT_POSITION
	pot_sprite.scale = POT_SCALE

	burner_knob_sprite.rotation = KNOB_ROTATION_OFF
	burner_knob_sprite.visible = true
	heat_gauge_root.visible = false
	_update_heat_gauge()

	next_button.visible = true
	next_button.disabled = false

	_apply_selected_ingredient_immediately()
	_announce_required_ingredient()
