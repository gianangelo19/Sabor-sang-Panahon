extends "res://features/minigames/final_cooking/scripts/final_cooking_stage.gd"

const DIALOGUE_SCENE := preload("res://features/minigames/shared/dialogue/shared_dialogue.tscn")
const INSTRUCTION_PANEL_TEXTURE := preload("res://features/minigames/export_templates/instruction_panel.png")
const UI_FONT := preload("res://features/minigames/shared/fonts/VCR_OSD_MONO_1.001.ttf")
const MIKI_PROGRESS_PANEL := preload("res://features/minigames/miki_noodle_crank/assets/ui/miki_progress_panel.png")
const MIKI_PROGRESS_GREEN := preload("res://features/minigames/miki_noodle_crank/assets/ui/miki_progress_green.png")
const MIKI_PROGRESS_FRAME := preload("res://features/minigames/miki_noodle_crank/assets/ui/miki_progress_frame.png")

const MIKI_BACKGROUND_PATH := "res://features/minigames/final_cooking/assets/backgrounds/bg_cooking_station_front.png"
const MIKI_BURNER_PATH := "res://features/minigames/final_cooking/assets/cookware/add_to_pot/burner.png"
const MIKI_BURNER_KNOB_PATH := "res://features/minigames/final_cooking/assets/cookware/add_to_pot/burner_knob.png"
const MIKI_WATER_POT_PATH := "res://features/minigames/final_cooking/assets/cookware/add_to_pot/pot_with_water.png"
const MIKI_EMPTY_TRAY_PATH := "res://features/minigames/final_cooking/assets/ingredients/cook_with_miki/containers/tray_empty.png"
const MIKI_UNCOOKED_TRAY_PATH := "res://features/minigames/final_cooking/assets/ingredients/cook_with_miki/containers/scene4_miki_uncooked.png"
const MIKI_COOKED_TRAY_PATH := "res://features/minigames/final_cooking/assets/ingredients/cook_with_miki/containers/scene4_miki_cooked_tray.png"
const MIKI_OVERCOOKED_TRAY_PATH := "res://features/minigames/final_cooking/assets/ingredients/cook_with_miki/containers/scene4_miki_overcooked_tray.png"
const MIKI_COOKING_POT_PATH := "res://features/minigames/final_cooking/assets/ingredients/cook_with_miki/noodles/scene4_miki_cooking.png"
const MIKI_COOKED_POT_PATH := "res://features/minigames/final_cooking/assets/ingredients/cook_with_miki/noodles/scene4_miki_cooked.png"
const MIKI_OVERCOOKED_POT_PATH := "res://features/minigames/final_cooking/assets/ingredients/cook_with_miki/noodles/scene4_miki_overcooked.png"

const MIKI_SCREEN_CENTER := Vector2(576.0, 324.0)
const MIKI_BURNER_POSITION := Vector2(576.0, 324.0)
const MIKI_POT_POSITION := Vector2(591.0, 234.0)
const MIKI_KNOB_POSITION := Vector2(576.0, 580.0)
const MIKI_TRAY_TOP_LEFT := Vector2(876.7, 406.6)
const MIKI_TRAY_ASSET_SIZE := Vector2(450.0, 265.0)
const MIKI_TRAY_POSITION := MIKI_TRAY_TOP_LEFT + MIKI_TRAY_ASSET_SIZE * 0.5
const MIKI_POT_DROP_CENTER := Vector2(591.0, 150.0)
const MIKI_POT_DROP_RADIUS := Vector2(190.0, 95.0)
const MIKI_REQUIRED_STIR_ROTATIONS := 2.75
const MIKI_MIN_STIR_RADIUS := 35.0
const MIKI_MAX_STIR_RADIUS_MULTIPLIER := 1.05
const MIKI_DONENESS_SPEED := 5.5
const MIKI_PERFECT_MIN := 48.0
const MIKI_PERFECT_MAX := 72.0
const MIKI_STARTING_QUALITY := 100
const MIKI_OVERCOOKED_PENALTY := 15
const MIKI_DRAG_SCALE := Vector2(0.4, 0.4)

enum MikiPhase { ADD, STIR, REMOVE, RESULT }

