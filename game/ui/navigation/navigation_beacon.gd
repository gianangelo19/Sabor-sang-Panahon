extends Control

const EDGE_MARGIN := 70.0

var current_marker: Marker3D = null
var current_player: Node3D = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameState.navigation_changed.connect(_refresh_destination)
	call_deferred("_refresh_destination")


func _process(_delta: float) -> void:
	if current_marker == null or not is_instance_valid(current_marker):
		_refresh_destination()
	queue_redraw()


func _refresh_destination() -> void:
	current_marker = null
	if GameState.active_destination.is_empty() or not GameState.has_seen_active_destination_in_maps():
		return
	for marker in get_tree().get_nodes_in_group("navigation_destination"):
		if marker.destination_id == GameState.active_destination:
			current_marker = marker
			break


func _draw() -> void:
	if not GameState.has_seen_active_destination_in_maps():
		return
	if current_marker == null or not is_instance_valid(current_marker):
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	if current_player == null or not is_instance_valid(current_player):
		current_player = get_tree().get_first_node_in_group("player") as Node3D
		if current_player == null:
			current_player = get_tree().root.find_child("ProtoController", true, false) as Node3D
	if current_player == null:
		return

	var target := current_marker.global_position + Vector3.UP * 4.0
	var distance := current_player.global_position.distance_to(current_marker.global_position)
	var arrival_radius: float = current_marker.arrival_radius
	var alpha := clampf((distance - arrival_radius) / maxf(arrival_radius, 1.0), 0.0, 1.0)
	if alpha <= 0.01:
		return

	var screen_position: Vector2
	var projected := camera.unproject_position(target)
	var usable_rect := Rect2(
		Vector2(EDGE_MARGIN, EDGE_MARGIN),
		size - Vector2(EDGE_MARGIN * 2.0, EDGE_MARGIN * 2.0)
	)
	if not camera.is_position_behind(target) and usable_rect.has_point(projected):
		screen_position = projected
	else:
		var local_target := camera.to_local(target)
		var direction := Vector2(local_target.x, local_target.z).normalized()
		if direction.is_zero_approx():
			direction = Vector2.UP
		var center := size * 0.5
		screen_position = center + direction * maxf(size.x, size.y)
		screen_position.x = clampf(screen_position.x, usable_rect.position.x, usable_rect.end.x)
		screen_position.y = clampf(screen_position.y, usable_rect.position.y, usable_rect.end.y)

	var color := Color(0.98, 0.69, 0.32, alpha)
	var outline := Color(0.08, 0.05, 0.03, alpha * 0.9)
	var points := PackedVector2Array([
		screen_position + Vector2(0, -13),
		screen_position + Vector2(10, 0),
		screen_position + Vector2(0, 13),
		screen_position + Vector2(-10, 0),
	])
	draw_colored_polygon(points, outline)
	var inner := PackedVector2Array()
	for point in points:
		inner.append(screen_position + (point - screen_position) * 0.7)
	draw_colored_polygon(inner, color)

	var caption := "%s  •  %dm" % [current_marker.display_name, roundi(distance)]
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	var text_position := screen_position + Vector2(-text_size.x * 0.5, 34)
	draw_rect(Rect2(text_position - Vector2(6, 18), text_size + Vector2(12, 8)), Color(0.05, 0.04, 0.03, alpha * 0.82), true)
	draw_string(font, text_position, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.93, 0.78, alpha))
