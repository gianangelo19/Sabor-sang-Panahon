extends SceneTree

const SCENERY_SCENES := {
	"res://game/props/environment/background_scenery/la_paz/la_paz_commercial_row.tscn": Vector2(
		45.0,
		14.501953,
	),
	"res://game/props/environment/background_scenery/la_paz/la_paz_heritage_row.tscn": Vector2(
		45.0,
		16.933594,
	),
	"res://game/props/environment/background_scenery/la_paz/la_paz_market_row.tscn": Vector2(
		45.0,
		17.34375,
	),
	"res://game/props/environment/background_scenery/la_paz/la_paz_residential_row.tscn": Vector2(
		45.0,
		17.519531,
	),
	"res://game/props/environment/background_scenery/la_paz/la_paz_seasoning_stall_backdrop.tscn": Vector2(
		12.0,
		6.75,
	),
	"res://game/props/environment/background_scenery/la_paz/la_paz_vendor_stall_backdrop.tscn": Vector2(
		12.0,
		6.75,
	),
}

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path: String in SCENERY_SCENES:
		var packed := load(scene_path) as PackedScene
		_check(packed != null, scene_path + " loads as a PackedScene")
		if packed == null:
			continue

		var scenery := packed.instantiate() as Node3D
		_check(scenery != null, scene_path + " instantiates as Node3D")
		if scenery == null:
			continue

		var mesh_instance := scenery.get_node_or_null("SceneryMesh") as MeshInstance3D
		_check(mesh_instance != null, scene_path + " contains SceneryMesh")
		if mesh_instance == null:
			scenery.free()
			continue

		var quad := mesh_instance.mesh as QuadMesh
		_check(quad != null, scene_path + " uses a QuadMesh")
		if quad == null:
			scenery.free()
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
				scene_path
				+ " preserves its baked background lighting (actual "
				+ str(material.shading_mode)
				+ ", expected "
				+ str(BaseMaterial3D.SHADING_MODE_UNSHADED)
				+ ")",
			)
			_check(
				material.billboard_mode == BaseMaterial3D.BILLBOARD_DISABLED,
				scene_path + " remains fixed-facing",
			)
			_check(material.albedo_texture != null, scene_path + " has a scenery texture")

		var expected_size: Vector2 = SCENERY_SCENES[scene_path]
		_check(
			quad.size.is_equal_approx(expected_size),
			scene_path + " uses the intended background dimensions",
		)
		_check(
			is_equal_approx(mesh_instance.position.y, expected_size.y * 0.5),
			scene_path + " places its root on the ground line",
		)
		_check(
			is_equal_approx(mesh_instance.position.z, 0.02),
			scene_path + " includes the anti-z-fighting offset",
		)
		scenery.free()

	if failures.is_empty():
		print("Background scenery scene verification passed.")
		quit(0)
	else:
		print("Background scenery scene verification failed: " + ", ".join(failures))
		quit(1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)
