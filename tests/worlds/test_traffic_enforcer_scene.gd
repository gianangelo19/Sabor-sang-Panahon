extends SceneTree

const SCENE_PATH := "res://game/characters/npcs/citizens/npc_traffic_enforcer.tscn"
const EXPECTED_TEXTURE_SIZE := Vector2(384, 608)
const EXPECTED_PIXEL_SIZE := 0.015

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	_check(packed != null, "Traffic enforcer scene loads")
	if packed == null:
		_finish()
		return

	var npc := packed.instantiate() as Node3D
	_check(npc != null, "Traffic enforcer instantiates as Node3D")
	if npc == null:
		_finish()
		return

	var body := npc.get_node_or_null("CharacterBody3D") as CharacterBody3D
	var sprite := npc.get_node_or_null("CharacterBody3D/Sprite3D") as Sprite3D
	var body_collision := npc.get_node_or_null(
		"CharacterBody3D/CollisionShape3D"
	) as CollisionShape3D
	var interaction_collision := npc.get_node_or_null(
		"CharacterBody3D/Area3D/CollisionShape3D"
	) as CollisionShape3D

	_check(body != null, "Traffic enforcer has a CharacterBody3D")
	_check(sprite != null, "Traffic enforcer has a Sprite3D")
	_check(body_collision != null, "Traffic enforcer has body collision")
	_check(interaction_collision != null, "Traffic enforcer has interaction collision")

	if sprite != null:
		_check(
			sprite.billboard == BaseMaterial3D.BILLBOARD_ENABLED,
			"Traffic enforcer enables billboarding",
		)
		_check(
			is_equal_approx(sprite.pixel_size, EXPECTED_PIXEL_SIZE),
			"Traffic enforcer uses the intended world scale",
		)
		_check(
			sprite.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD,
			"Traffic enforcer uses alpha-cut transparency",
		)
		_check(sprite.texture == sprite.front_texture, "Traffic enforcer starts on the front view")
		_check(
			sprite.right_texture.resource_path.ends_with(
				"npc_traffic_enforcer_left.png"
			),
			"Traffic enforcer uses the corrected right-side artwork",
		)
		_check(
			sprite.left_texture.resource_path.ends_with(
				"npc_traffic_enforcer_right.png"
			),
			"Traffic enforcer uses the corrected left-side artwork",
		)

		for property_name: StringName in [
			&"front_texture",
			&"right_texture",
			&"back_texture",
			&"left_texture",
		]:
			var texture := sprite.get(property_name) as Texture2D
			_check(texture != null, "Traffic enforcer has " + String(property_name))
			if texture != null:
				_check(
					texture.get_size() == EXPECTED_TEXTURE_SIZE,
					String(property_name) + " is normalized to 384x608",
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
		print("Traffic enforcer scene verification passed.")
		quit(0)
	else:
		print("Traffic enforcer scene verification failed: " + ", ".join(failures))
		quit(1)
