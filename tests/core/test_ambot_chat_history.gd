extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	var original_save_path: String = game_state.save_file_path
	var original_autosave: bool = game_state.autosave_enabled
	var test_save_path := "user://codex_ambot_history_test_save.json"
	var absolute_save_path := ProjectSettings.globalize_path(test_save_path)

	game_state.save_file_path = test_save_path
	game_state.autosave_enabled = false
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(absolute_save_path)
	game_state.reset()

	game_state.append_ambot_chat_message(
		"You",
		"What should I do now?",
		true,
		"casual",
		"question_1",
	)
	game_state.append_ambot_chat_message(
		"AMBot",
		"Continue your current objective.",
		false,
		"casual",
		"answer_1",
	)
	game_state.record_ambot_question("casual", 1)

	_check(game_state.ambot_chat_history.size() == 2, "AMBot messages append to history")
	_check(
		game_state.has_ambot_chat_entry("casual", "question_1"),
		"AMBot history can identify existing message kinds",
	)
	_check(
		game_state.get_ambot_asked_questions("casual") == [1],
		"AMBot records answered-question state",
	)
	_check(
		game_state.save_game("res://game/worlds/la_paz/la_paz.tscn"),
		"AMBot history can be written to the game save",
	)

	game_state.reset()
	_check(not game_state.load_game().is_empty(), "AMBot history save can be loaded")
	game_state.autosave_enabled = false
	_check(
		game_state.ambot_chat_history.size() == 2,
		"Save data restores AMBot chat history",
	)
	_check(
		game_state.get_ambot_asked_questions("casual") == [1],
		"Save data restores AMBot answered-question state",
	)

	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(absolute_save_path)
	game_state.reset()
	game_state.save_file_path = original_save_path
	game_state.autosave_enabled = original_autosave
	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	if failures.is_empty():
		print("AMBot chat history verification passed.")
		quit(0)
	else:
		print("AMBot chat history verification failed: " + ", ".join(failures))
		quit(1)
