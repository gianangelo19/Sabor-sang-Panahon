extends Node2D

const RING_TEXTURE: Texture2D = preload(
	"res://features/minigames/chicharon_beat/assets/gameplay/takeout_indicator_ring.png"
)

const ARROW_TEXTURE: Texture2D = preload(
	"res://features/minigames/chicharon_beat/assets/gameplay/takeout_indicator_arrow.png"
)

const PULSE_TEXTURE: Texture2D = preload(
	"res://features/minigames/chicharon_beat/assets/gameplay/beat_pulse_circle.png"
)

@export_category("Indicator Layout")

# Moves Ring, Arrow, and BeatPulse together.
# Positive X moves the complete takeout UI to the right.
@export var indicator_group_offset: Vector2 = Vector2(19.0, 0.0)

@export var ring_scale: Vector2 = Vector2(0.12, 0.12)
@export var arrow_scale: Vector2 = Vector2(0.09, 0.09)
@export var pulse_scale: Vector2 = Vector2(0.15, 0.15)

@export var arrow_offset: Vector2 = Vector2(0.0, -88.0)
@export var arrow_bob_distance: float = 7.0
@export var arrow_bob_speed: float = 4.5

@export_category("Timing Feedback")

@export var near_perfect_progress: float = 0.66
@export var perfect_start_progress: float = 0.78

@export var idle_ring_alpha: float = 0.40
@export var active_ring_alpha: float = 0.72
@export var perfect_ring_alpha: float = 1.0

@export var beat_pulse_strength: float = 0.22
@export var perfect_pulse_strength: float = 0.38

@export_category("Result Flash")

@export var result_flash_duration: float = 0.28

var ring_sprite: Sprite2D = null
var arrow_sprite: Sprite2D = null
var pulse_sprite: Sprite2D = null

var bpm: float = 120.0
var beat_timer: float = 0.0

var current_progress: float = 0.0
var current_cook_state: String = "none"
var has_target: bool = false

var result_flash_timer: float = 0.0
var result_flash_type: String = ""


func _ready() -> void:
	_build_indicator_sprites()
	_apply_idle_state()


func _process(delta: float) -> void:
	beat_timer += delta

	if result_flash_timer > 0.0:
		result_flash_timer -= delta
		_update_result_flash()
		_update_arrow(delta)
		return

	_update_arrow(delta)
	_update_timing_visuals()


func get_takeout_center_global_position() -> Vector2:
	# Exact visible center of the ring and beat pulse.
	return to_global(
		indicator_group_offset
	)


func set_bpm(
	new_bpm: float
) -> void:
	bpm = maxf(new_bpm, 1.0)


func set_target_timing(
	progress: float,
	cook_state_name: String
) -> void:
	current_progress = clampf(
		progress,
		0.0,
		1.0
	)

	current_cook_state = (
		cook_state_name
	)

	has_target = true


func clear_target_timing() -> void:
	has_target = false
	current_progress = 0.0
	current_cook_state = "none"


func flash_result(
	result_type: String
) -> void:
	result_flash_type = result_type
	result_flash_timer = (
		result_flash_duration
	)

	if pulse_sprite != null:
		pulse_sprite.visible = true


func _build_indicator_sprites() -> void:
	for child in get_children():
		if child is Sprite2D:
			child.queue_free()

	pulse_sprite = Sprite2D.new()
	pulse_sprite.name = "BeatPulse"
	pulse_sprite.texture = PULSE_TEXTURE
	pulse_sprite.position = indicator_group_offset
	pulse_sprite.scale = pulse_scale
	pulse_sprite.z_index = -1
	add_child(pulse_sprite)

	ring_sprite = Sprite2D.new()
	ring_sprite.name = "Ring"
	ring_sprite.texture = RING_TEXTURE
	ring_sprite.position = indicator_group_offset
	ring_sprite.scale = ring_scale
	ring_sprite.z_index = 0
	add_child(ring_sprite)

	arrow_sprite = Sprite2D.new()
	arrow_sprite.name = "Arrow"
	arrow_sprite.texture = ARROW_TEXTURE
	arrow_sprite.position = (
		indicator_group_offset
		+ arrow_offset
	)
	arrow_sprite.scale = arrow_scale
	arrow_sprite.z_index = 1
	add_child(arrow_sprite)


