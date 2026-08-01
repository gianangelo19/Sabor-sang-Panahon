extends Node3D

const ARTIFACT_SCENE := preload("res://game/props/artifacts/batchoy_bowl/batchoy_bowl_artifact.tscn")
const MINIGAME_SESSION_SCRIPT := preload(
	"res://features/minigames/shared/scripts/minigame_session.gd"
)
const ARTIFACT_MINIGAME_PLACEHOLDER := preload(
	"res://game/ui/minigames/vendor_minigame_placeholder.tscn"
)
const ARTIFACT_DISCOVERY_POPUP_SCENE := preload("res://game/ui/artifact/artifact_discovery_popup.tscn")
const POST_RECOVERY_CHOICE_SCENE := preload("res://game/ui/artifact/post_recovery_choice.tscn")
const HUNT_CLOCK_SOUND := preload("res://assets/audio/clock_sound.mp3")

const SIGN_REVEALED_CLUE := "Teb's Old La Paz Batchoyan signage revealed."
const ARTIFACT_RECOVERED_CLUE := "Batchoy Bowl artifact recovered."
const DISH_RESTORED_CLUE := "The forgotten dish is La Paz Batchoy."
const BATCHOY_SERVED_CLUE := "La Paz Batchoy served to Grandma."
const GAME_ON_REWARD_PENDING_FLAG := "game_on_artifact_reward_pending"
const GAME_ON_REWARD_CLAIMED_FLAG := "game_on_artifact_reward_claimed"

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
var _artifact_minigame_session: CanvasLayer
var _game_on_reward_screen
var _reward_requires_auth := false
var _reward_reconnect_pending := false


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
		if GameState.has_story_flag(GAME_ON_REWARD_PENDING_FLAG):
			call_deferred("_resume_pending_game_on_reward")
		return
	if GameState.final_hunt_active or GameState.clues.has(SIGN_REVEALED_CLUE):
		call_deferred("start_hunt", GameState.final_hunt_time_remaining)


func _exit_tree() -> void:
	_cleanup_game_on_reward()


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
	GameState.push_ambot_notification(
		"cultural_echoes",
		"Cultural Echo search active",
		"I can explain what sounds to follow."
	)
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
	_lock_player()
	_start_artifact_minigame()


func _start_artifact_minigame() -> void:
	if (
		_artifact_minigame_session != null
		and is_instance_valid(_artifact_minigame_session)
	):
		return
	_artifact_minigame_session = MINIGAME_SESSION_SCRIPT.new()
	_artifact_minigame_session.name = "ArtifactRecoveryMinigameSession"
	var session_parent: Node = get_tree().current_scene
	if session_parent == null:
		session_parent = get_tree().root
	session_parent.add_child(_artifact_minigame_session)
	_artifact_minigame_session.minigame_won.connect(_on_artifact_minigame_won)
	_artifact_minigame_session.dismissed.connect(_on_artifact_minigame_dismissed)
	_artifact_minigame_session.start(
		ARTIFACT_MINIGAME_PLACEHOLDER,
		{
			"title": "Restore the Old Batchoy Bowl",
			"instructions": "Complete the final memory challenge to preserve the recovered bowl.",
			"reward": "Old Batchoy Bowl artifact",
			"time_of_day_stage": 8,
		},
	)


func _on_artifact_minigame_won() -> void:
	_artifact_minigame_session = null
	GameState.add_clue(ARTIFACT_RECOVERED_CLUE)
	GameState.add_clue(DISH_RESTORED_CLUE)
	GameState.add_clue(BATCHOY_SERVED_CLUE)
	GameState.add_inventory_item("batchoy_bowl", "Old Batchoy Bowl")
	GameState.complete_final_hunt(true)
	GameState.set_objective("Memory restored. Grandma remembers La Paz Batchoy.")
	GameState.set_ambot_status("Cultural memory restored: La Paz Batchoy")
	GameState.set_grandma_left_for_medicine(false)
	GameState.set_story_flag(GAME_ON_REWARD_PENDING_FLAG)
	_set_grandma_present(true)
	_show_artifact_discovery_popup()


func _on_artifact_minigame_dismissed() -> void:
	_artifact_minigame_session = null
	if _artifact != null and is_instance_valid(_artifact):
		if _artifact.has_method("reset_recovery"):
			_artifact.call("reset_recovery")
	_active = _artifact != null and is_instance_valid(_artifact)
	if _active:
		_start_hunt_clock()
	_restore_player()


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


func _show_artifact_discovery_popup() -> void:
	_show_game_on_reward()


func _resume_pending_game_on_reward() -> void:
	_lock_player()
	_show_game_on_reward()


