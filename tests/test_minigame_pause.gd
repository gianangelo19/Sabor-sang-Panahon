extends SceneTree

const MINIGAME_SESSION_SCRIPT := preload("res://scripts/minigame_session.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var hud_scene := load("res://ui/game_hud.tscn") as PackedScene
	var hud := hud_scene.instantiate()
	root.add_child(hud)
	await process_frame

	var dummy_root := Node2D.new()
	dummy_root.name = "DummyMinigame"
	var always_processing_child := Node.new()
	always_processing_child.name = "AlwaysProcessingChild"
	always_processing_child.process_mode = Node.PROCESS_MODE_ALWAYS
	dummy_root.add_child(always_processing_child)
	always_processing_child.owner = dummy_root
	var dummy_scene := PackedScene.new()
	_check(dummy_scene.pack(dummy_root) == OK, "A test minigame can be packed")
	dummy_root.free()

	var session: CanvasLayer = MINIGAME_SESSION_SCRIPT.new()
	session.name = "TestMinigameSession"
	root.add_child(session)
	session.start(dummy_scene)
	_check(session.process_mode == Node.PROCESS_MODE_ALWAYS, "The shared session can receive Escape while paused")
	_check(session.get_minigame().process_mode == Node.PROCESS_MODE_PAUSABLE, "Minigame gameplay obeys the global pause state")
	_check(
		session.get_minigame().get_node("AlwaysProcessingChild").process_mode == Node.PROCESS_MODE_PAUSABLE,
		"Explicit always-processing minigame children are frozen by pause",
	)

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var pause_event := InputEventAction.new()
	pause_event.action = &"pause"
	pause_event.pressed = true
	session._input(pause_event)
	_check(paused, "Escape pauses an active minigame")
	_check(hud.pause_menu.visible, "The pause menu appears during a minigame")
	_check(hud.layer >= 500, "The pause menu renders above all minigame overlays")
	_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "The cursor remains visible on the minigame pause menu")

	hud._on_settings_button_pressed()
	var settings_window: Window = null
	for child in root.find_children("*", "Window", true, false):
		if child is Window and child.title == "Settings":
			settings_window = child
			break
	_check(settings_window != null, "Settings opens from the minigame pause menu")
	if settings_window:
		_check(settings_window.process_mode == Node.PROCESS_MODE_ALWAYS, "Minigame settings remains interactive while paused")
		settings_window.queue_free()

	session._input(pause_event)
	_check(not paused, "Escape resumes the paused minigame")
	_check(not hud.pause_menu.visible, "The minigame pause overlay closes on resume")
	_check(hud.layer < 500, "The HUD returns to its normal layer after resuming")
	_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Resuming a minigame restores its visible cursor")

	session.queue_free()
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
		print("Minigame pause verification passed.")
		quit(0)
	else:
		print("Minigame pause verification failed: " + ", ".join(failures))
		quit(1)
