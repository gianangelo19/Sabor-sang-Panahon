extends Node

const SAVE_VERSION := 1
const DEFAULT_GAME_SCENE := "res://game/worlds/la_paz/la_paz.tscn"
const STORY_INGREDIENT_IDS := [
	"pork_and_liver",
	"ginamos",
	"crushed_chicharon",
	"fresh_miki",
]
const STORY_INGREDIENT_TOTAL := 4
const INVENTORY_SIZE := 27
const HOTBAR_SIZE := 9
const MAX_ITEM_STACK := 64
const PHYSICAL_EVIDENCE_OBJECTIVE := "Search around the La Paz house for physical evidence."
const SIGN_REVEALED_CLUE := "Teb's Old La Paz Batchoyan signage revealed."
const ITEM_CATALOG := {
	"pork_and_liver": {
		"display_name": "Pork and Liver",
		"category": "Ingredient",
		"icon": "res://features/minigames/ending_sequence/assets/collectibles/collectible_meat_set_bag.png",
		"ambot": "A market bundle of pork belly, liver, and spleen. These cuts build the rich, savory base associated with traditional La Paz Batchoy.",
	},
	"ginamos": {
		"display_name": "Aged Ginamos",
		"category": "Ingredient",
		"icon": "res://features/minigames/ending_sequence/assets/collectibles/collectible_guinamos_bag.png",
		"ambot": "Fermented shrimp paste with a concentrated salty, umami flavor. A small amount deepens the broth; the aged aroma is strong by design.",
	},
	"crushed_chicharon": {
		"display_name": "Crushed Chicharon",
		"category": "Ingredient",
		"icon": "res://features/minigames/ending_sequence/assets/collectibles/collectible_chicharon_bag.png",
		"ambot": "Crisp pork cracklings crushed into a topping. They add texture and a roasted, savory finish after the broth is served.",
	},
	"fresh_miki": {
		"display_name": "Fresh Miki Noodles",
		"category": "Ingredient",
		"icon": "res://features/minigames/ending_sequence/assets/collectibles/collectible_miki_noodles_bag.png",
		"ambot": "Fresh yellow egg noodles made for a springy, tender bite. Their shape and texture make them a defining part of the reconstructed dish.",
	},
	"damaged_newspaper": {
		"display_name": "Damaged Newspaper",
		"category": "Clue",
		"icon": "res://features/minigames/ending_sequence/assets/collectibles/collectible_newspaper_clue.png",
		"ambot": "A badly damaged historical article. The surviving print mentions La Paz, Iloilo City, and a local dish, but its name and photograph are missing.",
	},
	"empty_aged_jar": {
		"display_name": "Empty Aged Jar",
		"category": "Tool",
		"icon": "res://game/props/items/collectibles/assets/empty_aged_jar.png",
		"ambot": "An empty earthen jar with residue from aged ginamos. The staining and aroma suggest repeated use for fermented seasoning.",
	},
	"crank_handle": {
		"display_name": "Crank Handle",
		"category": "Tool",
		"icon": "res://game/props/items/collectibles/assets/crank_handle_world_item.png",
		"ambot": "A removable hand crank shaped for a noodle machine. Wear around the grip suggests it was used often rather than kept as decoration.",
	},
	"batchoy_bowl": {
		"display_name": "Old Batchoy Bowl",
		"category": "Artifact",
		"icon": "res://assets/art/images/batchoy_bowl_artifact.png",
		"ambot": "A well-used serving bowl tied to the family eatery. Its physical history connects the recovered ingredients, the house, and the forgotten name La Paz Batchoy.",
	},
}

signal objective_changed(objective: String)
signal clue_added(clue: String)
signal ingredients_changed(found: int, total: int)
signal ambot_status_changed(status: String)
signal phone_notification_received(notification: Dictionary)
signal ambot_availability_changed(available: bool)
signal tutorial_step_changed(step: int)
signal destination_unlocked(destination_id: String)
signal destination_selected(destination_id: String)
signal destination_completed(destination_id: String)
signal navigation_changed
signal final_hunt_started(duration: float)
signal final_hunt_time_changed(seconds_remaining: float)
signal final_hunt_finished(success: bool)
signal final_hunt_placement_decided(source: String, spot_id: String)
signal grandma_presence_changed(present: bool)
signal inventory_changed
signal selected_inventory_slot_changed(slot_index: int)

