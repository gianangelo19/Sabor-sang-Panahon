extends Area2D

signal released(release_position: Vector2)

@onready var sprite: Sprite2D = $Sprite2D

var collision_shape: CollisionShape2D = null

@export var return_duration: float = 0.20

var drag_enabled: bool = false
var dragging: bool = false

var drag_offset: Vector2 = Vector2.ZERO
var home_position: Vector2 = Vector2.ZERO

var return_tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	input_pickable = false

	_create_or_find_collision_shape()


func _create_or_find_collision_shape() -> void:
	var existing_collision: Node = get_node_or_null(
		"CollisionShape2D"
	)

	if existing_collision is CollisionShape2D:
		collision_shape = (
			existing_collision as CollisionShape2D
		)
	else:
		if existing_collision != null:
			existing_collision.queue_free()

		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"

		add_child(collision_shape)

	var default_rectangle := RectangleShape2D.new()
	default_rectangle.size = Vector2(260, 180)

	collision_shape.position = Vector2.ZERO
	collision_shape.shape = default_rectangle
	collision_shape.disabled = false


func configure_collectible(
	new_texture: Texture2D,
	display_scale: Vector2 = Vector2(0.6, 0.6),
	new_collision_size: Vector2 = Vector2(260, 180)
) -> void:
	if new_texture == null:
		push_error(
			"Cannot configure collectible with a null texture."
		)
		return

	if collision_shape == null:
		_create_or_find_collision_shape()

	sprite.texture = new_texture
	sprite.scale = display_scale
	sprite.position = Vector2.ZERO
	sprite.centered = true

	var rectangle_shape := RectangleShape2D.new()
	rectangle_shape.size = new_collision_size

	collision_shape.position = Vector2.ZERO
	collision_shape.shape = rectangle_shape
	collision_shape.disabled = false


func set_home_position(
	new_home_position: Vector2
) -> void:
	home_position = new_home_position
	global_position = home_position


func set_drag_enabled(enabled: bool) -> void:
	drag_enabled = enabled
	input_pickable = enabled

	if collision_shape != null:
		collision_shape.set_deferred(
			"disabled",
			not enabled
		)

	if not drag_enabled:
		dragging = false


func _input_event(
	_viewport: Node,
	event: InputEvent,
	_shape_index: int
) -> void:
	if not drag_enabled:
		return

	if event is InputEventMouseButton:
		if (
			event.button_index == MOUSE_BUTTON_LEFT
			and event.pressed
		):
			if return_tween != null:
				return_tween.kill()
				return_tween = null

			dragging = true

			drag_offset = (
				global_position
				- get_global_mouse_position()
			)

			get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if not dragging:
		return

	if event is InputEventMouseMotion:
		global_position = (
			get_global_mouse_position()
			+ drag_offset
		)

	if event is InputEventMouseButton:
		if (
			event.button_index == MOUSE_BUTTON_LEFT
			and not event.pressed
		):
			dragging = false

			# Use the collectible center instead of the mouse.
			var collectible_center: Vector2 = global_position

			print(
				"DEBUG DRAGGABLE: Collectible center released at: ",
				collectible_center
			)

			released.emit(collectible_center)

			get_viewport().set_input_as_handled()


func return_to_home() -> void:
	if return_tween != null:
		return_tween.kill()
		return_tween = null

	dragging = false
	drag_enabled = false
	input_pickable = false

	if collision_shape != null:
		collision_shape.set_deferred(
			"disabled",
			true
		)

	return_tween = create_tween()

	return_tween.tween_property(
		self,
		"global_position",
		home_position,
		return_duration
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	await return_tween.finished
	return_tween = null

	drag_enabled = true
	input_pickable = true

	if collision_shape != null:
		collision_shape.set_deferred(
			"disabled",
			false
		)
