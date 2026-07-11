extends Node2D

signal removed(reason: String)
signal landed

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

const OIL_SPLASH_SMALL_01: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_oil_splash_small_01.wav"
)

const OIL_SPLASH_SMALL_02: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_oil_splash_small_02.wav"
)

const CHICHARON_THROW_01: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_chicharon_throw_01.wav"
)

const CHICHARON_THROW_02: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_chicharon_throw_02.wav"
)

const CHICHARON_THROW_03: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_chicharon_throw_03.wav"
)

const CHICHARON_FLOAT: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_chicharon_float.wav"
)

const CHICHARON_BURN: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_chicharon_burn.wav"
)

const BURNT_JUMP: AudioStream = preload(
	"res://minigames-main/chicharon_beat/assets/audio/sfx/sfx_burnt_jump.wav"
)

const OIL_SPLASH_SMALL_TEXTURE: Texture2D = preload(
	"res://minigames-main/chicharon_beat/assets/effects/oil_splash_small.png"
)

const CHICHARON_SHADOW_TEXTURE: Texture2D = preload(
	"res://minigames-main/chicharon_beat/assets/effects/chicharon_shadow.png"
)

@export_category("Cooking Textures")

@export var raw_texture: Texture2D
@export var slightly_cooked_texture: Texture2D
@export var perfect_texture: Texture2D
@export var burnt_texture: Texture2D

@export_category("Movement")

@export var throw_duration: float = 0.55
@export var throw_arc_height: float = 190.0
@export var bob_strength: float = 5.0
@export var bob_speed: float = 7.0

# Keeps the chicharon moving after the takeout point without
# allowing it to visibly leave the pot.
@export var max_post_takeout_float_distance: float = 24.0

@export_category("Cooking Windows")

@export_range(0.0, 1.0, 0.01) var raw_end: float = 0.35

# The piece becomes visually perfect shortly before the ring center.
@export_range(0.0, 1.0, 0.01) var perfect_start: float = 0.86

# When the piece reaches the exact center of the takeout point, it
# stays PERFECT for this short grace period before burning.
@export var perfect_center_grace_duration: float = 0.38

@export_category("Visual Polish")

@export var small_splash_scale: Vector2 = Vector2(0.12, 0.12)
@export var small_splash_offset: Vector2 = Vector2(0.0, 10.0)

@export var shadow_scale: Vector2 = Vector2(0.12, 0.12)
@export var shadow_offset: Vector2 = Vector2(0.0, 18.0)
@export var shadow_near_alpha: float = 0.45
@export var shadow_far_alpha: float = 0.16
@export var shadow_air_scale_multiplier: float = 0.55

@export var landing_squash_x: float = 1.10
@export var landing_squash_y: float = 0.88
@export var landing_stretch_x: float = 0.95
@export var landing_stretch_y: float = 1.06

@export var cook_state_pop_scale: float = 1.08

@export_category("Audio")

@export var piece_sfx_volume_db: float = -6.0

@onready var sprite: Sprite2D = $Sprite2D

var move_state: MoveState = MoveState.THROWING
var cook_state: CookState = CookState.RAW

var throw_start_position: Vector2
var land_position: Vector2
var takeout_position: Vector2

var timer: float = 0.0
var float_duration: float = 4.0
var is_removing: bool = false

# Locks the exact timing result on the frame the player presses SPACE.
# The piece stops moving/cooking while the tongs strike.
var takeout_locked: bool = false

var shadow_sprite: Sprite2D = null
var cook_tween: Tween = null
var landing_tween: Tween = null


func _ready() -> void:
	_ensure_cooking_textures()

	# The piece is commonly instantiated while ChicharonContainer
	# is still adding children. Defer the sibling shadow creation
	# so Godot does not reject add_child() during scene setup.
	call_deferred("_create_shadow")


func _ensure_cooking_textures() -> void:
	# Replacing a script can clear exported Inspector assignments.
	# Keep the piece visible by using the Sprite2D's current texture
	# as a fallback raw texture.
	if raw_texture == null and sprite.texture != null:
		raw_texture = sprite.texture

	if slightly_cooked_texture == null:
		slightly_cooked_texture = raw_texture

	if perfect_texture == null:
		perfect_texture = slightly_cooked_texture

	if burnt_texture == null:
		burnt_texture = perfect_texture

	if raw_texture == null:
		push_error(
			"CHICHARON PIECE: No cooking texture is assigned "
			+ "and Sprite2D has no fallback texture."
		)


