extends Node2D

signal minigame_finished
signal minigame_failed
signal minigame_retry_requested

enum BoxState { CLOSED, OPEN }

const SCREEN_SIZE := Vector2(1152.0, 648.0)
const SCREEN_CENTER := SCREEN_SIZE * 0.5
const BOX_INTERIOR := Rect2(365.0, 120.0, 425.0, 405.0)
const REQUIRED_IDS := ["newspaper", "photo", "key"]
const ITEM_ORDER := [
	"newspaper", "photo", "key", "spoon", "bowl_piece", "receipt", "letter"
]

const SHARED_FONT_PATH := "res://features/minigames/shared/fonts/VCR_OSD_MONO_1.001.ttf"
const INVENTORY_PANEL_PATH := "res://features/minigames/box_unboxing/assets/ui/panels/box_unboxing_inventory_panel.png"
const HISTORY_PANEL_PATH := "res://features/minigames/box_unboxing/assets/ui/panels/box_unboxing_history_panel.png"
const HISTORY_SELECTED_PATH := "res://features/minigames/box_unboxing/assets/ui/panels/box_unboxing_history_row_selected.png"
const HISTORY_CURSOR_PATH := "res://features/minigames/box_unboxing/assets/ui/panels/box_unboxing_history_selection_cursor.png"
const MUSIC_PATH := "res://features/minigames/box_unboxing/assets/audio/music/bgm_box_memory_loop.ogg"
const AMBIENCE_PATH := "res://features/minigames/box_unboxing/assets/audio/ambience/amb_old_room_loop.ogg"
const SFX_ROOT := "res://features/minigames/box_unboxing/assets/audio/sfx/"
const UI_SFX_ROOT := "res://features/minigames/box_unboxing/assets/audio/ui/"
const FAIL_SCREEN_SCENE := preload(
	"res://features/minigames/fail_screen/scenes/minigame_fail_screen.tscn"
)

const INVENTORY_PANEL_POSITION := Vector2(12.0, 12.0)
const INVENTORY_ICON_POSITIONS := [
	Vector2(39.9, 44.9),
	Vector2(122.5, 44.9),
	Vector2(200.8, 44.0),
]
const HISTORY_PANEL_POSITION := Vector2(847.0, 12.0)
const HISTORY_ROW_POSITIONS := [
	Vector2(53.9, 38.0),
	Vector2(53.9, 69.9),
	Vector2(53.9, 103.0),
	Vector2(53.9, 136.2),
	Vector2(53.9, 169.3),
	Vector2(53.9, 201.3),
]
const HISTORY_CURSOR_POSITIONS := [
	Vector2(15.5, 30.2),
	Vector2(15.5, 62.1),
	Vector2(15.5, 95.2),
	Vector2(15.5, 128.4),
	Vector2(15.5, 161.5),
	Vector2(15.5, 193.5),
]
const HISTORY_VISIBLE_ROWS := 6

const PREMATURE_CLOSE_DIALOGUE := [
	"There should be something else in here. Am I not curious?",
	"I've barely looked through this. There must be more.",
	"Something important may still be buried underneath.",
	"I shouldn't close this until I've checked more carefully.",
	"Why stop now? This box still has something to show me.",
]

