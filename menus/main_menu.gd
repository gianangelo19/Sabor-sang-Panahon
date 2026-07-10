extends Control

const APARTMENT_SCENE := "res://la_paz.tscn"
const MAIN_MENU_MUSIC := preload("res://audio/main menu music.mp3")

@onready var start_button: Button = %StartButton
@onready var continue_button: Button = %ContinueButton

var _music_player: AudioStreamPlayer

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	start_button.text = "New Game"
	continue_button.visible = GameState.has_save_game()
	continue_button.disabled = not continue_button.visible
	continue_button.tooltip_text = "Continue your previous game" if continue_button.visible else ""
	start_button.grab_focus()
	_start_music()

func _start_music() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = MAIN_MENU_MUSIC
	_music_player.bus = "Music"
	_music_player.autoplay = true
	_music_player.finished.connect(func(): _music_player.play())
	add_child(_music_player)

func _on_start_button_pressed() -> void:
	GameState.start_new_game(APARTMENT_SCENE)
	get_tree().change_scene_to_file(APARTMENT_SCENE)

func _on_continue_button_pressed() -> void:
	var saved_scene := GameState.load_game()
	if not saved_scene.is_empty():
		get_tree().change_scene_to_file(saved_scene)

func _on_settings_button_pressed() -> void:
	SettingsManager.show_settings_menu(self)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
