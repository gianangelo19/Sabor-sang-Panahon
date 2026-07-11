extends Node2D

signal removed(reason: String)

enum MoveState {
	THROWING,
	FLOATING,
	REMOVING
}

enum CookState {
	RAW,
	SLIGHTLY_COOKED,
	PERFECT,
	BURNT
}

@export var raw_texture: Texture2D
@export var slightly_cooked_texture: Texture2D
@export var perfect_texture: Texture2D
@export var burnt_texture: Texture2D

@export var throw_duration := 0.55
@export var throw_arc_height := 190.0
@export var bob_strength := 5.0
@export var bob_speed := 7.0

@onready var sprite: Sprite2D = $Sprite2D

var move_state: MoveState = MoveState.THROWING
var cook_state: CookState = CookState.RAW

var throw_start_position: Vector2
var land_position: Vector2
var takeout_position: Vector2

var timer := 0.0
var float_duration := 4.0
var is_removing := false


func setup_for_batch(
	new_throw_start_position: Vector2,
	new_land_position: Vector2,
	new_takeout_position: Vector2,
	new_float_duration: float
) -> void:
	throw_start_position = new_throw_start_position
	land_position = new_land_position
	takeout_position = new_takeout_position
	float_duration = new_float_duration

	position = throw_start_position
	timer = 0.0
	is_removing = false
	move_state = MoveState.THROWING
	cook_state = CookState.RAW

	set_texture(raw_texture)


func _process(delta: float) -> void:
	if is_removing:
		return

	timer += delta

	if move_state == MoveState.THROWING:
		update_throwing()
	elif move_state == MoveState.FLOATING:
		update_floating()


func update_throwing() -> void:
	var progress: float = timer / throw_duration
	progress = clampf(progress, 0.0, 1.0)

	var flat_position: Vector2 = throw_start_position.lerp(land_position, progress)
	var arc: float = sin(progress * PI) * throw_arc_height

	position = flat_position
	position.y -= arc

	if progress >= 1.0:
		move_state = MoveState.FLOATING
		timer = 0.0
		position = land_position
		set_texture(raw_texture)


func update_floating() -> void:
	var progress: float = timer / float_duration
	progress = clampf(progress, 0.0, 1.0)

	var base_position: Vector2 = land_position.lerp(takeout_position, progress)

	position = base_position
	position.y += sin(timer * bob_speed) * bob_strength

	update_cooking_state(progress)

	if progress >= 1.0:
		burn_and_jump_out()


func update_cooking_state(progress: float) -> void:
	if progress < 0.35:
		cook_state = CookState.RAW
		set_texture(raw_texture)
	elif progress < 0.78:
		cook_state = CookState.SLIGHTLY_COOKED
		set_texture(slightly_cooked_texture)
	elif progress < 0.98:
		cook_state = CookState.PERFECT
		set_texture(perfect_texture)
	else:
		cook_state = CookState.BURNT
		set_texture(burnt_texture)


func is_active_for_input() -> bool:
	return move_state == MoveState.FLOATING and not is_removing


func try_take() -> void:
	if not is_active_for_input():
		return

	if cook_state == CookState.RAW:
		drop_wasted("wasted_raw")
	elif cook_state == CookState.SLIGHTLY_COOKED:
		drop_wasted("wasted_slightly")
	elif cook_state == CookState.PERFECT:
		collect_success()
	elif cook_state == CookState.BURNT:
		burn_and_jump_out()


func collect_success() -> void:
	if is_removing:
		return

	is_removing = true
	move_state = MoveState.REMOVING
	set_texture(perfect_texture)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(0, -55), 0.18)
	tween.tween_property(self, "scale", Vector2(0.35, 0.35), 0.18)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)

	await tween.finished

	removed.emit("collected")
	queue_free()


func drop_wasted(reason: String) -> void:
	if is_removing:
		return

	is_removing = true
	move_state = MoveState.REMOVING

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(0, 45), 0.22)
	tween.tween_property(self, "rotation_degrees", 45.0, 0.22)
	tween.tween_property(self, "modulate:a", 0.0, 0.22)

	await tween.finished

	removed.emit(reason)
	queue_free()


func burn_and_jump_out() -> void:
	if is_removing:
		return

	is_removing = true
	move_state = MoveState.REMOVING
	cook_state = CookState.BURNT
	set_texture(burnt_texture)

	var start_position: Vector2 = position

	# Jump away to the left first.
	var jump_peak: Vector2 = start_position + Vector2(-120, -170)

	# Then fall down off-screen.
	var screen_height: float = get_viewport_rect().size.y
	var fall_end: Vector2 = Vector2(start_position.x - 230, screen_height + 120)

	var tween: Tween = create_tween()

	# Jump up-left.
	tween.tween_property(self, "position", jump_peak, 0.25)

	# Fall down-left out of the screen.
	tween.tween_property(self, "position", fall_end, 0.55)

	# Rotate while jumping/falling.
	tween.parallel().tween_property(self, "rotation_degrees", -540.0, 0.80)

	await tween.finished

	removed.emit("burnt")
	queue_free()


func set_texture(texture: Texture2D) -> void:
	if texture != null:
		sprite.texture = texture
