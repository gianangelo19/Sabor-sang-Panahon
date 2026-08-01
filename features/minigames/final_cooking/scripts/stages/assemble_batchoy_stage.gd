extends "res://features/minigames/final_cooking/scripts/final_cooking_stage.gd"

# Final assembly is deliberately self-contained: the scene only supplies this Control.
const ASSEMBLY_BACKGROUND_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/backgrounds/bg_cooking_station_front.png")
const ASSEMBLY_BOWL_EMPTY_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/ingredients/assemble_batchoy/bowl_states/scene6_bowl_empty.png")
const ASSEMBLY_BOWL_MIKI_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/ingredients/assemble_batchoy/bowl_states/scene6_bowl_with_miki.png")
const ASSEMBLY_BOWL_EGG_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/ingredients/assemble_batchoy/bowl_states/scene6_bowl_with_miki_egg.png")
const ASSEMBLY_BOWL_BROTH_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/ingredients/assemble_batchoy/bowl_states/scene6_bowl_with_miki_egg_broth_meat.png")
const ASSEMBLY_BOWL_ONION_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/ingredients/assemble_batchoy/bowl_states/scene6_bowl_with_green_onions.png")
const ASSEMBLY_BOWL_COMPLETE_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/ingredients/assemble_batchoy/bowl_states/scene6_bowl_complete.png")
const ASSEMBLY_MIKI_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/ingredients/cook_with_miki/containers/scene4_miki_cooked_tray.png")
const ASSEMBLY_EGG_BOWL_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/ingredients/assemble_batchoy/components/egg/scene6_raw_egg_bowl.png")
const ASSEMBLY_RAW_EGG_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/ingredients/assemble_batchoy/components/egg/scene6_raw_egg.png")
const ASSEMBLY_CRACKED_EGG_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/ingredients/assemble_batchoy/components/egg/scene6_cracked_egg.png")
const ASSEMBLY_BROTH_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/cookware/add_to_pot/pot_with_all_ingredients.png")
const ASSEMBLY_ONION_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/ingredients/cutting/containers_cut/green_onions_cut_bowl.png")
const ASSEMBLY_CHICHARON_TEXTURE: Texture2D = preload("res://features/minigames/final_cooking/assets/ingredients/crush_chicharon/containers/scene5_chicharon_crushed_tray.png")
const INSTRUCTION_PANEL_TEXTURE: Texture2D = preload("res://features/minigames/export_templates/instruction_panel.png")
const NAVIGATION_ARROW_TEXTURE: Texture2D = preload("res://features/minigames/snatch_battle/assets/ui/snatch_hand_attack_indicator.png")
const DIALOGUE_SCENE: PackedScene = preload("res://features/minigames/shared/dialogue/shared_dialogue.tscn")

# Editable composition constants.
const ASSEMBLY_SCREEN_CENTER := Vector2(576.0, 324.0)
const ASSEMBLY_BOWL_POSITION := Vector2(576.0, 350.0)
const ASSEMBLY_BOWL_SCALE := Vector2(1.0, 1.0)
const ASSEMBLY_BOWL_DROP_CENTER := Vector2(576.0, 300.0)
const ASSEMBLY_BOWL_DROP_RADIUS := Vector2(205.0, 105.0)
const ASSEMBLY_MIKI_POSITION := Vector2(155.0, 470.0)
const ASSEMBLY_EGG_BOWL_POSITION := Vector2(320.0, 492.0)
const ASSEMBLY_BROTH_POSITION := Vector2(966.0, 392.0)
const ASSEMBLY_GREEN_ONIONS_POSITION := Vector2(836.0, 520.0)
const ASSEMBLY_CHICHARON_POSITION := Vector2(1020.0, 544.0)
const ASSEMBLY_COMPONENT_TOP_LEFT := Vector2(893.5, 372.1)
const ASSEMBLY_MIKI_SCALE := Vector2(1.2, 1.2)
const ASSEMBLY_EGG_BOWL_SCALE := Vector2.ONE
const ASSEMBLY_BROTH_SCALE := Vector2.ONE
const ASSEMBLY_GREEN_ONIONS_SCALE := Vector2.ONE
const ASSEMBLY_CHICHARON_SCALE := Vector2(1.2, 1.2)
const ASSEMBLY_MIKI_ROTATION := 0.0
const ASSEMBLY_EGG_BOWL_ROTATION := 0.0
const ASSEMBLY_BROTH_ROTATION := 0.0
const ASSEMBLY_GREEN_ONIONS_ROTATION := 0.0
const ASSEMBLY_CHICHARON_ROTATION := 0.0
const ASSEMBLY_DRAG_SCALE := Vector2(0.4, 0.4)
const ASSEMBLY_EGG_CRACK_CLICKS := 3
const ASSEMBLY_CRACKED_EGG_DURATION := 0.55
const ASSEMBLY_INSTRUCTION_PANEL_POSITION := Vector2(12.0, 12.0)
const ASSEMBLY_INSTRUCTION_PANEL_SIZE := Vector2(293.0, 350.0)

