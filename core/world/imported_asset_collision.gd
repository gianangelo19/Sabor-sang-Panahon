extends Node3D

## Adds trimesh collision to imported static scenery that does not ship with it.
## Shapes are cached by mesh resource so repeated scene instances stay inexpensive.

static var _shape_cache: Dictionary = {}


func _ready() -> void:
	_add_missing_collision(self)


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
