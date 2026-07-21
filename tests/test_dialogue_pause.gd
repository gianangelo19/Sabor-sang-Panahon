extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var hud := (load("res://ui/game_hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame

	var dialogue := (load("res://dialogue_ui.tscn") as PackedScene).instantiate()
	root.add_child(dialogue)
	dialogue.start_conversation([
		{
			"speaker": "You",
			"text": "This deliberately long dialogue line should stop revealing while paused.",
			"portrait": null,
		},
	])
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await process_frame

	var visible_before_pause: int = dialogue.dialogue_text.visible_characters
	hud.toggle_pause()
	_check(paused, "Escape pauses an active dialogue")
	_check(hud.pause_menu.visible, "The pause menu appears above dialogue")
	_check(hud.layer > dialogue.canvas.layer, "The pause overlay renders above the dialogue canvas")
	_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "The cursor remains visible on the dialogue pause menu")

	# This test timer intentionally runs while paused; the dialogue timer must not.
	await create_timer(0.12, true).timeout
	_check(
		dialogue.dialogue_text.visible_characters == visible_before_pause,
		"Dialogue typewriter progression freezes while paused",
	)

	hud.toggle_pause()
	_check(not paused, "Escape resumes the paused dialogue")
	_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Resuming dialogue restores its visible cursor")
	await create_timer(0.08).timeout
	_check(
		dialogue.dialogue_text.visible_characters > visible_before_pause,
		"Dialogue typewriter progression continues after resuming",
	)

	dialogue.queue_free()
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
	paused = false
	if failures.is_empty():
		print("Dialogue pause verification passed.")
		quit(0)
	else:
		print("Dialogue pause verification failed: " + ", ".join(failures))
		quit(1)
