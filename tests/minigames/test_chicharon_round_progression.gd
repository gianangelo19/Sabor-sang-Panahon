extends SceneTree

const MINIGAME_SESSION_SCRIPT := preload(
	"res://features/minigames/shared/scripts/minigame_session.gd"
)

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := load(
		"res://features/minigames/chicharon_beat/scenes/chicharon_beat.tscn"
	) as PackedScene
	var session: CanvasLayer = MINIGAME_SESSION_SCRIPT.new()
	root.add_child(session)
	session.start(scene)
	await process_frame
	var game: Node = session.get_minigame()
	paused = false
	var instructions: Node = game.get_node_or_null("InstructionDialogue")
	if instructions != null:
		instructions.queue_free()

	_check(session.layer == 80, "The shared session uses its authored gameplay layer")
	_check(
		game.ui.layer > session.layer and game.ui.layer < game.dialogue.layer,
		"The Chicharon HUD renders above gameplay and below dialogue",
	)
	_check(game.performance_sprite.visible, "The performance panel is visible")
	_check(game.round_panel_sprite.visible, "The round panel is visible")
	_check(game.collected_label.text == "0 / 18", "The HUD shows the collection target")
	_check(game.wasted_label.text == "0 / 7", "The HUD shows the failure threshold")
	_check(game.round_label.text == "ROUND 1 / 5", "The HUD starts on Round 1 of 5")
	_check(
		game.ROUND_LINES.size() == game.round_defs.size() - 1,
		"Every between-round transition has vendor dialogue",
	)
	var maximum_available := 0
	for definition: Dictionary in game.round_defs:
		var pattern: Array = game._choose_pattern(str(definition.difficulty))
		maximum_available += pattern.size() + 1
	_check(
		game.required_collected <= maximum_available,
		"The five authored rounds contain enough pieces to meet the goal",
	)

	game.gameplay_active = true
	game.current_round_index = 0
	game.phase = game.RoundPhase.ROUND_END
	game._finish_round_sequence(0)
	await create_timer(1.2).timeout
	_check(game.current_round_index == 1, "Completing Round 1 advances to the Round 2 checkpoint")
	_check(game.waiting_for_round_continue, "Round 2 waits at its visible continue gate")
	_check(game.difficulty_label.text == "CLICK / SPACE", "The continue prompt shows both supported controls")

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	game._input(click)
	_check(not game.waiting_for_round_continue, "Left-click releases the between-round gate")
	_check(game.countdown_active, "Left-click starts the next-round countdown")
	await create_timer(1.4).timeout
	_check(game.current_round_index == 1, "The countdown keeps the correct Round 2 index")
	_check(game.phase == game.RoundPhase.ACTIVE, "Round 2 becomes active after the countdown")
	_check(game.expected_pieces > 0, "Round 2 creates a playable chicharon pattern")

	for completed_round: int in range(1, game.round_defs.size()):
		game.phase = game.RoundPhase.ROUND_END
		if completed_round == game.round_defs.size() - 1:
			game.collected = game.required_collected
		game._finish_round_sequence(completed_round)
		await create_timer(1.2).timeout
		if completed_round < game.round_defs.size() - 1:
			_check(
				game.current_round_index == completed_round + 1,
				"Round %d advances to Round %d" % [
					completed_round + 1,
					completed_round + 2,
				],
			)
			_check(game.waiting_for_round_continue, "Each later round exposes its continue gate")
			game._input(click)
			await create_timer(1.4).timeout
			_check(game.phase == game.RoundPhase.ACTIVE, "Each later round becomes active")
		else:
			_check(game.phase == game.RoundPhase.GAME_OVER, "Round 5 reaches the success state")
			_check(not game.gameplay_active, "Success stops active Chicharon gameplay")

	game.dialogue.advance()
	game.dialogue.advance()
	_check(game.result_emitted, "Closing the success dialogue starts result delivery once")
	_check(game.get_node("CollectibleEnding")._active, "Success opens the collectible reward sequence")

	session.queue_free()
	await process_frame
	paused = false

	var failure_session: CanvasLayer = MINIGAME_SESSION_SCRIPT.new()
	root.add_child(failure_session)
	failure_session.start(scene)
	await process_frame
	var failure_game: Node = failure_session.get_minigame()
	paused = false
	var failure_instructions: Node = failure_game.get_node_or_null("InstructionDialogue")
	if failure_instructions != null:
		failure_instructions.queue_free()
	failure_game.gameplay_active = true
	failure_game.phase = failure_game.RoundPhase.ACTIVE
	failure_game.wasted = failure_game.fail_wasted - 1
	failure_game.expected_pieces = 2
	var failed_piece := Node2D.new()
	failure_game.chicharon_container.add_child(failed_piece)
	failure_game.piece_indices[failed_piece.get_instance_id()] = 0
	failure_game._on_chicharon_removed("burnt", failed_piece)
	_check(failure_game.wasted == failure_game.fail_wasted, "The seventh wasted piece reaches the fail threshold")
	_check(failure_game.phase == failure_game.RoundPhase.GAME_OVER, "The fail threshold stops gameplay immediately")
	_check(failure_game.wasted_label.text == "7 / 7", "The HUD shows the terminal wasted count")
	_check(
		failure_game.fail_screen.current_state
		!= failure_game.fail_screen.FailState.IDLE,
		"The terminal failure opens the retry screen",
	)
	_check(
		failure_game.fail_screen.layer > failure_game.ui.layer,
		"The retry screen renders above the Chicharon HUD",
	)
	failure_session.queue_free()
	await process_frame
	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	paused = false
	if failures.is_empty():
		print("Chicharon round-progression verification passed.")
		quit(0)
	else:
		print("Chicharon round-progression verification failed: " + ", ".join(failures))
		quit(1)
