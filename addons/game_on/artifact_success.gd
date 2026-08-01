class_name ArtifactSuccess
extends Control

signal retry_requested
signal continue_requested
signal back_pressed

@onready var title_label: Label = %Title
@onready var status_label: Label = %StatusLabel
@onready var artifact_name_label: Label = %ArtifactName
@onready var artifact_description_label: Label = %ArtifactDescription
@onready var thumbnail_rect: TextureRect = %Thumbnail
@onready var retry_button: Button = %RetryButton
@onready var back_button: Button = %BackButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	retry_button.pressed.connect(_on_retry_pressed)
	back_button.pressed.connect(_on_continue_pressed)
	var game_on_connect := get_node_or_null(^"/root/GameOnPortal") as GameOnConnect
	if game_on_connect != null and not game_on_connect.pending_artifact.is_empty():
		show_artifact(
			game_on_connect.pending_artifact,
			game_on_connect.pending_is_new_unlock,
		)
	else:
		show_loading()


func show_loading(message := "Contacting GameOn...") -> void:
	title_label.text = "Unlocking GameOn Artifact"
	status_label.text = message
	_set_artifact_details_visible(false)
	retry_button.visible = false
	back_button.visible = false


func show_artifact(artifact_data: Dictionary, is_new_unlock: bool) -> void:
	title_label.text = (
		"Artifact Unlocked!" if is_new_unlock else "Artifact Already Unlocked"
	)
	status_label.text = "Your GameOn collection has been updated."
	var artifact := artifact_data.get("artifact", {}) as Dictionary
	artifact_name_label.text = str(artifact.get("name", "Old Batchoy Bowl"))
	artifact_description_label.text = str(artifact.get("description", ""))
	_set_artifact_details_visible(true)
	retry_button.visible = false
	back_button.visible = true
	back_button.text = "Continue"
	back_button.grab_focus()

	thumbnail_rect.texture = null
	thumbnail_rect.visible = false
	var thumbnail_url := str(artifact.get("thumbnailUrl", ""))
	if not thumbnail_url.is_empty():
		_download_thumbnail(thumbnail_url)


func show_error(message: String, requires_auth: bool) -> void:
	title_label.text = "GameOn Reward Pending"
	status_label.text = message
	_set_artifact_details_visible(false)
	retry_button.visible = true
	retry_button.text = "Reconnect & Retry" if requires_auth else "Retry"
	back_button.visible = true
	back_button.text = "Continue Without Reward"
	retry_button.grab_focus()


func _set_artifact_details_visible(should_show: bool) -> void:
	artifact_name_label.visible = should_show
	artifact_description_label.visible = should_show
	thumbnail_rect.visible = should_show and thumbnail_rect.texture != null


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
		push_warning("Failed to download GameOn thumbnail: empty response")
		return
	if (
		int(result[0]) != HTTPRequest.RESULT_SUCCESS
		or int(result[1]) < 200
		or int(result[1]) >= 300
	):
		push_warning("Failed to download GameOn thumbnail")
		return

	var body := result[3] as PackedByteArray
	var image := Image.new()
	var error := image.load_png_from_buffer(body)
	if error != OK:
		error = image.load_jpg_from_buffer(body)
	if error != OK:
		error = image.load_webp_from_buffer(body)
	if error != OK:
		push_warning("Failed to decode GameOn thumbnail")
		return
	thumbnail_rect.texture = ImageTexture.create_from_image(image)
	thumbnail_rect.visible = true


func _on_retry_pressed() -> void:
	retry_requested.emit()


func _on_continue_pressed() -> void:
	continue_requested.emit()
	back_pressed.emit()