enum AssemblyPhase { ADD_MIKI, PREPARE_EGG, CRACK_EGG, ADD_BROTH, ADD_GREEN_ONIONS, ADD_CHICHARON, COMPLETE }
enum AssemblyDragType { NONE, MIKI, EGG_BOWL, RAW_EGG, BROTH, GREEN_ONIONS, CHICHARON }

var assembly_phase: int = AssemblyPhase.ADD_MIKI
var assembly_drag_type: int = AssemblyDragType.NONE
var assembly_stage_is_complete := false
var assembly_completion_emitted := false
var assembly_egg_clicks := 0
var assembly_egg_transition_running := false
var assembly_components: Dictionary = {}
var assembly_selected_component: int = AssemblyDragType.MIKI
var assembly_background_sprite: Sprite2D
var assembly_bowl_sprite: Sprite2D
var assembly_drag_preview_sprite: Sprite2D
var assembly_raw_egg_sprite: Sprite2D
var assembly_status_label: Label
var assembly_dialogue: SharedDialogue
var assembly_previous_button: TextureButton
var assembly_next_button: TextureButton

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_assembly_build_stage()
	set_process_input(true)
	stage_started.emit()

func _assembly_build_stage() -> void:
	assembly_background_sprite = _assembly_create_sprite("ASSEMBLY_Background", ASSEMBLY_BACKGROUND_TEXTURE, ASSEMBLY_SCREEN_CENTER, Vector2.ONE, 0.0, -20)
	assembly_bowl_sprite = _assembly_create_sprite("ASSEMBLY_FinalBowl", ASSEMBLY_BOWL_EMPTY_TEXTURE, ASSEMBLY_BOWL_POSITION, ASSEMBLY_BOWL_SCALE, 0.0, 4)
	assembly_drag_preview_sprite = _assembly_create_sprite("ASSEMBLY_DragPreview", ASSEMBLY_MIKI_TEXTURE, Vector2.ZERO, Vector2.ONE, 0.0, 30)
	assembly_drag_preview_sprite.visible = false
	assembly_raw_egg_sprite = _assembly_create_sprite("ASSEMBLY_RawEgg", ASSEMBLY_RAW_EGG_TEXTURE, ASSEMBLY_BOWL_POSITION + Vector2(0, -170), Vector2(0.65, 0.65), 0.0, 20)
	assembly_raw_egg_sprite.visible = false
	_assembly_create_component_data()
	_assembly_create_ui()
	_assembly_create_navigation_buttons()
	_assembly_refresh_components()
	_assembly_update_ui()

func _assembly_create_sprite(assembly_name: String, assembly_texture: Texture2D, assembly_position: Vector2, assembly_scale: Vector2, assembly_rotation: float, assembly_z_index: int) -> Sprite2D:
	var assembly_sprite := Sprite2D.new()
	assembly_sprite.name = assembly_name
	assembly_sprite.texture = assembly_texture
	assembly_sprite.position = assembly_position
	assembly_sprite.scale = assembly_scale
	assembly_sprite.rotation = assembly_rotation
	assembly_sprite.centered = true
	assembly_sprite.z_index = assembly_z_index
	assembly_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(assembly_sprite)
	return assembly_sprite