const ITEM_DATA := {
	"newspaper": {
		"name": "OLD NEWSPAPER",
		"texture": "res://features/minigames/box_unboxing/assets/contents/damaged_newspaper_small.png",
		"closeup": "res://features/minigames/box_unboxing/assets/closeups/damaged_newspaper_closeup.png",
		"inventory": "res://features/minigames/box_unboxing/assets/ui/inventory/damaged_newspaper_small.png",
		"collision": Vector2(320.0, 245.0),
		"dialogue": "A torn newspaper... La Paz, hot broth, and miki are still readable. The dish's name is missing.",
		"expression": "concerned",
		"required": true,
		"material": "paper",
	},
	"photo": {
		"name": "FAMILY PHOTO",
		"texture": "res://features/minigames/box_unboxing/assets/contents/old_family_photo_small.png",
		"closeup": "res://features/minigames/box_unboxing/assets/closeups/old_family_photo_closeup.png",
		"inventory": "res://features/minigames/box_unboxing/assets/ui/inventory/old_family_photo_small.png",
		"collision": Vector2(270.0, 210.0),
		"dialogue": "Lola looks so happy here. This photo feels warm, like something I should remember.",
		"expression": "happy",
		"required": true,
		"material": "paper",
	},
	"key": {
		"name": "OLD KEY",
		"texture": "res://features/minigames/box_unboxing/assets/contents/old_key.png",
		"closeup": "res://features/minigames/box_unboxing/assets/closeups/old_key_closeup.png",
		"inventory": "res://features/minigames/box_unboxing/assets/ui/inventory/old_key.png",
		"collision": Vector2(130.0, 210.0),
		"dialogue": "An old key... Maybe it opens something Lola kept hidden.",
		"expression": "surprised",
		"required": true,
		"material": "metal",
	},
	"spoon": {
		"name": "OLD SPOON",
		"texture": "res://features/minigames/box_unboxing/assets/contents/old_spoon.png",
		"closeup": "res://features/minigames/box_unboxing/assets/closeups/old_spoon_closeup.png",
		"collision": Vector2(110.0, 235.0),
		"dialogue": "An old spoon. The handle is worn smooth from years of use.",
		"expression": "neutral",
		"required": false,
		"material": "metal",
	},
	"bowl_piece": {
		"name": "BOWL PIECE",
		"texture": "res://features/minigames/box_unboxing/assets/contents/small_bowl_piece.png",
		"closeup": "res://features/minigames/box_unboxing/assets/closeups/small_bowl_piece_closeup.png",
		"collision": Vector2(165.0, 130.0),
		"dialogue": "A broken bowl piece. It was kept too carefully to be ordinary.",
		"expression": "concerned",
		"required": false,
		"material": "ceramic",
	},
	"receipt": {
		"name": "MARKET RECEIPT",
		"texture": "res://features/minigames/box_unboxing/assets/contents/market_receipt_small.png",
		"closeup": "res://features/minigames/box_unboxing/assets/closeups/market_receipt_closeup.png",
		"collision": Vector2(145.0, 215.0),
		"dialogue": "An old La Paz market receipt. Chicharon is still readable, but the rest has faded.",
		"expression": "surprised",
		"required": false,
		"material": "paper",
	},
	"letter": {
		"name": "FAMILY LETTER",
		"texture": "res://features/minigames/box_unboxing/assets/contents/family_letter_small.png",
		"closeup": "res://features/minigames/box_unboxing/assets/closeups/family_letter_closeup.png",
		"collision": Vector2(180.0, 210.0),
		"dialogue": "A letter from Lola. Her words feel like they were waiting for me.",
		"expression": "happy",
		"required": false,
		"material": "paper",
	},
}

@export_category("Polish")
@export var hover_scale_multiplier := 1.05
@export var drag_scale_multiplier := 1.08
@export var item_return_duration := 0.20
@export var closeup_transition_duration := 0.20

@export_category("Testing")
@export var success_test_key_enabled := false
@export var fail_test_key_enabled := false

@onready var background: Sprite2D = $Background
@onready var box_closed: Sprite2D = $BoxClosed
@onready var box_open: Sprite2D = $BoxOpen
@onready var box_click_area: Area2D = $BoxClickArea
@onready var flap_areas: Array[Area2D] = [
	$FlapClickAreas/TopFlapArea,
	$FlapClickAreas/BottomFlapArea,
	$FlapClickAreas/LeftFlapArea,
	$FlapClickAreas/RightFlapArea,
]
@onready var box_contents: Node2D = $BoxContents
@onready var closeup_layer: CanvasLayer = $CloseupLayer
@onready var dim_overlay: ColorRect = $CloseupLayer/DimOverlay
@onready var closeup_sprite: Sprite2D = $CloseupLayer/CloseupSprite
@onready var dialogue: SharedDialogue = $SharedDialogue

