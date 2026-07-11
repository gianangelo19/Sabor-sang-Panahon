extends "res://scripts/two_person_npc_dialogue.gd"

const VENDOR_PORTRAIT := preload("res://characters/npc_market_vendor/npc_market_vendor_front.png")
const MEAT_MINIGAME := preload(
	"res://minigames-main/snatch_battle/scenes/snatch_battle.tscn"
)


func _ready() -> void:
	npc_display_name = "Market Vendor"
	npc_portrait = VENDOR_PORTRAIT
	minigame_title = "Find the Right Meat Cuts"
	minigame_instructions = "Claim the required cuts before the other customers and reject spoiled meat."
	minigame_scene = MEAT_MINIGAME
	reward_id = "pork_and_liver"
	reward_name = "Meat"
	destination_id = "market_vendor_1"
	first_conversation = [
		player_line("Excuse me. My grandma remembers an old noodle dish from this neighborhood, but she cannot remember its name."),
		npc_line("An old dish from La Paz? Tell me what she remembers about the bowl."),
		player_line("Soft noodles, tender meat, a deep salty taste, and something crisp on top."),
		npc_line("Pork and liver feel right. My hands know exactly how I would portion them, but I cannot remember the dish they belonged to."),
		player_line("How could a local dish disappear from everyone's memory so suddenly?"),
		npc_line("I wish I knew. I have worked here for years, and it feels like a word was quietly taken from us."),
		player_line("Could I take the cuts that belong in that bowl? Maybe handling the right ingredients will help Grandma remember."),
		npc_line("You may, but the stall is crowded. Find the belly, atay, and lapay before another customer takes them, and keep spoiled or unwanted cuts out of the basket."),
		player_line("So I need to recognize the right pieces quickly, without grabbing whatever is closest."),
		npc_line("Exactly. Complete the order carefully, and I will set aside fresh meat for your grandmother's bowl."),
	]
	repeat_conversation = [
		player_line("Does the forgotten bowl still sound familiar?"),
		npc_line("Only the way I prepare the pork and liver. The dish itself remains an empty space in my memory."),
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
