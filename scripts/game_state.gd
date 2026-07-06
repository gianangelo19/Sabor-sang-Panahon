extends Node

signal objective_changed(objective: String)
signal clue_added(clue: String)
signal ingredients_changed(found: int, total: int)
signal ambot_status_changed(status: String)
signal phone_notification_received(notification: Dictionary)
signal ambot_availability_changed(available: bool)
signal tutorial_step_changed(step: int)

var current_objective := "Find something to eat."
var ambot_status := "Offline"
var clues: Array[String] = []
var ingredients_found := 0
var ingredients_total := 7
var pending_ambot_notification: Dictionary = {}
var completed_ambot_conversations: Array[String] = []
var tutorial_step := 0

func reset() -> void:
	current_objective = "Find something to eat."
	ambot_status = "Offline"
	clues.clear()
	ingredients_found = 0
	ingredients_total = 7
	pending_ambot_notification.clear()
	completed_ambot_conversations.clear()
	tutorial_step = 0
	objective_changed.emit(current_objective)
	ambot_status_changed.emit(ambot_status)
	ingredients_changed.emit(ingredients_found, ingredients_total)
	ambot_availability_changed.emit(false)
	tutorial_step_changed.emit(tutorial_step)

func set_objective(objective: String) -> void:
	current_objective = objective
	objective_changed.emit(current_objective)

func set_ambot_status(status: String) -> void:
	ambot_status = status
	ambot_status_changed.emit(ambot_status)

func add_clue(clue: String) -> void:
	if clues.has(clue):
		return
	clues.append(clue)
	clue_added.emit(clue)

func set_ingredients(found: int, total: int = ingredients_total) -> void:
	ingredients_found = clampi(found, 0, total)
	ingredients_total = max(total, 1)
	ingredients_changed.emit(ingredients_found, ingredients_total)

func push_ambot_notification(situation_id: String, title: String, preview: String) -> void:
	pending_ambot_notification = {
		"situation_id": situation_id,
		"title": title,
		"preview": preview,
	}
	phone_notification_received.emit(pending_ambot_notification.duplicate())
	ambot_availability_changed.emit(true)

func has_ambot_notification() -> bool:
	return not pending_ambot_notification.is_empty()

func consume_ambot_notification() -> String:
	if pending_ambot_notification.is_empty():
		return ""
	var situation_id: String = pending_ambot_notification.get("situation_id", "")
	pending_ambot_notification.clear()
	ambot_availability_changed.emit(false)
	return situation_id

func complete_ambot_conversation(situation_id: String) -> void:
	if situation_id != "" and not completed_ambot_conversations.has(situation_id):
		completed_ambot_conversations.append(situation_id)

func set_tutorial_step(step: int) -> void:
	tutorial_step = maxi(step, 0)
	tutorial_step_changed.emit(tutorial_step)
