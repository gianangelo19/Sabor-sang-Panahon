class_name SharedDialogue
extends CanvasLayer

## Reusable bottom-left dialogue overlay for every minigame.
## Add res://features/minigames/shared/dialogue/shared_dialogue.tscn to a scene,
## or create it with SharedDialogue.new(). The portrait remains visible while
## the speech bubble only appears when a line is active.

signal dialogue_started
signal line_started(text: String, expression: String)
signal line_finished(text: String, expression: String)
signal dialogue_finished
signal choice_presented(prompt: String, choices: Array)
signal choice_selected(choice_id: String, choice_index: int, choice_text: String)

enum Emotion {
	NEUTRAL,
	HAPPY,
	CONCERNED,
	SURPRISED,
	ANGRY,
	SUPER_ANGRY,
}

const EXPRESSION_NAMES := {
	Emotion.NEUTRAL: "neutral",
	Emotion.HAPPY: "happy",
	Emotion.CONCERNED: "concerned",
	Emotion.SURPRISED: "surprised",
	Emotion.ANGRY: "angry",
	Emotion.SUPER_ANGRY: "super_angry",
}

const BUILT_IN_CHARACTER_IDS := [
	"mc",
	"lola",
	"vendor_chicharon",
	"vendor_egg",
	"vendor_guinamos",
	"vendor_miki",
	"vendor_seasoning",
	"vendor_snatch",
	"vendor_vegetable",
]

const CHARACTER_ASSET_ROOT := (
	"res://features/minigames/shared/dialogue/assets/characters"
)
const CHOICE_SELECTOR_TEXTURE: Texture2D = preload(
	"res://features/minigames/shared/dialogue/assets/choice_selection_cursor.png"
)

@export_group("Placement")
@export var screen_margin := Vector2(12.0, 10.0)
@export var portrait_size := Vector2(142.0, 142.0)
@export var bubble_overlap := 19.0
@export var bubble_vertical_offset := 4.0

@export_group("Bubble Size")
@export var minimum_bubble_width := 375.0
@export var maximum_bubble_width := 650.0
@export var minimum_bubble_height := 108.0
@export var bubble_grow_speed := 900.0
@export_range(1, 6, 1) var maximum_text_lines := 3

@export_group("Typing")
@export_range(0.005, 0.2, 0.005) var seconds_per_character := 0.035
@export var accept_mouse_click := true
@export var accept_ui_accept := true

@onready var bubble: NinePatchRect = $Bubble
@onready var dialogue_text: Label = $Bubble/Text
@onready var portrait: TextureRect = $Portrait
@onready var choice_overlay: Control = $ChoiceOverlay
@onready var choice_panel: PanelContainer = $ChoiceOverlay/ChoicePanel
@onready var choices_container: VBoxContainer = $ChoiceOverlay/ChoicePanel/Choices
@onready var choice_dim: ColorRect = $ChoiceOverlay/Dim

var _characters: Dictionary = {}
var _speaker_id := "mc"
var _expression := "neutral"
var _queue: Array[Dictionary] = []
var _current_line: Dictionary = {}
var _full_text := ""
var _typing_elapsed := 0.0
var _auto_hide_remaining := -1.0
var _target_bubble_size := Vector2.ZERO
var _is_typing := false
var _dialogue_active := false
var _choice_rows: Array[Control] = []
var _choice_options: Array[Dictionary] = []
var _selected_choice_index := 0
var _choice_mode := false
var _bubble_position_override := Vector2(-1.0, -1.0)
var _hide_portrait_for_override := false
var _choice_panel_position_override := Vector2(-1.0, -1.0)
var _hide_choice_dim_for_override := false


func _ready() -> void:
	set_process_unhandled_input(true)
	_register_built_in_characters()
	set_character("mc", "neutral")
	bubble.visible = false
	choice_overlay.visible = false
	dialogue_text.text = ""
	dialogue_text.max_lines_visible = maximum_text_lines
	_update_placement()
	get_viewport().size_changed.connect(_update_placement)


