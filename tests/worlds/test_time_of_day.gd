extends SceneTree

const TEST_SAVE_PATH := "user://codex_time_of_day_test_save.json"
const DAY_PANORAMA := preload("res://assets/citrus_orchard_road_puresky_4k.hdr")
const SUNSET_PANORAMA := preload("res://assets/bambanani_sunset_4k.hdr")
const TIME_OF_DAY_CONTROLLER := preload(
	"res://game/worlds/la_paz/time_of_day_controller.gd"
)

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	var original_save_path: String = game_state.save_file_path
	var original_autosave: bool = game_state.autosave_enabled
	game_state.save_file_path = TEST_SAVE_PATH
	game_state.autosave_enabled = false
	_remove_test_save()

	_verify_monotonic_progression(game_state)
	_verify_save_compatibility(game_state)
	await _verify_environment_profiles(game_state)
	_verify_authored_streetlights()

	game_state.reset()
	game_state.autosave_enabled = false
	_remove_test_save()
	game_state.save_file_path = original_save_path
	game_state.autosave_enabled = original_autosave
	_finish()


func _verify_monotonic_progression(game_state: Node) -> void:
	game_state.reset()
	var emitted_stages: Array[int] = []
	var record_stage := func(stage: int): emitted_stages.append(stage)
	game_state.time_of_day_changed.connect(record_stage)
	_check(game_state.advance_time_of_day(2), "A later checkpoint advances story time")
	_check(not game_state.advance_time_of_day(2), "Repeating a checkpoint is idempotent")
	_check(not game_state.advance_time_of_day(1), "An earlier checkpoint cannot rewind story time")
	_check(game_state.advance_time_of_day(99), "A future checkpoint advances up to the supported maximum")
	_check(game_state.time_of_day_stage == 8, "Time-of-day advancement clamps at stage 8")
	_check(emitted_stages == [2, 8], "Only real forward changes emit time_of_day_changed")
	game_state.time_of_day_changed.disconnect(record_stage)
	game_state.reset()
	_check(game_state.time_of_day_stage == 0, "New Game state begins at the 10:00 AM stage")


func _verify_save_compatibility(game_state: Node) -> void:
	game_state.reset()
	game_state.autosave_enabled = false
	game_state.advance_time_of_day(5)
	_check(game_state.save_game(), "A time-of-day save can be written")
	game_state.reset()
	game_state.load_game()
	_check(game_state.time_of_day_stage == 5, "Loading restores the exact saved stage")

	game_state.autosave_enabled = false
	game_state.reset()
	game_state.completed_destinations.assign([
		"market_vendor_1",
		"market_vendor_2",
		"herbs_vendor",
		"seasoning_vendor",
		"egg_vendor",
		"chicharon_vendor",
		"tindero",
	])
	_check(game_state.save_game(), "A legacy inference fixture can be written")
	var save_file := FileAccess.open(TEST_SAVE_PATH, FileAccess.READ)
	var legacy_data = JSON.parse_string(save_file.get_as_text())
	save_file.close()
	legacy_data.erase("time_of_day_stage")
	save_file = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	save_file.store_string(JSON.stringify(legacy_data))
	save_file.close()
	game_state.reset()
	game_state.load_game()
	_check(game_state.time_of_day_stage == 7, "An older vendor-complete save infers the 5:00 PM stage")

	game_state.autosave_enabled = false
	legacy_data["final_hunt_succeeded"] = true
	save_file = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	save_file.store_string(JSON.stringify(legacy_data))
	save_file.close()
	game_state.reset()
	game_state.load_game()
	_check(game_state.time_of_day_stage == 8, "An older recovered-bowl save infers dinner dusk")
	game_state.autosave_enabled = false


