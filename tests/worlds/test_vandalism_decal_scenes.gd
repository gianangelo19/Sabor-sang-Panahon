extends SceneTree

const DECAL_SCENES := {
	"res://game/props/environment/vandalism/iloilo_color_burst_decal.tscn": Vector2(
		5.0,
		1.591495,
	),
	"res://game/props/environment/vandalism/punk_tarsier_stencil_decal.tscn": Vector2(
		1.8,
		1.786224,
	),
	"res://game/props/environment/vandalism/palangga_lugar_message_decal.tscn": Vector2(
		3.0,
		1.101923,
	),
	"res://game/props/environment/vandalism/layered_marker_tag_decal.tscn": Vector2(
		2.6,
		1.405,
	),
	"res://game/props/environment/vandalism/la_paz_bubble_piece_decal.tscn": Vector2(
		3.2,
		1.076923,
	),
}

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path: String in DECAL_SCENES:
		var packed := load(scene_path) as PackedScene
		_check(packed != null, scene_path.get_file() + " loads")
		if packed == null:
			continue

		var decal := packed.instantiate() as Node3D
		_check(decal != null, scene_path.get_file() + " instantiates as Node3D")
		if decal == null:
			continue

		var mesh_instance := decal.get_node_or_null("DecalMesh") as MeshInstance3D
		_check(mesh_instance != null, scene_path.get_file() + " contains DecalMesh")
		if mesh_instance == null:
			decal.free()
			continue

		var quad := mesh_instance.mesh as QuadMesh
		_check(quad != null, scene_path.get_file() + " uses a QuadMesh")
		if quad != null:
			_check(
				quad.size.is_equal_approx(DECAL_SCENES[scene_path]),
				scene_path.get_file() + " preserves the texture aspect ratio",
			)
			var material := quad.material as StandardMaterial3D
			_check(material != null, scene_path.get_file() + " uses StandardMaterial3D")
			if material != null:
				_check(
					material.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR,
					scene_path.get_file() + " uses alpha-scissor transparency",
				)
				_check(
					material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST,
					scene_path.get_file() + " uses nearest-neighbor filtering",
				)
				_check(
					material.cull_mode == BaseMaterial3D.CULL_DISABLED,
					scene_path.get_file() + " remains visible from either side",
				)
				_check(
					material.albedo_texture != null,
					scene_path.get_file() + " has a decal texture",
				)

		_check(
			is_equal_approx(mesh_instance.position.z, 0.003),
			scene_path.get_file() + " includes the anti-z-fighting offset",
		)
		_check(
			not mesh_instance.cast_shadow,
			scene_path.get_file() + " does not cast a floating-card shadow",
		)

		decal.free()

	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	if failures.is_empty():
		print("Vandalism decal scene verification passed.")
		quit(0)
	else:
		print("Vandalism decal scene verification failed: " + ", ".join(failures))
		quit(1)
