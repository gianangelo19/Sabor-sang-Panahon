extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var settings := root.get_node("SettingsManager")
	var original_quality: String = settings.config.get_value("Graphics", "Quality", "Balanced")
	var original_fps: int = int(settings.config.get_value("Graphics", "FPSLimit", 60))
	await process_frame
	var expected_startup_scale := {"Performance": 0.5, "Balanced": 0.75, "Quality": 1.0}.get(original_quality, 0.75) as float
	_check(is_equal_approx(root.scaling_3d_scale, expected_startup_scale), "Saved graphics preset survives a startup-style deferred apply")

	settings.config.set_value("Graphics", "Quality", "Performance")
	settings.apply_graphics_settings()
	_check(is_equal_approx(root.scaling_3d_scale, 0.5), "Performance preset uses 50 percent render scale")

	settings.config.set_value("Graphics", "Quality", "Balanced")
	settings.apply_graphics_settings()
	_check(is_equal_approx(root.scaling_3d_scale, 0.75), "Balanced preset uses 75 percent render scale")

	settings.config.set_value("Graphics", "Quality", "Quality")
	settings.apply_graphics_settings()
	_check(is_equal_approx(root.scaling_3d_scale, 1.0), "Quality preset uses full render scale")

	settings.show_settings_menu(root)
	await process_frame
	var popup := root.get_child(root.get_child_count() - 1) as Window
	_check(popup != null, "Settings window opens")
	if popup:
		var pickers := popup.find_children("*", "OptionButton", true, false)
		_check(pickers.size() == 2, "Settings window exposes quality and FPS controls")
		popup.queue_free()

	settings.config.set_value("Graphics", "Quality", original_quality)
	settings.config.set_value("Graphics", "FPSLimit", original_fps)
	settings.apply_graphics_settings()
	_finish()

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)

func _finish() -> void:
	if failures.is_empty():
		print("Graphics settings verification passed.")
		quit(0)
	else:
		print("Graphics settings verification failed: " + ", ".join(failures))
		quit(1)
