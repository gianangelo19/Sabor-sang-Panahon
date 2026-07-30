extends "res://game/characters/npcs/shared/two_person_npc_dialogue.gd"

const VENDOR_PORTRAIT := preload("res://assets/art/characters/npc_chicharon_vendor/npc_chicharon_vendor_front.png")


func _ready() -> void:
	npc_display_name = "Nong Andy"
	npc_portrait = VENDOR_PORTRAIT
	minigame_title = "Fry the Chicharon"
	minigame_instructions = "Follow the rhythm and lift enough pieces from the oil at perfect crispness."
	reward_id = "crushed_chicharon"
	reward_name = "Crushed chicharon"
	destination_id = "chicharon_vendor"
	first_conversation = [
		player_line("Nong Andy!"),
		npc_line("Jobert."),
		player_line("I'm trying to cook a dish from Lola's old recipe... any idea for a crisp topping?"),
		npc_line("Chicharon."),
		player_line("You didn't even ask about the dish."),
		npc_line("You smell like karne and ginamos."),
		npc_line("That is enough."),
		player_line("Okay... then can I have some po?"),
		npc_line("No."),
		player_line("Pretty please?"),
		npc_line("No."),
		player_line("..."),
		npc_line("..."),
		player_line("Uh—pretty, pretty please with chicharon on top? I'll help you fry them!"),
		npc_line("Hmm... okay."),
		player_line("Nayswan! You really love this job."),
		npc_line("...I love going home."),
	]
	repeat_conversation = [
		player_line("Still no extra words, Nong?"),
		npc_line("Crisp. Last. Good."),
	]
	reward_conversation = [
		npc_line("Keep the crackle."),
		player_line("Three words. New record."),
	]
	sync_completion_from_game_state()


func _handle_minigame_won() -> void:
	GameState.complete_destination("chicharon_vendor")
	GameState.unlock_destination("tindero")
	GameState.select_destination("tindero")
	GameState.add_clue("Nong Andy confirms crushed chicharon as the crisp topping.")
	GameState.set_objective("Talk to Tito Bobet about fresh miki noodles.")
	GameState.set_ambot_status("Tito Bobet marked in Maps")
	GameState.push_ambot_notification(
		"chicharon_clues",
		"Crushed chicharon acquired",
		"Tito Bobet's miki stall is the final ingredient lead."
	)
