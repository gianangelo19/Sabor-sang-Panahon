extends SceneTree

class MockPlayer extends Node3D:
	var can_move := true

	func release_mouse() -> void:
		pass

	func capture_mouse() -> void:
		pass


var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.reset()

	_check(game_state.unlocked_destinations.is_empty(), "No destinations are revealed before arrival")
	_check(not game_state.select_destination("grandma_house"), "Locked destinations cannot be selected")

	var jeepney_script := load("res://scripts/jeepney_cutscene.gd")
	var arrival_controller = jeepney_script.new()
	arrival_controller._unlock_arrival_destination()
	_check(game_state.unlocked_destinations == ["grandma_house"], "Arrival reveals only Grandma's house")
	_check(game_state.active_destination == "grandma_house", "Grandma's house is selected on arrival")
	_check(not game_state.has_seen_active_destination_in_maps(), "Beacon stays hidden until Maps is opened")
	_check(game_state.current_objective == "Visit Grandma at her old house.", "Arrival objective points to Grandma")
	_check(game_state.has_ambot_notification(), "Arrival sends the Maps notification")

	var player := MockPlayer.new()
	player.name = "ProtoController"
	player.add_to_group("player")
	root.add_child(player)

	var home_scene := load("res://lapaz_home.tscn") as PackedScene
	var market_scene := load("res://lapaz_public_market.tscn") as PackedScene
	var tindahan_scene := load("res://tindahan.tscn") as PackedScene
	_check(home_scene != null and market_scene != null and tindahan_scene != null, "Destination scenes load")
	if home_scene == null or market_scene == null or tindahan_scene == null:
		_finish()
		return

	var home := home_scene.instantiate()
	var market := market_scene.instantiate()
	var tindahan := tindahan_scene.instantiate()
	root.add_child(home)
	root.add_child(market)
	root.add_child(tindahan)
	await process_frame

	var home_marker := home.get_node("GrandmaHouseDestination")
	var grandma := home.get_node("npc_grandma") as Node3D
	var market_marker := market.get_node("MarketVendor1Destination")
	var market_marker_2 := market.get_node("MarketVendor2Destination")
	var market_vendor_1 := market.get_node("npc_market_vendor") as Node3D
	var market_vendor_2 := market.get_node("npc_market_vendor2") as Node3D
	var chicharon_marker := tindahan.get_node("ChicharonVendorDestination")
	var chicharon_vendor := tindahan.get_node("npc_chicharon_vendor") as Node3D
	var tindero_marker := tindahan.get_node("TinderoDestination")
	var tindero := tindahan.get_node("npc_tindero") as Node3D
	_check(home_marker.destination_id == "grandma_house", "Grandma entrance has a stable destination ID")
	_check(home_marker.position.is_equal_approx(grandma.position), "Grandma marker targets the NPC itself")
	_check(market_marker.destination_id == "market_vendor_1", "First market vendor has a stable destination ID")
	_check(market_marker_2.destination_id == "market_vendor_2", "Second market vendor has a stable destination ID")
	_check(tindero_marker.destination_id == "tindero", "Tindero has a stable destination ID")
	_check(market_marker.position.is_equal_approx(market_vendor_1.position), "First market beacon targets its NPC")
	_check(market_marker_2.position.is_equal_approx(market_vendor_2.position), "Second market beacon targets its NPC")
	_check(chicharon_marker.position.is_equal_approx(chicharon_vendor.position), "Chicharon beacon targets its NPC")
	_check(tindero_marker.position.is_equal_approx(tindero.position), "Tindero beacon targets its NPC")

	var map_script := load("res://ui/map_view.gd")
	var map_view = map_script.new()
	map_view.size = Vector2(310, 405)
	root.add_child(map_view)
	await process_frame
	await process_frame
	_check(game_state.has_seen_active_destination_in_maps(), "Opening Maps arms the selected destination beacon")
	_check(map_view.marker_buttons.has("grandma_house"), "Map shows the unlocked Grandma destination")
	_check(not map_view.marker_buttons.has("market_vendor_1"), "Map hides the locked market vendor")

	player.global_position = home_marker.global_position
	home_marker._process(0.0)
	_check(game_state.current_objective == "Talk to Grandma.", "Reaching Grandma changes the objective")

	game_state.complete_destination("grandma_house")
	game_state.unlock_destination("market_vendor_1")
	game_state.select_destination("market_vendor_1")
	await process_frame
	_check(game_state.has_seen_active_destination_in_maps(), "Open Maps arms newly selected destinations")
	_check(map_view.marker_buttons.has("market_vendor_1"), "Map reveals the first market vendor after story unlock")
	_check(not map_view.marker_buttons.has("market_vendor_2"), "Map keeps the second vendor hidden")
	_check(not map_view.marker_buttons.has("tindero"), "Map keeps the tindero hidden until the egg step")
	_check(game_state.active_destination == "market_vendor_1", "Unlocked market vendor can be selected")
	var marker_button_count := _count_marker_buttons(map_view.marker_layer)
	map_view._rebuild_markers()
	await process_frame
	_check(_count_marker_buttons(map_view.marker_layer) == marker_button_count, "Map rebuilds do not duplicate destination labels")
	var current_destination_button: Button = map_view.marker_buttons["market_vendor_1"].button
	current_destination_button.pressed.emit()
	await process_frame
	await process_frame
	_check(game_state.active_destination == "market_vendor_1", "Clicking a map label keeps the selected destination stable")
	_check(_count_marker_buttons(map_view.marker_layer) == marker_button_count, "Clicking a map label rebuilds without duplicate labels")

	map_view.queue_free()
	home.queue_free()
	market.queue_free()
	tindahan.queue_free()
	player.queue_free()
	arrival_controller.free()
	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _count_marker_buttons(marker_layer: Control) -> int:
	var count := 0
	for child in marker_layer.get_children():
		if child is Button:
			count += 1
	return count


func _finish() -> void:
	if failures.is_empty():
		print("Navigation verification passed.")
		quit(0)
	else:
		print("Navigation verification failed: " + ", ".join(failures))
		quit(1)
