extends "res://game/characters/npcs/shared/ambient_npc_dialogue.gd"

const PLAYER_PORTRAIT := preload("res://assets/art/characters/2main_character_asking.png")

var _core_conversation_active := false


func _ready() -> void:
	npc_display_name = "Bjorn"


func _build_conversation() -> Array[Dictionary]:
	_core_conversation_active = (
		GameState.has_story_flag("miki_crank_requested")
		and not GameState.has_story_flag("bjorn_crank_talked")
	)
	if _core_conversation_active:
		return [
			_player_line("Yo Bjorn! Long time no see!"),
			_player_line("Haven't seen you in a while. How you doing, Chat?"),
			_npc_line("Uyyyy Chat! Do you got a power bank with you?"),
			_npc_line("I still haven't bought that phone charger, heh..."),
			_player_line("I do... but seriously, you should buy a charger instead of going to 6-Eleven just to charge."),
			_npc_line("I could..."),
			_npc_line("But I won't. Because I'm not a capitalist, bro. It's for the love of the gameee, yeah?"),
			_player_line("A charger is a basic necessity in this era... Y'know what? Do what you gotta do, bro."),
			_npc_line("Hehe. Anyways, what brings you here, man?"),
			_player_line("I believe I'm looking for a crank handle that Milk stole?"),
			_npc_line("Ha? Crank handle? What for?"),
			_player_line("For Tito Bobet's miki machine. He told me a cat stole it."),
			_npc_line("And why do you think Milk stole it?"),
			_player_line("Because he said it was a fat cat near 6-Eleven. Like... a really fat cat."),
			_npc_line("...No comment, chat. I tried."),
			_player_line("So, do you think he stole it?"),
			_npc_line("Most likely. You should check on him, yeah?"),
		]
	if GameState.has_story_flag("bjorn_crank_talked"):
		return [
			_player_line("I missed talking to you, Bjorn. Hope to see you again soon."),
			_npc_line("I'll see you again soon, chat."),
		]
	return [
		_npc_line("Chat! My phone is charging inside. Capitalism remains temporarily defeated."),
		_player_line("You could also buy a charger."),
		_npc_line("That sounds like a future-Bjorn problem."),
	]


func _on_dialogue_finished() -> void:
	super._on_dialogue_finished()
	if not _core_conversation_active:
		return
	GameState.set_story_flag("bjorn_crank_talked")
	GameState.set_objective("Ask Milk about Tito Bobet's stolen crank.")
	GameState.set_ambot_status("Milk can now be questioned near 6-Eleven")
	_core_conversation_active = false


func _player_line(text: String) -> Dictionary:
	return {"speaker": "You", "text": text, "portrait": PLAYER_PORTRAIT}
