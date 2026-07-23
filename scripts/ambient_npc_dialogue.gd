extends Node3D

const DIALOGUE_SCENE := preload("res://dialogue_ui.tscn")
const BATCHOY_SERVED_CLUE := "La Paz Batchoy served to Grandma."

@export var npc_display_name := "Local"
@export_multiline var opening_line := "Good day."
@export_multiline var player_reply := "Good day."
@export_multiline var closing_line := "Take care."
@export var repeat_lines: Array[String] = []
@export_multiline var restored_line := "La Paz remembers."

var _dialogue_active := false
var _conversation_count := 0
var _player: Node = null
var _player_was_movable := true


func get_interaction_text() -> String:
	return "Press E to talk to " + npc_display_name


func interact() -> void:
	if _dialogue_active:
		return
	_dialogue_active = true
	_lock_player()

	var dialogue := DIALOGUE_SCENE.instantiate()
	get_tree().root.add_child(dialogue)
	dialogue.start_conversation(_build_conversation(), self)
	dialogue.dialogue_finished.connect(_on_dialogue_finished)


func _build_conversation() -> Array[Dictionary]:
	if GameState.clues.has(BATCHOY_SERVED_CLUE) and not restored_line.is_empty():
		return [_npc_line(restored_line)]
	if _conversation_count > 0 and not repeat_lines.is_empty():
		var repeat_index := (_conversation_count - 1) % repeat_lines.size()
		return [_npc_line(repeat_lines[repeat_index])]

	var entries: Array[Dictionary] = []
	if not opening_line.is_empty():
		entries.append(_npc_line(opening_line))
	if not player_reply.is_empty():
		entries.append({"speaker": "You", "text": player_reply, "portrait": null})
	if not closing_line.is_empty():
		entries.append(_npc_line(closing_line))
	return entries


func _npc_line(text: String) -> Dictionary:
	return {"speaker": npc_display_name, "text": text, "portrait": null}


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


func _on_dialogue_finished() -> void:
	_conversation_count += 1
	if _player != null and is_instance_valid(_player):
		_player.can_move = _player_was_movable
		_player.set_process_unhandled_input(true)
		if _player.has_method("capture_mouse"):
			_player.capture_mouse()
	_player = null
	_dialogue_active = false
