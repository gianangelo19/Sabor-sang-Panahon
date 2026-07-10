extends Control

const WORLD_MIN := Vector2(-75.0, -122.0)
const WORLD_MAX := Vector2(55.0, 65.0)
const MAP_CENTER := Vector3(-10.0, 150.0, -28.5)
const MAP_HEIGHT := 187.0

var map_viewport: SubViewport
var marker_layer: Control
var player_pin: Label
var marker_buttons: Dictionary = {}
var player: Node3D = null
var _rebuild_queued := false


func _ready() -> void:
	custom_minimum_size = Vector2(310, 405)
	clip_contents = true
	_build_live_map()
	GameState.navigation_changed.connect(_queue_rebuild_markers)
	_queue_rebuild_markers()


func _build_live_map() -> void:
	var container := SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)

	map_viewport = SubViewport.new()
	map_viewport.size = Vector2i(310, 405)
	map_viewport.world_3d = get_viewport().world_3d
	map_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	container.add_child(map_viewport)

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = MAP_HEIGHT
	camera.position = MAP_CENTER
	camera.rotation_degrees = Vector3(-90, 0, 0)
	camera.current = true
	map_viewport.add_child(camera)

	var tint := ColorRect.new()
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(0.05, 0.15, 0.17, 0.42)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tint)

	var border := Panel.new()
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var border_style := StyleBoxFlat.new()
	border_style.bg_color = Color(0, 0, 0, 0)
	border_style.border_color = Color("d8c49d")
	border_style.set_border_width_all(2)
	border.add_theme_stylebox_override("panel", border_style)
	add_child(border)

	marker_layer = Control.new()
	marker_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	marker_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(marker_layer)

	player_pin = Label.new()
	player_pin.text = "▲"
	player_pin.add_theme_font_size_override("font_size", 22)
	player_pin.add_theme_color_override("font_color", Color("7de3ff"))
	player_pin.custom_minimum_size = Vector2(28, 28)
	player_pin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_pin.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker_layer.add_child(player_pin)


func _process(_delta: float) -> void:
	_mark_active_destination_if_visible()
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node3D
		if player == null:
			player = get_tree().root.find_child("ProtoController", true, false) as Node3D
	if player != null:
		player_pin.position = _world_to_map(player.global_position) - player_pin.size * 0.5
		player_pin.rotation = -player.rotation.y
	_update_marker_positions()


func _rebuild_markers() -> void:
	_rebuild_queued = false
	if marker_layer == null or not is_instance_valid(marker_layer):
		return
	_mark_active_destination_if_visible()
	for child in marker_layer.get_children():
		if child is Button:
			child.visible = false
			child.queue_free()
	marker_buttons.clear()
	for marker in get_tree().get_nodes_in_group("navigation_destination"):
		if not GameState.is_destination_unlocked(marker.destination_id):
			continue
		var button := Button.new()
		button.custom_minimum_size = Vector2(116, 42)
		button.text = ("◆ " if GameState.active_destination == marker.destination_id else "◇ ") + marker.display_name
		button.add_theme_font_size_override("font_size", 13)
		button.tooltip_text = "Select " + marker.display_name
		button.disabled = GameState.is_destination_completed(marker.destination_id)
		button.pressed.connect(_select_destination_from_map.bind(marker.destination_id))
		marker_layer.add_child(button)
		marker_buttons[marker.destination_id] = {"button": button, "marker": marker}
	_update_marker_positions()


func _select_destination_from_map(destination_id: String) -> void:
	if GameState.select_destination(destination_id):
		GameState.mark_active_destination_seen_in_maps()
		_queue_rebuild_markers()


func _queue_rebuild_markers() -> void:
	if _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild_markers")


func _mark_active_destination_if_visible() -> void:
	if is_visible_in_tree():
		GameState.mark_active_destination_seen_in_maps()


func _update_marker_positions() -> void:
	for entry in marker_buttons.values():
		var button: Button = entry.button
		var marker: Node3D = entry.marker
		if not is_instance_valid(button) or not is_instance_valid(marker):
			continue
		var map_position := _world_to_map(marker.global_position)
		button.position = map_position - Vector2(button.size.x * 0.5, button.size.y + 8)
		button.position.x = clampf(button.position.x, 3.0, maxf(size.x - button.size.x - 3.0, 3.0))
		button.position.y = clampf(button.position.y, 3.0, maxf(size.y - button.size.y - 3.0, 3.0))


func _world_to_map(world_position: Vector3) -> Vector2:
	var normalized := Vector2(
		inverse_lerp(WORLD_MIN.x, WORLD_MAX.x, world_position.x),
		inverse_lerp(WORLD_MIN.y, WORLD_MAX.y, world_position.z)
	)
	return Vector2(normalized.x * size.x, normalized.y * size.y)
