extends "res://scripts/two_person_npc_dialogue.gd"

const TINDERO_PORTRAIT := preload("res://characters/npc_tindero/npc_tindero_front.png")
const MIKI_MINIGAME := preload(
	"res://minigames-main/chicharon_beat/scripts/miki_noodle_crank.tscn"
)


func _ready() -> void:
	npc_display_name = "Tindero"
	npc_portrait = TINDERO_PORTRAIT
	minigame_title = "Crank the Miki Noodles"
	minigame_instructions = "Keep the machine's tension in the safe zone until the noodle batch is complete."
	minigame_scene = MIKI_MINIGAME
	reward_id = "fresh_miki"
	reward_name = "Fresh miki noodles"
	destination_id = "tindero"
	first_conversation = [
		player_line("Nong, I am rebuilding an old La Paz noodle bowl. I have meat, ginamos, and crushed chicharon, but I still need the miki noodles."),
		npc_line("Then you need fresh miki. Soft, springy noodles are what a bowl like that calls for."),
		player_line("Could I take a batch? It may be the last piece Grandma needs to remember the dish."),
		npc_line("You can earn one by helping with this old noodle machine. Turn the crank steadily and watch the tension needle—it likes to drift when your rhythm slips."),
		player_line("So I must keep the needle in the safe range while the noodles come through, without losing the progress I have made."),
		npc_line("Exactly, gha. Hold that balance until the batch is finished, and the freshest miki will be yours."),
	]
	repeat_conversation = [
		player_line("Do you still think fresh miki belongs in the bowl?"),
		npc_line("Yes. Those noodles are made to carry a rich, savory broth."),
	]
	sync_completion_from_game_state()


func _handle_minigame_won() -> void:
	GameState.complete_destination("tindero")
	GameState.add_clue("Tindero testimony: fresh miki noodles complete the set of four ingredients.")
	GameState.begin_physical_evidence_search()
	GameState.push_ambot_notification(
		"tindero_miki_clue",
		"All four ingredients collected",
		"Return to the La Paz house and search for physical evidence."
	)
