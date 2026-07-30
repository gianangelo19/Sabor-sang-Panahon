extends "res://game/characters/npcs/shared/two_person_npc_dialogue.gd"

const VENDOR_PORTRAIT := preload("res://assets/art/characters/npc_market_vendor/npc_market_vendor_front.png")


func _ready() -> void:
	npc_display_name = "Ate Telyn"
	npc_portrait = VENDOR_PORTRAIT
	minigame_title = "Find the Right Meat Cuts"
	minigame_instructions = "Claim the required cuts before the other customers and reject spoiled meat."
	reward_id = "pork_and_liver"
	reward_name = "Meat"
	destination_id = "market_vendor_1"
	first_conversation = [
		player_line("Ate Telyn!"),
		npc_line("Hoy, Jobert! Dugay ka na wala kabalik ba!"),
		npc_line("Ano, Lola Lynn sent you?"),
		player_line("Not exactly po. She's acting weird—she couldn't recall what's in this newspaper."),
		npc_line("Ehh? Your Lola Lynn always gives me the mystery and keeps the easy work."),
		player_line("Miki. Deep, salty broth. Meat. Something crisp?"),
		npc_line("And pork and liver. I cut those beside her for years."),
		player_line("So you remember?"),
		npc_line("I think so... but I can't confirm pa."),
		npc_line("Find the belly, atay, at lapay around here. Then you can keep it for free."),
		player_line("Same welcome as always."),
	]
	repeat_conversation = [
		player_line("Still making me work?"),
		npc_line("Close friends do not raise lazy grandchildren."),
		player_line("But I'm not your grandchild...?"),
		npc_line("Tell that to your Lola."),
	]
	reward_conversation = [
		npc_line("There. Pork and liver—the first pieces of your mystery."),
		player_line("Salamat gid, Ate. One clue down, six to go."),
	]
	sync_completion_from_game_state()


func _handle_minigame_won() -> void:
	GameState.complete_destination("market_vendor_1")
	GameState.unlock_destination("market_vendor_2")
	GameState.select_destination("market_vendor_2")
	GameState.add_clue("Ate Telyn remembers cutting pork and liver beside Lola Lynn.")
	GameState.set_objective("Talk to the ginamos vendor.")
	GameState.set_ambot_status("Second market testimony marked in Maps")
	GameState.push_ambot_notification(
		"market_vendor_1_clues",
		"Meat acquired",
		"The ginamos vendor is now marked in Maps."
	)


func _handle_first_conversation_started() -> void:
	GameState.set_grandma_left_for_medicine(true)
