extends SceneTree

const COMPONENT_SCENES := {
	"res://game/props/environment/buildings/peteron_station/peteron_support_column.tscn": {
		"size": Vector2(1.202411, 5.0),
		"texture_size": Vector2(379, 1576),
		"mesh_y": 2.5,
		"collision_size": Vector3(0.8, 5.0, 0.8),
	},
	"res://game/props/environment/buildings/peteron_station/peteron_fuel_pump_island.tscn": {
		"size": Vector2(2.87746, 2.4),
		"texture_size": Vector2(1133, 945),
		"mesh_y": 1.2,
		"collision_size": Vector3(2.6, 2.4, 1.2),
	},
}
const CANOPY_SCENE := (
	"res://game/props/environment/buildings/peteron_station/peteron_canopy.tscn"
)
const CANOPY_FACE_SCENES := {
	"res://game/props/environment/buildings/peteron_station/peteron_canopy_front_face.tscn": {
		"size": Vector2(20.0, 2.539062),
		"collision_size": Vector3(20.0, 2.539062, 0.05),
		"texture_size": Vector2(1024, 130),
	},
	"res://game/props/environment/buildings/peteron_station/peteron_canopy_back_face.tscn": {
		"size": Vector2(20.0, 2.539062),
		"collision_size": Vector3(20.0, 2.539062, 0.05),
		"texture_size": Vector2(1024, 130),
	},
	"res://game/props/environment/buildings/peteron_station/peteron_canopy_top_face.tscn": {
		"size": Vector2(20.0, 5.996094),
		"collision_size": Vector3(20.0, 5.996094, 0.05),
		"texture_size": Vector2(1024, 307),
	},
	"res://game/props/environment/buildings/peteron_station/peteron_canopy_bottom_face.tscn": {
		"size": Vector2(20.0, 5.996094),
		"collision_size": Vector3(20.0, 5.996094, 0.05),
		"texture_size": Vector2(1024, 307),
	},
	"res://game/props/environment/buildings/peteron_station/peteron_canopy_left_face.tscn": {
		"size": Vector2(6.0, 2.542969),
		"collision_size": Vector3(6.0, 2.542969, 0.05),
		"texture_size": Vector2(512, 217),
	},
	"res://game/props/environment/buildings/peteron_station/peteron_canopy_right_face.tscn": {
		"size": Vector2(6.0, 2.542969),
		"collision_size": Vector3(6.0, 2.542969, 0.05),
		"texture_size": Vector2(512, 217),
	},
}
const ASSEMBLED_SCENE := (
	"res://game/props/environment/buildings/peteron_station/"
	+ "peteron_station_assembled.tscn"
)

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path: String in COMPONENT_SCENES:
		_verify_component(scene_path, COMPONENT_SCENES[scene_path])
	for scene_path: String in CANOPY_FACE_SCENES:
		_verify_face_scene(scene_path, CANOPY_FACE_SCENES[scene_path])
	_verify_flat_canopy_wrapper()
	_verify_assembled_scene()
	_finish()


