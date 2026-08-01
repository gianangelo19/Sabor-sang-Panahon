extends Control

const APARTMENT_SCENE := "res://game/worlds/la_paz/la_paz.tscn"
const GAME_ON_AUTH_SCENE := "res://addons/game_on/auth_panel.tscn"
const MAIN_MENU_MUSIC := preload("res://assets/audio/retro_filipino_pack/main_menu_retro_filipino.ogg")
const AssetCredits := preload("res://game/ui/menus/asset_credits.gd")

@onready var start_button: Button = %StartButton
@onready var continue_button: Button = %ContinueButton
@onready var game_on_button: Button = %GameOnButton
@onready var game_on_status: Label = %GameOnStatus
@onready var credits_button: Button = %CreditsButton
@onready var menu_column: VBoxContainer = $MenuColumn
@onready var credits_overlay: Control = %CreditsOverlay
@onready var credits_text: RichTextLabel = %CreditsText
@onready var close_credits_button: Button = %CloseCreditsButton

var _music_player: AudioStreamPlayer

func _ready() -> void:
	_ensure_cursor_visible()
	var window := get_window()
	if window != null and not window.focus_entered.is_connected(_ensure_cursor_visible):
		window.focus_entered.connect(_ensure_cursor_visible)
	start_button.text = "NEW GAME"
	var game_on := get_node(^"/root/GameOnPortal") as GameOnConnect
	if not game_on.authorization_status_changed.is_connected(_on_game_on_status_changed):
		game_on.authorization_status_changed.connect(_on_game_on_status_changed)
	_refresh_game_on_gate()
	credits_text.text = AssetCredits.build_bbcode()
	_start_music()

func _unhandled_input(event: InputEvent) -> void:
	if credits_overlay.visible and event.is_action_pressed("ui_cancel"):
		_close_credits()
		get_viewport().set_input_as_handled()

func _start_music() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = MAIN_MENU_MUSIC
	_music_player.bus = "Music"
	_music_player.autoplay = true
	_music_player.finished.connect(func(): _music_player.play())
	add_child(_music_player)

func _on_start_button_pressed() -> void:
	if not _is_game_on_authorized():
		return
	SettingsManager.play_ui_button_sound()
	GameState.start_new_game(APARTMENT_SCENE)
	get_tree().change_scene_to_file(APARTMENT_SCENE)

func _on_continue_button_pressed() -> void:
	if not _is_game_on_authorized():
		return
	SettingsManager.play_ui_button_sound()
	var saved_scene := GameState.load_game()
	if not saved_scene.is_empty():
		get_tree().change_scene_to_file(saved_scene)

func _on_game_on_button_pressed() -> void:
	SettingsManager.play_ui_button_sound()
	get_tree().change_scene_to_file(GAME_ON_AUTH_SCENE)

func _on_game_on_status_changed(_status: String) -> void:
	_ensure_cursor_visible()
	_refresh_game_on_gate()

func _ensure_cursor_visible() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _refresh_game_on_gate() -> void:
	var authorized := _is_game_on_authorized()
	var has_save := GameState.has_save_game()
	start_button.disabled = not authorized
	continue_button.visible = has_save
	continue_button.disabled = not authorized or not has_save
	continue_button.tooltip_text = (
		"Continue your previous game" if has_save and authorized
		else "Connect GameOn to continue" if has_save
		else ""
	)
	game_on_button.visible = not authorized
	game_on_status.text = (
		"GAMEON: CONNECTED" if authorized
		else "GAMEON: CONNECTION REQUIRED"
	)
	if authorized:
		start_button.grab_focus()
	else:
		game_on_button.grab_focus()

func _is_game_on_authorized() -> bool:
	var game_on := get_node_or_null(^"/root/GameOnPortal") as GameOnConnect
	return game_on != null and game_on.is_authorized

func _on_settings_button_pressed() -> void:
	SettingsManager.play_ui_button_sound()
	SettingsManager.show_settings_menu(self)

func _on_credits_button_pressed() -> void:
	SettingsManager.play_ui_button_sound()
	menu_column.hide()
	credits_overlay.show()
	credits_text.scroll_to_line(0)
	close_credits_button.grab_focus()

func _on_close_credits_button_pressed() -> void:
	SettingsManager.play_ui_button_sound()
	_close_credits()

func _close_credits() -> void:
	credits_overlay.hide()
	menu_column.show()
	credits_button.grab_focus()

func _on_credits_link_clicked(meta: Variant) -> void:
	var url := str(meta)
	if url.begins_with("https://") or url.begins_with("http://"):
		OS.shell_open(url)

func _on_quit_button_pressed() -> void:
	SettingsManager.play_ui_button_sound()
	await get_tree().create_timer(0.08).timeout
	get_tree().quit()
