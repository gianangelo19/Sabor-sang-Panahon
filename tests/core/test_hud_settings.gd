extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var settings := root.get_node("SettingsManager")
	var game_state := root.get_node("GameState")
	var original_hud_visible: bool = settings.is_hud_visible()
	var original_tutorial_step: int = game_state.tutorial_step
	var original_autosave: bool = game_state.autosave_enabled
	game_state.autosave_enabled = false
	game_state.set_tutorial_step(5)
	settings.set_hud_visible(true)

	var hud_scene := load("res://game/ui/hud/game_hud.tscn") as PackedScene
	var hud := hud_scene.instantiate()
	root.add_child(hud)
	var controller_scene := load(
		"res://addons/proto_controller/proto_controller.tscn"
	) as PackedScene
	var controller := controller_scene.instantiate()
	root.add_child(controller)
	await process_frame

	_check(settings.is_hud_visible(), "HUD visibility defaults to the enabled state")
	_check(hud.hud_root.visible, "The gameplay HUD starts visible when enabled")
	_check(hud.navigation_beacon.visible, "The navigation beacon follows the HUD setting")
	_check(hud.inventory_ui.hotbar_panel.visible, "The quick-access hotbar follows the HUD setting")

	settings.show_settings_menu(root)
	await process_frame
	var settings_window: Window = null
	for child in root.get_children():
		if child is Window and child.title == "Settings":
			settings_window = child
			break
	_check(settings_window != null, "Settings window opens for the HUD option")
	if settings_window:
		var hud_toggles := settings_window.find_children(
			"HUDVisibilityToggle",
			"CheckButton",
			true,
			false,
		)
		_check(hud_toggles.size() == 1, "Settings exposes one Show Gameplay HUD toggle")
		if not hud_toggles.is_empty():
			_check(
				(hud_toggles[0] as CheckButton).button_pressed,
				"The HUD toggle reflects the saved enabled state",
			)
		var close_button: Button = null
		for button in settings_window.find_children("*", "Button", true, false):
			if button.text == "Close":
				close_button = button as Button
				break
		var content_height: float = (
			close_button.get_parent().get_combined_minimum_size().y
			if close_button != null
			else 9999.0
		)
		_check(
			content_height <= 588.0,
			"The HUD option keeps the Settings close action inside the window",
		)
		settings_window.queue_free()

	controller.interact_prompt.visible = true
	settings.set_hud_visible(false)
	await process_frame
	_check(not settings.is_hud_visible(), "Disabling the HUD is saved immediately")
	_check(not hud.hud_root.visible, "Disabling the HUD hides gameplay panels and prompts")
	_check(not hud.navigation_beacon.visible, "Disabling the HUD hides navigation guidance")
	_check(not hud.inventory_ui.hotbar_panel.visible, "Disabling the HUD hides the hotbar")
	_check(not hud.inventory_ui.held_root.visible, "Disabling the HUD hides the held-item display")
	_check(not controller.interact_prompt.visible, "Disabling the HUD hides interaction prompts")

	hud.phone_ui._on_notification_received({}, false)
	_check(
		not hud.phone_ui.notification_banner.visible,
		"HUD-disabled notifications remain available without showing a banner",
	)
	hud.phone_ui.open_phone()
	_check(hud.phone_ui.phone_frame.visible, "The phone remains usable while the HUD is disabled")
	hud.phone_ui.close_phone()
	hud.toggle_pause()
	_check(hud.pause_menu.visible, "The pause menu remains usable while the HUD is disabled")
	hud.close_pause()

	settings.set_hud_visible(true)
	await process_frame
	_check(hud.hud_root.visible, "Re-enabling the HUD restores gameplay panels immediately")
	_check(hud.inventory_ui.hotbar_panel.visible, "Re-enabling the HUD restores the hotbar immediately")

	settings.set_hud_visible(original_hud_visible)
	game_state.set_tutorial_step(original_tutorial_step)
	game_state.autosave_enabled = original_autosave
	controller.queue_free()
	hud.queue_free()
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
		print("HUD settings verification passed.")
		quit(0)
	else:
		print("HUD settings verification failed: " + ", ".join(failures))
		quit(1)
