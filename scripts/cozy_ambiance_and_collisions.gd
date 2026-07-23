extends Node3D

var bg_music: AudioStreamPlayer

func _ready():
	_apply_cozy_ambiance()
	# Defer so all instanced PackedScene children (GLTFs) are fully loaded before we scan them
	call_deferred("_generate_collisions", self)
	
	bg_music = AudioStreamPlayer.new()
	bg_music.stream = load("res://audio/retro_filipino_pack/in_game_retro_filipino.ogg")
	bg_music.bus = "Music"
	bg_music.autoplay = true
	bg_music.finished.connect(func(): bg_music.play())
	add_child(bg_music)

func _apply_cozy_ambiance():
	# The main La Paz scene owns the world environment and sunlight. Avoid adding
	# a second global environment/sun when this house is instanced into that map.
	if _has_ancestor_world_environment():
		_tweak_lights(self)
		return

	var we = WorldEnvironment.new()
	var env = Environment.new()
	
	# Afternoon background and ambient light
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.35, 0.22, 0.15) # sunset/afternoon sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.25, 0.2) # golden afternoon bounce light
	env.ambient_light_energy = 0.72
	
	# Tone mapping to reduce harsh highlights
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.95
	env.tonemap_white = 1.0
	
	# Bloom for a softer look
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_strength = 0.7
	env.glow_bloom = 0.08
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	
	# SSAO for softer contact shadows
	env.ssao_enabled = true
	env.ssao_radius = 0.9
	env.ssao_intensity = 1.1
	env.ssao_power = 1.2
	env.ssao_light_affect = 0.08
	
	we.environment = env
	add_child(we)
	
	# Add a DirectionalLight3D for afternoon sun
	var dir_light = DirectionalLight3D.new()
	dir_light.light_color = Color(1.0, 0.82, 0.64) # Soft afternoon sunlight
	dir_light.light_energy = 0.85
	dir_light.light_indirect_energy = 0.7
	dir_light.light_angular_distance = 0.8
	dir_light.shadow_enabled = true
	dir_light.shadow_opacity = 0.62
	dir_light.shadow_blur = 1.6
	dir_light.shadow_bias = 0.045
	dir_light.shadow_normal_bias = 0.9
	dir_light.rotation_degrees = Vector3(-20, 75, 0) # Low afternoon sun angle
	add_child(dir_light)
	
	_tweak_lights(self)

func _has_ancestor_world_environment() -> bool:
	var ancestor := get_parent()
	while ancestor != null:
		for sibling in ancestor.get_children():
			if sibling is WorldEnvironment:
				return true
		ancestor = ancestor.get_parent()
	return false

func _tweak_lights(node: Node):
	if node is OmniLight3D or node is SpotLight3D:
		# Warmer color, less harsh energy, softer shadows
		node.light_color = Color(1.0, 0.88, 0.75) # Warm cozy color
		node.light_energy = node.light_energy * 0.75
		if node.shadow_enabled:
			node.shadow_opacity = min(node.shadow_opacity, 0.38)
			node.shadow_blur = max(node.shadow_blur, 2.0)
	
	for child in node.get_children():
		_tweak_lights(child)

func _generate_collisions(node: Node):
	# Skip the overlay quad mesh on the player camera — it has no collision use
	if node is MeshInstance3D and node.mesh != null:
		var skip = false
		# Don't collide on QuadMesh (screen overlays) or tiny/invisible meshes
		if node.mesh is QuadMesh:
			skip = true
		if not skip:
			node.create_trimesh_collision()
	
	for child in node.get_children():
		_generate_collisions(child)
