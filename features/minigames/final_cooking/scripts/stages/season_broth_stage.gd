extends "res://features/minigames/final_cooking/scripts/final_cooking_stage.gd"

const BACKGROUND: Texture2D = preload("res://features/minigames/final_cooking/assets/backgrounds/bg_cooking_station_front.png")
const BURNER: Texture2D = preload("res://features/minigames/final_cooking/assets/cookware/add_to_pot/burner.png")
const POT: Texture2D = preload("res://features/minigames/final_cooking/assets/cookware/add_to_pot/pot_with_all_ingredients.png")
const INSTRUCTION_PANEL: Texture2D = preload("res://features/minigames/export_templates/instruction_panel.png")
const NAVIGATION_ARROW: Texture2D = preload("res://features/minigames/snatch_battle/assets/ui/snatch_hand_attack_indicator.png")
const MIKI_PROGRESS_PANEL: Texture2D = preload("res://features/minigames/miki_noodle_crank/assets/ui/miki_progress_panel.png")
const MIKI_PROGRESS_GREEN: Texture2D = preload("res://features/minigames/miki_noodle_crank/assets/ui/miki_progress_green.png")
const MIKI_PROGRESS_FRAME: Texture2D = preload("res://features/minigames/miki_noodle_crank/assets/ui/miki_progress_frame.png")
const LOLA_DIALOGUE: PackedScene = preload("res://features/minigames/shared/dialogue/shared_dialogue.tscn")
const DROP_CENTER := Vector2(591.0, 150.0)
const DROP_RADIUS := Vector2(185.0, 88.0)
const POUR_EFFECT_BOTTOM_Y := 224.5
const INGREDIENT_TOP_LEFT := Vector2(849.4, 331.1)
const INSTRUCTION_PANEL_POSITION := Vector2(12.0, 12.0)
const INSTRUCTION_PANEL_SIZE := Vector2(293.0, 350.0)
const INSTRUCTION_TEXT_POSITION := Vector2(27.0, 22.0)
const INSTRUCTION_TEXT_SIZE := Vector2(239.0, 105.0)
const CONTAINER_PATHS := ["res://features/minigames/final_cooking/assets/ingredients/season_broth/containers/scene3_ginamos_jar.png", "res://features/minigames/final_cooking/assets/ingredients/season_broth/containers/scene3_patis_bottle.png", "res://features/minigames/final_cooking/assets/ingredients/season_broth/containers/scene3_black_pepper_shaker.png"]
const EFFECT_PATHS := ["res://features/minigames/final_cooking/assets/ingredients/season_broth/effects/scene3_ginamos_drop.png", "res://features/minigames/final_cooking/assets/ingredients/season_broth/effects/scene3_patis_stream.png", "res://features/minigames/final_cooking/assets/ingredients/season_broth/effects/scene3_black_pepper_particles.png"]
const NAMES := ["Ginamos", "Patis", "Black Pepper"]
const POUR_SPEEDS := [22.0, 30.0, 20.0]

var seasonings: Array[Dictionary] = []
var requested_index := -1
var selected_index := 0
var current_amount := 0.0
var dragged_index := -1
var pouring := false
var input_locked := false
var rng := RandomNumberGenerator.new()
var ingredient_sprite: Sprite2D
var drag_preview: Sprite2D
var pour_effect: Sprite2D
var previous_button: TextureButton
var next_button: TextureButton
var pour_progress_green: Sprite2D
var lola: SharedDialogue

func _ready() -> void:
	rng.randomize()
	_create_data()
	_create_world()
	_create_instruction_panel()
	_create_navigation_buttons()
	_create_pour_meter()
	_create_lola()
	_request_next_seasoning()
	stage_started.emit()

func _create_data() -> void:
	for index in range(NAMES.size()):
		var minimum := float(rng.randi_range(30, 52))
		seasonings.append({"name": NAMES[index], "container": load(CONTAINER_PATHS[index]), "effect": load(EFFECT_PATHS[index]), "target": Vector2(minimum, minimum + rng.randi_range(14, 22)), "completed": false})

func _create_world() -> void:
	_make_sprite("Background", BACKGROUND, Vector2(576, 324), -20)
	_make_sprite("Burner", BURNER, Vector2(576, 324), -5)
	_make_sprite("Pot", POT, Vector2(591, 234), 0)
	ingredient_sprite = Sprite2D.new()
	ingredient_sprite.name = "SelectedSeasoning"
	ingredient_sprite.z_index = 10
	add_child(ingredient_sprite)
	drag_preview = Sprite2D.new()
	drag_preview.z_index = 30
	drag_preview.scale = Vector2(0.58, 0.58)
	drag_preview.visible = false
	add_child(drag_preview)
	pour_effect = Sprite2D.new()
	pour_effect.scale = Vector2(0.72, 0.72)
	pour_effect.z_index = 14
	pour_effect.visible = false
	add_child(pour_effect)

