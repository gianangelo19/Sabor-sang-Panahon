extends Control

const APARTMENT_SCENE := "res://apartment.tscn"

@onready var start_button: Button = %StartButton

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	start_button.grab_focus()

func _on_start_button_pressed() -> void:
	GameState.reset()
	get_tree().change_scene_to_file(APARTMENT_SCENE)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
