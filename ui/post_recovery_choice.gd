extends CanvasLayer

signal continue_exploring
signal main_menu_requested

@onready var continue_button: Button = %ContinueButton

var _resolved := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	continue_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_choose_continue()


func _choose_continue() -> void:
	if _resolved:
		return
	_resolved = true
	SettingsManager.play_ui_button_sound()
	continue_exploring.emit()
	queue_free()


func _choose_main_menu() -> void:
	if _resolved:
		return
	_resolved = true
	SettingsManager.play_ui_button_sound()
	main_menu_requested.emit()
	queue_free()
