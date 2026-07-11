extends StaticBody3D

const BOX_MINIGAME_SCENE := preload(
	"res://minigames-main/box_unboxing/scenes/box_unboxing.tscn"
)
const MINIGAME_SESSION_SCRIPT := preload("res://scripts/minigame_session.gd")
const NEWSPAPER_CLUE := "Damaged newspaper"

var _session: CanvasLayer
var _player: Node
var _player_was_movable := true


func get_interaction_text() -> String:
	if GameState.clues.has(NEWSPAPER_CLUE):
		return "Press E to inspect the opened box"
	return "Press E to open the box"


func interact() -> void:
	if GameState.clues.has(NEWSPAPER_CLUE):
		print("The opened box held the damaged newspaper that pointed toward La Paz.")
		return
	if _session != null and is_instance_valid(_session):
		return

	_lock_player()
	_session = MINIGAME_SESSION_SCRIPT.new()
	_session.name = "BoxMinigameSession"
	get_tree().root.add_child(_session)
	_session.minigame_won.connect(_on_minigame_won)
	_session.dismissed.connect(_on_minigame_dismissed)
	_session.start(BOX_MINIGAME_SCENE)


func _lock_player() -> void:
	_player = get_tree().root.find_child("ProtoController", true, false)
	if _player == null:
		return
	_player_was_movable = _player.can_move
	_player.can_move = false
	_player.set_process_unhandled_input(false)
	_player.release_mouse()
	var prompt := _player.get_node_or_null("InteractionUI/Prompt")
	if prompt:
		prompt.visible = false


func _on_minigame_won() -> void:
	_session = null
	GameState.add_clue(NEWSPAPER_CLUE)
	GameState.set_objective("Ride the jeepney to La Paz.")
	GameState.set_ambot_status("Document scan incomplete. Dish identity unknown.")
	GameState.push_ambot_notification(
		"newspaper_scan",
		"Damaged article detected",
		"I can scan the surviving text."
	)
	_restore_player()


func _on_minigame_dismissed() -> void:
	_session = null
	_restore_player()


func _restore_player() -> void:
	if _player != null and is_instance_valid(_player):
		_player.can_move = _player_was_movable
		_player.set_process_unhandled_input(true)
		_player.capture_mouse()
	_player = null
