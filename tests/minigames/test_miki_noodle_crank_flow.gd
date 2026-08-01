extends SceneTree

const MINIGAME_SESSION_SCRIPT := preload(
	"res://features/minigames/shared/scripts/minigame_session.gd"
)
const MIKI_SCENE := preload(
	"res://features/minigames/miki_noodle_crank/scenes/miki_noodle_crank.tscn"
)

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: CanvasLayer = MINIGAME_SESSION_SCRIPT.new()
	root.add_child(session)
	session.start(MIKI_SCENE)
	await process_frame
	var game: Node = session.get_minigame()

	_check(game != null, "Miki noodle crank instantiates in a shared session")
	if game == null:
		_finish()
		return
	_check(
		game.hud.layer > session.layer and game.hud.layer < game.dialogue.layer,
		"The Miki HUD renders above gameplay and below shared dialogue",
	)
	_check(game.warning_markers.size() == game.max_strikes, "Every allowed strike has a HUD marker")
	_check(not game.music_player.playing, "Miki music waits for the instruction overlay")
	_check(not game.ambience_player.playing, "Miki ambience waits for the instruction overlay")
	_check(
		game.music_player.stream is AudioStreamOggVorbis
		and (game.music_player.stream as AudioStreamOggVorbis).loop,
		"Miki music loops at runtime",
	)
	_check(
		game.ambience_player.stream is AudioStreamOggVorbis
		and (game.ambience_player.stream as AudioStreamOggVorbis).loop,
		"Miki ambience loops at runtime",
	)
	_check(
		game.extrusion_player.stream is AudioStreamOggVorbis
		and (game.extrusion_player.stream as AudioStreamOggVorbis).loop,
		"The noodle extrusion sound loops while noodles move",
	)

	var instructions: Node = game.get_node_or_null("InstructionDialogue")
	if instructions != null:
		instructions.queue_free()
	paused = false
	game.start_after_instructions()
	_check(game.gameplay_started, "Finishing instructions enables the crank")
	_check(game.music_player.playing, "Finishing instructions starts Miki music")
	_check(game.ambience_player.playing, "Finishing instructions starts Miki ambience")

	game.progress = 0.0
	game.tension = 0.5
	game.sweet_center = 0.5
	game.sweet_size = 0.25
	game._update_gameplay(1.0)
	game._update_hud()
	_check(
		game.progress >= 0.13,
		"One steady second in the green zone visibly advances noodle progress",
	)
	_check(
		game.progress_green.region_rect.size.x >= 53.0,
		"The progress HUD visibly fills as noodle progress advances",
	)
	var earned_progress: float = game.progress
	game.tension = 0.8
	game._update_gameplay(1.0)
	_check(
		is_equal_approx(game.progress, earned_progress),
		"Leaving the green zone pauses progress without erasing earned noodles",
	)
	var previous_tension: float = game.tension
	game.crank()
	_check(game.tension > previous_tension, "Cranking raises the dough tension")

	game._finish_success()
	_check(game.game_finished, "Miki success locks further gameplay")
	_check(not game.music_player.playing, "Miki success stops authored music")
	_check(not game.ambience_player.playing, "Miki success stops authored ambience")

	session.queue_free()
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
		print("Miki noodle-crank flow verification passed.")
		quit(0)
	else:
		print("Miki noodle-crank flow verification failed: " + ", ".join(failures))
		quit(1)
