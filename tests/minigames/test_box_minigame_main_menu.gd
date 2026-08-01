extends SceneTree

const MINIGAME_SESSION_SCRIPT := preload("res://features/minigames/shared/scripts/minigame_session.gd")
const BOX_SCENE := preload(
	"res://features/minigames/box_unboxing/scenes/box_unboxing.tscn"
)

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Node.new()
	world.name = "TestWorld"
	root.add_child(world)
	current_scene = world

	var hud := (load("res://game/ui/hud/game_hud.tscn") as PackedScene).instantiate()
	world.add_child(hud)
	await process_frame

	var session: CanvasLayer = MINIGAME_SESSION_SCRIPT.new()
	session.name = "BoxMinigameSession"
	root.add_child(session)
	session.start(BOX_SCENE)
	await process_frame
	await process_frame

	var pause_event := InputEventAction.new()
	pause_event.action = &"pause"
	pause_event.pressed = true
	session._input(pause_event)
	_check(paused, "Escape keeps the instruction overlay paused")
	_check(hud.pause_menu.visible, "The pause menu is visible over box instructions")

	hud.get_node("PauseMenu/MenuPanel/MenuStack/MainMenuButton").pressed.emit()
	for frame in range(4):
		await process_frame

	_check(not paused, "Main Menu clears the paused tree state")
	_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Main Menu leaves the cursor visible")
	_check(
		get_nodes_in_group("minigame_session").is_empty(),
		"The box session is removed instead of surviving over the menu",
	)
	_check(
		current_scene != null and current_scene.scene_file_path == "res://game/ui/menus/main_menu.tscn",
		"Main Menu exits the box minigame and changes scenes",
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
		print("Box minigame Main Menu verification passed.")
		quit(0)
	else:
		print("Box minigame Main Menu verification failed: " + ", ".join(failures))
		quit(1)
