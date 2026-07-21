extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	# Recreate the hierarchy used by the La Paz cutscene so the jeep's
	# AnimationPlayer lookup resolves during _ready().
	var animation_player := AnimationPlayer.new()
	var path := Node3D.new()
	var path_follow := Node3D.new()
	animation_player.add_child(path)
	path.add_child(path_follow)
	root.add_child(animation_player)

	var jeep := (load("res://jeepney.tscn") as PackedScene).instantiate()
	path_follow.add_child(jeep)
	await process_frame

	var cruising_player: AudioStreamPlayer = jeep.audio_cruising
	_check(cruising_player != null, "The jeep creates its cruising audio player")
	_check(
		cruising_player.stream.resource_path.ends_with("jeepney_cruising_subtle_loop.ogg"),
		"The jeep uses the recorded-engine cruising replacement",
	)
	_check(cruising_player.volume_db == -8.0, "Cruising playback is quieter but clearly audible")
	_check(
		cruising_player.get_class() == "AudioStreamPlayer",
		"Interior cruising audio is not reduced by 3D distance attenuation",
	)
	_check(
		(cruising_player.stream as AudioStreamOggVorbis).loop,
		"The replacement uses native seamless looping",
	)
	jeep.current_state = 1 # State.RIDING
	jeep._update_audio()
	await process_frame
	_check(cruising_player.playing, "Entering the riding state starts the cruising sound")

	animation_player.queue_free()
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
		print("Jeepney cruising audio verification passed.")
		quit(0)
	else:
		print("Jeepney cruising audio verification failed: " + ", ".join(failures))
		quit(1)
