extends Node3D

const DIALOGUE_SCENE := preload("res://game/ui/dialogue/dialogue_ui.tscn")
const TALK_INDICATOR_SCENE := preload(
	"res://game/characters/npcs/shared/npc_talk_indicator.tscn"
)
const PLAYER_PORTRAIT := preload("res://assets/art/characters/2main_character_asking.png")
const MINIGAME_SESSION_SCRIPT := preload("res://features/minigames/shared/scripts/minigame_session.gd")
const TIME_OF_DAY_STAGE_BY_DESTINATION := {
	"market_vendor_1": 1,
	"market_vendor_2": 2,
	"herbs_vendor": 3,
	"seasoning_vendor": 4,
	"egg_vendor": 5,
	"chicharon_vendor": 6,
	"tindero": 7,
}

var npc_display_name := "NPC"
var npc_portrait: Texture2D
var first_conversation: Array[Dictionary] = []
var repeat_conversation: Array[Dictionary] = []
var minigame_title := "Vendor Challenge"
var minigame_instructions := "Complete the vendor's challenge."
var reward_id := "ingredient"
var reward_name := "Ingredient"
var destination_id := ""
var minigame_scene: PackedScene
var dialogue_only_reward := false
var required_item_id := ""
var required_item_name := ""
var consume_required_item := false
var reward_conversation: Array[Dictionary] = []

var _dialogue_active := false
var _conversation_completed := false
var _minigame_completed := false
var _player: Node = null
var _player_was_movable := true
var _minigame_session: CanvasLayer = null


func _enter_tree() -> void:
	_install_talk_indicator.call_deferred()


func _install_talk_indicator() -> void:
	if not is_inside_tree() or get_node_or_null("TalkIndicator") != null:
		return
	add_child(TALK_INDICATOR_SCENE.instantiate())


func can_show_talk_indicator() -> bool:
	return not _dialogue_active and _is_story_available()


func get_interaction_text() -> String:
	if not _is_story_available():
		return _locked_interaction_text()
	if _conversation_completed and not _minigame_completed:
		if not _has_required_item() and not required_item_name.is_empty():
			return "Press F to ask about the missing " + required_item_name
		return "Press F to continue " + npc_display_name + "'s story"
	return "Press F to talk to " + npc_display_name


func interact() -> void:
	if _dialogue_active or not _is_story_available():
		return
	_dialogue_active = true
	_lock_player()
	if (
		_conversation_completed
		and not _minigame_completed
		and required_item_id.is_empty()
	):
		_start_challenge()
		return
	if not _conversation_completed:
		_handle_first_conversation_started()

	var dialogue := DIALOGUE_SCENE.instantiate()
	get_tree().root.add_child(dialogue)
	dialogue.start_conversation(
		_get_conversation_entries(_conversation_completed),
		self,
	)
	dialogue.dialogue_finished.connect(_on_dialogue_finished)


func player_line(text: String) -> Dictionary:
	return {"speaker": "You", "text": text, "portrait": PLAYER_PORTRAIT}


func npc_line(text: String) -> Dictionary:
	return {"speaker": npc_display_name, "text": text, "portrait": npc_portrait}

func choice_line(prompt: String, choices: Array) -> Dictionary:
	return {
		"speaker": "You",
		"text": prompt,
		"portrait": PLAYER_PORTRAIT,
		"choices": choices,
	}

func _get_conversation_entries(is_repeat: bool) -> Array[Dictionary]:
	return repeat_conversation if is_repeat else first_conversation


func sync_completion_from_game_state() -> void:
	if not destination_id.is_empty() and GameState.is_destination_completed(destination_id):
		_conversation_completed = true
		_minigame_completed = true


func _is_story_available() -> bool:
	if destination_id.is_empty():
		return true
	return GameState.is_destination_unlocked(destination_id) or GameState.is_destination_completed(destination_id)


func _locked_interaction_text() -> String:
	if not GameState.is_destination_completed("grandma_house"):
		return "Talk to Grandma first"
	return "Follow the current lead first"


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


func _on_dialogue_finished() -> void:
	if not _conversation_completed:
		_conversation_completed = true
	if not _has_required_item():
		_handle_required_item_missing()
		_restore_player()
		return
	if not _minigame_completed:
		_start_challenge()
		return
	_restore_player()


func _start_challenge() -> void:
	if dialogue_only_reward:
		_complete_dialogue_only_reward()
		return
	_start_minigame()


func _complete_dialogue_only_reward() -> void:
	# Let the completed conversation leave the tree before creating the reward
	# conversation, so both dialogue instances never compete for ownership.
	await get_tree().process_frame
	GameState.advance_time_of_day(
		int(TIME_OF_DAY_STAGE_BY_DESTINATION.get(destination_id, 0))
	)
	_on_minigame_won()


func _start_minigame() -> void:
	if minigame_scene == null:
		push_error(npc_display_name + " has no minigame scene configured.")
		_restore_player()
		return
	_minigame_session = MINIGAME_SESSION_SCRIPT.new()
	_minigame_session.name = "VendorMinigameSession"
	var session_parent: Node = get_tree().current_scene
	if session_parent == null:
		session_parent = get_tree().root
	session_parent.add_child(_minigame_session)
	_minigame_session.minigame_won.connect(_on_minigame_won)
	_minigame_session.dismissed.connect(_on_minigame_dismissed)
	_minigame_session.start(
		minigame_scene,
		{
			"title": minigame_title,
			"instructions": minigame_instructions,
			"reward": reward_name,
			"time_of_day_stage": int(
				TIME_OF_DAY_STAGE_BY_DESTINATION.get(destination_id, 0)
			),
		}
	)


func _on_minigame_won() -> void:
	_minigame_session = null
	_minigame_completed = true
	if consume_required_item and not required_item_id.is_empty():
		GameState.remove_inventory_item(required_item_id)
	GameState.collect_ingredient(reward_id, reward_name)
	_handle_minigame_won()
	if reward_conversation.is_empty():
		_restore_player()
		return
	var dialogue := DIALOGUE_SCENE.instantiate()
	get_tree().root.add_child(dialogue)
	dialogue.start_conversation(reward_conversation, self)
	dialogue.dialogue_finished.connect(_restore_player)


func _on_minigame_dismissed() -> void:
	_minigame_session = null
	_restore_player()


func _restore_player() -> void:
	if _player != null and is_instance_valid(_player):
		_player.can_move = _player_was_movable
		_player.set_process_unhandled_input(true)
		_player.capture_mouse()
	_dialogue_active = false


func _handle_minigame_won() -> void:
	pass


func _handle_first_conversation_started() -> void:
	pass

func _has_required_item() -> bool:
	return required_item_id.is_empty() or GameState.has_inventory_item(required_item_id)

func _handle_required_item_missing() -> void:
	pass
