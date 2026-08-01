extends SceneTree

const AUTH_SCENE := preload("res://addons/game_on/auth_panel.tscn")
const MAIN_MENU_SCENE_PATH := "res://game/ui/menus/main_menu.tscn"
const REWARD_SCENE := preload(
	"res://game/ui/artifact/artifact_discovery_popup.tscn"
)

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var auth_panel := AUTH_SCENE.instantiate() as AuthPanel
	root.add_child(auth_panel)
	await process_frame
	_check(
		Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,
		"Opening GameOn authentication restores the cursor",
	)

	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	auth_panel._update_ui_for_status("pending")
	_check(
		Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,
		"A pending GameOn status keeps the cursor visible",
	)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	auth_panel._update_ui_for_status("authorized")
	_check(
		Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,
		"Successful GameOn authorization restores the cursor",
	)
	auth_panel.queue_free()
	await process_frame

	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	var menu_scene := load(MAIN_MENU_SCENE_PATH) as PackedScene
	var menu := menu_scene.instantiate()
	root.add_child(menu)
	await process_frame
	_check(
		Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,
		"Returning to the Main Menu keeps the cursor visible",
	)
	menu.queue_free()
	await process_frame

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var reward_popup := REWARD_SCENE.instantiate() as ArtifactDiscoveryPopup
	root.add_child(reward_popup)
	await process_frame
	_check(
		Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,
		"The in-game GameOn reward reconnect keeps the cursor visible",
	)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	reward_popup.show_error("Reconnect required.", true)
	_check(
		Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,
		"A GameOn reconnect error restores the cursor",
	)
	reward_popup.queue_free()
	await process_frame
	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if failures.is_empty():
		print("GameOn cursor-restoration verification passed.")
		quit(0)
	else:
		print("GameOn cursor-restoration verification failed: " + ", ".join(failures))
		quit(1)