func _show_game_on_reward() -> void:
	if (
		_game_on_reward_screen != null
		and is_instance_valid(_game_on_reward_screen)
	):
		return
	_lock_player()
	_game_on_reward_screen = ARTIFACT_DISCOVERY_POPUP_SCENE.instantiate()
	get_tree().root.add_child(_game_on_reward_screen)
	_game_on_reward_screen.retry_requested.connect(_on_game_on_retry_requested)
	_game_on_reward_screen.continue_requested.connect(_on_game_on_continue_requested)
	var game_on := get_node(^"/root/GameOnPortal") as GameOnConnect
	if not game_on.artifact_unlocked.is_connected(_on_game_on_artifact_unlocked):
		game_on.artifact_unlocked.connect(_on_game_on_artifact_unlocked)
	if not game_on.artifact_unlock_failed.is_connected(_on_game_on_artifact_failed):
		game_on.artifact_unlock_failed.connect(_on_game_on_artifact_failed)
	if not game_on.authorization_status_changed.is_connected(_on_reward_authorization_changed):
		game_on.authorization_status_changed.connect(_on_reward_authorization_changed)
	_request_game_on_unlock()


func _request_game_on_unlock() -> void:
	if _game_on_reward_screen == null:
		return
	_reward_requires_auth = false
	_game_on_reward_screen.show_loading()
	var game_on := get_node(^"/root/GameOnPortal") as GameOnConnect
	game_on.unlock_artifact()


func _on_game_on_artifact_unlocked(
	artifact_data: Dictionary,
	is_new_unlock: bool,
) -> void:
	_reward_reconnect_pending = false
	GameState.set_story_flag(GAME_ON_REWARD_PENDING_FLAG, false)
	GameState.set_story_flag(GAME_ON_REWARD_CLAIMED_FLAG)
	if _game_on_reward_screen != null:
		_game_on_reward_screen.show_artifact(artifact_data, is_new_unlock)


func _on_game_on_artifact_failed(message: String, requires_auth: bool) -> void:
	_reward_reconnect_pending = false
	_reward_requires_auth = requires_auth
	if _game_on_reward_screen != null:
		_game_on_reward_screen.show_error(message, requires_auth)


func _on_game_on_retry_requested() -> void:
	if _game_on_reward_screen == null:
		return
	if not _reward_requires_auth:
		_request_game_on_unlock()
		return
	_reward_reconnect_pending = true
	_game_on_reward_screen.show_loading("Opening GameOn sign-in...")
	var game_on := get_node(^"/root/GameOnPortal") as GameOnConnect
	game_on.connect_account()


func _on_reward_authorization_changed(status: String) -> void:
	if not _reward_reconnect_pending or _game_on_reward_screen == null:
		return
	match status:
		"connecting":
			_game_on_reward_screen.show_loading("Opening GameOn sign-in...")
		"pending":
			_game_on_reward_screen.show_loading("Waiting for GameOn sign-in...")
		"authorized":
			_reward_reconnect_pending = false
			_request_game_on_unlock()
		"expired", "error":
			_reward_reconnect_pending = false
			_reward_requires_auth = true
			_game_on_reward_screen.show_error(
				"GameOn authentication was not completed.",
				true,
			)


func _on_game_on_continue_requested() -> void:
	GameState.set_story_flag(GAME_ON_REWARD_PENDING_FLAG, false)
	_cleanup_game_on_reward()
	_show_post_recovery_choice()


func _cleanup_game_on_reward() -> void:
	var game_on := get_node_or_null(^"/root/GameOnPortal") as GameOnConnect
	if game_on != null:
		if game_on.artifact_unlocked.is_connected(_on_game_on_artifact_unlocked):
			game_on.artifact_unlocked.disconnect(_on_game_on_artifact_unlocked)
		if game_on.artifact_unlock_failed.is_connected(_on_game_on_artifact_failed):
			game_on.artifact_unlock_failed.disconnect(_on_game_on_artifact_failed)
		if game_on.authorization_status_changed.is_connected(_on_reward_authorization_changed):
			game_on.authorization_status_changed.disconnect(_on_reward_authorization_changed)
	if _game_on_reward_screen != null and is_instance_valid(_game_on_reward_screen):
		_game_on_reward_screen.queue_free()
	_game_on_reward_screen = null
	_reward_reconnect_pending = false


func _show_post_recovery_choice() -> void:
	var choice := POST_RECOVERY_CHOICE_SCENE.instantiate()
	get_tree().root.add_child(choice)
	choice.continue_exploring.connect(_on_continue_exploring_requested)
	choice.main_menu_requested.connect(_on_recovery_main_menu_requested)


func _on_continue_exploring_requested() -> void:
	_restore_player()
	_clear_artifact()


func _on_recovery_main_menu_requested() -> void:
	GameState.save_game()
	_cleanup_game_on_reward()
	_clear_artifact()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://game/ui/menus/main_menu.tscn")


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
