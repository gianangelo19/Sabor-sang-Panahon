extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_key("crank", KEY_SPACE, "Crank accepts Space")
	_check_mouse("crank", MOUSE_BUTTON_LEFT, "Crank accepts left mouse")
	_check_key("guinamos_left", KEY_A, "Guinamos left accepts A")
	_check_key("guinamos_left", KEY_LEFT, "Guinamos left accepts Left Arrow")
	_check_key("guinamos_right", KEY_D, "Guinamos right accepts D")
	_check_key("guinamos_right", KEY_RIGHT, "Guinamos right accepts Right Arrow")
	_check_key("guinamos_confirm", KEY_SPACE, "Guinamos confirm accepts Space")

	if failures.is_empty():
		print("Minigame input-map verification passed.")
		quit(0)
	else:
		print("Minigame input-map verification failed: " + ", ".join(failures))
		quit(1)


func _check_key(action: StringName, key: Key, label: String) -> void:
	var found := false
	if InputMap.has_action(action):
		for event in InputMap.action_get_events(action):
			if event is InputEventKey and event.physical_keycode == key:
				found = true
				break
	_check(found, label)


func _check_mouse(action: StringName, button: MouseButton, label: String) -> void:
	var found := false
	if InputMap.has_action(action):
		for event in InputMap.action_get_events(action):
			if event is InputEventMouseButton and event.button_index == button:
				found = true
				break
	_check(found, label)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)