func _assembly_create_component_data() -> void:
	_assembly_add_component(AssemblyDragType.MIKI, "Miki", ASSEMBLY_MIKI_TEXTURE, ASSEMBLY_MIKI_POSITION, ASSEMBLY_MIKI_SCALE, ASSEMBLY_MIKI_ROTATION, "Miki noodles")
	_assembly_add_component(AssemblyDragType.EGG_BOWL, "EggBowl", ASSEMBLY_EGG_BOWL_TEXTURE, ASSEMBLY_EGG_BOWL_POSITION, ASSEMBLY_EGG_BOWL_SCALE, ASSEMBLY_EGG_BOWL_ROTATION, "Raw egg")
	_assembly_add_component(AssemblyDragType.BROTH, "BrothPot", ASSEMBLY_BROTH_TEXTURE, ASSEMBLY_BROTH_POSITION, ASSEMBLY_BROTH_SCALE, ASSEMBLY_BROTH_ROTATION, "Broth with meat")
	_assembly_add_component(AssemblyDragType.GREEN_ONIONS, "GreenOnions", ASSEMBLY_ONION_TEXTURE, ASSEMBLY_GREEN_ONIONS_POSITION, ASSEMBLY_GREEN_ONIONS_SCALE, ASSEMBLY_GREEN_ONIONS_ROTATION, "Green onions")
	_assembly_add_component(AssemblyDragType.CHICHARON, "Chicharon", ASSEMBLY_CHICHARON_TEXTURE, ASSEMBLY_CHICHARON_POSITION, ASSEMBLY_CHICHARON_SCALE, ASSEMBLY_CHICHARON_ROTATION, "Crushed chicharon")

func _assembly_add_component(assembly_type: int, assembly_name: String, assembly_texture: Texture2D, assembly_position: Vector2, assembly_scale: Vector2, assembly_rotation: float, assembly_title: String) -> void:
	var assembly_sprite := _assembly_create_sprite("ASSEMBLY_" + assembly_name, assembly_texture, assembly_position, assembly_scale, assembly_rotation, 10)
	var assembly_locked_label := Label.new()
	assembly_locked_label.name = "ASSEMBLY_" + assembly_name + "Locked"
	assembly_locked_label.text = assembly_title.to_upper()
	assembly_locked_label.position = assembly_position + Vector2(-42, -18)
	assembly_locked_label.size = Vector2(84, 28)
	assembly_locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	assembly_locked_label.add_theme_font_size_override("font_size", 14)
	assembly_locked_label.add_theme_color_override("font_color", Color(1.0, 0.91, 0.68))
	assembly_locked_label.z_index = 16
	assembly_locked_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(assembly_locked_label)
	assembly_components[assembly_type] = {"sprite": assembly_sprite, "label": assembly_locked_label, "position": assembly_position, "scale": assembly_scale, "rotation": assembly_rotation, "title": assembly_title, "complete": false}

func _assembly_create_ui() -> void:
	var instruction_panel := _assembly_create_texture_panel("AssemblyInstructionPanel", INSTRUCTION_PANEL_TEXTURE, ASSEMBLY_INSTRUCTION_PANEL_POSITION, ASSEMBLY_INSTRUCTION_PANEL_SIZE)
	var instruction_label := _assembly_create_label("InstructionText", Vector2(34, 22), Vector2(225, 105), 18)
	instruction_label.text = "ASSEMBLE THE BATCHOY"
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction_label.add_theme_color_override("font_color", Color(1.0, 0.91, 0.68))
	instruction_panel.add_child(instruction_label)
	assembly_status_label = _assembly_create_label("ASSEMBLY_Status", Vector2(300, 570), Vector2(550, 42), 20)
	assembly_status_label.add_theme_color_override("font_color", Color(1.0, 0.91, 0.57))
	assembly_dialogue = DIALOGUE_SCENE.instantiate() as SharedDialogue
	assembly_dialogue.name = "LolaDialogue"
	assembly_dialogue.accept_mouse_click = false
	assembly_dialogue.accept_ui_accept = false
	add_child(assembly_dialogue)
	assembly_dialogue.set_character("lola", "neutral")

func _assembly_create_texture_panel(assembly_name: String, assembly_texture: Texture2D, assembly_position: Vector2, assembly_size: Vector2) -> TextureRect:
	var assembly_panel := TextureRect.new()
	assembly_panel.name = assembly_name
	assembly_panel.texture = assembly_texture
	assembly_panel.position = assembly_position
	assembly_panel.size = assembly_size
	assembly_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	assembly_panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	assembly_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	assembly_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	assembly_panel.z_index = 40
	add_child(assembly_panel)
	return assembly_panel

func _assembly_create_navigation_buttons() -> void:
	assembly_previous_button = _assembly_create_navigation_button("PreviousComponentButton", -1)
	assembly_next_button = _assembly_create_navigation_button("NextComponentButton", 1)

