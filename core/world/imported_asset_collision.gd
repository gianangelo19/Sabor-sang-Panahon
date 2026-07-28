extends Node3D

## Adds trimesh collision to imported static scenery that does not ship with it.
## Shapes are cached by mesh resource so repeated scene instances stay inexpensive.

@export var scan_scene_assets := false

const STATIC_ASSET_PREFIXES := [
	"res://assets/",
	"res://game/props/environment/",
	"res://game/props/vehicles/",
]
const LA_PAZ_WORLD_PREFIX := "res://game/worlds/la_paz/"

static var _shape_cache: Dictionary = {}


func _ready() -> void:
	if scan_scene_assets:
		_scan_static_asset_instances(self)
	elif not _subtree_has_collision(self):
		_add_missing_collision(self)


func _scan_static_asset_instances(node: Node) -> void:
	for child in node.get_children():
		if _is_nested_la_paz_scene(child):
			continue

		if _is_static_asset_instance(child):
			if not _subtree_has_collision(child):
				_add_missing_collision(child)
			continue

		# Moving or interactive objects must keep their authored physics behavior.
		if child is CollisionObject3D or child is PathFollow3D:
			continue

		_scan_static_asset_instances(child)


func _is_static_asset_instance(node: Node) -> bool:
	if node.scene_file_path.is_empty():
		return false

	for path_prefix in STATIC_ASSET_PREFIXES:
		if node.scene_file_path.begins_with(path_prefix):
			return true

	return false


func _is_nested_la_paz_scene(node: Node) -> bool:
	return (
		not node.scene_file_path.is_empty()
		and node.scene_file_path.begins_with(LA_PAZ_WORLD_PREFIX)
	)


func _subtree_has_collision(node: Node) -> bool:
	if node is CollisionShape3D and node.shape != null:
		return true
	if node is CollisionPolygon3D:
		return true
	if node is CSGShape3D and node.use_collision:
		return true

	for child in node.get_children():
		if _subtree_has_collision(child):
			return true

	return false


func _add_missing_collision(node: Node) -> void:
	if node is MeshInstance3D:
		_add_mesh_collision(node)

	for child in node.get_children():
		# Do not duplicate collision supplied by the imported asset itself.
		if child is CollisionObject3D or child is CollisionShape3D:
			continue
		_add_missing_collision(child)


func _add_mesh_collision(mesh_instance: MeshInstance3D) -> void:
	if mesh_instance.mesh == null:
		return
	if mesh_instance.has_node("GeneratedStaticBody"):
		return

	var mesh_id := mesh_instance.mesh.get_instance_id()
	var collision_shape: Shape3D = _shape_cache.get(mesh_id)
	if collision_shape == null:
		collision_shape = mesh_instance.mesh.create_trimesh_shape()
		if collision_shape == null:
			return
		_shape_cache[mesh_id] = collision_shape

	var static_body := StaticBody3D.new()
	static_body.name = "GeneratedStaticBody"
	var shape_node := CollisionShape3D.new()
	shape_node.name = "GeneratedCollisionShape"
	shape_node.shape = collision_shape
	static_body.add_child(shape_node)
	mesh_instance.add_child(static_body)
