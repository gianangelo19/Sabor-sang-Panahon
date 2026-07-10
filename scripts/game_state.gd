extends Node

const SAVE_VERSION := 1
const DEFAULT_GAME_SCENE := "res://la_paz.tscn"

signal objective_changed(objective: String)
signal clue_added(clue: String)
signal ingredients_changed(found: int, total: int)
signal ambot_status_changed(status: String)
signal phone_notification_received(notification: Dictionary)
signal ambot_availability_changed(available: bool)
signal tutorial_step_changed(step: int)
signal destination_unlocked(destination_id: String)
signal destination_selected(destination_id: String)
signal destination_completed(destination_id: String)
signal navigation_changed

var current_objective := "Find something to eat."
var ambot_status := "Offline"
var clues: Array[String] = []
var ingredients_found := 0
var ingredients_total := 7
var collected_ingredients: Dictionary = {}
var pending_ambot_notification: Dictionary = {}
var completed_ambot_conversations: Array[String] = []
var tutorial_step := 0
var unlocked_destinations: Array[String] = []
var completed_destinations: Array[String] = []
var active_destination := ""
var map_viewed_destination := ""
var save_file_path := "user://savegame.json"
var autosave_enabled := false
var pending_player_transform: Dictionary = {}
var _wake_up_intro_requested := false
var _autosave_queued := false

func reset() -> void:
	_wake_up_intro_requested = false
	current_objective = "Find something to eat."
	ambot_status = "Offline"
	clues.clear()
	ingredients_found = 0
	ingredients_total = 7
	collected_ingredients.clear()
	pending_ambot_notification.clear()
	completed_ambot_conversations.clear()
	tutorial_step = 0
	unlocked_destinations.clear()
	completed_destinations.clear()
	active_destination = ""
	map_viewed_destination = ""
	pending_player_transform.clear()
	objective_changed.emit(current_objective)
	ambot_status_changed.emit(ambot_status)
	ingredients_changed.emit(ingredients_found, ingredients_total)
	ambot_availability_changed.emit(false)
	tutorial_step_changed.emit(tutorial_step)
	navigation_changed.emit()

func set_objective(objective: String) -> void:
	current_objective = objective
	objective_changed.emit(current_objective)
	_request_autosave()

func set_ambot_status(status: String) -> void:
	ambot_status = status
	ambot_status_changed.emit(ambot_status)
	_request_autosave()

func add_clue(clue: String) -> void:
	if clues.has(clue):
		return
	clues.append(clue)
	clue_added.emit(clue)
	_request_autosave()

func set_ingredients(found: int, total: int = ingredients_total) -> void:
	ingredients_found = clampi(found, 0, total)
	ingredients_total = max(total, 1)
	ingredients_changed.emit(ingredients_found, ingredients_total)
	_request_autosave()

func collect_ingredient(ingredient_id: String, display_name: String) -> bool:
	if ingredient_id.is_empty() or collected_ingredients.has(ingredient_id):
		return false
	collected_ingredients[ingredient_id] = display_name
	ingredients_found = collected_ingredients.size()
	ingredients_changed.emit(ingredients_found, ingredients_total)
	_request_autosave()
	return true

func has_ingredient(ingredient_id: String) -> bool:
	return collected_ingredients.has(ingredient_id)

func push_ambot_notification(situation_id: String, title: String, preview: String) -> void:
	pending_ambot_notification = {
		"situation_id": situation_id,
		"title": title,
		"preview": preview,
	}
	phone_notification_received.emit(pending_ambot_notification.duplicate())
	ambot_availability_changed.emit(true)
	_request_autosave()

func has_ambot_notification() -> bool:
	return not pending_ambot_notification.is_empty()

func consume_ambot_notification() -> String:
	if pending_ambot_notification.is_empty():
		return ""
	var situation_id: String = pending_ambot_notification.get("situation_id", "")
	pending_ambot_notification.clear()
	ambot_availability_changed.emit(false)
	_request_autosave()
	return situation_id

func complete_ambot_conversation(situation_id: String) -> void:
	if situation_id != "" and not completed_ambot_conversations.has(situation_id):
		completed_ambot_conversations.append(situation_id)
		_request_autosave()

func set_tutorial_step(step: int) -> void:
	tutorial_step = maxi(step, 0)
	tutorial_step_changed.emit(tutorial_step)
	_request_autosave()

func unlock_destination(destination_id: String) -> bool:
	if destination_id.is_empty() or unlocked_destinations.has(destination_id):
		return false
	unlocked_destinations.append(destination_id)
	destination_unlocked.emit(destination_id)
	navigation_changed.emit()
	_request_autosave()
	return true

func select_destination(destination_id: String) -> bool:
	if not unlocked_destinations.has(destination_id) or completed_destinations.has(destination_id):
		return false
	if active_destination == destination_id:
		return true
	active_destination = destination_id
	map_viewed_destination = ""
	destination_selected.emit(destination_id)
	navigation_changed.emit()
	_request_autosave()
	return true

func complete_destination(destination_id: String) -> bool:
	if destination_id.is_empty() or completed_destinations.has(destination_id):
		return false
	if not unlocked_destinations.has(destination_id):
		unlocked_destinations.append(destination_id)
	completed_destinations.append(destination_id)
	if active_destination == destination_id:
		active_destination = ""
		map_viewed_destination = ""
	destination_completed.emit(destination_id)
	navigation_changed.emit()
	_request_autosave()
	return true

