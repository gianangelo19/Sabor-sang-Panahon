extends SceneTree

const CABLE_SCENES := {
	"res://game/props/environment/infrastructure/cable_clutter/cable_clutter_hanging.tscn": Vector2(
		3.0,
		5.287436,
	),
	"res://game/props/environment/infrastructure/cable_clutter/cable_clutter_horizontal.tscn": Vector2(
		7.0,
		1.982422,
	),
	"res://game/props/environment/infrastructure/cable_clutter/cable_clutter_radial.tscn": Vector2(
		4.5,
		4.494141,
	),
}

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path: String in CABLE_SCENES:
		var packed := load(scene_path) as PackedScene
		_check(packed != null, scene_path + " loads as a PackedScene")
		if packed == null:
			continue

		var cable_clutter := packed.instantiate() as Node3D
		_check(cable_clutter != null, scene_path + " instantiates as Node3D")
		if cable_clutter == null:
			continue

		var mesh_instance := cable_clutter.get_node_or_null("CableMesh") as MeshInstance3D
		_check(mesh_instance != null, scene_path + " contains CableMesh")
		if mesh_instance == null:
			cable_clutter.free()
			continue

		var quad := mesh_instance.mesh as QuadMesh
		_check(quad != null, scene_path + " uses a QuadMesh")
		if quad == null:
			cable_clutter.free()
			continue

		var material := quad.material as StandardMaterial3D
		_check(material != null, scene_path + " uses StandardMaterial3D")
		if material != null:
			_check(
				material.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR,
				scene_path + " uses alpha-scissor transparency",
			)
			_check(
				material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST,
				scene_path + " uses nearest-neighbor texture filtering",
			)
			_check(material.albedo_texture != null, scene_path + " has a cable texture")

		_check(
			quad.size.is_equal_approx(CABLE_SCENES[scene_path] as Vector2),
			scene_path + " uses the intended pole-scale dimensions",
		)
		_check(
			is_equal_approx(mesh_instance.position.z, 0.01),
			scene_path + " includes the anti-z-fighting offset",
		)
		cable_clutter.free()

	if failures.is_empty():
		print("Cable clutter scene verification passed.")
		quit(0)
	else:
		print("Cable clutter scene verification failed: " + ", ".join(failures))
		quit(1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)
