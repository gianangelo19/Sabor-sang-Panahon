extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.reset()
	var hud_scene := load("res://ui/game_hud.tscn") as PackedScene
	_check(hud_scene != null, "HUD scene loads")
	if hud_scene == null:
		_finish()
		return

	var hud := hud_scene.instantiate()
	root.add_child(hud)
	await process_frame
	_check(hud.hint_text.text == "Press WASD to move", "Movement instruction appears first")
	_check(hud.ingredient_label.text == "0/4 collected", "HUD uses the four-ingredient story total")
	hud._on_ingredients_changed(4, 4)
	_check(hud.ingredient_label.text == "4/4 collected", "HUD clearly marks all four ingredients collected")
	var ingredient_title := hud.ingredient_label.get_node("../IngredientTitle") as Label
	_check(ingredient_title.text == "Ingredients complete", "HUD highlights the completed ingredient set")
	hud._on_ingredients_changed(0, 4)

	await _send_action(hud, "move_forward")
	_check(game_state.tutorial_step == 1, "Movement advances the tutorial")
	_check(hud.hint_text.text == "Move the mouse to look around", "Look instruction appears second")

	var mouse_event := InputEventMouseMotion.new()
	mouse_event.relative = Vector2(4, 0)
	hud._input(mouse_event)
	await create_timer(0.4).timeout
	_check(game_state.tutorial_step == 2, "Mouse movement advances the tutorial")
	_check(hud.hint_text.text == "Press E to interact", "Interaction instruction appears third")

	await _send_action(hud, "interact")
	_check(hud.hint_text.text == "Press P to open your phone", "Phone-open instruction follows interaction")
	await _send_action(hud, "phone")
	_check(hud.hint_text.text == "Press P again to put your phone away", "Phone-close instruction follows opening")
	await _send_action(hud, "phone")
	_check(hud.hint_text.text == "Press Esc to pause", "Pause instruction appears last")
	await _send_action(hud, "pause")
	_check(game_state.tutorial_step == hud.TUTORIAL_PROMPTS.size(), "All tutorial steps complete")
	_check(not hud.hint_bar.visible, "Instruction bar disappears after completion")

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
