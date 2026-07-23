extends CanvasLayer

signal dismissed

@onready var continue_button: Button = %ContinueButton

var _previous_mouse_mode := Input.MOUSE_MODE_CAPTURED
var _closing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	continue_button.pressed.connect(_dismiss)
	continue_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_dismiss()


func _dismiss() -> void:
	if _closing:
		return
	_closing = true
	Input.mouse_mode = _previous_mouse_mode
	dismissed.emit()
	queue_free()

