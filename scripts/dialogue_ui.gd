extends Control

signal dialogue_finished

const DIALOGUE_TYPE_SOUND := preload("res://audio/retro_filipino_pack/dialogue_type_click.wav")
const TYPE_SOUND_CHARACTER_INTERVAL := 2
const PLAYER_SPEAKER_NAMES := ["you", "player", "main character"]

@export_range(0.005, 0.1, 0.005) var type_character_delay := 0.025
@export_range(-12.0, 6.0, 0.5) var type_sound_volume_db := 3.0
@export_range(12.0, 160.0, 2.0) var npc_bubble_screen_gap := 42.0
@export_range(0.5, 4.0, 0.1) var npc_auto_advance_base_delay := 1.4
@export_range(0.0, 0.05, 0.001) var npc_auto_advance_seconds_per_character := 0.015
@export_range(1.0, 8.0, 0.1) var npc_auto_advance_max_delay := 3.8

@onready var canvas: CanvasLayer = $canvas
@onready var portrait: TextureRect = $canvas/portrait
@onready var npc_portrait: TextureRect = $canvas/npc_portrait
@onready var npc_bubble: Panel = $canvas/npc_bubble
@onready var bubble_tail: Polygon2D = $canvas/bubble_tail
@onready var player_thought: Panel = $canvas/player_thought
@onready var speaker_name: RichTextLabel = $canvas/speaker_name
@onready var dialogue_text: RichTextLabel = $canvas/dialogue_text
@onready var continue_btn: Button = $canvas/continue_btn

var dialogue_lines: Array = []
var current_line := 0
var auto_advance := false
var timed_line_durations: Array = []
var _player_portrait: Texture2D = null
var _npc_portrait: Texture2D = null
var _two_person_mode := false
var _typing_audio_player: AudioStreamPlayer
var _typing_generation := 0
var _is_typing := false
var _showing_player_thought := true
var _speaker_target: Node3D = null
var _line_speaker_target: Node3D = null
var _current_line_text := ""


func _ready() -> void:
	add_to_group("transient_gameplay_ui")
	_typing_audio_player = AudioStreamPlayer.new()
	_typing_audio_player.name = "DialogueTypeAudio"
	_typing_audio_player.stream = DIALOGUE_TYPE_SOUND
	_typing_audio_player.bus = "SFX"
	_typing_audio_player.volume_db = type_sound_volume_db
	_typing_audio_player.max_polyphony = 2
	add_child(_typing_audio_player)
	continue_btn.pressed.connect(_on_continue_pressed)
	continue_btn.grab_focus()


func _process(_delta: float) -> void:
	if not canvas.visible:
		return
	if _showing_player_thought:
		_layout_player_thought()
	else:
		_layout_npc_bubble()


func _unhandled_input(event: InputEvent) -> void:
	if auto_advance or not _showing_player_thought:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_continue_pressed()


func start_dialogue(
	speaker: String,
	text_lines: Array,
	portrait_texture: Texture2D,
	speaker_target: Node3D = null,
) -> void:
	var entries: Array[Dictionary] = []
	for text in text_lines:
		entries.append({
			"speaker": speaker,
			"text": str(text),
			"portrait": portrait_texture,
		})
	start_conversation(entries, speaker_target)


func start_conversation(entries: Array, speaker_target: Node3D = null) -> void:
	auto_advance = false
	continue_btn.visible = true
	continue_btn.disabled = false
	dialogue_lines = entries
	_speaker_target = speaker_target
	current_line = 0
	_prepare_portraits()
	show_current_line()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hide_hud()


func start_timed_conversation(
	entries: Array,
	durations: Array,
	speaker_target: Node3D = null,
) -> void:
	auto_advance = true
	continue_btn.visible = false
	continue_btn.disabled = true
	dialogue_lines = entries
	timed_line_durations = durations
	_speaker_target = speaker_target
	current_line = 0
	_prepare_portraits()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_hide_hud()
	_run_timed_dialogue()


func _hide_hud() -> void:
	var hud_root := get_tree().root.find_child("HUDRoot", true, false)
	if hud_root:
		hud_root.modulate.a = 0.0


func _prepare_portraits() -> void:
	# Portrait data remains accepted so existing conversations do not need a data
	# migration, but the redesigned UI never displays the portrait controls.
	_player_portrait = null
	_npc_portrait = null
	for entry in dialogue_lines:
		if not entry is Dictionary:
			continue
		var line_portrait = entry.get("portrait")
		if not line_portrait is Texture2D:
			continue
		if _is_player_speaker(str(entry.get("speaker", ""))):
			if _player_portrait == null:
				_player_portrait = line_portrait
		elif _npc_portrait == null:
			_npc_portrait = line_portrait
	_two_person_mode = _player_portrait != null and _npc_portrait != null
	npc_portrait.visible = _two_person_mode
	if _player_portrait != null:
		portrait.texture = _player_portrait
	if _npc_portrait != null:
		npc_portrait.texture = _npc_portrait
	_make_portraits_invisible()


