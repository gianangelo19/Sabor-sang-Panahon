class_name ArtifactDiscoveryPopup
extends CanvasLayer

signal retry_requested
signal continue_requested
signal dismissed

@onready var kicker_label: Label = %Kicker
@onready var bowl_image: TextureRect = %BowlImage
@onready var artifact_title: Label = %ArtifactTitle
@onready var description_heading: Label = %FactHeading
@onready var description_scroll: ScrollContainer = %DescriptionScroll
@onready var description_text: Label = %FactText
@onready var retry_button: Button = %RetryButton
@onready var continue_button: Button = %ContinueButton

var _previous_mouse_mode := Input.MOUSE_MODE_CAPTURED
var _default_bowl_texture: Texture2D
var _closing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_previous_mouse_mode = Input.mouse_mode
	_default_bowl_texture = bowl_image.texture
	_ensure_cursor_visible()
	var window := get_window()
	if window != null and not window.focus_entered.is_connected(_ensure_cursor_visible):
		window.focus_entered.connect(_ensure_cursor_visible)
	retry_button.pressed.connect(_retry)
	continue_button.pressed.connect(_dismiss)
	show_loading()


func _unhandled_input(event: InputEvent) -> void:
	if (
		continue_button.visible
		and not continue_button.disabled
		and (
			event.is_action_pressed("interact")
			or event.is_action_pressed("ui_accept")
		)
	):
		get_viewport().set_input_as_handled()
		_dismiss()


func show_loading(message := "Contacting GameOn...") -> void:
	_ensure_cursor_visible()
	kicker_label.text = "CULTURAL ARTIFACT RECOVERED"
	artifact_title.text = "THE BATCHOY BOWL"
	description_heading.text = "CONNECTING TO GAMEON"
	description_text.text = message
	bowl_image.texture = _default_bowl_texture
	retry_button.visible = false
	continue_button.visible = false
	_reset_description_scroll()


func show_artifact(artifact_data: Dictionary, is_new_unlock: bool) -> void:
	_ensure_cursor_visible()
	var artifact := artifact_data.get("artifact", {}) as Dictionary
	var artifact_name := str(artifact.get("name", "Old Batchoy Bowl")).strip_edges()
	var game_on_description := str(artifact.get("description", "")).strip_edges()
	if artifact_name.is_empty():
		artifact_name = "Old Batchoy Bowl"
	if game_on_description.is_empty():
		game_on_description = "No GameOn description was provided for this artifact."

	kicker_label.text = (
		"GAMEON ARTIFACT UNLOCKED"
		if is_new_unlock
		else "GAMEON ARTIFACT ALREADY OWNED"
	)
	artifact_title.text = artifact_name.to_upper()
	description_heading.text = "GAMEON ARTIFACT DESCRIPTION"
	description_text.text = game_on_description
	retry_button.visible = false
	continue_button.visible = true
	continue_button.text = "CONTINUE"
	continue_button.grab_focus()
	_reset_description_scroll()

	bowl_image.texture = _default_bowl_texture
	var thumbnail_url := str(artifact.get("thumbnailUrl", "")).strip_edges()
	if not thumbnail_url.is_empty():
		_download_thumbnail(thumbnail_url)


func show_error(message: String, requires_auth: bool) -> void:
	_ensure_cursor_visible()
	kicker_label.text = "CULTURAL ARTIFACT RECOVERED"
	artifact_title.text = "THE BATCHOY BOWL"
	description_heading.text = "GAMEON REWARD PENDING"
	description_text.text = message
	bowl_image.texture = _default_bowl_texture
	retry_button.visible = true
	retry_button.text = "RECONNECT & RETRY" if requires_auth else "RETRY"
	continue_button.visible = true
	continue_button.text = "CONTINUE WITHOUT REWARD"
	retry_button.grab_focus()
	_reset_description_scroll()


func _reset_description_scroll() -> void:
	description_scroll.scroll_vertical = 0


func _ensure_cursor_visible() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _download_thumbnail(url: String) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	var request_error := http.request(url)
	if request_error != OK:
		http.queue_free()
		push_warning("Failed to request GameOn thumbnail: " + error_string(request_error))
		return
	var result: Array = await http.request_completed
	http.queue_free()
	if result.size() < 4:
		return
	if (
		int(result[0]) != HTTPRequest.RESULT_SUCCESS
		or int(result[1]) < 200
		or int(result[1]) >= 300
	):
		return

	var body := result[3] as PackedByteArray
	var image := Image.new()
	var error := image.load_png_from_buffer(body)
	if error != OK:
		error = image.load_jpg_from_buffer(body)
	if error != OK:
		error = image.load_webp_from_buffer(body)
	if error == OK:
		bowl_image.texture = ImageTexture.create_from_image(image)


func _retry() -> void:
	retry_requested.emit()


func _dismiss() -> void:
	if _closing or not continue_button.visible:
		return
	_closing = true
	Input.mouse_mode = _previous_mouse_mode
	continue_requested.emit()
	dismissed.emit()
	queue_free()