var box_state := BoxState.CLOSED
var gameplay_active := false
var result_emitted := false
var interaction_locked := true
var dragged_item: Area2D
var dragged_item_id := ""
var drag_offset := Vector2.ZERO
var item_nodes: Dictionary = {}
var item_start_positions: Dictionary = {}
var item_original_z: Dictionary = {}
var investigated: Dictionary = {}
var history_ids: Array[String] = []
var inventory_icons: Dictionary = {}
var history_buttons: Array[Button] = []
var history_selection: TextureRect
var history_cursor: TextureRect
var selected_history_index := -1
var history_scroll_offset := 0
var hud_layer_node: CanvasLayer
var dialogue_context := ""
var active_closeup_item := ""
var all_required_announced := false
var all_items_announced := false
var hovered_item_id := ""
var shared_font: Font
var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var fail_screen: CanvasLayer


func _ready() -> void:
	randomize()
	shared_font = load(SHARED_FONT_PATH)
	for item_id: String in ITEM_ORDER:
		investigated[item_id] = false
	_setup_scene()
	_setup_audio()
	_setup_hud()
	_setup_fail_screen()
	_create_content_items()
	_position_content_items()
	_connect_interactions()
	dialogue.dialogue_finished.connect(_on_dialogue_finished)
	dialogue.choice_selected.connect(_on_dialogue_choice_selected)
	SharedCursor.install()
	_set_box_state(BoxState.CLOSED)
	_set_interactions_enabled(false)


func _process(_delta: float) -> void:
	if not gameplay_active or interaction_locked or dialogue.is_dialogue_active():
		return
	_update_hover_cursor()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if success_test_key_enabled and event.keycode == KEY_T:
			_close_box_and_finish()
			get_viewport().set_input_as_handled()
			return
		if fail_test_key_enabled and event.keycode == KEY_F:
			_show_failure_screen()
			get_viewport().set_input_as_handled()
			return
	if not gameplay_active or interaction_locked or dialogue.is_dialogue_active():
		return
	if dragged_item != null and event is InputEventMouseMotion:
		dragged_item.global_position = get_global_mouse_position() + drag_offset
		SharedCursor.set_dragging()
	if dragged_item != null and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_finish_drag()
			get_viewport().set_input_as_handled()


func _setup_scene() -> void:
	background.z_index = 0
	box_closed.z_index = 2
	box_open.z_index = 2
	box_contents.z_index = 5
	closeup_layer.layer = 80
	closeup_layer.visible = false
	dim_overlay.position = Vector2.ZERO
	dim_overlay.size = SCREEN_SIZE
	dim_overlay.color = Color(0.0, 0.0, 0.0, 0.76)
	closeup_sprite.position = SCREEN_CENTER
	closeup_sprite.scale = Vector2.ONE


func _setup_audio() -> void:
	music_player = _make_audio_player(MUSIC_PATH, -13.0)
	ambience_player = _make_audio_player(AMBIENCE_PATH, -25.0)


