extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	var original_autosave: bool = game_state.autosave_enabled
	game_state.autosave_enabled = false
	game_state.reset()

	var apartment := (load("res://apartment.tscn") as PackedScene).instantiate()
	root.add_child(apartment)
	var hud := (load("res://ui/game_hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame

	var door := apartment.get_node("ApartmentDoor")
	var box := apartment.get_node("box_minigame")
	var objective_panel := hud.get_node("HUDRoot/TopLeftPanel") as PanelContainer

	_check(not objective_panel.visible, "Objective HUD is hidden before the newspaper is found")
	_check(box is StaticBody3D and box.has_method("interact"), "The table box is the newspaper minigame interactable")
	_check(box.get_node_or_null("CollisionShape3D") != null, "The table box has a raycast collision shape")
	_check(door._is_story_locked(), "Apartment door is locked before the first clue")
	_check(door.get_interaction_text() == "Press E to open the box before leaving", "Locked door points the player toward the box")
	door.interact()
	await process_frame
	_check(not door._is_open, "Trying the locked door cannot open it")
	var locked_dialogue := root.find_child("dialogue_ui", true, false)
	_check(locked_dialogue != null, "Trying the locked door opens player dialogue")
	if locked_dialogue != null:
		_check(
			locked_dialogue.dialogue_lines[0].text == door.locked_message,
			"Locked-door dialogue tells the player to open the box"
		)
		locked_dialogue._cancel_typewriter()
		locked_dialogue.current_line = locked_dialogue.dialogue_lines.size()
		locked_dialogue.show_current_line()
		await process_frame
	_check(not door._locked_dialogue_active, "Finishing locked-door dialogue allows future interactions")

	box.interact()
	await process_frame
	var minigame := root.find_child("VendorMinigamePlaceholder", true, false)
	_check(minigame != null, "Interacting with the table box launches the temporary placeholder")
	_check(not game_state.clues.has("Damaged newspaper"), "Opening the placeholder does not award the clue early")
	if minigame != null:
		_check(minigame.title_label.text == "Open the Keepsake Box", "The box placeholder identifies the skipped challenge")
		minigame.get_node("Panel/Stack/ContinueButton").pressed.emit()
	await process_frame
	_check(game_state.clues.has("Damaged newspaper"), "Continuing past the placeholder records the newspaper clue")
	_check(game_state.current_objective == "Ride the jeepney to La Paz.", "The newspaper supplies the first visible objective")
	_check(objective_panel.visible, "Objective HUD appears when the newspaper is found")
	_check(not door._is_story_locked(), "Finding the newspaper unlocks the apartment door")
	_check(door.get_interaction_text() == "Press E to open apartment door", "Unlocked door restores its normal prompt")
	door.interact()
	_check(door._is_open, "The apartment door opens after the first clue")

	hud.queue_free()
	apartment.queue_free()
	game_state.reset()
	game_state.autosave_enabled = original_autosave
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
		print("Apartment clue-gate verification passed.")
		quit(0)
	else:
		print("Apartment clue-gate verification failed: " + ", ".join(failures))
		quit(1)
