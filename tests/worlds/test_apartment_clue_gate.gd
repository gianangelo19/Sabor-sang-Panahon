extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	var original_autosave: bool = game_state.autosave_enabled
	game_state.autosave_enabled = false
	game_state.reset()

	var apartment := (load("res://game/worlds/la_paz/apartment/apartment.tscn") as PackedScene).instantiate()
	root.add_child(apartment)
	var hud := (load("res://game/ui/hud/game_hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame

	var door := apartment.get_node("ApartmentDoor")
	var box := apartment.get_node("box_minigame")
	var fridge := apartment.get_node("FridgeInteractable")
	var objective_panel := hud.get_node("HUDRoot/TopLeftPanel") as PanelContainer
	var phone := hud.get_node("PhoneUI")

	_check(not objective_panel.visible, "Objective HUD is hidden before the newspaper is found")
	_check(box is StaticBody3D and box.has_method("interact"), "The table box is the newspaper minigame interactable")
	_check(box.get_node_or_null("CollisionShape3D") != null, "The table box has a raycast collision shape")
	_check(door._is_story_locked(), "Apartment door is locked before the first clue")
	_check(door.get_interaction_text() == "Press F to check the fridge and open the box first", "Locked door points the player toward the fridge and box")
	door.interact()
	await process_frame
	_check(not door._is_open, "Trying the locked door cannot open it")
	var locked_dialogue := root.find_child("dialogue_ui", true, false)
	_check(locked_dialogue != null, "Trying the locked door opens player dialogue")
	if locked_dialogue != null:
		_check(
			locked_dialogue.dialogue_lines[0].text == door.locked_message,
			"Locked-door dialogue tells the player to check the fridge and open the box"
		)
		locked_dialogue._cancel_typewriter()
		locked_dialogue.current_line = locked_dialogue.dialogue_lines.size()
		locked_dialogue.show_current_line()
		await process_frame
	_check(not door._locked_dialogue_active, "Finishing locked-door dialogue allows future interactions")

	_check(fridge.has_method("interact"), "The apartment fridge is interactable")
	_check(box.get_interaction_text().is_empty(), "The package has no prompt before the fridge dialogue")
	_check(box.should_hide_interaction_prompt(), "The package interaction is disabled before the fridge dialogue")
	box.interact()
	await process_frame
	_check(
		root.find_child("BoxMinigameSession", true, false) == null,
		"The disabled package cannot launch before the fridge dialogue",
	)
	fridge.interact()
	await process_frame
	var fridge_dialogue := root.find_child("dialogue_ui", true, false)
	_check(fridge_dialogue != null, "Checking the fridge opens Scene 2 dialogue")
	if fridge_dialogue != null:
		_check(fridge_dialogue.dialogue_lines.size() == 4, "The fridge carries the full V3 food-search exchange")
		await _finish_dialogue(fridge_dialogue)
	_check(game_state.has_story_flag("apartment_fridge_checked"), "Finishing the fridge dialogue unlocks the package")
	_check(
		not game_state.has_ambot_notification()
		and not phone.notification_banner.visible,
		"The new box objective does not create an empty AMBot notification",
	)

	box.interact()
	await process_frame
	var session := root.find_child("BoxMinigameSession", true, false)
	var minigame: Node = session.get_minigame() if session != null else null
	_check(
		minigame != null and minigame.name == "BoxUnboxing",
		"Interacting with the table box launches Box Unboxing",
	)
	_check(game_state.time_of_day_stage == 0, "The apartment box does not advance story time")
	_check(not game_state.clues.has("Damaged newspaper"), "Starting Box Unboxing does not award the clue early")
	if minigame != null:
		minigame.minigame_finished.emit()
	await process_frame
	_check(game_state.clues.has("Damaged newspaper"), "Completing Box Unboxing records the newspaper clue")
	_check(box.get_interaction_text().is_empty(), "The opened package no longer advertises another interaction")
	_check(box.should_hide_interaction_prompt(), "The opened package keeps its interaction prompt hidden")
	_check(
		root.find_child("dialogue_ui", true, false) == null,
		"The box does not repeat dialogue owned by the eventual keepsake minigame",
	)
	_check(game_state.current_objective == "Ride the jeepney to La Paz.", "The newspaper supplies the first visible objective")
	_check(not objective_panel.visible, "The old standalone objective panel stays hidden")
	_check(
		phone.notification_banner.visible
		and phone.notification_banner.text == "You have a new notification!",
		"The authored AMBot update displays one generic notification",
	)
	_check(not door._is_story_locked(), "Finding the newspaper unlocks the apartment door")
	_check(door.get_interaction_text() == "Press F to open apartment door", "Unlocked door restores its normal prompt")
	door.interact()
	_check(door._is_open, "The apartment door opens after the first clue")

	hud.queue_free()
	apartment.queue_free()
	game_state.reset()
	game_state.autosave_enabled = original_autosave
	await process_frame
	_finish()


func _finish_dialogue(dialogue: Node) -> void:
	while is_instance_valid(dialogue) and dialogue.is_inside_tree():
		dialogue._complete_typewriter()
		dialogue._on_continue_pressed()
		await process_frame


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
