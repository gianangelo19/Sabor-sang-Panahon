extends Control

signal dialogue_finished

@onready var portrait = $canvas/portrait
@onready var speaker_name = $canvas/speaker_name
@onready var dialogue_text = $canvas/dialogue_text
@onready var continue_btn = $canvas/continue_btn

var dialogue_lines = []
var current_line = 0

func _ready():
	continue_btn.pressed.connect(_on_continue_pressed)

func start_dialogue(speaker: String, text_lines: Array, portrait_texture: Texture2D):
	speaker_name.text = speaker
	dialogue_lines = text_lines
	if portrait_texture:
		portrait.texture = portrait_texture
	current_line = 0
	show_current_line()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Hide HUD instantly during dialogue
	var hud_root = get_tree().root.find_child("HUDRoot", true, false)
	if hud_root:
		hud_root.modulate.a = 0.0

func show_current_line():
	if current_line < dialogue_lines.size():
		dialogue_text.text = dialogue_lines[current_line]
	else:
		# Fade in HUD smoothly
		var hud_root = get_tree().root.find_child("HUDRoot", true, false)
		if hud_root:
			var tween = hud_root.create_tween()
			tween.tween_property(hud_root, "modulate:a", 1.0, 0.5)
			
		dialogue_finished.emit()
		queue_free()

func _on_continue_pressed():
	current_line += 1
	show_current_line()