func _process(delta: float) -> void:
	if _is_typing:
		_typing_elapsed += delta
		var visible_count := mini(
			int(_typing_elapsed / seconds_per_character),
			_full_text.length()
		)
		dialogue_text.visible_characters = visible_count
		_update_target_size(visible_count)
		if visible_count >= _full_text.length():
			_finish_typing()

	if bubble.visible:
		bubble.size = bubble.size.move_toward(
			_target_bubble_size,
			bubble_grow_speed * delta
		)
		_update_placement()

	if not _is_typing and _auto_hide_remaining >= 0.0:
		_auto_hide_remaining -= delta
		if _auto_hide_remaining <= 0.0:
			advance()


func _unhandled_input(event: InputEvent) -> void:
	if not _dialogue_active:
		return

	if _choice_mode and not _is_typing:
		if event.is_action_pressed("ui_up"):
			_set_selected_choice(_selected_choice_index - 1)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_down"):
			_set_selected_choice(_selected_choice_index + 1)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_accept"):
			_confirm_choice(_selected_choice_index)
			get_viewport().set_input_as_handled()
			return

	var accepted := false
	if accept_mouse_click and event is InputEventMouseButton:
		accepted = event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if accept_ui_accept and event.is_action_pressed("ui_accept"):
		accepted = true

	if accepted and (not _choice_mode or _is_typing):
		advance()
		get_viewport().set_input_as_handled()


## Registers a speaker. Expressions use keys such as "neutral", "happy",
## "concerned", "surprised", "angry", and "super_angry".
func register_character(
	character_id: String,
	expressions: Dictionary,
	default_expression := "neutral"
) -> void:
	_characters[character_id] = {
		"expressions": expressions.duplicate(),
		"default_expression": default_expression,
	}


func has_character(character_id: String) -> bool:
	return _characters.has(character_id)


func has_expression(character_id: String, expression: Variant) -> bool:
	if not _characters.has(character_id):
		return false
	var character: Dictionary = _characters[character_id]
	var expressions: Dictionary = character.get("expressions", {})
	return expressions.has(_normalize_expression(expression))


func set_character(character_id: String, expression := "neutral") -> void:
	if not _characters.has(character_id):
		push_warning("SharedDialogue: unknown character '%s'." % character_id)
		return
	_speaker_id = character_id
	set_expression(expression)


func set_expression(expression: Variant) -> void:
	var expression_name := _normalize_expression(expression)
	var character: Dictionary = _characters.get(_speaker_id, {})
	var expressions: Dictionary = character.get("expressions", {})
	if not expressions.has(expression_name):
		expression_name = character.get("default_expression", "neutral")
	if expressions.has(expression_name):
		_expression = expression_name
		portrait.texture = expressions[expression_name]


## Immediately shows one line. auto_hide < 0 waits for click/Space/Enter.
func say(
	text: String,
	expression: Variant = "neutral",
	auto_hide := -1.0,
	character_id := "mc"
) -> void:
	_queue.clear()
	_start_dialogue_if_needed()
	_show_line({
		"text": text,
		"expression": _normalize_expression(expression),
		"character": character_id,
		"auto_hide": auto_hide,
	})


## Shows a reusable conditional prompt. Each choice can be a String or a
## Dictionary with `id` and `text`. The result is emitted through
## `choice_selected`; mouse, Up/Down, and Space/Enter are supported.
func ask(
	prompt: String,
	choices: Array,
	expression: Variant = "neutral",
	character_id := "mc"
) -> void:
	_queue.clear()
	_choice_options.clear()
	for index: int in range(choices.size()):
		var source: Variant = choices[index]
		if source is Dictionary:
			var option := (source as Dictionary).duplicate()
			option["id"] = str(option.get("id", index))
			option["text"] = str(option.get("text", option["id"]))
			_choice_options.append(option)
		else:
			_choice_options.append({"id": str(index), "text": str(source)})
	if _choice_options.is_empty():
		return
	_choice_mode = true
	_selected_choice_index = 0
	_start_dialogue_if_needed()
	_show_line({
		"text": prompt,
		"expression": _normalize_expression(expression),
		"character": character_id,
		"auto_hide": -1.0,
	})
	choice_presented.emit(prompt, _choice_options.duplicate(true))


