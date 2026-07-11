extends SceneTree

class MockPlayer extends Node:
	var can_move := true
	var mouse_released := false
	var mouse_captured := false

	func release_mouse() -> void:
		mouse_released = true

	func capture_mouse() -> void:
		mouse_captured = true


var failures: Array[String] = []
var player: MockPlayer


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.reset()
	_check(game_state.ingredients_total == 4, "The story HUD tracks exactly four ingredients")
	game_state.set_ingredients(4, 4)
	var count_only_sign := (load("res://tebs_sign.tscn") as PackedScene).instantiate()
	root.add_child(count_only_sign)
	await process_frame
	_check(count_only_sign.get_interaction_text() == "Press E to inspect covered sign", "A count alone cannot bypass the exact four-ingredient sign gate")
	count_only_sign.queue_free()
	game_state.reset()

	player = MockPlayer.new()
	player.name = "ProtoController"
	root.add_child(player)

	await _verify_vendor_locked_before_grandma()
	game_state.complete_destination("grandma_house")
	game_state.unlock_destination("market_vendor_1")
	game_state.select_destination("market_vendor_1")

	var vendor_1 := _load_npc("res://npc_market_vendor.tscn")
	var vendor_2 := _load_npc("res://npc_market_vendor_2.tscn")
	var chicharon_vendor := _load_npc("res://npc_chicharon_vendor.tscn")
	var tindero := _load_npc("res://npc_tindero.tscn")
	_check(vendor_1 != null and vendor_2 != null and chicharon_vendor != null and tindero != null, "All vendor scenes load")
	if vendor_1 == null or vendor_2 == null or chicharon_vendor == null or tindero == null:
		_finish()
		return
	_verify_placed_tindero()

	await _verify_conversation(vendor_1, "Market Vendor", "npc_market_vendor_front.png", 10, "pork_and_liver", "SnatchBattle", &"minigame_completed")
	_check(game_state.is_destination_completed("market_vendor_1"), "First market vendor destination completes")
	_check(game_state.active_destination == "market_vendor_2", "First vendor unlocks and selects the second vendor")
	_check(game_state.clues.has("Market testimony: pork and liver feel connected, but the vendor cannot remember the dish."), "First vendor records the meat clue")

	await _verify_conversation(vendor_2, "Market Vendor 2", "npc_market_vendor2_front.png", 10, "ginamos", "GuinamosJarPick", &"minigame_completed")
	_check(game_state.is_destination_completed("market_vendor_2"), "Second market vendor destination completes")
	_check(game_state.active_destination == "chicharon_vendor", "Second vendor unlocks and selects the chicharon vendor")
	_check(game_state.clues.has("Market testimony: ginamos belongs in the broth, but the vendor cannot remember the dish."), "Second vendor records the broth seasoning clue")

	await _verify_conversation(chicharon_vendor, "Chicharon Vendor", "npc_chicharon_vendor_front.png", 10, "crushed_chicharon", "ChicharonBeat", &"minigame_finished")
	_check(game_state.is_destination_completed("chicharon_vendor"), "Chicharon vendor destination completes")
	_check(game_state.active_destination == "tindero", "Chicharon vendor unlocks and selects the tindero")
	_check(game_state.clues.has("Vendor testimony: crushed chicharon fits the bowl, but its identity remains forgotten."), "Chicharon vendor records the final memory clue")
	_check(game_state.current_objective == "Talk to the tindero for fresh miki noodles.", "Chicharon vendor points to the noodle seller")

	await _verify_conversation(tindero, "Tindero", "npc_tindero_front.png", 6, "fresh_miki", "MikiNoodleCrank", &"minigame_finished")
	_check(game_state.is_destination_completed("tindero"), "Tindero destination completes")
	_check(game_state.active_destination.is_empty(), "No stale beacon remains after the final vendor")
	_check(game_state.clues.has("Tindero testimony: fresh miki noodles complete the set of four ingredients."), "Tindero records the fourth ingredient")
	_check(game_state.ingredients_found == 4 and game_state.has_all_story_ingredients(), "The four required ingredients complete the set")
	_check(game_state.current_objective == GameState.PHYSICAL_EVIDENCE_OBJECTIVE, "The complete set sends the player back to search the La Paz house")
	_check(game_state.pending_ambot_notification.get("title", "") == "All four ingredients collected", "AMBot reports the completed four-ingredient set")
	var sign := (load("res://tebs_sign.tscn") as PackedScene).instantiate()
	root.add_child(sign)
	await process_frame
	_check(sign.get_interaction_text() == "Press E to uncover Teb's sign", "The covered signage becomes discoverable after the exact four ingredients")
	sign.queue_free()

	vendor_1.queue_free()
	vendor_2.queue_free()
	chicharon_vendor.queue_free()
	tindero.queue_free()
	player.queue_free()
	_finish()


