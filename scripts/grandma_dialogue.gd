extends Node3D

const DIALOGUE_SCENE := preload("res://dialogue_ui.tscn")
const GRANDMA_PORTRAIT := preload("res://characters/npc_grandma/npc_grandma_front.png")
const PLAYER_PORTRAIT := preload("res://characters/2main_character_asking.png")
const ARTIFACT_RECOVERED_CLUE := "Batchoy Bowl artifact recovered."
const BATCHOY_SERVED_CLUE := "La Paz Batchoy served to Grandma."

const FIRST_CONVERSATION: Array[Dictionary] = [
	{"speaker": "You", "text": "Grandma! It's good to see you. How are you feeling?", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Grandma", "text": "Ay, apo! You came all the way to La Paz? I'm all right, only a little tired.", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "You", "text": "I found a damaged newspaper about an old dish from La Paz. I thought you might remember it.", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Grandma", "text": "An old dish? My memory is not what it used to be, but tell me what you found.", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "You", "text": "The article mentioned broth, noodles, the market, and an oldtimer. Does that sound familiar?", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Grandma", "text": "I remember soft noodles, tender meat, a deep salty taste, and something crisp scattered on top.", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "You", "text": "Do you remember what the dish was called?", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Grandma", "text": "No... the name escapes me. But I can still hear bowls clinking and the market bustling nearby.", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "Grandma", "text": "The aroma used to fill this whole neighborhood. It felt warm and familiar, especially on rainy afternoons.", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "You", "text": "I'll ask around the neighborhood and the market. Someone else may remember.", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Grandma", "text": "Please do, apo. I must leave soon to buy my medicine.", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "You", "text": "I'll be back before dinner. Maybe we can make the dish together.", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Grandma", "text": "I'll look forward to that. Take care while you explore La Paz, ha?", "portrait": GRANDMA_PORTRAIT},
]

const REPEAT_CONVERSATION: Array[Dictionary] = [
	{"speaker": "You", "text": "Grandma, can you remind me what you remembered about the dish?", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Grandma", "text": "Soft noodles, tender meat, a deep salty taste, and something crisp scattered on top.", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "You", "text": "Got it. I'll ask around the neighborhood and the market.", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Grandma", "text": "Take care, apo. Come back before dinner.", "portrait": GRANDMA_PORTRAIT},
]

const RESTORED_CONVERSATION: Array[Dictionary] = [
	{"speaker": "You", "text": "How is the batchoy, Grandma?", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Grandma", "text": "It tastes like home, apo. The meat, fresh miki, ginamos, and crushed chicharon - I remember all four now.", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "You", "text": "Then the old bowl really carried the memory back to us.", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Grandma", "text": "And now that we remember together, La Paz Batchoy will not be forgotten again.", "portrait": GRANDMA_PORTRAIT},
]

var _dialogue_active := false
var _conversation_completed := false
var _player: Node = null
var _player_was_movable := true


func _ready() -> void:
	_conversation_completed = GameState.is_destination_completed("grandma_house")
	if not GameState.grandma_presence_changed.is_connected(_on_grandma_presence_changed):
		GameState.grandma_presence_changed.connect(_on_grandma_presence_changed)
	_apply_presence(_should_be_present())


func _should_be_present() -> bool:
	return (
		not GameState.grandma_left_for_medicine
		or GameState.clues.has(ARTIFACT_RECOVERED_CLUE)
		or GameState.clues.has(BATCHOY_SERVED_CLUE)
	)


func _on_grandma_presence_changed(present: bool) -> void:
	_apply_presence(present or GameState.clues.has(ARTIFACT_RECOVERED_CLUE))


func _apply_presence(present: bool) -> void:
	visible = present
	for descendant in find_children("*", "CollisionShape3D", true, false):
		(descendant as CollisionShape3D).set_deferred("disabled", not present)


func get_interaction_text() -> String:
	if GameState.clues.has("La Paz Batchoy served to Grandma."):
		return "Press E to talk about the restored Batchoy"
	return "Press E to talk to Grandma"


func interact() -> void:
	if _dialogue_active:
		return

	_dialogue_active = true
	_lock_player()

	var dialogue := DIALOGUE_SCENE.instantiate()
	get_tree().root.add_child(dialogue)
	var conversation := FIRST_CONVERSATION
	if GameState.clues.has("La Paz Batchoy served to Grandma."):
		conversation = RESTORED_CONVERSATION
	elif _conversation_completed:
		conversation = REPEAT_CONVERSATION
	dialogue.start_conversation(conversation)
	dialogue.dialogue_finished.connect(_on_dialogue_finished)


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
		GameState.complete_destination("grandma_house")
		GameState.unlock_destination("market_vendor_1")
		GameState.select_destination("market_vendor_1")
		GameState.add_clue("Grandma remembers soft noodles, tender meat, a salty taste, and a crisp topping.")
		GameState.set_objective("Ask the people of La Paz about Grandma's memories.")
		GameState.set_ambot_status("La Paz Market marked in Maps")
		GameState.push_ambot_notification(
			"grandma_clues",
			"Grandma's testimony recorded",
			"A new search area is available in Maps."
		)

	if _player != null and is_instance_valid(_player):
		_player.can_move = _player_was_movable
		_player.set_process_unhandled_input(true)
		_player.capture_mouse()

	_dialogue_active = false