var current_objective := "Find something to eat."
var ambot_status := "Offline"
var clues: Array[String] = []
var ingredients_found := 0
var ingredients_total := STORY_INGREDIENT_TOTAL
var collected_ingredients: Dictionary = {}
var inventory_slots: Array[Dictionary] = []
var selected_inventory_slot := 0
var pending_ambot_notification: Dictionary = {}
var completed_ambot_conversations: Array[String] = []
var tutorial_step := 0
var unlocked_destinations: Array[String] = []
var completed_destinations: Array[String] = []
var active_destination := ""
var map_viewed_destination := ""
var save_file_path := "user://savegame.json"
var autosave_enabled := false
var pending_player_transform: Dictionary = {}
var _wake_up_intro_requested := false
var _autosave_queued := false
var final_hunt_active := false
var final_hunt_time_remaining := 0.0
var final_hunt_succeeded := false
var final_hunt_placement_source := ""
var final_hunt_placement_spot := ""
var final_hunt_placement_reason := ""
var final_hunt_used_placement_spots: Array[String] = []
var grandma_left_for_medicine := false

func reset() -> void:
	_wake_up_intro_requested = false
	current_objective = "Find something to eat."
	ambot_status = "Offline"
	clues.clear()
	ingredients_found = 0
	ingredients_total = STORY_INGREDIENT_TOTAL
	collected_ingredients.clear()
	_initialize_inventory_slots()
	selected_inventory_slot = 0
	pending_ambot_notification.clear()
	completed_ambot_conversations.clear()
	tutorial_step = 0
	unlocked_destinations.clear()
	completed_destinations.clear()
	active_destination = ""
	map_viewed_destination = ""
	pending_player_transform.clear()
	final_hunt_active = false
	final_hunt_time_remaining = 0.0
	final_hunt_succeeded = false
	final_hunt_placement_source = ""
	final_hunt_placement_spot = ""
	final_hunt_placement_reason = ""
	final_hunt_used_placement_spots.clear()
	grandma_left_for_medicine = false
	objective_changed.emit(current_objective)
	ambot_status_changed.emit(ambot_status)
	ingredients_changed.emit(ingredients_found, ingredients_total)
	inventory_changed.emit()
	selected_inventory_slot_changed.emit(selected_inventory_slot)
	ambot_availability_changed.emit(false)
	tutorial_step_changed.emit(tutorial_step)
	navigation_changed.emit()

func begin_final_hunt(duration: float = 30.0) -> void:
	final_hunt_active = true
	final_hunt_succeeded = false
	final_hunt_time_remaining = maxf(duration, 0.0)
	final_hunt_started.emit(final_hunt_time_remaining)
	final_hunt_time_changed.emit(final_hunt_time_remaining)
	_request_autosave()

func update_final_hunt_time(seconds_remaining: float) -> void:
	final_hunt_time_remaining = maxf(seconds_remaining, 0.0)
	final_hunt_time_changed.emit(final_hunt_time_remaining)

func complete_final_hunt(success: bool) -> void:
	final_hunt_active = false
	final_hunt_succeeded = success
	final_hunt_finished.emit(success)
	_request_autosave()

func record_final_hunt_placement(source: String, spot_id: String, reason: String = "") -> void:
	final_hunt_placement_source = source
	final_hunt_placement_spot = spot_id
	final_hunt_placement_reason = reason
	if not spot_id.is_empty() and source != "unavailable" and not final_hunt_used_placement_spots.has(spot_id):
		final_hunt_used_placement_spots.append(spot_id)
	final_hunt_placement_decided.emit(source, spot_id)
	_request_autosave()

func set_grandma_left_for_medicine(left: bool) -> void:
	if grandma_left_for_medicine == left:
		return
	grandma_left_for_medicine = left
	grandma_presence_changed.emit(not left)
	_request_autosave()

