extends "res://game/characters/npcs/shared/two_person_npc_dialogue.gd"

const VENDOR_PORTRAIT := preload("res://assets/art/characters/npc_market_vendor/npc_market_vendor_front.png")


func _ready() -> void:
	npc_display_name = "Meat Vendor"
	npc_portrait = VENDOR_PORTRAIT
	minigame_title = "Find the Right Meat Cuts"
	minigame_instructions = "Claim the required cuts before the other customers and reject spoiled meat."
	reward_id = "pork_and_liver"
	reward_name = "Meat"
	destination_id = "market_vendor_1"
	first_conversation = [
		player_line("Excuse me, Nang. My grandma remembers a La Paz noodle dish, except for the useful part—the name."),
		npc_line("So you came to a meat stall with a mystery. Better than the man who asked if pork was vegetarian."),
		player_line("She remembers soft noodles, tender meat, a salty broth, and something crisp on top."),
		npc_line("Pork and liver. My hands already know the cuts—belly, atay, lapay. Strange. The knife remembers, but I don't."),
		player_line("Everyone keeps saying that. How does a whole city lose the same word?"),
		npc_line("In this market? We cannot lose gossip for five minutes. But this dish vanished, and nobody even noticed the empty space."),
		player_line("Could I take the right cuts to Grandma? Maybe the taste will pull the memory loose."),
		npc_line("Earn them. Find the belly, atay, and lapay before the crowd does. And no spoiled meat—your grandmother will blame me, then haunt my stall while still alive."),
		player_line("Fast hands, good eyes, no accidental poisoning. Comforting standards."),
		npc_line("You joke now. Wait until three aunties reach for the same cut. Survive that, and the meat is yours."),
	]
	repeat_conversation = [
		player_line("Still getting that strange almost-memory when you cut the liver?"),
		npc_line("Every time. My hands say yes; my head says, 'Please hold.' Very poor customer service."),
	]
	sync_completion_from_game_state()


func _handle_minigame_won() -> void:
	GameState.complete_destination("market_vendor_1")
	GameState.unlock_destination("market_vendor_2")
	GameState.select_destination("market_vendor_2")
	GameState.add_clue("Market testimony: pork and liver feel connected, but the vendor cannot remember the dish.")
	GameState.set_objective("Talk to the ginamos vendor.")
	GameState.set_ambot_status("Second market testimony marked in Maps")
	GameState.push_ambot_notification(
		"market_vendor_1_clues",
		"Meat acquired",
		"The ginamos vendor is now marked in Maps."
	)


func _handle_first_conversation_started() -> void:
	GameState.set_grandma_left_for_medicine(true)
