extends Marker3D

@export var destination_id := ""
@export var display_name := "Destination"
@export_enum("home", "market", "person", "landmark") var icon_category := "landmark"
@export var arrival_radius := 8.0
@export_multiline var near_objective := ""

var _arrival_announced := false


func _ready() -> void:
	add_to_group("navigation_destination")


func _process(_delta: float) -> void:
	if GameState.active_destination != destination_id:
		_arrival_announced = false
		return
	if _arrival_announced:
		return

	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		player = get_tree().root.find_child("ProtoController", true, false) as Node3D
	if player == null:
		return

	if player.global_position.distance_to(global_position) <= arrival_radius:
		_arrival_announced = true
		if not near_objective.is_empty():
			GameState.set_objective(near_objective)


func get_navigation_data() -> Dictionary:
	return {
		"id": destination_id,
		"label": display_name,
		"category": icon_category,
		"position": global_position,
		"arrival_radius": arrival_radius,
	}
