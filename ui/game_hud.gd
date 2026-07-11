extends CanvasLayer

const FIRST_STORY_CLUE := "Damaged newspaper"
const MINIGAME_PAUSE_LAYER := 500
const TUTORIAL_PROMPTS := [
	"Press WASD to move",
	"Move the mouse to look around",
	"Press E to interact",
	"Press P to open your phone",
	"Press P again to put your phone away",
	"Press Esc to pause",
]

@onready var objective_label: Label = %ObjectiveValue
@onready var objective_panel: PanelContainer = $HUDRoot/TopLeftPanel
@onready var clue_label: Label = %ClueValue
@onready var ingredient_label: Label = %IngredientValue
@onready var ambot_label: Label = %AMBotValue
@onready var pause_menu: Control = %PauseMenu
@onready var resume_button: Button = %ResumeButton
@onready var phone_ui: Control = $PhoneUI
@onready var hint_bar: PanelContainer = $HUDRoot/HintBar
@onready var hint_text: Label = $HUDRoot/HintBar/HintText
@onready var final_hunt_panel: PanelContainer = %FinalHuntPanel
@onready var final_hunt_timer: Label = %FinalHuntTimer
@onready var final_hunt_placement_status: Label = %FinalHuntPlacementStatus
@onready var final_hunt_result: Control = %FinalHuntResult
@onready var final_hunt_result_title: Label = %FinalHuntResultTitle
@onready var final_hunt_result_message: Label = %FinalHuntResultMessage
@onready var final_hunt_retry_button: Button = %FinalHuntRetryButton

var tutorial_transitioning := false
var _normal_canvas_layer := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_normal_canvas_layer = layer
	pause_menu.visible = false
	_sync_from_state()
	GameState.objective_changed.connect(_on_objective_changed)
	GameState.clue_added.connect(_on_clue_added)
	GameState.ingredients_changed.connect(_on_ingredients_changed)
	GameState.ambot_status_changed.connect(_on_ambot_status_changed)
	GameState.tutorial_step_changed.connect(_on_tutorial_step_changed)
	GameState.final_hunt_started.connect(_on_final_hunt_started)
	GameState.final_hunt_time_changed.connect(_on_final_hunt_time_changed)
	GameState.final_hunt_finished.connect(_on_final_hunt_finished)
	GameState.final_hunt_placement_decided.connect(_on_final_hunt_placement_decided)
	_on_tutorial_step_changed(GameState.tutorial_step)
	final_hunt_result.visible = false
	_on_final_hunt_placement_decided(GameState.final_hunt_placement_source, GameState.final_hunt_placement_spot)
	if GameState.final_hunt_active:
		_on_final_hunt_started(GameState.final_hunt_time_remaining)
	else:
		final_hunt_panel.visible = false

func _input(event: InputEvent) -> void:
	if tutorial_transitioning or GameState.tutorial_step >= TUTORIAL_PROMPTS.size():
		return

	var completed := false
	match GameState.tutorial_step:
		0:
			completed = (
				event.is_action_pressed("move_forward")
				or event.is_action_pressed("move_back")
				or event.is_action_pressed("move_left")
				or event.is_action_pressed("move_right")
			)
		1:
			completed = event is InputEventMouseMotion and event.relative.length() >= 2.0
		2:
			completed = event.is_action_pressed("interact")
		3, 4:
			completed = event.is_action_pressed("phone")
		5:
			completed = event.is_action_pressed("pause")

	if completed:
		_advance_tutorial()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if phone_ui.phone_open:
			phone_ui.close_phone()
			get_viewport().set_input_as_handled()
			return
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _sync_from_state() -> void:
	_update_objective_panel_visibility()
	_on_objective_changed(GameState.current_objective)
	_on_ambot_status_changed(GameState.ambot_status)
	_on_ingredients_changed(GameState.ingredients_found, GameState.ingredients_total)
	_update_clue_count()

func _toggle_pause() -> void:
	var should_pause := not get_tree().paused
	get_tree().paused = should_pause
	pause_menu.visible = should_pause
	var minigame_active := (
		get_tree().get_first_node_in_group("minigame_session") != null
	)
	layer = MINIGAME_PAUSE_LAYER if should_pause and minigame_active else _normal_canvas_layer

	if should_pause:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		resume_button.grab_focus()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func toggle_pause() -> void:
	_toggle_pause()


