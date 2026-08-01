extends SceneTree

const FINAL_SCENE := preload(
	"res://features/minigames/final_cooking/scenes/final_cooking.tscn"
)
const SEASON_SCENE := preload(
	"res://features/minigames/final_cooking/scenes/stages/season_broth_stage.tscn"
)
const CRUSH_SCENE := preload(
	"res://features/minigames/final_cooking/scenes/stages/crush_chicharon_stage.tscn"
)
const ASSEMBLY_SCENE := preload(
	"res://features/minigames/final_cooking/scenes/stages/assemble_batchoy_stage.tscn"
)

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _verify_seasoning_recovery()
	await _verify_chicharon_recovery()
	await _verify_assembly_prompts()
	await _verify_complete_stage_sequence()
	_finish()


func _verify_seasoning_recovery() -> void:
	var stage := SEASON_SCENE.instantiate()
	root.add_child(stage)
	await process_frame
	var target: Vector2 = stage.seasonings[stage.requested_index]["target"]
	stage.current_amount = target.y + 1.0
	stage._evaluate_pour(stage.requested_index)
	_check(is_zero_approx(stage.current_amount), "Over-pouring seasoning resets the meter")
	_check(not stage.input_locked, "Over-pouring leaves seasoning input available for a retry")
	stage.current_amount = target.x
	stage._evaluate_pour(stage.requested_index)
	_check(
		bool(stage.seasonings[stage.requested_index]["completed"]),
		"A valid retry completes the requested seasoning",
	)
	stage.queue_free()
	await process_frame


func _verify_chicharon_recovery() -> void:
	var stage := CRUSH_SCENE.instantiate()
	root.add_child(stage)
	await process_frame
	stage.crush_count = stage.perfect_end + 1
	stage.confirm_button.disabled = false
	stage._on_confirm_pressed()
	_check(stage.crush_count == 0, "Confirming powdered chicharon provides a fresh pile")
	_check(stage.pile.texture == stage.WHOLE_TEXTURE, "The fresh chicharon pile restores its artwork")
	_check(stage.confirm_button.disabled, "The reset pile must be crushed before confirming")
	stage.queue_free()
	await process_frame


func _verify_assembly_prompts() -> void:
	var stage := ASSEMBLY_SCENE.instantiate()
	root.add_child(stage)
	await process_frame
	stage._assembly_accept_component(stage.AssemblyDragType.MIKI)
	stage._assembly_accept_component(stage.AssemblyDragType.EGG_BOWL)
	_check(
		stage.assembly_phase == stage.AssemblyPhase.CRACK_EGG,
		"Placing the egg bowl advances to the egg-cracking phase",
	)
	_check(stage.assembly_raw_egg_sprite.visible, "The raw egg appears for the cracking step")
	_check(
		stage.assembly_status_label.text == "CLICK THE EGG TO CRACK IT",
		"The assembly HUD ends on the next actionable egg instruction",
	)
	stage.queue_free()
	await process_frame


func _verify_complete_stage_sequence() -> void:
	var game := FINAL_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	var instructions: Node = game.get_node_or_null("InstructionDialogue")
	if instructions != null:
		instructions.queue_free()
	paused = false
	game.stage_transition_delay_seconds = 0.01
	game.final_completion_delay_seconds = 0.01
	_check(not game.audio_manager.music_player.playing, "Final-cooking music waits for instructions")
	game.start_after_instructions()
	_check(game.audio_manager.music_player.playing, "Final-cooking music starts after instructions")

	for expected_index: int in range(game.STAGE_SCENES.size()):
		_check(game.current_stage_index == expected_index, "Final cooking reaches stage %d" % (expected_index + 1))
		_check(game.current_stage != null, "Final cooking stage %d is instantiated" % (expected_index + 1))
		game.current_stage.complete_stage()
		await create_timer(0.04).timeout

	_check(game.get_node("CollectibleEnding")._active, "Completing every stage opens the batchoy reward")
	_check(not game.audio_manager.music_player.playing, "Final-cooking music stops before the reward")
	game.queue_free()
	await process_frame
	paused = false


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	paused = false
	if failures.is_empty():
		print("Final-cooking flow verification passed.")
		quit(0)
	else:
		print("Final-cooking flow verification failed: " + ", ".join(failures))
		quit(1)