func set_objective(objective: String) -> void:
	current_objective = objective
	objective_changed.emit(current_objective)
	_request_autosave()

func set_ambot_status(status: String) -> void:
	ambot_status = status
	ambot_status_changed.emit(ambot_status)
	_request_autosave()

func add_clue(clue: String) -> void:
	if clues.has(clue):
		return
	clues.append(clue)
	clue_added.emit(clue)
	_request_autosave()

func set_ingredients(found: int, _total: int = STORY_INGREDIENT_TOTAL) -> void:
	ingredients_total = STORY_INGREDIENT_TOTAL
	ingredients_found = clampi(found, 0, ingredients_total)
	ingredients_changed.emit(ingredients_found, ingredients_total)
	_request_autosave()

func collect_ingredient(ingredient_id: String, display_name: String) -> bool:
	if ingredient_id.is_empty() or collected_ingredients.has(ingredient_id):
		return false
	collected_ingredients[ingredient_id] = display_name
	add_inventory_item(ingredient_id, display_name)
	ingredients_found = _count_story_ingredients()
	ingredients_changed.emit(ingredients_found, ingredients_total)
	_request_autosave()
	return true

func has_ingredient(ingredient_id: String) -> bool:
	return collected_ingredients.has(ingredient_id)

func add_inventory_item(item_id: String, display_name: String = "", quantity: int = 1) -> bool:
	if item_id.is_empty() or quantity <= 0:
		return false
	if inventory_slots.size() != INVENTORY_SIZE:
		_initialize_inventory_slots()

	var remaining := quantity
	var resolved_name := display_name
	if resolved_name.is_empty():
		resolved_name = str(get_item_definition(item_id).get("display_name", item_id.capitalize()))

	for index in range(inventory_slots.size()):
		var slot: Dictionary = inventory_slots[index]
		if (
			str(slot.get("item_id", "")) == item_id
			and int(slot.get("quantity", 0)) < MAX_ITEM_STACK
		):
			var room := MAX_ITEM_STACK - int(slot.get("quantity", 0))
			var amount := mini(room, remaining)
			slot["quantity"] = int(slot.get("quantity", 0)) + amount
			inventory_slots[index] = slot
			remaining -= amount
			if remaining <= 0:
				break

	while remaining > 0:
		var empty_index := _find_empty_inventory_slot()
		if empty_index < 0:
			break
		var amount := mini(MAX_ITEM_STACK, remaining)
		inventory_slots[empty_index] = {
			"item_id": item_id,
			"display_name": resolved_name,
			"quantity": amount,
		}
		remaining -= amount

	if remaining != quantity:
		inventory_changed.emit()
		_request_autosave()
	return remaining == 0

