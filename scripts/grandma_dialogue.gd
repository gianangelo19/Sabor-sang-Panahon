extends Node3D

const DIALOGUE_SCENE := preload("res://dialogue_ui.tscn")
const GRANDMA_PORTRAIT := preload("res://characters/npc_grandma/npc_grandma_front.png")
const PLAYER_PORTRAIT := preload("res://characters/2main_character_asking.png")
const ARTIFACT_RECOVERED_CLUE := "Batchoy Bowl artifact recovered."
const BATCHOY_SERVED_CLUE := "La Paz Batchoy served to Grandma."

const FIRST_CONVERSATION: Array[Dictionary] = [
	{"speaker": "You", "text": "Grandma! I crossed half of Iloilo and survived a jeepney ride with no suspension. Please look impressed.", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Grandma", "text": "Apo! Come here. Let me look at you. Ay—thinner. Are they not feeding you, or are you spending everything on iced coffee again?", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "You", "text": "Both can be true. How are you feeling?", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Grandma", "text": "Old enough to dislike that question. A little tired, nothing dramatic. Now, why are you holding that newspaper like a detective?", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "You", "text": "I found it damaged. It's about an old La Paz dish—broth, noodles, the market, and an old-timer. I thought you might remember.", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Grandma", "text": "Hmm. Soft noodles. Tender meat. A broth salty enough to wake you up. And something crisp on top that disappeared before the bowl reached the table.", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "You", "text": "That sounds very specific for someone who doesn't remember the name.", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Grandma", "text": "My hands remember more than my head. I can hear bowls clinking, vendors shouting, rain on the roof... but the name? Blank.", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "Grandma", "text": "The smell used to reach the street. On wet afternoons, people squeezed inside dripping everywhere and still left smiling.", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "You", "text": "Then I'll ask around. If the whole neighborhood ate it, somebody has to remember.", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Grandma", "text": "Good. I need to buy my medicine anyway. Apparently stubbornness is not a complete treatment.", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "You", "text": "Be back before dinner. If I find the dish, we make it together.", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Grandma", "text": "Deal. And apo? Follow the clues, not every stranger offering free food. Use judgment—then bring me some.", "portrait": GRANDMA_PORTRAIT},
]

const REPEAT_CONVERSATION: Array[Dictionary] = [
	{"speaker": "You", "text": "Quick memory check: soft noodles, tender meat, salty broth, crisp topping. Did I miss anything?", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Grandma", "text": "Yes. Legible handwriting. But the food clues are right.", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "You", "text": "Cruel. Accurate, but cruel.", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Grandma", "text": "That is what grandmothers are for. Go carefully, apo—and come home hungry.", "portrait": GRANDMA_PORTRAIT},
]

const RESTORED_CONVERSATION: Array[Dictionary] = [
	{"speaker": "You", "text": "Verdict, Grandma. Does it taste like the one in your memory?", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Grandma", "text": "It tastes like home—meat, fresh miki, ginamos, chicharon... and you hovering over me like a nervous waiter.", "portrait": GRANDMA_PORTRAIT},
	{"speaker": "You", "text": "I nearly fought half the market for that bowl. I'm allowed to hover.", "portrait": PLAYER_PORTRAIT},
	{"speaker": "Grandma", "text": "Then sit. Memories are better when they have someone to return to.", "portrait": GRANDMA_PORTRAIT},
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
