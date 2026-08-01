extends SceneTree

const AssetCredits := preload("res://game/ui/menus/asset_credits.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var menu_scene := load("res://game/ui/menus/main_menu.tscn") as PackedScene
	_check(menu_scene != null, "Main menu scene loads")
	if menu_scene == null:
		_finish()
		return

	var menu := menu_scene.instantiate()
	root.add_child(menu)
	await process_frame
	var settings_manager := root.get_node("SettingsManager")
	menu._music_player.stop()
	menu._music_player.stream = null
	settings_manager._ui_button_player.stop()
	settings_manager._ui_button_player.stream = null

	var credits_button := menu.get_node("%CreditsButton") as Button
	var credits_overlay := menu.get_node("%CreditsOverlay") as Control
	var credits_text := menu.get_node("%CreditsText") as RichTextLabel
	var close_button := menu.get_node("%CloseCreditsButton") as Button
	var menu_column := menu.get_node("MenuColumn") as VBoxContainer
	var continue_button := menu.get_node("%ContinueButton") as Button
	var footer := menu.get_node("Footer") as Label
	var background := menu.get_node("Background") as TextureRect
	var title_logo := menu.get_node("TitleLogo") as TextureRect
	var ai_disclaimer := menu.get_node("AiAssetDisclaimer") as RichTextLabel

	_check(
		background.texture.resource_path == "res://assets/art/images/main_menu_bg_v2.png",
		"Main menu uses the background with the old baked-in title removed",
	)
	_check(title_logo.texture is AtlasTexture, "Updated title logo is displayed as a separate UI layer")
	if title_logo.texture is AtlasTexture:
		var title_atlas := title_logo.texture as AtlasTexture
		_check(
			title_atlas.atlas.resource_path
			== "res://assets/art/images/title_sabor_sang_panahon_v2.png",
			"Title layer uses the supplied updated logo",
		)
	_check(
		ai_disclaimer.text.contains(
			"DISCLAIMER[/color]: SOME OF THE GAME ASSETS ARE AI GENERATED"
		)
			and ai_disclaimer.text.contains("[color=#ef4d43]DISCLAIMER[/color]")
			and ai_disclaimer.text.begins_with("[right]"),
		"AI asset disclaimer is right-aligned with its heading in red",
	)
	_check(credits_button != null and credits_button.text == "CREDITS", "Main menu has a Credits button")
	_check(credits_overlay != null and not credits_overlay.visible, "Credits start closed")
	var continue_was_visible := continue_button.visible
	continue_button.show()
	await process_frame
	_check(
		menu_column.position.y + menu_column.size.y <= footer.position.y,
		"All authenticated menu actions fit above the footer when Continue is available",
	)
	continue_button.visible = continue_was_visible

	credits_button.pressed.emit()
	await process_frame
	_check(credits_overlay.visible, "Credits button opens the credits overlay")
	_check(not menu_column.visible, "Credits overlay disables the menu controls behind it")
	_check(
		root.get_viewport().gui_get_focus_owner() == close_button,
		"Credits overlay moves keyboard focus to its Back button",
	)
	_check(credits_text.text.contains("POLY HAVEN"), "Credits include Poly Haven assets")
	_check(credits_text.text.contains("SKETCHFAB MODELS"), "Credits include Sketchfab models")
	_check(credits_text.text.contains("Kenney"), "Credits include the Kenney asset packs")
	_check(credits_text.text.contains("Kyle Fuji"), "Credits include the bedroom asset pack")
	_check(credits_text.text.contains("loafbrr"), "Credits include the toilets asset pack")
	_check(credits_text.text.contains("Lukky"), "Credits include the handpainted textures")
	_check(credits_text.text.contains("VCR OSD Mono"), "Credits include the downloaded typeface")
	var poly_haven_assets: Array = (
		AssetCredits.POLY_HAVEN_MODELS
		+ AssetCredits.POLY_HAVEN_MATERIALS
		+ AssetCredits.POLY_HAVEN_HDRIS
	)
	var all_poly_haven_assets_listed := true
	for asset in poly_haven_assets:
		if not credits_text.text.contains(asset):
			all_poly_haven_assets_listed = false
	_check(
		poly_haven_assets.size() == 42 and all_poly_haven_assets_listed,
		"All 42 downloaded Poly Haven assets are listed",
	)
	_check(AssetCredits.sketchfab_credit_count() == 50, "All 50 downloaded Sketchfab models are listed")
	_check(
		credits_text.text.count("sketchfab.com/3d-models/") == 50,
		"Every Sketchfab credit links to its source model",
	)
	var credits_scroll := credits_text.get_v_scroll_bar()
	_check(
		credits_scroll.max_value > credits_scroll.page,
		"The full attribution list is scrollable",
	)

	close_button.pressed.emit()
	await process_frame
	_check(not credits_overlay.visible, "Back button closes the credits overlay")
	_check(menu_column.visible, "Closing credits restores the main-menu controls")
	_check(
		root.get_viewport().gui_get_focus_owner() == credits_button,
		"Closing credits returns keyboard focus to Credits",
	)

	credits_button.pressed.emit()
	await process_frame
	var cancel_event := InputEventAction.new()
	cancel_event.action = "ui_cancel"
	cancel_event.pressed = true
	Input.parse_input_event(cancel_event)
	await process_frame
	_check(not credits_overlay.visible, "Escape closes the credits overlay")

	menu.free()
	await process_frame
	call_deferred("_finish")


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	if failures.is_empty():
		print("Main menu credits verification passed.")
		quit(0)
	else:
		print("Main menu credits verification failed: " + ", ".join(failures))
		quit(1)
