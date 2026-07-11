extends Node3D

const WOOD_DOOR_OPEN_SOUND := preload("res://audio/retro_filipino_pack/wood_door_open_realistic.wav")
const WOOD_DOOR_CLOSE_SOUND := preload("res://audio/retro_filipino_pack/wood_door_close_realistic.wav")

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
		return "Press E to " + locked_interaction_label
	var label := interaction_label_close if _is_open else interaction_label_open
	return "Press E to " + label


func interact() -> void:
	if _is_story_locked():
		print(locked_message)
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
