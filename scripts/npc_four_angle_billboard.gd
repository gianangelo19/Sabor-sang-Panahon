extends Sprite3D

enum ViewDirection { FRONT, RIGHT, BACK, LEFT }

@export_category("Doom-style directional textures")
@export var front_texture: Texture2D
@export var right_texture: Texture2D
@export var back_texture: Texture2D
@export var left_texture: Texture2D

var current_direction: ViewDirection = ViewDirection.FRONT


func _ready() -> void:
	# The card faces the camera, but its artwork has an independent direction.
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	fixed_size = false
	_update_direction(true)


func _process(_delta: float) -> void:
	_update_direction()


func _update_direction(force_update: bool = false) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	# Choose the frame from the viewer's position around the actor. The parent
	# CharacterBody3D owns Grandma's stable facing axes; billboarding the sprite
	# does not alter those axes.
	var to_player := camera.global_position - global_position
	to_player.y = 0.0
	if to_player.is_zero_approx():
		return
	to_player = to_player.normalized()

	var actor_basis := get_parent_node_3d().global_basis.orthonormalized()
	var actor_forward := -actor_basis.z # Godot forward is local -Z.
	var actor_right := actor_basis.x
	var forward_dot := actor_forward.dot(to_player)
	var right_dot := actor_right.dot(to_player)

	var new_direction: ViewDirection
	if absf(forward_dot) >= absf(right_dot):
		new_direction = ViewDirection.FRONT if forward_dot >= 0.0 else ViewDirection.BACK
	else:
		new_direction = ViewDirection.RIGHT if right_dot >= 0.0 else ViewDirection.LEFT

	if not force_update and new_direction == current_direction:
		return

	current_direction = new_direction
	match current_direction:
		ViewDirection.FRONT:
			texture = front_texture
		ViewDirection.RIGHT:
			texture = right_texture
		ViewDirection.BACK:
			texture = back_texture
		ViewDirection.LEFT:
			texture = left_texture
