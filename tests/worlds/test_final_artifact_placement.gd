extends SceneTree

const LONG_GAME_ON_DESCRIPTION := (
	"Born in the district of La Paz in Iloilo City, La Paz Batchoy is more "
	+ "than a noodle soup—it is a living record of the people who cooked, sold, "
	+ "and shared it across generations. Its history is tied to the public market "
	+ "and the meeting of culinary traditions with Ilonggo ingredients.\n\n"
	+ "At the heart of the bowl are fresh miki noodles and deeply flavored broth, "
	+ "traditionally enriched with pork, offal, garlic, scallions, and crushed "
	+ "chicharon. Every batchoyan has a method of their own, while every bowl "
	+ "carries the warmth and identity of Iloilo.\n\n"
	+ "The recovered bowl represents this living heritage. Finding it restores "
	+ "not only a forgotten recipe, but the stories, labor, and memories passed "
	+ "from one generation of Ilonggos to the next."
)

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	var original_autosave: bool = game_state.autosave_enabled
	game_state.autosave_enabled = false
	game_state.reset()

	var home := (load("res://game/worlds/la_paz/grandma_house/lapaz_home.tscn") as PackedScene).instantiate()
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
		_check(
			sign_dialogue.dialogue_lines.any(func(line): return str(line.get("speaker", "")) == "AMBot"),
			"The V3 sign discovery includes AMBot's physical-evidence confirmation",
		)
		_check(
			sign_dialogue.dialogue_lines.any(func(line): return str(line.get("speaker", "")) == "You"),
			"The player connects the sign to their lived memory",
		)
		for line_index in range(sign_dialogue.dialogue_lines.size()):
			sign_dialogue._complete_typewriter()
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
		var placeholder := root.find_child("VendorMinigamePlaceholder", true, false)
		_check(placeholder != null, "Recovering the bowl starts the artifact minigame placeholder")
		_check(game_state.time_of_day_stage == 8, "The final bowl challenge advances story time to dinner dusk")
		_check(
			not game_state.clues.has("Batchoy Bowl artifact recovered."),
			"Starting the artifact challenge does not award the bowl early",
		)
		_check(
			root.find_child("FinalEndingScene", true, false) == null,
			"The artifact placeholder replaces the former final ending scene",
		)
		var popup := root.find_child("ArtifactDiscoveryPopup", true, false)
		_check(popup == null, "The cultural artifact popup waits for challenge completion")
		if placeholder:
			placeholder.get_node("Panel/Stack/ReturnButton").pressed.emit()
			await process_frame
		_check(artifact.active and artifact.visible, "Dismissing the challenge restores the bowl")
		_check(game_state.final_hunt_active, "Dismissing the challenge resumes the active hunt")
		artifact.interact()
		await process_frame
		placeholder = root.find_child("VendorMinigamePlaceholder", true, false)
		_check(placeholder != null, "The restored bowl can launch the challenge again")
		_check(game_state.time_of_day_stage == 8, "Retrying the final challenge does not advance time again")
		if placeholder:
			placeholder.get_node("Panel/Stack/ContinueButton").pressed.emit()
			await process_frame
		popup = root.find_child("ArtifactDiscoveryPopup", true, false)
		_check(popup != null, "Completing the challenge opens the cultural artifact popup")
		_check(
			game_state.clues.has("Batchoy Bowl artifact recovered."),
			"Completing the challenge records the recovered bowl",
		)
		if popup:
			var game_on_reward = popup
			var bowl_image := game_on_reward.bowl_image as TextureRect
			_check(
				bowl_image.texture.resource_path.ends_with("batchoy_bowl_artifact.png"),
				"The styled GameOn popup retains the recovered bowl artwork",
			)
			_check(
				root.find_child("ArtifactSuccess", true, false) == null,
				"The ending does not use the default GameOn reward screen",
			)
			if game_on_reward:
				_check(
					game_on_reward.retry_button.visible
					and game_on_reward.retry_button.text == "RECONNECT & RETRY",
					"An expired GameOn session offers reconnect and retry",
				)
				game_on_reward._dismiss()
				await process_frame
				_check(
					not game_state.has_story_flag("game_on_artifact_reward_pending"),
					"Continuing without GameOn clears the saved retry prompt",
				)
				var skipped_reward_choice := root.find_child(
					"PostRecoveryChoice",
					true,
					false,
				)
				_check(
					skipped_reward_choice != null,
					"Continuing without GameOn preserves the normal recovery choice",
				)
				if skipped_reward_choice:
					skipped_reward_choice._choose_continue()
					await process_frame
				game_state.set_story_flag("game_on_artifact_reward_pending")
				director._show_game_on_reward()
				await process_frame
				game_on_reward = root.find_child(
					"ArtifactDiscoveryPopup",
					true,
					false,
				)
				director._on_game_on_artifact_unlocked(
					{
						"success": true,
						"artifact": {
							"name": "Old Batchoy Bowl",
							"description": LONG_GAME_ON_DESCRIPTION,
						},
					},
					true,
				)
				_check(
					game_on_reward.artifact_title.text == "OLD BATCHOY BOWL"
					and game_on_reward.description_text.text
					== LONG_GAME_ON_DESCRIPTION,
					"The local popup uses the GameOn artifact name and description",
				)
				await process_frame
				var reward_panel := game_on_reward.get_node(
					"Overlay/Center/Panel"
				) as PanelContainer
				var description_scroll := (
					game_on_reward.description_scroll
					as ScrollContainer
				)
				_check(
					reward_panel.size.y <= 600.0
					and game_on_reward.continue_button.visible
					and game_on_reward.continue_button.get_global_rect().end.y
					<= reward_panel.get_global_rect().end.y + 0.5,
					"Long GameOn text keeps the Continue button inside the fixed card",
				)
				_check(
					game_on_reward.description_text.size.y
					> description_scroll.size.y,
					"Long GameOn descriptions remain readable in a scroll region",
				)
				_check(
					game_state.has_story_flag("game_on_artifact_reward_claimed")
					and not game_state.has_story_flag("game_on_artifact_reward_pending"),
					"A confirmed GameOn reward clears its saved pending state",
				)
				game_on_reward._dismiss()
				await process_frame
			var recovery_choice := root.find_child("PostRecoveryChoice", true, false)
			_check(recovery_choice != null, "Closing the GameOn result preserves the post-recovery choice")
			if recovery_choice:
				_check(recovery_choice.has_signal("main_menu_requested"), "The recovery choice offers a main-menu route")
				_check(recovery_choice.has_signal("continue_exploring"), "The recovery choice offers continued exploration")
				recovery_choice._choose_continue()
				await process_frame
			_check(
				root.find_child("dialogue_ui", true, false) == null,
				"The final minigame is not followed by duplicate cooking dialogue",
			)
			_check(
				game_state.clues.has("La Paz Batchoy served to Grandma."),
				"Finishing the final minigame records the restored dish",
			)
			_check(
				game_state.current_objective
					== "Memory restored. Grandma remembers La Paz Batchoy.",
				"The final minigame advances directly to the restored-memory objective",
			)
		_check(not game_state.grandma_left_for_medicine, "Grandma returns after the bowl is recovered")

	home.queue_free()
	await process_frame
	game_state.reset()
	game_state.add_clue("Teb's Old La Paz Batchoyan signage revealed.")
	game_state.record_final_hunt_placement("unavailable", "", "Previous placement failed")
	var resumed_home := (load("res://game/worlds/la_paz/grandma_house/lapaz_home.tscn") as PackedScene).instantiate()
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
