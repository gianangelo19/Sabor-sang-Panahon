extends "res://scripts/two_person_npc_dialogue.gd"

const VENDOR_PORTRAIT := preload("res://characters/npc_chicharon_vendor/npc_chicharon_vendor_front.png")


func _ready() -> void:
	npc_display_name = "Chicharon Vendor"
	npc_portrait = VENDOR_PORTRAIT
	minigame_title = "Fry the Chicharon"
	minigame_instructions = "Follow the rhythm and lift enough pieces from the oil at perfect crispness."
	reward_id = "crushed_chicharon"
	reward_name = "Crushed chicharon"
	destination_id = "chicharon_vendor"
	first_conversation = [
		player_line("I'm hunting for the crisp topping of a noodle dish nobody can name."),
		npc_line("A mystery topping at my stall? Careful. The chicharon can hear you flattering it."),
		player_line("So far: meat, ginamos in the broth, something crunchy on top, and fresh miki still missing."),
		npc_line("Crushed chicharon fits. Even that little crackle feels familiar... but the dish behind it is all fog."),
		player_line("The other vendors remember what their hands did, just not why they did it."),
		npc_line("People forget birthdays, umbrellas, sometimes a child at the sari-sari store. Iloilo does not forget food. Something is wrong."),
		player_line("Can I get some for Grandma's bowl? Maybe the crunch will wake the memory."),
		npc_line("Help with this batch. Listen to the oil and lift each piece at the perfect beat. Too early: rubber. Too late: family shame."),
		player_line("No pressure. Just rhythm, boiling oil, and the honor of my bloodline."),
		npc_line("Now you understand chicharon. Keep the batch crisp, and the best pieces are yours."),
	]
	repeat_conversation = [
		player_line("Has the chicharon remembered the dish yet? You said it could hear us."),
		npc_line("It remains deliciously silent. But yes—it belongs in that bowl. My bones are sure, even if my brain is lazy."),
	]
	sync_completion_from_game_state()


func _handle_minigame_won() -> void:
	GameState.complete_destination("chicharon_vendor")
	GameState.unlock_destination("tindero")
	GameState.select_destination("tindero")
	GameState.add_clue("Vendor testimony: crushed chicharon fits the bowl, but its identity remains forgotten.")
	GameState.set_objective("Talk to the tindero for fresh miki noodles.")
	GameState.set_ambot_status("Tindero marked in Maps")
	GameState.push_ambot_notification(
		"chicharon_clues",
		"Crushed chicharon acquired",
		"The tindero is now marked in Maps."
	)
