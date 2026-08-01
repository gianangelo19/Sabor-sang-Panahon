extends SceneTree

const MINIGAME_SESSION_SCRIPT := preload(
	"res://features/minigames/shared/scripts/minigame_session.gd"
)
const ROUTES := [
	{
		"scene": "res://features/minigames/box_unboxing/scenes/box_unboxing.tscn",
		"success": "minigame_finished",
		"failure": "minigame_failed",
		"retry": true,
	},
	{
		"scene": "res://features/minigames/snatch_battle/scenes/snatch_battle.tscn",
		"success": "minigame_completed",
		"failure": "minigame_failed",
		"retry": true,
	},
	{
		"scene": "res://features/minigames/guinamos_jar_pick/scenes/guinamos_jar_pick.tscn",
		"success": "minigame_completed",
		"success_score": true,
		"failure": "minigame_failed",
		"failure_score": true,
		"retry": true,
	},
	{
		"scene": "res://features/minigames/egg_sorting/scenes/egg_sorting.tscn",
		"success": "minigame_completed",
		"failure": "minigame_failed",
		"retry": true,
	},
	{
		"scene": "res://features/minigames/chicharon_beat/scenes/chicharon_beat.tscn",
		"success": "minigame_finished",
		"failure": "minigame_failed",
		"failure_score": true,
		"retry": true,
	},
	{
		"scene": "res://features/minigames/miki_noodle_crank/scenes/miki_noodle_crank.tscn",
		"success": "minigame_finished",
		"failure": "minigame_failed",
		"retry": true,
	},
	{
		"scene": "res://features/minigames/final_cooking/scenes/final_cooking.tscn",
		"success": "cooking_sequence_completed",
		"failure": "cooking_sequence_cancelled",
		"retry": false,
	},
]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for route: Dictionary in ROUTES:
		await _verify_route(route)
	_finish()


func _verify_route(route: Dictionary) -> void:
	var scene := load(str(route.scene)) as PackedScene
	var result := {"won": false, "dismissed": false}
	var session: CanvasLayer = MINIGAME_SESSION_SCRIPT.new()
	root.add_child(session)
	session.minigame_won.connect(func(): result.won = true)
	session.dismissed.connect(func(): result.dismissed = true)
	session.start(scene)
	await process_frame
	var minigame: Node = session.get_minigame()
	_check(minigame.has_signal(StringName(route.success)), str(route.scene) + " exposes success")
	_check(minigame.has_signal(StringName(route.failure)), str(route.scene) + " exposes dismissal")
	if bool(route.retry):
		_check(minigame.has_signal("minigame_retry_requested"), str(route.scene) + " exposes retry")
		var first_instance_id := minigame.get_instance_id()
		minigame.emit_signal("minigame_retry_requested")
		await process_frame
		minigame = session.get_minigame()
		_check(
			minigame.get_instance_id() != first_instance_id,
			str(route.scene) + " retry creates a fresh game instance",
		)
	_emit_result(minigame, StringName(route.success), bool(route.get("success_score", false)))
	await process_frame
	_check(result.won and not result.dismissed, str(route.scene) + " routes completion as a win")

	result = {"won": false, "dismissed": false}
	session = MINIGAME_SESSION_SCRIPT.new()
	root.add_child(session)
	session.minigame_won.connect(func(): result.won = true)
	session.dismissed.connect(func(): result.dismissed = true)
	session.start(scene)
	await process_frame
	minigame = session.get_minigame()
	_emit_result(minigame, StringName(route.failure), bool(route.get("failure_score", false)))
	await process_frame
	_check(result.dismissed and not result.won, str(route.scene) + " routes failure as dismissal")


func _emit_result(minigame: Node, signal_name: StringName, with_score: bool) -> void:
	if with_score:
		minigame.emit_signal(signal_name, 50)
	else:
		minigame.emit_signal(signal_name)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	paused = false
	if failures.is_empty():
		print("Minigame session signal verification passed.")
		quit(0)
	else:
		print("Minigame session signal verification failed: " + ", ".join(failures))
		quit(1)