func setup_for_batch(
	new_throw_start_position: Vector2,
	new_land_position: Vector2,
	new_takeout_position: Vector2,
	new_float_duration: float,
	new_throw_duration: float = 0.55
) -> void:
	_ensure_cooking_textures()

	throw_start_position = new_throw_start_position
	land_position = new_land_position
	takeout_position = new_takeout_position
	float_duration = maxf(new_float_duration, 0.01)
	throw_duration = maxf(new_throw_duration, 0.01)

	global_position = throw_start_position
	timer = 0.0
	is_removing = false
	takeout_locked = false
	move_state = MoveState.THROWING
	cook_state = CookState.RAW

	rotation_degrees = 0.0
	scale = Vector2.ONE
	modulate = Color.WHITE

	sprite.scale = Vector2.ONE
	sprite.modulate = Color.WHITE

	_change_cook_state(
		CookState.RAW,
		true
	)

	_create_shadow()
	_update_shadow(
		0.0,
		throw_start_position
	)

	_play_random_throw_sound()


func _process(delta: float) -> void:
	if is_removing:
		return

	if takeout_locked:
		return

	timer += delta

	match move_state:
		MoveState.THROWING:
			update_throwing()

		MoveState.FLOATING:
			update_floating()

		MoveState.REMOVING:
			pass


func update_throwing() -> void:
	var progress: float = timer / throw_duration
	progress = clampf(progress, 0.0, 1.0)

	var flat_position: Vector2 = (
		throw_start_position.lerp(
			land_position,
			progress
		)
	)

	var arc_amount: float = sin(
		progress * PI
	)

	var arc: float = (
		arc_amount * throw_arc_height
	)

	global_position = flat_position
	global_position.y -= arc

	rotation_degrees = lerpf(
		-8.0,
		8.0,
		progress
	)

	_update_shadow(
		arc_amount,
		flat_position
	)

	if progress >= 1.0:
		_on_landed()


func _on_landed() -> void:
	move_state = MoveState.FLOATING
	timer = 0.0
	global_position = land_position
	rotation_degrees = 0.0

	_hide_shadow()

	_change_cook_state(
		CookState.RAW,
		true
	)

	_spawn_small_oil_splash()
	_play_random_small_splash()
	_play_one_shot(
		CHICHARON_FLOAT,
		piece_sfx_volume_db - 5.0,
		1.0
	)

	_play_landing_squash()

	landed.emit()


func update_floating() -> void:
	var progress: float = get_float_progress()

	var travel_vector: Vector2 = (
		takeout_position
		- land_position
	)

	var travel_distance: float = (
		travel_vector.length()
	)

	var travel_direction: Vector2 = Vector2.LEFT

	if travel_distance > 0.001:
		travel_direction = (
			travel_vector
			/ travel_distance
		)

	var travel_speed: float = (
		travel_distance
		/ maxf(
			float_duration,
			0.01
		)
	)

	var base_position: Vector2

	if timer <= float_duration:
		base_position = (
			land_position.lerp(
				takeout_position,
				progress
			)
		)

	else:
		var overflow_time: float = (
			timer - float_duration
		)

		var overflow_distance: float = (
			travel_speed
			* overflow_time
		)

		var safe_overflow_distance: float = minf(
			overflow_distance,
			max_post_takeout_float_distance
		)

		base_position = (
			takeout_position
			+ travel_direction
			* safe_overflow_distance
		)

	global_position = base_position
	global_position.y += (
		sin(timer * bob_speed)
		* bob_strength
	)

	if timer < float_duration:
		update_cooking_state(progress)
		return

	_change_cook_state(
		CookState.PERFECT
	)

	var moving_grace_time: float = (
		timer - float_duration
	)

	var max_safe_overflow_time: float = (
		max_post_takeout_float_distance
		/ maxf(
			travel_speed,
			0.01
		)
	)

	var burn_after_time: float = minf(
		perfect_center_grace_duration,
		max_safe_overflow_time
	)

	if moving_grace_time >= burn_after_time:
		burn_and_jump_out()

func update_cooking_state(
	progress: float
) -> void:
	if progress < raw_end:
		_change_cook_state(
			CookState.RAW
		)

	elif progress < perfect_start:
		_change_cook_state(
			CookState.SLIGHTLY_COOKED
		)

	else:
		_change_cook_state(
			CookState.PERFECT
		)

func _change_cook_state(
	new_state: CookState,
	force_update: bool = false
) -> void:
	if (
		not force_update
		and cook_state == new_state
	):
		return

	cook_state = new_state

	match cook_state:
		CookState.RAW:
			set_texture(raw_texture)

		CookState.SLIGHTLY_COOKED:
			set_texture(
				slightly_cooked_texture
			)

		CookState.PERFECT:
			set_texture(perfect_texture)

		CookState.BURNT:
			set_texture(burnt_texture)

	if not force_update:
		_play_cook_state_pop()