## Plays dictionaries in sequence. Supported fields: text, expression,
## character, and auto_hide. Missing fields use the MC defaults.
func play(lines: Array) -> void:
	_queue.clear()
	for line: Variant in lines:
		if line is Dictionary:
			_queue.append((line as Dictionary).duplicate())
		elif line is String:
			_queue.append({"text": line})
	if _queue.is_empty():
		return
	_start_dialogue_if_needed()
	_show_next_line()


func queue_line(
	text: String,
	expression: Variant = "neutral",
	auto_hide := -1.0,
	character_id := "mc"
) -> void:
	_queue.append({
		"text": text,
		"expression": _normalize_expression(expression),
		"character": character_id,
		"auto_hide": auto_hide,
	})
	if not _dialogue_active:
		_start_dialogue_if_needed()
		_show_next_line()


## Useful for the planned randomized reminder/warning dialogue pools.
func say_random(
	choices: Array,
	expression: Variant = "neutral",
	auto_hide := -1.0,
	character_id := "mc"
) -> void:
	if choices.is_empty():
		return
	say(choices.pick_random(), expression, auto_hide, character_id)


## During typing, advance reveals the whole line. Afterwards it moves to the
## next queued line, or hides only the speech bubble when the queue is empty.
func advance() -> void:
	if not _dialogue_active:
		return
	if _is_typing:
		dialogue_text.visible_characters = -1
		_update_target_size(_full_text.length())
		_finish_typing()
		return
	if _choice_mode:
		return
	line_finished.emit(_full_text, _expression)
	if _queue.is_empty():
		hide_bubble()
	else:
		_show_next_line()


func hide_bubble() -> void:
	bubble.visible = false
	_is_typing = false
	_auto_hide_remaining = -1.0
	_current_line.clear()
	_full_text = ""
	dialogue_text.text = ""
	_clear_choices()
	if _dialogue_active:
		_dialogue_active = false
		dialogue_finished.emit()


func clear() -> void:
	_queue.clear()
	hide_bubble()


## Places the shared dialogue bubble near an in-scene speaker. This keeps the
## dialogue system and its choices intact while allowing minigames with a
## visible speaker to hide the usual lower-left portrait.
func set_bubble_position(position: Vector2, hide_portrait := true) -> void:
	_bubble_position_override = position
	_hide_portrait_for_override = hide_portrait
	portrait.visible = not hide_portrait
	_update_placement()


func clear_bubble_position_override() -> void:
	_bubble_position_override = Vector2(-1.0, -1.0)
	_hide_portrait_for_override = false
	portrait.visible = true
	_update_placement()


func set_choice_panel_position(position: Vector2, hide_dim := true) -> void:
	_choice_panel_position_override = position
	_hide_choice_dim_for_override = hide_dim
	_update_placement()


func clear_choice_panel_position_override() -> void:
	_choice_panel_position_override = Vector2(-1.0, -1.0)
	_hide_choice_dim_for_override = false
	_update_placement()


func is_dialogue_active() -> bool:
	return _dialogue_active


func _start_dialogue_if_needed() -> void:
	if not _dialogue_active:
		_dialogue_active = true
		dialogue_started.emit()


func _show_next_line() -> void:
	if _queue.is_empty():
		hide_bubble()
		return
	_show_line(_queue.pop_front())


