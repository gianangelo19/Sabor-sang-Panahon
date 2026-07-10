extends Node3D

const WOOD_DOOR_SOUND := preload("res://audio/wood_door_sound.mp3")

@export var interaction_label_open: String = "open door"
@export var interaction_label_close: String = "close door"
@export var open_angle_degrees: float = 95.0
@export var animation_time: float = 0.35

var _closed_rotation_y: float
var _is_open := false
var _tween: Tween
var _audio: AudioStreamPlayer3D


func _ready() -> void:
	_closed_rotation_y = rotation_degrees.y
	_audio = AudioStreamPlayer3D.new()
	_audio.stream = WOOD_DOOR_SOUND
	_audio.bus = "SFX"
	_audio.unit_size = 2.0
	_audio.max_distance = 14.0
	add_child(_audio)


func get_interaction_text() -> String:
	var label := interaction_label_close if _is_open else interaction_label_open
	return "Press E to " + label


func interact() -> void:
	_is_open = not _is_open
	if _audio:
		_audio.stop()
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
