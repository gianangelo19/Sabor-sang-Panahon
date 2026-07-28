extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.reset()
	var interact_uses_f := false
	var interact_uses_e := false
	for event: InputEvent in InputMap.action_get_events("interact"):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			interact_uses_f = (
				interact_uses_f
				or key_event.physical_keycode == KEY_F
				or key_event.keycode == KEY_F
			)
			interact_uses_e = (
				interact_uses_e
				or key_event.physical_keycode == KEY_E
				or key_event.keycode == KEY_E
			)
	_check(interact_uses_f and not interact_uses_e, "Interact action is bound to F instead of E")
	var hud_scene := load("res://game/ui/hud/game_hud.tscn") as PackedScene
	_check(hud_scene != null, "HUD scene loads")
	if hud_scene == null:
		_finish()
		return

	var hud := hud_scene.instantiate()
	root.add_child(hud)
	await process_frame
	_check(not hud.hint_bar.visible, "Tutorial waits for the wake-up dialogue")
	_check(hud.ingredient_label.text == "0/4 collected", "HUD uses the four-ingredient story total")
	hud._on_ingredients_changed(4, 4)
	_check(hud.ingredient_label.text == "4/4 collected", "HUD clearly marks all four ingredients collected")
	var ingredient_title := hud.ingredient_label.get_node("../IngredientTitle") as Label
	_check(ingredient_title.text == "Ingredients complete", "HUD highlights the completed ingredient set")
	hud._on_ingredients_changed(0, 4)

	hud.begin_apartment_tutorial()
	await create_timer(0.35).timeout
	_check(game_state.tutorial_step == hud.TUTORIAL_MOVEMENT, "Wake-up dialogue unlocks movement instruction")
	_check(hud.hint_bar.visible and is_equal_approx(hud.hint_bar.modulate.a, 1.0), "Movement instruction fades in")
	_check(hud.hint_text.text == "MOVE AROUND", "Movement instruction appears first")
	_check(hud.primary_key.texture.resource_path.ends_with("key_wasd.png"), "Movement instruction uses the combined WASD sprite")
	_check(hud.secondary_key.texture.resource_path.ends_with("key_spacebar.png"), "Movement instruction includes the Spacebar jump sprite")

	await _send_action(hud, "move_forward")
	_check(game_state.tutorial_step == hud.TUTORIAL_MOVEMENT, "Movement prompt remains until jump is also used")
	await _send_action(hud, "jump")
	_check(game_state.tutorial_step == hud.TUTORIAL_WAITING_FOR_BOX, "Movement and jump completion starts the box wait")
	_check(not hud.hint_bar.visible, "No new instruction appears before the box is seen")

	hud.notify_box_seen()
	await create_timer(0.35).timeout
	_check(game_state.tutorial_step == hud.TUTORIAL_INTERACT, "Seeing the box unlocks interaction instruction")
	_check(hud.hint_text.text == "OPEN THE BOX", "Box instruction identifies the current action")
	_check(hud.primary_key.texture.resource_path.ends_with("key_f.png"), "Box instruction uses the F sprite")

	await _send_action(hud, "interact")
	_check(game_state.tutorial_step == hud.TUTORIAL_WAITING_FOR_MINIGAME, "Interaction prompt disappears while the minigame runs")
	_check(not hud.hint_bar.visible, "Tutorial remains quiet during the box minigame")

	hud.notify_box_minigame_completed()
	await create_timer(0.35).timeout
	_check(game_state.tutorial_step == hud.TUTORIAL_PHONE, "Completing the box minigame unlocks the phone instruction")
	_check(hud.hint_text.text == "CHECK YOUR PHONE", "Phone instruction follows minigame completion")
	_check(hud.primary_key.texture.resource_path.ends_with("key_e.png"), "Phone instruction uses the E sprite")
	await _send_action(hud, "phone")
	_check(game_state.tutorial_step == hud.TUTORIAL_COMPLETE, "Opening the phone completes the tutorial")
	_check(not hud.hint_bar.visible, "Final instruction fades out after completion")

	hud.queue_free()
	await process_frame
	var replacement_hud := hud_scene.instantiate()
	root.add_child(replacement_hud)
	await process_frame
	_check(not replacement_hud.hint_bar.visible, "Completed tutorial remains hidden after a scene-style reload")
	replacement_hud.queue_free()
	_finish()

func _send_action(hud: Node, action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	hud._input(event)
	await create_timer(0.4).timeout

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)

func _finish() -> void:
	if failures.is_empty():
		print("Tutorial HUD verification passed.")
		quit(0)
	else:
		print("Tutorial HUD verification failed: " + ", ".join(failures))
		quit(1)
