extends StaticBody3D

const BOX_PLACEHOLDER_SCENE := preload("res://game/ui/minigames/vendor_minigame_placeholder.tscn")
const MINIGAME_SESSION_SCRIPT := preload("res://features/minigames/shared/scripts/minigame_session.gd")
const NEWSPAPER_CLUE := "Damaged newspaper"
const TUTORIAL_INTERACT_STEP := 3

var _session: CanvasLayer
var _player: Node
var _player_was_movable := true


func get_interaction_text() -> String:
	if GameState.clues.has(NEWSPAPER_CLUE):
		return "Press F to inspect the opened box"
	return "Press F to open the box"


func interaction_focus_entered() -> void:
	var hud := get_tree().root.find_child("GameHUD", true, false)
	if hud != null and hud.has_method("notify_box_seen"):
		hud.notify_box_seen()


func should_hide_interaction_prompt() -> bool:
	# The tutorial card already shows the F key and interaction action.
	return (
		GameState.tutorial_step == TUTORIAL_INTERACT_STEP
		and not GameState.clues.has(NEWSPAPER_CLUE)
	)


func interact() -> void:
	if GameState.clues.has(NEWSPAPER_CLUE):
		print("The opened box held the damaged newspaper that pointed toward La Paz.")
		return
	if _session != null and is_instance_valid(_session):
		return

	_notify_hud("notify_box_minigame_started")
	_lock_player()
	_session = MINIGAME_SESSION_SCRIPT.new()
	_session.name = "BoxMinigameSession"
	var session_parent: Node = get_tree().current_scene
	if session_parent == null:
		session_parent = get_tree().root
	session_parent.add_child(_session)
	_session.minigame_won.connect(_on_minigame_won)
	_session.dismissed.connect(_on_minigame_dismissed)
	_session.start(
		BOX_PLACEHOLDER_SCENE,
		{
			"title": "Open the Keepsake Box",
			"instructions": "Unpack the box and examine the damaged newspaper inside.",
			"reward": "Damaged newspaper clue",
		}
	)


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
	_notify_hud("notify_box_minigame_completed")
	_restore_player()


func _on_minigame_dismissed() -> void:
	_session = null
	_notify_hud("notify_box_minigame_dismissed")
	_restore_player()


func _notify_hud(method_name: StringName) -> void:
	var hud := get_tree().root.find_child("GameHUD", true, false)
	if hud != null and hud.has_method(method_name):
		hud.call(method_name)


func _restore_player() -> void:
	if _player != null and is_instance_valid(_player):
		_player.can_move = _player_was_movable
		_player.set_process_unhandled_input(true)
		_player.capture_mouse()
	_player = null
