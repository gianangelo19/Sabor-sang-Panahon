extends Node3D

signal artifact_recovered(artifact: Node3D)

@export var active := true
@export var close_clue_distance := 32.0
@export var broad_clue_distance := 90.0

@onready var collision_shape: CollisionShape3D = $StaticBody3D/CollisionShape3D
@onready var broth_clue: AudioStreamPlayer3D = $BrothCulturalClue
@onready var artifact_clue: AudioStreamPlayer3D = $ArtifactCulturalClue

var _recovered := false
var _player: Node3D


func _ready() -> void:
	add_to_group("batchoy_bowl_artifact")
	_loop_audio(broth_clue)
	_loop_audio(artifact_clue)
	set_active(active)


func _process(_delta: float) -> void:
	if not active or _recovered:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
		if _player == null:
			_player = get_tree().root.find_child("ProtoController", true, false) as Node3D
	if _player == null:
		return

	var distance := global_position.distance_to(_player.global_position)
	var broad_mix := clampf(distance / broad_clue_distance, 0.0, 1.0)
	var close_mix := clampf(distance / close_clue_distance, 0.0, 1.0)
	# The remembered eatery carries from afar; hot broth and steam emerge up close.
	artifact_clue.volume_db = lerpf(-14.0, -1.0, broad_mix)
	broth_clue.volume_db = lerpf(0.0, -28.0, close_mix)


func get_interaction_text() -> String:
	if not active or _recovered:
		return ""
	return "Press F to recover the Batchoy Bowl"


func interact() -> void:
	if not active or _recovered:
		return
	_recovered = true
	set_active(false)
	artifact_recovered.emit(self)


func set_active(should_be_active: bool) -> void:
	active = should_be_active
	visible = should_be_active and not _recovered
	if collision_shape:
		collision_shape.set_deferred("disabled", not should_be_active or _recovered)
	if should_be_active and not _recovered:
		_play_if_stopped(broth_clue)
		_play_if_stopped(artifact_clue)
	else:
		broth_clue.stop()
		artifact_clue.stop()


func reset_recovery() -> void:
	_recovered = false
	set_active(true)


func _loop_audio(player: AudioStreamPlayer3D) -> void:
	if player == null:
		return
	if not player.finished.is_connected(_replay_audio.bind(player)):
		player.finished.connect(_replay_audio.bind(player))
	_play_if_stopped(player)


func _play_if_stopped(player: AudioStreamPlayer3D) -> void:
	if active and not _recovered and player and not player.playing:
		player.play()


func _replay_audio(player: AudioStreamPlayer3D) -> void:
	_play_if_stopped(player)
