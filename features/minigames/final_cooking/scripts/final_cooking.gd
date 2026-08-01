class_name FinalCooking
extends Control

const AUDIO_MANAGER_SCRIPT: Script = preload(
	"res://features/minigames/final_cooking/scripts/final_cooking_audio.gd"
)

signal cooking_sequence_completed
signal cooking_sequence_cancelled

enum CookingStage {
	CUTTING,
	ADD_INGREDIENTS_TO_POT,
	SEASON_BROTH,
	CRUSH_CHICHARON,
	ASSEMBLE_BATCHOY
}

const STAGE_SCENES: Array[PackedScene] = [
	preload("res://features/minigames/final_cooking/scenes/stages/cutting_stage.tscn"),
	preload("res://features/minigames/final_cooking/scenes/stages/add_to_pot_stage.tscn"),
	preload("res://features/minigames/final_cooking/scenes/stages/season_broth_stage.tscn"),
	preload("res://features/minigames/final_cooking/scenes/stages/crush_chicharon_stage.tscn"),
	preload("res://features/minigames/final_cooking/scenes/stages/assemble_batchoy_stage.tscn")
]

const FINAL_STAGE_ORDER: Array[int] = [
	CookingStage.CUTTING,
	CookingStage.ADD_INGREDIENTS_TO_POT,
	CookingStage.SEASON_BROTH,
	CookingStage.CRUSH_CHICHARON,
	CookingStage.ASSEMBLE_BATCHOY,
]

@export_range(0.0, 10.0, 0.05) var stage_transition_delay_seconds := 2.0
@export_range(0.0, 10.0, 0.05) var final_completion_delay_seconds := 3.0

var current_stage_index: int = CookingStage.CUTTING
var current_stage: FinalCookingStage
var stage_container: Control
var audio_manager: FinalCookingAudio
var transition_in_progress := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	audio_manager = AUDIO_MANAGER_SCRIPT.new() as FinalCookingAudio
	add_child(audio_manager)

	stage_container = Control.new()
	stage_container.name = "StageContainer"
	stage_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(stage_container)

	_load_current_stage()


## Called by the shared instruction overlay after its countdown finishes.
func start_after_instructions() -> void:
	audio_manager.start_music()


func _load_current_stage() -> void:
	_remove_current_stage()
	stage_container.visible = true

	if current_stage_index < 0 or current_stage_index >= STAGE_SCENES.size():
		$CollectibleEnding.play()
		return

	current_stage = STAGE_SCENES[current_stage_index].instantiate() as FinalCookingStage
	stage_container.add_child(current_stage)
	current_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current_stage.stage_completed.connect(_on_current_stage_completed, CONNECT_ONE_SHOT)
	current_stage.start_stage()


func _on_current_stage_completed() -> void:
	if transition_in_progress:
		return
	transition_in_progress = true
	var sequence_position := FINAL_STAGE_ORDER.find(current_stage_index)
	if sequence_position < 0 or sequence_position >= FINAL_STAGE_ORDER.size() - 1:
		audio_manager.play_sfx("final_complete", -2.0)
		audio_manager.stop_music()
		await get_tree().create_timer(final_completion_delay_seconds).timeout
		_remove_current_stage()
		$CollectibleEnding.play()
		return

	current_stage_index = FINAL_STAGE_ORDER[sequence_position + 1]
	audio_manager.play_sfx("stage_complete", -4.0)
	await get_tree().create_timer(stage_transition_delay_seconds).timeout
	_load_current_stage()
	transition_in_progress = false


func _remove_current_stage() -> void:
	if current_stage == null:
		return
	current_stage.cleanup_stage()
	current_stage.queue_free()
	current_stage = null