func _show_line(line: Dictionary) -> void:
	_current_line = line
	var character_id: String = line.get("character", "mc")
	var expression_name := _normalize_expression(
		line.get("expression", "neutral")
	)
	set_character(character_id, expression_name)
	_full_text = str(line.get("text", ""))
	_auto_hide_remaining = float(line.get("auto_hide", -1.0))
	_typing_elapsed = 0.0
	_is_typing = not _full_text.is_empty()
	dialogue_text.text = _full_text
	dialogue_text.visible_characters = 0 if _is_typing else -1
	bubble.visible = true
	bubble.size = Vector2(minimum_bubble_width, minimum_bubble_height)
	_update_target_size(0)
	line_started.emit(_full_text, expression_name)
	if not _is_typing:
		_finish_typing()


func _finish_typing() -> void:
	_is_typing = false
	dialogue_text.visible_characters = -1
	_update_target_size(_full_text.length())
	if _choice_mode:
		_show_choices()


func _update_target_size(visible_count: int) -> void:
	var visible_text := _full_text.left(visible_count)
	var font := dialogue_text.get_theme_font("font")
	var font_size := dialogue_text.get_theme_font_size("font_size")
	var measured_width := font.get_string_size(
		visible_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size
	).x
	var width := clampf(
		measured_width + 84.0,
		minimum_bubble_width,
		maximum_bubble_width
	)
	var usable_width := maxf(width - 66.0, 1.0)
	var wrapped_lines := maxi(
		ceili(font.get_multiline_string_size(
			visible_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			usable_width,
			font_size
		).y / maxf(font.get_height(font_size), 1.0)),
		1
	)
	var height := maxf(
		minimum_bubble_height,
		48.0 + mini(wrapped_lines, maximum_text_lines) * font.get_height(font_size)
	)
	_target_bubble_size = Vector2(width, height)
	_update_placement()


func _update_placement() -> void:
	if not is_node_ready():
		return
	var viewport_height := get_viewport().get_visible_rect().size.y
	portrait.position = Vector2(screen_margin.x, viewport_height - screen_margin.y - portrait_size.y)
	portrait.size = portrait_size
	var rendered_bubble_height := maxf(
		bubble.size.y if bubble.visible else _target_bubble_size.y,
		minimum_bubble_height
	)
	if _bubble_position_override.x >= 0.0:
		var viewport_width := get_viewport().get_visible_rect().size.x
		bubble.position = Vector2(
			clampf(_bubble_position_override.x, screen_margin.x, viewport_width - bubble.size.x - screen_margin.x),
			clampf(_bubble_position_override.y, screen_margin.y, viewport_height - bubble.size.y - screen_margin.y)
		)
		portrait.visible = not _hide_portrait_for_override
	else:
		bubble.position = Vector2(
			screen_margin.x + portrait_size.x - bubble_overlap,
			viewport_height - screen_margin.y - rendered_bubble_height - bubble_vertical_offset
		)
		portrait.visible = true
	if choice_panel != null:
		var viewport_width := get_viewport().get_visible_rect().size.x
		var choice_height := maxf(
			150.0,
			float(_choice_options.size()) * 70.0 + 48.0
		)
		choice_panel.size = Vector2(choice_panel.custom_minimum_size.x, choice_height)
		choice_panel.position = _choice_panel_position_override if _choice_panel_position_override.x >= 0.0 else Vector2(
			(viewport_width - choice_panel.size.x) * 0.5,
			(viewport_height - choice_panel.size.y) * 0.5
		)


func _normalize_expression(expression: Variant) -> String:
	if expression is int and EXPRESSION_NAMES.has(expression):
		return EXPRESSION_NAMES[expression]
	return str(expression).to_lower().replace(" ", "_").replace("/", "_")


func _register_built_in_characters() -> void:
	for character_id: String in BUILT_IN_CHARACTER_IDS:
		var expressions := _load_character_expressions(character_id)
		if expressions.has("neutral"):
			register_character(character_id, expressions, "neutral")
		else:
			push_warning(
				"SharedDialogue: '%s' has no neutral portrait." % character_id
			)


