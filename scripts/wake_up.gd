extends CanvasLayer

@onready var top_eyelid = $TopEyelid
@onready var bottom_eyelid = $BottomEyelid

var dialogue_scene = preload("res://dialogue_ui.tscn")
var waking_up_tex = preload("res://characters/1main_character_waking_up.png")

func _ready():
	var player = get_node("../ProtoController")
	if player:
		# Disable player movement during wake up and dialogue
		player.can_move = false
		player.set_process_unhandled_input(false)
		player.release_mouse()
		
	# Hide the HUD instantly before waking up
	var hud_root = get_tree().root.find_child("HUDRoot", true, false)
	if hud_root:
		hud_root.modulate.a = 0.0
		
	# Small delay before opening eyes
	await get_tree().create_timer(1.5).timeout

	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(top_eyelid, "position:y", -top_eyelid.size.y, 3.0)
	tween.tween_property(bottom_eyelid, "position:y", bottom_eyelid.position.y + bottom_eyelid.size.y, 3.0)
	
	tween.chain().tween_callback(start_dialogue)

func start_dialogue():
	var ui = dialogue_scene.instantiate()
	add_child(ui)
	
	ui.start_dialogue(
		"Main Character", 
		["Ugh... my head...", "I'm so hungry... I should find something to eat."],
		waking_up_tex
	)
	
	ui.dialogue_finished.connect(_on_dialogue_finished)

func _on_dialogue_finished():
	var player = get_node("../ProtoController")
	if player:
		player.can_move = true
		player.set_process_unhandled_input(true)
		player.capture_mouse()
	queue_free()