func _assembly_create_navigation_button(assembly_name: String, assembly_direction: int) -> TextureButton:
	var assembly_button := TextureButton.new()
	assembly_button.name = assembly_name
	assembly_button.texture_normal = NAVIGATION_ARROW_TEXTURE
	assembly_button.ignore_texture_size = true
	assembly_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	assembly_button.flip_h = assembly_direction < 0
	assembly_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	assembly_button.size = Vector2(42, 48)
	assembly_button.z_index = 40
	assembly_button.focus_mode = Control.FOCUS_NONE
	assembly_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	assembly_button.pressed.connect(_assembly_change_selection.bind(assembly_direction))
	add_child(assembly_button)
	return assembly_button

func _assembly_change_selection(assembly_direction: int) -> void:
	if assembly_drag_type != AssemblyDragType.NONE or assembly_egg_transition_running or assembly_phase == AssemblyPhase.CRACK_EGG:
		return
	var assembly_available := _assembly_unfinished_component_types()
	if assembly_available.is_empty():
		return
	var assembly_index := assembly_available.find(assembly_selected_component)
	assembly_selected_component = assembly_available[wrapi(assembly_index + assembly_direction, 0, assembly_available.size())]
	play_cooking_sfx("ui_navigate", -8.0, 1.0 + assembly_direction * 0.04)
	_assembly_refresh_components()

func _assembly_unfinished_component_types() -> Array[int]:
	var assembly_available: Array[int] = []
	for assembly_type_variant in assembly_components.keys():
		var assembly_type := int(assembly_type_variant)
		var assembly_component: Dictionary = assembly_components[assembly_type]
		if not bool(assembly_component["complete"]):
			assembly_available.append(assembly_type)
	assembly_available.sort()
	return assembly_available

func _assembly_create_label(assembly_name: String, assembly_position: Vector2, assembly_size: Vector2, assembly_font_size: int) -> Label:
	var assembly_label := Label.new()
	assembly_label.name = assembly_name
	assembly_label.position = assembly_position
	assembly_label.size = assembly_size
	assembly_label.z_index = 40
	assembly_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	assembly_label.add_theme_font_size_override("font_size", assembly_font_size)
	assembly_label.add_theme_color_override("font_color", Color.WHITE)
	return assembly_label

func _input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		return
	if assembly_stage_is_complete or assembly_egg_transition_running:
		return
	if event is InputEventMouseMotion and assembly_drag_type != AssemblyDragType.NONE:
		assembly_drag_preview_sprite.position = (event as InputEventMouseMotion).position
		return
	if event is InputEventMouseButton:
		var assembly_mouse_event := event as InputEventMouseButton
		if assembly_mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if assembly_mouse_event.pressed:
			_assembly_handle_mouse_pressed(assembly_mouse_event.position)
		elif assembly_drag_type != AssemblyDragType.NONE:
			_assembly_finish_drag(assembly_mouse_event.position)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()

func _assembly_handle_mouse_pressed(assembly_position: Vector2) -> void:
	if assembly_phase == AssemblyPhase.CRACK_EGG:
		if _assembly_point_on_sprite(assembly_raw_egg_sprite, assembly_position):
			_assembly_process_egg_click()
		return
	for assembly_type_variant in assembly_components.keys():
		var assembly_type := int(assembly_type_variant)
		var assembly_component: Dictionary = assembly_components[assembly_type]
		if _assembly_point_on_sprite(assembly_component["sprite"] as Sprite2D, assembly_position):
			_assembly_start_drag(assembly_type, assembly_position)
			return

func _assembly_required_drag_type() -> int:
	match assembly_phase:
		AssemblyPhase.ADD_MIKI: return AssemblyDragType.MIKI
		AssemblyPhase.PREPARE_EGG: return AssemblyDragType.EGG_BOWL
		AssemblyPhase.ADD_BROTH: return AssemblyDragType.BROTH
		AssemblyPhase.ADD_GREEN_ONIONS: return AssemblyDragType.GREEN_ONIONS
		AssemblyPhase.ADD_CHICHARON: return AssemblyDragType.CHICHARON
	return AssemblyDragType.NONE

func _assembly_start_drag(assembly_type: int, assembly_position: Vector2) -> void:
	if assembly_drag_type != AssemblyDragType.NONE:
		return
	play_cooking_sfx("item_pickup", -7.0)
	var assembly_component: Dictionary = assembly_components[assembly_type]
	var assembly_sprite := assembly_component["sprite"] as Sprite2D
	assembly_drag_type = assembly_type
	assembly_drag_preview_sprite.texture = assembly_sprite.texture
	assembly_drag_preview_sprite.position = assembly_position
	assembly_drag_preview_sprite.scale = ASSEMBLY_DRAG_SCALE
	assembly_drag_preview_sprite.rotation = float(assembly_component["rotation"])
	assembly_drag_preview_sprite.visible = true
	assembly_sprite.visible = false
	(assembly_component["label"] as Label).visible = false

