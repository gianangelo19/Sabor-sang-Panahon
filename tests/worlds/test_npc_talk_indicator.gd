extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.reset()

	var player := Node3D.new()
	player.name = "ProtoController"
	root.add_child(player)

	var ambient_scene := load(
		"res://game/characters/npcs/citizens/npc_man.tscn"
	) as PackedScene
	var ambient_npc := ambient_scene.instantiate() as Node3D
	ambient_npc.position = Vector3(0, 0, -8)
	root.add_child(ambient_npc)
	await process_frame
	await process_frame

	var indicator := ambient_npc.get_node_or_null("TalkIndicator") as Node3D
	_check(indicator != null, "Conversational NPCs receive the shared talk indicator")
	if indicator != null:
		var bubble := indicator.get_node("Bubble") as Sprite3D
		var sound := indicator.get_node("AppearanceSound") as AudioStreamPlayer3D
		_check(not bubble.visible, "The talk bubble stays hidden outside close proximity")
		_check(
			bubble.texture != null
			and bubble.texture.resource_path.ends_with("npc_talk_bubble.svg"),
			"The indicator uses the ellipsis speech-bubble icon",
		)
		_check(
			sound.stream != null
			and sound.volume_db <= -18.0,
			"The indicator has a subtle spatial appearance sound",
		)

		ambient_npc.position = Vector3(0, 0, -4)
		await process_frame
		_check(bubble.visible, "The talk bubble appears when the player is nearby")
		_check(sound.playing, "Approaching the NPC plays the bubble appearance sound")

		ambient_npc._dialogue_active = true
		await process_frame
		_check(not bubble.visible, "The talk bubble hides while dialogue is active")

		ambient_npc._dialogue_active = false
		ambient_npc.position = Vector3(0, 0, -6)
		await process_frame
		_check(not bubble.visible, "The talk bubble hides after leaving its proximity range")

	var vendor_scene := load(
		"res://game/characters/npcs/vendors/npc_market_vendor.tscn"
	) as PackedScene
	var vendor := vendor_scene.instantiate() as Node3D
	vendor.position = Vector3(0, 0, -4)
	root.add_child(vendor)
	await process_frame
	await process_frame
	var vendor_indicator := vendor.get_node_or_null("TalkIndicator") as Node3D
	_check(vendor_indicator != null, "Story NPCs receive the shared talk indicator")
	if vendor_indicator != null:
		var vendor_bubble := vendor_indicator.get_node("Bubble") as Sprite3D
		_check(not vendor_bubble.visible, "Locked story NPCs do not advertise unavailable dialogue")
		game_state.unlock_destination("market_vendor_1")
		await process_frame
		_check(vendor_bubble.visible, "Unlocked story NPCs advertise available dialogue")

	ambient_npc.queue_free()
	vendor.queue_free()
	player.queue_free()
	await process_frame
	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	if failures.is_empty():
		print("NPC talk indicator verification passed.")
		quit(0)
	else:
		print("NPC talk indicator verification failed: " + ", ".join(failures))
		quit(1)
