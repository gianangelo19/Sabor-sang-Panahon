extends "res://scripts/two_person_npc_dialogue.gd"

const VENDOR_PORTRAIT := preload("res://characters/npc_market_vendor2/npc_market_vendor2_front.png")


func _ready() -> void:
	npc_display_name = "Market Vendor 2"
	npc_portrait = VENDOR_PORTRAIT
	minigame_title = "Prepare the Meat Portions"
	minigame_instructions = "Placeholder for Vendor 2's minigame. Replace this with your ingredient-preparation challenge and emit minigame_won when the player succeeds."
	reward_id = "pork_and_liver"
	reward_name = "Pork and liver"
	destination_id = "market_vendor_2"
	first_conversation = [
		player_line("The other vendor could identify fresh miki, but not the dish it belonged to. Do you remember it?"),
		npc_line("Miki in hot broth with garlic and a crisp topping... No. That should mean something to me, but it does not."),
		player_line("Grandma forgot it too. It is as if the whole city lost the same memory."),
		npc_line("That is impossible, and yet even old customers have stopped mentioning dishes they once ordered every week."),
		player_line("Could pork and liver have been part of the bowl?"),
		npc_line("They feel right. My hands remember preparing those cuts together, though my mind cannot remember why."),
		player_line("May I take a portion to test with the miki?"),
		npc_line("Help me prepare today's portions first. Win the challenge and I will set aside pork and liver for you."),
		player_line("Maybe rebuilding the ingredients can rebuild the missing memory."),
		npc_line("I hope so. This forgetting feels too sudden to be natural."),
	]
	repeat_conversation = [
		player_line("Do the pork and liver bring the dish back?"),
		npc_line("Not yet. My hands recognize them together, but the name is still gone."),
	]
	sync_completion_from_game_state()


func _handle_minigame_won() -> void:
	GameState.complete_destination("market_vendor_2")
	GameState.unlock_destination("chicharon_vendor")
	GameState.select_destination("chicharon_vendor")
	GameState.add_clue("Market testimony: muscle memory connects pork and liver to the forgotten bowl.")
	GameState.set_objective("Find the chicharon vendor.")
	GameState.set_ambot_status("Chicharon vendor marked in Maps")
	GameState.push_ambot_notification(
		"market_vendor_2_clues",
		"Pork and liver acquired",
		"The chicharon vendor is now marked in Maps."
	)
