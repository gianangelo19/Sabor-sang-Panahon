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
	var collect_audio := game_state.get_node_or_null("ItemCollectAudio") as AudioStreamPlayer
	_check(
		collect_audio != null
			and collect_audio.stream.resource_path.ends_with("sfx_collectible_pickup.wav"),
		"Inventory uses the collectible pickup sound",
	)
	_check(collect_audio != null and collect_audio.playing, "Receiving an item plays the collect-item audio")
	var first_slot: Dictionary = game_state.get_inventory_slot(0)
	_check(first_slot.get("item_id", "") == "pork_and_liver", "Collected ingredients enter the inventory")
	_check(int(first_slot.get("quantity", 0)) == 1, "A collected ingredient starts with quantity one")
	_check(
		not game_state.collect_ingredient("pork_and_liver", "Pork and Liver"),
		"Duplicate story rewards are rejected",
	)
	var meat_scan_text := str(
		game_state.get_item_definition("pork_and_liver").get("ambot", "")
	)
	_check(
		not meat_scan_text.to_lower().contains("batchoy"),
		"The pork-and-liver AMBot scan does not reveal the dish name",
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
	game_state.set_story_flag("milk_released_crank")
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
	_check(
		game_state.has_story_flag("milk_released_crank"),
		"Save data restores story-item progression gates",
	)
	DirAccess.remove_absolute(absolute_save_path)
	game_state.save_file_path = original_save_path
	game_state.add_clue("Damaged newspaper")
	game_state.set_tutorial_step(6)
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
	_check(not hud.objective_panel.visible, "Standalone objective HUD stays hidden during regular play")
	_check(
		phone.notification_banner.visible
		and phone.notification_banner.text == "You have a new notification!"
		and phone.notification_banner.icon != null,
		"The AMBot update uses the generic icon notification",
	)

	var dialogue := (
		load("res://game/ui/dialogue/dialogue_ui.tscn") as PackedScene
	).instantiate()
	root.add_child(dialogue)
	dialogue.start_conversation([
		{
			"speaker": "You",
			"text": "The gameplay HUD should fade away during this line.",
			"portrait": null,
		},
	])
	await create_timer(0.3).timeout
	_check(
		is_zero_approx(hud.get_node("HUDRoot").modulate.a),
		"Dialogue fades out the gameplay notification HUD",
	)
	_check(
		is_zero_approx(inventory.modulate.a),
		"Dialogue fades out the hotbar and held item",
	)
	_check(
		not phone.notification_banner.visible,
		"Dialogue fades out the unified notification banner",
	)
	dialogue._cancel_typewriter()
	dialogue.current_line = dialogue.dialogue_lines.size()
	dialogue.show_current_line()
	await create_timer(0.3).timeout
	_check(
		is_equal_approx(hud.get_node("HUDRoot").modulate.a, 1.0),
		"Gameplay HUD fades back in after dialogue",
	)
	_check(
		is_equal_approx(inventory.modulate.a, 1.0),
		"Hotbar and held item fade back in after dialogue",
	)
	_check(
		phone.notification_banner.visible
			and is_equal_approx(phone.notification_banner.modulate.a, 1.0),
		"Unread notification fades back in after dialogue",
	)

	phone.open_phone()
	await process_frame
	_check(phone.phone_open, "E phone state can open")
	_check(inventory.backpack_panel.visible, "Opening the phone opens the backpack")
	_check(not inventory.scan_target.visible, "AMBot drop target stays hidden until an item is approached")
	_check(not inventory.hotbar_panel.visible, "Expanded inventory replaces the regular hotbar")
	_check(not hud.objective_panel.visible, "Open inventory keeps the old objective HUD hidden")
	_check(not phone.notification_banner.visible, "Open inventory hides the unified notification banner")

	inventory.inventory_item_hover_changed(1, "pork_and_liver", true)
	await create_timer(0.22).timeout
	_check(
		inventory.scan_target.visible
			and is_equal_approx(inventory.scan_target.modulate.a, 1.0),
		"Hovering a filled slot fades in the AMBot drop target",
	)
	inventory.inventory_item_hover_changed(1, "pork_and_liver", false)
	await create_timer(0.22).timeout
	_check(
		not inventory.scan_target.visible,
		"Leaving an item fades out the AMBot drop target",
	)
	inventory.inventory_drag_started("pork_and_liver")
	await create_timer(0.22).timeout
	_check(
		inventory.scan_target.visible
			and is_equal_approx(inventory.scan_target.modulate.a, 1.0),
		"Dragging an item fades in the AMBot drop target",
	)
	game_state.unlock_destination("market_vendor_2")
	game_state.select_destination("market_vendor_2")
	_check(
		not game_state.has_seen_active_destination_in_maps(),
		"The next marker stays hidden before AMBot finishes the item scan",
	)
	var phone_center: Vector2 = phone.phone_frame.get_global_rect().get_center()
	inventory.inventory_drag_ended("pork_and_liver", phone_center, false)
	_check(phone.current_app == "ambot", "Dropping an item on the phone opens AMBot")
	_check(
		phone.current_situation == "inventory_scan_pork_and_liver",
		"AMBot tracks which inventory item was scanned",
	)
	var meat_preview := phone.screen_stack.find_child(
		"ScannedItemPreview",
		true,
		false,
	) as TextureRect
	_check(
		meat_preview != null
			and meat_preview.texture != null
			and str(meat_preview.get_meta("item_id", "")) == "pork_and_liver"
			and str(meat_preview.get_meta("source_icon_path", "")).ends_with(
				"collectible_meat_set_bag.png"
			),
		"The phone scan displays the dragged meat item's inventory artwork",
	)
	_check(
		phone.screen_stack.find_child("ScannedItemDetailsScroll", true, false)
			is ScrollContainer,
		"Long AMBot item details remain scrollable below the item image",
	)
	_check(phone.ambot_typing_active, "AMBot types its item analysis")
	phone._finish_ambot_typing()
	_check(
		game_state.has_seen_active_destination_in_maps(),
		"Finishing the meat scan reveals the next vendor marker without opening Maps",
	)
	_check(
		phone.screen_stack.get_child_count() >= 3,
		"AMBot provides item information and a completed-scan action",
	)

	phone.analyze_inventory_item("damaged_newspaper")
	await process_frame
	var newspaper_preview := phone.screen_stack.find_child(
		"ScannedItemPreview",
		true,
		false,
	) as TextureRect
	_check(
		newspaper_preview != null
			and newspaper_preview.texture != null
			and str(newspaper_preview.get_meta("item_id", "")) == "damaged_newspaper"
			and str(newspaper_preview.get_meta("source_icon_path", "")).ends_with(
				"collectible_newspaper_clue.png"
			),
		"The scan preview updates to the newly dragged newspaper artwork",
	)
	_check(phone.ambot_typing_active, "AMBot types its newspaper analysis")
	phone._finish_ambot_typing()
	_check(
		game_state.is_destination_unlocked("grandma_house")
			and game_state.active_destination == "grandma_house",
		"Scanning the newspaper selects Grandma's house",
	)
	_check(
		game_state.has_seen_active_destination_in_maps(),
		"The Grandma's house marker is revealed without opening Maps",
	)

	phone.close_phone()
	await process_frame
	_check(not inventory.backpack_panel.visible, "Closing the phone closes the backpack")
	_check(inventory.hotbar_panel.visible, "Closing the inventory restores the hotbar")
	_check(not hud.objective_panel.visible, "Closing inventory does not restore a duplicate objective panel")
	_check(phone.notification_banner.visible, "Closing inventory restores the unread notification")

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
