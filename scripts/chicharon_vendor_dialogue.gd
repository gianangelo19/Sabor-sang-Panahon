extends "res://scripts/two_person_npc_dialogue.gd"

const VENDOR_PORTRAIT := preload("res://characters/npc_chicharon_vendor/npc_chicharon_vendor_front.png")
const CHICHARON_MINIGAME := preload(
	"res://minigames-main/chicharon_beat/scenes/chicharon_beat.tscn"
)


func _ready() -> void:
	npc_display_name = "Chicharon Vendor"
	npc_portrait = VENDOR_PORTRAIT
	minigame_title = "Fry the Chicharon"
	minigame_instructions = "Follow the rhythm and lift enough pieces from the oil at perfect crispness."
	minigame_scene = CHICHARON_MINIGAME
	reward_id = "crushed_chicharon"
	reward_name = "Crushed chicharon"
	destination_id = "chicharon_vendor"
	first_conversation = [
		player_line("I'm looking for a crisp topping from a noodle dish nobody seems able to remember."),
		npc_line("Nobody remembers it? Even here in La Paz? Tell me what was in the bowl."),
		player_line("Meat, ginamos in the broth, and something crunchy scattered on top. I still need the miki noodles."),
		npc_line("Crushed chicharon would match that texture. But the dish... no. It is like a sign after all its letters have faded."),
		player_line("The other vendors remember preparing ingredients, but not what they were for."),
		npc_line("Then this is bigger than one forgotten recipe. People in Iloilo do not simply forget food that shaped their lives."),
		player_line("Could you give me some crushed chicharon? I want to rebuild the bowl for Grandma."),
		npc_line("Help me with this batch first. Listen to the frying rhythm and lift each piece when it turns perfectly crisp—not raw, and not burnt."),
		player_line("I will watch the oil and keep the timing steady until we have enough good pieces."),
		npc_line("Do that without wasting the batch, and I will crush the best chicharon for your grandmother's bowl."),
	]
	repeat_conversation = [
		player_line("Does crushed chicharon bring back the missing dish?"),
		npc_line("Only a feeling that it belongs in the bowl. The name itself is still missing."),
	]
	sync_completion_from_game_state()


func _handle_minigame_won() -> void:
	GameState.complete_destination("chicharon_vendor")
	GameState.unlock_destination("tindero")
	GameState.select_destination("tindero")
	GameState.add_clue("Vendor testimony: crushed chicharon fits the bowl, but its identity remains forgotten.")
	GameState.set_objective("Talk to the tindero for fresh miki noodles.")
	GameState.set_ambot_status("Tindero marked in Maps")
	GameState.push_ambot_notification(
		"chicharon_clues",
		"Crushed chicharon acquired",
		"The tindero is now marked in Maps."
	)
