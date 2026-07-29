extends Control

const INVENTORY_SLOT_SCRIPT := preload("res://game/ui/inventory/inventory_slot.gd")

const LEATHER_DARK := Color("2c160e")
const LEATHER := Color("6b3820")
const LEATHER_LIGHT := Color("9b5d2f")
const CANVAS := Color("c89252")
const STITCH := Color("f0c879")
const INK := Color("2b180f")
const CREAM := Color("fff0c7")
const SELECTED := Color("ffd36a")

var backpack_open := false
var phone_ui: Control
var hotbar_panel: PanelContainer
var hotbar_row: HBoxContainer
var backpack_panel: PanelContainer
var backpack_slots: Array[Button] = []
var hotbar_slots: Array[Button] = []
var scan_target: PanelContainer
var held_root: Control
var held_icon: TextureRect
var _drag_item_id := ""
var _idle_time := 0.0
var _dialogue_hud_tween: Tween
var _prepared_texture_cache: Dictionary = {}
var _hovered_item_slot := -1
var _scan_target_requested := false
var _scan_target_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_interface()
	GameState.inventory_changed.connect(_refresh_inventory)
	GameState.selected_inventory_slot_changed.connect(_on_selected_slot_changed)
	phone_ui = get_parent().get_node_or_null("PhoneUI") as Control
	if phone_ui != null and phone_ui.has_signal("open_state_changed"):
		phone_ui.open_state_changed.connect(_on_phone_open_state_changed)
	_on_phone_open_state_changed(phone_ui != null and bool(phone_ui.get("phone_open")))
	_refresh_inventory()


func _unhandled_input(event: InputEvent) -> void:
	if (
		get_tree().paused
		or backpack_open
		or (phone_ui != null and bool(phone_ui.get("phone_open")))
	):
		return

	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_select_relative_slot(-1)
			get_viewport().set_input_as_handled()
			return
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_select_relative_slot(1)
			get_viewport().set_input_as_handled()
			return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		var pressed_key := key_event.physical_keycode
		if pressed_key == 0:
			pressed_key = key_event.keycode
		if pressed_key >= KEY_1 and pressed_key <= KEY_9:
			GameState.select_inventory_slot(pressed_key - KEY_1)
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_idle_time += delta
	if held_root.visible:
		var held_sway := sin(_idle_time * 1.8)
		var held_vertical := absf(sin(_idle_time * 0.95))
		held_icon.position = Vector2(held_sway * 4.0, held_vertical * 2.5)
		held_icon.rotation = deg_to_rad(held_sway * 1.2)


func _build_interface() -> void:
	_build_hotbar()
	_build_backpack()
	_build_phone_scan_target()
	_build_held_item()


func _build_hotbar() -> void:
	hotbar_panel = PanelContainer.new()
	hotbar_panel.name = "Hotbar"
	hotbar_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hotbar_panel.position = Vector2(-276, -83)
	hotbar_panel.custom_minimum_size = Vector2(552, 66)
	hotbar_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	hotbar_panel.add_theme_stylebox_override("panel", _style(Color("20120bd9"), LEATHER_LIGHT, 2, 7, 6))
	add_child(hotbar_panel)

	hotbar_row = HBoxContainer.new()
	hotbar_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hotbar_row.add_theme_constant_override("separation", 5)
	hotbar_panel.add_child(hotbar_row)
	for index in range(GameState.HOTBAR_SIZE):
		var slot := INVENTORY_SLOT_SCRIPT.new() as Button
		hotbar_row.add_child(slot)
		slot.configure(self, index, true)
		hotbar_slots.append(slot)

