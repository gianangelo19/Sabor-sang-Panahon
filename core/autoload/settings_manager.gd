extends Node

signal hud_visibility_changed(visible: bool)

const SETTINGS_FILE_PATH = "user://settings.cfg"
const UI_BUTTON_SOUND := preload("res://assets/audio/retro_filipino_pack/menu_button_press.wav")
const DIALOGUE_CONTINUE_SOUND := preload("res://assets/audio/retro_filipino_pack/dialogue_continue.wav")
var config = ConfigFile.new()

var master_bus_index: int
var music_bus_index: int
var sfx_bus_index: int
var _ui_button_player: AudioStreamPlayer
var _dialogue_continue_player: AudioStreamPlayer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	master_bus_index = AudioServer.get_bus_index("Master")
	music_bus_index = AudioServer.get_bus_index("Music")
	sfx_bus_index = AudioServer.get_bus_index("SFX")
	_ui_button_player = AudioStreamPlayer.new()
	_ui_button_player.stream = UI_BUTTON_SOUND
	_ui_button_player.bus = "SFX"
	add_child(_ui_button_player)
	_dialogue_continue_player = AudioStreamPlayer.new()
	_dialogue_continue_player.stream = DIALOGUE_CONTINUE_SOUND
	_dialogue_continue_player.bus = "SFX"
	add_child(_dialogue_continue_player)
	
	load_settings()
	# Reapply after the root viewport finishes loading project defaults.
	call_deferred("apply_graphics_settings")

func play_ui_button_sound() -> void:
	if _ui_button_player == null:
		return
	_ui_button_player.stop()
	_ui_button_player.play()

func play_dialogue_continue_sound() -> void:
	if _dialogue_continue_player == null:
		return
	_dialogue_continue_player.stop()
	_dialogue_continue_player.play()

func load_settings():
	if config.load(SETTINGS_FILE_PATH) != OK:
		# Default settings
		config.set_value("Audio", "Master", 1.0)
		config.set_value("Audio", "Music", 1.0)
		config.set_value("Audio", "SFX", 1.0)
		config.set_value("Graphics", "Quality", "Balanced")
		config.set_value("Graphics", "FPSLimit", 60)
		config.set_value("Interface", "HUDVisible", true)
		save_settings()
	else:
		var added_defaults := false
		if not config.has_section_key("Graphics", "Quality"):
			config.set_value("Graphics", "Quality", "Balanced")
			added_defaults = true
		if not config.has_section_key("Graphics", "FPSLimit"):
			config.set_value("Graphics", "FPSLimit", 60)
			added_defaults = true
		if not config.has_section_key("Interface", "HUDVisible"):
			config.set_value("Interface", "HUDVisible", true)
			added_defaults = true
		if added_defaults:
			save_settings()
	
	set_bus_volume(master_bus_index, config.get_value("Audio", "Master", 1.0))
	set_bus_volume(music_bus_index, config.get_value("Audio", "Music", 1.0))
	set_bus_volume(sfx_bus_index, config.get_value("Audio", "SFX", 1.0))
	apply_graphics_settings()

func save_settings():
	config.save(SETTINGS_FILE_PATH)

func set_bus_volume(bus_index: int, linear_volume: float):
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_volume))
	if bus_index == master_bus_index:
		config.set_value("Audio", "Master", linear_volume)
	elif bus_index == music_bus_index:
		config.set_value("Audio", "Music", linear_volume)
	elif bus_index == sfx_bus_index:
		config.set_value("Audio", "SFX", linear_volume)
	save_settings()

func get_bus_volume(bus_index: int) -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(bus_index))

func set_graphics_quality(quality: String) -> void:
	config.set_value("Graphics", "Quality", quality)
	apply_graphics_settings()
	save_settings()

func set_fps_limit(limit: int) -> void:
	config.set_value("Graphics", "FPSLimit", limit)
	Engine.max_fps = limit
	save_settings()

func set_hud_visible(visible: bool) -> void:
	var changed := visible != is_hud_visible()
	config.set_value("Interface", "HUDVisible", visible)
	save_settings()
	if changed:
		hud_visibility_changed.emit(visible)

func is_hud_visible() -> bool:
	return bool(config.get_value("Interface", "HUDVisible", true))

func apply_graphics_settings() -> void:
	var quality: String = config.get_value("Graphics", "Quality", "Balanced")
	var render_scale := 0.75
	match quality:
		"Performance":
			render_scale = 0.5
		"Quality":
			render_scale = 1.0
	get_tree().root.scaling_3d_scale = render_scale
	Engine.max_fps = int(config.get_value("Graphics", "FPSLimit", 60))

