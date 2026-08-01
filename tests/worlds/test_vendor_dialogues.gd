extends SceneTree

class MockPlayer extends Node:
	var can_move := true
	var mouse_released := false
	var mouse_captured := false

	func release_mouse() -> void:
		mouse_released = true

	func capture_mouse() -> void:
		mouse_captured = true


const VENDOR_ROUTE := [
	{
		"scene": "res://game/characters/npcs/vendors/npc_market_vendor.tscn",
		"reward": "pork_and_liver",
		"destination": "market_vendor_1",
		"next": "market_vendor_2",
		"time_stage": 1,
		"root_name": "SnatchBattle",
		"success_signal": "minigame_completed",
	},
	{
		"scene": "res://game/characters/npcs/vendors/npc_market_vendor_2.tscn",
		"reward": "ginamos",
		"destination": "market_vendor_2",
		"next": "herbs_vendor",
		"time_stage": 2,
		"root_name": "GuinamosJarPick",
		"success_signal": "minigame_completed",
		"score_signal": true,
	},
	{
		"scene": "res://game/characters/npcs/vendors/npc_herbs_vendor.tscn",
		"reward": "fresh_herbs",
		"destination": "herbs_vendor",
		"next": "seasoning_vendor",
		"time_stage": 3,
		"dialogue_only": true,
	},
	{
		"scene": "res://game/characters/npcs/vendors/npc_seasoning_vendor.tscn",
		"reward": "seasoning",
		"destination": "seasoning_vendor",
		"next": "egg_vendor",
		"time_stage": 4,
		"dialogue_only": true,
	},
	{
		"scene": "res://game/characters/npcs/vendors/npc_egg_vendor.tscn",
		"reward": "fresh_egg",
		"destination": "egg_vendor",
		"next": "chicharon_vendor",
		"time_stage": 5,
		"root_name": "EggSorting",
		"success_signal": "minigame_completed",
	},
	{
		"scene": "res://game/characters/npcs/vendors/npc_chicharon_vendor.tscn",
		"reward": "crushed_chicharon",
		"destination": "chicharon_vendor",
		"next": "tindero",
		"time_stage": 6,
		"root_name": "ChicharonBeat",
		"success_signal": "minigame_finished",
	},
]

