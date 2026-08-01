extends "res://features/minigames/final_cooking/scripts/final_cooking_stage.gd"


const BACKGROUND_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/backgrounds/bg_prep_station_top.png")
const BOARD_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/cookware/cutting/cutting_board.png")
const WHOLE_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/ingredients/crush_chicharon/chicharon/scene5_chicharon_whole_pile.png")
const CRUSH_1_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/ingredients/crush_chicharon/chicharon/scene5_chicharon_crush_1.png")
const CRUSH_2_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/ingredients/crush_chicharon/chicharon/scene5_chicharon_crush_2.png")
const CRUSH_3_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/ingredients/crush_chicharon/chicharon/scene5_chicharon_crush_3.png")
const POWDER_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/ingredients/crush_chicharon/chicharon/scene5_chicharon_overcrushed.png")
const DIALOGUE_SCENE: PackedScene = preload("res://features/minigames/shared/dialogue/shared_dialogue.tscn")
const INSTRUCTION_PANEL_TEXTURE: Texture2D = preload("res://features/minigames/export_templates/instruction_panel.png")
const FINISH_BUTTON_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/ui/crush_chicharon/finish_button.png")
const UI_FONT: Font = preload("res://features/minigames/shared/fonts/VCR_OSD_MONO_1.001.ttf")

const PERFECT_CLICK_MIN := 9
const PERFECT_CLICK_MAX := 12
const PERFECT_RANGE_WIDTH := 2
const PILE_POSITION := Vector2(565.0, 350.0)
const BOARD_POSITION := Vector2(576.0, 338.0)
const UI_Z := 30
const INSTRUCTION_PANEL_POSITION := Vector2(12.0, 12.0)
const INSTRUCTION_PANEL_SIZE := Vector2(293.0, 350.0)
const INSTRUCTION_TEXT_POSITION := Vector2(27.0, 22.0)
const INSTRUCTION_TEXT_SIZE := Vector2(239.0, 105.0)

var rng := RandomNumberGenerator.new()
var perfect_start := PERFECT_CLICK_MIN
var perfect_end := PERFECT_CLICK_MIN + PERFECT_RANGE_WIDTH - 1
var crush_count := 0
var completed := false
var pile: Sprite2D
var feedback_label: Label
var confirm_button: TextureButton
var impact_tween: Tween
var dialogue: SharedDialogue


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rng.randomize()
	perfect_start = rng.randi_range(PERFECT_CLICK_MIN, PERFECT_CLICK_MAX)
	perfect_end = perfect_start + PERFECT_RANGE_WIDTH - 1
	_build_stage()
	stage_started.emit()


func _build_stage() -> void:
	_add_sprite("Background", BACKGROUND_TEXTURE, Vector2(576, 324), Vector2.ONE, -10)
	_add_sprite("CuttingBoard", BOARD_TEXTURE, BOARD_POSITION, Vector2.ONE, 0)
	pile = _add_sprite("ChicharonPile", WHOLE_TEXTURE, PILE_POSITION, Vector2.ONE, 5)

	_create_dialogue()
	_create_instruction_panel()
	feedback_label = _create_label("Feedback", Vector2(310, 554), Vector2(530, 38), 20)
	feedback_label.add_theme_color_override("font_color", Color(1.0, 0.91, 0.58))
	feedback_label.text = "CLICK THE CHICHARON TO CRUSH IT"

	confirm_button = TextureButton.new()
	confirm_button.name = "ConfirmButton"
	confirm_button.texture_normal = FINISH_BUTTON_TEXTURE
	confirm_button.ignore_texture_size = true
	confirm_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	confirm_button.position = Vector2(882, 535)
	confirm_button.size = FINISH_BUTTON_TEXTURE.get_size()
	confirm_button.z_index = UI_Z
	confirm_button.focus_mode = Control.FOCUS_NONE
	confirm_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	confirm_button.disabled = true
	confirm_button.tooltip_text = "Crush the chicharon first, then confirm its size."
	confirm_button.pressed.connect(_on_confirm_pressed)
	add_child(confirm_button)
	_say_lola("Crush the chicharon until it is fine, but not powder.")


