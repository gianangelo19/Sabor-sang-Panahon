extends "res://game/characters/npcs/shared/two_person_npc_dialogue.gd"

const TINDERO_PORTRAIT := preload("res://assets/art/characters/npc_tindero/npc_tindero_front.png")
const MINIGAME_SCENE := preload(
	"res://features/minigames/miki_noodle_crank/scenes/miki_noodle_crank.tscn"
)


func _ready() -> void:
	npc_display_name = "Tito Bobet"
	npc_portrait = TINDERO_PORTRAIT
	minigame_title = "Crank the Miki Noodles"
	minigame_instructions = "Keep the machine's tension in the safe zone until the noodle batch is complete."
	minigame_scene = MINIGAME_SCENE
	reward_id = "fresh_miki"
	reward_name = "Fresh miki noodles"
	destination_id = "tindero"
	required_item_id = "crank_handle"
	required_item_name = "crank handle"
	consume_required_item = true
	first_conversation = [
		npc_line("Uyyyy Jobert!"),
		player_line("Tito Bobet! Balita ko nga kasal ka na subong? Himala ah!"),
		npc_line("Aba syempre! Ako pa! Baka Tito Bobet to!"),
		player_line("Looks like he's drunk again..."),
		player_line("Anyways, have you ever seen or heard of this dish before po? Lola Lynn forgot the name. Fresh miki is the last clue."),
		npc_line("Lynn forgot? Ay sus. Then we make the kind she always bought."),
		player_line("You remember po?"),
		npc_line("The texture? Yes. The name? Never heard of it."),
		player_line("How do I make it?"),
		npc_line("First, help me find my crank handle."),
		npc_line("If I remember correctly... there's a fat cat near 6-Eleven that likes stealing my things."),
		player_line("A fat cat near 6-Eleven? That sounds like Milk, maybe."),
		player_line("Sige po, I'll try to find the cat."),
	]
	repeat_conversation = [
		player_line("Still looking for your crank. Milk has expensive taste."),
		npc_line("Check near 6-Eleven. Find Bjorn first; Milk listens to him more than me."),
	]
	reward_conversation = [
		npc_line("Fresh miki. Soft, not forced—just how Lynn always wanted it."),
		player_line("Seven ingredients. Now I just need the name."),
	]
	sync_completion_from_game_state()

func _get_conversation_entries(is_repeat: bool) -> Array[Dictionary]:
	if is_repeat and GameState.has_inventory_item(required_item_id):
		return [
			npc_line("Uy! You found it... was it from the cat?"),
			player_line("Yes po, still fat as ever."),
			player_line("Anyways, back to the miki noodles."),
			npc_line("Sige ah. Let's get you those noodles."),
		]
	return repeat_conversation if is_repeat else first_conversation

func _handle_required_item_missing() -> void:
	GameState.set_story_flag("miki_crank_requested")
	GameState.set_objective("Find the fat cat near 6-Eleven to retrieve the stolen crank.")
	GameState.set_ambot_status("Crank handle search active near 6-Eleven")


func _handle_minigame_won() -> void:
	GameState.complete_destination("tindero")
	GameState.add_clue("Tito Bobet's fresh miki completes the seven-ingredient set.")
	# This is the final ordered vendor reward. Set the next objective directly so
	# no earlier crank-search text can survive after fresh miki is awarded.
	GameState.set_objective(GameState.PHYSICAL_EVIDENCE_OBJECTIVE)
	GameState.set_ambot_status("7/7 ingredients collected - search the La Paz house")
	GameState.push_ambot_notification(
		"tindero_miki_clue",
		"All seven ingredients collected",
		"Return to the La Paz house and search for physical evidence."
	)