var failures: Array[String] = []
var player: MockPlayer


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.reset()
	_check(game_state.ingredients_total == 7, "The story tracks exactly seven ingredients")
	_check(
		GameState.STORY_INGREDIENT_IDS == [
			"pork_and_liver",
			"ginamos",
			"fresh_herbs",
			"seasoning",
			"fresh_egg",
			"crushed_chicharon",
			"fresh_miki",
		],
		"The canonical ingredient order matches the vendor route",
	)
	game_state.set_ingredients(7, 7)
	var count_only_sign := _instantiate("res://game/props/environment/signage/tebs_sign.tscn")
	_check(
		count_only_sign.get_interaction_text() == "Press F to inspect covered sign",
		"A count alone cannot bypass the exact seven-item sign gate",
	)
	count_only_sign.queue_free()
	game_state.reset()

	player = MockPlayer.new()
	player.name = "ProtoController"
	root.add_child(player)
	await _verify_vendor_locked_before_grandma()

	game_state.complete_destination("grandma_house")
	game_state.unlock_destination("market_vendor_1")
	game_state.select_destination("market_vendor_1")

	for route_index in range(VENDOR_ROUTE.size()):
		var route: Dictionary = VENDOR_ROUTE[route_index]
		var vendor := _instantiate(str(route.scene))
		_check(vendor != null, str(route.scene).get_file() + " loads")
		if vendor == null:
			continue

		if str(route.reward) == "ginamos":
			await _run_conversation(vendor)
			_check(
				not game_state.has_ingredient("ginamos"),
				"Kuya Boy waits for an empty jar after the reply choice",
			)
			_check(player.can_move, "Missing jar returns control to the player")
			game_state.add_inventory_item("empty_aged_jar", "Empty Jar")

		await _run_vendor_to_reward(vendor, route)
		_check(
			game_state.is_destination_completed(str(route.destination)),
			str(route.destination) + " completes",
		)
		_check(
			game_state.active_destination == str(route.next),
			str(route.destination) + " selects " + str(route.next),
		)
		vendor.queue_free()
		await process_frame

	var tindero := _instantiate("res://game/characters/npcs/vendors/npc_tindero.tscn")
	await _run_conversation(tindero)
	_check(
		game_state.has_story_flag("miki_crank_requested"),
		"Tito Bobet starts the missing-crank route",
	)
	_check(
		game_state.current_objective
			== "Find the fat cat near 6-Eleven to retrieve the stolen crank.",
		"The missing-crank objective points to the fat cat with the correct wording",
	)
	_check(not game_state.has_ingredient("fresh_miki"), "Fresh miki waits for the crank")

	var crank := _instantiate("res://game/props/items/collectibles/crank_handle_item.tscn")
	_check(not crank.visible, "The placed crank remains hidden before Milk releases it")
	var bjorn := _instantiate("res://game/characters/npcs/citizens/npc_bjorn.tscn")
	await _run_conversation(bjorn)
	_check(game_state.has_story_flag("bjorn_crank_talked"), "Bjorn points the player to Milk")
	var milk := _instantiate("res://game/characters/npcs/citizens/npc_milk.tscn")
	await _run_conversation(milk)
	_check(game_state.has_story_flag("milk_released_crank"), "Milk releases the stolen crank")
	_check(crank.visible, "Milk's dialogue activates the placed crank handle")
	crank.interact()
	_check(game_state.has_inventory_item("crank_handle"), "The placed crank enters the inventory")

	await _run_vendor_to_reward(
		tindero,
		{
			"reward": "fresh_miki",
			"time_stage": 7,
			"root_name": "MikiNoodleCrank",
			"success_signal": "minigame_finished",
		},
	)
	_check(
		game_state.current_objective != "Find the fat cat near 6-Eleven to retrieve the stolen crank.",
		"Collecting fresh miki clears the crank-search objective",
	)
	_check(game_state.is_destination_completed("tindero"), "Tito Bobet completes the vendor route")
	_check(game_state.active_destination.is_empty(), "The final vendor clears the destination beacon")
	_check(game_state.ingredients_found == 7, "All seven ingredient rewards are counted")
	_check(game_state.has_all_story_ingredients(), "All seven exact ingredient IDs complete the set")
	_check(
		game_state.current_objective == GameState.PHYSICAL_EVIDENCE_OBJECTIVE,
		"The full set sends the player back for physical evidence",
	)
	_check(
		game_state.pending_ambot_notification.get("title", "") == "All seven ingredients collected",
		"AMBot reports the completed seven-ingredient set",
	)

	var sign := _instantiate("res://game/props/environment/signage/tebs_sign.tscn")
	_check(
		sign.get_interaction_text() == "Press F to uncover Teb's sign",
		"The sign becomes discoverable after all seven exact ingredients",
	)

	for node in [sign, tindero, crank, bjorn, milk, player]:
		if node != null and is_instance_valid(node):
			node.queue_free()
	_finish()


func _instantiate(scene_path: String) -> Node:
	var scene := load(scene_path) as PackedScene
	if scene == null:
		return null
	var instance := scene.instantiate()
	root.add_child(instance)
	return instance


func _verify_vendor_locked_before_grandma() -> void:
	var vendor := _instantiate("res://game/characters/npcs/vendors/npc_market_vendor.tscn")
	_check(vendor.get_interaction_text() == "Talk to Grandma first", "Vendor route waits for Lola Lynn")
	vendor.interact()
	await process_frame
	_check(root.find_child("dialogue_ui", true, false) == null, "Locked vendor cannot start dialogue")
	vendor.queue_free()


