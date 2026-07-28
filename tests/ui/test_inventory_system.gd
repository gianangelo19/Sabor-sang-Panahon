extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.autosave_enabled = false
	game_state.reset()

	_check(game_state.inventory_slots.size() == 27, "Inventory initializes 27 slots")
	_check(game_state.selected_inventory_slot == 0, "The first hotbar slot is selected by default")
	_check(
		game_state.inventory_slots.all(func(slot: Dictionary): return slot.is_empty()),
		"Inventory starts empty",
	)

	_check(
		game_state.collect_ingredient("pork_and_liver", "Pork and Liver"),
		"Collected ingredients enter story state",
	)
	var first_slot: Dictionary = game_state.get_inventory_slot(0)
	_check(first_slot.get("item_id", "") == "pork_and_liver", "Collected ingredients enter the inventory")
	_check(int(first_slot.get("quantity", 0)) == 1, "A collected ingredient starts with quantity one")
	_check(
		not game_state.collect_ingredient("pork_and_liver", "Pork and Liver"),
		"Duplicate story rewards are rejected",
	)
	_check(
		int(game_state.get_inventory_slot(0).get("quantity", 0)) == 1,
		"Rejected duplicate rewards do not duplicate inventory items",
	)

	game_state.add_inventory_item("empty_aged_jar", "Empty Jar", 2)
	_check(
		int(game_state.get_inventory_slot(1).get("quantity", 0)) == 2,
		"Stackable collected items retain their quantity",
	)
	game_state.swap_inventory_slots(0, 1)
	_check(
		game_state.get_inventory_slot(0).get("item_id", "") == "empty_aged_jar",
		"Inventory slots can be rearranged",
	)
	game_state.select_inventory_slot(1)
	_check(
		game_state.get_selected_inventory_slot().get("item_id", "") == "pork_and_liver",
		"Hotbar selection resolves the held item",
	)
	var original_save_path: String = game_state.save_file_path
	var inventory_save_path := "user://codex_inventory_test_save.json"
	game_state.save_file_path = inventory_save_path
	var absolute_save_path := ProjectSettings.globalize_path(inventory_save_path)
	if FileAccess.file_exists(inventory_save_path):
		DirAccess.remove_absolute(absolute_save_path)
	_check(game_state.save_game(), "Inventory can be written into the game save")
	game_state.reset()
	_check(not game_state.load_game().is_empty(), "Inventory save can be loaded")
	game_state.autosave_enabled = false
	_check(
		game_state.get_inventory_slot(0).get("item_id", "") == "empty_aged_jar",
		"Save data restores rearranged inventory slots",
	)
	_check(game_state.selected_inventory_slot == 1, "Save data restores hotbar selection")
	DirAccess.remove_absolute(absolute_save_path)
	game_state.save_file_path = original_save_path
	game_state.add_clue("Damaged newspaper")
	game_state.push_ambot_notification(
		"newspaper_scan",
		"Damaged article detected",
		"I can scan the surviving text.",
	)

	var hud_scene := load("res://game/ui/hud/game_hud.tscn") as PackedScene
	_check(hud_scene != null, "HUD with inventory loads")
	if hud_scene == null:
		_finish()
		return
	var hud := hud_scene.instantiate()
	root.add_child(hud)
	await process_frame

	var inventory := hud.get_node("InventoryUI")
	var phone := hud.get_node("PhoneUI")
	_check(inventory.hotbar_slots.size() == 9, "HUD creates nine quick-access slots")
	_check(inventory.backpack_slots.size() == 27, "Backpack displays every inventory slot")
	_check(inventory.hotbar_panel.visible, "Hotbar is visible during regular play")
	_check(not inventory.backpack_panel.visible, "Backpack starts closed")
	_check(inventory.held_root.visible, "Selecting a filled hotbar slot shows a held item")
	_check(inventory.held_icon.texture != null, "Held item uses its inventory artwork")
	_check(hud.objective_panel.visible, "Objective HUD is visible during regular play")
	_check(phone.notification_banner.visible, "AMBot notification is visible during regular play")

	phone.open_phone()
	await process_frame
	_check(phone.phone_open, "E phone state can open")
	_check(inventory.backpack_panel.visible, "Opening the phone opens the backpack")
	_check(inventory.scan_target.visible, "Open inventory marks the phone as an AMBot drop target")
	_check(not inventory.hotbar_panel.visible, "Expanded inventory replaces the regular hotbar")
	_check(not hud.objective_panel.visible, "Open inventory hides the objective HUD")
	_check(not phone.notification_banner.visible, "Open inventory hides the AMBot notification banner")

	var phone_center: Vector2 = phone.phone_frame.get_global_rect().get_center()
	inventory.inventory_drag_ended("pork_and_liver", phone_center, false)
	_check(phone.current_app == "ambot", "Dropping an item on the phone opens AMBot")
	_check(
		phone.current_situation == "inventory_scan_pork_and_liver",
		"AMBot tracks which inventory item was scanned",
	)
	_check(phone.ambot_typing_active, "AMBot types its item analysis")
	phone._finish_ambot_typing()
	_check(
		phone.screen_stack.get_child_count() >= 3,
		"AMBot provides item information and a completed-scan action",
	)

	phone.close_phone()
	await process_frame
	_check(not inventory.backpack_panel.visible, "Closing the phone closes the backpack")
	_check(inventory.hotbar_panel.visible, "Closing the inventory restores the hotbar")
	_check(hud.objective_panel.visible, "Closing inventory restores the objective HUD")
	_check(phone.notification_banner.visible, "Closing inventory restores unread AMBot notifications")

	var wheel_down := InputEventMouseButton.new()
	wheel_down.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel_down.pressed = true
	var selected_before: int = game_state.selected_inventory_slot
	inventory._unhandled_input(wheel_down)
	_check(
		game_state.selected_inventory_slot == posmod(selected_before + 1, 9),
		"Mouse wheel cycles the quick-access slots",
	)

	var number_key := InputEventKey.new()
	number_key.physical_keycode = KEY_1
	number_key.pressed = true
	inventory._unhandled_input(number_key)
	_check(game_state.selected_inventory_slot == 0, "Number keys select their matching hotbar slot")

	hud.queue_free()
	await process_frame
	game_state.reset()
	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	if failures.is_empty():
		print("Inventory system verification passed.")
		quit(0)
	else:
		print("Inventory system verification failed: " + ", ".join(failures))
		quit(1)
