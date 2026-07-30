extends SceneTree

const ITEM_SCENES := {
	"res://game/props/items/collectibles/empty_aged_jar_item.tscn": &"empty_aged_jar",
	"res://game/props/items/collectibles/crank_handle_item.tscn": &"crank_handle",
}
const EXPECTED_TEXTURE_SIZE := Vector2(512, 512)
const EXPECTED_PIXEL_SIZE := 0.0035

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path: String in ITEM_SCENES:
		await _verify_item(scene_path, ITEM_SCENES[scene_path])
	_finish()


func _verify_item(scene_path: String, expected_item_id: StringName) -> void:
	var game_state := root.get_node("GameState")
	if expected_item_id == &"crank_handle":
		game_state.set_story_flag("milk_released_crank")
	var label := scene_path.get_file()
	var packed := load(scene_path) as PackedScene
	_check(packed != null, label + " loads")
	if packed == null:
		return

	var item := packed.instantiate() as Node3D
	_check(item != null, label + " instantiates as Node3D")
	if item == null:
		return
	root.add_child(item)
	await process_frame

	var sprite := item.get_node_or_null("Sprite3D") as Sprite3D
	var body := item.get_node_or_null("StaticBody3D") as StaticBody3D
	var collision := item.get_node_or_null(
		"StaticBody3D/CollisionShape3D"
	) as CollisionShape3D

	_check(sprite != null, label + " has a Sprite3D")
	_check(body != null, label + " has a StaticBody3D")
	_check(collision != null, label + " has item collision")
	_check(item.has_method("interact"), label + " is interactable")
	_check(item.has_signal("collected"), label + " exposes a collection signal")
	_check(
		item.get_interaction_text().begins_with("Press F to "),
		label + " displays the F interaction prompt",
	)
	_check(
		item.get("item_id") == expected_item_id,
		label + " has the expected item ID",
	)
	_check(
		item.is_in_group("collectible_world_item"),
		label + " joins the collectible item group",
	)

	if sprite != null:
		_check(
			sprite.billboard == BaseMaterial3D.BILLBOARD_ENABLED,
			label + " enables regular billboarding",
		)
		_check(
			is_equal_approx(sprite.pixel_size, EXPECTED_PIXEL_SIZE),
			label + " uses the intended world scale",
		)
		_check(
			sprite.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD,
			label + " uses alpha-cut transparency",
		)
		_check(sprite.texture != null, label + " has a texture")
		if sprite.texture != null:
			_check(
				sprite.texture.get_size() == EXPECTED_TEXTURE_SIZE,
				label + " uses a normalized 512x512 texture",
			)

	var events: Array[StringName] = []
	item.collected.connect(
		func(
			collected_id: StringName,
			_display_name: String,
			_item: Node3D,
		) -> void:
			events.append(collected_id)
	)
	item.interact()
	await process_frame

	_check(item.is_collected(), label + " records collection")
	_check(not item.visible, label + " hides after collection")
	_check(collision != null and collision.disabled, label + " disables collision after collection")
	_check(
		events == [expected_item_id],
		label + " emits its stable item ID when collected",
	)

	item.reset_collection()
	await process_frame
	_check(not item.is_collected(), label + " can reset for reuse")
	_check(item.visible, label + " becomes visible after reset")
	_check(collision != null and not collision.disabled, label + " restores collision after reset")

	item.queue_free()
	await process_frame


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	if failures.is_empty():
		print("Collectible billboard item verification passed.")
		quit(0)
	else:
		print(
			"Collectible billboard item verification failed: "
			+ ", ".join(failures)
		)
		quit(1)
