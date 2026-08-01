extends Node2D

## Round-wide timing display. The green layer fills from left to right while
## one reusable needle texture is duplicated for every chicharon in the batch.

const PANEL_TEXTURE: Texture2D = preload(
	"res://features/minigames/chicharon_beat/assets/gameplay/take_out_indicator_panel.png"
)
const GREEN_TEXTURE: Texture2D = preload(
	"res://features/minigames/chicharon_beat/assets/gameplay/take_out_indicator_green.png"
)
const FRAME_TEXTURE: Texture2D = preload(
	"res://features/minigames/chicharon_beat/assets/gameplay/take_out_indicator_frame.png"
)
const NEEDLE_TEXTURE: Texture2D = preload(
	"res://features/minigames/chicharon_beat/assets/gameplay/take_out_indicator_needle.png"
)

const CANVAS_SIZE := Vector2(414.0, 177.0)
const TRACK_LEFT := 18.0
const TRACK_RIGHT := 396.0

@export_range(0.01, 0.20, 0.005) var perfect_window := 0.065

var panel_sprite: Sprite2D
var green_sprite: Sprite2D
var frame_sprite: Sprite2D
var needle_sprites: Array[Sprite2D] = []
var needle_positions: Array[float] = []
var resolved_needles: Dictionary = {}
var elapsed := 0.0
var duration := 1.0
var running := false


func _ready() -> void:
	_build_layers()
	set_process(true)


func _process(delta: float) -> void:
	if not running:
		return
	elapsed = minf(elapsed + delta, duration)
	_update_green_crop()
	_update_needles()
	if elapsed >= duration:
		running = false


func configure_round(new_positions: Array, new_duration: float) -> void:
	needle_positions.clear()
	resolved_needles.clear()
	for value: Variant in new_positions:
		needle_positions.append(clampf(float(value), 0.0, 1.0))
	duration = maxf(new_duration, 0.01)
	elapsed = 0.0
	running = false
	_rebuild_needles()
	_update_green_crop()
	_update_needles()
	visible = true


func start_sweep() -> void:
	elapsed = 0.0
	running = true
	_update_green_crop()
	_update_needles()


func stop_sweep() -> void:
	running = false


func reset_indicator() -> void:
	running = false
	elapsed = 0.0
	needle_positions.clear()
	resolved_needles.clear()
	_rebuild_needles()
	_update_green_crop()


func get_progress() -> float:
	return clampf(elapsed / maxf(duration, 0.01), 0.0, 1.0)


func get_elapsed_time() -> float:
	return elapsed


func get_perfect_window() -> float:
	return perfect_window


func flash_result(result_type: String, needle_index := -1) -> void:
	if needle_index < 0 or needle_index >= needle_sprites.size():
		return
	var needle := needle_sprites[needle_index]
	var flash_color := Color("ffd95a")
	match result_type:
		"perfect":
			flash_color = Color("fff19a")
		"burnt":
			flash_color = Color("ff4a2d")
		"raw", "slightly_cooked":
			flash_color = Color("ff9c5a")
	needle.modulate = flash_color
	var tween := create_tween()
	tween.tween_property(needle, "scale", Vector2(1.22, 1.22), 0.08)
	tween.tween_property(needle, "scale", Vector2.ONE, 0.12)
	tween.parallel().tween_property(needle, "modulate", Color.WHITE, 0.12)


func mark_resolved(needle_index: int) -> void:
	if needle_index < 0 or needle_index >= needle_sprites.size():
		return
	resolved_needles[needle_index] = true
	needle_sprites[needle_index].modulate = Color(0.55, 0.55, 0.55, 0.45)


func _build_layers() -> void:
	for child: Node in get_children():
		child.queue_free()

	panel_sprite = _make_sprite("Panel", PANEL_TEXTURE, 0)
	green_sprite = _make_sprite("GreenFill", GREEN_TEXTURE, 1)
	green_sprite.centered = false
	green_sprite.position = -CANVAS_SIZE * 0.5
	green_sprite.region_enabled = true
	frame_sprite = _make_sprite("Frame", FRAME_TEXTURE, 2)
	_rebuild_needles()
	_update_green_crop()


func _make_sprite(node_name: String, texture: Texture2D, layer: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = layer
	add_child(sprite)
	return sprite


func _rebuild_needles() -> void:
	for needle: Sprite2D in needle_sprites:
		if is_instance_valid(needle):
			needle.queue_free()
	needle_sprites.clear()

	for index: int in range(needle_positions.size()):
		var needle := _make_sprite(
			"Needle%d" % (index + 1),
			NEEDLE_TEXTURE,
			3
		)
		needle_sprites.append(needle)


func _update_green_crop() -> void:
	if green_sprite == null:
		return
	var crop_width := CANVAS_SIZE.x * get_progress()
	green_sprite.region_rect = Rect2(0.0, 0.0, crop_width, CANVAS_SIZE.y)
	green_sprite.visible = crop_width > 0.5


func _update_needles() -> void:
	var progress := get_progress()
	for index: int in range(needle_sprites.size()):
		var needle := needle_sprites[index]
		var target := needle_positions[index]
		var target_x := lerpf(TRACK_LEFT, TRACK_RIGHT, target)
		needle.position = Vector2(target_x - CANVAS_SIZE.x * 0.5, 5.0)
		if resolved_needles.has(index):
			needle.modulate = Color(0.55, 0.55, 0.55, 0.45)
		elif absf(progress - target) <= perfect_window:
			needle.modulate = Color("fff19a")
		else:
			needle.modulate = Color.WHITE
