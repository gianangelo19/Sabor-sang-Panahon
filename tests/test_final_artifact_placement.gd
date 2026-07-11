extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	var original_autosave: bool = game_state.autosave_enabled
	game_state.autosave_enabled = false
	game_state.reset()

	var home := (load("res://lapaz_home.tscn") as PackedScene).instantiate()
	root.add_child(home)
	await physics_frame
	await physics_frame
	var director := home.get_node("FinalArtifactHunt")
	var valid_spots: Array[Marker3D] = director._get_valid_hiding_spots()
	_check(not valid_spots.is_empty(), "The home has at least one usable authored hiding marker")
	_check(valid_spots.size() >= 3, "The home retains multiple collision-safe locations for visible random variation")
	_check(valid_spots.size() <= 8, "Placement uses the eight authored hiding locations")
	_check(valid_spots.all(func(spot): return director._spot_is_clear(spot)), "Blocked wall and object markers are filtered out")

	var selected_spot: Marker3D = director._choose_hiding_spot(valid_spots)
	_check(selected_spot != null, "Offline procedural rules select a marker without an external service")
	game_state.record_final_hunt_placement("procedural", str(selected_spot.name), "First random test placement")
	var next_spot: Marker3D = director._choose_hiding_spot(valid_spots)
	_check(next_spot != null and next_spot.name != selected_spot.name, "The next search cannot reuse a marker already stored in the save")
	game_state.reset()

	var sign := home.get_node("Tebs Sign")
	sign._start_reveal_dialogue()
	await process_frame
	var sign_dialogue := root.find_child("dialogue_ui", true, false)
	_check(sign_dialogue != null, "Revealing the sign opens the discovery monologue")
	if sign_dialogue:
		_check(sign_dialogue.dialogue_lines.all(func(line): return str(line.get("speaker", "")) == "You"), "The sign discovery is entirely the player's inner monologue")
		_check(not sign_dialogue.npc_portrait.visible, "AMBot does not appear in the sign discovery")
		for line_index in range(sign_dialogue.dialogue_lines.size()):
			sign_dialogue._on_continue_pressed()
	await process_frame
	_check(game_state.final_hunt_active, "The countdown hunt starts after the discovery monologue")
	_check(game_state.final_hunt_placement_source == "procedural", "Placement source is recorded as procedural")
	_check(not game_state.final_hunt_placement_spot.is_empty(), "Selected hiding marker is recorded for save data")
	var artifacts := director.get_tree().get_nodes_in_group("batchoy_bowl_artifact")
	_check(not artifacts.is_empty(), "The Batchoy Bowl is spawned at one of the authored hiding markers")
	if not artifacts.is_empty():
		var artifact = artifacts[0]
		var recorded_marker := director.get_node_or_null(game_state.final_hunt_placement_spot) as Marker3D
		_check(recorded_marker != null and artifact.global_position.is_equal_approx(recorded_marker.global_position), "The artifact position matches the selected home marker")
		_check(artifact.broad_clue_distance >= 90.0, "Broad cultural clue logic reaches across the home area")
		_check(artifact.close_clue_distance >= 32.0, "Close artifact clue has an expanded search radius")
		_check(artifact.get_node("BrothCulturalClue").max_distance >= 55.0, "Broth audio reaches the close search area")
		_check(artifact.get_node("ArtifactCulturalClue").max_distance >= 110.0, "Artifact echo reaches across the home")
		artifact.interact()
		await process_frame
		var final_ending := root.find_child("FinalEndingScene", true, false)
		_check(final_ending != null, "Recovering the bowl starts the final ending before the artifact popup")
		var popup := root.find_child("ArtifactDiscoveryPopup", true, false)
		_check(popup == null, "The cultural artifact popup waits for the final ending")
		if final_ending:
			final_ending.ending_finished.emit()
			await process_frame
		popup = root.find_child("ArtifactDiscoveryPopup", true, false)
		_check(popup != null, "Finishing the ending opens the cultural artifact popup")
		if popup:
			var fact_text := popup.find_child("FactText", true, false) as Label
			var bowl_image := popup.find_child("BowlImage", true, false) as TextureRect
			_check(fact_text != null and fact_text.text.contains("La Paz district of Iloilo City"), "The popup includes a La Paz Batchoy fact")
			_check(bowl_image != null and bowl_image.texture.resource_path.ends_with("batchoy_bowl_artifact.png"), "The popup displays the recovered bowl")
			popup._dismiss()
			await process_frame
			var recovery_choice := root.find_child("PostRecoveryChoice", true, false)
			_check(recovery_choice != null, "Dismissing the artifact popup asks whether to explore or return to the menu")
			if recovery_choice:
				_check(recovery_choice.has_signal("main_menu_requested"), "The recovery choice offers a main-menu route")
				_check(recovery_choice.has_signal("continue_exploring"), "The recovery choice offers continued exploration")
				recovery_choice._choose_continue()
				await process_frame
			var ending_dialogue := root.find_child("dialogue_ui", true, false)
			_check(ending_dialogue != null, "Continuing exploration resumes Grandma's ending dialogue")
			if ending_dialogue:
				ending_dialogue.queue_free()
		_check(not game_state.grandma_left_for_medicine, "Grandma returns after the bowl is recovered")

	home.queue_free()
	await process_frame
	game_state.reset()
	game_state.add_clue("Teb's Old La Paz Batchoyan signage revealed.")
	game_state.record_final_hunt_placement("unavailable", "", "Previous placement failed")
	var resumed_home := (load("res://lapaz_home.tscn") as PackedScene).instantiate()
	root.add_child(resumed_home)
	await process_frame
	await process_frame
	_check(game_state.final_hunt_active, "A save with the sign already revealed automatically retries placement")
	_check(game_state.final_hunt_placement_source == "procedural", "Automatic retry replaces the stale unavailable state")
	resumed_home.queue_free()
	game_state.reset()
	game_state.autosave_enabled = original_autosave
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
		print("Final artifact procedural-placement verification passed.")
		quit(0)
	else:
		print("Final artifact procedural-placement verification failed: " + ", ".join(failures))
		quit(1)