func _run_vendor_to_reward(vendor: Node, route: Dictionary) -> void:
	var reward_id := str(route.reward)
	var expected_stage := int(route.time_stage)
	var dialogue_only := bool(route.get("dialogue_only", false))
	await _run_conversation(vendor)
	if dialogue_only:
		await process_frame
	_check(
		root.get_node("GameState").time_of_day_stage == expected_stage,
		vendor.npc_display_name + " advances time once when its challenge starts",
	)
	var session := root.find_child("VendorMinigameSession", true, false)
	if dialogue_only:
		_check(session == null, vendor.npc_display_name + " never creates a minigame session")
	else:
		_check(session != null, vendor.npc_display_name + " opens the installed minigame")
		vendor._start_minigame()
		vendor._start_minigame()
		await process_frame
		_check(
			_count_nodes_named(root, "VendorMinigameSession") == 1,
			vendor.npc_display_name + " cannot duplicate its minigame session",
		)
		_check(
			not root.get_node("GameState").has_ingredient(reward_id),
			vendor.npc_display_name + " does not award before minigame completion",
		)
		var minigame: Node = session.get_minigame() if session != null else null
		_check(
			minigame != null and minigame.name == str(route.root_name),
			vendor.npc_display_name + " launches " + str(route.root_name),
		)
		if minigame != null:
			if bool(route.get("score_signal", false)):
				minigame.emit_signal(StringName(route.success_signal), 100)
			else:
				minigame.emit_signal(StringName(route.success_signal))
		await process_frame
	var reward_dialogue := root.find_child("dialogue_ui", true, false)
	_check(reward_dialogue != null, vendor.npc_display_name + " plays its reward conversation")
	if reward_dialogue != null:
		await _finish_dialogue(reward_dialogue)
	_check(root.get_node("GameState").has_ingredient(reward_id), vendor.npc_display_name + " awards " + reward_id)
	_check(player.can_move and player.mouse_captured, vendor.npc_display_name + " restores player controls")
	if dialogue_only:
		var completed_stage: int = root.get_node("GameState").time_of_day_stage
		await _run_conversation(vendor)
		_check(
			root.get_node("GameState").time_of_day_stage == completed_stage,
			vendor.npc_display_name + " cannot advance time twice on repeat dialogue",
		)
		_check(
			root.find_child("VendorMinigameSession", true, false) == null,
			vendor.npc_display_name + " remains dialogue-only after completion",
		)


func _run_conversation(npc: Node) -> void:
	npc.interact()
	npc.interact()
	npc.interact()
	await process_frame
	var dialogue := root.find_child("dialogue_ui", true, false)
	_check(dialogue != null, npc.npc_display_name + " opens dialogue")
	_check(
		_count_nodes_named(root, "dialogue_ui") == 1,
		npc.npc_display_name + " cannot duplicate dialogue from repeated interaction",
	)
	if dialogue != null:
		await _finish_dialogue(dialogue)


func _count_nodes_named(node: Node, target_name: String) -> int:
	var count := 1 if node.name == target_name else 0
	for child: Node in node.get_children():
		count += _count_nodes_named(child, target_name)
	return count


func _finish_dialogue(dialogue: Node) -> void:
	while is_instance_valid(dialogue) and dialogue.is_inside_tree():
		dialogue._complete_typewriter()
		if dialogue._choice_active and not dialogue._choice_buttons.is_empty():
			_check(
				dialogue._choice_buttons.size() == 2,
				"Kuya Boy's jar question presents two selectable replies",
			)
			dialogue._choice_buttons[0].pressed.emit()
		else:
			dialogue._on_continue_pressed()
		await process_frame


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	if failures.is_empty():
		print("Seven-vendor dialogue verification passed.")
		quit(0)
	else:
		print("Seven-vendor dialogue verification failed: " + ", ".join(failures))
		quit(1)
