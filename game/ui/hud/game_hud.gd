extends CanvasLayer

const FIRST_STORY_CLUE := "Damaged newspaper"
const PAUSE_OVERLAY_LAYER := 500
const MAIN_MENU_SCENE := preload("res://game/ui/menus/main_menu.tscn")
const TUTORIAL_WAITING_FOR_WAKE_UP := 0
const TUTORIAL_MOVEMENT := 1
const TUTORIAL_WAITING_FOR_BOX := 2
const TUTORIAL_INTERACT := 3
const TUTORIAL_WAITING_FOR_MINIGAME := 4
const TUTORIAL_PHONE := 5
const TUTORIAL_COMPLETE := 6
const TUTORIAL_FADE_DURATION := 0.28
const DIALOGUE_HUD_FADE_DURATION := 0.24

const KEY_WASD := preload("res://assets/art/images/ui/key_prompts/key_wasd.png")
const KEY_SPACEBAR := preload("res://assets/art/images/ui/key_prompts/key_spacebar.png")
const KEY_F := preload("res://assets/art/images/ui/key_prompts/key_f.png")
const KEY_E := preload("res://assets/art/images/ui/key_prompts/key_e.png")

@onready var objective_label: Label = %ObjectiveValue
@onready var objective_panel: PanelContainer = $HUDRoot/TopLeftPanel
@onready var clue_label: Label = %ClueValue
@onready var ingredient_label: Label = %IngredientValue
@onready var ambot_label: Label = %AMBotValue
@onready var ambot_panel: PanelContainer = $HUDRoot/AMBotPanel
@onready var pause_menu: Control = %PauseMenu
@onready var resume_button: Button = %ResumeButton
@onready var phone_ui: Control = $PhoneUI
@onready var inventory_ui: Control = $InventoryUI
@onready var hint_bar: PanelContainer = $HUDRoot/HintBar
@onready var hint_text: Label = %HintText
@onready var primary_key: TextureRect = %PrimaryKey
@onready var primary_label: Label = %PrimaryLabel
@onready var secondary_prompt: VBoxContainer = %SecondaryPrompt
@onready var secondary_key: TextureRect = %SecondaryKey
@onready var secondary_label: Label = %SecondaryLabel
@onready var final_hunt_panel: PanelContainer = %FinalHuntPanel
@onready var final_hunt_timer: Label = %FinalHuntTimer
@onready var final_hunt_placement_status: Label = %FinalHuntPlacementStatus
@onready var final_hunt_result: Control = %FinalHuntResult
@onready var final_hunt_result_title: Label = %FinalHuntResultTitle
@onready var final_hunt_result_message: Label = %FinalHuntResultMessage
@onready var final_hunt_retry_button: Button = %FinalHuntRetryButton

var tutorial_transitioning := false
var tutorial_movement_used := false
var tutorial_jump_used := false
var _tutorial_tween: Tween
var _normal_canvas_layer := 0
var _mouse_mode_before_pause := Input.MOUSE_MODE_CAPTURED
var _main_menu_transitioning := false
var _inventory_hud_hidden := false
var _ambot_panel_was_visible := false
var _dialogue_hud_tween: Tween

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
	phone_ui.open_state_changed.connect(_on_inventory_open_state_changed)
	_on_tutorial_step_changed(GameState.tutorial_step)
	_on_inventory_open_state_changed(phone_ui.phone_open)
	final_hunt_result.visible = false
	_on_final_hunt_placement_decided(GameState.final_hunt_placement_source, GameState.final_hunt_placement_spot)
	if GameState.final_hunt_active:
		_on_final_hunt_started(GameState.final_hunt_time_remaining)
	else:
		final_hunt_panel.visible = false

func _on_inventory_open_state_changed(is_open: bool) -> void:
	if is_open:
		if not _inventory_hud_hidden:
			_ambot_panel_was_visible = ambot_panel.visible
		_inventory_hud_hidden = true
		objective_panel.visible = false
		ambot_panel.visible = false
	elif _inventory_hud_hidden:
		_inventory_hud_hidden = false
		_update_objective_panel_visibility()
		ambot_panel.visible = _ambot_panel_was_visible