func _assembly_finish_drag(assembly_position: Vector2) -> void:
	var assembly_finished_type := assembly_drag_type
	assembly_drag_type = AssemblyDragType.NONE
	assembly_drag_preview_sprite.visible = false
	if not _assembly_inside_bowl_ellipse(assembly_position):
		play_cooking_sfx("wrong", -7.0)
		_assembly_restore_component(assembly_finished_type)
		_assembly_show_status(_assembly_invalid_drop_message(assembly_finished_type))
		return
	if assembly_finished_type != _assembly_required_drag_type():
		play_cooking_sfx("wrong", -5.0)
		_assembly_restore_component(assembly_finished_type)
		_assembly_show_status("NOT YET — FOLLOW LOLA'S REQUEST")
		_assembly_say_lola("Not that one yet, apo. Let us add the %s first." % _assembly_current_request_name(), "concerned")
		return
	_assembly_accept_component(assembly_finished_type)

func _assembly_invalid_drop_message(assembly_type: int) -> String:
	match assembly_type:
		AssemblyDragType.MIKI: return "DROP THE MIKI INTO THE SERVING BOWL"
		AssemblyDragType.EGG_BOWL: return "BRING THE EGG BOWL NEAR THE SERVING BOWL"
		AssemblyDragType.BROTH: return "POUR THE BROTH INTO THE SERVING BOWL"
		AssemblyDragType.GREEN_ONIONS: return "SPRINKLE THE GREEN ONIONS OVER THE BOWL"
		AssemblyDragType.CHICHARON: return "ADD THE CHICHARON AS THE FINAL TOPPING"
	return "DROP THE INGREDIENT INTO THE BOWL"

func _assembly_restore_component(assembly_type: int) -> void:
	var assembly_component: Dictionary = assembly_components[assembly_type]
	var assembly_sprite := assembly_component["sprite"] as Sprite2D
	assembly_sprite.position = assembly_component["position"] as Vector2
	assembly_sprite.scale = assembly_component["scale"] as Vector2
	assembly_sprite.rotation = float(assembly_component["rotation"])
	assembly_sprite.visible = true
	_assembly_refresh_components()

func _assembly_accept_component(assembly_type: int) -> void:
	play_cooking_sfx("bowl_place", -4.0, randf_range(0.96, 1.04))
	var assembly_component: Dictionary = assembly_components[assembly_type]
	assembly_component["complete"] = true
	assembly_components[assembly_type] = assembly_component
	(assembly_component["sprite"] as Sprite2D).visible = false
	if assembly_type == AssemblyDragType.MIKI:
		_assembly_swap_bowl_texture(ASSEMBLY_BOWL_MIKI_TEXTURE)
		assembly_phase = AssemblyPhase.PREPARE_EGG
		_assembly_pulse_bowl()
	elif assembly_type == AssemblyDragType.EGG_BOWL:
		assembly_phase = AssemblyPhase.CRACK_EGG
		assembly_raw_egg_sprite.position = ASSEMBLY_BOWL_POSITION + Vector2(0, -160)
		assembly_raw_egg_sprite.texture = ASSEMBLY_RAW_EGG_TEXTURE
		assembly_raw_egg_sprite.modulate = Color.WHITE
		assembly_raw_egg_sprite.visible = true
	elif assembly_type == AssemblyDragType.BROTH:
		_assembly_swap_bowl_texture(ASSEMBLY_BOWL_BROTH_TEXTURE)
		assembly_phase = AssemblyPhase.ADD_GREEN_ONIONS
		_assembly_pulse_bowl()
		_assembly_create_particles(Color(0.92, 0.92, 0.92, 0.75), 7)
	elif assembly_type == AssemblyDragType.GREEN_ONIONS:
		_assembly_swap_bowl_texture(ASSEMBLY_BOWL_ONION_TEXTURE)
		assembly_phase = AssemblyPhase.ADD_CHICHARON
		_assembly_pulse_bowl()
		_assembly_create_particles(Color(0.35, 0.90, 0.32, 0.9), 10)
	elif assembly_type == AssemblyDragType.CHICHARON:
		_assembly_swap_bowl_texture(ASSEMBLY_BOWL_COMPLETE_TEXTURE)
		assembly_phase = AssemblyPhase.COMPLETE
		assembly_stage_is_complete = true
		_assembly_final_celebration()
	_assembly_refresh_components()
	_assembly_show_status("CORRECT — %s ADDED" % str(assembly_component["title"]).to_upper())
	_assembly_say_lola("Perfect, apo. That is exactly what Lola asked for.", "happy")
	# End on the next actionable instruction (especially the egg-cracking step)
	# instead of leaving the player on the generic confirmation message.
	_assembly_update_ui()

