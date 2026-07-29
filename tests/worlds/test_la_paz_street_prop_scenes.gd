extends SceneTree

const STREET_PROP_SCENES := {
	"res://game/props/environment/street_props/twin_arm_streetlight.tscn": {
		"size": Vector2(6.529066, 12.0),
		"texture_size": Vector2(833, 1531),
		"collision_radius": 0.16,
	},
	"res://game/props/environment/street_props/pedestrian_warning_sign.tscn": {
		"size": Vector2(1.031553, 3.2),
		"texture_size": Vector2(519, 1610),
		"collision_radius": 0.08,
	},
	"res://game/props/environment/street_props/intersection_warning_sign.tscn": {
		"size": Vector2(1.15534, 3.2),
		"texture_size": Vector2(595, 1648),
		"collision_radius": 0.08,
	},
	"res://game/props/environment/street_props/wave_pedestrian_railing.tscn": {
		"size": Vector2(4.8, 2.039063),
		"texture_size": Vector2(1024, 435),
		"collision_shape": "box",
		"collision_size": Vector3(4.8, 2.039063, 0.12),
	},
}

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path: String in STREET_PROP_SCENES:
		var packed := load(scene_path) as PackedScene
		_check(packed != null, scene_path + " loads as a PackedScene")
		if packed == null:
			continue

		var prop := packed.instantiate() as Node3D
		_check(prop != null, scene_path + " instantiates as Node3D")
		if prop == null:
			continue

		var mesh_instance := prop.get_node_or_null("StreetPropMesh") as MeshInstance3D
		_check(mesh_instance != null, scene_path + " contains StreetPropMesh")
		if mesh_instance == null:
			prop.free()
			continue

		var spec: Dictionary = STREET_PROP_SCENES[scene_path]
		var expected_size: Vector2 = spec["size"]
		var quad := mesh_instance.mesh as QuadMesh
		_check(quad != null, scene_path + " uses a QuadMesh")
		if quad != null:
			_check(
				quad.size.is_equal_approx(expected_size),
				scene_path + " uses the intended world dimensions",
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
					scene_path + " uses nearest-neighbor filtering",
				)
				_check(
					material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED,
					scene_path + " preserves its baked pixel-art lighting",
				)
				_check(
					material.billboard_mode == BaseMaterial3D.BILLBOARD_DISABLED,
					scene_path + " remains fixed-facing",
				)
				_check(
					material.cull_mode == BaseMaterial3D.CULL_DISABLED,
					scene_path + " remains visible from both sides",
				)
				_check(
					material.albedo_texture != null,
					scene_path + " has a prop texture",
				)
				if material.albedo_texture != null:
					var expected_texture_size: Vector2 = spec["texture_size"]
					_check(
						material.albedo_texture.get_size() == expected_texture_size,
						scene_path + " texture has the intended cropped dimensions",
					)

		_check(
			is_equal_approx(mesh_instance.position.y, expected_size.y * 0.5),
			scene_path + " root sits on the ground line",
		)
		_check(
			is_equal_approx(mesh_instance.position.z, 0.02),
			scene_path + " includes an anti-z-fighting offset",
		)
		_check(
			mesh_instance.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
			scene_path + " does not cast a rectangular quad shadow",
		)

		var static_body := prop.get_node_or_null("StaticBody3D") as StaticBody3D
		_check(static_body != null, scene_path + " includes a StaticBody3D")
		var collision: CollisionShape3D
		if static_body != null:
			collision = (
				static_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
			)
		_check(collision != null, scene_path + " includes a CollisionShape3D")
		if collision != null:
			if spec.get("collision_shape", "cylinder") == "box":
				var box := collision.shape as BoxShape3D
				_check(box != null, scene_path + " collision uses a BoxShape3D")
				if box != null:
					var expected_collision_size: Vector3 = spec["collision_size"]
					_check(
						box.size.is_equal_approx(expected_collision_size),
						scene_path + " barrier collider matches the railing",
					)
			else:
				var cylinder := collision.shape as CylinderShape3D
				_check(
					cylinder != null,
					scene_path + " collision uses a CylinderShape3D",
				)
				if cylinder != null:
					_check(
						is_equal_approx(cylinder.height, expected_size.y),
						scene_path + " pole collider matches the prop height",
					)
					var expected_radius: float = spec["collision_radius"]
					_check(
						is_equal_approx(cylinder.radius, expected_radius),
						scene_path + " pole collider uses the intended radius",
					)
			_check(
				is_equal_approx(collision.position.y, expected_size.y * 0.5),
				scene_path + " collider is grounded",
			)

		prop.free()

	if failures.is_empty():
		print("La Paz street-prop scene verification passed.")
		quit(0)
	else:
		print(
			"La Paz street-prop scene verification failed: "
			+ ", ".join(failures),
		)
		quit(1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)
