extends Node3D

@export var show_distance := 5.0
@export var hide_distance := 5.75
@export var vertical_clearance := 0.35

@onready var bubble: Sprite3D = $Bubble
@onready var appearance_sound: AudioStreamPlayer3D = $AppearanceSound

var _host: Node3D
var _player: Node3D
var _is_shown := false
var _appearance_tween: Tween


func _ready() -> void:
	_host = get_parent() as Node3D
	bubble.visible = false
	_update_anchor()


func _process(_delta: float) -> void:
	if _host == null or not is_instance_valid(_host):
		return
	_update_anchor()
	if _player == null or not is_instance_valid(_player):
		_player = _find_player()
	var next_visible := _should_show()
	if next_visible != _is_shown:
		_set_shown(next_visible)


func _find_player() -> Node3D:
	var found := get_tree().get_first_node_in_group("player") as Node3D
	if found == null:
		found = get_tree().root.find_child("ProtoController", true, false) as Node3D
	return found


func _should_show() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	if not _host.is_visible_in_tree():
		return false
	if (
		_host.has_method("can_show_talk_indicator")
		and not bool(_host.call("can_show_talk_indicator"))
	):
		return false
	var player_ground := Vector2(_player.global_position.x, _player.global_position.z)
	var host_ground := Vector2(_host.global_position.x, _host.global_position.z)
	var threshold := hide_distance if _is_shown else show_distance
	return player_ground.distance_to(host_ground) <= threshold


func _update_anchor() -> void:
	if _host == null or not is_instance_valid(_host):
		return
	var anchor_position := _host.global_position + Vector3.UP * 2.4
	var sprite := _host.find_child("Sprite3D", true, false) as Sprite3D
	if sprite != null and sprite.texture != null:
		var sprite_half_height := (
			float(sprite.texture.get_height()) * sprite.pixel_size * 0.5
		)
		anchor_position = (
			sprite.global_position
			+ sprite.global_transform.basis.y * sprite_half_height
		)
	global_position = anchor_position + Vector3.UP * vertical_clearance


func _set_shown(next_visible: bool) -> void:
	_is_shown = next_visible
	if _appearance_tween != null and _appearance_tween.is_valid():
		_appearance_tween.kill()
	if not next_visible:
		bubble.visible = false
		return

	bubble.visible = true
	bubble.scale = Vector3.ONE * 0.72
	bubble.modulate = Color(1, 1, 1, 0)
	_appearance_tween = create_tween().set_parallel(true)
	_appearance_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_appearance_tween.tween_property(bubble, "scale", Vector3.ONE, 0.2)
	_appearance_tween.tween_property(bubble, "modulate:a", 1.0, 0.12)
	appearance_sound.pitch_scale = randf_range(0.98, 1.04)
	appearance_sound.play()
