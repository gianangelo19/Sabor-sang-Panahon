extends SceneTree

const VENDOR_SCENES := {
	"res://game/characters/npcs/vendors/npc_herbs_vendor.tscn": "Herbs vendor",
	"res://game/characters/npcs/vendors/npc_seasoning_vendor.tscn": "Seasoning vendor",
	"res://game/characters/npcs/vendors/npc_egg_vendor.tscn": "Egg vendor",
}
const EXPECTED_TEXTURE_SIZE := Vector2(384, 608)
const EXPECTED_PIXEL_SIZE := 0.015

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path: String in VENDOR_SCENES:
		_verify_vendor(scene_path, VENDOR_SCENES[scene_path])
	_finish()


func _verify_vendor(scene_path: String, label: String) -> void:
	var packed := load(scene_path) as PackedScene
	_check(packed != null, label + " scene loads")
	if packed == null:
		return

	var vendor := packed.instantiate() as Node3D
	_check(vendor != null, label + " instantiates as Node3D")
	if vendor == null:
		return

	var body := vendor.get_node_or_null("CharacterBody3D") as CharacterBody3D
	var sprite := vendor.get_node_or_null("CharacterBody3D/Sprite3D") as Sprite3D
	var body_collision := vendor.get_node_or_null(
		"CharacterBody3D/CollisionShape3D"
	) as CollisionShape3D
	var interaction_collision := vendor.get_node_or_null(
		"CharacterBody3D/Area3D/CollisionShape3D"
	) as CollisionShape3D

	_check(body != null, label + " has a CharacterBody3D")
	_check(sprite != null, label + " has a Sprite3D")
	_check(body_collision != null, label + " has physical collision")
	_check(interaction_collision != null, label + " has interaction collision")

	if sprite != null:
		_check(
			sprite.billboard == BaseMaterial3D.BILLBOARD_ENABLED,
			label + " enables billboarding",
		)
		_check(
			is_equal_approx(sprite.pixel_size, EXPECTED_PIXEL_SIZE),
			label + " uses the standard NPC world scale",
		)
		_check(
			sprite.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD,
			label + " uses alpha-cut transparency",
		)
		_check(sprite.texture == sprite.front_texture, label + " starts on its front view")

		for property_name: StringName in [
			&"front_texture",
			&"right_texture",
			&"back_texture",
			&"left_texture",
		]:
			var texture := sprite.get(property_name) as Texture2D
			_check(texture != null, label + " has " + String(property_name))
			if texture != null:
				_check(
					texture.get_size() == EXPECTED_TEXTURE_SIZE,
					label + " " + String(property_name) + " is normalized to 384x608",
				)

	vendor.free()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	if failures.is_empty():
		print("Specialty vendor scene verification passed.")
		quit(0)
	else:
		print(
			"Specialty vendor scene verification failed: "
			+ ", ".join(failures)
		)
		quit(1)