var miki_phase: int = MikiPhase.ADD
var miki_stage_is_complete := false
var miki_completion_emitted := false
var miki_noodles_added := false
var miki_stir_complete := false
var miki_dragging_uncooked := false
var miki_dragging_empty_tray := false
var miki_mouse_stirring := false
var miki_has_previous_angle := false
var miki_previous_angle := 0.0
var miki_stir_rotation := 0.0
var miki_doneness := 0.0
var miki_quality := MIKI_STARTING_QUALITY
var miki_ideal_range_announced := false
var miki_reset_pending := false

var miki_background_sprite: Sprite2D
var miki_burner_sprite: Sprite2D
var miki_burner_knob_sprite: Sprite2D
var miki_pot_sprite: Sprite2D
var miki_uncooked_tray_sprite: Sprite2D
var miki_empty_tray_sprite: Sprite2D
var miki_drag_preview_sprite: Sprite2D
var miki_stir_guide: Line2D
var miki_sequence_label: Label
var miki_status_label: Label
var miki_stir_label: Label
var miki_meter_fill: Sprite2D
var miki_meter_target: ColorRect
var miki_meter_range_label: Label
var miki_dialogue: SharedDialogue
var miki_continue_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_miki_build_stage()
	set_process_input(true)
	set_process(true)
	stage_started.emit()


func _miki_build_stage() -> void:
	miki_background_sprite = _miki_create_sprite("Background", _miki_load_texture(MIKI_BACKGROUND_PATH, Vector2i(1152, 648), Color(0.20, 0.15, 0.10)), MIKI_SCREEN_CENTER, Vector2.ONE, -20)
	miki_burner_sprite = _miki_create_sprite("Burner", _miki_load_texture(MIKI_BURNER_PATH, Vector2i(1152, 648), Color(0.12, 0.12, 0.12)), MIKI_BURNER_POSITION, Vector2.ONE, -5)
	miki_burner_knob_sprite = _miki_create_sprite("BurnerKnob", _miki_load_texture(MIKI_BURNER_KNOB_PATH, Vector2i(96, 96), Color(0.25, 0.25, 0.25)), MIKI_KNOB_POSITION, Vector2.ONE, 18)
	miki_burner_knob_sprite.rotation_degrees = -90.0
	miki_pot_sprite = _miki_create_sprite("Pot", _miki_load_texture(MIKI_WATER_POT_PATH, Vector2i(590, 429), Color(0.18, 0.34, 0.48)), MIKI_POT_POSITION, Vector2.ONE, 0)
	miki_uncooked_tray_sprite = _miki_create_sprite("UncookedMikiTray", _miki_load_texture(MIKI_UNCOOKED_TRAY_PATH, Vector2i(450, 265), Color(0.92, 0.78, 0.42)), MIKI_TRAY_POSITION, Vector2.ONE, 10)
	miki_empty_tray_sprite = _miki_create_sprite("EmptyTray", _miki_load_texture(MIKI_EMPTY_TRAY_PATH, Vector2i(450, 265), Color(0.55, 0.55, 0.55)), MIKI_TRAY_POSITION, Vector2.ONE, 10)
	miki_empty_tray_sprite.visible = false
	miki_drag_preview_sprite = _miki_create_sprite("DragPreview", _miki_load_texture(MIKI_EMPTY_TRAY_PATH, Vector2i(450, 265), Color(0.55, 0.55, 0.55)), Vector2.ZERO, MIKI_DRAG_SCALE, 30)
	miki_drag_preview_sprite.visible = false
	_miki_create_stir_guide()
	_miki_create_ui()
	_miki_create_dialogue()
	_miki_update_ui()


