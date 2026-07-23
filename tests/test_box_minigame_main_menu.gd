extends SceneTree

const MINIGAME_SESSION_SCRIPT := preload("res://scripts/minigame_session.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Node.new()
	world.name = "TestWorld"
	root.add_child(world)
	current_scene = world

	var hud := (load("res://ui/game_hud.tscn") as PackedScene).instantiate()
	world.add_child(hud)
	await process_frame

	var session: CanvasLayer = MINIGAME_SESSION_SCRIPT.new()
	session.name = "BoxMinigameSession"
	root.add_child(session)
	session.start(
		load("res://ui/vendor_minigame_placeholder.tscn"),
		{
			"title": "Open the Keepsake Box",
			"instructions": "Unpack the box and examine the damaged newspaper inside.",
			"reward": "Damaged newspaper clue",
		}
	)
	await process_frame
	await process_frame

	var pause_event := InputEventAction.new()
	pause_event.action = &"pause"
	pause_event.pressed = true
	session._input(pause_event)
	_check(paused, "Escape pauses the box placeholder")
	_check(hud.pause_menu.visible, "The pause menu is visible over the box placeholder")

	hud.get_node("PauseMenu/MenuPanel/MenuStack/MainMenuButton").pressed.emit()
	for frame in range(4):
		await process_frame

	_check(not paused, "Main Menu clears the paused tree state")
	_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Main Menu leaves the cursor visible")
	_check(
		get_nodes_in_group("minigame_session").is_empty(),
		"The placeholder session is removed instead of surviving over the menu",
	)
	_check(
		current_scene != null and current_scene.scene_file_path == "res://menus/main_menu.tscn",
		"Main Menu exits the placeholder and changes scenes",
	)

	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	paused = false
	if failures.is_empty():
		print("Box placeholder Main Menu verification passed.")
		quit(0)
	else:
		print("Box placeholder Main Menu verification failed: " + ", ".join(failures))
		quit(1)