func _build_backpack() -> void:
	backpack_panel = PanelContainer.new()
	backpack_panel.name = "BackpackInventory"
	backpack_panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	backpack_panel.position = Vector2(22, -205)
	backpack_panel.custom_minimum_size = Vector2(618, 410)
	backpack_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	backpack_panel.add_theme_stylebox_override("panel", _style(LEATHER, LEATHER_DARK, 5, 26, 14))
	add_child(backpack_panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 7)
	backpack_panel.add_child(outer)

	var flap := PanelContainer.new()
	flap.custom_minimum_size.y = 65
	flap.add_theme_stylebox_override("panel", _style(LEATHER_LIGHT, STITCH, 2, 20, 10))
	outer.add_child(flap)
	var flap_row := HBoxContainer.new()
	flap_row.add_theme_constant_override("separation", 10)
	flap.add_child(flap_row)
	var title := Label.new()
	title.text = "BACKPACK"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", CREAM)
	flap_row.add_child(title)
	var close_hint := Label.new()
	close_hint.text = "[ E ] CLOSE"
	close_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	close_hint.add_theme_font_size_override("font_size", 13)
	close_hint.add_theme_color_override("font_color", STITCH)
	flap_row.add_child(close_hint)

	var lining := PanelContainer.new()
	lining.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lining.add_theme_stylebox_override("panel", _style(CANVAS, LEATHER_DARK, 3, 12, 12))
	outer.add_child(lining)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 5)
	lining.add_child(contents)

	var scan_help := Label.new()
	scan_help.text = "Drag an item onto the phone → AMBot will identify it"
	scan_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scan_help.add_theme_font_size_override("font_size", 14)
	scan_help.add_theme_color_override("font_color", INK)
	contents.add_child(scan_help)

	var storage_label := Label.new()
	storage_label.text = "MAIN POCKET"
	storage_label.add_theme_font_size_override("font_size", 14)
	storage_label.add_theme_color_override("font_color", INK)
	contents.add_child(storage_label)
	var storage_grid := GridContainer.new()
	storage_grid.columns = 9
	storage_grid.add_theme_constant_override("h_separation", 4)
	storage_grid.add_theme_constant_override("v_separation", 4)
	contents.add_child(storage_grid)
	for index in range(GameState.HOTBAR_SIZE, GameState.INVENTORY_SIZE):
		_add_backpack_slot(storage_grid, index)

	var quick_label := Label.new()
	quick_label.text = "QUICK ACCESS • NUMBER KEYS 1–9 / MOUSE WHEEL"
	quick_label.add_theme_font_size_override("font_size", 13)
	quick_label.add_theme_color_override("font_color", INK)
	contents.add_child(quick_label)
	var quick_grid := GridContainer.new()
	quick_grid.columns = 9
	quick_grid.add_theme_constant_override("h_separation", 4)
	contents.add_child(quick_grid)
	for index in range(GameState.HOTBAR_SIZE):
		_add_backpack_slot(quick_grid, index)


func _add_backpack_slot(parent: GridContainer, index: int) -> void:
	var slot := INVENTORY_SLOT_SCRIPT.new() as Button
	parent.add_child(slot)
	slot.configure(self, index, false)
	backpack_slots.append(slot)


func _build_phone_scan_target() -> void:
	scan_target = PanelContainer.new()
	scan_target.name = "AMBotDropTarget"
	scan_target.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	scan_target.position = Vector2(-337, -326)
	scan_target.custom_minimum_size = Vector2(326, 652)
	scan_target.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scan_target.add_theme_stylebox_override("panel", _style(Color("10243818"), Color("ffd36ad9"), 3, 28, 7))
	scan_target.visible = false
	scan_target.modulate.a = 0.0
	add_child(scan_target)
	var target_label := Label.new()
	target_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	target_label.position = Vector2(20, -45)
	target_label.size = Vector2(286, 34)
	target_label.text = "DROP ITEM HERE • AMBot SCAN"
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	target_label.add_theme_font_size_override("font_size", 13)
	target_label.add_theme_color_override("font_color", SELECTED)
	target_label.add_theme_stylebox_override("normal", _style(Color("102438e8"), SELECTED, 1, 8, 5))
	target_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scan_target.add_child(target_label)


func _build_held_item() -> void:
	held_root = Control.new()
	held_root.name = "HeldItem"
	held_root.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	held_root.position = Vector2(-250, -250)
	held_root.size = Vector2(280, 280)
	held_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(held_root)

	held_icon = TextureRect.new()
	held_icon.position = Vector2.ZERO
	held_icon.size = held_root.size
	held_icon.pivot_offset = Vector2(held_icon.size.x * 0.76, held_icon.size.y * 0.92)
	held_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	held_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	held_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	held_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	held_root.add_child(held_icon)


func _refresh_inventory() -> void:
	for slot in hotbar_slots:
		slot.refresh()
	for slot in backpack_slots:
		slot.refresh()
	_refresh_selected_item()


func _on_selected_slot_changed(_slot_index: int) -> void:
	_refresh_inventory()


func _refresh_selected_item() -> void:
	var selected := GameState.get_selected_inventory_slot()
	var item_id := str(selected.get("item_id", ""))
	var definition := GameState.get_item_definition(item_id) if not item_id.is_empty() else {}
	var display_name := str(selected.get("display_name", definition.get("display_name", "")))
	var icon_path := str(definition.get("icon", ""))
	var texture := load(icon_path) as Texture2D if not icon_path.is_empty() else null
	held_icon.texture = prepare_item_texture(texture)
	held_icon.tooltip_text = display_name
	held_root.visible = not backpack_open and not item_id.is_empty()
	for slot in hotbar_slots:
		style_inventory_slot(slot, slot.slot_index)
	for slot in backpack_slots:
		style_inventory_slot(slot, slot.slot_index)


