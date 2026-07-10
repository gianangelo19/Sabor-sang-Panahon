extends "res://scripts/two_person_npc_dialogue.gd"

const VENDOR_PORTRAIT := preload("res://characters/npc_market_vendor/npc_market_vendor_front.png")


func _ready() -> void:
	npc_display_name = "Market Vendor"
	npc_portrait = VENDOR_PORTRAIT
	minigame_title = "Sort the Miki Bundles"
	minigame_instructions = "Placeholder for Vendor 1's minigame. Replace this with your noodle-sorting challenge and emit minigame_won when the player succeeds."
	reward_id = "fresh_miki"
	reward_name = "Fresh miki noodles"
	destination_id = "market_vendor_1"
	first_conversation = [
		player_line("Excuse me. My grandma remembers an old noodle dish from this neighborhood, but she cannot remember its name."),
		npc_line("An old dish from La Paz? Strange... people ask me about noodles every day, but no dish comes to mind."),
		player_line("Hot broth, soft noodles, plenty of garlic, and something crisp on top."),
		npc_line("Those ingredients are familiar on their own. Fresh miki would fit, yet when I picture the complete bowl, there is only a blank."),
		player_line("How could a local dish disappear from everyone's memory so suddenly?"),
		npc_line("I wish I knew. I have worked here for years, and it feels like a word was quietly taken from us."),
		player_line("Could I take some fresh miki? Maybe the ingredient will help Grandma remember."),
		npc_line("Help me sort these noodle bundles first. Finish the task and I will give you a fresh batch."),
		player_line("Deal. Then I'll ask the other vendors if this missing memory feels familiar to them too."),
		npc_line("Please do. I cannot shake the feeling that we should all know what you are describing."),
	]
	repeat_conversation = [
		player_line("Does the forgotten bowl still sound familiar?"),
		npc_line("Only the fresh miki. The dish itself remains an empty space in my memory."),
	]
	sync_completion_from_game_state()


func _handle_minigame_won() -> void:
	GameState.complete_destination("market_vendor_1")
	GameState.unlock_destination("market_vendor_2")
	GameState.select_destination("market_vendor_2")
	GameState.add_clue("Market testimony: fresh miki feels connected, but the vendor cannot remember the dish.")
	GameState.set_objective("Talk to the second market vendor.")
	GameState.set_ambot_status("Second market testimony marked in Maps")
	GameState.push_ambot_notification(
		"market_vendor_1_clues",
		"Fresh miki acquired",
		"The second market vendor is now marked in Maps."
	)