func show_settings_menu(parent: Node):
	var popup = Window.new()
	popup.title = "Settings"
	popup.process_mode = Node.PROCESS_MODE_ALWAYS
	popup.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	popup.size = Vector2(420, 620)
	popup.exclusive = true
	popup.transient = true
	
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("241d19")
	panel_style.border_color = Color("8c5d42")
	panel_style.set_border_width_all(6)
	panel_style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", panel_style)
	popup.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Add some margins
	vbox.add_theme_constant_override("separation", 12)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	margin.add_child(vbox)
	panel.add_child(margin)
	
	var title = Label.new()
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("ffd58a"))
	title.add_theme_font_size_override("font_size", 30)
	vbox.add_child(title)

	var audio_title = Label.new()
	audio_title.text = "AUDIO"
	audio_title.add_theme_color_override("font_color", Color("f9b05b"))
	audio_title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(audio_title)
	
	# Master Slider
	var master_hbox = VBoxContainer.new()
	var master_label = Label.new()
	master_label.text = "Master Volume"
	var master_slider = HSlider.new()
	master_slider.max_value = 1.0
	master_slider.step = 0.05
	master_slider.value = get_bus_volume(master_bus_index)
	master_slider.value_changed.connect(func(value): set_bus_volume(master_bus_index, value))
	master_slider.drag_started.connect(play_ui_button_sound)
	master_hbox.add_child(master_label)
	master_hbox.add_child(master_slider)
	vbox.add_child(master_hbox)
	
	# Music Slider
	var music_hbox = VBoxContainer.new()
	var music_label = Label.new()
	music_label.text = "Music Volume"
	var music_slider = HSlider.new()
	music_slider.max_value = 1.0
	music_slider.step = 0.05
	music_slider.value = get_bus_volume(music_bus_index)
	music_slider.value_changed.connect(func(value): set_bus_volume(music_bus_index, value))
	music_slider.drag_started.connect(play_ui_button_sound)
	music_hbox.add_child(music_label)
	music_hbox.add_child(music_slider)
	vbox.add_child(music_hbox)
	
	# SFX Slider
	var sfx_hbox = VBoxContainer.new()
	var sfx_label = Label.new()
	sfx_label.text = "SFX Volume"
	var sfx_slider = HSlider.new()
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05
	sfx_slider.value = get_bus_volume(sfx_bus_index)
	sfx_slider.value_changed.connect(func(value): set_bus_volume(sfx_bus_index, value))
	sfx_slider.drag_started.connect(play_ui_button_sound)
	sfx_hbox.add_child(sfx_label)
	sfx_hbox.add_child(sfx_slider)
	vbox.add_child(sfx_hbox)

	var graphics_title = Label.new()
	graphics_title.text = "GRAPHICS"
	graphics_title.add_theme_color_override("font_color", Color("f9b05b"))
	graphics_title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(graphics_title)

	var quality_box = VBoxContainer.new()
	var quality_label = Label.new()
	quality_label.text = "Graphics Quality"
	var quality_picker = OptionButton.new()
	quality_picker.add_item("Performance")
	quality_picker.add_item("Balanced")
	quality_picker.add_item("Quality")
	var current_quality: String = config.get_value("Graphics", "Quality", "Balanced")
	var selected_quality_index := 1
	for index in range(quality_picker.item_count):
		if quality_picker.get_item_text(index) == current_quality:
			selected_quality_index = index
			break
	quality_picker.select(selected_quality_index)
	quality_picker.item_selected.connect(func(index):
		play_ui_button_sound()
		set_graphics_quality(quality_picker.get_item_text(index))
	)
	quality_box.add_child(quality_label)
	quality_box.add_child(quality_picker)
	vbox.add_child(quality_box)

	var fps_box = VBoxContainer.new()
	var fps_label = Label.new()
	fps_label.text = "Frame Rate Limit"
	var fps_picker = OptionButton.new()
	fps_picker.add_item("30 FPS", 30)
	fps_picker.add_item("60 FPS", 60)
	fps_picker.add_item("Unlimited", 0)
	var current_fps: int = int(config.get_value("Graphics", "FPSLimit", 60))
	for index in range(fps_picker.item_count):
		if fps_picker.get_item_id(index) == current_fps:
			fps_picker.select(index)
			break
	fps_picker.item_selected.connect(func(index):
		play_ui_button_sound()
		set_fps_limit(fps_picker.get_item_id(index))
	)
	fps_box.add_child(fps_label)
	fps_box.add_child(fps_picker)
	vbox.add_child(fps_box)

	var interface_title = Label.new()
	interface_title.text = "INTERFACE"
	interface_title.add_theme_color_override("font_color", Color("f9b05b"))
	interface_title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(interface_title)

	var hud_toggle = CheckButton.new()
	hud_toggle.name = "HUDVisibilityToggle"
	hud_toggle.text = "Show Gameplay HUD"
	hud_toggle.tooltip_text = "Show prompts, notifications, navigation, and quick-access HUD elements"
	hud_toggle.button_pressed = is_hud_visible()
	hud_toggle.toggled.connect(func(enabled: bool):
		play_ui_button_sound()
		set_hud_visible(enabled)
	)
	vbox.add_child(hud_toggle)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var close_btn = Button.new()
	close_btn.text = "Close"
	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color("8c5d42")
	button_style.set_corner_radius_all(7)
	button_style.content_margin_top = 9
	button_style.content_margin_bottom = 9
	close_btn.add_theme_stylebox_override("normal", button_style)
	close_btn.pressed.connect(func():
		play_ui_button_sound()
		popup.queue_free()
	)
	vbox.add_child(close_btn)
	
	parent.add_child(popup)
	popup.popup_centered()
