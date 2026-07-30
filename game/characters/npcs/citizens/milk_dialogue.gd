extends "res://game/characters/npcs/shared/ambient_npc_dialogue.gd"

const PLAYER_PORTRAIT := preload("res://assets/art/characters/2main_character_asking.png")

var _releasing_crank := false


func _ready() -> void:
	npc_display_name = "Milk"


func _build_conversation() -> Array[Dictionary]:
	_releasing_crank = (
		GameState.has_story_flag("bjorn_crank_talked")
		and not GameState.has_story_flag("milk_released_crank")
	)
	if _releasing_crank:
		return [
			_player_line("Milk..."),
			_npc_line("Meooww... Mrraaww."),
			_player_line("Yeah... got a lot to say, huh?"),
			_npc_line("Mrrrp."),
			_player_line("Woah, let's not get too political."),
			_npc_line("Mrawww."),
			_player_line("Anyway, I was wondering if you stole a crank handle from Tito Bobet."),
			_npc_line("Meoww mrow."),
			_player_line("Oh, you're just gonna give it to me? Well, that was easy."),
			_player_line("Thanks, bud."),
		]
	if GameState.has_story_flag("miki_crank_requested"):
		return [
			_npc_line("Mrrrow."),
			_player_line("You know why I'm here, but you're pretending not to. I should ask Bjorn first."),
		]
	return [
		_npc_line("Mrrrow."),
		_player_line("Milk. You got wider."),
		_npc_line("Mrrp."),
		_player_line("You are shaped like a pandesal. This is an observation, not a feeding contract."),
	]


func _on_dialogue_finished() -> void:
	super._on_dialogue_finished()
	if not _releasing_crank:
		return
	GameState.set_story_flag("milk_released_crank")
	GameState.set_objective("Pick up the crank beside Milk, then return it to Tito Bobet.")
	GameState.set_ambot_status("Stolen crank located near Milk")
	for item: Node in get_tree().get_nodes_in_group("collectible_world_item"):
		if str(item.get("item_id")) == "crank_handle" and item.has_method("set_active"):
			item.set_active(true)
	_releasing_crank = false


func _player_line(text: String) -> Dictionary:
	return {"speaker": "You", "text": text, "portrait": PLAYER_PORTRAIT}
