class_name GameOnConnect
extends Node

signal authorization_status_changed(status: String)
signal artifact_unlocked(artifact_data: Dictionary, is_new_unlock: bool)
signal artifact_unlock_failed(message: String, requires_auth: bool)

const POLL_INTERVAL_SECONDS := 3.0

var api_url: String = ProjectSettings.get_setting(
	"game_on/api_url",
	"https://staging.gameonportal.ph",
).trim_suffix("/")
var game_id: String = ProjectSettings.get_setting("game_on/game_id", "")

var is_authorized := false
var unlock_in_progress := false
var pending_artifact: Dictionary = {}
var pending_is_new_unlock := false

var _session_token := ""
var _session_in_progress := false


func connect_account() -> void:
	if _session_in_progress or is_authorized:
		return
	if game_id.is_empty():
		push_error("GameOnConnect: game_id not configured in Project Settings")
		authorization_status_changed.emit("error")
		return
	_session_in_progress = true
	authorization_status_changed.emit("connecting")
	_create_session()


func unlock_artifact() -> bool:
	if unlock_in_progress:
		return false
	if not is_authorized or _session_token.is_empty():
		artifact_unlock_failed.emit(
			"Your GameOn session is not connected.",
			true,
		)
		return false
	unlock_in_progress = true
	_unlock_artifact_request()
	return true


func _create_session() -> void:
	var response := await _post_json("/api/session", {"gameId": game_id}, "")
	if not bool(response.get("ok", false)):
		_session_in_progress = false
		_clear_authorization()
		push_error("GameOnConnect: " + str(response.get("message", "Unable to create session")))
		authorization_status_changed.emit("error")
		return

	var data := response.get("data", {}) as Dictionary
	_session_token = str(data.get("sessionToken", ""))
	var signin_url := str(data.get("signinUrl", ""))
	if _session_token.is_empty() or signin_url.is_empty():
		_session_in_progress = false
		_clear_authorization()
		push_error("GameOnConnect: invalid create session response")
		authorization_status_changed.emit("error")
		return

	_open_browser(signin_url)
	_poll_authorization()


func _poll_authorization() -> void:
	while _session_in_progress:
		var response := await _get_with_bearer("/api/session", _session_token)
		if not bool(response.get("ok", false)):
			_session_in_progress = false
			_clear_authorization()
			authorization_status_changed.emit("error")
			return

		var data := response.get("data", {}) as Dictionary
		var status := str(data.get("status", ""))
		match status:
			"pending":
				authorization_status_changed.emit("pending")
			"authorized":
				_session_in_progress = false
				is_authorized = true
				authorization_status_changed.emit("authorized")
				return
			"expired":
				_session_in_progress = false
				_clear_authorization()
				authorization_status_changed.emit("expired")
				return
			_:
				_session_in_progress = false
				_clear_authorization()
				authorization_status_changed.emit("error")
				return

		await get_tree().create_timer(POLL_INTERVAL_SECONDS).timeout


func _unlock_artifact_request() -> void:
	var response := await _post_json(
		"/api/artifacts/unlock",
		{},
		_session_token,
	)
	unlock_in_progress = false
	if not bool(response.get("ok", false)):
		var status_code := int(response.get("status_code", 0))
		var requires_auth := status_code == 401 or status_code == 403
		if requires_auth:
			_clear_authorization()
		artifact_unlock_failed.emit(
			str(response.get("message", "Unable to unlock the GameOn artifact.")),
			requires_auth,
		)
		return

	var data := response.get("data", {}) as Dictionary
	if not bool(data.get("success", false)):
		artifact_unlock_failed.emit(
			_response_message(data, "GameOn did not confirm the artifact unlock."),
			false,
		)
		return

	var already_unlocked := bool(data.get("alreadyUnlocked", false))
	var resolved_data := data
	if already_unlocked and (data.get("artifact", {}) as Dictionary).is_empty():
		var cached := _load_artifact_cache()
		if not cached.is_empty():
			resolved_data = cached
	else:
		_save_artifact_cache(data)

	pending_artifact = resolved_data
	pending_is_new_unlock = not already_unlocked
	artifact_unlocked.emit(resolved_data, not already_unlocked)


func _clear_authorization() -> void:
	is_authorized = false
	_session_token = ""


func _save_artifact_cache(artifact_data: Dictionary) -> void:
	var file := FileAccess.open("user://artifact_cache.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(artifact_data))


func _load_artifact_cache() -> Dictionary:
	var file := FileAccess.open("user://artifact_cache.json", FileAccess.READ)
	if file:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			return parsed
	return {}


func _open_browser(url: String) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.open('%s', '_blank');" % url, true)
	else:
		OS.shell_open(url)


func _post_json(path: String, body: Dictionary, bearer: String) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)
	var headers := PackedStringArray(["Content-Type: application/json"])
	if not bearer.is_empty():
		headers.append("Authorization: Bearer %s" % bearer)
	var request_error := http.request(
		api_url + path,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(body),
	)
	if request_error != OK:
		http.queue_free()
		return _request_failure(error_string(request_error))
	var result: Array = await http.request_completed
	http.queue_free()
	return _parse_response(result)


func _get_with_bearer(path: String, bearer: String) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)
	var headers := PackedStringArray(["Authorization: Bearer %s" % bearer])
	var request_error := http.request(
		api_url + path,
		headers,
		HTTPClient.METHOD_GET,
		"",
	)
	if request_error != OK:
		http.queue_free()
		return _request_failure(error_string(request_error))
	var result: Array = await http.request_completed
	http.queue_free()
	return _parse_response(result)


func _parse_response(result: Array) -> Dictionary:
	if result.size() < 4:
		return _request_failure("GameOn returned an empty response.")
	var transport_status := int(result[0])
	var status_code := int(result[1])
	if transport_status != HTTPRequest.RESULT_SUCCESS:
		return _request_failure(
			"Network request failed (%d)." % transport_status,
			status_code,
		)

	var text := (result[3] as PackedByteArray).get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text)
	var data := parsed as Dictionary if parsed is Dictionary else {}
	if status_code < 200 or status_code >= 300:
		return _request_failure(
			_response_message(data, "GameOn returned HTTP %d." % status_code),
			status_code,
			data,
		)
	if not (parsed is Dictionary):
		return _request_failure("GameOn response was not a JSON object.", status_code)
	return {
		"ok": true,
		"status_code": status_code,
		"data": data,
		"message": "",
	}


func _request_failure(
	message: String,
	status_code := 0,
	data: Dictionary = {},
) -> Dictionary:
	return {
		"ok": false,
		"status_code": status_code,
		"data": data,
		"message": message,
	}


func _response_message(data: Dictionary, fallback: String) -> String:
	var message := str(data.get("message", data.get("error", ""))).strip_edges()
	return fallback if message.is_empty() else message
