extends AudioStreamPlayer

@export var audio_path := ""
@export var start_on_ready := true
@export var restart_on_finish := true


func _ready() -> void:
	if stream == null and not audio_path.is_empty():
		stream = load(audio_path)
	if restart_on_finish:
		_enable_native_loop()
		finished.connect(_on_finished)
	if start_on_ready and stream != null:
		play()


func _enable_native_loop() -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD


func _on_finished() -> void:
	if stream != null:
		play()