func _load_character_expressions(character_id: String) -> Dictionary:
	var expressions := {}
	for expression_name: String in EXPRESSION_NAMES.values():
		var asset_path := "%s/%s/%s_%s.png" % [
			CHARACTER_ASSET_ROOT,
			character_id,
			character_id,
			expression_name,
		]
		if ResourceLoader.exists(asset_path):
			expressions[expression_name] = load(asset_path)
	return expressions


func _show_choices() -> void:
	if not _choice_mode or not _choice_rows.is_empty():
		return
	choice_overlay.visible = true
	choice_dim.visible = not _hide_choice_dim_for_override
	choices_container.visible = true
	for index: int in range(_choice_options.size()):
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 70.0
		var selector := TextureRect.new()
		selector.custom_minimum_size = Vector2(28.0, 28.0)
		selector.texture = CHOICE_SELECTOR_TEXTURE
		selector.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		selector.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		selector.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(selector)
		var option_icon := TextureRect.new()
		option_icon.custom_minimum_size = Vector2(52.0, 52.0)
		option_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		option_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		option_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var source_icon: Variant = _choice_options[index].get("icon", null)
		if source_icon is Texture2D:
			option_icon.texture = source_icon as Texture2D
		elif source_icon is String and ResourceLoader.exists(source_icon):
			option_icon.texture = load(source_icon)
		else:
			option_icon.visible = false
			option_icon.custom_minimum_size.x = 0.0
		row.add_child(option_icon)
		var button := Button.new()
		button.name = "Choice%d" % index
		button.text = str(_choice_options[index].get("text", ""))
		button.custom_minimum_size = Vector2(400.0, 64.0)
		button.flat = false
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_override("font", dialogue_text.get_theme_font("font"))
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_color_override("font_color", Color("ffe1a0"))
		button.add_theme_color_override("font_hover_color", Color("fff1bd"))
		button.add_theme_color_override("font_pressed_color", Color("fff7d6"))
		button.add_theme_stylebox_override(
			"normal",
			_make_choice_button_style(Color("2b1609"), Color("b86720"), 3)
		)
		button.add_theme_stylebox_override(
			"hover",
			_make_choice_button_style(Color("5a2c0d"), Color("f4a340"), 4)
		)
		button.add_theme_stylebox_override(
			"pressed",
			_make_choice_button_style(Color("7b3d12"), Color("ffd06a"), 4)
		)
		button.mouse_entered.connect(_set_selected_choice.bind(index))
		button.pressed.connect(_confirm_choice.bind(index))
		row.add_child(button)
		choices_container.add_child(row)
		_choice_rows.append(row)
	_set_selected_choice(_selected_choice_index)
	_update_target_size(_full_text.length())


func _make_choice_button_style(
	background_color: Color,
	border_color: Color,
	border_width: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(5)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style


func _set_selected_choice(index: int) -> void:
	if _choice_options.is_empty():
		return
	_selected_choice_index = posmod(index, _choice_options.size())
	for row_index: int in range(_choice_rows.size()):
		var selector := _choice_rows[row_index].get_child(0) as TextureRect
		selector.visible = row_index == _selected_choice_index


func _confirm_choice(index: int) -> void:
	if not _choice_mode or index < 0 or index >= _choice_options.size():
		return
	var option: Dictionary = _choice_options[index]
	var choice_id := str(option.get("id", index))
	var choice_text := str(option.get("text", choice_id))
	_choice_mode = false
	choice_selected.emit(choice_id, index, choice_text)
	hide_bubble()


func _clear_choices() -> void:
	for row: Control in _choice_rows:
		if is_instance_valid(row):
			row.queue_free()
	_choice_rows.clear()
	_choice_options.clear()
	_choice_mode = false
	choice_overlay.visible = false
	choices_container.visible = false
	dialogue_text.offset_bottom = -29.0
