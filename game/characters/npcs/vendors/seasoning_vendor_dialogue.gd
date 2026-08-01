extends "res://game/characters/npcs/shared/two_person_npc_dialogue.gd"

const VENDOR_PORTRAIT := preload("res://assets/art/characters/npc_seasoning_vendor/npc_seasoning_vendor_front.png")


func _ready() -> void:
	npc_display_name = "Kuya Jun"
	npc_portrait = VENDOR_PORTRAIT
	minigame_title = "Measure the Seasoning"
	minigame_instructions = "Balance black pepper and seasoning without hiding the meat."
	dialogue_only_reward = true
	reward_id = "seasoning"
	reward_name = "Warm seasoning"
	destination_id = "seasoning_vendor"
	first_conversation = [
		npc_line("Jobert. You look like someone carrying too many opinions about soup."),
		player_line("Seven ingredients, actually. I'm collecting them one clue at a time."),
		npc_line("Worse. What does the broth need?"),
		player_line("Something warm. Peppery, maybe. Pero Kuya Boy already gave me ginamos."),
		npc_line("Then salt is not the answer. Balance is."),
		player_line("You sound like AMbot."),
		npc_line("I was measuring properly before your phone learned to talk."),
		player_line("Fair point."),
		npc_line("Black pepper wakes the broth. A small amount of seasoning rounds it out. Too much hides the meat."),
		player_line("Did Lola Lynn buy that blend here?"),
		npc_line("Always. Then she told me my scoop was heavy, even when it was not."),
		player_line("That sounds exactly like her. I'll buy some, Kuya Jun."),
		npc_line("Sure, no problemo. Measure it properly."),
	]
	repeat_conversation = [
		player_line("Was that scoop really exact?"),
		npc_line("Close enough for dinner. Not close enough for my shelf."),
	]
	reward_conversation = [
		npc_line("Pepper first. Taste before you add anything else."),
		player_line("Measured twice. Lola would approve once."),
	]
	sync_completion_from_game_state()


func _handle_minigame_won() -> void:
	GameState.complete_destination("seasoning_vendor")
	GameState.unlock_destination("egg_vendor")
	GameState.select_destination("egg_vendor")
	GameState.add_clue("Kuya Jun remembers balancing the broth with black pepper and warm seasoning.")
	GameState.set_objective("Choose a fresh egg from Nang Cora.")
	GameState.set_ambot_status("Egg vendor marked in Maps")
	GameState.push_ambot_notification(
		"seasoning_clues",
		"Seasoning acquired",
		"Nang Cora's egg stall is the next lead."
	)