func _make_audio_player(path: String, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	player.volume_db = volume_db
	add_child(player)
	return player


func _play_background_audio() -> void:
	if music_player.stream != null and not music_player.playing:
		music_player.play()
	if ambience_player.stream != null and not ambience_player.playing:
		ambience_player.play()


func _stop_background_audio() -> void:
	music_player.stop()
	ambience_player.stop()


func _play_sound(file_name: String, volume_db := -6.0, pitch := 1.0) -> void:
	var path := SFX_ROOT + file_name
	if not ResourceLoader.exists(path):
		return
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


func _play_ui_sound(file_name: String, volume_db := -10.0) -> void:
	var path := UI_SFX_ROOT + file_name
	if not ResourceLoader.exists(path):
		return
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	player.volume_db = volume_db
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


func _setup_hud() -> void:
	hud_layer_node = CanvasLayer.new()
	hud_layer_node.name = "UnboxingHUD"
	hud_layer_node.layer = 40
	add_child(hud_layer_node)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer_node.add_child(root)

	var inventory_panel := _make_texture_rect(
		INVENTORY_PANEL_PATH, INVENTORY_PANEL_POSITION, Vector2(293.0, 350.0)
	)
	root.add_child(inventory_panel)
	for index: int in range(REQUIRED_IDS.size()):
		var item_id: String = REQUIRED_IDS[index]
		var icon := _make_texture_rect(
			str(ITEM_DATA[item_id]["inventory"]),
			INVENTORY_PANEL_POSITION + INVENTORY_ICON_POSITIONS[index],
			Vector2(48.0, 48.0)
		)
		icon.visible = false
		root.add_child(icon)
		inventory_icons[item_id] = icon

	var history_panel := _make_texture_rect(
		HISTORY_PANEL_PATH, HISTORY_PANEL_POSITION, Vector2(293.0, 350.0)
	)
	history_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	history_panel.gui_input.connect(_on_history_panel_input)
	root.add_child(history_panel)
	history_selection = _make_texture_rect(
		HISTORY_SELECTED_PATH,
		HISTORY_PANEL_POSITION + HISTORY_ROW_POSITIONS[0],
		Vector2(210.0, 40.0)
	)
	history_selection.visible = false
	root.add_child(history_selection)
	history_cursor = _make_texture_rect(
		HISTORY_CURSOR_PATH,
		HISTORY_PANEL_POSITION + HISTORY_CURSOR_POSITIONS[0],
		Vector2(48.0, 48.0)
	)
	history_cursor.visible = false
	root.add_child(history_cursor)

	for index: int in range(HISTORY_VISIBLE_ROWS):
		var button := Button.new()
		button.position = HISTORY_PANEL_POSITION + HISTORY_ROW_POSITIONS[index]
		button.size = Vector2(210.0, 31.5)
		button.flat = true
		button.visible = false
		button.focus_mode = Control.FOCUS_NONE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_override("font", shared_font)
		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_color_override("font_color", Color("f3d9a0"))
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_on_history_pressed.bind(index))
		button.mouse_entered.connect(_on_history_hovered.bind(index))
		root.add_child(button)
		history_buttons.append(button)


