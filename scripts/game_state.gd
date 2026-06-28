extends Node

signal objective_changed(objective: String)
signal clue_added(clue: String)
signal ingredients_changed(found: int, total: int)
signal ambot_status_changed(status: String)

var current_objective := "Find something to eat."
var ambot_status := "Offline"
var clues: Array[String] = []
var ingredients_found := 0
var ingredients_total := 7

func reset() -> void:
	current_objective = "Find something to eat."
	ambot_status = "Offline"
	clues.clear()
	ingredients_found = 0
	ingredients_total = 7
	objective_changed.emit(current_objective)
	ambot_status_changed.emit(ambot_status)
	ingredients_changed.emit(ingredients_found, ingredients_total)

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
