extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var map := (load("res://la_paz.tscn") as PackedScene).instantiate()
	var street_player := map.get_node("StreetLapazAmbience")
	_check(
		street_player.get("audio_path") == "res://audio/ambience/la_paz_street_loop.ogg",
		"The map uses the new global street ambience",
	)

	var market := (load("res://lapaz_public_market.tscn") as PackedScene).instantiate()
	var market_player := market.get_node("MarketAmbience") as AudioStreamPlayer3D
	_check(
		market_player.get("audio_path") == "res://audio/ambience/la_paz_public_market_loop.ogg",
		"The public market has localized crowd ambience",
	)
	_check(market_player.max_distance == 34.0, "Market ambience stays localized to the market")

	var home := (load("res://lapaz_home.tscn") as PackedScene).instantiate()
	var home_player := home.get_node("LapazHomeAmbience") as AudioStreamPlayer3D
	_check(
		home_player.get("audio_path") == "res://audio/ambience/grandmas_house_loop.ogg",
		"Grandma's house uses its dedicated room ambience",
	)

	var apartment := (load("res://apartment.tscn") as PackedScene).instantiate()
	var apartment_player := apartment.get_node("ApartmentAmbience") as AudioStreamPlayer3D
	_check(
		apartment_player.get("audio_path") == "res://audio/ambience/apartment_room_loop.ogg",
		"The apartment uses its dedicated room ambience",
	)

	var loop_player := AudioStreamPlayer.new()
	loop_player.set_script(load("res://scripts/looping_audio_player.gd"))
	loop_player.set("audio_path", "res://audio/ambience/la_paz_street_loop.ogg")
	root.add_child(loop_player)
	await process_frame
	_check(loop_player.stream is AudioStreamOggVorbis, "The ambience OGG loads at runtime")
	_check(
		(loop_player.stream as AudioStreamOggVorbis).loop,
		"The ambience player enables native seamless looping",
	)
	_check(loop_player.playing, "The ambience starts automatically")

	loop_player.queue_free()
	map.free()
	market.free()
	home.free()
	apartment.free()
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
		print("Map ambience verification passed.")
		quit(0)
	else:
		print("Map ambience verification failed: " + ", ".join(failures))
		quit(1)