func show_current_line() -> void:
	if current_line >= dialogue_lines.size():
		_finish_dialogue()
		return

	var entry = dialogue_lines[current_line]
	if entry is Dictionary:
		if bool(entry.get("hide_dialogue", false)):
			_cancel_typewriter()
			canvas.visible = false
			return
		canvas.visible = true
		var speaker := str(entry.get("speaker", ""))
		_current_line_text = str(entry.get("text", ""))
		speaker_name.text = speaker
		_resolve_line_target(entry)
		_apply_line_layout(speaker)
		_start_typewriter(_current_line_text)
		_update_portrait_cache(entry, speaker)
	else:
		canvas.visible = true
		_current_line_text = str(entry)
		_line_speaker_target = null
		_apply_line_layout("You")
		_start_typewriter(_current_line_text)


func _resolve_line_target(entry: Dictionary) -> void:
	var requested_target = entry.get("speaker_target", _speaker_target)
	_line_speaker_target = requested_target as Node3D


func _apply_line_layout(speaker: String) -> void:
	_showing_player_thought = _is_player_speaker(speaker)
	npc_bubble.visible = not _showing_player_thought
	bubble_tail.visible = not _showing_player_thought
	player_thought.visible = _showing_player_thought
	speaker_name.visible = not _showing_player_thought
	continue_btn.visible = not auto_advance and _showing_player_thought
	continue_btn.disabled = auto_advance or not _showing_player_thought
	if _showing_player_thought:
		_layout_player_thought()
	else:
		_layout_npc_bubble()


func _layout_player_thought() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var panel_width := minf(980.0, maxf(280.0, viewport_size.x - 48.0))
	if viewport_size.x > 720.0:
		panel_width = minf(panel_width, viewport_size.x * 0.76)
	var panel_height := clampf(viewport_size.y * 0.22, 132.0, 188.0)
	panel_height = minf(panel_height, maxf(108.0, viewport_size.y - 32.0))
	var panel_position := Vector2(
		(viewport_size.x - panel_width) * 0.5,
		viewport_size.y - panel_height - clampf(viewport_size.y * 0.045, 22.0, 42.0),
	)
	player_thought.position = panel_position
	player_thought.size = Vector2(panel_width, panel_height)
	dialogue_text.position = panel_position + Vector2(34.0, 28.0)
	dialogue_text.size = Vector2(panel_width - 68.0, panel_height - 50.0)
	_position_continue_button(panel_position, Vector2(panel_width, panel_height))


func _layout_npc_bubble() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var bubble_width := clampf(viewport_size.x * 0.38, 340.0, 520.0)
	bubble_width = minf(bubble_width, maxf(260.0, viewport_size.x - 32.0))
	var estimated_lines := clampi(ceili(float(_current_line_text.length()) / 40.0), 2, 6)
	var bubble_height := clampf(82.0 + float(estimated_lines * 24), 138.0, 226.0)
	bubble_height = minf(bubble_height, maxf(120.0, viewport_size.y - 48.0))
	var anchor := _get_speaker_screen_position(viewport_size)
	var desired_position := Vector2(
		anchor.x - bubble_width * 0.5,
		anchor.y - bubble_height - npc_bubble_screen_gap,
	)
	var panel_position := Vector2(
		clampf(desired_position.x, 16.0, maxf(16.0, viewport_size.x - bubble_width - 16.0)),
		clampf(desired_position.y, 18.0, maxf(18.0, viewport_size.y - bubble_height - 24.0)),
	)
	npc_bubble.position = panel_position
	npc_bubble.size = Vector2(bubble_width, bubble_height)
	speaker_name.position = panel_position + Vector2(22.0, 14.0)
	speaker_name.size = Vector2(bubble_width - 44.0, 30.0)
	dialogue_text.position = panel_position + Vector2(22.0, 48.0)
	dialogue_text.size = Vector2(bubble_width - 44.0, bubble_height - 68.0)
	var tail_x := clampf(anchor.x, panel_position.x + 28.0, panel_position.x + bubble_width - 28.0)
	bubble_tail.position = Vector2(tail_x, panel_position.y + bubble_height - 1.0)
	_position_continue_button(panel_position, Vector2(bubble_width, bubble_height))


func _get_speaker_screen_position(viewport_size: Vector2) -> Vector2:
	if _line_speaker_target == null or not is_instance_valid(_line_speaker_target):
		return Vector2(viewport_size.x * 0.5, viewport_size.y * 0.46)
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector2(viewport_size.x * 0.5, viewport_size.y * 0.46)
	# Anchor to the top edge of the rendered character instead of their center.
	# This keeps the entire bubble above differently-scaled NPC sprites.
	var sprite := _line_speaker_target.find_child("Sprite3D", true, false) as Sprite3D
	var anchor_node: Node3D = sprite
	if anchor_node == null:
		anchor_node = _line_speaker_target.find_child("Marker3D", true, false) as Node3D
	if anchor_node == null:
		anchor_node = _line_speaker_target
	var anchor_position := anchor_node.global_position
	if sprite != null and sprite.texture != null:
		var sprite_half_height := float(sprite.texture.get_height()) * sprite.pixel_size * 0.5
		anchor_position += sprite.global_transform.basis.y * sprite_half_height
	if camera.is_position_behind(anchor_position):
		return Vector2(viewport_size.x * 0.5, viewport_size.y * 0.46)
	return camera.unproject_position(anchor_position)


