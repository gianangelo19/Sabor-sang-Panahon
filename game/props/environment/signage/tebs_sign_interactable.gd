extends Node3D

const DIALOGUE_SCENE := preload("res://game/ui/dialogue/dialogue_ui.tscn")
const PLAYER_PORTRAIT := preload("res://assets/art/characters/2main_character_asking.png")

@export var covered_texture: Texture2D
@export var revealed_texture: Texture2D
@export var sign_mesh_path: NodePath = ^"MeshInstance3D"
@export var revealed_clue := "Teb's Old La Paz Batchoyan signage revealed."
@export var reveal_objective := "Find the hidden Batchoy Bowl artifact."
@export var reveal_status := "Cultural echoes detected around the old home."
@export var reveal_duration := 0.8

var _mesh: MeshInstance3D
var _material: StandardMaterial3D
var _revealed := false
var _revealing := false
var _dialogue_active := false
var _player: Node
var _player_was_movable := true


func _ready() -> void:
	_mesh = get_node_or_null(sign_mesh_path) as MeshInstance3D
	_prepare_material()
	_revealed = GameState.clues.has(revealed_clue)
	_apply_texture(revealed_texture if _revealed else covered_texture)


func get_interaction_text() -> String:
	if _revealed:
		if GameState.final_hunt_active:
			return "Cultural echoes active — find the Batchoy Bowl"
		if not GameState.final_hunt_succeeded:
			return "Press F to recall Teb's sign"
		return "Press F to inspect Teb's sign"
	if _has_required_ingredients():
		return "Press F to uncover Teb's sign"
	return "Press F to inspect covered sign"


func interact() -> void:
	if _revealing or _dialogue_active:
		return
	if _revealed:
		if not GameState.final_hunt_active and not GameState.final_hunt_succeeded:
			_start_reveal_dialogue()
		else:
			print("The sign reads: Teb's Old La Paz Batchoyan.")
		return
	if not _has_required_ingredients():
		_start_incomplete_dialogue()
		return

	_reveal_sign()


func _prepare_material() -> void:
	if _mesh == null:
		return
	var base_material := _mesh.get_active_material(0) as StandardMaterial3D
	if base_material:
		_material = base_material.duplicate() as StandardMaterial3D
	else:
		_material = StandardMaterial3D.new()
	_material.resource_local_to_scene = true
	_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.albedo_color = Color(1, 1, 1, 1)
	_mesh.material_override = _material


func _has_required_ingredients() -> bool:
	return GameState.has_all_story_ingredients()


func _reveal_sign() -> void:
	_revealing = true
	_revealed = true
	GameState.add_clue(revealed_clue)
	GameState.set_objective(reveal_objective)
	GameState.set_ambot_status(reveal_status)

	if _material == null:
		_apply_texture(revealed_texture)
		_finish_reveal()
		return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(Callable(self, "_set_material_brightness"), 1.0, 0.35, reveal_duration * 0.45)
	tween.tween_callback(Callable(self, "_swap_to_revealed_texture"))
	tween.tween_method(Callable(self, "_set_material_brightness"), 0.35, 1.0, reveal_duration * 0.55)
	tween.tween_callback(Callable(self, "_finish_reveal"))


func _apply_texture(texture: Texture2D) -> void:
	if _material == null or texture == null:
		return
	_material.albedo_texture = texture
	_set_material_brightness(1.0)


func _swap_to_revealed_texture() -> void:
	if _material == null or revealed_texture == null:
		return
	_material.albedo_texture = revealed_texture
	_set_material_brightness(0.35)


func _set_material_brightness(brightness: float) -> void:
	if _material == null:
		return
	var value := clampf(brightness, 0.0, 1.0)
	_material.albedo_color = Color(value, value, value, 1.0)


func _finish_reveal() -> void:
	_revealing = false
	_start_reveal_dialogue()


func _start_incomplete_dialogue() -> void:
	_dialogue_active = true
	_lock_player()
	var dialogue := DIALOGUE_SCENE.instantiate()
	get_tree().root.add_child(dialogue)
	dialogue.start_conversation([
		{"speaker": "You", "text": "Whatever is under this cloth has been collecting dust longer than I've been collecting bad decisions.", "portrait": PLAYER_PORTRAIT},
		{"speaker": "AMBot", "text": "The covering is fragile. Complete the ingredient evidence first; then we can examine the sign without guessing.", "portrait": null},
	])
	dialogue.dialogue_finished.connect(_on_incomplete_dialogue_finished)


func _on_incomplete_dialogue_finished() -> void:
	_dialogue_active = false
	_restore_player()


func _start_reveal_dialogue() -> void:
	if _dialogue_active or GameState.final_hunt_active or GameState.final_hunt_succeeded:
		return
	_dialogue_active = true
	_lock_player()
	var dialogue := DIALOGUE_SCENE.instantiate()
	get_tree().root.add_child(dialogue)
	dialogue.start_conversation([
		{"speaker": "You", "text": "Teb's Old La Paz Batchoyan?", "portrait": PLAYER_PORTRAIT},
		{"speaker": "You", "text": "Batchoy...", "portrait": PLAYER_PORTRAIT},
		{"speaker": "You", "text": "That's the word! Lola used to serve it to me here—after school, during rain, or whenever I pretended I wasn't hungry.", "portrait": PLAYER_PORTRAIT},
		{"speaker": "You", "text": "The house was not beside the story. It was the story.", "portrait": PLAYER_PORTRAIT},
		{"speaker": "AMBot", "text": "Physical record confirmed. Dish identity: La Paz Batchoy. Confidence: ninety-nine percent.", "portrait": null},
		{"speaker": "You", "text": "Why does remembering it feel less like learning something and more like finding a room I forgot was in my own house?", "portrait": PLAYER_PORTRAIT},
		{"speaker": "AMBot", "text": "Because the evidence is connected to lived experience. I am also detecting repeating audio-visual anomalies nearby.", "portrait": null},
		{"speaker": "You", "text": "Cultural Echoes. If the sign survived, maybe the old Batchoy Bowl did too.", "portrait": PLAYER_PORTRAIT},
		{"speaker": "AMBot", "text": "Search the property. The echoes intensify near objects with a strong connection to the old batchoyan.", "portrait": null},
	])
	dialogue.dialogue_finished.connect(_on_reveal_dialogue_finished)


func _on_reveal_dialogue_finished() -> void:
	_dialogue_active = false
	_restore_player()
	var hunt_director := get_tree().get_first_node_in_group("final_artifact_hunt")
	if hunt_director and hunt_director.has_method("start_hunt"):
		hunt_director.start_hunt()
	else:
		push_error("Teb's sign could not find the final artifact hunt director.")


func _lock_player() -> void:
	_player = get_tree().root.find_child("ProtoController", true, false)
	if _player == null:
		return
	_player_was_movable = _player.can_move
	_player.can_move = false
	_player.set_process_unhandled_input(false)
	_player.release_mouse()


func _restore_player() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_player.can_move = _player_was_movable
	_player.set_process_unhandled_input(true)
	_player.capture_mouse()
