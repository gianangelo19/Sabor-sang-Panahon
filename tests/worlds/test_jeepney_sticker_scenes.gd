extends SceneTree

const STICKERS := {
	"res://game/props/vehicles/jeepney/stickers/bayad_po_sticker.tscn": 253.0 / 384.0,
	"res://game/props/vehicles/jeepney/stickers/dlords_palm_sticker.tscn": 104.0 / 512.0,
	"res://game/props/vehicles/jeepney/stickers/flame_trim_sticker.tscn": 75.0 / 768.0,
	"res://game/props/vehicles/jeepney/stickers/geometric_trim_sticker.tscn": 98.0 / 768.0,
	"res://game/props/vehicles/jeepney/stickers/god_bless_our_trip_sticker.tscn": 180.0 / 768.0,
	"res://game/props/vehicles/jeepney/stickers/hari_ng_kalsada_sticker.tscn": 179.0 / 768.0,
	"res://game/props/vehicles/jeepney/stickers/iloilo_city_sticker.tscn": 104.0 / 512.0,
	"res://game/props/vehicles/jeepney/stickers/jeepney_emblem_sticker.tscn": 1.0,
	"res://game/props/vehicles/jeepney/stickers/la_paz_city_proper_sticker.tscn": 229.0 / 512.0,
	"res://game/props/vehicles/jeepney/stickers/pasahero_sosyal_sticker.tscn": 74.0 / 512.0,
	"res://game/props/vehicles/jeepney/stickers/pavia_lapaz_sticker.tscn": 220.0 / 384.0,
	"res://game/props/vehicles/jeepney/stickers/route_22_sticker.tscn": 201.0 / 512.0,
	"res://game/props/vehicles/jeepney/stickers/sunburst_badge_sticker.tscn": 1.0,
	"res://game/props/vehicles/jeepney/stickers/winged_star_sticker.tscn": 178.0 / 768.0,
}

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path: String in STICKERS:
		var packed := load(scene_path) as PackedScene
		_check(packed != null, scene_path + " loads as a PackedScene")
		if packed == null:
			continue

		var sticker := packed.instantiate() as Node3D
		_check(sticker != null, scene_path + " instantiates as Node3D")
		if sticker == null:
			continue

		var mesh_instance := sticker.get_node_or_null("StickerMesh") as MeshInstance3D
		_check(mesh_instance != null, scene_path + " contains StickerMesh")
		if mesh_instance == null:
			sticker.free()
			continue

		var quad := mesh_instance.mesh as QuadMesh
		_check(quad != null, scene_path + " uses a QuadMesh")
		if quad == null:
			sticker.free()
			continue

		var material := quad.material as StandardMaterial3D
		_check(material != null, scene_path + " uses StandardMaterial3D")
		if material != null:
			_check(
				material.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR,
				scene_path + " uses crisp alpha-scissor transparency",
			)
			_check(
				material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST,
				scene_path + " uses nearest-neighbor texture filtering",
			)
			_check(material.albedo_texture != null, scene_path + " has a sticker texture")

		var expected_ratio := float(STICKERS[scene_path])
		_check(
			is_equal_approx(quad.size.x, 1.0)
			and absf(quad.size.y - expected_ratio) < 0.001,
			scene_path + " preserves the source image aspect ratio",
		)
		_check(
			is_equal_approx(mesh_instance.position.z, 0.003),
			scene_path + " includes the anti-z-fighting offset",
		)
		sticker.free()

	if failures.is_empty():
		print("Jeepney sticker scene verification passed.")
		quit(0)
	else:
		print("Jeepney sticker scene verification failed: " + ", ".join(failures))
		quit(1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)
