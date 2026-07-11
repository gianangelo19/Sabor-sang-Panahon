extends Control

signal dialogue_finished

@onready var canvas = $canvas
@onready var portrait = $canvas/portrait
@onready var npc_portrait = $canvas/npc_portrait
@onready var speaker_name = $canvas/speaker_name
@onready var dialogue_text = $canvas/dialogue_text
@onready var continue_btn = $canvas/continue_btn

var dialogue_lines = []
var current_line = 0
var auto_advance := false
var timed_line_durations: Array = []
var _player_portrait: Texture2D = null
var _npc_portrait: Texture2D = null
var _two_person_mode := false

func _ready():
	continue_btn.pressed.connect(_on_continue_pressed)
	continue_btn.grab_focus()

func _unhandled_input(event: InputEvent):
	if auto_advance:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_continue_pressed()

func start_dialogue(speaker: String, text_lines: Array, portrait_texture: Texture2D):
	var entries: Array[Dictionary] = []
	for text in text_lines:
		entries.append({
			"speaker": speaker,
			"text": str(text),
			"portrait": portrait_texture,
		})
	start_conversation(entries)

func start_conversation(entries: Array):
	auto_advance = false
	continue_btn.visible = true
	continue_btn.disabled = false
	dialogue_lines = entries
	current_line = 0
	_prepare_portraits()
	show_current_line()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Hide HUD instantly during dialogue
	var hud_root = get_tree().root.find_child("HUDRoot", true, false)
	if hud_root:
		hud_root.modulate.a = 0.0

func start_timed_conversation(entries: Array, durations: Array) -> void:
	auto_advance = true
	continue_btn.visible = false
	continue_btn.disabled = true
	dialogue_lines = entries
	timed_line_durations = durations
	current_line = 0
	_prepare_portraits()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	var hud_root = get_tree().root.find_child("HUDRoot", true, false)
	if hud_root:
		hud_root.modulate.a = 0.0

	_run_timed_dialogue()

func _prepare_portraits() -> void:
	_player_portrait = null
	_npc_portrait = null
	for entry in dialogue_lines:
		if not entry is Dictionary:
			continue
		var line_portrait = entry.get("portrait")
		if not line_portrait is Texture2D:
			continue
		if str(entry.get("speaker", "")) == "You":
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

func show_current_line():
	if current_line < dialogue_lines.size():
		var entry = dialogue_lines[current_line]
		if entry is Dictionary:
			if bool(entry.get("hide_dialogue", false)):
				canvas.visible = false
				return
			canvas.visible = true
			speaker_name.text = str(entry.get("speaker", ""))
			dialogue_text.text = str(entry.get("text", ""))
			var line_portrait = entry.get("portrait")
			if _two_person_mode:
				if str(entry.get("speaker", "")) == "You" and line_portrait is Texture2D:
					portrait.texture = line_portrait
				elif line_portrait is Texture2D:
					npc_portrait.texture = line_portrait
				_update_portrait_focus(str(entry.get("speaker", "")))
			elif line_portrait is Texture2D:
				portrait.texture = line_portrait
				portrait.modulate = Color.WHITE
				npc_portrait.visible = false
		else:
			canvas.visible = true
			dialogue_text.text = str(entry)
	else:
		# Fade in HUD smoothly
		var hud_root = get_tree().root.find_child("HUDRoot", true, false)
		if hud_root:
			var tween = hud_root.create_tween()
			tween.tween_property(hud_root, "modulate:a", 1.0, 0.5)
			
		dialogue_finished.emit()
		queue_free()

func _update_portrait_focus(speaker: String) -> void:
	if speaker == "You":
		portrait.modulate = Color.WHITE
		npc_portrait.modulate = Color(0.55, 0.55, 0.55, 0.9)
	else:
		portrait.modulate = Color(0.55, 0.55, 0.55, 0.9)
		npc_portrait.modulate = Color.WHITE

func _run_timed_dialogue() -> void:
	while auto_advance and current_line < dialogue_lines.size():
		var entry = dialogue_lines[current_line]
		if entry is Dictionary:
			var delay_before := float(entry.get("delay_before", 0.0))
			if delay_before > 0.0:
				canvas.visible = false
				await get_tree().create_timer(delay_before).timeout
		show_current_line()
		var duration := 2.0
		if current_line < timed_line_durations.size():
			duration = timed_line_durations[current_line]
		await get_tree().create_timer(duration).timeout
		current_line += 1
	auto_advance = false
	show_current_line()

func _on_continue_pressed():
	if auto_advance:
		return
	SettingsManager.play_dialogue_continue_sound()
	current_line += 1
	show_current_line()