func _verify_environment_profiles(game_state: Node) -> void:
	game_state.reset()
	var fixture := Node3D.new()
	fixture.name = "TimeOfDayFixture"

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	var sky_material := PanoramaSkyMaterial.new()
	sky_material.panorama = DAY_PANORAMA
	environment.sky.sky_material = sky_material
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	world_environment.environment = environment
	fixture.add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "DirectionalLight3D"
	fixture.add_child(sun)

	var streetlight := OmniLight3D.new()
	streetlight.name = "TestStreetlight"
	streetlight.visible = false
	streetlight.light_energy = 0.0
	fixture.add_child(streetlight)
	streetlight.add_to_group("time_of_day_streetlight")

	var controller := TIME_OF_DAY_CONTROLLER.new()
	controller.name = "TimeOfDayController"
	fixture.add_child(controller)
	root.add_child(fixture)
	await process_frame
	await process_frame

	_check(controller.applied_stage == 0, "A loaded stage applies immediately when La Paz enters the tree")
	_check(is_equal_approx(controller.TRANSITION_DURATION, 2.5), "Live lighting changes use a 2.5 second transition")
	var previous_rotation: Vector3 = sun.rotation_degrees
	var previous_energy: float = sun.light_energy
	for stage in range(1, 9):
		controller.apply_stage(stage, false)
		_check(
			not sun.rotation_degrees.is_equal_approx(previous_rotation)
			or not is_equal_approx(sun.light_energy, previous_energy),
			"Stage %d changes the outdoor lighting profile" % stage,
		)
		previous_rotation = sun.rotation_degrees
		previous_energy = sun.light_energy

	controller.apply_stage(5, false)
	_check(
		controller._sky_material.panorama == DAY_PANORAMA,
		"Mid-afternoon keeps the authored daytime HDR",
	)
	_check(not streetlight.visible, "Streetlights remain off through 3:00 PM")
	controller.apply_stage(6, false)
	_check(
		controller._sky_material.panorama == SUNSET_PANORAMA,
		"The sunset HDR begins at the 4:00 PM checkpoint",
	)
	_check(not streetlight.visible, "Streetlights remain off at the first sunset stage")
	controller.apply_stage(7, false)
	_check(
		streetlight.visible and is_equal_approx(streetlight.light_energy, 0.4),
		"Streetlights fade in subtly at 5:00 PM",
	)
	controller.apply_stage(8, false)
	_check(
		streetlight.visible and is_equal_approx(streetlight.light_energy, 1.2),
		"Streetlights strengthen for the final dinner-time dusk",
	)
	_check(
		controller._environment.ambient_light_energy >= 0.4
		and controller._environment.background_energy_multiplier >= 0.6
		and controller._environment.tonemap_exposure >= 0.95,
		"Final dusk retains enough fill and exposure for navigation",
	)
	fixture.queue_free()
	await process_frame


func _verify_authored_streetlights() -> void:
	var la_paz_file := FileAccess.open("res://game/worlds/la_paz/la_paz.tscn", FileAccess.READ)
	var la_paz_source := la_paz_file.get_as_text()
	la_paz_file.close()
	_check(
		la_paz_source.count("instance=ExtResource(\"13_eoqxb\")") == 7,
		"La Paz retains exactly seven authored twin-arm streetlights",
	)
	_check(
		la_paz_source.contains("TimeOfDayController"),
		"The La Paz scene owns the global time-of-day controller",
	)
	var streetlight_scene := (
		load("res://game/props/environment/street_props/twin_arm_streetlight.tscn")
		as PackedScene
	)
	var streetlight_prop := streetlight_scene.instantiate()
	root.add_child(streetlight_prop)
	var lamp := streetlight_prop.get_node("EveningLamp") as OmniLight3D
	_check(lamp.is_in_group("time_of_day_streetlight"), "Every authored streetlight exposes its dusk lamp to the controller")
	_check(not lamp.shadow_enabled, "Dusk streetlights use inexpensive shadowless lamps")
	_check(not lamp.visible and is_zero_approx(lamp.light_energy), "Streetlights start disabled during daytime")
	streetlight_prop.queue_free()


func _remove_test_save() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	if failures.is_empty():
		print("Story-driven time-of-day verification passed.")
		quit(0)
	else:
		print("Story-driven time-of-day verification failed: " + ", ".join(failures))
		quit(1)