func _add_sprite(node_name: String, texture: Texture2D, sprite_position: Vector2, sprite_scale: Vector2, z_order: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.position = sprite_position
	sprite.scale = sprite_scale
	sprite.z_index = z_order
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	return sprite


func _create_dialogue() -> void:
	dialogue = DIALOGUE_SCENE.instantiate() as SharedDialogue
	dialogue.name = "SharedDialogue"
	dialogue.accept_mouse_click = false
	dialogue.accept_ui_accept = false
	add_child(dialogue)
	dialogue.set_character("lola", "neutral")


func _create_instruction_panel() -> void:
	var instruction_panel := TextureRect.new()
	instruction_panel.name = "InstructionPanel"
	instruction_panel.texture = INSTRUCTION_PANEL_TEXTURE
	instruction_panel.position = INSTRUCTION_PANEL_POSITION
	instruction_panel.size = INSTRUCTION_PANEL_SIZE
	instruction_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	instruction_panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	instruction_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	instruction_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	instruction_panel.z_index = UI_Z
	add_child(instruction_panel)

	var instructions := Label.new()
	instructions.name = "InstructionText"
	instructions.text = "CLICK THE CHICHARON.\nCONFIRM BEFORE IT\nTURNS TO POWDER."
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


func _create_label(node_name: String, label_position: Vector2, label_size: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = label_position
	label.size = label_size
	label.z_index = UI_Z
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label


func _input(event: InputEvent) -> void:
	if completed:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if _button_contains_point(mouse_event.position):
				return
			if _point_on_sprite(pile, mouse_event.position):
				_crush()


func _crush() -> void:
	crush_count += 1
	play_cooking_sfx("chicharon_crush", -5.0, randf_range(0.91, 1.08))
	confirm_button.disabled = false
	pile.texture = _texture_for_click_count()
	_play_impact()
	if crush_count > perfect_end:
		feedback_label.text = "POWDERED — YOU CRUSHED PAST THE IDEAL SIZE"
		_say_lola("Easy, apo — it is turning to powder.", "angry")
	elif crush_count >= perfect_start:
		feedback_label.text = "IDEAL SIZE — CONFIRM WHEN READY"
		_say_lola("That is just right. Lovely work!", "happy")
	else:
		feedback_label.text = "TOO LARGE — KEEP CRUSHING"
		_say_lola("A little smaller, apo.", "concerned")


func _on_confirm_pressed() -> void:
	if crush_count == 0:
		return
	if crush_count < perfect_start:
		play_cooking_sfx("wrong", -5.0)
		feedback_label.text = "TOO LARGE — THAT COUNTS AS A MISTAKE"
		_say_lola("Not quite yet, apo. Crush it a little more.", "concerned")
		return
	if crush_count > perfect_end:
		play_cooking_sfx("wrong", -4.0)
		_reset_overcrushed_pile()
		return

	completed = true
	play_cooking_sfx("correct", -3.0)
	confirm_button.disabled = true
	pile.texture = CRUSH_3_TEXTURE
	feedback_label.text = "PERFECT! ADDING IT TO THE BATCHOY..."
	_say_lola("Perfect texture, apo! Let us finish the bowl.", "happy")
	var finish_tween := create_tween()
	finish_tween.tween_interval(0.7)
	finish_tween.tween_callback(_complete_stage)


func _reset_overcrushed_pile() -> void:
	crush_count = 0
	pile.texture = WHOLE_TEXTURE
	pile.scale = Vector2.ONE
	pile.rotation = 0.0
	confirm_button.disabled = true
	feedback_label.text = "TOO FINE — FRESH PILE READY, TRY AGAIN"
	_say_lola("That became powder, apo. Here is a fresh pile to try again.", "concerned")


func _complete_stage() -> void:
	set_process_input(false)
	stage_completed.emit()


func _texture_for_click_count() -> Texture2D:
	if crush_count > perfect_end:
		return POWDER_TEXTURE
	if crush_count >= perfect_start:
		return CRUSH_3_TEXTURE
	var first_step := maxi(1, floori(float(perfect_start) / 3.0))
	var second_step := maxi(first_step + 1, floori(float(perfect_start) * 2.0 / 3.0))
	if crush_count >= second_step:
		return CRUSH_2_TEXTURE
	if crush_count >= first_step:
		return CRUSH_1_TEXTURE
	return WHOLE_TEXTURE


func _say_lola(
	text: String,
	expression: String = "neutral",
	auto_hide: float = 3.2
) -> void:
	if dialogue != null:
		dialogue.say(text, expression, auto_hide, "lola")


func _play_impact() -> void:
	if impact_tween != null:
		impact_tween.kill()
	pile.scale = Vector2.ONE
	pile.rotation = 0.0
	impact_tween = create_tween()
	impact_tween.set_trans(Tween.TRANS_QUAD)
	impact_tween.tween_property(pile, "scale", Vector2(0.89, 0.84), 0.06)
	impact_tween.parallel().tween_property(pile, "rotation", rng.randf_range(-0.05, 0.05), 0.06)
	impact_tween.tween_property(pile, "scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_BACK)
	impact_tween.parallel().tween_property(pile, "rotation", 0.0, 0.13)


func _button_contains_point(point: Vector2) -> bool:
	return Rect2(confirm_button.position, confirm_button.size).has_point(point)


func _point_on_sprite(sprite: Sprite2D, point: Vector2) -> bool:
	if sprite == null or sprite.texture == null or not sprite.visible:
		return false
	var local_point := sprite.to_local(point) + sprite.texture.get_size() * 0.5
	return Rect2(Vector2.ZERO, sprite.texture.get_size()).has_point(local_point)
