extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := load(
		"res://features/minigames/egg_sorting/scenes/egg_sorting.tscn"
	) as PackedScene
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	paused = false
	var instructions := game.get_node_or_null("InstructionDialogue")
	if instructions != null:
		instructions.queue_free()
	game.basket_root.position = game.BASKET_VISIBLE_POSITION
	if game.basket_tween != null:
		game.basket_tween.kill()

	_check(game.eggs.size() == game.TOTAL_EGGS, "Egg sorting creates every draggable egg")
	var egg_id := 0
	var egg: Dictionary = game.eggs[egg_id]
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	game._on_egg_input(root, press, 0, egg_id)
	_check(game.dragging_id == egg_id, "Pressing an egg begins a drag")

	# This point is visibly inside the lower half of the basket artwork. The old
	# y=560 cutoff rejected it even though the egg overlapped the basket.
	egg.area.global_position = Vector2(792, 600)
	game._finish_drag()
	_check(bool(game.eggs[egg_id].accepted), "An egg dropped on the visible lower basket is accepted")
	_check(game.eggs[egg_id].area.get_parent() == game.basket_root, "An accepted egg moves into the basket")

	var edge_position := Vector2(1090, 580)
	_check(
		game._egg_overlaps_basket(edge_position),
		"Egg collision overlap is accepted near the basket rim",
	)
	_check(
		not game._egg_overlaps_basket(Vector2(400, 600)),
		"Dropping clearly outside the basket remains rejected",
	)

	game.queue_free()
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
		print("Egg sorting drag-and-drop verification passed.")
		quit(0)
	else:
		print("Egg sorting drag-and-drop verification failed: " + ", ".join(failures))
		quit(1)
