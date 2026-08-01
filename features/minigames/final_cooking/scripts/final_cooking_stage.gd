class_name FinalCookingStage
extends Control

signal stage_started
signal stage_completed
signal stage_restarted

var has_completed: bool = false
var background_node: TextureRect = null


func start_stage() -> void:
	has_completed = false
	show()
	stage_started.emit()


func complete_stage() -> void:
	if has_completed:
		return

	has_completed = true
	stage_completed.emit()


func restart_stage() -> void:
	has_completed = false
	stage_restarted.emit()
	start_stage()


func skip_stage() -> void:
	complete_stage()


func play_cooking_sfx(
	sound_name: String,
	volume_db := -5.0,
	pitch_scale := 1.0
) -> void:
	var audio := get_tree().get_first_node_in_group("final_cooking_audio") as FinalCookingAudio
	if audio != null:
		audio.play_sfx(sound_name, volume_db, pitch_scale)


func cleanup_stage() -> void:
	_clear_runtime_nodes()


func _build_background(texture_path: String) -> TextureRect:
	if not ResourceLoader.exists(texture_path):
		push_error("FinalCookingStage: Background not found: %s" % texture_path)
		return null

	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_error("FinalCookingStage: Failed to load background: %s" % texture_path)
		return null

	var background := TextureRect.new()
	background.name = "Background"
	background.texture = texture
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(background)
	move_child(background, 0)
	background_node = background

	return background


func _clear_runtime_nodes() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	background_node = null