func _play_cook_state_pop() -> void:
	if (
		cook_tween != null
		and cook_tween.is_valid()
	):
		cook_tween.kill()

	sprite.scale = Vector2.ONE

	cook_tween = create_tween()

	cook_tween.tween_property(
		sprite,
		"scale",
		Vector2.ONE * cook_state_pop_scale,
		0.07
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	cook_tween.tween_property(
		sprite,
		"scale",
		Vector2.ONE,
		0.07
	)

	if cook_state == CookState.PERFECT:
		sprite.modulate = Color(
			1.22,
			1.12,
			0.78,
			1.0
		)

		cook_tween.parallel().tween_property(
			sprite,
			"modulate",
			Color.WHITE,
			0.16
		)


func _play_landing_squash() -> void:
	if (
		landing_tween != null
		and landing_tween.is_valid()
	):
		landing_tween.kill()

	sprite.scale = Vector2.ONE

	landing_tween = create_tween()

	landing_tween.tween_property(
		sprite,
		"scale",
		Vector2(
			landing_squash_x,
			landing_squash_y
		),
		0.06
	)

	landing_tween.tween_property(
		sprite,
		"scale",
		Vector2(
			landing_stretch_x,
			landing_stretch_y
		),
		0.05
	)

	landing_tween.tween_property(
		sprite,
		"scale",
		Vector2.ONE,
		0.05
	)


func is_active_for_input() -> bool:
	return (
		move_state == MoveState.FLOATING
		and not is_removing
		and not takeout_locked
	)


func lock_for_takeout() -> bool:
	if not is_active_for_input():
		return false

	takeout_locked = true
	return true


func resolve_take_result(
	result: String
) -> void:
	if is_removing:
		return

	# The controller captured this result on the exact input frame.
	# Unlock only for the forced resolution below.
	takeout_locked = false

	match result:
		"perfect":
			collect_success()

		"slightly_cooked":
			drop_wasted(
				"wasted_slightly"
			)

		"burnt":
			burn_and_jump_out()

		_:
			drop_wasted(
				"wasted_raw"
			)

func get_float_progress() -> float:
	if move_state != MoveState.FLOATING:
		return 0.0

	return clampf(
		timer / maxf(float_duration, 0.01),
		0.0,
		1.0
	)


func get_cook_state_name() -> String:
	match cook_state:
		CookState.RAW:
			return "raw"

		CookState.SLIGHTLY_COOKED:
			return "slightly_cooked"

		CookState.PERFECT:
			return "perfect"

		CookState.BURNT:
			return "burnt"

	return "raw"


func try_take() -> void:
	if not is_active_for_input():
		return

	var distance_to_takeout: float = (
		global_position.distance_to(
			takeout_position
		)
	)

	# Compatibility behavior for direct calls:
	# close to the takeout center is always perfect.
	if distance_to_takeout <= 58.0:
		collect_success()
		return

	match cook_state:
		CookState.RAW:
			drop_wasted(
				"wasted_raw"
			)

		CookState.SLIGHTLY_COOKED:
			drop_wasted(
				"wasted_slightly"
			)

		CookState.PERFECT:
			collect_success()

		CookState.BURNT:
			burn_and_jump_out()

func collect_success() -> void:
	if is_removing:
		return

	is_removing = true
	move_state = MoveState.REMOVING

	_hide_shadow()

	set_texture(perfect_texture)

	var tween: Tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		self,
		"global_position",
		global_position + Vector2(0.0, -55.0),
		0.18
	)

	tween.tween_property(
		self,
		"scale",
		Vector2(0.35, 0.35),
		0.18
	)

	tween.tween_property(
		self,
		"modulate:a",
		0.0,
		0.18
	)

	await tween.finished

	removed.emit("collected")
	queue_free()


func drop_wasted(
	reason: String
) -> void:
	if is_removing:
		return

	is_removing = true
	move_state = MoveState.REMOVING

	_hide_shadow()

	var tween: Tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		self,
		"global_position",
		global_position + Vector2(0.0, 45.0),
		0.22
	)

	tween.tween_property(
		self,
		"rotation_degrees",
		45.0,
		0.22
	)

	tween.tween_property(
		self,
		"modulate:a",
		0.0,
		0.22
	)

	await tween.finished

	removed.emit(reason)
	queue_free()