func _update_arrow(
	_delta: float
) -> void:
	if arrow_sprite == null:
		return

	var bob: float = sin(
		Time.get_ticks_msec()
		/ 1000.0
		* arrow_bob_speed
	) * arrow_bob_distance

	arrow_sprite.position = (
		indicator_group_offset
		+ arrow_offset
		+ Vector2(0.0, bob)
	)


func _update_timing_visuals() -> void:
	if (
		ring_sprite == null
		or pulse_sprite == null
	):
		return

	if not has_target:
		_apply_idle_state()
		return

	var seconds_per_beat: float = (
		60.0 / maxf(bpm, 1.0)
	)

	var beat_phase: float = fmod(
		beat_timer,
		seconds_per_beat
	) / seconds_per_beat

	var beat_hit: float = pow(
		1.0 - beat_phase,
		4.0
	)

	match current_cook_state:
		"perfect":
			ring_sprite.modulate = Color(
				1.15,
				1.08,
				0.70,
				perfect_ring_alpha
			)

			var perfect_scale_boost: float = (
				1.0
				+ beat_hit
				* perfect_pulse_strength
			)

			ring_sprite.scale = (
				ring_scale
				* perfect_scale_boost
			)

			pulse_sprite.visible = true
			pulse_sprite.modulate = Color(
				1.0,
				0.92,
				0.48,
				0.72
			)

			pulse_sprite.scale = (
				pulse_scale
				* (
					0.84
					+ beat_hit * 0.42
				)
			)

		"burnt":
			ring_sprite.modulate = Color(
				1.0,
				0.32,
				0.18,
				1.0
			)

			ring_sprite.scale = (
				ring_scale
				* (
					1.0
					+ beat_hit * 0.12
				)
			)

			pulse_sprite.visible = true
			pulse_sprite.modulate = Color(
				1.0,
				0.18,
				0.08,
				0.55
			)

			pulse_sprite.scale = (
				pulse_scale
				* (
					0.90
					+ beat_hit * 0.20
				)
			)

		_:
			var is_near_perfect: bool = (
				current_progress
				>= near_perfect_progress
			)

			ring_sprite.modulate = Color(
				1.0,
				0.88,
				0.28,
				active_ring_alpha
			)

			if is_near_perfect:
				var pulse_amount: float = (
					1.0
					+ beat_hit
					* beat_pulse_strength
				)

				ring_sprite.scale = (
					ring_scale
					* pulse_amount
				)

				pulse_sprite.visible = true
				pulse_sprite.modulate = Color(
					1.0,
					0.82,
					0.22,
					0.48
				)

				pulse_sprite.scale = (
					pulse_scale
					* (
						0.88
						+ beat_hit * 0.30
					)
				)

			else:
				ring_sprite.scale = (
					ring_scale
				)

				pulse_sprite.visible = false


func _update_result_flash() -> void:
	if (
		ring_sprite == null
		or pulse_sprite == null
	):
		return

	var flash_progress: float = (
		1.0
		- (
			result_flash_timer
			/ maxf(
				result_flash_duration,
				0.01
			)
		)
	)

	var pulse_amount: float = sin(
		flash_progress * PI
	)

	match result_flash_type:
		"perfect":
			ring_sprite.modulate = Color(
				1.25,
				1.16,
				0.62,
				1.0
			)

			pulse_sprite.modulate = Color(
				1.0,
				0.95,
				0.52,
				0.90
			)

		"burnt":
			ring_sprite.modulate = Color(
				1.0,
				0.20,
				0.08,
				1.0
			)

			pulse_sprite.modulate = Color(
				1.0,
				0.12,
				0.04,
				0.82
			)

		_:
			ring_sprite.modulate = Color(
				1.0,
				0.48,
				0.22,
				1.0
			)

			pulse_sprite.modulate = Color(
				1.0,
				0.36,
				0.12,
				0.72
			)

	ring_sprite.scale = (
		ring_scale
		* (
			1.0
			+ pulse_amount * 0.24
		)
	)

	pulse_sprite.visible = true
	pulse_sprite.scale = (
		pulse_scale
		* (
			0.80
			+ pulse_amount * 0.62
		)
	)


func _apply_idle_state() -> void:
	if ring_sprite != null:
		ring_sprite.modulate = Color(
			1.0,
			0.84,
			0.24,
			idle_ring_alpha
		)

		ring_sprite.scale = ring_scale

	if pulse_sprite != null:
		pulse_sprite.visible = false

	if arrow_sprite != null:
		arrow_sprite.modulate = Color(
			1.0,
			1.0,
			1.0,
			0.82
		)
