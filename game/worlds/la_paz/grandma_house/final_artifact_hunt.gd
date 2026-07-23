extends Node3D

const ARTIFACT_SCENE := preload("res://game/props/artifacts/batchoy_bowl/batchoy_bowl_artifact.tscn")
const FINAL_ENDING_SCENE := preload(
	"res://features/minigames/final_ending/scenes/final_ending_scene.tscn"
)
const ARTIFACT_DISCOVERY_POPUP_SCENE := preload("res://game/ui/artifact/artifact_discovery_popup.tscn")
const POST_RECOVERY_CHOICE_SCENE := preload("res://game/ui/artifact/post_recovery_choice.tscn")
const DIALOGUE_SCENE := preload("res://game/ui/dialogue/dialogue_ui.tscn")
const PLAYER_PORTRAIT := preload("res://assets/art/characters/2main_character_asking.png")
const GRANDMA_PORTRAIT := preload("res://assets/art/characters/npc_grandma/npc_grandma_front.png")
const HUNT_CLOCK_SOUND := preload("res://assets/audio/clock_sound.mp3")

const SIGN_REVEALED_CLUE := "Teb's Old La Paz Batchoyan signage revealed."
const ARTIFACT_RECOVERED_CLUE := "Batchoy Bowl artifact recovered."
const DISH_RESTORED_CLUE := "The forgotten dish is La Paz Batchoy."
const BATCHOY_SERVED_CLUE := "La Paz Batchoy served to Grandma."

@export var hunt_duration := 30.0
@export var minimum_player_distance := 7.0

var _artifact: Node3D
var _active := false
var _selecting_placement := false
var _remaining := 0.0
var _rng := RandomNumberGenerator.new()
var _player: Node
var _player_was_movable := true
var _player_locked := false
var _grandma: Node3D
var _last_spot_id := ""
var _hunt_clock_player: AudioStreamPlayer
var _final_ending: Node2D


func _ready() -> void:
	add_to_group("final_artifact_hunt")
	_hunt_clock_player = AudioStreamPlayer.new()
	_hunt_clock_player.name = "FinalHuntClock"
	_hunt_clock_player.stream = HUNT_CLOCK_SOUND
	_hunt_clock_player.bus = "SFX"
	add_child(_hunt_clock_player)
	_rng.randomize()
	_last_spot_id = GameState.final_hunt_placement_spot
	_grandma = get_parent().get_node_or_null("npc_grandma") as Node3D
	if GameState.clues.has(ARTIFACT_RECOVERED_CLUE):
		_set_grandma_present(true)
		return
	if GameState.final_hunt_active or GameState.clues.has(SIGN_REVEALED_CLUE):
		call_deferred("start_hunt", GameState.final_hunt_time_remaining)


func _process(delta: float) -> void:
	if not _active:
		return
	_remaining = maxf(_remaining - delta, 0.0)
	GameState.update_final_hunt_time(_remaining)
	if _remaining <= 0.0:
		_timeout_hunt()


func start_hunt(resume_time: float = 0.0) -> void:
	if _active or _selecting_placement or GameState.clues.has(ARTIFACT_RECOVERED_CLUE):
		return
	_selecting_placement = true
	_clear_artifact()
	_set_grandma_present(false)
	_remaining = (
		clampf(resume_time, 0.0, hunt_duration)
		if resume_time > 0.0
		else hunt_duration
	)
	_lock_player()
	GameState.set_objective("Choosing a hiding place for the Batchoy Bowl...")
	GameState.set_ambot_status("Preparing the Cultural Echo search")

	var spots := _get_valid_hiding_spots()
	var selected_spot := _choose_hiding_spot(spots)
	_selecting_placement = false
	if selected_spot == null:
		var reason := "No hiding markers exist in lapaz_home.tscn."
		_set_grandma_present(true)
		GameState.record_final_hunt_placement("unavailable", "", reason)
		GameState.set_objective("The Batchoy Bowl could not be placed. Inspect Teb's sign to retry.")
		GameState.set_ambot_status("Artifact placement unavailable - hunt not started")
		_restore_player()
		push_warning("Final artifact placement unavailable: " + reason)
		return

	_spawn_artifact_at(selected_spot)
	_active = _artifact != null
	if not _active:
		push_error("Final artifact hunt could not create the Batchoy Bowl.")
		_restore_player()
		return

	_last_spot_id = str(selected_spot.name)
	var reason := "Offline procedural rules selected %s using bowl-sized clearance, uniform randomness, and saved no-repeat history." % _last_spot_id
	GameState.record_final_hunt_placement("procedural", _last_spot_id, reason)
	GameState.begin_final_hunt(_remaining)
	GameState.set_objective("Find the Batchoy Bowl before Grandma returns. Follow the cultural echoes!")
	GameState.set_ambot_status("Cultural Echo search active")
	_start_hunt_clock()
	print("Artifact placement source=procedural marker=%s reason=%s" % [_last_spot_id, reason])
	_restore_player()