func burn_and_jump_out() -> void:
	if is_removing:
		return

	is_removing = true
	move_state = MoveState.REMOVING

	_hide_shadow()

	_change_cook_state(
		CookState.BURNT,
		true
	)

	_play_one_shot(
		CHICHARON_BURN,
		piece_sfx_volume_db,
		1.0
	)

	_play_one_shot(
		BURNT_JUMP,
		piece_sfx_volume_db,
		1.0
	)

	var start_position: Vector2 = (
		global_position
	)

	var jump_peak: Vector2 = (
		start_position
		+ Vector2(18.0, -72.0)
	)

	var fall_end: Vector2 = (
		start_position
		+ Vector2(34.0, 92.0)
	)

	var tween: Tween = create_tween()

	tween.tween_property(
		self,
		"global_position",
		jump_peak,
		0.18
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		self,
		"global_position",
		fall_end,
		0.32
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	tween.parallel().tween_property(
		self,
		"rotation_degrees",
		-360.0,
		0.50
	)

	tween.parallel().tween_property(
		self,
		"modulate:a",
		0.0,
		0.22
	).set_delay(
		0.28
	)

	await tween.finished

	removed.emit("burnt")
	queue_free()

func set_texture(
	texture: Texture2D
) -> void:
	if texture != null:
		sprite.texture = texture


# =========================================================
# THROW SHADOW
# =========================================================

func _create_shadow() -> void:
	if shadow_sprite != null:
		return

	if not is_inside_tree():
		return

	var parent_node: Node = get_parent()

	if parent_node == null:
		return

	shadow_sprite = Sprite2D.new()
	shadow_sprite.name = (
		"RuntimeChicharonShadow"
	)
	shadow_sprite.texture = (
		CHICHARON_SHADOW_TEXTURE
	)
	shadow_sprite.scale = shadow_scale
	shadow_sprite.z_index = z_index - 2
	shadow_sprite.modulate = Color(
		1.0,
		1.0,
		1.0,
		shadow_near_alpha
	)
	shadow_sprite.visible = false

	# The shadow is a sibling so it can stay on the oil plane
	# while the chicharon follows its throw arc.
	parent_node.call_deferred(
		"add_child",
		shadow_sprite
	)


func _update_shadow(
	air_height_amount: float,
	flat_position: Vector2
) -> void:
	_create_shadow()

	if shadow_sprite == null:
		return

	# A deferred sibling shadow may not be inside the tree until
	# the next idle step. Simply wait for the following frame.
	if not shadow_sprite.is_inside_tree():
		return

	shadow_sprite.visible = true
	shadow_sprite.global_position = (
		flat_position
		+ shadow_offset
	)

	var scale_multiplier: float = lerpf(
		1.0,
		shadow_air_scale_multiplier,
		air_height_amount
	)

	shadow_sprite.scale = (
		shadow_scale
		* scale_multiplier
	)

	shadow_sprite.modulate.a = lerpf(
		shadow_near_alpha,
		shadow_far_alpha,
		air_height_amount
	)


func _hide_shadow() -> void:
	if shadow_sprite != null:
		shadow_sprite.visible = false


# =========================================================
# OIL SPLASH
# =========================================================

func _spawn_small_oil_splash() -> void:
	var parent_node: Node = get_parent()

	if parent_node == null:
		return

	var splash: Sprite2D = Sprite2D.new()

	splash.texture = OIL_SPLASH_SMALL_TEXTURE
	splash.global_position = (
		land_position
		+ small_splash_offset
	)
	splash.scale = (
		small_splash_scale * 0.50
	)
	splash.modulate = Color.WHITE
	splash.z_index = z_index - 1

	parent_node.add_child(splash)

	var tween: Tween = create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		splash,
		"scale",
		small_splash_scale * 1.10,
		0.20
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		splash,
		"modulate:a",
		0.0,
		0.28
	).set_delay(
		0.06
	)

	await tween.finished

	if is_instance_valid(splash):
		splash.queue_free()


# =========================================================
# PIECE AUDIO
# =========================================================

func _play_random_throw_sound() -> void:
	var streams: Array[AudioStream] = [
		CHICHARON_THROW_01,
		CHICHARON_THROW_02,
		CHICHARON_THROW_03
	]

	var selected_stream: AudioStream = (
		streams.pick_random()
		as AudioStream
	)

	_play_one_shot(
		selected_stream,
		piece_sfx_volume_db,
		randf_range(0.96, 1.04)
	)


func _play_random_small_splash() -> void:
	var streams: Array[AudioStream] = [
		OIL_SPLASH_SMALL_01,
		OIL_SPLASH_SMALL_02
	]

	var selected_stream: AudioStream = (
		streams.pick_random()
		as AudioStream
	)

	_play_one_shot(
		selected_stream,
		piece_sfx_volume_db,
		randf_range(0.97, 1.03)
	)


func _play_one_shot(
	stream: AudioStream,
	volume_db: float,
	pitch_scale: float = 1.0
) -> void:
	if stream == null:
		return

	var player: AudioStreamPlayer = (
		AudioStreamPlayer.new()
	)

	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale

	add_child(player)

	player.finished.connect(
		Callable(
			player,
			"queue_free"
		)
	)

	player.play()


func _exit_tree() -> void:
	if is_instance_valid(shadow_sprite):
		shadow_sprite.queue_free()

	shadow_sprite = null
