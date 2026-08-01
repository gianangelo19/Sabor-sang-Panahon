extends SceneTree

const MINIGAME_SESSION_SCRIPT := preload(
	"res://features/minigames/shared/scripts/minigame_session.gd"
)
const SNATCH_SCENE := preload(
	"res://features/minigames/snatch_battle/scenes/snatch_battle.tscn"
)

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: CanvasLayer = MINIGAME_SESSION_SCRIPT.new()
	root.add_child(session)
	session.start(SNATCH_SCENE)
	await process_frame

	var game: Node = session.get_minigame()
	_check(game != null, "The story session creates Snatch Battle")
	if game == null:
		_finish()
		return

	_check(
		game.ui_layer.layer > session.layer,
		"The meat HUD renders above the shared gameplay canvas",
	)
	_check(
		game.order_board.visible
		and game.mistake_board.visible
		and game.order_value_labels.size() == 3,
		"Order counts and mistake limits are visible in the story session",
	)
	_check(
		game.order_value_labels.values().all(
			func(label: Label): return not label.text.is_empty()
		),
		"The HUD displays all three generated order amounts",
	)

	paused = false
	game.gameplay_active = true
	var required_piece: Node2D = game._spawn_piece("belly", false, false)
	var before_count := int(game.collected_amounts["belly"])
	# Simulate grabbing the meat off-center: the release pointer is just above
	# the target, while the visible cut is clearly overlapping the basket.
	required_piece.position = Vector2(615.0, 515.0)
	game.dragged_piece = required_piece
	game.drag_start_position = Vector2(400.0, 350.0)
	game._end_drag(Vector2(580.0, 480.0))
	await process_frame
	_check(
		int(game.collected_amounts["belly"]) == before_count + 1,
		"A required cut visibly overlapping the basket is accepted",
	)

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
		print("Snatch Battle HUD and basket verification passed.")
		quit(0)
	else:
		print("Snatch Battle HUD and basket verification failed: " + ", ".join(failures))
		quit(1)
