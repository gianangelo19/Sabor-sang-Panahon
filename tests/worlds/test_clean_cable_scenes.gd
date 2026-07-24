extends SceneTree

const CABLE_SCENES := {
	"res://game/props/environment/infrastructure/cables_clean/cable_clean_bundle.tscn": Vector2(
		8.0,
		1.119792,
	),
	"res://game/props/environment/infrastructure/cables_clean/cable_clean_junction_loop.tscn": Vector2(
		8.0,
		2.005208,
	),
	"res://game/props/environment/infrastructure/cables_clean/cable_clean_pole_drop.tscn": Vector2(
		1.125,
		6.0,
	),
	"res://game/props/environment/infrastructure/cables_clean/cable_clean_single_long.tscn": Vector2(
		12.0,
		0.898438,
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

		var cable := packed.instantiate() as Node3D
		_check(cable != null, scene_path + " instantiates as Node3D")
		if cable == null:
			continue

		var mesh_instance := cable.get_node_or_null("CableMesh") as MeshInstance3D
		_check(mesh_instance != null, scene_path + " contains CableMesh")
		if mesh_instance == null:
			cable.free()
			continue

		var quad := mesh_instance.mesh as QuadMesh
		_check(quad != null, scene_path + " uses a QuadMesh")
		if quad == null:
			cable.free()
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
			_check(
				material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED,
				scene_path + " preserves its baked pixel-art lighting",
			)
			_check(
				material.billboard_mode == BaseMaterial3D.BILLBOARD_DISABLED,
				scene_path + " remains fixed-facing",
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
		cable.free()

	if failures.is_empty():
		print("Clean cable scene verification passed.")
		quit(0)
	else:
		print("Clean cable scene verification failed: " + ", ".join(failures))
		quit(1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)
