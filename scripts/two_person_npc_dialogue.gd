extends Node3D

const DIALOGUE_SCENE := preload("res://dialogue_ui.tscn")
const PLAYER_PORTRAIT := preload("res://characters/2main_character_asking.png")
const MINIGAME_SESSION_SCRIPT := preload("res://scripts/minigame_session.gd")

var npc_display_name := "NPC"
var npc_portrait: Texture2D
var first_conversation: Array[Dictionary] = []
var repeat_conversation: Array[Dictionary] = []
var minigame_title := "Vendor Challenge"
var minigame_instructions := "Complete the vendor's challenge."
var reward_id := "ingredient"
var reward_name := "Ingredient"
var destination_id := ""
var minigame_scene: PackedScene

var _dialogue_active := false
var _conversation_completed := false
var _minigame_completed := false
var _player: Node = null
var _player_was_movable := true
var _minigame_session: CanvasLayer = null


func get_interaction_text() -> String:
	if not _is_story_available():
		return _locked_interaction_text()
	if _conversation_completed and not _minigame_completed:
		return "Press E to try " + npc_display_name + "'s challenge"
	return "Press E to talk to " + npc_display_name


func interact() -> void:
	if _dialogue_active or not _is_story_available():
		return
	_dialogue_active = true
	_lock_player()
	if _conversation_completed and not _minigame_completed:
		_start_minigame()
		return
	if not _conversation_completed:
		_handle_first_conversation_started()

	var dialogue := DIALOGUE_SCENE.instantiate()
	get_tree().root.add_child(dialogue)
	dialogue.start_conversation(
		repeat_conversation if _conversation_completed else first_conversation
	)
	dialogue.dialogue_finished.connect(_on_dialogue_finished)


func player_line(text: String) -> Dictionary:
	return {"speaker": "You", "text": text, "portrait": PLAYER_PORTRAIT}


func npc_line(text: String) -> Dictionary:
	return {"speaker": npc_display_name, "text": text, "portrait": npc_portrait}


func sync_completion_from_game_state() -> void:
	if not destination_id.is_empty() and GameState.is_destination_completed(destination_id):
		_conversation_completed = true
		_minigame_completed = true


func _is_story_available() -> bool:
	if destination_id.is_empty():
		return true
	return GameState.is_destination_unlocked(destination_id) or GameState.is_destination_completed(destination_id)


func _locked_interaction_text() -> String:
	if not GameState.is_destination_completed("grandma_house"):
		return "Talk to Grandma first"
	return "Follow the current lead first"


func _lock_player() -> void:
	_player = get_tree().root.find_child("ProtoController", true, false)
	if _player == null:
		return
	_player_was_movable = _player.can_move
	_player.can_move = false
	_player.set_process_unhandled_input(false)
	_player.release_mouse()
	var prompt := _player.get_node_or_null("InteractionUI/Prompt")
	if prompt:
		prompt.visible = false


func _on_dialogue_finished() -> void:
	if not _conversation_completed:
		_conversation_completed = true
		_start_minigame()
		return
	_restore_player()


func _start_minigame() -> void:
	if minigame_scene == null:
		push_error(npc_display_name + " has no minigame scene configured.")
		_restore_player()
		return
	_minigame_session = MINIGAME_SESSION_SCRIPT.new()
	_minigame_session.name = "VendorMinigameSession"
	get_tree().root.add_child(_minigame_session)
	_minigame_session.minigame_won.connect(_on_minigame_won)
	_minigame_session.dismissed.connect(_on_minigame_dismissed)
	_minigame_session.start(minigame_scene)


func _on_minigame_won() -> void:
	_minigame_session = null
	_minigame_completed = true
	GameState.collect_ingredient(reward_id, reward_name)
	_handle_minigame_won()
	_restore_player()


func _on_minigame_dismissed() -> void:
	_minigame_session = null
	_restore_player()


func _restore_player() -> void:
	if _player != null and is_instance_valid(_player):
		_player.can_move = _player_was_movable
		_player.set_process_unhandled_input(true)
		_player.capture_mouse()
	_dialogue_active = false


func _handle_minigame_won() -> void:
	pass


func _handle_first_conversation_started() -> void:
	pass
