extends "res://scripts/two_person_npc_dialogue.gd"

const VENDOR_PORTRAIT := preload("res://characters/npc_market_vendor2/npc_market_vendor2_front.png")
const GUINAMOS_MINIGAME := preload(
	"res://minigames-main/guinamos_jar_pick/scenes/guinamos_jar_pick.tscn"
)


func _ready() -> void:
	npc_display_name = "Market Vendor 2"
	npc_portrait = VENDOR_PORTRAIT
	minigame_title = "Choose the Right Ginamos"
	minigame_instructions = "Inspect the five jars through your senses and identify the best-aged ginamos."
	minigame_scene = GUINAMOS_MINIGAME
	reward_id = "ginamos"
	reward_name = "Ginamos (shrimp paste)"
	destination_id = "market_vendor_2"
	first_conversation = [
		player_line("The meat vendor remembered preparing pork and liver, but not the dish they belonged to. Do you remember it?"),
		npc_line("Meat with soft noodles, a deep salty taste, and a crisp topping... No. That should mean something to me, but it does not."),
		player_line("Grandma forgot it too. It is as if the whole city lost the same memory."),
		npc_line("That is impossible, and yet even old customers have stopped mentioning dishes they once ordered every week."),
		player_line("Could ginamos have seasoned the broth?"),
		npc_line("Yes, just a little shrimp paste for depth. I cannot recall the recipe, but I still know the scent, color, and age good ginamos should have."),
		player_line("May I take some to test with the pork and liver?"),
		npc_line("First, choose the proper jar from these five. They look alike at a glance, so inspect them closely and trust the clues each sense gives you."),
		player_line("Then I should learn what separates the right jar from one that is too fresh, salty, watery, or spoiled."),
		npc_line("That is the idea. Choose wisely, and the best-aged ginamos is yours for the broth."),
	]
	repeat_conversation = [
		player_line("Does the ginamos bring the broth back to you?"),
		npc_line("Only the amount I would add. The dish and its name are still gone."),
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
