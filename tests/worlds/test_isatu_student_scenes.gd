extends SceneTree

const STUDENT_SCENES := [
	"res://game/characters/npcs/citizens/npc_isatu_student_female_01.tscn",
	"res://game/characters/npcs/citizens/npc_isatu_student_female_02.tscn",
	"res://game/characters/npcs/citizens/npc_isatu_student_male_01.tscn",
]

const EXPECTED_TEXTURE_SIZE := Vector2(384, 608)
const EXPECTED_PIXEL_SIZE := 0.015

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path: String in STUDENT_SCENES:
		var packed := load(scene_path) as PackedScene
		_check(packed != null, scene_path.get_file() + " loads")
		if packed == null:
			continue

		var npc := packed.instantiate() as Node3D
		_check(npc != null, scene_path.get_file() + " instantiates as Node3D")
		if npc == null:
			continue

		var body := npc.get_node_or_null("CharacterBody3D") as CharacterBody3D
		var sprite := npc.get_node_or_null("CharacterBody3D/Sprite3D") as Sprite3D
		var body_collision := npc.get_node_or_null(
			"CharacterBody3D/CollisionShape3D"
		) as CollisionShape3D
		var interaction_collision := npc.get_node_or_null(
			"CharacterBody3D/Area3D/CollisionShape3D"
		) as CollisionShape3D

		_check(body != null, scene_path.get_file() + " has a CharacterBody3D")
		_check(sprite != null, scene_path.get_file() + " has a Sprite3D")
		_check(body_collision != null, scene_path.get_file() + " has body collision")
		_check(interaction_collision != null, scene_path.get_file() + " has interaction collision")

		if sprite != null:
			_check(
				sprite.billboard == BaseMaterial3D.BILLBOARD_ENABLED,
				scene_path.get_file() + " enables billboarding",
			)
			_check(
				is_equal_approx(sprite.pixel_size, EXPECTED_PIXEL_SIZE),
				scene_path.get_file() + " uses the intended world scale",
			)
			_check(
				sprite.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD,
				scene_path.get_file() + " uses alpha-cut transparency",
			)
			for property_name: StringName in [
				&"front_texture",
				&"right_texture",
				&"back_texture",
				&"left_texture",
			]:
				var texture := sprite.get(property_name) as Texture2D
				_check(
					texture != null,
					scene_path.get_file() + " has " + String(property_name),
				)
				if texture != null:
					_check(
						texture.get_size() == EXPECTED_TEXTURE_SIZE,
						scene_path.get_file() + " "
						+ String(property_name)
						+ " is normalized to 384x608",
					)

		npc.free()

	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	if failures.is_empty():
		print("ISAT U student scene verification passed.")
		quit(0)
	else:
		print("ISAT U student scene verification failed: " + ", ".join(failures))
		quit(1)