func _load_npc(scene_path: String) -> Node:
	var scene := load(scene_path) as PackedScene
	if scene == null:
		return null
	var npc := scene.instantiate()
	root.add_child(npc)
	return npc


func _verify_placed_tindero() -> void:
	var scene := load("res://tindahan.tscn") as PackedScene
	_check(scene != null, "Tindahan scene loads")
	if scene == null:
		return
	var tindahan := scene.instantiate()
	root.add_child(tindahan)
	var placed_tindero := tindahan.get_node_or_null("npc_tindero")
	_check(placed_tindero != null and placed_tindero.has_method("interact"), "Placed tindero keeps his interaction script")
	tindahan.queue_free()


func _verify_vendor_locked_before_grandma() -> void:
	var vendor := _load_npc("res://npc_market_vendor.tscn")
	_check(vendor != null, "Market vendor scene loads for sequence lock")
	if vendor == null:
		return
	_check(vendor.get_interaction_text() == "Talk to Grandma first", "Vendor prompt points to Grandma before the sequence starts")
	vendor.interact()
	await process_frame
	_check(root.find_child("dialogue_ui", true, false) == null, "Vendor dialogue cannot start before Grandma")
	vendor.queue_free()


func _verify_conversation(npc: Node, npc_name: String, portrait_filename: String, expected_lines: int, reward_id: String, minigame_node_name: String, completion_signal: StringName) -> void:
	await process_frame
	var game_state := root.get_node("GameState")
	_check(npc.has_method("interact"), npc_name + " is interactable")
	var body_shape := npc.get_node("CharacterBody3D/CollisionShape3D") as CollisionShape3D
	_check(body_shape.shape != null, npc_name + " has physical collision")
	npc.interact()
	await process_frame
	var dialogue := root.find_child("dialogue_ui", true, false)
	_check(dialogue != null, npc_name + " opens the shared dialogue UI")
	_check(not player.can_move and player.mouse_released, npc_name + " locks player controls")
	if npc_name == "Market Vendor":
		_check(game_state.grandma_left_for_medicine, "Talking to the first vendor sends Grandma out to buy medicine")
	if dialogue == null:
		return
	_check(dialogue.dialogue_lines.size() == expected_lines, npc_name + " has the complete authored conversation")
	_check(dialogue.speaker_name.text == "You", npc_name + " conversation begins with the player")
	_check(dialogue.portrait.texture.resource_path.ends_with("2main_character_asking.png"), npc_name + " uses the player asking portrait")
	_check(dialogue.npc_portrait.visible, npc_name + " shows the NPC portrait on the right")
	_check(dialogue.npc_portrait.texture.resource_path.ends_with(portrait_filename), npc_name + " keeps the NPC portrait on the right")
	dialogue._on_continue_pressed()
	_check(dialogue.speaker_name.text == npc_name, npc_name + " speaker name appears")
	_check(dialogue.portrait.texture.resource_path.ends_with("2main_character_asking.png"), npc_name + " keeps the player portrait on the left")
	_check(dialogue.npc_portrait.texture.resource_path.ends_with(portrait_filename), npc_name + " uses the correct right-side front portrait")
	for line_index in range(1, dialogue.dialogue_lines.size()):
		dialogue._on_continue_pressed()
	await process_frame
	var minigame := root.find_child(minigame_node_name, true, false)
	_check(minigame != null, npc_name + " opens the mapped " + minigame_node_name + " minigame after dialogue")
	_check(not game_state.has_ingredient(reward_id), npc_name + " does not award its ingredient before a win")
	if minigame:
		if completion_signal == &"minigame_completed":
			minigame.emit_signal(completion_signal, 100)
		else:
			minigame.emit_signal(completion_signal)
		await process_frame
	_check(game_state.has_ingredient(reward_id), npc_name + " awards its ingredient after the win signal")
	_check(player.can_move and player.mouse_captured, npc_name + " restores player controls")


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	if failures.is_empty():
		print("Vendor dialogue verification passed.")
		quit(0)
	else:
		print("Vendor dialogue verification failed: " + ", ".join(failures))
		quit(1)
