extends Node3D

const WOOD_DOOR_OPEN_SOUND := preload("res://assets/audio/retro_filipino_pack/wood_door_open_realistic.wav")
const WOOD_DOOR_CLOSE_SOUND := preload("res://assets/audio/retro_filipino_pack/wood_door_close_realistic.wav")
const DIALOGUE_SCENE := preload("res://game/ui/dialogue/dialogue_ui.tscn")
const PLAYER_PORTRAIT := preload("res://assets/art/characters/2main_character_asking.png")

@export var interaction_label_open: String = "open door"
@export var interaction_label_close: String = "close door"
@export var open_angle_degrees: float = 95.0
@export var animation_time: float = 0.35
@export_group("Story Lock")
@export var required_clue: String = ""
@export var locked_interaction_label: String = "find the required clue first"
@export_multiline var locked_message: String = "I should look around before leaving."

var _closed_rotation_y: float
var _is_open := false
var _tween: Tween
var _audio: AudioStreamPlayer3D
var _locked_dialogue_active := false
var _player: Node
var _player_was_movable := true


func _ready() -> void:
	_closed_rotation_y = rotation_degrees.y
	_audio = AudioStreamPlayer3D.new()
	_audio.stream = WOOD_DOOR_OPEN_SOUND
	_audio.bus = "SFX"
	_audio.unit_size = 2.0
	_audio.max_distance = 14.0
	add_child(_audio)


func get_interaction_text() -> String:
	if _is_story_locked():
		return "Press F to " + locked_interaction_label
	var label := interaction_label_close if _is_open else interaction_label_open
	return "Press F to " + label


func interact() -> void:
	if _is_story_locked():
		print(locked_message)
		_start_locked_dialogue()
		return
	_is_open = not _is_open
	if _audio:
		_audio.stop()
		_audio.stream = WOOD_DOOR_OPEN_SOUND if _is_open else WOOD_DOOR_CLOSE_SOUND
		_audio.play()
	var target_y := _closed_rotation_y
	if _is_open:
		target_y += open_angle_degrees

	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "rotation_degrees:y", target_y, animation_time)


func _is_story_locked() -> bool:
	return not required_clue.is_empty() and not GameState.clues.has(required_clue)


func _start_locked_dialogue() -> void:
	if _locked_dialogue_active:
		return
	_locked_dialogue_active = true
	_lock_player()
	var dialogue := DIALOGUE_SCENE.instantiate()
	get_tree().root.add_child(dialogue)
	dialogue.start_conversation([
		{
			"speaker": "You",
			"text": locked_message,
			"portrait": PLAYER_PORTRAIT,
		},
	])
	dialogue.dialogue_finished.connect(_on_locked_dialogue_finished)


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


func _on_locked_dialogue_finished() -> void:
	if _player != null and is_instance_valid(_player):
		_player.can_move = _player_was_movable
		_player.set_process_unhandled_input(true)
		_player.capture_mouse()
	_player = null
	_locked_dialogue_active = false
