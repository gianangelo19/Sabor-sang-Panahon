extends SceneTree

const LANDMARK_SCENES := {
	"res://game/props/environment/signage/commercial_landmarks/gaysano_g_logo.tscn": {
		"size": Vector2(2.0, 2.080471),
		"grounded": false,
	},
	"res://game/props/environment/signage/commercial_landmarks/gaysano_la_paz_sign.tscn": {
		"size": Vector2(7.0, 1.754557),
		"grounded": false,
	},
	"res://game/props/environment/signage/commercial_landmarks/jabilee_sign.tscn": {
		"size": Vector2(4.0, 3.989381),
		"grounded": false,
	},
	"res://game/props/environment/signage/commercial_landmarks/peteron_price_pylon.tscn": {
		"size": Vector2(1.902344, 6.0),
		"grounded": true,
	},
	"res://game/props/environment/signage/commercial_landmarks/peteron_tall_pylon.tscn": {
		"size": Vector2(2.632813, 12.0),
		"grounded": true,
	},
	"res://game/props/environment/signage/commercial_landmarks/six_eleven_sign.tscn": {
		"size": Vector2(4.0, 4.0),
		"grounded": false,
	},
	"res://game/props/environment/signage/commercial_landmarks/six_eleven_white_wordmark.tscn": {
		"size": Vector2(6.0, 1.5),
		"grounded": false,
	},
}

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path: String in LANDMARK_SCENES:
		var packed := load(scene_path) as PackedScene
		_check(packed != null, scene_path + " loads as a PackedScene")
		if packed == null:
			continue

		var landmark := packed.instantiate() as Node3D
		_check(landmark != null, scene_path + " instantiates as Node3D")
		if landmark == null:
			continue

		var mesh_instance := landmark.get_node_or_null("LandmarkMesh") as MeshInstance3D
		_check(mesh_instance != null, scene_path + " contains LandmarkMesh")
		if mesh_instance == null:
			landmark.free()
			continue

		var quad := mesh_instance.mesh as QuadMesh
		_check(quad != null, scene_path + " uses a QuadMesh")
		if quad == null:
			landmark.free()
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
			_check(material.albedo_texture != null, scene_path + " has a landmark texture")

		var spec: Dictionary = LANDMARK_SCENES[scene_path]
		var expected_size: Vector2 = spec["size"]
		_check(
			quad.size.is_equal_approx(expected_size),
			scene_path + " uses the intended world dimensions",
		)
		var expected_y := expected_size.y * 0.5 if spec["grounded"] else 0.0
		_check(
			is_equal_approx(mesh_instance.position.y, expected_y),
			scene_path + " uses the intended mounting origin",
		)
		_check(
			is_equal_approx(mesh_instance.position.z, 0.02),
			scene_path + " includes the anti-z-fighting offset",
		)
		landmark.free()

	if failures.is_empty():
		print("Commercial landmark scene verification passed.")
		quit(0)
	else:
		print("Commercial landmark scene verification failed: " + ", ".join(failures))
		quit(1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)
