extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	var original_save_path: String = game_state.save_file_path
	var original_autosave: bool = game_state.autosave_enabled
	var test_save_path := "user://codex_menu_test_save.json"
	game_state.save_file_path = test_save_path
	game_state.autosave_enabled = false
	_remove_test_save(test_save_path)
	_check(ProjectSettings.get_setting("application/run/main_scene") == "res://menus/main_menu.tscn", "Project starts at the Main Menu")

	var menu_scene := load("res://menus/main_menu.tscn") as PackedScene
	var no_save_menu := menu_scene.instantiate()
	root.add_child(no_save_menu)
	await process_frame
	var no_save_buttons := _visible_button_texts(no_save_menu.get_node("CenterPanel/MenuStack"))
	_check(no_save_buttons == ["New Game", "Settings", "Quit"], "Main Menu hides Continue when no save exists")
	no_save_menu.queue_free()
	await process_frame

	game_state.start_new_game("res://la_paz.tscn")
	_check(game_state.consume_wake_up_intro(), "New Game requests the wake-up intro")
	_check(not game_state.consume_wake_up_intro(), "Wake-up intro request can only be consumed once")
	game_state.set_objective("Test saved objective")
	game_state.collect_ingredient("test_ingredient", "Test Ingredient")
	game_state.unlock_destination("grandma_house")
	game_state.select_destination("grandma_house")
	_check(game_state.save_game("res://la_paz.tscn"), "Game state saves successfully")
	_check(game_state.has_save_game(), "Saved game is detected")

	game_state.reset()
	var loaded_scene: String = game_state.load_game()
	_check(loaded_scene == "res://la_paz.tscn", "Continue restores the saved scene")
	_check(game_state.current_objective == "Test saved objective", "Continue restores the objective")
	_check(game_state.has_ingredient("test_ingredient"), "Continue restores collected ingredients")
	_check(game_state.active_destination == "grandma_house", "Continue restores the active beacon")

	var menu := menu_scene.instantiate()
	root.add_child(menu)
	await process_frame
	var menu_buttons := _visible_button_texts(menu.get_node("CenterPanel/MenuStack"))
	_check(menu_buttons == ["New Game", "Continue", "Settings", "Quit"], "Main Menu has the required four actions")
	_check(not menu.continue_button.disabled, "Continue is enabled when a save exists")
	game_state.request_wake_up_intro()
	game_state.load_game()
	_check(not game_state.consume_wake_up_intro(), "Continue clears any stale wake-up request")
	var skipped_wake_up := _create_wake_up_effect()
	root.add_child(skipped_wake_up)
	await process_frame
	await process_frame
	_check(not is_instance_valid(skipped_wake_up), "Continue removes the wake-up effect before it can display")

	game_state.request_wake_up_intro()
	var new_game_wake_up := _create_wake_up_effect()
	root.add_child(new_game_wake_up)
	await process_frame
	_check(is_instance_valid(new_game_wake_up) and not new_game_wake_up.is_queued_for_deletion(), "New Game starts the wake-up sequence")
	new_game_wake_up.queue_free()
	await process_frame

	var hud_scene := load("res://ui/game_hud.tscn") as PackedScene
	var hud := hud_scene.instantiate()
	root.add_child(hud)
	await process_frame
	var pause_buttons := _button_texts(hud.get_node("PauseMenu/MenuPanel/MenuStack"))
	_check(pause_buttons == ["Resume", "Main Menu", "Settings", "Quit"], "Pause menu has only the required four actions")

	var controller_scene := load("res://addons/proto_controller/proto_controller.tscn") as PackedScene
	var controller := controller_scene.instantiate()
	root.add_child(controller)
	await process_frame
	controller.interact_prompt.visible = true
	controller.can_move = false
	controller.update_interaction_prompt()
	_check(not controller.interact_prompt.visible, "Interaction prompt hides while dialogue locks the player")

	var settings_manager := root.get_node("SettingsManager")
	settings_manager.show_settings_menu(root)
	await process_frame
	var settings_window: Window = null
	for child in root.get_children():
		if child is Window and child.title == "Settings":
			settings_window = child
			break
	_check(settings_window != null, "Settings window opens")
	if settings_window:
		_check(settings_window.process_mode == Node.PROCESS_MODE_ALWAYS, "Settings remains interactive while paused")
		settings_window.queue_free()

	controller.queue_free()
	hud.queue_free()
	menu.queue_free()
	game_state.autosave_enabled = false
	_remove_test_save(test_save_path)
	game_state.save_file_path = original_save_path
	game_state.autosave_enabled = original_autosave
	_finish()


func _button_texts(container: Node) -> Array[String]:
	var result: Array[String] = []
	for child in container.get_children():
		if child is Button:
			result.append(child.text)
	return result


func _visible_button_texts(container: Node) -> Array[String]:
	var result: Array[String] = []
	for child in container.get_children():
		if child is Button and child.visible:
			result.append(child.text)
	return result


func _create_wake_up_effect() -> CanvasLayer:
	var effect := CanvasLayer.new()
	effect.name = "WakeUpEffect"
	var top := ColorRect.new()
	top.name = "TopEyelid"
	effect.add_child(top)
	var bottom := ColorRect.new()
	bottom.name = "BottomEyelid"
	effect.add_child(bottom)
	effect.set_script(load("res://scripts/wake_up.gd"))
	return effect


func _remove_test_save(path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute_path)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	if failures.is_empty():
		print("Menu and save verification passed.")
		quit(0)
	else:
		print("Menu and save verification failed: " + ", ".join(failures))
		quit(1)