func _verify_component(scene_path: String, spec: Dictionary) -> void:
	var packed := load(scene_path) as PackedScene
	_check(packed != null, scene_path + " loads as a PackedScene")
	if packed == null:
		return

	var component := packed.instantiate() as Node3D
	_check(component != null, scene_path + " instantiates as Node3D")
	if component == null:
		return

	var mesh_instance := component.get_node_or_null("ComponentMesh") as MeshInstance3D
	_check(mesh_instance != null, scene_path + " contains ComponentMesh")
	if mesh_instance != null:
		var quad := mesh_instance.mesh as QuadMesh
		_check(quad != null, scene_path + " uses a QuadMesh")
		if quad != null:
			var expected_size: Vector2 = spec["size"]
			_check(
				quad.size.is_equal_approx(expected_size),
				scene_path + " preserves its source aspect ratio",
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
				_check(material.albedo_texture != null, scene_path + " has a texture")
				if material.albedo_texture != null:
					var expected_texture_size: Vector2 = spec["texture_size"]
					_check(
						material.albedo_texture.get_size() == expected_texture_size,
						scene_path + " texture has the intended cropped dimensions",
					)
		var expected_mesh_y: float = spec["mesh_y"]
		_check(
			is_equal_approx(mesh_instance.position.y, expected_mesh_y),
			scene_path + " uses the intended assembly origin",
		)
		_check(
			mesh_instance.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
			scene_path + " avoids rectangular quad shadows",
		)

	var collision := component.get_node_or_null(
		"StaticBody3D/CollisionShape3D",
	) as CollisionShape3D
	_check(collision != null, scene_path + " includes component collision")
	if collision != null:
		var box := collision.shape as BoxShape3D
		_check(box != null, scene_path + " collision uses a BoxShape3D")
		if box != null:
			var expected_collision_size: Vector3 = spec["collision_size"]
			_check(
				box.size.is_equal_approx(expected_collision_size),
				scene_path + " collision uses the intended dimensions",
			)

	component.free()


func _verify_face_scene(scene_path: String, spec: Dictionary) -> void:
	var packed := load(scene_path) as PackedScene
	_check(packed != null, scene_path + " loads independently")
	if packed == null:
		return
	var face := packed.instantiate() as Node3D
	_check(face != null, scene_path + " instantiates as Node3D")
	if face == null:
		return

	var mesh_instance := face.get_node_or_null("FaceMesh") as MeshInstance3D
	_check(mesh_instance != null, scene_path + " includes FaceMesh")
	if mesh_instance != null:
		var quad := mesh_instance.mesh as QuadMesh
		_check(quad != null, scene_path + " uses a QuadMesh")
		if quad != null:
			var expected_size: Vector2 = spec["size"]
			_check(
				quad.size.is_equal_approx(expected_size),
				scene_path + " has the intended face dimensions",
			)
			var material := quad.material as StandardMaterial3D
			_check(material != null, scene_path + " has a face material")
			if material != null:
				_check(
					material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED,
					scene_path + " preserves the pixel-art colors",
				)
				_check(
					material.cull_mode == BaseMaterial3D.CULL_DISABLED,
					scene_path + " remains visible while being positioned",
				)
				_check(
					material.billboard_mode == BaseMaterial3D.BILLBOARD_DISABLED,
					scene_path + " does not auto-rotate as a billboard",
				)
				_check(
					material.transparency
					== BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR,
					scene_path + " uses alpha-scissor transparency",
				)
				_check(
					material.texture_filter
					== BaseMaterial3D.TEXTURE_FILTER_NEAREST,
					scene_path + " uses nearest-neighbor filtering",
				)
				_check(
					material.albedo_texture != null,
					scene_path + " has its own face texture",
				)
				if material.albedo_texture != null:
					var expected_texture_size: Vector2 = spec["texture_size"]
					_check(
						material.albedo_texture.get_size()
						== expected_texture_size,
						scene_path + " uses its intended flat sprite dimensions",
					)
		_check(
			mesh_instance.cast_shadow
			== GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
			scene_path + " avoids rectangular quad shadows",
		)
		_check(
			mesh_instance.transform.is_equal_approx(Transform3D.IDENTITY),
			scene_path + " presents its face straight-on at the scene origin",
		)

	var collision := face.get_node_or_null(
		"StaticBody3D/CollisionShape3D",
	) as CollisionShape3D
	_check(collision != null, scene_path + " includes its own thin collision")
	if collision != null:
		var box := collision.shape as BoxShape3D
		_check(box != null, scene_path + " collision uses a BoxShape3D")
		if box != null:
			var expected_collision_size: Vector3 = spec["collision_size"]
			_check(
				box.size.is_equal_approx(expected_collision_size),
				scene_path + " collision matches the face dimensions",
			)
	face.free()


func _verify_flat_canopy_wrapper() -> void:
	var packed := load(CANOPY_SCENE) as PackedScene
	_check(packed != null, "Peteron flat canopy compatibility scene loads")
	if packed == null:
		return
	var canopy := packed.instantiate() as Node3D
	_check(canopy != null, "Peteron flat canopy compatibility scene instantiates")
	if canopy == null:
		return
	_check(
		canopy.get_child_count() == 1,
		"Peteron compatibility scene no longer assembles a 3D canopy",
	)
	var front := canopy.get_node_or_null("FrontFace") as Node3D
	_check(front != null, "Peteron compatibility scene keeps the flat front face")
	if front != null:
		_check(
			front.transform.is_equal_approx(Transform3D.IDENTITY),
			"Peteron compatibility front remains straight-on",
		)
		_check(
			front.scene_file_path.ends_with("peteron_canopy_front_face.tscn"),
			"Peteron compatibility scene links to the standalone front scene",
		)
	canopy.free()


func _verify_assembled_scene() -> void:
	var packed := load(ASSEMBLED_SCENE) as PackedScene
	_check(packed != null, "assembled Peteron station loads")
	if packed == null:
		return
	var station := packed.instantiate() as Node3D
	_check(station != null, "assembled Peteron station instantiates")
	if station == null:
		return

	var expected_children := [
		"Canopy",
		"SupportColumnLeft",
		"SupportColumnMiddle",
		"SupportColumnRight",
		"FuelPumpLeft",
		"FuelPumpRight",
	]
	for child_name: String in expected_children:
		_check(
			station.get_node_or_null(child_name) != null,
			"assembled Peteron station includes " + child_name,
		)

	var canopy := station.get_node_or_null("Canopy") as Node3D
	_check(
		canopy != null and is_equal_approx(canopy.position.y, 4.85),
		"assembled canopy is mounted above the supports",
	)
	_check(
		canopy != null
		and canopy.get_node_or_null("FrontFace/FaceMesh") != null,
		"legacy station preview uses only the flat canopy-front sprite",
	)
	_check(
		canopy != null and canopy.get_node_or_null("BottomFace") == null,
		"legacy station preview no longer constructs a 3D canopy",
	)
	_check(
		station.get_node_or_null("SupportColumnLeft").position.x < 0.0
		and station.get_node_or_null("SupportColumnRight").position.x > 0.0,
		"assembled station spaces its outer supports",
	)
	_check(
		station.get_node_or_null("FuelPumpLeft").position.z > 0.0
		and station.get_node_or_null("SupportColumnLeft").position.z < 0.0,
		"assembled pumps render in front of the supports",
	)
	station.free()


func _finish() -> void:
	if failures.is_empty():
		print("Peteron station scene verification passed.")
		quit(0)
	else:
		print("Peteron station scene verification failed: " + ", ".join(failures))
		quit(1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)