func _assembly_process_egg_click() -> void:
	if assembly_phase != AssemblyPhase.CRACK_EGG or assembly_drag_type != AssemblyDragType.NONE:
		return
	assembly_egg_clicks += 1
	play_cooking_sfx("egg_crack", -4.0, 0.92 + assembly_egg_clicks * 0.05)
	_assembly_show_status("CRACK: %d/%d" % [assembly_egg_clicks, ASSEMBLY_EGG_CRACK_CLICKS])
	var assembly_tween := create_tween()
	assembly_tween.tween_property(assembly_raw_egg_sprite, "scale", Vector2(0.75, 0.55), 0.07)
	assembly_tween.parallel().tween_property(assembly_raw_egg_sprite, "rotation", deg_to_rad(-8.0), 0.07)
	assembly_tween.tween_property(assembly_raw_egg_sprite, "scale", Vector2(0.65, 0.65), 0.11)
	assembly_tween.parallel().tween_property(assembly_raw_egg_sprite, "rotation", 0.0, 0.11)
	if assembly_egg_clicks >= ASSEMBLY_EGG_CRACK_CLICKS:
		_assembly_begin_cracked_egg_transition()

func _assembly_begin_cracked_egg_transition() -> void:
	assembly_egg_transition_running = true
	assembly_raw_egg_sprite.texture = ASSEMBLY_CRACKED_EGG_TEXTURE
	assembly_raw_egg_sprite.position = ASSEMBLY_BOWL_POSITION + Vector2(0, -155)
	var assembly_tween := create_tween()
	assembly_tween.set_trans(Tween.TRANS_QUAD)
	assembly_tween.set_ease(Tween.EASE_IN)
	assembly_tween.parallel().tween_property(assembly_raw_egg_sprite, "position", ASSEMBLY_BOWL_POSITION + Vector2(0, -55), ASSEMBLY_CRACKED_EGG_DURATION)
	assembly_tween.parallel().tween_property(assembly_raw_egg_sprite, "modulate:a", 0.0, ASSEMBLY_CRACKED_EGG_DURATION)
	assembly_tween.tween_callback(_assembly_finish_egg_transition)

func _assembly_finish_egg_transition() -> void:
	assembly_raw_egg_sprite.visible = false
	assembly_raw_egg_sprite.modulate = Color.WHITE
	_assembly_swap_bowl_texture(ASSEMBLY_BOWL_EGG_TEXTURE)
	assembly_phase = AssemblyPhase.ADD_BROTH
	assembly_egg_transition_running = false
	_assembly_pulse_bowl()
	_assembly_show_status("EGG CRACKED — WELL DONE")
	_assembly_say_lola("Beautifully cracked. Now the hot broth and meat.", "happy")
	_assembly_refresh_components()
	_assembly_update_ui()

func _assembly_swap_bowl_texture(assembly_texture: Texture2D) -> void:
	assembly_bowl_sprite.texture = assembly_texture
	assembly_bowl_sprite.position = ASSEMBLY_BOWL_POSITION
	assembly_bowl_sprite.scale = ASSEMBLY_BOWL_SCALE
	assembly_bowl_sprite.rotation = 0.0