func _make_sprite(node_name: String, texture: Texture2D, position: Vector2, z: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.position = position
	sprite.z_index = z
	add_child(sprite)
	return sprite

func _create_instruction_panel() -> void:
	var panel := TextureRect.new()
	panel.name = "InstructionPanel"
	panel.texture = INSTRUCTION_PANEL
	panel.position = INSTRUCTION_PANEL_POSITION
	panel.size = INSTRUCTION_PANEL_SIZE
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 40
	add_child(panel)
	var instructions := Label.new()
	instructions.name = "InstructionText"
	instructions.text = "LISTEN TO LOLA.\nPOUR UNTIL THE\nPROGRESS IS GREEN."
	instructions.position = INSTRUCTION_TEXT_POSITION
	instructions.size = INSTRUCTION_TEXT_SIZE
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	instructions.add_theme_font_size_override("font_size", 15)
	instructions.add_theme_color_override("font_color", Color(1.0, 0.91, 0.68))
	instructions.add_theme_color_override("font_shadow_color", Color(0.08, 0.03, 0.01, 1.0))
	instructions.add_theme_constant_override("shadow_offset_x", 1)
	instructions.add_theme_constant_override("shadow_offset_y", 1)
	instructions.add_theme_constant_override("line_spacing", 5)
	panel.add_child(instructions)

func _create_navigation_buttons() -> void:
	previous_button = _create_navigation_button("PreviousSeasoningButton", -1)
	next_button = _create_navigation_button("NextSeasoningButton", 1)

func _create_navigation_button(node_name: String, direction: int) -> TextureButton:
	var button := TextureButton.new()
	button.name = node_name
	button.texture_normal = NAVIGATION_ARROW
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.flip_h = direction < 0
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.position = Vector2(0, INGREDIENT_TOP_LEFT.y + 110)
	button.size = Vector2(42, 48)
	button.z_index = 40
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(_change_selection.bind(direction))
	add_child(button)
	return button

func _create_pour_meter() -> void:
	var meter_top_left := Vector2(369, 250)
	_create_meter_sprite("PourProgressPanel", MIKI_PROGRESS_PANEL, meter_top_left, 40)
	pour_progress_green = _create_meter_sprite("PourProgressGreen", MIKI_PROGRESS_GREEN, meter_top_left, 41)
	pour_progress_green.region_enabled = true
	pour_progress_green.region_rect = Rect2(0, 0, 0, 177)
	_create_meter_sprite("PourProgressFrame", MIKI_PROGRESS_FRAME, meter_top_left, 42)

func _create_meter_sprite(node_name: String, texture: Texture2D, position: Vector2, z: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.position = position
	sprite.centered = false
	sprite.z_index = z
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	return sprite

func _create_lola() -> void:
	lola = LOLA_DIALOGUE.instantiate() as SharedDialogue
	lola.accept_mouse_click = false
	lola.accept_ui_accept = false
	add_child(lola)
	lola.set_character("lola", "neutral")

func _request_next_seasoning() -> void:
	var remaining := _unfinished_indices()
	if remaining.is_empty():
		_finish_stage()
		return
	requested_index = remaining[rng.randi_range(0, remaining.size() - 1)]
	current_amount = 0.0
	if bool(seasonings[selected_index]["completed"]): selected_index = requested_index
	_refresh_selected_ingredient()
	_update_pour_meter()
	_say_lola("Apo, could you add the %s now?" % seasonings[requested_index]["name"], "neutral")

func _change_selection(direction: int) -> void:
	if input_locked or dragged_index >= 0: return
	var available := _unfinished_indices()
	if available.is_empty(): return
	var position := available.find(selected_index)
	selected_index = available[wrapi(position + direction, 0, available.size())]
	play_cooking_sfx("ui_navigate", -8.0, 1.0 + direction * 0.04)
	_refresh_selected_ingredient()

func _refresh_selected_ingredient() -> void:
	var texture: Texture2D = seasonings[selected_index]["container"]
	ingredient_sprite.texture = texture
	ingredient_sprite.position = INGREDIENT_TOP_LEFT + texture.get_size() * 0.5
	ingredient_sprite.visible = true
	previous_button.position = Vector2(INGREDIENT_TOP_LEFT.x - 54, ingredient_sprite.position.y - 24)
	next_button.position = Vector2(INGREDIENT_TOP_LEFT.x + texture.get_size().x - 7, ingredient_sprite.position.y - 24)

func _input(event: InputEvent) -> void:
	if input_locked: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: _press(event.position)
		else: _release(event.position)
	elif event is InputEventMouseMotion and dragged_index >= 0:
		drag_preview.position = event.position
		_set_pouring_state(_inside_pot(event.position))

func _press(position: Vector2) -> void:
	if dragged_index >= 0 or not _on_sprite(ingredient_sprite, position): return
	play_cooking_sfx("item_pickup", -7.0)
	dragged_index = selected_index
	drag_preview.texture = seasonings[selected_index]["container"]
	drag_preview.position = position
	drag_preview.visible = true
	ingredient_sprite.visible = false

func _release(position: Vector2) -> void:
	if dragged_index < 0: return
	var released_over_pot := _inside_pot(position)
	var index := dragged_index
	dragged_index = -1
	pouring = false
	pour_effect.visible = false
	drag_preview.visible = false
	ingredient_sprite.visible = true
	if released_over_pot: _evaluate_pour(index)

func _process(delta: float) -> void:
	if not pouring or dragged_index != requested_index or input_locked: return
	current_amount = minf(100.0, current_amount + float(POUR_SPEEDS[requested_index]) * delta)
	_update_pour_meter()

func _set_pouring_state(inside_pot: bool) -> void:
	var started_pouring := inside_pot and not pouring
	pouring = inside_pot
	pour_effect.visible = inside_pot
	drag_preview.visible = not inside_pot
	if not inside_pot:
		return
	if started_pouring:
		play_cooking_sfx("seasoning_pour", -6.0, randf_range(0.96, 1.04))
	var effect: Texture2D = seasonings[dragged_index]["effect"]
	pour_effect.texture = effect
	pour_effect.position = Vector2(
		DROP_CENTER.x,
		POUR_EFFECT_BOTTOM_Y - effect.get_size().y * pour_effect.scale.y * 0.5
	)

func _update_pour_meter() -> void:
	if pour_progress_green == null or requested_index < 0:
		return
	var target: Vector2 = seasonings[requested_index]["target"]
	pour_progress_green.region_rect = Rect2(0, 0, 414.0 * current_amount / 100.0, 177)
	if current_amount < target.x:
		pour_progress_green.modulate = Color(0.42, 0.72, 1.0)
	elif current_amount <= target.y:
		pour_progress_green.modulate = Color.WHITE
	else:
		pour_progress_green.modulate = Color(1.0, 0.42, 0.35)

func _evaluate_pour(index: int) -> void:
	if index != requested_index:
		play_cooking_sfx("wrong", -5.0)
		_say_lola("That is not the one yet, apo. Please save it for later.", "surprised")
		return
	if current_amount <= 0.0:
		play_cooking_sfx("wrong", -7.0)
		_say_lola("Just a little more, apo.", "concerned")
		return
	var target: Vector2 = seasonings[index]["target"]
	if current_amount < target.x:
		play_cooking_sfx("wrong", -7.0)
		_say_lola("A little more, apo. You can do it.", "concerned")
		return
	if current_amount <= target.y:
		play_cooking_sfx("correct", -4.0)
		_say_lola("Just right, apo. That smells wonderful!", "happy")
		_complete_requested()
		return
	play_cooking_sfx("wrong", -4.0)
	current_amount = 0.0
	_update_pour_meter()
	_say_lola("That was too much, apo. I emptied it so you can measure again.", "concerned")

func _complete_requested() -> void:
	input_locked = true
	seasonings[requested_index]["completed"] = true
	await get_tree().create_timer(1.2).timeout
	input_locked = false
	_request_next_seasoning()

func _finish_stage() -> void:
	input_locked = true
	ingredient_sprite.visible = false
	previous_button.visible = false
	next_button.visible = false
	_say_lola("Beautiful work, apo. Let us crush the chicharon next!", "happy")
	await get_tree().create_timer(1.5).timeout
	complete_stage()

func _unfinished_indices() -> Array[int]:
	var result: Array[int] = []
	for index in range(seasonings.size()):
		if not bool(seasonings[index]["completed"]): result.append(index)
	return result

func _say_lola(text: String, expression: String) -> void:
	if lola != null: lola.say(text, expression, 3.0, "lola")

func _inside_pot(point: Vector2) -> bool:
	var relative := point - DROP_CENTER
	return pow(relative.x / DROP_RADIUS.x, 2) + pow(relative.y / DROP_RADIUS.y, 2) <= 1.0

func _on_sprite(sprite: Sprite2D, point: Vector2) -> bool:
	if not sprite.visible or sprite.texture == null: return false
	var size := sprite.texture.get_size() * sprite.scale.abs()
	return Rect2(sprite.position - size * 0.5, size).has_point(point)