func set_dialogue_hud_hidden(
	hidden: bool,
	duration: float = DIALOGUE_HUD_FADE_DURATION,
) -> void:
	if _dialogue_hud_tween != null and _dialogue_hud_tween.is_valid():
		_dialogue_hud_tween.kill()
	var target_alpha := 0.0 if hidden else 1.0
	_dialogue_hud_tween = create_tween()
	_dialogue_hud_tween.set_trans(Tween.TRANS_SINE)
	_dialogue_hud_tween.set_ease(Tween.EASE_IN_OUT)
	_dialogue_hud_tween.tween_property(
		$HUDRoot,
		"modulate:a",
		target_alpha,
		maxf(duration, 0.0),
	)
	if inventory_ui.has_method("set_dialogue_hud_hidden"):
		inventory_ui.set_dialogue_hud_hidden(hidden, duration)
	if phone_ui.has_method("set_dialogue_hud_hidden"):
		phone_ui.set_dialogue_hud_hidden(hidden, duration)

func _input(event: InputEvent) -> void:
	if tutorial_transitioning:
		return

	match GameState.tutorial_step:
		TUTORIAL_MOVEMENT:
			if (
				event.is_action_pressed("move_forward")
				or event.is_action_pressed("move_back")
				or event.is_action_pressed("move_left")
				or event.is_action_pressed("move_right")
			):
				tutorial_movement_used = true
			if event.is_action_pressed("jump"):
				tutorial_jump_used = true
			if tutorial_movement_used and tutorial_jump_used:
				_hide_tutorial_and_set_step(TUTORIAL_WAITING_FOR_BOX)
		TUTORIAL_INTERACT:
			if event.is_action_pressed("interact"):
				_hide_tutorial_and_set_step(TUTORIAL_WAITING_FOR_MINIGAME)
		TUTORIAL_PHONE:
			if event.is_action_pressed("phone"):
				_hide_tutorial_and_set_step(TUTORIAL_COMPLETE)

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
	if should_pause:
		_mouse_mode_before_pause = Input.mouse_mode
		pause_menu.visible = true
		layer = PAUSE_OVERLAY_LAYER
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		resume_button.grab_focus()
		get_tree().paused = true
	else:
		get_tree().paused = false
		pause_menu.visible = false
		layer = _normal_canvas_layer
		Input.set_mouse_mode(_mouse_mode_before_pause)


func toggle_pause() -> void:
	_toggle_pause()


func close_pause() -> void:
	get_tree().paused = false
	pause_menu.visible = false
	layer = _normal_canvas_layer
	Input.set_mouse_mode(_mouse_mode_before_pause)

func _on_resume_button_pressed() -> void:
	if get_tree().paused:
		_toggle_pause()

func _on_main_menu_button_pressed() -> void:
	if _main_menu_transitioning:
		return
	_main_menu_transitioning = true

	# Root-level minigames and dialogues survive a normal scene change. Disable
	# and remove them first so they cannot remain over the Main Menu or keep input.
	get_tree().paused = false
	pause_menu.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	GameState.save_game()
	for transient_ui in get_tree().get_nodes_in_group("transient_gameplay_ui"):
		_disable_transient_ui(transient_ui)
		transient_ui.queue_free()
	await get_tree().process_frame

	var change_error := get_tree().change_scene_to_packed(MAIN_MENU_SCENE)
	if change_error != OK:
		_main_menu_transitioning = false
		layer = _normal_canvas_layer
		push_error("Could not return to the Main Menu: %s" % error_string(change_error))


