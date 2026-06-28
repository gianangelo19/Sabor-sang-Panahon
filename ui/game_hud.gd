extends CanvasLayer

@onready var objective_label: Label = %ObjectiveValue
@onready var clue_label: Label = %ClueValue
@onready var ingredient_label: Label = %IngredientValue
@onready var ambot_label: Label = %AMBotValue
@onready var pause_menu: Control = %PauseMenu
@onready var resume_button: Button = %ResumeButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.visible = false
	_sync_from_state()
	GameState.objective_changed.connect(_on_objective_changed)
	GameState.clue_added.connect(_on_clue_added)
	GameState.ingredients_changed.connect(_on_ingredients_changed)
	GameState.ambot_status_changed.connect(_on_ambot_status_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _sync_from_state() -> void:
	_on_objective_changed(GameState.current_objective)
	_on_ambot_status_changed(GameState.ambot_status)
	_on_ingredients_changed(GameState.ingredients_found, GameState.ingredients_total)
	_update_clue_count()

func _toggle_pause() -> void:
	var should_pause := not get_tree().paused
	get_tree().paused = should_pause
	pause_menu.visible = should_pause

	if should_pause:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		resume_button.grab_focus()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume_button_pressed() -> void:
	if get_tree().paused:
		_toggle_pause()

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	GameState.reset()
	get_tree().reload_current_scene()

func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	GameState.reset()
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_objective_changed(objective: String) -> void:
	objective_label.text = objective

func _on_clue_added(_clue: String) -> void:
	_update_clue_count()

func _on_ingredients_changed(found: int, total: int) -> void:
	ingredient_label.text = "%d/%d found" % [found, total]

func _on_ambot_status_changed(status: String) -> void:
	ambot_label.text = status

func _update_clue_count() -> void:
	clue_label.text = "%d recorded" % GameState.clues.size()