func _assembly_refresh_components() -> void:
	var assembly_active := _assembly_required_drag_type()
	var assembly_available := _assembly_unfinished_component_types()
	if not assembly_available.is_empty() and not assembly_available.has(assembly_selected_component):
		assembly_selected_component = assembly_available[0]
	for assembly_type_variant in assembly_components.keys():
		var assembly_type := int(assembly_type_variant)
		var assembly_component: Dictionary = assembly_components[assembly_type]
		var assembly_sprite := assembly_component["sprite"] as Sprite2D
		var assembly_label := assembly_component["label"] as Label
		var assembly_complete := bool(assembly_component["complete"])
		if assembly_complete:
			assembly_sprite.visible = false
			assembly_label.visible = false
		else:
			var assembly_selected := assembly_type == assembly_selected_component
			assembly_sprite.visible = assembly_selected and assembly_type != assembly_drag_type
			var assembly_display_scale := assembly_component["scale"] as Vector2
			assembly_sprite.scale = assembly_display_scale
			assembly_sprite.position = ASSEMBLY_COMPONENT_TOP_LEFT + assembly_sprite.texture.get_size() * assembly_display_scale * 0.5
			var assembly_unlocked := assembly_type == assembly_active
			assembly_sprite.modulate = Color.WHITE if assembly_unlocked else Color(0.68, 0.68, 0.68, 0.94)
			assembly_label.position = assembly_sprite.position + Vector2(-80, -assembly_sprite.texture.get_size().y * assembly_display_scale.y * 0.5 - 28)
			assembly_label.visible = assembly_selected and assembly_type != assembly_drag_type
			assembly_label.text = assembly_component["title"].to_upper() + ("  • NEXT" if assembly_unlocked else "")
	if assembly_previous_button != null:
		var assembly_can_navigate := assembly_available.size() > 1 and assembly_phase != AssemblyPhase.CRACK_EGG and not assembly_stage_is_complete
		assembly_previous_button.visible = assembly_can_navigate
		assembly_next_button.visible = assembly_can_navigate
		assembly_previous_button.position = Vector2(797, 460)
		assembly_next_button.position = Vector2(1090, 460)

func _assembly_update_ui() -> void:
	var assembly_lines := ["Miki noodles", "Raw egg", "Broth with meat", "Green onions", "Crushed chicharon"]
	var assembly_done := [assembly_phase != AssemblyPhase.ADD_MIKI, assembly_phase in [AssemblyPhase.ADD_BROTH, AssemblyPhase.ADD_GREEN_ONIONS, AssemblyPhase.ADD_CHICHARON, AssemblyPhase.COMPLETE], assembly_phase in [AssemblyPhase.ADD_GREEN_ONIONS, AssemblyPhase.ADD_CHICHARON, AssemblyPhase.COMPLETE], assembly_phase in [AssemblyPhase.ADD_CHICHARON, AssemblyPhase.COMPLETE], assembly_phase == AssemblyPhase.COMPLETE]
	var assembly_current := clampi(assembly_phase, 0, 5)
	var assembly_text := "ASSEMBLE THE BATCHOY\n\n"
	for assembly_index in range(5):
		var assembly_prefix := "✓ " if assembly_done[assembly_index] else ("→ " if assembly_index == assembly_current else "  ")
		assembly_text += assembly_prefix + assembly_lines[assembly_index] + ("\n" if assembly_index < 4 else "")
	match assembly_phase:
		AssemblyPhase.ADD_MIKI:
			_assembly_show_status("DRAG THE COOKED MIKI INTO THE BOWL")
			_assembly_say_lola("Start with the noodles. They will hold everything together.", "neutral")
		AssemblyPhase.PREPARE_EGG:
			_assembly_show_status("DRAG THE EGG BOWL NEAR THE SERVING BOWL")
			_assembly_say_lola("Bring the egg bowl over, then crack the egg right into the bowl.", "neutral")
		AssemblyPhase.CRACK_EGG:
			_assembly_show_status("CLICK THE EGG TO CRACK IT")
			_assembly_say_lola("Tap the egg gently, apo. %d more crack%s." % [ASSEMBLY_EGG_CRACK_CLICKS - assembly_egg_clicks, "s" if ASSEMBLY_EGG_CRACK_CLICKS - assembly_egg_clicks != 1 else ""], "surprised")
		AssemblyPhase.ADD_BROTH:
			_assembly_show_status("DRAG THE HOT BROTH TO THE BOWL")
			_assembly_say_lola("Lovely. Now pour in the hot broth and meat.", "happy")
		AssemblyPhase.ADD_GREEN_ONIONS:
			_assembly_show_status("ADD THE GREEN ONIONS")
			_assembly_say_lola("A little green onion will brighten the bowl.", "happy")
		AssemblyPhase.ADD_CHICHARON:
			_assembly_show_status("ADD THE CRUSHED CHICHARON")
			_assembly_say_lola("Finish it with the crushed chicharon, apo.", "happy")
		AssemblyPhase.COMPLETE:
			_assembly_show_status("BATCHOY COMPLETE!")
			_assembly_say_lola("There it is... the taste I remember. You made it beautifully.", "happy")

