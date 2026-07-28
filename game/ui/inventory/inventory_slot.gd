extends Button

var slot_index := -1
var inventory_ui: Control
var compact := false
var item_id := ""
var _dragged_item_id := ""

var icon_rect: TextureRect
var quantity_label: Label
var number_label: Label


func configure(owner_ui: Control, index: int, is_compact: bool = false) -> void:
	inventory_ui = owner_ui
	slot_index = index
	compact = is_compact
	name = "InventorySlot%d" % index
	custom_minimum_size = Vector2(54, 54) if compact else Vector2(58, 58)
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pressed.connect(_on_pressed)

	icon_rect = TextureRect.new()
	icon_rect.name = "ItemIcon"
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_rect.offset_left = 5.0
	icon_rect.offset_top = 5.0
	icon_rect.offset_right = -5.0
	icon_rect.offset_bottom = -5.0
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_rect)

	quantity_label = Label.new()
	quantity_label.name = "Quantity"
	quantity_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	quantity_label.position = Vector2(-27, -23)
	quantity_label.size = Vector2(23, 19)
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	quantity_label.add_theme_font_size_override("font_size", 15)
	quantity_label.add_theme_color_override("font_color", Color("fff1c7"))
	quantity_label.add_theme_color_override("font_shadow_color", Color("32190c"))
	quantity_label.add_theme_constant_override("shadow_offset_x", 2)
	quantity_label.add_theme_constant_override("shadow_offset_y", 2)
	quantity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(quantity_label)

	number_label = Label.new()
	number_label.name = "HotbarNumber"
	number_label.position = Vector2(4, 1)
	number_label.size = Vector2(18, 17)
	number_label.add_theme_font_size_override("font_size", 11)
	number_label.add_theme_color_override("font_color", Color("d2a96a"))
	number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number_label.visible = slot_index < GameState.HOTBAR_SIZE
	number_label.text = str(slot_index + 1) if slot_index < GameState.HOTBAR_SIZE else ""
	add_child(number_label)

	refresh()


func refresh() -> void:
	if inventory_ui == null:
		return
	var slot := GameState.get_inventory_slot(slot_index)
	item_id = str(slot.get("item_id", ""))
	var quantity := int(slot.get("quantity", 0))
	var definition := GameState.get_item_definition(item_id) if not item_id.is_empty() else {}
	var icon_path := str(definition.get("icon", ""))
	icon_rect.texture = load(icon_path) as Texture2D if not icon_path.is_empty() else null
	quantity_label.text = str(quantity) if quantity > 1 else ""
	tooltip_text = (
		"%s\n%s" % [
			str(slot.get("display_name", definition.get("display_name", item_id.capitalize()))),
			str(definition.get("category", "Item")),
		]
		if not item_id.is_empty()
		else "Empty slot"
	)
	disabled = false
	if inventory_ui.has_method("style_inventory_slot"):
		inventory_ui.style_inventory_slot(self, slot_index)


func _on_pressed() -> void:
	if inventory_ui != null and inventory_ui.has_method("inventory_slot_pressed"):
		inventory_ui.inventory_slot_pressed(slot_index)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_id.is_empty() or inventory_ui == null:
		return null
	_dragged_item_id = item_id
	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(76, 76)
	preview.texture = icon_rect.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.modulate = Color(1.1, 1.05, 0.9, 0.92)
	set_drag_preview(preview)
	if inventory_ui.has_method("inventory_drag_started"):
		inventory_ui.inventory_drag_started(item_id)
	return {
		"type": "inventory_item",
		"slot_index": slot_index,
		"item_id": item_id,
	}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return (
		data is Dictionary
		and str((data as Dictionary).get("type", "")) == "inventory_item"
	)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if inventory_ui == null or not data is Dictionary:
		return
	inventory_ui.swap_inventory_slots(int((data as Dictionary).get("slot_index", -1)), slot_index)


func _notification(what: int) -> void:
	if what != NOTIFICATION_DRAG_END or _dragged_item_id.is_empty():
		return
	if inventory_ui != null and inventory_ui.has_method("inventory_drag_ended"):
		inventory_ui.inventory_drag_ended(
			_dragged_item_id,
			get_viewport().get_mouse_position(),
			get_viewport().gui_is_drag_successful(),
		)
	_dragged_item_id = ""