func _make_texture_rect(path: String, position: Vector2, size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = load(path)
	rect.position = position
	rect.size = size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _start_gameplay() -> void:
	gameplay_active = true
	interaction_locked = false
	_play_background_audio()
	_set_box_state(BoxState.CLOSED)
	_set_interactions_enabled(true)
	SharedCursor.set_normal()


func _show_failure_screen() -> void:
	if result_emitted:
		return
	gameplay_active = false
	interaction_locked = true
	_set_interactions_enabled(false)
	_hide_closeup(false)
	dialogue.clear()
	_stop_background_audio()
	_play_sound("sfx_failure_transition.wav")
	fail_screen.call(
		"start_fail_screen",
		"The box closed before its important memories were recovered.",
		"The required newspaper, family photo, and old key were not all found.",
		0,
		false,
	)


func _setup_fail_screen() -> void:
	fail_screen = FAIL_SCREEN_SCENE.instantiate() as CanvasLayer
	fail_screen.name = "MinigameFailScreen"
	add_child(fail_screen)
	fail_screen.retry_requested.connect(_on_fail_retry_requested)
	fail_screen.exit_requested.connect(_on_fail_exit_requested)


func _on_fail_retry_requested() -> void:
	if get_tree().current_scene == self:
		get_tree().reload_current_scene()
	else:
		minigame_retry_requested.emit()


func _on_fail_exit_requested() -> void:
	if result_emitted:
		return
	result_emitted = true
	minigame_failed.emit()


func _create_content_items() -> void:
	for item_id: String in ITEM_ORDER:
		var data: Dictionary = ITEM_DATA[item_id]
		var area := Area2D.new()
		area.name = item_id.to_pascal_case()
		area.input_pickable = true
		var sprite := Sprite2D.new()
		sprite.name = "Sprite2D"
		sprite.texture = load(str(data["texture"]))
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		area.add_child(sprite)
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape := RectangleShape2D.new()
		shape.size = data["collision"]
		collision.shape = shape
		area.add_child(collision)
		box_contents.add_child(area)
		area.input_event.connect(_on_item_input_event.bind(item_id))
		area.mouse_entered.connect(_on_item_mouse_entered.bind(item_id))
		area.mouse_exited.connect(_on_item_mouse_exited.bind(item_id))
		item_nodes[item_id] = area


func _position_content_items() -> void:
	var positions := [
		Vector2(576.0, 390.0), Vector2(506.0, 295.0), Vector2(641.0, 300.0),
		Vector2(491.0, 365.0), Vector2(661.0, 370.0), Vector2(541.0, 405.0),
		Vector2(616.0, 410.0),
	]
	var movable_positions: Array = positions.slice(1)
	movable_positions.shuffle()
	for index: int in range(ITEM_ORDER.size()):
		var item_id: String = ITEM_ORDER[index]
		var node: Area2D = item_nodes[item_id]
		var position: Vector2 = positions[0] if index == 0 else movable_positions[index - 1]
		if index > 0:
			position += Vector2(randf_range(-12.0, 12.0), randf_range(-10.0, 10.0))
		node.position = position
		node.z_index = 4 + index
		item_start_positions[item_id] = position
		item_original_z[item_id] = node.z_index


func _connect_interactions() -> void:
	box_click_area.input_event.connect(_on_box_input_event)
	box_click_area.mouse_entered.connect(_on_box_hovered)
	box_click_area.mouse_exited.connect(_on_interactable_exited)
	for area: Area2D in flap_areas:
		area.input_event.connect(_on_flap_input_event)
		area.mouse_entered.connect(_on_box_hovered)
		area.mouse_exited.connect(_on_interactable_exited)


func _on_box_input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if _can_interact() and _is_left_press(event) and box_state == BoxState.CLOSED:
		_open_box()


func _on_flap_input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if _can_interact() and _is_left_press(event) and box_state == BoxState.OPEN:
		_request_close_box()


func _on_item_input_event(
	_viewport: Node, event: InputEvent, _shape_index: int, item_id: String
) -> void:
	if not _can_interact() or box_state != BoxState.OPEN or investigated[item_id]:
		return
	if _is_left_press(event) and _is_topmost_item_at_mouse(item_id):
		_start_drag(item_id)


func _can_interact() -> bool:
	return gameplay_active and not interaction_locked and not dialogue.is_dialogue_active()


func _start_drag(item_id: String) -> void:
	dragged_item_id = item_id
	dragged_item = item_nodes[item_id]
	drag_offset = dragged_item.global_position - get_global_mouse_position()
	dragged_item.z_index = 60
	var sprite: Sprite2D = dragged_item.get_node("Sprite2D")
	sprite.scale = Vector2.ONE * drag_scale_multiplier
	_play_ui_sound("sfx_ui_click.wav", -14.0)
	_play_sound("sfx_item_pickup.wav", -12.0)
	_play_material_sound(item_id)
	SharedCursor.set_dragging()


func _finish_drag() -> void:
	if dragged_item == null:
		return
	var item_id := dragged_item_id
	var sprite: Sprite2D = dragged_item.get_node("Sprite2D")
	sprite.scale = Vector2.ONE
	if not BOX_INTERIOR.has_point(get_global_mouse_position()):
		_investigate_item(item_id)
	else:
		_return_item(item_id)
	dragged_item = null
	dragged_item_id = ""
	drag_offset = Vector2.ZERO
	SharedCursor.set_normal()


func _return_item(item_id: String) -> void:
	var node: Area2D = item_nodes[item_id]
	_set_area_enabled(node, false)
	_play_sound("sfx_item_return.wav", -9.0)
	var tween := create_tween()
	tween.tween_property(node, "position", item_start_positions[item_id], item_return_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func() -> void:
		node.z_index = int(item_original_z[item_id])
		if _can_interact() and box_state == BoxState.OPEN and not investigated[item_id]:
			_set_area_enabled(node, true)
	)


func _investigate_item(item_id: String) -> void:
	investigated[item_id] = true
	var node: Area2D = item_nodes[item_id]
	node.visible = false
	_set_area_enabled(node, false)
	history_ids.append(item_id)
	history_scroll_offset = maxi(0, history_ids.size() - HISTORY_VISIBLE_ROWS)
	_refresh_history()
	_set_history_selection(history_ids.size() - 1)
	if bool(ITEM_DATA[item_id]["required"]):
		(inventory_icons[item_id] as TextureRect).visible = true
		_play_sound("sfx_clue_discovered.wav", -5.0)
	interaction_locked = true
	_show_item_closeup(item_id)
	var lines: Array = [{
		"text": str(ITEM_DATA[item_id]["dialogue"]),
		"expression": str(ITEM_DATA[item_id]["expression"]),
		"character": "mc",
	}]
	if _all_required_found() and not all_required_announced:
		all_required_announced = true
		lines.append({
			"text": "These three feel important. I can close the box when I'm ready, but I may keep looking.",
			"expression": "happy",
		})
		_play_sound("sfx_all_clues_found.wav", -4.0)
	if _all_items_found() and not all_items_announced:
		all_items_announced = true
		lines.append({
			"text": "That's everything. I should clean this up and close the box.",
			"expression": "happy",
		})
	dialogue_context = "inspection"
	dialogue.play(lines)


func _show_item_closeup(item_id: String) -> void:
	active_closeup_item = item_id
	closeup_sprite.texture = load(str(ITEM_DATA[item_id]["closeup"]))
	closeup_sprite.modulate.a = 0.0
	closeup_sprite.scale = Vector2(0.88, 0.88)
	dim_overlay.color.a = 0.0
	closeup_layer.visible = true
	_play_sound("sfx_closeup_open.wav", -8.0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(dim_overlay, "color:a", 0.76, closeup_transition_duration)
	tween.tween_property(closeup_sprite, "modulate:a", 1.0, closeup_transition_duration)
	tween.tween_property(closeup_sprite, "scale", Vector2.ONE, closeup_transition_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _hide_closeup(animated := true) -> void:
	if not closeup_layer.visible:
		active_closeup_item = ""
		return
	if not animated:
		closeup_layer.visible = false
		active_closeup_item = ""
		return
	_play_sound("sfx_closeup_close.wav", -9.0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(dim_overlay, "color:a", 0.0, closeup_transition_duration)
	tween.tween_property(closeup_sprite, "modulate:a", 0.0, closeup_transition_duration)
	tween.finished.connect(func() -> void:
		closeup_layer.visible = false
		active_closeup_item = ""
	)


func _refresh_history() -> void:
	var maximum_offset := maxi(0, history_ids.size() - HISTORY_VISIBLE_ROWS)
	history_scroll_offset = clampi(history_scroll_offset, 0, maximum_offset)
	for row_index: int in range(history_buttons.size()):
		var button := history_buttons[row_index]
		var history_index := history_scroll_offset + row_index
		button.visible = history_index < history_ids.size()
		button.disabled = history_index >= history_ids.size()
		if history_index < history_ids.size():
			button.text = "  " + str(ITEM_DATA[history_ids[history_index]]["name"])
	_update_history_selection_position()


func _on_history_hovered(row_index: int) -> void:
	var history_index := history_scroll_offset + row_index
	if history_index < history_ids.size():
		_set_history_selection(history_index)
		_play_ui_sound("sfx_ui_hover.wav", -18.0)


func _on_history_pressed(row_index: int) -> void:
	var history_index := history_scroll_offset + row_index
	if not _can_interact() or history_index >= history_ids.size():
		return
	_set_history_selection(history_index)
	var item_id := history_ids[history_index]
	interaction_locked = true
	_show_item_closeup(item_id)
	dialogue_context = "history"
	_play_ui_sound("sfx_ui_click.wav", -12.0)
	dialogue.say(
		str(ITEM_DATA[item_id]["dialogue"]),
		str(ITEM_DATA[item_id]["expression"]),
		-1.0,
		"mc"
	)


func _set_history_selection(index: int) -> void:
	selected_history_index = index
	if index < history_scroll_offset:
		history_scroll_offset = index
	elif index >= history_scroll_offset + HISTORY_VISIBLE_ROWS:
		history_scroll_offset = index - HISTORY_VISIBLE_ROWS + 1
	_refresh_history()


func _update_history_selection_position() -> void:
	var visible_row := selected_history_index - history_scroll_offset
	var selection_is_visible := (
		selected_history_index >= 0
		and visible_row >= 0
		and visible_row < HISTORY_VISIBLE_ROWS
		and selected_history_index < history_ids.size()
	)
	history_selection.visible = selection_is_visible
	history_cursor.visible = selection_is_visible
	if not selection_is_visible:
		return
	history_selection.visible = true
	history_cursor.visible = true
	history_selection.position = HISTORY_PANEL_POSITION + HISTORY_ROW_POSITIONS[visible_row]
	history_cursor.position = HISTORY_PANEL_POSITION + HISTORY_CURSOR_POSITIONS[visible_row]


func _on_history_panel_input(event: InputEvent) -> void:
	if history_ids.size() <= HISTORY_VISIBLE_ROWS:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			history_scroll_offset -= 1
			_refresh_history()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			history_scroll_offset += 1
			_refresh_history()
			get_viewport().set_input_as_handled()


func _request_close_box() -> void:
	interaction_locked = true
	if not _all_required_found():
		dialogue_context = "close_reminder"
		dialogue.say_random(PREMATURE_CLOSE_DIALOGUE, "concerned", -1.0, "mc")
		return
	dialogue_context = "close_choice"
	var prompt := "That's everything. Should I clean this up and close the box?" if _all_items_found() else "I found what I needed. Is that all I want from this box?"
	var keep_text := "Review memories" if _all_items_found() else "Keep looking"
	dialogue.ask(prompt, [
		{"id": "keep_looking", "text": keep_text},
		{"id": "close_box", "text": "Close the box"},
	], "concerned", "mc")


func _on_dialogue_choice_selected(choice_id: String, _index: int, _text: String) -> void:
	if dialogue_context != "close_choice":
		return
	dialogue_context = ""
	if choice_id == "close_box":
		_close_box_and_finish()
	else:
		interaction_locked = false
		_set_interactions_enabled(true)


func _on_dialogue_finished() -> void:
	var finished_context := dialogue_context
	dialogue_context = ""
	if finished_context == "inspection" or finished_context == "history":
		_hide_closeup()
	if finished_context != "close_choice" and gameplay_active:
		interaction_locked = false
		_set_interactions_enabled(true)


func _open_box() -> void:
	_play_ui_sound("sfx_ui_click.wav", -14.0)
	_play_sound("sfx_box_open.wav", -5.0)
	_play_sound("sfx_cardboard_rustle.wav", -14.0, randf_range(0.96, 1.04))
	_set_box_state(BoxState.OPEN)
	_pulse_sprite(box_open)


func _close_box_and_finish() -> void:
	if result_emitted:
		return
	gameplay_active = false
	interaction_locked = true
	_set_interactions_enabled(false)
	_hide_closeup(false)
	_play_ui_sound("sfx_ui_click.wav", -14.0)
	_play_sound("sfx_box_close.wav", -5.0)
	_play_sound("sfx_cardboard_rustle.wav", -14.0, randf_range(0.96, 1.04))
	_set_box_state(BoxState.CLOSED)
	_pulse_sprite(box_closed)
	_play_sound("sfx_success_transition.wav", -4.0)
	_stop_background_audio()
	result_emitted = true
	$CollectibleEnding.play()


func _set_box_state(new_state: BoxState) -> void:
	box_state = new_state
	box_closed.visible = box_state == BoxState.CLOSED
	box_open.visible = box_state == BoxState.OPEN
	box_contents.visible = box_state == BoxState.OPEN
	_set_interactions_enabled(gameplay_active and not interaction_locked)


func _set_interactions_enabled(enabled: bool) -> void:
	_set_area_enabled(box_click_area, enabled and box_state == BoxState.CLOSED)
	for area: Area2D in flap_areas:
		_set_area_enabled(area, enabled and box_state == BoxState.OPEN)
	for item_id: String in ITEM_ORDER:
		_set_area_enabled(
			item_nodes.get(item_id) as Area2D,
			enabled and box_state == BoxState.OPEN and not bool(investigated[item_id])
		)


func _set_area_enabled(area: Area2D, enabled: bool) -> void:
	if area == null:
		return
	area.input_pickable = enabled
	area.monitoring = enabled
	area.monitorable = enabled
	for child: Node in area.get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", not enabled)


func _all_required_found() -> bool:
	for item_id: String in REQUIRED_IDS:
		if not bool(investigated[item_id]):
			return false
	return true


func _all_items_found() -> bool:
	return history_ids.size() == ITEM_ORDER.size()


func _is_topmost_item_at_mouse(item_id: String) -> bool:
	var mouse := get_global_mouse_position()
	var top_id := ""
	var top_z := -9999
	for check_id: String in ITEM_ORDER:
		if investigated[check_id]:
			continue
		var node: Area2D = item_nodes[check_id]
		if not node.visible or not _point_inside_item(node, mouse):
			continue
		if node.z_index > top_z:
			top_z = node.z_index
			top_id = check_id
	return top_id == item_id


func _point_inside_item(node: Area2D, point: Vector2) -> bool:
	var collision: CollisionShape2D = node.get_node("CollisionShape2D")
	var shape := collision.shape as RectangleShape2D
	if shape == null:
		return false
	return Rect2(-shape.size * 0.5, shape.size).has_point(node.to_local(point))


func _on_item_mouse_entered(item_id: String) -> void:
	if _can_interact() and box_state == BoxState.OPEN and not investigated[item_id]:
		hovered_item_id = item_id
		var sprite: Sprite2D = (item_nodes[item_id] as Area2D).get_node("Sprite2D")
		sprite.scale = Vector2.ONE * hover_scale_multiplier
		SharedCursor.set_grab()


func _on_item_mouse_exited(item_id: String) -> void:
	if dragged_item_id == item_id:
		return
	if item_nodes.has(item_id):
		var sprite: Sprite2D = (item_nodes[item_id] as Area2D).get_node("Sprite2D")
		sprite.scale = Vector2.ONE
	if hovered_item_id == item_id:
		hovered_item_id = ""
		SharedCursor.set_normal()


func _on_box_hovered() -> void:
	if _can_interact():
		SharedCursor.set_pointer()


func _on_interactable_exited() -> void:
	if dragged_item == null:
		SharedCursor.set_normal()


func _update_hover_cursor() -> void:
	if dragged_item != null:
		SharedCursor.set_dragging()
	elif hovered_item_id != "" and not investigated[hovered_item_id]:
		SharedCursor.set_grab()


func _play_material_sound(item_id: String) -> void:
	match str(ITEM_DATA[item_id]["material"]):
		"metal":
			_play_sound("sfx_metal_pickup.wav", -8.0)
		"ceramic":
			_play_sound("sfx_ceramic_pickup.wav", -8.0)
		_:
			var sound := "sfx_paper_pickup_01.wav" if randi() % 2 == 0 else "sfx_paper_pickup_02.wav"
			_play_sound(sound, -9.0)


func _pulse_sprite(sprite: Sprite2D) -> void:
	var base_scale := Vector2(0.6, 0.6)
	sprite.scale = base_scale * 0.97
	create_tween().tween_property(sprite, "scale", base_scale, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _is_left_press(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