func retry_hunt() -> void:
	_active = false
	GameState.final_hunt_time_remaining = hunt_duration
	start_hunt(hunt_duration)


func _spawn_artifact_at(spot: Marker3D) -> void:
	_artifact = ARTIFACT_SCENE.instantiate()
	add_child(_artifact)
	_artifact.global_position = spot.global_position
	_artifact.artifact_recovered.connect(_on_artifact_recovered)


func _get_valid_hiding_spots() -> Array[Marker3D]:
	var clear_spots: Array[Marker3D] = []
	var all_spots: Array[Marker3D] = []
	for child in get_children():
		if not child is Marker3D:
			continue
		var spot := child as Marker3D
		all_spots.append(spot)
		if _spot_is_clear(spot):
			clear_spots.append(spot)
	return clear_spots if not clear_spots.is_empty() else all_spots


func _choose_hiding_spot(spots: Array[Marker3D]) -> Marker3D:
	if spots.is_empty():
		return null

	var unused_choices: Array[Marker3D] = []
	for spot in spots:
		if not GameState.final_hunt_used_placement_spots.has(str(spot.name)):
			unused_choices.append(spot)

	var choices := unused_choices
	if choices.is_empty():
		choices = spots.duplicate()
		if choices.size() > 1:
			for index in range(choices.size() - 1, -1, -1):
				if str(choices[index].name) == _last_spot_id:
					choices.remove_at(index)

	return choices[_rng.randi_range(0, choices.size() - 1)]


func _spot_is_clear(spot: Marker3D) -> bool:
	if not is_inside_tree():
		return true
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.8, 1.4, 1.0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, spot.global_position)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func _is_occluded_from_player(player: Node3D, target: Vector3) -> bool:
	var origin := player.global_position + Vector3.UP * 1.4
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.collision_mask = 1
	if player is CollisionObject3D:
		query.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and Vector3(hit.position).distance_to(target) > 1.0


func _on_artifact_recovered(_recovered_artifact: Node3D) -> void:
	if not _active:
		return
	_active = false
	_stop_hunt_clock()
	GameState.add_clue(ARTIFACT_RECOVERED_CLUE)
	GameState.add_clue(DISH_RESTORED_CLUE)
	GameState.complete_final_hunt(true)
	GameState.set_objective("Serve the restored La Paz Batchoy to Grandma.")
	GameState.set_ambot_status("Cultural memory restored: La Paz Batchoy")
	GameState.set_grandma_left_for_medicine(false)
	_set_grandma_present(true)
	_lock_player()
	_show_final_ending()


func _timeout_hunt() -> void:
	_active = false
	_stop_hunt_clock()
	_clear_artifact()
	GameState.set_grandma_left_for_medicine(false)
	_set_grandma_present(true)
	_lock_player()
	GameState.complete_final_hunt(false)
	GameState.set_objective("Grandma has returned. Retry the search for the Batchoy Bowl.")
	GameState.set_ambot_status("Cultural Echo search interrupted")


func _show_final_ending() -> void:
	if _final_ending != null and is_instance_valid(_final_ending):
		return
	_final_ending = FINAL_ENDING_SCENE.instantiate()
	get_tree().root.add_child(_final_ending)
	_final_ending.ending_finished.connect(_on_final_ending_finished)


func _on_final_ending_finished() -> void:
	if _final_ending != null and is_instance_valid(_final_ending):
		_final_ending.queue_free()
	_final_ending = null
	_show_artifact_discovery_popup()


