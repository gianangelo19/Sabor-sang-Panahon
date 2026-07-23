extends "res://game/characters/npcs/shared/two_person_npc_dialogue.gd"

const VENDOR_PORTRAIT := preload("res://assets/art/characters/npc_market_vendor2/npc_market_vendor2_front.png")


func _ready() -> void:
	npc_display_name = "Ginamos Vendor"
	npc_portrait = VENDOR_PORTRAIT
	minigame_title = "Choose the Right Ginamos"
	minigame_instructions = "Inspect the five jars through your senses and identify the best-aged ginamos."
	reward_id = "ginamos"
	reward_name = "Ginamos (shrimp paste)"
	destination_id = "market_vendor_2"
	first_conversation = [
		player_line("The meat vendor's hands remembered pork and liver. Her brain filed no report. Does that sound familiar?"),
		npc_line("Very. I judge jars by scent, color, age. Ask what dish they belong to and—pfft—my memory closes the stall."),
		player_line("Grandma has the same gap. Like the whole city agreed to forget and forgot the meeting too."),
		npc_line("Impossible... yet old customers stopped asking for one regular order. I remember missing them, but not what they ordered. That bothers me."),
		player_line("Could ginamos have seasoned the broth?"),
		npc_line("A little. Enough to deepen it, not enough to announce itself from across the street. Good ginamos has manners. Bad ginamos enters before you do."),
		player_line("Can I take some to test with the meat?"),
		npc_line("Choose the proper jar from five. Trust the scent, color, and texture; labels can lie, but noses gossip honestly."),
		player_line("And if I pick the watery or spoiled one?"),
		npc_line("Then your face will tell me before your mouth does. Pick well, and the best-aged jar is yours."),
	]
	repeat_conversation = [
		player_line("Any luck remembering what the ginamos belonged to?"),
		npc_line("Only the exact spoonful. Apparently my memory kept the measurement and threw away the label."),
	]
	sync_completion_from_game_state()


func _handle_minigame_won() -> void:
	GameState.complete_destination("market_vendor_2")
	GameState.unlock_destination("chicharon_vendor")
	GameState.select_destination("chicharon_vendor")
	GameState.add_clue("Market testimony: ginamos belongs in the broth, but the vendor cannot remember the dish.")
	GameState.set_objective("Find the chicharon vendor.")
	GameState.set_ambot_status("Chicharon vendor marked in Maps")
	GameState.push_ambot_notification(
		"market_vendor_2_clues",
		"Ginamos acquired",
		"The chicharon vendor is now marked in Maps."
	)