func get_inventory_slot(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= inventory_slots.size():
		return {}
	return inventory_slots[slot_index].duplicate(true)

func get_selected_inventory_slot() -> Dictionary:
	return get_inventory_slot(selected_inventory_slot)

func select_inventory_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= HOTBAR_SIZE:
		return false
	if selected_inventory_slot == slot_index:
		return true
	selected_inventory_slot = slot_index
	selected_inventory_slot_changed.emit(selected_inventory_slot)
	_request_autosave()
	return true

func swap_inventory_slots(first_index: int, second_index: int) -> bool:
	if (
		first_index < 0
		or second_index < 0
		or first_index >= inventory_slots.size()
		or second_index >= inventory_slots.size()
	):
		return false
	if first_index == second_index:
		return true
	var held_slot: Dictionary = inventory_slots[first_index]
	inventory_slots[first_index] = inventory_slots[second_index]
	inventory_slots[second_index] = held_slot
	inventory_changed.emit()
	_request_autosave()
	return true

func get_item_definition(item_id: String) -> Dictionary:
	var definition: Dictionary = ITEM_CATALOG.get(item_id, {}).duplicate(true)
	if definition.is_empty():
		definition = {
			"display_name": item_id.capitalize(),
			"category": "Item",
			"icon": "",
			"ambot": "I can confirm this is an inventory item, but I do not have enough reference data for a more precise identification.",
		}
	return definition

func _initialize_inventory_slots() -> void:
	inventory_slots.clear()
	for _index in range(INVENTORY_SIZE):
		inventory_slots.append({})

func _find_empty_inventory_slot() -> int:
	for index in range(inventory_slots.size()):
		if str(inventory_slots[index].get("item_id", "")).is_empty():
			return index
	return -1

func has_all_story_ingredients() -> bool:
	for ingredient_id in STORY_INGREDIENT_IDS:
		if not has_ingredient(ingredient_id):
			return false
	return true

func begin_physical_evidence_search() -> void:
	if not has_all_story_ingredients() or clues.has(SIGN_REVEALED_CLUE):
		return
	set_objective(PHYSICAL_EVIDENCE_OBJECTIVE)
	set_ambot_status("4/4 ingredients collected - search the La Paz house")

func _count_story_ingredients() -> int:
	var count := 0
	for ingredient_id in STORY_INGREDIENT_IDS:
		if collected_ingredients.has(ingredient_id):
			count += 1
	return count

func push_ambot_notification(situation_id: String, title: String, preview: String) -> void:
	pending_ambot_notification = {
		"situation_id": situation_id,
		"title": title,
		"preview": preview,
	}
	phone_notification_received.emit(pending_ambot_notification.duplicate())
	ambot_availability_changed.emit(true)
	_request_autosave()

func has_ambot_notification() -> bool:
	return not pending_ambot_notification.is_empty()

func consume_ambot_notification() -> String:
	if pending_ambot_notification.is_empty():
		return ""
	var situation_id: String = pending_ambot_notification.get("situation_id", "")
	pending_ambot_notification.clear()
	ambot_availability_changed.emit(false)
	_request_autosave()
	return situation_id

func complete_ambot_conversation(situation_id: String) -> void:
	if situation_id != "" and not completed_ambot_conversations.has(situation_id):
		completed_ambot_conversations.append(situation_id)
		_request_autosave()

func set_tutorial_step(step: int) -> void:
	tutorial_step = maxi(step, 0)
	tutorial_step_changed.emit(tutorial_step)
	_request_autosave()

func unlock_destination(destination_id: String) -> bool:
	if destination_id.is_empty() or unlocked_destinations.has(destination_id):
		return false
	unlocked_destinations.append(destination_id)
	destination_unlocked.emit(destination_id)
	navigation_changed.emit()
	_request_autosave()
	return true

func select_destination(destination_id: String) -> bool:
	if not unlocked_destinations.has(destination_id) or completed_destinations.has(destination_id):
		return false
	if active_destination == destination_id:
		return true
	active_destination = destination_id
	map_viewed_destination = ""
	destination_selected.emit(destination_id)
	navigation_changed.emit()
	_request_autosave()
	return true

func complete_destination(destination_id: String) -> bool:
	if destination_id.is_empty() or completed_destinations.has(destination_id):
		return false
	if not unlocked_destinations.has(destination_id):
		unlocked_destinations.append(destination_id)
	completed_destinations.append(destination_id)
	if active_destination == destination_id:
		active_destination = ""
		map_viewed_destination = ""
	destination_completed.emit(destination_id)
	navigation_changed.emit()
	_request_autosave()
	return true

func mark_active_destination_seen_in_maps() -> bool:
	if active_destination.is_empty() or map_viewed_destination == active_destination:
		return false
	map_viewed_destination = active_destination
	navigation_changed.emit()
	_request_autosave()
	return true

func has_seen_active_destination_in_maps() -> bool:
	return not active_destination.is_empty() and map_viewed_destination == active_destination

func is_destination_unlocked(destination_id: String) -> bool:
	return unlocked_destinations.has(destination_id)

func is_destination_completed(destination_id: String) -> bool:
	return completed_destinations.has(destination_id)

func start_new_game(scene_path: String = DEFAULT_GAME_SCENE) -> void:
	autosave_enabled = false
	reset()
	request_wake_up_intro()
	autosave_enabled = true
	save_game(scene_path)

func request_wake_up_intro() -> void:
	_wake_up_intro_requested = true

func consume_wake_up_intro() -> bool:
	if not _wake_up_intro_requested:
		return false
	_wake_up_intro_requested = false
	return true

func has_save_game() -> bool:
	return FileAccess.file_exists(save_file_path)

func save_game(scene_path: String = "") -> bool:
	var resolved_scene := scene_path
	if resolved_scene.is_empty() and get_tree().current_scene:
		resolved_scene = get_tree().current_scene.scene_file_path
	if resolved_scene.is_empty() or resolved_scene == "res://game/ui/menus/main_menu.tscn":
		resolved_scene = DEFAULT_GAME_SCENE

	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		player = get_tree().root.find_child("ProtoController", true, false) as Node3D
	var player_data: Dictionary = pending_player_transform.duplicate(true)
	if player:
		player_data = {
			"position": [player.global_position.x, player.global_position.y, player.global_position.z],
			"rotation": [player.rotation.x, player.rotation.y, player.rotation.z],
		}

	var data := {
		"version": SAVE_VERSION,
		"scene": resolved_scene,
		"objective": current_objective,
		"ambot_status": ambot_status,
		"clues": clues,
		"ingredients": collected_ingredients,
		"inventory": inventory_slots,
		"selected_inventory_slot": selected_inventory_slot,
		"ingredients_total": ingredients_total,
		"pending_notification": pending_ambot_notification,
		"completed_ambot_conversations": completed_ambot_conversations,
		"tutorial_step": tutorial_step,
		"unlocked_destinations": unlocked_destinations,
		"completed_destinations": completed_destinations,
		"active_destination": active_destination,
		"map_viewed_destination": map_viewed_destination,
		"final_hunt_active": final_hunt_active,
		"final_hunt_time_remaining": final_hunt_time_remaining,
		"final_hunt_succeeded": final_hunt_succeeded,
		"final_hunt_placement_source": final_hunt_placement_source,
		"final_hunt_placement_spot": final_hunt_placement_spot,
		"final_hunt_placement_reason": final_hunt_placement_reason,
		"final_hunt_used_placement_spots": final_hunt_used_placement_spots,
		"grandma_left_for_medicine": grandma_left_for_medicine,
		"player": player_data,
	}
	var file := FileAccess.open(save_file_path, FileAccess.WRITE)
	if file == null:
		push_error("Unable to open save file: " + save_file_path)
		return false
	file.store_string(JSON.stringify(data))
	return true

func load_game() -> String:
	_wake_up_intro_requested = false
	if not has_save_game():
		return ""
	var file := FileAccess.open(save_file_path, FileAccess.READ)
	if file == null:
		return ""
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or int(parsed.get("version", 0)) != SAVE_VERSION:
		return ""

	autosave_enabled = false
	current_objective = str(parsed.get("objective", "Find something to eat."))
	ambot_status = str(parsed.get("ambot_status", "Offline"))
	clues.assign(parsed.get("clues", []))
	collected_ingredients = parsed.get("ingredients", {}).duplicate(true)
	_load_inventory(parsed.get("inventory", []))
	selected_inventory_slot = clampi(
		int(parsed.get("selected_inventory_slot", 0)),
		0,
		HOTBAR_SIZE - 1,
	)
	if not parsed.has("inventory"):
		for ingredient_id: String in collected_ingredients:
			add_inventory_item(ingredient_id, str(collected_ingredients[ingredient_id]))
	ingredients_found = _count_story_ingredients()
	ingredients_total = STORY_INGREDIENT_TOTAL
	pending_ambot_notification = parsed.get("pending_notification", {}).duplicate(true)
	completed_ambot_conversations.assign(parsed.get("completed_ambot_conversations", []))
	tutorial_step = int(parsed.get("tutorial_step", 0))
	unlocked_destinations.assign(parsed.get("unlocked_destinations", []))
	completed_destinations.assign(parsed.get("completed_destinations", []))
	active_destination = str(parsed.get("active_destination", ""))
	map_viewed_destination = str(parsed.get("map_viewed_destination", ""))
	final_hunt_active = bool(parsed.get("final_hunt_active", false))
	final_hunt_time_remaining = float(parsed.get("final_hunt_time_remaining", 0.0))
	final_hunt_succeeded = bool(parsed.get("final_hunt_succeeded", false))
	final_hunt_placement_source = str(parsed.get("final_hunt_placement_source", ""))
	final_hunt_placement_spot = str(parsed.get("final_hunt_placement_spot", ""))
	final_hunt_placement_reason = str(parsed.get("final_hunt_placement_reason", ""))
	final_hunt_used_placement_spots.assign(parsed.get("final_hunt_used_placement_spots", []))
	var legacy_grandma_left := (
		completed_destinations.has("market_vendor_1")
		and not clues.has("Batchoy Bowl artifact recovered.")
		and not clues.has("La Paz Batchoy served to Grandma.")
	)
	grandma_left_for_medicine = bool(parsed.get("grandma_left_for_medicine", legacy_grandma_left))
	if has_all_story_ingredients() and not clues.has(SIGN_REVEALED_CLUE):
		current_objective = PHYSICAL_EVIDENCE_OBJECTIVE
		ambot_status = "4/4 ingredients collected - search the La Paz house"
	pending_player_transform = parsed.get("player", {}).duplicate(true)
	autosave_enabled = true
	_emit_loaded_state()
	return str(parsed.get("scene", DEFAULT_GAME_SCENE))

func apply_saved_player_transform(player: Node3D) -> void:
	if pending_player_transform.is_empty() or player == null:
		return
	var position_data: Array = pending_player_transform.get("position", [])
	var rotation_data: Array = pending_player_transform.get("rotation", [])
	if position_data.size() == 3:
		player.global_position = Vector3(float(position_data[0]), float(position_data[1]), float(position_data[2]))
	if rotation_data.size() == 3:
		player.rotation = Vector3(float(rotation_data[0]), float(rotation_data[1]), float(rotation_data[2]))
	pending_player_transform.clear()

func _request_autosave() -> void:
	if not autosave_enabled or _autosave_queued:
		return
	_autosave_queued = true
	call_deferred("_perform_autosave")

func _perform_autosave() -> void:
	_autosave_queued = false
	if autosave_enabled:
		save_game()

func _load_inventory(raw_inventory: Variant) -> void:
	_initialize_inventory_slots()
	if not raw_inventory is Array:
		return
	var loaded_slots := raw_inventory as Array
	for index in range(mini(loaded_slots.size(), INVENTORY_SIZE)):
		if not loaded_slots[index] is Dictionary:
			continue
		var slot := (loaded_slots[index] as Dictionary).duplicate(true)
		var item_id := str(slot.get("item_id", ""))
		var quantity := clampi(int(slot.get("quantity", 0)), 0, MAX_ITEM_STACK)
		if item_id.is_empty() or quantity <= 0:
			continue
		inventory_slots[index] = {
			"item_id": item_id,
			"display_name": str(slot.get("display_name", get_item_definition(item_id).get("display_name", item_id.capitalize()))),
			"quantity": quantity,
		}

func _emit_loaded_state() -> void:
	objective_changed.emit(current_objective)
	ambot_status_changed.emit(ambot_status)
	ingredients_changed.emit(ingredients_found, ingredients_total)
	inventory_changed.emit()
	selected_inventory_slot_changed.emit(selected_inventory_slot)
	ambot_availability_changed.emit(not pending_ambot_notification.is_empty())
	tutorial_step_changed.emit(tutorial_step)
	navigation_changed.emit()
	if not final_hunt_placement_source.is_empty():
		final_hunt_placement_decided.emit(final_hunt_placement_source, final_hunt_placement_spot)
	grandma_presence_changed.emit(not grandma_left_for_medicine)
	if final_hunt_active:
		final_hunt_started.emit(final_hunt_time_remaining)
		final_hunt_time_changed.emit(final_hunt_time_remaining)
	elif final_hunt_succeeded:
		final_hunt_finished.emit(true)