func _assembly_show_status(assembly_message: String) -> void:
	assembly_status_label.text = assembly_message

func _assembly_current_request_name() -> String:
	match assembly_phase:
		AssemblyPhase.ADD_MIKI: return "Miki noodles"
		AssemblyPhase.PREPARE_EGG: return "Raw egg"
		AssemblyPhase.CRACK_EGG: return "Crack the egg"
		AssemblyPhase.ADD_BROTH: return "Broth with meat"
		AssemblyPhase.ADD_GREEN_ONIONS: return "Green onions"
		AssemblyPhase.ADD_CHICHARON: return "Crushed chicharon"
	return "Batchoy complete"

func _assembly_say_lola(assembly_text: String, assembly_expression: String) -> void:
	if assembly_dialogue != null:
		assembly_dialogue.say(assembly_text, assembly_expression, 3.0, "lola")

func _assembly_pulse_bowl() -> void:
	assembly_bowl_sprite.position = ASSEMBLY_BOWL_POSITION
	assembly_bowl_sprite.scale = ASSEMBLY_BOWL_SCALE
	var assembly_tween := create_tween()
	assembly_tween.tween_property(assembly_bowl_sprite, "scale", ASSEMBLY_BOWL_SCALE * 1.08, 0.12)
	assembly_tween.tween_property(assembly_bowl_sprite, "scale", ASSEMBLY_BOWL_SCALE, 0.16)

func _assembly_create_particles(assembly_color: Color, assembly_count: int) -> void:
	for assembly_index in range(assembly_count):
		var assembly_dot := Polygon2D.new()
		assembly_dot.polygon = PackedVector2Array([Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3)])
		assembly_dot.color = assembly_color
		assembly_dot.position = ASSEMBLY_BOWL_POSITION + Vector2(float((assembly_index * 31) % 150 - 75), -20.0)
		assembly_dot.z_index = 25
		add_child(assembly_dot)
		var assembly_tween := create_tween()
		assembly_tween.parallel().tween_property(assembly_dot, "position:y", assembly_dot.position.y - 35.0 - float(assembly_index % 3) * 12.0, 0.45)
		assembly_tween.parallel().tween_property(assembly_dot, "modulate:a", 0.0, 0.45)
		assembly_tween.tween_callback(assembly_dot.queue_free)

func _assembly_final_celebration() -> void:
	_assembly_create_particles(Color(1.0, 0.82, 0.28, 0.95), 18)
	var assembly_tween := create_tween()
	assembly_tween.tween_property(assembly_bowl_sprite, "position", ASSEMBLY_BOWL_POSITION + Vector2(0, -14), 0.18)
	assembly_tween.parallel().tween_property(assembly_bowl_sprite, "scale", ASSEMBLY_BOWL_SCALE * 1.13, 0.18)
	assembly_tween.tween_property(assembly_bowl_sprite, "position", ASSEMBLY_BOWL_POSITION, 0.25)
	assembly_tween.parallel().tween_property(assembly_bowl_sprite, "scale", ASSEMBLY_BOWL_SCALE, 0.25)
	assembly_tween.tween_callback(_assembly_show_continue_button)

func _assembly_show_continue_button() -> void:
	_assembly_on_continue_pressed()

func _assembly_inside_bowl_ellipse(assembly_point: Vector2) -> bool:
	var assembly_offset := assembly_point - ASSEMBLY_BOWL_DROP_CENTER
	return assembly_offset.x * assembly_offset.x / (ASSEMBLY_BOWL_DROP_RADIUS.x * ASSEMBLY_BOWL_DROP_RADIUS.x) + assembly_offset.y * assembly_offset.y / (ASSEMBLY_BOWL_DROP_RADIUS.y * ASSEMBLY_BOWL_DROP_RADIUS.y) <= 1.0

func _assembly_point_on_sprite(assembly_sprite: Sprite2D, assembly_point: Vector2) -> bool:
	if assembly_sprite == null or not assembly_sprite.visible or assembly_sprite.texture == null:
		return false
	var assembly_local := assembly_sprite.to_local(assembly_point)
	var assembly_size := assembly_sprite.texture.get_size() * 0.5
	return Rect2(-assembly_size, assembly_size * 2.0).has_point(assembly_local)

func _assembly_on_continue_pressed() -> void:
	if not assembly_stage_is_complete or assembly_completion_emitted:
		return
	assembly_completion_emitted = true
	set_process_input(false)
	stage_completed.emit()