func style_inventory_slot(slot: Button, slot_index: int) -> void:
	var selected := slot_index == GameState.selected_inventory_slot
	var fill := Color("3b2417ee") if not selected else Color("75481fff")
	var border := Color("9c6a39") if not selected else SELECTED
	var width := 1 if not selected else 3
	slot.add_theme_stylebox_override("normal", _style(fill, border, width, 5, 3))
	slot.add_theme_stylebox_override("hover", _style(Color("614025"), STITCH, 2, 5, 3))
	slot.add_theme_stylebox_override("pressed", _style(Color("2b190f"), SELECTED, 2, 5, 3))


func inventory_slot_pressed(slot_index: int) -> void:
	if slot_index < GameState.HOTBAR_SIZE:
		GameState.select_inventory_slot(slot_index)


func swap_inventory_slots(first_index: int, second_index: int) -> void:
	GameState.swap_inventory_slots(first_index, second_index)


func inventory_drag_started(item_id: String) -> void:
	_drag_item_id = item_id
	_set_scan_target_active(true)


func inventory_drag_ended(item_id: String, mouse_position: Vector2, drag_succeeded: bool) -> void:
	_drag_item_id = ""
	_hovered_item_slot = -1
	_set_scan_target_active(false)
	if drag_succeeded or phone_ui == null or not backpack_open:
		return
	if (
		phone_ui.has_method("is_point_over_phone")
		and phone_ui.is_point_over_phone(mouse_position)
		and phone_ui.has_method("analyze_inventory_item")
	):
		phone_ui.analyze_inventory_item(item_id)


func inventory_item_hover_changed(
	slot_index: int,
	item_id: String,
	hovered: bool,
) -> void:
	if hovered and not item_id.is_empty():
		_hovered_item_slot = slot_index
		_set_scan_target_active(true)
	elif _hovered_item_slot == slot_index:
		_hovered_item_slot = -1
		if _drag_item_id.is_empty():
			_set_scan_target_active(false)


func _on_phone_open_state_changed(is_open: bool) -> void:
	backpack_open = is_open
	backpack_panel.visible = backpack_open
	hotbar_panel.visible = not backpack_open
	if not backpack_open:
		_hovered_item_slot = -1
		_drag_item_id = ""
	_set_scan_target_active(
		backpack_open
			and (_hovered_item_slot >= 0 or not _drag_item_id.is_empty())
	)
	_refresh_selected_item()


func _set_scan_target_active(active: bool) -> void:
	_scan_target_requested = active and backpack_open
	if _scan_target_tween != null and _scan_target_tween.is_valid():
		_scan_target_tween.kill()
	if _scan_target_requested:
		scan_target.visible = true
		_scan_target_tween = create_tween()
		_scan_target_tween.set_trans(Tween.TRANS_SINE)
		_scan_target_tween.set_ease(Tween.EASE_OUT)
		_scan_target_tween.tween_property(scan_target, "modulate:a", 1.0, 0.18)
	elif scan_target.visible:
		_scan_target_tween = create_tween()
		_scan_target_tween.set_trans(Tween.TRANS_SINE)
		_scan_target_tween.set_ease(Tween.EASE_IN)
		_scan_target_tween.tween_property(scan_target, "modulate:a", 0.0, 0.18)
		_scan_target_tween.tween_callback(func():
			if not _scan_target_requested:
				scan_target.visible = false
		)


func set_dialogue_hud_hidden(hidden: bool, duration: float = 0.24) -> void:
	if _dialogue_hud_tween != null and _dialogue_hud_tween.is_valid():
		_dialogue_hud_tween.kill()
	_dialogue_hud_tween = create_tween()
	_dialogue_hud_tween.set_trans(Tween.TRANS_SINE)
	_dialogue_hud_tween.set_ease(Tween.EASE_IN_OUT)
	_dialogue_hud_tween.tween_property(
		self,
		"modulate:a",
		0.0 if hidden else 1.0,
		maxf(duration, 0.0),
	)


func _select_relative_slot(direction: int) -> void:
	var next_slot := posmod(GameState.selected_inventory_slot + direction, GameState.HOTBAR_SIZE)
	GameState.select_inventory_slot(next_slot)


func prepare_item_texture(texture: Texture2D) -> Texture2D:
	if texture == null:
		return null
	var cache_key := texture.resource_path
	if not cache_key.is_empty() and _prepared_texture_cache.has(cache_key):
		return _prepared_texture_cache[cache_key] as Texture2D
	var image := texture.get_image()
	if image == null or image.is_empty():
		return texture
	if image.is_compressed() and image.decompress() != OK:
		return texture
	var used_rect := image.get_used_rect()
	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		return texture
	var padding := maxi(used_rect.size.x, used_rect.size.y) / 24
	used_rect = used_rect.grow(padding).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var prepared := ImageTexture.create_from_image(image.get_region(used_rect))
	if not cache_key.is_empty():
		_prepared_texture_cache[cache_key] = prepared
	return prepared


func _style(fill: Color, border: Color, border_width: int, radius: int, margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style
