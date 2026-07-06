extends Node3D

enum State { IDLE, RIDING, STOPPED, EXITING }
var current_state: int = State.IDLE

var interaction_label: String = "ride Jeepney"

var phantom_cam_host_script = preload("res://addons/phantom_camera/scripts/phantom_camera_host/phantom_camera_host.gd")
var phantom_cam_script = preload("res://addons/phantom_camera/scripts/phantom_camera/phantom_camera_3d.gd")

var jeep_phantom_cam: Node3D = null
@onready var animation_player: AnimationPlayer = get_node("../../..") as AnimationPlayer
var look_rotation: Vector2 = Vector2.ZERO
var player_node: CharacterBody3D = null

var audio_idle: AudioStreamPlayer3D
var audio_cruising: AudioStreamPlayer3D

func _ready() -> void:
	jeep_phantom_cam = phantom_cam_script.new()
	jeep_phantom_cam.name = "JeepPhantomCamera3D"
	add_child(jeep_phantom_cam)
	
	# Position the camera in the back of the jeepney where the windows are
	jeep_phantom_cam.position = Vector3(1.2, 1.5, 1)
	jeep_phantom_cam.rotation_degrees = Vector3(0, -90, 0)
	jeep_phantom_cam.priority = 0
	
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)
		
	audio_idle = AudioStreamPlayer3D.new()
	audio_idle.stream = load("res://audio/idle jeepney sound.mp3")
	audio_idle.bus = "SFX"
	audio_idle.unit_size = 5.0
	audio_idle.max_distance = 30.0
	audio_idle.autoplay = true
	audio_idle.finished.connect(func(): audio_idle.play())
	add_child(audio_idle)
	
	audio_cruising = AudioStreamPlayer3D.new()
	audio_cruising.stream = load("res://audio/cruising jeepney sound.mp3")
	audio_cruising.bus = "SFX"
	audio_cruising.unit_size = 5.0
	audio_cruising.max_distance = 30.0
	audio_cruising.finished.connect(func(): audio_cruising.play())
	add_child(audio_cruising)
	
	_update_audio()

func _update_audio() -> void:
	if current_state == State.RIDING:
		if audio_idle.playing: audio_idle.stop()
		if not audio_cruising.playing: audio_cruising.play()
	else:
		if audio_cruising.playing: audio_cruising.stop()
		if not audio_idle.playing: audio_idle.play()

func get_interaction_text() -> String:
	if current_state == State.IDLE:
		return "Press E to ride Jeepney"
	return ""

func interact() -> void:
	if current_state == State.IDLE:
		start_ride()

func start_ride() -> void:
	current_state = State.RIDING
	_update_audio()
	
	player_node = get_tree().get_first_node_in_group("player")
	if not player_node:
		player_node = get_node_or_null("/root/la_paz/ProtoController")
		
	var main_camera = get_viewport().get_camera_3d()
	if main_camera:
		if not main_camera.has_node("PhantomCameraHost"):
			var host = phantom_cam_host_script.new()
			host.name = "PhantomCameraHost"
			main_camera.add_child(host)
			
		var head = main_camera.get_parent()
		if head and not head.has_node("PlayerPhantomCamera"):
			var player_pcam = phantom_cam_script.new()
			player_pcam.name = "PlayerPhantomCamera"
			head.add_child(player_pcam)
			player_pcam.priority = 5
	
	if player_node:
		player_node.set_physics_process(false)
		player_node.set_process_unhandled_input(false)
		player_node.set_process(false) # Disable UI and head bobbing
		# Hide the player's interact prompt if it was showing
		var prompt = player_node.get_node_or_null("InteractionUI/Prompt")
		if prompt:
			prompt.visible = false
			
		# Hide the player's mesh so it's not left behind
		var mesh = player_node.get_node_or_null("Mesh")
		if mesh:
			mesh.visible = false
			
	# Wait a couple frames to ensure PlayerPhantomCamera is fully registered by the manager
	await get_tree().process_frame
	await get_tree().process_frame
		
	look_rotation = Vector2(0, deg_to_rad(-90))
	jeep_phantom_cam.rotation = Vector3(look_rotation.x, look_rotation.y, 0)
	jeep_phantom_cam.priority = 10
	
	if animation_player:
		# Wait 1.0 second for the camera to smoothly transition before moving the jeep
		await get_tree().create_timer(1.0).timeout
		if current_state == State.RIDING:
			animation_player.play("jeepney_cutscene")

func get_off() -> void:
	current_state = State.EXITING
	_update_audio()
	
	if player_node:
		# Teleport player outside the Jeepney's new location (at the back of the jeepney)
		var exit_pos = global_transform.origin + (global_transform.basis * Vector3(-10.0, 1.0, 0.0))
		player_node.global_transform.origin = exit_pos
		
		# Reset rotation slightly so the player isn't disoriented
		player_node.rotation.y = global_transform.basis.get_euler().y
		
		player_node.set_physics_process(true)
		player_node.set_process_unhandled_input(true)
		player_node.set_process(true)
		
		var prompt = player_node.get_node_or_null("InteractionUI/Prompt")
		if prompt:
			prompt.visible = false
			
		# Show the player's mesh again
		var mesh = player_node.get_node_or_null("Mesh")
		if mesh:
			mesh.visible = true
			
	jeep_phantom_cam.priority = 0
	
	if animation_player:
		animation_player.play("exit jeep cutscene")

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "jeepney_cutscene":
		current_state = State.STOPPED
	elif anim_name == "exit jeep cutscene":
		current_state = State.IDLE
		player_node = null
	_update_audio()

func _process(_delta: float) -> void:
	if current_state == State.STOPPED and player_node:
		var prompt = player_node.get_node_or_null("InteractionUI/Prompt")
		if prompt:
			prompt.text = "Press E to get off Jeepney"
			prompt.visible = true
	elif current_state == State.RIDING and player_node:
		var prompt = player_node.get_node_or_null("InteractionUI/Prompt")
		if prompt:
			prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if current_state == State.RIDING or current_state == State.STOPPED:
		if Input.is_key_pressed(KEY_ESCAPE):
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			var look_speed = 0.002
			look_rotation.x -= event.relative.y * look_speed
			look_rotation.x = clamp(look_rotation.x, deg_to_rad(-80), deg_to_rad(80))
			look_rotation.y -= event.relative.x * look_speed
			jeep_phantom_cam.rotation = Vector3(look_rotation.x, look_rotation.y, 0)
			
		if event.is_action_pressed("interact") and current_state == State.STOPPED:
			get_off()
