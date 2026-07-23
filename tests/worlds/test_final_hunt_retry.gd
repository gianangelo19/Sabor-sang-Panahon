extends SceneTree

class MockPlayer extends Node:
	var can_move := true
	var mouse_released := false
	var mouse_captured := false

	func release_mouse() -> void:
		mouse_released = true

	func capture_mouse() -> void:
		mouse_captured = true


var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	var original_autosave: bool = game_state.autosave_enabled
	game_state.autosave_enabled = false
	game_state.reset()

	var player := MockPlayer.new()
	player.name = "ProtoController"
	root.add_child(player)
	var home := (load("res://game/worlds/la_paz/grandma_house/lapaz_home.tscn") as PackedScene).instantiate()
	root.add_child(home)
	await physics_frame
	await physics_frame

	var director := home.get_node("FinalArtifactHunt")
	_check(is_equal_approx(director.hunt_duration, 30.0), "The final hunt lasts 30 seconds")
	director.start_hunt(60.0)
	_check(game_state.final_hunt_active, "The final hunt starts")
	_check(is_equal_approx(game_state.final_hunt_time_remaining, 30.0), "New and older saves are capped at the 30-second timer")
	_check(player.can_move, "The player can move after artifact placement")
	_check(director._hunt_clock_player.playing, "The clock sound starts with the hunt")

	director._timeout_hunt()
	_check(not player.can_move, "The timeout result holds player movement while retry is shown")
	_check(not director._hunt_clock_player.playing, "The clock sound stops at timeout")

	director.retry_hunt()
	_check(game_state.final_hunt_active, "Follow Echoes starts a new hunt")
	_check(player.can_move, "The player can move after following the echoes again")
	_check(player.mouse_captured, "Retry restores captured-mouse gameplay")
	_check(director._hunt_clock_player.playing, "The clock sound restarts for the retry")

	home.queue_free()
	player.queue_free()
	game_state.reset()
	game_state.autosave_enabled = original_autosave
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
		print("Final-hunt retry verification passed.")
		quit(0)
	else:
		print("Final-hunt retry verification failed: " + ", ".join(failures))
		quit(1)
