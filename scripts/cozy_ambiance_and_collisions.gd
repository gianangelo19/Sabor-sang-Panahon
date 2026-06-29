extends Node3D

func _ready():
	_apply_cozy_ambiance()
	# Defer so all instanced PackedScene children (GLTFs) are fully loaded before we scan them
	call_deferred("_generate_collisions", self)

func _apply_cozy_ambiance():
	var we = WorldEnvironment.new()
	var env = Environment.new()
	
	# Afternoon background and ambient light
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.35, 0.22, 0.15) # sunset/afternoon sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.25, 0.2) # golden afternoon bounce light
	
	# Tone mapping to reduce harsh highlights
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.95
	env.tonemap_white = 1.0
	
	# Bloom for a softer look
	env.glow_enabled = true
	env.glow_intensity = 1.2
	env.glow_strength = 0.8
	env.glow_bloom = 0.15
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	
	# SSAO for softer contact shadows
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 2.5
	
	we.environment = env
	add_child(we)
	
	# Add a DirectionalLight3D for afternoon sun
	var dir_light = DirectionalLight3D.new()
	dir_light.light_color = Color(1.0, 0.7, 0.35) # Golden afternoon sunlight
	dir_light.light_energy = 0.8
	dir_light.shadow_enabled = true
	dir_light.shadow_blur = 4.0 # Very soft shadows
	dir_light.rotation_degrees = Vector3(-20, 75, 0) # Low afternoon sun angle
	add_child(dir_light)
	
	_tweak_lights(self)

func _tweak_lights(node: Node):
	if node is OmniLight3D or node is SpotLight3D:
		# Warmer color, less harsh energy, softer shadows
		node.light_color = Color(1.0, 0.88, 0.75) # Warm cozy color
		node.light_energy = node.light_energy * 0.6 # Soften the light intensity
		if node.shadow_enabled:
			node.shadow_blur = 2.5 # Soften the shadow edges
	
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