func close_pause() -> void:
	get_tree().paused = false
	pause_menu.visible = false
	layer = _normal_canvas_layer
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume_button_pressed() -> void:
	if get_tree().paused:
		_toggle_pause()

func _on_main_menu_button_pressed() -> void:
	close_pause()
	GameState.save_game()
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")

func _on_settings_button_pressed() -> void:
	SettingsManager.show_settings_menu(self)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_objective_changed(objective: String) -> void:
	objective_label.text = objective

func _on_clue_added(_clue: String) -> void:
	_update_objective_panel_visibility()
	_update_clue_count()

func _on_ingredients_changed(found: int, total: int) -> void:
	var complete := found >= total
	ingredient_label.text = "%d/%d collected" % [found, total]
	ingredient_label.modulate = Color("75e6a4") if complete else Color.WHITE
	ingredient_label.visible = found > 0
	var ingredient_title := ingredient_label.get_node_or_null("../IngredientTitle") as Label
	if ingredient_title:
		ingredient_title.text = "Ingredients complete" if complete else "Ingredients"
		ingredient_title.modulate = Color("75e6a4") if complete else Color.WHITE
		ingredient_title.visible = found > 0

func _on_ambot_status_changed(status: String) -> void:
	ambot_label.text = status

func _on_final_hunt_started(duration: float) -> void:
	final_hunt_result.visible = false
	final_hunt_panel.visible = true
	_on_final_hunt_time_changed(duration)

func _on_final_hunt_time_changed(seconds_remaining: float) -> void:
	var total_seconds := ceili(maxf(seconds_remaining, 0.0))
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	final_hunt_timer.text = "%d:%02d" % [minutes, seconds]
	final_hunt_timer.modulate = Color("ff7867") if total_seconds <= 10 else Color.WHITE

func _on_final_hunt_placement_decided(source: String, _spot_id: String) -> void:
	match source:
		"procedural":
			final_hunt_placement_status.text = "HIDING PLACE SELECTED"
			final_hunt_placement_status.modulate = Color("75e6a4")
		"unavailable":
			final_hunt_placement_status.text = "NO SAFE HIDING PLACE"
			final_hunt_placement_status.modulate = Color("ff7867")
		_:
			final_hunt_placement_status.text = "ARTIFACT SEARCH"
			final_hunt_placement_status.modulate = Color.WHITE

func _on_final_hunt_finished(success: bool) -> void:
	final_hunt_panel.visible = false
	if success:
		final_hunt_result.visible = false
		return
	final_hunt_result_title.text = "GRANDMA IS HOME"
	final_hunt_result_message.text = "The cultural echoes faded before you found the Batchoy Bowl. Retry to search a different hiding place."
	final_hunt_result.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	final_hunt_retry_button.grab_focus()

func _on_final_hunt_retry_pressed() -> void:
	final_hunt_result.visible = false
	var hunt_director := get_tree().get_first_node_in_group("final_artifact_hunt")
	if hunt_director and hunt_director.has_method("retry_hunt"):
		hunt_director.retry_hunt()

func _update_clue_count() -> void:
	clue_label.text = "%d recorded" % GameState.clues.size()

func _update_objective_panel_visibility() -> void:
	objective_panel.visible = GameState.clues.has(FIRST_STORY_CLUE)

func _advance_tutorial() -> void:
	tutorial_transitioning = true
	GameState.set_tutorial_step(GameState.tutorial_step + 1)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(hint_bar, "modulate:a", 0.0, 0.16)
	tween.tween_callback(_show_current_tutorial_step)

func _on_tutorial_step_changed(_step: int) -> void:
	if not tutorial_transitioning:
		_show_current_tutorial_step()

func _show_current_tutorial_step() -> void:
	if GameState.tutorial_step >= TUTORIAL_PROMPTS.size():
		hint_bar.visible = false
		tutorial_transitioning = false
		return

	hint_text.text = TUTORIAL_PROMPTS[GameState.tutorial_step]
	hint_bar.visible = true
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(hint_bar, "modulate:a", 1.0, 0.16)
	tween.finished.connect(func(): tutorial_transitioning = false)
