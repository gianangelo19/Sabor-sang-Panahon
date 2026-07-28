extends SceneTree

const MAP_PATH := "res://game/worlds/la_paz/la_paz.tscn"
const STATIC_ASSET_PREFIXES := [
	"res://assets/",
	"res://game/props/environment/",
	"res://game/props/vehicles/",
]
const LA_PAZ_WORLD_PREFIX := "res://game/worlds/la_paz/"

var failures: Array[String] = []
var checked_asset_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(MAP_PATH) as PackedScene
	_check(packed != null, "La Paz loads as a PackedScene")
	if packed == null:
		_finish()
		return

	var world := packed.instantiate()
	root.add_child(world)
	await process_frame

	_check(world.get("scan_scene_assets") == true, "La Paz enables its static asset collision scan")
	_audit_static_asset_instances(world)
	_check(checked_asset_count >= 100, "The collision audit covers the map's static assets")
	_check(
		not failures.any(func(message: String) -> bool: return message.begins_with("Missing collision:")),
		"Every static asset instance has collision",
	)

	var older_building := world.get_node_or_null("buildings/Sketchfab_Scene")
	_check(
		older_building != null and _has_generated_collision(older_building),
		"The older building group receives generated collision",
	)
	var older_house := world.get_node_or_null("background/Sketchfab_Scene15")
	_check(
		older_house != null and _has_generated_collision(older_house),
		"The older background houses receive generated collision",
	)

	var moving_jeepney := world.get_node_or_null(
		"jeepney cutscene/AnimationPlayer/Path3D/PathFollow3D/Jeepney",
	)
	_check(
		moving_jeepney != null and not _has_generated_collision(moving_jeepney),
		"The moving cutscene jeepney is not converted into static scenery",
	)

	_stop_audio(world)
	world.queue_free()
	await process_frame
	_finish()


func _audit_static_asset_instances(node: Node) -> void:
	for child in node.get_children():
		if _is_nested_la_paz_scene(child):
			continue

		if _is_static_asset_instance(child):
			checked_asset_count += 1
			if not _subtree_has_collision(child):
				failures.append("Missing collision: " + str(child.get_path()))
			_check_generated_body_duplicates(child)
			continue

		if child is CollisionObject3D or child is PathFollow3D:
			continue

		_audit_static_asset_instances(child)


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


func _has_generated_collision(node: Node) -> bool:
	if node is StaticBody3D and node.name == &"GeneratedStaticBody":
		return true
	for child in node.get_children():
		if _has_generated_collision(child):
			return true
	return false


func _check_generated_body_duplicates(node: Node) -> void:
	if node is MeshInstance3D:
		var generated_body_count := 0
		for child in node.get_children():
			if child is StaticBody3D and child.name == &"GeneratedStaticBody":
				generated_body_count += 1
		if generated_body_count > 1:
			failures.append("Duplicate generated collision: " + str(node.get_path()))

	for child in node.get_children():
		_check_generated_body_duplicates(child)


func _stop_audio(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		node.stop()
		node.stream = null
	for child in node.get_children():
		_stop_audio(child)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	if failures.is_empty():
		print("La Paz asset collision verification passed (%d assets checked)." % checked_asset_count)
		quit(0)
	else:
		for failure in failures:
			push_error("FAIL: " + failure)
		print("La Paz asset collision verification failed: " + ", ".join(failures))
		quit(1)
