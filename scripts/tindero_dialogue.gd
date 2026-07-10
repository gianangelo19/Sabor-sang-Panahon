extends "res://scripts/two_person_npc_dialogue.gd"

const TINDERO_PORTRAIT := preload("res://characters/npc_tindero/npc_tindero_front.png")


func _ready() -> void:
	npc_display_name = "Tindero"
	npc_portrait = TINDERO_PORTRAIT
	minigame_title = "Balance the Egg Tray"
	minigame_instructions = "Placeholder for the Tindero's egg minigame. Replace this with the egg-selling challenge and emit minigame_won when the player succeeds."
	reward_id = "egg"
	reward_name = "Fresh egg"
	destination_id = "tindero"
	first_conversation = [
		player_line("Nong, I am rebuilding an old La Paz noodle bowl. The vendors remembered miki, pork, liver, garlic, and chicharon."),
		npc_line("If that bowl needs richness on top, an egg may be what you are missing."),
		player_line("Grandma mentioned the dish felt warm and complete. An egg could help bring that memory back."),
		npc_line("I can spare one, but help me sort these trays first. I cannot sell cracked eggs at the stall."),
		player_line("I will be careful. If this works, Grandma might finally remember the dish."),
		npc_line("Then take your time, gha. Some memories are as fragile as eggs."),
	]
	repeat_conversation = [
		player_line("Do you still think the egg belongs in the bowl?"),
		npc_line("Yes. A fresh egg can make the broth feel whole."),
	]
	sync_completion_from_game_state()


func _handle_minigame_won() -> void:
	GameState.complete_destination("tindero")
	GameState.add_clue("Tindero testimony: a fresh egg may complete the remembered bowl.")
	GameState.set_objective("Review the gathered food clues with AMBot.")
	GameState.set_ambot_status("Ingredient profile ready for review")
	GameState.push_ambot_notification(
		"tindero_egg_clue",
		"Fresh egg acquired",
		"The collected food clues are ready for review."
	)
