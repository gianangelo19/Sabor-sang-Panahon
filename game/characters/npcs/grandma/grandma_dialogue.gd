extends Node3D

const DIALOGUE_SCENE := preload("res://game/ui/dialogue/dialogue_ui.tscn")
const GRANDMA_PORTRAIT := preload("res://assets/art/characters/npc_grandma/npc_grandma_front.png")
const PLAYER_PORTRAIT := preload("res://assets/art/characters/2main_character_asking.png")
const ARTIFACT_RECOVERED_CLUE := "Batchoy Bowl artifact recovered."
const BATCHOY_SERVED_CLUE := "La Paz Batchoy served to Grandma."

const FIRST_CONVERSATION: Array[Dictionary] = [
	{"speaker": "You", "text": "Lolaaa! I crossed half of Iloilo and survived a jeepney ride. Tani proud ka sakon!", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Lola Lynn", "text": "Apo! Ay, ari ka na! Come here, come here.", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "Lola Lynn", "text": "Naku, you're so thin now! Nagkaon ka na bala?", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "You", "text": "Working on it po. I found this in your package.", "portrait": PLAYER_PORTRAIT},
	{"speaker": "You", "text": "It describes a La Paz dish. But I don't remember the name...", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Lola Lynn", "text": "Huh...", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "Lola Lynn", "text": "That's strange.", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "Lola Lynn", "text": "I don't remember storing a newspaper in your package.", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "Lola Lynn", "text": "The contents of the newspaper... are familiar?", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "Lola Lynn", "text": "It's like having a memory that's not mine...", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "Lola Lynn", "text": "...", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "You", "text": "Lola?", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Lola Lynn", "text": "Soft miki. Deep, salty broth. Meat... something crisp. An egg. Fresh herbs. Warm seasoning.", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "You", "text": "So... you do remember?", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Lola Lynn", "text": "I'm getting old na, Jobert.", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "Lola Lynn", "text": "I need to buy my medicine. Make dinner while I am out, ha? Palihog lang, Jobert.", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "You", "text": "Sige po, no worries, La. I'll bring this dish home.", "portrait": PLAYER_PORTRAIT},
]

const REPEAT_CONVERSATION: Array[Dictionary] = [
	{"speaker": "You", "text": "Quick memory check: soft noodles, tender meat, salty broth, crisp topping. Did I miss anything?", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Lola Lynn", "text": "Yes. Legible handwriting. But the food clues are right.", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "You", "text": "Cruel. Accurate, but cruel.", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Lola Lynn", "text": "That is what grandmothers are for. Go carefully, apo—and come home hungry.", "portrait": GRANDMA_PORTRAIT},
]

const RESTORED_CONVERSATION: Array[Dictionary] = [
	{"speaker": "You", "text": "Verdict, Grandma. Does it taste like the one in your memory?", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Lola Lynn", "text": "It tastes like home—meat, fresh miki, ginamos, chicharon, herbs, seasoning, egg... and you hovering over me like a nervous waiter.", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "You", "text": "I nearly fought half the market for that bowl. I'm allowed to hover.", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Lola Lynn", "text": "Then sit. Memories are better when they have someone to return to.", "portrait": GRANDMA_PORTRAIT},
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
		return "Press F to talk about the restored Batchoy"
	return "Press F to talk to Grandma"


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
	dialogue.start_conversation(conversation, self)
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
		GameState.add_clue("Lola Lynn remembers seven sensory clues: miki, meat, salty depth, crisp topping, egg, herbs, and seasoning.")
		GameState.set_objective("Ask the people of La Paz about Grandma's memories.")
		GameState.set_ambot_status("La Paz Market marked in Maps")
		GameState.push_ambot_notification(
			"grandma_clues",
			"Grandma's testimony recorded",
			"A new search area is available in Maps."
		)
		GameState.set_grandma_left_for_medicine(true)

	if _player != null and is_instance_valid(_player):
		_player.can_move = _player_was_movable
		_player.set_process_unhandled_input(true)
		_player.capture_mouse()

	_dialogue_active = false