func _disable_transient_ui(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node is CanvasLayer:
		(node as CanvasLayer).visible = false
	elif node is CanvasItem:
		(node as CanvasItem).visible = false
	for child in node.get_children():
		_disable_transient_ui(child)

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

func begin_apartment_tutorial() -> void:
	if GameState.tutorial_step != TUTORIAL_WAITING_FOR_WAKE_UP:
		return
	tutorial_movement_used = false
	tutorial_jump_used = false
	_show_tutorial_step(TUTORIAL_MOVEMENT)


func notify_box_seen() -> void:
	if GameState.tutorial_step == TUTORIAL_WAITING_FOR_BOX:
		_show_tutorial_step(TUTORIAL_INTERACT)


func notify_box_minigame_started() -> void:
	if GameState.tutorial_step == TUTORIAL_INTERACT:
		_hide_tutorial_and_set_step(TUTORIAL_WAITING_FOR_MINIGAME)


func notify_box_minigame_completed() -> void:
	if GameState.tutorial_step < TUTORIAL_PHONE:
		_show_tutorial_step(TUTORIAL_PHONE)


func notify_box_minigame_dismissed() -> void:
	if GameState.tutorial_step == TUTORIAL_WAITING_FOR_MINIGAME:
		_show_tutorial_step(TUTORIAL_INTERACT)


func _on_tutorial_step_changed(_step: int) -> void:
	if not tutorial_transitioning:
		_restore_tutorial_from_state()


func _restore_tutorial_from_state() -> void:
	match GameState.tutorial_step:
		TUTORIAL_MOVEMENT, TUTORIAL_INTERACT, TUTORIAL_PHONE:
			_configure_tutorial(GameState.tutorial_step)
			hint_bar.modulate.a = 1.0
			hint_bar.visible = true
		_:
			hint_bar.visible = false
			hint_bar.modulate.a = 0.0


func _show_tutorial_step(step: int) -> void:
	_stop_tutorial_tween()
	tutorial_transitioning = true
	GameState.set_tutorial_step(step)
	_configure_tutorial(step)
	hint_bar.modulate.a = 0.0
	hint_bar.visible = true
	_tutorial_tween = create_tween()
	_tutorial_tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_tutorial_tween.set_trans(Tween.TRANS_SINE)
	_tutorial_tween.set_ease(Tween.EASE_OUT)
	_tutorial_tween.tween_property(
		hint_bar, "modulate:a", 1.0, TUTORIAL_FADE_DURATION
	)
	_tutorial_tween.finished.connect(_on_tutorial_fade_finished)


func _hide_tutorial_and_set_step(step: int) -> void:
	_stop_tutorial_tween()
	tutorial_transitioning = true
	_tutorial_tween = create_tween()
	_tutorial_tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_tutorial_tween.set_trans(Tween.TRANS_SINE)
	_tutorial_tween.set_ease(Tween.EASE_IN)
	_tutorial_tween.tween_property(
		hint_bar, "modulate:a", 0.0, TUTORIAL_FADE_DURATION
	)
	_tutorial_tween.tween_callback(func() -> void:
		hint_bar.visible = false
		GameState.set_tutorial_step(step)
	)
	_tutorial_tween.finished.connect(_on_tutorial_fade_finished)


func _configure_tutorial(step: int) -> void:
	secondary_prompt.visible = false
	primary_key.custom_minimum_size = Vector2(142, 96)
	match step:
		TUTORIAL_MOVEMENT:
			hint_text.text = "MOVE AROUND"
			primary_key.texture = KEY_WASD
			primary_label.text = "MOVE"
			secondary_prompt.visible = true
			secondary_key.texture = KEY_SPACEBAR
			secondary_label.text = "JUMP"
		TUTORIAL_INTERACT:
			hint_text.text = "OPEN THE BOX"
			primary_key.texture = KEY_F
			primary_label.text = "INTERACT"
		TUTORIAL_PHONE:
			hint_text.text = "CHECK YOUR PHONE"
			primary_key.texture = KEY_E
			primary_label.text = "OPEN PHONE"


func _stop_tutorial_tween() -> void:
	if _tutorial_tween != null and _tutorial_tween.is_valid():
		_tutorial_tween.kill()
	_tutorial_tween = null


func _on_tutorial_fade_finished() -> void:
	tutorial_transitioning = false
