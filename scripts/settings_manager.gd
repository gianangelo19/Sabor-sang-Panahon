extends Node

const SETTINGS_FILE_PATH = "user://settings.cfg"
var config = ConfigFile.new()

var master_bus_index: int
var music_bus_index: int
var sfx_bus_index: int

func _ready():
	master_bus_index = AudioServer.get_bus_index("Master")
	music_bus_index = AudioServer.get_bus_index("Music")
	sfx_bus_index = AudioServer.get_bus_index("SFX")
	
	load_settings()
	# Reapply after the root viewport finishes loading project defaults.
	call_deferred("apply_graphics_settings")

func load_settings():
	if config.load(SETTINGS_FILE_PATH) != OK:
		# Default settings
		config.set_value("Audio", "Master", 1.0)
		config.set_value("Audio", "Music", 1.0)
		config.set_value("Audio", "SFX", 1.0)
		config.set_value("Graphics", "Quality", "Balanced")
		config.set_value("Graphics", "FPSLimit", 60)
		save_settings()
	else:
		var added_graphics_defaults := false
		if not config.has_section_key("Graphics", "Quality"):
			config.set_value("Graphics", "Quality", "Balanced")
			added_graphics_defaults = true
		if not config.has_section_key("Graphics", "FPSLimit"):
			config.set_value("Graphics", "FPSLimit", 60)
			added_graphics_defaults = true
		if added_graphics_defaults:
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
	popup.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	popup.size = Vector2(420, 560)
	popup.exclusive = true
	popup.transient = true
	
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Add some margins
	vbox.add_theme_constant_override("separation", 15)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	margin.add_child(vbox)
	panel.add_child(margin)
	
	var title = Label.new()
	title.text = "Audio Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	# Master Slider
	var master_hbox = VBoxContainer.new()
	var master_label = Label.new()
	master_label.text = "Master Volume"
	var master_slider = HSlider.new()
	master_slider.max_value = 1.0
	master_slider.step = 0.05
	master_slider.value = get_bus_volume(master_bus_index)
	master_slider.value_changed.connect(func(value): set_bus_volume(master_bus_index, value))
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
	sfx_hbox.add_child(sfx_label)
	sfx_hbox.add_child(sfx_slider)
	vbox.add_child(sfx_hbox)

	var graphics_title = Label.new()
	graphics_title.text = "Graphics Settings"
	graphics_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	graphics_title.add_theme_font_size_override("font_size", 24)
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
	quality_picker.item_selected.connect(func(index): set_graphics_quality(quality_picker.get_item_text(index)))
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
	fps_picker.item_selected.connect(func(index): set_fps_limit(fps_picker.get_item_id(index)))
	fps_box.add_child(fps_label)
	fps_box.add_child(fps_picker)
	vbox.add_child(fps_box)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(popup.queue_free)
	vbox.add_child(close_btn)
	
	parent.add_child(popup)
	popup.popup_centered()
