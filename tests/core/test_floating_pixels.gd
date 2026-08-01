extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var controller_scene := load("res://addons/proto_controller/proto_controller.tscn") as PackedScene
	var controller := controller_scene.instantiate()
	root.add_child(controller)
	await process_frame

	var pixels := controller.get_node_or_null(
		"Head/Camera3D/GlobalFloatingPixels"
	) as GPUParticles3D
	_check(pixels != null, "The shared player camera owns the global floating pixel field")
	if pixels != null:
		_check(pixels.emitting, "The global floating pixel field emits continuously")
		_check(pixels.amount == 96, "The global field remains subtle and sparse")
		_check(not pixels.local_coords, "Floating pixels remain in world space after emission")
		_check(is_equal_approx(pixels.lifetime, 12.0), "Floating pixels drift for a long, gentle lifetime")
		var particles := pixels.process_material as ParticleProcessMaterial
		_check(particles != null, "Floating pixels use a native particle process material")
		if particles != null:
			_check(
				particles.emission_shape == ParticleProcessMaterial.EMISSION_SHAPE_BOX,
				"The particle volume surrounds the camera view",
			)
			_check(
				particles.emission_box_extents == Vector3(11, 6, 12),
				"The global field fills nearby world space",
			)
		var pixel_mesh := pixels.draw_pass_1 as QuadMesh
		_check(pixel_mesh != null, "Floating pixels render as square billboards")
		if pixel_mesh != null:
			_check(pixel_mesh.size == Vector2(0.07, 0.07), "The square particles are visibly sized")

	var overlay := controller.get_node("Head/MeshInstance3D") as MeshInstance3D
	var overlay_material := overlay.mesh.material as ShaderMaterial
	_check(overlay_material != null, "The CRT overlay still loads independently")
	if overlay_material != null:
		_check(
			not overlay_material.shader.code.contains("floating_pixel"),
			"The CRT shader no longer generates the particle effect",
		)

	controller.queue_free()
	_finish()

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)

func _finish() -> void:
	if failures.is_empty():
		print("Floating pixel verification passed.")
		quit(0)
	else:
		print("Floating pixel verification failed: " + ", ".join(failures))
		quit(1)