func mark_active_destination_seen_in_maps() -> bool:
	if active_destination.is_empty() or map_viewed_destination == active_destination:
		return false
	map_viewed_destination = active_destination
	navigation_changed.emit()
	_request_autosave()
	return true

func has_seen_active_destination_in_maps() -> bool:
	return not active_destination.is_empty() and map_viewed_destination == active_destination

func is_destination_unlocked(destination_id: String) -> bool:
	return unlocked_destinations.has(destination_id)

func is_destination_completed(destination_id: String) -> bool:
	return completed_destinations.has(destination_id)

func start_new_game(scene_path: String = DEFAULT_GAME_SCENE) -> void:
	autosave_enabled = false
	reset()
	request_wake_up_intro()
	autosave_enabled = true
	save_game(scene_path)

func request_wake_up_intro() -> void:
	_wake_up_intro_requested = true

func consume_wake_up_intro() -> bool:
	if not _wake_up_intro_requested:
		return false
	_wake_up_intro_requested = false
	return true

func has_save_game() -> bool:
	return FileAccess.file_exists(save_file_path)

func save_game(scene_path: String = "") -> bool:
	var resolved_scene := scene_path
	if resolved_scene.is_empty() and get_tree().current_scene:
		resolved_scene = get_tree().current_scene.scene_file_path
	if resolved_scene.is_empty() or resolved_scene == "res://menus/main_menu.tscn":
		resolved_scene = DEFAULT_GAME_SCENE

	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		player = get_tree().root.find_child("ProtoController", true, false) as Node3D
	var player_data: Dictionary = pending_player_transform.duplicate(true)
	if player:
		player_data = {
			"position": [player.global_position.x, player.global_position.y, player.global_position.z],
			"rotation": [player.rotation.x, player.rotation.y, player.rotation.z],
		}

	var data := {
		"version": SAVE_VERSION,
		"scene": resolved_scene,
		"objective": current_objective,
		"ambot_status": ambot_status,
		"clues": clues,
		"ingredients": collected_ingredients,
		"ingredients_total": ingredients_total,
		"pending_notification": pending_ambot_notification,
		"completed_ambot_conversations": completed_ambot_conversations,
		"tutorial_step": tutorial_step,
		"unlocked_destinations": unlocked_destinations,
		"completed_destinations": completed_destinations,
		"active_destination": active_destination,
		"map_viewed_destination": map_viewed_destination,
		"player": player_data,
	}
	var file := FileAccess.open(save_file_path, FileAccess.WRITE)
	if file == null:
		push_error("Unable to open save file: " + save_file_path)
		return false
	file.store_string(JSON.stringify(data))
	return true

func load_game() -> String:
	_wake_up_intro_requested = false
	if not has_save_game():
		return ""
	var file := FileAccess.open(save_file_path, FileAccess.READ)
	if file == null:
		return ""
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or int(parsed.get("version", 0)) != SAVE_VERSION:
		return ""

	autosave_enabled = false
	current_objective = str(parsed.get("objective", "Find something to eat."))
	ambot_status = str(parsed.get("ambot_status", "Offline"))
	clues.assign(parsed.get("clues", []))
	collected_ingredients = parsed.get("ingredients", {}).duplicate(true)
	ingredients_found = collected_ingredients.size()
	ingredients_total = int(parsed.get("ingredients_total", 7))
	pending_ambot_notification = parsed.get("pending_notification", {}).duplicate(true)
	completed_ambot_conversations.assign(parsed.get("completed_ambot_conversations", []))
	tutorial_step = int(parsed.get("tutorial_step", 0))
	unlocked_destinations.assign(parsed.get("unlocked_destinations", []))
	completed_destinations.assign(parsed.get("completed_destinations", []))
	active_destination = str(parsed.get("active_destination", ""))
	map_viewed_destination = str(parsed.get("map_viewed_destination", ""))
	pending_player_transform = parsed.get("player", {}).duplicate(true)
	autosave_enabled = true
	_emit_loaded_state()
	return str(parsed.get("scene", DEFAULT_GAME_SCENE))

func apply_saved_player_transform(player: Node3D) -> void:
	if pending_player_transform.is_empty() or player == null:
		return
	var position_data: Array = pending_player_transform.get("position", [])
	var rotation_data: Array = pending_player_transform.get("rotation", [])
	if position_data.size() == 3:
		player.global_position = Vector3(float(position_data[0]), float(position_data[1]), float(position_data[2]))
	if rotation_data.size() == 3:
		player.rotation = Vector3(float(rotation_data[0]), float(rotation_data[1]), float(rotation_data[2]))
	pending_player_transform.clear()

func _request_autosave() -> void:
	if not autosave_enabled or _autosave_queued:
		return
	_autosave_queued = true
	call_deferred("_perform_autosave")

func _perform_autosave() -> void:
	_autosave_queued = false
	if autosave_enabled:
		save_game()

func _emit_loaded_state() -> void:
	objective_changed.emit(current_objective)
	ambot_status_changed.emit(ambot_status)
	ingredients_changed.emit(ingredients_found, ingredients_total)
	ambot_availability_changed.emit(not pending_ambot_notification.is_empty())
	tutorial_step_changed.emit(tutorial_step)
	navigation_changed.emit()
