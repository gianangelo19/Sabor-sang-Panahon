extends StaticBody3D

const DIALOGUE_SCENE := preload("res://game/ui/dialogue/dialogue_ui.tscn")
const PLAYER_PORTRAIT := preload("res://assets/art/characters/2main_character_asking.png")
const FRIDGE_FLAG := "apartment_fridge_checked"
const TUTORIAL_INTERACT_STEP := 3

var _dialogue_active := false
var _player: Node
var _player_was_movable := true


func get_interaction_text() -> String:
	if GameState.has_story_flag(FRIDGE_FLAG):
		return "Press F to check the empty fridge"
	return "Press F to look for food in the fridge"


func interaction_focus_entered() -> void:
	var hud := get_tree().root.find_child("GameHUD", true, false)
	if hud != null and hud.has_method("notify_fridge_seen"):
		hud.notify_fridge_seen()


func should_hide_interaction_prompt() -> bool:
	# The tutorial card already presents the F key while teaching interaction.
	return (
		GameState.tutorial_step == TUTORIAL_INTERACT_STEP
		and not GameState.has_story_flag(FRIDGE_FLAG)
	)


func interact() -> void:
	if _dialogue_active:
		return
	_dialogue_active = true
	_lock_player()
	var dialogue := DIALOGUE_SCENE.instantiate()
	get_tree().root.add_child(dialogue)
	if GameState.has_story_flag(FRIDGE_FLAG):
		dialogue.start_conversation([
			_player_line("Still empty. The fridge has remained committed to the bit."),
		])
	else:
		dialogue.start_conversation([
			_player_line("Empty. I really should restock soon..."),
			_player_line("Ay wait. Lola Lynn sent that package from the old house."),
			_player_line("Old things maybe? Hopefully food."),
			_player_line("Huh... surprisingly taped more than my hopes and dreams."),
		])
	dialogue.dialogue_finished.connect(_on_dialogue_finished)


func _on_dialogue_finished() -> void:
	if not GameState.has_story_flag(FRIDGE_FLAG):
		GameState.set_story_flag(FRIDGE_FLAG)
		GameState.set_objective("Open Lola Lynn's package on the table.")
	_restore_player()
	_dialogue_active = false


func _player_line(text: String) -> Dictionary:
	return {"speaker": "You", "text": text, "portrait": PLAYER_PORTRAIT}


func _lock_player() -> void:
	_player = get_tree().root.find_child("ProtoController", true, false)
	if _player == null:
		return
	_player_was_movable = bool(_player.can_move)
	_player.can_move = false
	_player.set_process_unhandled_input(false)
	if _player.has_method("release_mouse"):
		_player.release_mouse()
	var prompt := _player.get_node_or_null("InteractionUI/Prompt")
	if prompt:
		prompt.visible = false


func _restore_player() -> void:
	if _player != null and is_instance_valid(_player):
		_player.can_move = _player_was_movable
		_player.set_process_unhandled_input(true)
		if _player.has_method("capture_mouse"):
			_player.capture_mouse()
	_player = null
