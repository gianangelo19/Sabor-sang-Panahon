extends SceneTree

class MockGameOnConnect extends GameOnConnect:
	signal release_response

	var next_response: Dictionary = {}
	var wait_for_release := false
	var cached_response: Dictionary = {}
	var saved_response: Dictionary = {}

	func _post_json(_path: String, _body: Dictionary, _bearer: String) -> Dictionary:
		if wait_for_release:
			await release_response
		return next_response

	func _save_artifact_cache(artifact_data: Dictionary) -> void:
		saved_response = artifact_data.duplicate(true)

	func _load_artifact_cache() -> Dictionary:
		return cached_response.duplicate(true)


var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check(
		ProjectSettings.get_setting("game_on/api_url")
		== "https://staging.gameonportal.ph",
		"GameOn explicitly targets the staging portal",
	)
	_check(
		not str(ProjectSettings.get_setting("game_on/game_id", "")).is_empty(),
		"GameOn has a configured staging Game ID",
	)
	_check(root.get_node_or_null("GameOnPortal") != null, "GameOn is registered as an autoload")

	var client := MockGameOnConnect.new()
	root.add_child(client)
	var unlocks: Array[Dictionary] = []
	var failures_seen: Array[Dictionary] = []
	client.artifact_unlocked.connect(
		func(data: Dictionary, is_new: bool):
			unlocks.append({"data": data, "is_new": is_new})
	)
	client.artifact_unlock_failed.connect(
		func(message: String, requires_auth: bool):
			failures_seen.append({
				"message": message,
				"requires_auth": requires_auth,
			})
	)

	_check(not client.unlock_artifact(), "Unauthorized unlock requests are rejected")
	_check(
		failures_seen.size() == 1 and failures_seen[0].requires_auth,
		"Unauthorized unlock failures request authentication",
	)

	client.is_authorized = true
	client._session_token = "test-session"
	client.wait_for_release = true
	client.next_response = {
		"ok": true,
		"status_code": 200,
		"message": "",
		"data": {
			"success": true,
			"alreadyUnlocked": false,
			"artifact": {
				"name": "Old Batchoy Bowl",
				"description": "A recovered memory of La Paz.",
			},
		},
	}
	_check(client.unlock_artifact(), "An authorized unlock request starts")
	_check(client.unlock_in_progress, "The client records an in-flight unlock")
	_check(not client.unlock_artifact(), "A second in-flight unlock request is rejected")
	client.release_response.emit()
	await process_frame
	_check(not client.unlock_in_progress, "The in-flight guard clears after completion")
	_check(
		unlocks.size() == 1 and unlocks[0].is_new,
		"A new artifact response emits one new-unlock event",
	)
	_check(
		client.saved_response.get("artifact", {}).get("name", "")
		== "Old Batchoy Bowl",
		"New artifact metadata is cached",
	)

	client.wait_for_release = false
	client.cached_response = {
		"success": true,
		"artifact": {"name": "Cached Batchoy Bowl"},
	}
	client.next_response = {
		"ok": true,
		"status_code": 200,
		"message": "",
		"data": {
			"success": true,
			"alreadyUnlocked": true,
			"artifact": {},
		},
	}
	client.unlock_artifact()
	await process_frame
	_check(
		unlocks.size() == 2
		and not unlocks[1].is_new
		and unlocks[1].data.get("artifact", {}).get("name", "")
		== "Cached Batchoy Bowl",
		"Confirmed already-unlocked responses may use cached metadata",
	)

	client.next_response = {
		"ok": false,
		"status_code": 500,
		"message": "GameOn service unavailable.",
		"data": {},
	}
	client.unlock_artifact()
	await process_frame
	_check(
		failures_seen.size() == 2
		and not failures_seen[1].requires_auth
		and unlocks.size() == 2,
		"Server failures emit an error instead of silently awarding cached data",
	)

	client.next_response = {
		"ok": false,
		"status_code": 401,
		"message": "Session expired.",
		"data": {},
	}
	client.unlock_artifact()
	await process_frame
	_check(
		failures_seen.size() == 3
		and failures_seen[2].requires_auth
		and not client.is_authorized,
		"Authorization failures clear the session and request reconnection",
	)

	var parsed_error := client._parse_response([
		HTTPRequest.RESULT_SUCCESS,
		503,
		PackedStringArray(),
		JSON.stringify({"message": "Maintenance"}).to_utf8_buffer(),
	])
	_check(
		not parsed_error.ok
		and int(parsed_error.status_code) == 503
		and parsed_error.message == "Maintenance",
		"HTTP error codes and server messages are preserved",
	)

	var success_scene := load("res://addons/game_on/artifact_success.tscn") as PackedScene
	var success_screen := success_scene.instantiate() as ArtifactSuccess
	root.add_child(success_screen)
	await process_frame
	success_screen.show_loading()
	_check(
		not success_screen.retry_button.visible
		and not success_screen.back_button.visible,
		"The reward screen blocks duplicate actions while loading",
	)
	success_screen.show_error("Session expired.", true)
	_check(
		success_screen.retry_button.text == "Reconnect & Retry"
		and success_screen.back_button.text == "Continue Without Reward",
		"Authentication errors offer reconnect or safe continuation",
	)
	success_screen.show_artifact(
		{
			"artifact": {
				"name": "Old Batchoy Bowl",
				"description": "A recovered memory of La Paz.",
			},
		},
		true,
	)
	_check(
		success_screen.title_label.text == "Artifact Unlocked!"
		and success_screen.artifact_name_label.text == "Old Batchoy Bowl"
		and success_screen.back_button.visible,
		"The reward screen displays confirmed artifact metadata",
	)

	_check(
		AuthPanel.MAIN_MENU_SCENE == "res://game/ui/menus/main_menu.tscn",
		"The authentication screen returns to the real main menu",
	)

	success_screen.queue_free()
	client.queue_free()
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
		print("GameOn integration verification passed.")
		quit(0)
	else:
		print("GameOn integration verification failed: " + ", ".join(failures))
		quit(1)