func _show_artifact_discovery_popup() -> void:
	var popup := ARTIFACT_DISCOVERY_POPUP_SCENE.instantiate()
	get_tree().root.add_child(popup)
	popup.dismissed.connect(_on_artifact_discovery_dismissed)


func _on_artifact_discovery_dismissed() -> void:
	_show_post_recovery_choice()


func _show_post_recovery_choice() -> void:
	var choice := POST_RECOVERY_CHOICE_SCENE.instantiate()
	get_tree().root.add_child(choice)
	choice.continue_exploring.connect(_on_continue_exploring_requested)
	choice.main_menu_requested.connect(_on_recovery_main_menu_requested)


func _on_continue_exploring_requested() -> void:
	_show_ending_dialogue()


func _on_recovery_main_menu_requested() -> void:
	GameState.save_game()
	_clear_artifact()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://game/ui/menus/main_menu.tscn")


func _show_ending_dialogue() -> void:
	var dialogue := DIALOGUE_SCENE.instantiate()
	get_tree().root.add_child(dialogue)
	dialogue.start_conversation([
		{"speaker": "You", "text": "There you are... all that noise in my head was an old bowl asking not to be left behind.", "portrait": PLAYER_PORTRAIT},
		{"speaker": "Grandma", "text": "Apo, I'm home— Why are you holding that? That bowl... we served more meals in it than I could ever count.", "portrait": GRANDMA_PORTRAIT},
		{"speaker": "You", "text": "This house was Teb's Old La Paz Batchoyan. The dish everyone forgot is La Paz Batchoy.", "portrait": PLAYER_PORTRAIT},
		{"speaker": "Grandma", "text": "La Paz Batchoy... Meat, fresh miki, ginamos, crushed chicharon. Ay, apo—I remember the kitchen. I remember all of it.", "portrait": GRANDMA_PORTRAIT},
		{"speaker": "You", "text": "I found the bowl and made the batchoy before you returned. I wanted home to be waiting for you this time.", "portrait": PLAYER_PORTRAIT},
		{"speaker": "Grandma", "text": "It was always waiting. We only needed to remember the way back. Now sit—the soup is getting cold, and I raised you better than that.", "portrait": GRANDMA_PORTRAIT},
	], _grandma)
	dialogue.dialogue_finished.connect(_on_ending_dialogue_finished)


func _on_ending_dialogue_finished() -> void:
	GameState.add_clue(BATCHOY_SERVED_CLUE)
	GameState.set_objective("Memory restored. Grandma remembers La Paz Batchoy.")
	_restore_player()
	_clear_artifact()


func _clear_artifact() -> void:
	if _artifact and is_instance_valid(_artifact):
		_artifact.queue_free()
	_artifact = null


func _set_grandma_present(present: bool) -> void:
	if _grandma == null or not is_instance_valid(_grandma):
		return
	_grandma.visible = present
	_grandma.process_mode = Node.PROCESS_MODE_INHERIT if present else Node.PROCESS_MODE_DISABLED
	for descendant in _grandma.find_children("*", "CollisionShape3D", true, false):
		(descendant as CollisionShape3D).set_deferred("disabled", not present)


func _find_player() -> Node:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		player = get_tree().root.find_child("ProtoController", true, false)
	return player


func _start_hunt_clock() -> void:
	if _hunt_clock_player == null:
		return
	_hunt_clock_player.stop()
	var elapsed := clampf(hunt_duration - _remaining, 0.0, hunt_duration)
	_hunt_clock_player.play(elapsed)


func _stop_hunt_clock() -> void:
	if _hunt_clock_player != null and _hunt_clock_player.playing:
		_hunt_clock_player.stop()


func _lock_player() -> void:
	var found_player := _find_player()
	if found_player != null:
		_player = found_player
	if _player == null:
		return
	if not _player_locked:
		_player_was_movable = _player.can_move
		_player_locked = true
	_player.can_move = false
	_player.set_process_unhandled_input(false)
	_player.release_mouse()


func _restore_player() -> void:
	if _player == null or not is_instance_valid(_player):
		_player = _find_player()
	if _player == null:
		return
	_player.can_move = _player_was_movable
	_player.set_process_unhandled_input(true)
	_player.capture_mouse()
	_player_locked = false
