extends SceneTree

const COUNTER_SCENES := [
	"res://game/props/environment/market_stalls/la_paz/meat_counter_topdown.tscn",
	"res://game/props/environment/market_stalls/la_paz/vegetable_counter_topdown.tscn",
	"res://game/props/environment/market_stalls/la_paz/seasoning_counter_topdown.tscn",
]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path: String in COUNTER_SCENES:
		var packed := load(scene_path) as PackedScene
		_check(packed != null, scene_path + " loads as a PackedScene")
		if packed == null:
			continue

		var counter := packed.instantiate() as Node3D
		_check(counter != null, scene_path + " instantiates as Node3D")
		if counter == null:
			continue

		var mesh_instance := counter.get_node_or_null("CounterMesh") as MeshInstance3D
		_check(mesh_instance != null, scene_path + " contains CounterMesh")
		if mesh_instance == null:
			counter.free()
			continue

		var quad := mesh_instance.mesh as QuadMesh
		_check(quad != null, scene_path + " uses a QuadMesh")
		if quad == null:
			counter.free()
			continue

		_check(
			quad.size.is_equal_approx(Vector2(6.0, 2.0)),
			scene_path + " uses the intended 6 x 2 m footprint",
		)
		_check(
			is_equal_approx(mesh_instance.rotation.x, -PI * 0.5),
			scene_path + " lies horizontally for a top-down view",
		)
		_check(
			is_equal_approx(mesh_instance.position.y, 0.02),
			scene_path + " includes the anti-z-fighting lift",
		)

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
				scene_path + " preserves baked sprite lighting",
			)
			_check(material.albedo_texture != null, scene_path + " has a counter texture")

		counter.free()

	if failures.is_empty():
		print("Top-down market counter scene verification passed.")
		quit(0)
	else:
		print("Top-down market counter scene verification failed: " + ", ".join(failures))
		quit(1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)
