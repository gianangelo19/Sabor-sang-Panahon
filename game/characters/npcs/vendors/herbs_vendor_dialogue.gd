extends "res://game/characters/npcs/shared/two_person_npc_dialogue.gd"

const VENDOR_PORTRAIT := preload("res://assets/art/characters/npc_herbs_vendor/npc_herbs_vendor_front.png")


func _ready() -> void:
	npc_display_name = "Ate Mila"
	npc_portrait = VENDOR_PORTRAIT
	minigame_title = "Bundle the Fresh Herbs"
	minigame_instructions = "Placeholder: choose fragrant spring onion and toasted garlic for the bowl."
	reward_id = "fresh_herbs"
	reward_name = "Fresh herbs"
	destination_id = "herbs_vendor"
	first_conversation = [
		player_line("Ate Mila! Maayong hapon po."),
		npc_line("Jobert! Dugay ka na wala diri. Lola Lynn finally sent you grocery shopping?"),
		player_line("More like mystery shopping. She remembers a noodle dish, but we don't know the name."),
		npc_line("Let me hear the clues."),
		player_line("Pork and liver, ginamos... and something fragrant."),
		npc_line("Ah. Your lola always smelled the herbs before she bought them."),
		player_line("She still smells leftovers before trusting the date."),
		npc_line("Smart woman. A little spring onion and toasted garlic wake up a hot bowl."),
		player_line("So you know the dish?"),
		npc_line("The aroma, yes. The name is hiding from me too."),
		player_line("Can I buy some from you?"),
		npc_line("Sure, Jobert. Pick a fresh bundle for your lola."),
	]
	repeat_conversation = [
		player_line("These still look fresh, right?"),
		npc_line("If you need to ask, smell them again."),
	]
	reward_conversation = [
		npc_line("Spring onion and toasted garlic. Add them near the end."),
		player_line("My nose remembers before my tongue does. Got it."),
	]
	sync_completion_from_game_state()


func _handle_minigame_won() -> void:
	GameState.complete_destination("herbs_vendor")
	GameState.unlock_destination("seasoning_vendor")
	GameState.select_destination("seasoning_vendor")
	GameState.add_clue("Ate Mila remembers the aroma of spring onion and toasted garlic.")
	GameState.set_objective("Buy warm seasoning from Kuya Jun.")
	GameState.set_ambot_status("Seasoning vendor marked in Maps")
	GameState.push_ambot_notification(
		"herbs_clues",
		"Fresh herbs acquired",
		"Kuya Jun's seasoning stall is the next lead."
	)
