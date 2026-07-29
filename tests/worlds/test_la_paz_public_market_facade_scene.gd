extends SceneTree

const SCENE_PATH := (
	"res://game/props/environment/buildings/la_paz_public_market_facade.tscn"
)
const EXPECTED_SIZE := Vector2(42.0, 16.849856)
const EXPECTED_TEXTURE_SIZE := Vector2(1735, 696)
const EXPECTED_COLLISION_SIZE := Vector3(42.0, 16.849856, 0.8)

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	_check(packed != null, "market façade loads as a PackedScene")
	if packed == null:
		_finish()
		return

	var facade := packed.instantiate() as Node3D
	_check(facade != null, "market façade instantiates as Node3D")
	if facade == null:
		_finish()
		return

	var mesh_instance := facade.get_node_or_null("FacadeMesh") as MeshInstance3D
	_check(mesh_instance != null, "market façade contains FacadeMesh")
	if mesh_instance != null:
		var quad := mesh_instance.mesh as QuadMesh
		_check(quad != null, "market façade uses a QuadMesh")
		if quad != null:
			_check(
				quad.size.is_equal_approx(EXPECTED_SIZE),
				"market façade uses the intended world dimensions",
			)
			var material := quad.material as StandardMaterial3D
			_check(material != null, "market façade uses StandardMaterial3D")
			if material != null:
				_check(
					material.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR,
					"market façade uses alpha-scissor transparency",
				)
				_check(
					material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST,
					"market façade uses nearest-neighbor filtering",
				)
				_check(
					material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED,
					"market façade preserves its baked pixel-art lighting",
				)
				_check(
					material.billboard_mode == BaseMaterial3D.BILLBOARD_DISABLED,
					"market façade remains fixed-facing",
				)
				_check(
					material.cull_mode == BaseMaterial3D.CULL_DISABLED,
					"market façade is visible from both sides",
				)
				_check(
					material.albedo_texture != null,
					"market façade has a texture",
				)
				if material.albedo_texture != null:
					_check(
						material.albedo_texture.get_size() == EXPECTED_TEXTURE_SIZE,
						"market façade texture has the intended cropped dimensions",
					)
		_check(
			is_equal_approx(mesh_instance.position.y, EXPECTED_SIZE.y * 0.5),
			"market façade root sits on the ground line",
		)
		_check(
			is_equal_approx(mesh_instance.position.z, 0.02),
			"market façade includes an anti-z-fighting offset",
		)
		_check(
			mesh_instance.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
			"market façade does not cast a rectangular quad shadow",
		)

	var static_body := facade.get_node_or_null("StaticBody3D") as StaticBody3D
	_check(static_body != null, "market façade includes a StaticBody3D")
	var collision: CollisionShape3D
	if static_body != null:
		collision = static_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	_check(collision != null, "market façade includes a CollisionShape3D")
	if collision != null:
		var box := collision.shape as BoxShape3D
		_check(box != null, "market façade collision uses a BoxShape3D")
		if box != null:
			_check(
				box.size.is_equal_approx(EXPECTED_COLLISION_SIZE),
				"market façade collider matches its visible footprint",
			)
		_check(
			is_equal_approx(collision.position.y, EXPECTED_SIZE.y * 0.5),
			"market façade collider is grounded",
		)

	facade.free()
	_finish()


func _finish() -> void:
	if failures.is_empty():
		print("La Paz Public Market façade scene verification passed.")
		quit(0)
	else:
		print(
			"La Paz Public Market façade scene verification failed: "
			+ ", ".join(failures),
		)
		quit(1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)
