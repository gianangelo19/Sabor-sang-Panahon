extends "res://game/characters/npcs/shared/two_person_npc_dialogue.gd"

const VENDOR_PORTRAIT := preload("res://assets/art/characters/npc_market_vendor2/npc_market_vendor2_front.png")
const MINIGAME_SCENE := preload(
	"res://features/minigames/guinamos_jar_pick/scenes/guinamos_jar_pick.tscn"
)


func _ready() -> void:
	npc_display_name = "Kuya Boy"
	npc_portrait = VENDOR_PORTRAIT
	minigame_title = "Choose the Right Ginamos"
	minigame_instructions = "Inspect the five jars through your senses and identify the best-aged ginamos."
	minigame_scene = MINIGAME_SCENE
	reward_id = "ginamos"
	reward_name = "Ginamos (shrimp paste)"
	destination_id = "market_vendor_2"
	required_item_id = "empty_aged_jar"
	required_item_name = "empty jar"
	consume_required_item = true
	first_conversation = [
		npc_line("Uy, Jobert! Kamusta ka na?"),
		player_line("All goods po, Kuya Boy. How about you and tita?"),
		npc_line("Me? I'm fine, but tita's at the hospital right now. She's not feeling well."),
		player_line("Aww, tell her I'm hoping for her fast recovery!"),
		npc_line("I'll let her know. But what are you doing here? Visiting your lola?"),
		player_line("Lola Lynn can't name this dish I found in an old newspaper."),
		npc_line("Let me check. Hmm... miki noodles and meat? What do you have now?"),
		player_line("Ate Telyn just gave me pork and liver."),
		npc_line("Whew. Sounds like a heavy, gamey broth."),
		player_line("Is that bad?"),
		npc_line("It just needs a counterweight. It says it needs 'salty depth,' right? Tita uses ginamos with heavy meats. Maybe it would help."),
		player_line("Ehhhh... ginamos in a pork noodle soup?"),
		npc_line("Just a small spoonful. The sharp salt cuts right through the grease."),
		npc_line("I don't know the recipe, but culinary-wise, it'll help your cooking."),
		player_line("Wow, sige-sige. I'll keep my options open. Can I have some?"),
		npc_line("Sure, pero tita packed everything in bulk yesterday. I don't have an empty jar with me now."),
	]
	repeat_conversation = [
		player_line("Still no jar. I should search around Lola Lynn's place."),
		npc_line("Lolas always have a spare. Your backpack will thank you."),
	]
	reward_conversation = [
		npc_line("Good choice. Just enough salty depth—don't let it take over the broth."),
		player_line("Got it. Keep the lid tight and the mystery moving."),
	]
	sync_completion_from_game_state()

func _get_conversation_entries(is_repeat: bool) -> Array[Dictionary]:
	if is_repeat:
		if GameState.has_inventory_item(required_item_id):
			return [
				player_line("Yep, I got an empty jar."),
				npc_line("Good. Choose your ginamos wisely, ha?"),
			]
		return repeat_conversation

	var entries := first_conversation.duplicate(true)
	var has_jar := GameState.has_inventory_item(required_item_id)
	var yes_branch: Array[Dictionary]
	var no_branch: Array[Dictionary]
	if has_jar:
		yes_branch = [
			player_line("Yep, I got it while searching around."),
			npc_line("Good. Choose your ginamos wisely, ha?"),
		]
		no_branch = [
			player_line("No...? Wait, let me check my backpack."),
			player_line("Oh. I do have one. I don't know why, though."),
			npc_line("I guess your backpack didn't want to smell like ginamos."),
		]
	else:
		yes_branch = [
			player_line("Yes... I think?"),
			npc_line("Do you want your bag to smell like ginamos?"),
			player_line("No..."),
		]
		no_branch = [
			player_line("I don't think so..."),
			npc_line("Check your lola's house. Lolas always have a spare."),
		]
	entries.append(choice_line("KUYA BOY: Do you have an empty jar?", [
		{"id": "jar_yes", "text": "Yes, I have one.", "entries": yes_branch},
		{"id": "jar_no", "text": "No, not yet.", "entries": no_branch},
	]))
	return entries


func _handle_minigame_won() -> void:
	GameState.complete_destination("market_vendor_2")
	GameState.unlock_destination("herbs_vendor")
	GameState.select_destination("herbs_vendor")
	GameState.add_clue("Kuya Boy identifies ginamos as the broth's salty depth.")
	GameState.set_objective("Buy fresh herbs from Ate Mila.")
	GameState.set_ambot_status("Herbs vendor marked in Maps")
	GameState.push_ambot_notification(
		"market_vendor_2_clues",
		"Ginamos acquired",
		"Ate Mila's herbs stall is the next lead."
	)
