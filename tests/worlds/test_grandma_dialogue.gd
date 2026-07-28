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

	var grandma_scene := load("res://game/characters/npcs/grandma/npc_grandma.tscn") as PackedScene
	_check(grandma_scene != null, "Grandma scene loads")
	if grandma_scene == null:
		_finish()
		return

	var grandma := grandma_scene.instantiate()
	root.add_child(grandma)
	await process_frame

	_check(grandma.has_method("interact"), "Grandma is interactable")
	_check(grandma.get_interaction_text() == "Press F to talk to Grandma", "Grandma has a clear interaction prompt")
	var body_shape := grandma.get_node("CharacterBody3D/CollisionShape3D") as CollisionShape3D
	_check(body_shape.shape != null, "Grandma has physical collision")

	grandma.interact()
	await process_frame
	var dialogue := root.find_child("dialogue_ui", true, false)
	_check(dialogue != null, "Interacting opens the shared dialogue UI")
	_check(not player.can_move and player.mouse_released, "Player controls lock during dialogue")
	if dialogue:
		_check(dialogue.speaker_name.text == "You", "The player opens the conversation")
		_check(dialogue.player_thought.visible, "Player lines use the bottom thought panel")
		_check(not dialogue.npc_bubble.visible, "Player lines do not show an NPC speech bubble")
		_check(dialogue.portrait.texture.resource_path.ends_with("2main_character_asking.png"), "Player lines use the player's asking portrait")
		_check(dialogue.npc_portrait.visible, "Two-person dialogue shows the NPC portrait")
		_check(dialogue.npc_portrait.texture.resource_path.ends_with("npc_grandma_front.png"), "Grandma portrait stays on the right")
		_check(dialogue.dialogue_lines.size() == 13, "The complete two-person conversation is present")
		_check(dialogue._is_typing, "Dialogue begins with the typewriter reveal active")
		_check(dialogue._typing_audio_player.stream.resource_path.ends_with("dialogue_type_click.wav"), "Dialogue uses the subtle typing click")
		_check(dialogue._typing_audio_player.volume_db == 3.0, "Dialogue typing is mixed slightly louder")

		dialogue._on_continue_pressed()
		_check(dialogue.current_line == 0 and dialogue.dialogue_text.visible_characters == -1, "Continue first reveals the full current line")
		dialogue._on_continue_pressed()
		_check(dialogue.speaker_name.text == "Grandma", "Speaker switches to Grandma")
		_check(dialogue.npc_bubble.visible, "Grandma's line appears in the NPC speech bubble")
		_check(not dialogue.player_thought.visible, "The thought panel hides while Grandma speaks")
		_check(not dialogue.continue_btn.visible, "NPC dialogue does not ask for player input")
		_check(dialogue._line_speaker_target == grandma, "Grandma's speech bubble tracks her world node")
		_check(dialogue.portrait.modulate.a == 0.0 and dialogue.npc_portrait.modulate.a == 0.0, "Dialogue portraits are not rendered")
		_check(dialogue.portrait.texture.resource_path.ends_with("2main_character_asking.png"), "Player portrait stays on the left")
		_check(dialogue.npc_portrait.texture.resource_path.ends_with("npc_grandma_front.png"), "Grandma lines use Grandma's right-side portrait")

		var interact_event := InputEventAction.new()
		interact_event.action = "interact"
		interact_event.pressed = true
		dialogue._unhandled_input(interact_event)
		_check(
			dialogue.current_line == 1
				and not dialogue._is_typing
				and dialogue.dialogue_text.visible_characters == -1,
			"F reveals the rest of a typing NPC line",
		)
		dialogue._unhandled_input(interact_event)
		_check(
			dialogue.current_line == 2 and dialogue.player_thought.visible,
			"A second F skips the completed NPC line",
		)

		for line_index in range(2, dialogue.dialogue_lines.size()):
			dialogue._complete_typewriter()
			dialogue._on_continue_pressed()
		await process_frame

	_check(player.can_move and player.mouse_captured, "Player controls restore after dialogue")
	_check(game_state.clues.has("Grandma remembers soft noodles, tender meat, a salty taste, and a crisp topping."), "Grandma's four-part testimony is recorded as a clue")
	_check(game_state.current_objective == "Ask the people of La Paz about Grandma's memories.", "Objective advances after Grandma's testimony")
	_check(game_state.is_destination_completed("grandma_house"), "Talking to Grandma completes her destination")
	_check(game_state.is_destination_unlocked("market_vendor_1"), "Grandma unlocks the first market vendor")
	_check(game_state.active_destination == "market_vendor_1", "The first market vendor becomes the active destination")

	var camera := Camera3D.new()
	root.add_child(camera)
	var grandma_sprite := grandma.get_node("CharacterBody3D/Sprite3D") as Sprite3D
	camera.global_position = grandma_sprite.global_position + Vector3(0.0, 1.0, 10.0)
	camera.look_at(grandma_sprite.global_position + Vector3.UP)
	camera.current = true
	var automatic_dialogue := (load("res://game/ui/dialogue/dialogue_ui.tscn") as PackedScene).instantiate()
	root.add_child(automatic_dialogue)
	automatic_dialogue.type_character_delay = 0.005
	automatic_dialogue.npc_auto_advance_base_delay = 0.02
	automatic_dialogue.npc_auto_advance_seconds_per_character = 0.0
	automatic_dialogue.npc_auto_advance_max_delay = 0.02
	automatic_dialogue.start_conversation([
		{"speaker": "Grandma", "text": "Apo.", "portrait": null},
		{"speaker": "You", "text": "I heard you.", "portrait": null},
	], grandma)
	await process_frame
	var sprite_center_screen := camera.unproject_position(grandma_sprite.global_position)
	var bubble_bottom: float = float(
		automatic_dialogue.npc_bubble.position.y + automatic_dialogue.npc_bubble.size.y
	)
	_check(bubble_bottom < sprite_center_screen.y, "NPC bubble is placed above the character sprite")
	await create_timer(0.12).timeout
	_check(
		automatic_dialogue.current_line == 1 and automatic_dialogue.player_thought.visible,
		"NPC dialogue advances automatically to the next player thought",
	)
	automatic_dialogue.queue_free()
	camera.queue_free()

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