func _miki_create_sprite(node_name: String, sprite_texture: Texture2D, sprite_position: Vector2, sprite_scale: Vector2, sprite_z_index: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = sprite_texture
	sprite.position = sprite_position
	sprite.scale = sprite_scale
	sprite.centered = true
	sprite.z_index = sprite_z_index
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	return sprite


func _miki_create_stir_guide() -> void:
	var points := PackedVector2Array()
	for index in range(64):
		var angle := TAU * float(index) / 64.0
		points.append(MIKI_POT_DROP_CENTER + Vector2(cos(angle) * MIKI_POT_DROP_RADIUS.x, sin(angle) * MIKI_POT_DROP_RADIUS.y))
	miki_stir_guide = Line2D.new()
	miki_stir_guide.points = points
	miki_stir_guide.closed = true
	miki_stir_guide.width = 3.0
	miki_stir_guide.default_color = Color(0.95, 0.82, 0.32, 0.9)
	miki_stir_guide.z_index = 16
	miki_stir_guide.visible = false
	add_child(miki_stir_guide)


func _miki_create_ui() -> void:
	var instruction_panel := TextureRect.new()
	instruction_panel.name = "InstructionPanel"
	instruction_panel.texture = INSTRUCTION_PANEL_TEXTURE
	instruction_panel.position = Vector2(12, 12)
	instruction_panel.size = Vector2(293, 350)
	instruction_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	instruction_panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	instruction_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	instruction_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	instruction_panel.z_index = 40
	add_child(instruction_panel)
	var instruction_text := Label.new()
	instruction_text.name = "InstructionText"
	instruction_text.text = "DRAG MIKI INTO POT.\nSTIR IN CIRCLES.\nREMOVE IN THE GOLD ZONE."
	instruction_text.position = Vector2(27, 22)
	instruction_text.size = Vector2(210, 105)
	instruction_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	instruction_text.add_theme_font_override("font", UI_FONT)
	instruction_text.add_theme_font_size_override("font_size", 15)
	instruction_text.add_theme_color_override("font_color", Color(1.0, 0.91, 0.68))
	instruction_text.add_theme_color_override("font_shadow_color", Color(0.08, 0.03, 0.01, 1.0))
	instruction_text.add_theme_constant_override("shadow_offset_x", 1)
	instruction_text.add_theme_constant_override("shadow_offset_y", 1)
	instruction_text.add_theme_constant_override("line_spacing", 5)
	instruction_panel.add_child(instruction_text)
	var panel := Panel.new()
	panel.position = Vector2(24, 170)
	panel.size = Vector2(250, 210)
	panel.z_index = 40
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.visible = false
	panel.add_theme_stylebox_override("panel", _miki_panel_style())
	add_child(panel)
	miki_sequence_label = Label.new()
	miki_sequence_label.position = Vector2(14, 12)
	miki_sequence_label.size = Vector2(222, 186)
	miki_sequence_label.add_theme_font_size_override("font_size", 18)
	miki_sequence_label.visible = false
	panel.add_child(miki_sequence_label)
	miki_status_label = _miki_create_label("Status", Vector2(326, 458), Vector2(500, 45), 20)
	miki_stir_label = _miki_create_label("StirProgress", Vector2(326, 505), Vector2(500, 28), 16)
	miki_status_label.visible = false
	miki_stir_label.visible = false
	var meter_panel := Panel.new()
	meter_panel.position = Vector2(326, 303)
	meter_panel.size = Vector2(500, 82)
	meter_panel.z_index = 40
	meter_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter_panel.add_theme_stylebox_override("panel", _miki_panel_style())
	meter_panel.visible = false
	add_child(meter_panel)
	var meter_title := Label.new()
	meter_title.text = "NOODLE DONENESS"
	meter_title.position = Vector2(16, 7)
	meter_title.size = Vector2(468, 20)
	meter_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meter_title.add_theme_font_size_override("font_size", 16)
	meter_panel.add_child(meter_title)
	var meter_background := ColorRect.new()
	meter_background.position = Vector2(20, 37)
	meter_background.size = Vector2(460, 26)
	meter_background.color = Color(0.09, 0.09, 0.09)
	meter_panel.add_child(meter_background)
	var unused_meter_target := ColorRect.new()
	unused_meter_target.position = Vector2(460.0 * MIKI_PERFECT_MIN / 100.0, 0)
	unused_meter_target.size = Vector2(460.0 * (MIKI_PERFECT_MAX - MIKI_PERFECT_MIN) / 100.0, 26)
	unused_meter_target.color = Color(0.35, 0.95, 0.38, 0.35)
	meter_background.add_child(unused_meter_target)
	var unused_meter_fill := ColorRect.new()
	unused_meter_fill.size = Vector2.ZERO
	meter_background.add_child(unused_meter_fill)
	unused_meter_target.move_to_front()
	miki_continue_button = Button.new()
	miki_continue_button.text = "CONTINUE →"
	miki_continue_button.position = Vector2(940, 570)
	miki_continue_button.size = Vector2(175, 48)
	miki_continue_button.z_index = 40
	miki_continue_button.visible = false
	miki_continue_button.disabled = true
	miki_continue_button.pressed.connect(_miki_on_continue_pressed)
	add_child(miki_continue_button)
	miki_meter_range_label = Label.new()
	miki_meter_range_label.position = Vector2(20, 63)
	miki_meter_range_label.size = Vector2(460, 18)
	miki_meter_range_label.text = "UNDERCOOKED                 IDEAL                 OVERCOOKED"
	miki_meter_range_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	miki_meter_range_label.add_theme_font_size_override("font_size", 12)
	meter_panel.add_child(miki_meter_range_label)
	_miki_create_doneness_progress()


func _miki_create_doneness_progress() -> void:
	var meter_top_left := Vector2(369, 303)
	var panel := _miki_create_meter_sprite("DonenessProgressPanel", MIKI_PROGRESS_PANEL, meter_top_left, 40)
	miki_meter_fill = _miki_create_meter_sprite("DonenessProgressFill", MIKI_PROGRESS_GREEN, meter_top_left, 41)
	miki_meter_fill.region_enabled = true
	miki_meter_fill.region_rect = Rect2(0, 0, 0, 377)
	miki_meter_target = ColorRect.new()
	miki_meter_target.name = "IdealDonenessZone"
	miki_meter_target.position = meter_top_left + Vector2(20 + 377 * MIKI_PERFECT_MIN / 100.0, 67)
	miki_meter_target.size = Vector2(377 * (MIKI_PERFECT_MAX - MIKI_PERFECT_MIN) / 100.0, 42)
	miki_meter_target.color = Color(1.0, 0.76, 0.08, 0.78)
	miki_meter_target.z_index = 42
	miki_meter_target.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(miki_meter_target)
	_miki_create_meter_sprite("DonenessProgressFrame", MIKI_PROGRESS_FRAME, meter_top_left, 43)
	panel.z_index = 40


func _miki_create_meter_sprite(node_name: String, texture: Texture2D, position: Vector2, z_index: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.position = position
	sprite.centered = false
	sprite.z_index = z_index
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	return sprite


func _miki_create_label(node_name: String, label_position: Vector2, label_size: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = label_position
	label.size = label_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.z_index = 40
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	add_child(label)
	return label


func _miki_create_dialogue() -> void:
	miki_dialogue = DIALOGUE_SCENE.instantiate() as SharedDialogue
	miki_dialogue.name = "LolaGuide"
	miki_dialogue.accept_mouse_click = false
	miki_dialogue.accept_ui_accept = false
	add_child(miki_dialogue)
	miki_dialogue.set_character("lola", "neutral")
	_miki_say_lola("Apo, add the miki to the pot first. Then stir it gently so it cooks evenly.", "neutral", 4.2)


func _miki_say_lola(message: String, expression: String, duration := 3.0) -> void:
	if miki_dialogue != null:
		miki_dialogue.say(message, expression, duration, "lola")


func _miki_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.02, 0.82)
	style.border_color = Color(0.77, 0.62, 0.31, 0.9)
	style.set_border_width_all(3)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style


func _input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		return
	if miki_stage_is_complete:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_event.pressed:
			_miki_handle_mouse_pressed(mouse_event.position)
		else:
			_miki_handle_mouse_released(mouse_event.position)
	elif event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		_miki_handle_mouse_motion(motion_event.position, motion_event.button_mask)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()


func _miki_handle_mouse_pressed(mouse_position: Vector2) -> void:
	if miki_phase == MikiPhase.ADD and _miki_point_on_sprite(miki_uncooked_tray_sprite, mouse_position):
		_miki_start_drag(true, mouse_position)
	elif miki_phase == MikiPhase.STIR:
		if _miki_inside_pot(mouse_position):
			miki_mouse_stirring = true
			miki_has_previous_angle = false
		elif _miki_point_on_sprite(miki_empty_tray_sprite, mouse_position):
			_miki_show_status("STIR THE NOODLES FIRST")
			_miki_say_lola("Not yet, apo. Stir the noodles in gentle circles first.", "concerned")
	elif miki_phase == MikiPhase.REMOVE and _miki_point_on_sprite(miki_empty_tray_sprite, mouse_position):
		_miki_start_drag(false, mouse_position)


func _miki_handle_mouse_released(mouse_position: Vector2) -> void:
	if miki_dragging_uncooked or miki_dragging_empty_tray:
		_miki_finish_drag(mouse_position)
	miki_mouse_stirring = false
	miki_has_previous_angle = false


func _miki_handle_mouse_motion(mouse_position: Vector2, button_mask: int) -> void:
	if miki_dragging_uncooked or miki_dragging_empty_tray:
		miki_drag_preview_sprite.position = mouse_position
		return
	if miki_phase != MikiPhase.STIR or not miki_mouse_stirring:
		return
	if (button_mask & MOUSE_BUTTON_MASK_LEFT) == 0 or not _miki_inside_pot(mouse_position):
		miki_mouse_stirring = false
		miki_has_previous_angle = false
		return
	_miki_track_stir(mouse_position)


func _miki_start_drag(is_uncooked: bool, mouse_position: Vector2) -> void:
	miki_dragging_uncooked = is_uncooked
	miki_dragging_empty_tray = not is_uncooked
	var source := miki_uncooked_tray_sprite if is_uncooked else miki_empty_tray_sprite
	miki_drag_preview_sprite.texture = source.texture
	miki_drag_preview_sprite.position = mouse_position
	miki_drag_preview_sprite.scale = MIKI_DRAG_SCALE
	miki_drag_preview_sprite.visible = true
	source.visible = false


func _miki_finish_drag(mouse_position: Vector2) -> void:
	var was_uncooked := miki_dragging_uncooked
	miki_dragging_uncooked = false
	miki_dragging_empty_tray = false
	miki_drag_preview_sprite.visible = false
	if not _miki_inside_pot(mouse_position):
		_miki_return_tray(was_uncooked)
		_miki_show_status("DROP THE MIKI INTO THE POT" if was_uncooked else "BRING THE TRAY TO THE POT")
		return
	if was_uncooked:
		_miki_accept_uncooked_miki()
	else:
		_miki_evaluate_removal()


func _miki_accept_uncooked_miki() -> void:
	miki_noodles_added = true
	miki_phase = MikiPhase.STIR
	miki_pot_sprite.texture = _miki_load_texture(MIKI_COOKING_POT_PATH, Vector2i(590, 429), Color(0.84, 0.72, 0.38))
	miki_uncooked_tray_sprite.visible = false
	miki_empty_tray_sprite.visible = true
	miki_empty_tray_sprite.modulate = Color(0.38, 0.38, 0.38, 0.8)
	miki_stir_guide.visible = true
	_miki_pulse_pot()
	_miki_say_lola("Good. Stir in circles so every noodle cooks evenly.", "happy")
	_miki_update_ui()


func _miki_track_stir(mouse_position: Vector2) -> void:
	var offset := mouse_position - MIKI_POT_DROP_CENTER
	var radius := offset.length()
	if radius < MIKI_MIN_STIR_RADIUS or radius > MIKI_POT_DROP_RADIUS.x * MIKI_MAX_STIR_RADIUS_MULTIPLIER:
		return
	var current_angle := offset.angle()
	if miki_has_previous_angle:
		var angular_change := wrapf(current_angle - miki_previous_angle, -PI, PI)
		miki_stir_rotation += absf(angular_change)
	miki_previous_angle = current_angle
	miki_has_previous_angle = true
	if miki_stir_rotation >= TAU * MIKI_REQUIRED_STIR_ROTATIONS:
		miki_stir_rotation = TAU * MIKI_REQUIRED_STIR_ROTATIONS
		miki_stir_complete = true
		miki_phase = MikiPhase.REMOVE
		miki_mouse_stirring = false
		miki_stir_guide.visible = false
		miki_empty_tray_sprite.modulate = Color.WHITE
		_miki_show_status("USE THE EMPTY TRAY TO REMOVE THE NOODLES")
		_miki_say_lola("Watch the meter, apo. Lift them out only in the green ideal range.", "neutral", 4.0)
	_miki_update_ui()


func _process(delta: float) -> void:
	if miki_noodles_added and not miki_stage_is_complete:
		var stir_factor := lerpf(0.35, 1.25, miki_stir_rotation / (TAU * MIKI_REQUIRED_STIR_ROTATIONS))
		miki_doneness = minf(100.0, miki_doneness + MIKI_DONENESS_SPEED * stir_factor * delta)
		_miki_update_doneness_meter()


func _miki_evaluate_removal() -> void:
	if miki_doneness < MIKI_PERFECT_MIN:
		_miki_return_tray(false)
		_miki_show_status("UNDERCOOKED — WAIT A LITTLE LONGER")
		return
	if miki_doneness <= MIKI_PERFECT_MAX:
		miki_phase = MikiPhase.RESULT
		miki_stage_is_complete = true
		miki_empty_tray_sprite.visible = true
		miki_empty_tray_sprite.modulate = Color.WHITE
		miki_pot_sprite.texture = _miki_load_texture(MIKI_COOKED_POT_PATH, Vector2i(590, 429), Color(0.42, 0.82, 0.42))
		miki_empty_tray_sprite.texture = _miki_load_texture(MIKI_COOKED_TRAY_PATH, Vector2i(450, 265), Color(0.42, 0.82, 0.42))
		_miki_show_status("PERFECT! MOVING TO CHICHARON...")
		_miki_say_lola("Perfect timing, apo! On to the chicharon.", "happy", 1.2)
		_miki_complete_after_success()
		return
	_miki_show_status("OVERCOOKED. LET'S TRY A FRESH BATCH.")
	_miki_say_lola("Oh dear, those noodles stayed in too long. Let us cook a fresh batch.", "concerned", 2.2)
	_miki_reset_after_overcook()
	return
	miki_phase = MikiPhase.RESULT
	miki_stage_is_complete = true
	miki_empty_tray_sprite.visible = true
	miki_empty_tray_sprite.modulate = Color.WHITE
	if miki_doneness <= MIKI_PERFECT_MAX:
		miki_pot_sprite.texture = _miki_load_texture(MIKI_COOKED_POT_PATH, Vector2i(590, 429), Color(0.42, 0.82, 0.42))
		miki_empty_tray_sprite.texture = _miki_load_texture(MIKI_COOKED_TRAY_PATH, Vector2i(450, 265), Color(0.42, 0.82, 0.42))
		_miki_show_status("PERFECT!")
	else:
		miki_quality = maxi(0, miki_quality - MIKI_OVERCOOKED_PENALTY)
		miki_pot_sprite.texture = _miki_load_texture(MIKI_OVERCOOKED_POT_PATH, Vector2i(590, 429), Color(0.65, 0.20, 0.16))
		miki_empty_tray_sprite.texture = _miki_load_texture(MIKI_OVERCOOKED_TRAY_PATH, Vector2i(450, 265), Color(0.65, 0.20, 0.16))
		_miki_show_status("OVERCOOKED — QUALITY -%d" % MIKI_OVERCOOKED_PENALTY)
	miki_continue_button.visible = false
	miki_continue_button.disabled = true
	miki_stir_guide.visible = false
	_miki_update_ui()


func _miki_return_tray(is_uncooked: bool) -> void:
	var tray := miki_uncooked_tray_sprite if is_uncooked else miki_empty_tray_sprite
	tray.position = MIKI_TRAY_POSITION
	tray.scale = Vector2.ONE
	tray.visible = true


func _miki_update_ui() -> void:
	var add_line := "✓ Add miki" if miki_noodles_added else "→ Add miki"
	var stir_line := "✓ Stir noodles" if miki_stir_complete else ("→ Stir noodles" if miki_noodles_added else "  Stir noodles")
	var remove_line := "✓ Remove noodles" if miki_stage_is_complete else ("→ Remove noodles" if miki_phase == MikiPhase.REMOVE else "  Remove noodles")
	miki_sequence_label.text = "COOK THE MIKI\n\n%s\n%s\n%s" % [add_line, stir_line, remove_line]
	miki_stir_label.text = "STIR: %d%%" % int(round(100.0 * miki_stir_rotation / (TAU * MIKI_REQUIRED_STIR_ROTATIONS)))
	if miki_phase == MikiPhase.ADD:
		miki_status_label.text = "DRAG THE MIKI INTO THE POT"
	elif miki_phase == MikiPhase.STIR:
		miki_status_label.text = "STIR THE NOODLES IN CIRCLES"
	elif miki_phase == MikiPhase.REMOVE:
		miki_status_label.text = "USE THE EMPTY TRAY TO REMOVE THE NOODLES"
	_miki_update_doneness_meter()


func _miki_update_doneness_meter() -> void:
	if miki_meter_fill == null:
		return
	miki_meter_fill.region_rect = Rect2(0, 0, 377.0 * miki_doneness / 100.0, 377.0)
	if miki_doneness < MIKI_PERFECT_MIN:
		miki_meter_fill.modulate = Color(0.28, 0.63, 0.95)
	elif miki_doneness <= MIKI_PERFECT_MAX:
		miki_meter_fill.modulate = Color(0.30, 0.85, 0.38)
		if not miki_ideal_range_announced:
			miki_ideal_range_announced = true
			_miki_show_status("IDEAL RANGE! REMOVE THE NOODLES NOW")
			_miki_say_lola("Now, apo! The noodles are just right—lift them out!", "surprised", 2.2)
			_miki_pulse_ideal_range()
	else:
		miki_meter_fill.modulate = Color(0.90, 0.28, 0.22)


func _miki_show_status(message: String) -> void:
	miki_status_label.text = message


func _miki_pulse_pot() -> void:
	var tween := create_tween()
	tween.tween_property(miki_pot_sprite, "scale", Vector2(1.06, 1.06), 0.10)
	tween.tween_property(miki_pot_sprite, "scale", Vector2.ONE, 0.13)


func _miki_pulse_ideal_range() -> void:
	var tween := create_tween()
	tween.tween_property(miki_meter_target, "color:a", 0.95, 0.16)
	tween.tween_property(miki_meter_target, "color:a", 0.35, 0.22)
	tween.tween_property(miki_meter_target, "color:a", 0.95, 0.16)
	tween.tween_property(miki_meter_target, "color:a", 0.35, 0.22)


func _miki_complete_after_success() -> void:
	if miki_completion_emitted:
		return
	miki_completion_emitted = true
	set_process_input(false)
	await get_tree().create_timer(1.5).timeout
	stage_completed.emit()


func _miki_reset_after_overcook() -> void:
	if miki_reset_pending:
		return
	miki_reset_pending = true
	await get_tree().create_timer(2.4).timeout
	miki_reset_pending = false
	miki_phase = MikiPhase.ADD
	miki_noodles_added = false
	miki_stir_complete = false
	miki_stir_rotation = 0.0
	miki_doneness = 0.0
	miki_ideal_range_announced = false
	miki_pot_sprite.texture = _miki_load_texture(MIKI_WATER_POT_PATH, Vector2i(590, 429), Color(0.18, 0.34, 0.48))
	miki_uncooked_tray_sprite.visible = true
	miki_empty_tray_sprite.visible = false
	miki_empty_tray_sprite.texture = _miki_load_texture(MIKI_EMPTY_TRAY_PATH, Vector2i(450, 265), Color(0.55, 0.55, 0.55))
	_miki_update_ui()
	_miki_say_lola("We can do this. Add the fresh miki when you are ready.", "neutral")


func _miki_on_continue_pressed() -> void:
	if not miki_stage_is_complete or miki_completion_emitted:
		return
	miki_completion_emitted = true
	miki_continue_button.disabled = true
	miki_continue_button.visible = false
	set_process_input(false)
	set_process(false)
	stage_completed.emit()


func _miki_inside_pot(point: Vector2) -> bool:
	var local := point - MIKI_POT_DROP_CENTER
	return local.x * local.x / (MIKI_POT_DROP_RADIUS.x * MIKI_POT_DROP_RADIUS.x) + local.y * local.y / (MIKI_POT_DROP_RADIUS.y * MIKI_POT_DROP_RADIUS.y) <= 1.0


func _miki_point_on_sprite(sprite: Sprite2D, point: Vector2) -> bool:
	if sprite == null or not sprite.visible or sprite.texture == null:
		return false
	var sprite_scale := Vector2(absf(sprite.scale.x), absf(sprite.scale.y))
	var texture_size := sprite.texture.get_size() * sprite_scale
	return Rect2(sprite.position - texture_size * 0.5, texture_size).has_point(point)


func _miki_load_texture(path: String, fallback_size: Vector2i, fallback_color: Color) -> Texture2D:
	if ResourceLoader.exists(path):
		var loaded := load(path) as Texture2D
		if loaded != null:
			return loaded
	push_warning("CookMikiStage: missing texture, using placeholder: %s" % path)
	var image := Image.create(fallback_size.x, fallback_size.y, false, Image.FORMAT_RGBA8)
	image.fill(fallback_color)
	return ImageTexture.create_from_image(image)
