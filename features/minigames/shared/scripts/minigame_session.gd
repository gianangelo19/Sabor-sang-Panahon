extends CanvasLayer

signal minigame_won
signal dismissed

const GAMEPLAY_LAYER := 80
const GLOBAL_MUSIC_BUS := &"Music"
const MINIGAME_AUDIO_REDUCTION_DB := 8.0

var _minigame_scene: PackedScene
var _minigame_context: Dictionary = {}
var _minigame: Node
var _global_music_bus_index := -1
var _global_music_was_muted := false
var _has_muted_global_music := false
var _owns_pause := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("minigame_session")
	add_to_group("transient_gameplay_ui")
	get_tree().node_added.connect(_on_tree_node_added)


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	var hud := get_tree().root.find_child("GameHUD", true, false)
	if hud == null or not hud.has_method("toggle_pause"):
		return
	hud.toggle_pause()
	_owns_pause = bool(hud.pause_menu.visible)
	get_viewport().set_input_as_handled()


func start(scene: PackedScene, context: Dictionary = {}) -> void:
	_minigame_scene = scene
	_minigame_context = context
	if _minigame_scene != null and _minigame_context.has("time_of_day_stage"):
		var game_state := get_tree().root.get_node_or_null("GameState")
		if game_state != null:
			game_state.advance_time_of_day(
				int(_minigame_context.get("time_of_day_stage", 0))
			)
	layer = GAMEPLAY_LAYER
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_mute_global_music()
	_start_fresh_instance()


func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_on_tree_node_added):
		get_tree().node_added.disconnect(_on_tree_node_added)
	if _owns_pause:
		var hud := get_tree().root.find_child("GameHUD", true, false)
		if hud != null and hud.has_method("close_pause"):
			hud.close_pause(false)
	# An instruction, failure, or collectible overlay can own the paused state.
	# Once its session is gone there must not be a stale pause left on the world.
	if get_tree().paused:
		get_tree().paused = false
	_restore_global_music()


func _on_tree_node_added(node: Node) -> void:
	if node == self or not is_ancestor_of(node):
		return
	_attenuate_minigame_audio(node)


func _attenuate_minigame_audio(node: Node) -> void:
	if (
		node is AudioStreamPlayer
		or node is AudioStreamPlayer2D
		or node is AudioStreamPlayer3D
	):
		node.volume_db -= MINIGAME_AUDIO_REDUCTION_DB
		return

	for property in node.get_property_list():
		var property_name := String(property.get("name", ""))
		if not property_name.ends_with("_volume_db"):
			continue
		var property_type := int(property.get("type", TYPE_NIL))
		if property_type != TYPE_FLOAT and property_type != TYPE_INT:
			continue
		node.set(
			property_name,
			float(node.get(property_name)) - MINIGAME_AUDIO_REDUCTION_DB
		)


func get_minigame() -> Node:
	return _minigame


func _mute_global_music() -> void:
	if _has_muted_global_music:
		return
	_global_music_bus_index = AudioServer.get_bus_index(GLOBAL_MUSIC_BUS)
	if _global_music_bus_index < 0:
		return
	_global_music_was_muted = AudioServer.is_bus_mute(_global_music_bus_index)
	AudioServer.set_bus_mute(_global_music_bus_index, true)
	_has_muted_global_music = true


func _restore_global_music() -> void:
	if not _has_muted_global_music or _global_music_bus_index < 0:
		return
	AudioServer.set_bus_mute(
		_global_music_bus_index,
		_global_music_was_muted
	)
	_has_muted_global_music = false


func _start_fresh_instance() -> void:
	if _minigame != null and is_instance_valid(_minigame):
		remove_child(_minigame)
		_minigame.queue_free()
		_minigame = null

	if _minigame_scene == null:
		push_error("Cannot start a minigame session without a scene.")
		dismissed.emit()
		queue_free()
		return

	_minigame = _minigame_scene.instantiate()
	# The session must keep processing Escape while the tree is paused, but the
	# gameplay root must still obey the pause state instead of inheriting ALWAYS.
	_minigame.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_minigame)
	_connect_first_available(
		[
			&"minigame_finished",
			&"minigame_completed",
			&"cooking_sequence_completed",
		],
		_on_minigame_completed
	)
	_connect_first_available(
		[&"minigame_failed", &"cooking_sequence_cancelled"],
		_on_minigame_failed
	)
	_connect_first_available(
		[&"minigame_retry_requested"],
		_on_minigame_retry_requested
	)

func _connect_first_available(signal_names: Array[StringName], callback: Callable) -> void:
	for signal_name in signal_names:
		if _minigame.has_signal(signal_name):
			_minigame.connect(signal_name, callback)
			return


func _on_minigame_completed(_score: Variant = null) -> void:
	minigame_won.emit()
	queue_free()


func _on_minigame_failed(_score: Variant = null) -> void:
	dismissed.emit()
	queue_free()


func _on_minigame_retry_requested() -> void:
	call_deferred("_start_fresh_instance")
