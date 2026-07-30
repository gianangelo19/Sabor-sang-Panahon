extends Node3D

signal collected(item_id: StringName, display_name: String, item: Node3D)

@export var item_id: StringName
@export var display_name := "Item"
@export var interaction_label := "pick up"
@export var active := true
@export var collect_on_interact := true
@export var required_story_flag := ""

@onready var collision_shape: CollisionShape3D = (
	$StaticBody3D/CollisionShape3D
)

var _collected := false


func _ready() -> void:
	add_to_group("collectible_world_item")
	set_active(active and _story_gate_is_open())


func get_interaction_text() -> String:
	if not active or _collected:
		return ""
	return "Press F to %s %s" % [interaction_label, display_name]


func interact() -> void:
	if not active or _collected or not collect_on_interact:
		return

	_collected = true
	set_active(false)
	GameState.add_inventory_item(str(item_id), display_name)
	collected.emit(item_id, display_name, self)


func set_active(should_be_active: bool) -> void:
	if should_be_active and not _story_gate_is_open():
		should_be_active = false
	active = should_be_active
	visible = should_be_active and not _collected
	if collision_shape != null:
		collision_shape.set_deferred(
			"disabled",
			not should_be_active or _collected,
		)


func is_collected() -> bool:
	return _collected


func reset_collection() -> void:
	_collected = false
	set_active(_story_gate_is_open())


func _story_gate_is_open() -> bool:
	return required_story_flag.is_empty() or GameState.has_story_flag(required_story_flag)
