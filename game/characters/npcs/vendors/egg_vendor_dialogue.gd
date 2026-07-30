extends "res://game/characters/npcs/shared/two_person_npc_dialogue.gd"

const VENDOR_PORTRAIT := preload("res://assets/art/characters/npc_egg_vendor/npc_egg_vendor_front.png")


func _ready() -> void:
	npc_display_name = "Nang Cora"
	npc_portrait = VENDOR_PORTRAIT
	minigame_title = "Sort the Fresh Eggs"
	minigame_instructions = "Placeholder: inspect the shells and choose the freshest eggs for Lola Lynn's bowl."
	reward_id = "fresh_egg"
	reward_name = "Fresh egg"
	destination_id = "egg_vendor"
	first_conversation = [
		npc_line("Apo ni Lynn! You're back!"),
		player_line("Hi, Nang Cora. I'm trying to rebuild a dish she almost remembers."),
		npc_line("Almost?"),
		player_line("Meat, ginamos, herbs, and seasoning. I still need something soft for the bowl."),
		npc_line("Then the bowl needs one more soft thing in the middle."),
		player_line("An egg?"),
		npc_line("Fresh egg. The hot broth cooks it gently. Your lola liked the yolk a little soft."),
		player_line("You remember the dish?"),
		npc_line("I remember her carrying the bowls. The name is gone, but the steam is not."),
		player_line("Can I buy one?"),
		npc_line("I'll give you some for free. Just choose the best eggs for your dish."),
		player_line("Everyone in this market has chores ready for me."),
		npc_line("Because everyone remembers you avoiding them."),
	]
	repeat_conversation = [
		player_line("No cracks. I checked twice."),
		npc_line("Good. Your lola only needed to look once."),
	]
	reward_conversation = [
		npc_line("A fresh egg. Crack it gently into the hot broth."),
		player_line("Exactly one egg and no wasted confidence."),
	]
	sync_completion_from_game_state()


func _handle_minigame_won() -> void:
	GameState.complete_destination("egg_vendor")
	GameState.unlock_destination("chicharon_vendor")
	GameState.select_destination("chicharon_vendor")
	GameState.add_clue("Nang Cora remembers Lola Lynn serving each bowl with a gently cooked egg.")
	GameState.set_objective("Find the chicharon vendor.")
	GameState.set_ambot_status("Chicharon vendor marked in Maps")
	GameState.push_ambot_notification(
		"egg_clues",
		"Fresh egg acquired",
		"The chicharon vendor is now marked in Maps."
	)
