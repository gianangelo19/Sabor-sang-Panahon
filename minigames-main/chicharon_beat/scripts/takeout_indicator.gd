extends Node2D

@export var radius := 45.0
@export var arrow_height := 90.0

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var pulse := 0.65 + sin(Time.get_ticks_msec() / 180.0) * 0.25
	var color := Color(1.0, 0.85, 0.15, pulse)

	# Circle / outline where the chicharon should be taken out.
	draw_arc(
		Vector2.ZERO,
		radius,
		0.0,
		TAU,
		64,
		color,
		4.0
	)

	# Arrow pointing down to the take-out point.
	var arrow_top := Vector2(0, -arrow_height)
	var arrow_bottom := Vector2(0, -radius - 8)

	draw_line(arrow_top, arrow_bottom, color, 5.0)

	var arrow_head := PackedVector2Array([
		Vector2(0, -radius),
		Vector2(-14, -radius - 18),
		Vector2(14, -radius - 18)
	])

	var arrow_colors := PackedColorArray([
		color,
		color,
		color
	])

	draw_polygon(arrow_head, arrow_colors)
