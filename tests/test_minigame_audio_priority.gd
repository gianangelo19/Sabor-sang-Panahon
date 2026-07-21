extends SceneTree

const MINIGAME_SESSION_SCRIPT := preload("res://scripts/minigame_session.gd")
const MIKI_SCENE := preload(
	"res://minigames-main/chicharon_beat/scripts/miki_noodle_crank.tscn"
)

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var music_bus_index := AudioServer.get_bus_index("Music")
	_check(music_bus_index >= 0, "The global Music bus exists")
	if music_bus_index < 0:
		_finish()
		return

	var original_mute := AudioServer.is_bus_mute(music_bus_index)
	AudioServer.set_bus_mute(music_bus_index, false)

	var session: CanvasLayer = MINIGAME_SESSION_SCRIPT.new()
	root.add_child(session)
	session._mute_global_music()
	_check(AudioServer.is_bus_mute(music_bus_index), "A minigame session mutes global music")
	session.queue_free()
	await process_frame
	_check(not AudioServer.is_bus_mute(music_bus_index), "Leaving a minigame restores global music")

	var miki := MIKI_SCENE.instantiate()
	root.add_child(miki)
	await process_frame
	var original_music_volume: float = miki.music_volume_db
	_check(
		miki.music_player != null and miki.music_player.bus == &"Master",
		"Miki minigame music bypasses the muted global Music bus"
	)
	miki.queue_free()
	await process_frame

	var quiet_session: CanvasLayer = MINIGAME_SESSION_SCRIPT.new()
	root.add_child(quiet_session)
	quiet_session.start(MIKI_SCENE)
	await process_frame
	var quiet_miki: Node = quiet_session.get_minigame()
	_check(
		is_equal_approx(
			quiet_miki.music_volume_db,
			original_music_volume - quiet_session.MINIGAME_AUDIO_REDUCTION_DB
		),
		"Shared minigame sessions lower authored audio levels"
	)
	quiet_session.queue_free()
	AudioServer.set_bus_mute(music_bus_index, original_mute)
	await process_frame
	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	if failures.is_empty():
		print("Minigame audio-priority verification passed.")
		quit(0)
	else:
		print("Minigame audio-priority verification failed: " + ", ".join(failures))
		quit(1)