func _position_continue_button(panel_position: Vector2, panel_size: Vector2) -> void:
	continue_btn.position = panel_position + panel_size - Vector2(52.0, 43.0)
	continue_btn.size = Vector2(36.0, 30.0)


func _is_player_speaker(speaker: String) -> bool:
	return speaker.strip_edges().to_lower() in PLAYER_SPEAKER_NAMES


func _update_portrait_cache(entry: Dictionary, speaker: String) -> void:
	var line_portrait = entry.get("portrait")
	if _two_person_mode:
		if _is_player_speaker(speaker) and line_portrait is Texture2D:
			portrait.texture = line_portrait
		elif line_portrait is Texture2D:
			npc_portrait.texture = line_portrait
	elif line_portrait is Texture2D:
		portrait.texture = line_portrait
		npc_portrait.visible = false
	_make_portraits_invisible()


func _make_portraits_invisible() -> void:
	portrait.modulate = Color(1.0, 1.0, 1.0, 0.0)
	npc_portrait.modulate = Color(1.0, 1.0, 1.0, 0.0)


func _finish_dialogue() -> void:
	_cancel_typewriter()
	var hud_root := get_tree().root.find_child("HUDRoot", true, false)
	if hud_root:
		var tween := hud_root.create_tween()
		tween.tween_property(hud_root, "modulate:a", 1.0, 0.5)
	dialogue_finished.emit()
	queue_free()


func _start_typewriter(text: String) -> void:
	_cancel_typewriter()
	dialogue_text.text = text
	dialogue_text.visible_characters = 0
	var total_characters: int = dialogue_text.get_total_character_count()
	if total_characters == 0:
		dialogue_text.visible_characters = -1
		_schedule_npc_auto_advance(_typing_generation, 0)
		return

	_is_typing = true
	var generation := _typing_generation
	_type_current_line(generation, dialogue_text.get_parsed_text(), total_characters)


func _type_current_line(generation: int, parsed_text: String, total_characters: int) -> void:
	var audible_characters := 0
	for visible_count in range(1, total_characters + 1):
		if generation != _typing_generation or not _is_typing:
			return

		dialogue_text.visible_characters = visible_count
		var character_index: int = mini(visible_count - 1, parsed_text.length() - 1)
		if character_index >= 0:
			var character := parsed_text.substr(character_index, 1)
			if not character.strip_edges().is_empty():
				audible_characters += 1
				if audible_characters % TYPE_SOUND_CHARACTER_INTERVAL == 1:
					_play_typing_sound()

		if visible_count < total_characters:
			await get_tree().create_timer(type_character_delay, false).timeout

	if generation != _typing_generation:
		return
	dialogue_text.visible_characters = -1
	_is_typing = false
	_schedule_npc_auto_advance(generation, total_characters)


func _schedule_npc_auto_advance(generation: int, character_count: int) -> void:
	if auto_advance or _showing_player_thought:
		return
	var reading_delay := clampf(
		npc_auto_advance_base_delay
			+ float(character_count) * npc_auto_advance_seconds_per_character,
		npc_auto_advance_base_delay,
		npc_auto_advance_max_delay,
	)
	await get_tree().create_timer(reading_delay, false).timeout
	if (
		generation != _typing_generation
		or auto_advance
		or _showing_player_thought
		or not is_inside_tree()
	):
		return
	current_line += 1
	show_current_line()


func _play_typing_sound() -> void:
	if _typing_audio_player == null:
		return
	_typing_audio_player.pitch_scale = randf_range(0.96, 1.04)
	_typing_audio_player.play()


func _cancel_typewriter(show_full_line := false) -> void:
	_typing_generation += 1
	_is_typing = false
	if show_full_line:
		dialogue_text.visible_characters = -1
	if _typing_audio_player != null:
		_typing_audio_player.stop()


func _complete_typewriter() -> void:
	_cancel_typewriter(true)


func _update_portrait_focus(_speaker: String) -> void:
	# Kept as a no-op compatibility hook for older callers.
	_make_portraits_invisible()


func _run_timed_dialogue() -> void:
	while auto_advance and current_line < dialogue_lines.size():
		var entry = dialogue_lines[current_line]
		if entry is Dictionary:
			var delay_before := float(entry.get("delay_before", 0.0))
			if delay_before > 0.0:
				canvas.visible = false
				await get_tree().create_timer(delay_before, false).timeout
		show_current_line()
		var duration := 2.0
		if current_line < timed_line_durations.size():
			duration = timed_line_durations[current_line]
		await get_tree().create_timer(duration, false).timeout
		current_line += 1
	auto_advance = false
	show_current_line()


func _on_continue_pressed() -> void:
	if auto_advance:
		return
	if _is_typing:
		_complete_typewriter()
		return
	SettingsManager.play_dialogue_continue_sound()
	current_line += 1
	show_current_line()
