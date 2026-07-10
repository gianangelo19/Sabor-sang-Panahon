extends AudioStreamPlayer3D

@export var audio_path := ""
@export var start_on_ready := true
@export var restart_on_finish := true


func _ready() -> void:
	if stream == null and not audio_path.is_empty():
		stream = load(audio_path)
	if restart_on_finish:
		finished.connect(_on_finished)
	if start_on_ready and stream != null:
		play()


func _on_finished() -> void:
	if stream != null:
		play()
