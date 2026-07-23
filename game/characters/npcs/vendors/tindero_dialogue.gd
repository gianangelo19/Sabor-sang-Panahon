extends "res://game/characters/npcs/shared/two_person_npc_dialogue.gd"

const TINDERO_PORTRAIT := preload("res://assets/art/characters/npc_tindero/npc_tindero_front.png")


func _ready() -> void:
	npc_display_name = "Miki Tindero"
	npc_portrait = TINDERO_PORTRAIT
	minigame_title = "Crank the Miki Noodles"
	minigame_instructions = "Keep the machine's tension in the safe zone until the noodle batch is complete."
	reward_id = "fresh_miki"
	reward_name = "Fresh miki noodles"
	destination_id = "tindero"
	first_conversation = [
		player_line("Nong, I'm rebuilding a forgotten La Paz bowl. I have meat, ginamos, and chicharon. The miki is the last missing piece."),
		npc_line("Then it must be fresh miki—soft, springy, strong enough to carry broth without surrendering immediately."),
		player_line("Could I take a batch? Grandma is one taste away from remembering something important."),
		npc_line("Help me earn the machine's cooperation. Turn the crank steadily and watch the tension needle. This old thing has more moods than a teenager."),
		player_line("Keep the needle safe, keep the noodles moving, and avoid arguing with machinery. I can do two of those."),
		npc_line("Listen instead of fighting it, gha. Hold the rhythm until the batch is done, and the freshest miki is yours."),
	]
	repeat_conversation = [
		player_line("Still certain your miki belongs in Grandma's mystery bowl?"),
		npc_line("Certain enough to bet the machine. Not money—the machine complains less."),
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
