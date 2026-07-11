extends SceneTree

class MockPlayer extends Node:
	var can_move := true
	var mouse_released := false
	var mouse_captured := false

	func release_mouse() -> void:
		mouse_released = true

	func capture_mouse() -> void:
		mouse_captured = true


var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.reset()
	game_state.unlock_destination("grandma_house")
	game_state.select_destination("grandma_house")

	var player := MockPlayer.new()
	player.name = "ProtoController"
	root.add_child(player)

	var grandma_scene := load("res://npc_grandma.tscn") as PackedScene
	_check(grandma_scene != null, "Grandma scene loads")
	if grandma_scene == null:
		_finish()
		return

	var grandma := grandma_scene.instantiate()
	root.add_child(grandma)
	await process_frame

	_check(grandma.has_method("interact"), "Grandma is interactable")
	_check(grandma.get_interaction_text() == "Press E to talk to Grandma", "Grandma has a clear interaction prompt")
	var body_shape := grandma.get_node("CharacterBody3D/CollisionShape3D") as CollisionShape3D
	_check(body_shape.shape != null, "Grandma has physical collision")

	grandma.interact()
	await process_frame
	var dialogue := root.find_child("dialogue_ui", true, false)
	_check(dialogue != null, "Interacting opens the shared dialogue UI")
	_check(not player.can_move and player.mouse_released, "Player controls lock during dialogue")
	if dialogue:
		_check(dialogue.speaker_name.text == "You", "The player opens the conversation")
		_check(dialogue.portrait.texture.resource_path.ends_with("2main_character_asking.png"), "Player lines use the player's asking portrait")
		_check(dialogue.npc_portrait.visible, "Two-person dialogue shows the NPC portrait")
		_check(dialogue.npc_portrait.texture.resource_path.ends_with("npc_grandma_front.png"), "Grandma portrait stays on the right")
		_check(dialogue.dialogue_lines.size() == 13, "The complete two-person conversation is present")

		dialogue._on_continue_pressed()
		_check(dialogue.speaker_name.text == "Grandma", "Speaker switches to Grandma")
		_check(dialogue.portrait.texture.resource_path.ends_with("2main_character_asking.png"), "Player portrait stays on the left")
		_check(dialogue.npc_portrait.texture.resource_path.ends_with("npc_grandma_front.png"), "Grandma lines use Grandma's right-side portrait")

		for line_index in range(1, dialogue.dialogue_lines.size()):
			dialogue._on_continue_pressed()
		await process_frame

	_check(player.can_move and player.mouse_captured, "Player controls restore after dialogue")
	_check(game_state.clues.has("Grandma remembers soft noodles, tender meat, a salty taste, and a crisp topping."), "Grandma's four-part testimony is recorded as a clue")
	_check(game_state.current_objective == "Ask the people of La Paz about Grandma's memories.", "Objective advances after Grandma's testimony")
	_check(game_state.is_destination_completed("grandma_house"), "Talking to Grandma completes her destination")
	_check(game_state.is_destination_unlocked("market_vendor_1"), "Grandma unlocks the first market vendor")
	_check(game_state.active_destination == "market_vendor_1", "The first market vendor becomes the active destination")

	game_state.set_grandma_left_for_medicine(true)
	await process_frame
	_check(not grandma.visible, "Grandma disappears after the first vendor conversation begins")
	var grandma_collision := grandma.get_node("CharacterBody3D/CollisionShape3D") as CollisionShape3D
	_check(grandma_collision.disabled, "Grandma's collision is disabled while she buys medicine")
	game_state.set_grandma_left_for_medicine(false)
	await process_frame
	_check(grandma.visible, "Grandma can return for the final dinner sequence")

	grandma.queue_free()
	player.queue_free()
	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	if failures.is_empty():
		print("Grandma dialogue verification passed.")
		quit(0)
	else:
		print("Grandma dialogue verification failed: " + ", ".join(failures))
		quit(1)
