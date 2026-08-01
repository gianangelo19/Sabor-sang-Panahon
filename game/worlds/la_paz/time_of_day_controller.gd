class_name TimeOfDayController
extends Node

const TRANSITION_DURATION := 2.5
const SUNSET_PANORAMA := preload("res://assets/bambanani_sunset_4k.hdr")
const SUNSET_SKY_STAGE := 6

const STAGE_PROFILES := [
	{
		"sun_rotation": Vector3(-53.3, -148.3, -11.2),
		"sun_color": Color(1.0, 0.88, 0.72),
		"sun_energy": 1.12,
		"ambient_energy": 0.72,
		"background_energy": 1.53,
		"exposure": 1.08,
		"fog_color": Color(0.700359, 0.613651, 0.408115, 1.0),
		"fog_density": 0.2951,
		"sky_energy": 0.30,
		"streetlight_energy": 0.0,
	},
	{
		"sun_rotation": Vector3(-61.0, -138.0, -8.0),
		"sun_color": Color(1.0, 0.92, 0.80),
		"sun_energy": 1.18,
		"ambient_energy": 0.75,
		"background_energy": 1.60,
		"exposure": 1.06,
		"fog_color": Color(0.72, 0.65, 0.48, 1.0),
		"fog_density": 0.285,
		"sky_energy": 0.32,
		"streetlight_energy": 0.0,
	},
	{
		"sun_rotation": Vector3(-68.0, -128.0, -5.0),
		"sun_color": Color(1.0, 0.97, 0.90),
		"sun_energy": 1.22,
		"ambient_energy": 0.78,
		"background_energy": 1.65,
		"exposure": 1.04,
		"fog_color": Color(0.72, 0.67, 0.52, 1.0),
		"fog_density": 0.275,
		"sky_energy": 0.33,
		"streetlight_energy": 0.0,
	},
	{
		"sun_rotation": Vector3(-62.0, -118.0, -3.0),
		"sun_color": Color(1.0, 0.94, 0.84),
		"sun_energy": 1.18,
		"ambient_energy": 0.76,
		"background_energy": 1.55,
		"exposure": 1.05,
		"fog_color": Color(0.71, 0.64, 0.47, 1.0),
		"fog_density": 0.28,
		"sky_energy": 0.32,
		"streetlight_energy": 0.0,
	},
	{
		"sun_rotation": Vector3(-54.0, -108.0, 0.0),
		"sun_color": Color(1.0, 0.88, 0.72),
		"sun_energy": 1.08,
		"ambient_energy": 0.70,
		"background_energy": 1.40,
		"exposure": 1.04,
		"fog_color": Color(0.70, 0.60, 0.41, 1.0),
		"fog_density": 0.285,
		"sky_energy": 0.30,
		"streetlight_energy": 0.0,
	},
	{
		"sun_rotation": Vector3(-44.0, -98.0, 0.0),
		"sun_color": Color(1.0, 0.80, 0.60),
		"sun_energy": 0.96,
		"ambient_energy": 0.64,
		"background_energy": 1.22,
		"exposure": 1.02,
		"fog_color": Color(0.68, 0.54, 0.36, 1.0),
		"fog_density": 0.29,
		"sky_energy": 0.27,
		"streetlight_energy": 0.0,
	},
	{
		"sun_rotation": Vector3(-32.0, -88.0, 0.0),
		"sun_color": Color(1.0, 0.66, 0.38),
		"sun_energy": 0.78,
		"ambient_energy": 0.56,
		"background_energy": 0.95,
		"exposure": 1.00,
		"fog_color": Color(0.62, 0.43, 0.31, 1.0),
		"fog_density": 0.30,
		"sky_energy": 0.25,
		"streetlight_energy": 0.0,
	},
	{
		"sun_rotation": Vector3(-20.0, -78.0, 0.0),
		"sun_color": Color(1.0, 0.54, 0.31),
		"sun_energy": 0.55,
		"ambient_energy": 0.48,
		"background_energy": 0.76,
		"exposure": 0.99,
		"fog_color": Color(0.48, 0.36, 0.36, 1.0),
		"fog_density": 0.305,
		"sky_energy": 0.22,
		"streetlight_energy": 0.40,
	},
	{
		"sun_rotation": Vector3(-10.0, -68.0, 0.0),
		"sun_color": Color(1.0, 0.44, 0.28),
		"sun_energy": 0.35,
		"ambient_energy": 0.42,
		"background_energy": 0.62,
		"exposure": 1.00,
		"fog_color": Color(0.28, 0.31, 0.42, 1.0),
		"fog_density": 0.31,
		"sky_energy": 0.18,
		"streetlight_energy": 1.20,
	},
]

var applied_stage := -1
var _world_environment: WorldEnvironment
var _environment: Environment
var _sun: DirectionalLight3D
var _sky_material: PanoramaSkyMaterial
var _day_panorama: Texture2D
var _transition: Tween
var _game_state: Node


func _ready() -> void:
	_world_environment = get_parent().get_node_or_null("WorldEnvironment") as WorldEnvironment
	_sun = get_parent().get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if _world_environment == null or _world_environment.environment == null or _sun == null:
		push_error("TimeOfDayController requires the La Paz environment and sun.")
		return

	_environment = _world_environment.environment.duplicate(true) as Environment
	_world_environment.environment = _environment
	if _environment.sky != null:
		_environment.sky = _environment.sky.duplicate(true) as Sky
		_sky_material = _environment.sky.sky_material.duplicate(true) as PanoramaSkyMaterial
		_environment.sky.sky_material = _sky_material
		_day_panorama = _sky_material.panorama

	_game_state = get_tree().root.get_node_or_null("GameState")
	if _game_state == null:
		push_error("TimeOfDayController requires the GameState autoload.")
		call_deferred("apply_stage", 0, false)
		return
	if not _game_state.time_of_day_changed.is_connected(_on_time_of_day_changed):
		_game_state.time_of_day_changed.connect(_on_time_of_day_changed)
	call_deferred("apply_stage", int(_game_state.time_of_day_stage), false)


func apply_stage(stage: int, animate := true) -> void:
	if _environment == null or _sun == null:
		return
	var resolved_stage := clampi(stage, 0, STAGE_PROFILES.size() - 1)
	var profile := STAGE_PROFILES[resolved_stage] as Dictionary
	applied_stage = resolved_stage
	if _transition != null and _transition.is_valid():
		_transition.kill()

	if _sky_material != null:
		_sky_material.panorama = (
			SUNSET_PANORAMA
			if resolved_stage >= SUNSET_SKY_STAGE
			else _day_panorama
		)

	if not animate:
		_apply_profile_immediately(profile)
		return

	_transition = create_tween()
	_transition.set_parallel(true)
	_transition.set_trans(Tween.TRANS_SINE)
	_transition.set_ease(Tween.EASE_IN_OUT)
	_transition.tween_property(
		_sun,
		"rotation_degrees",
		profile.sun_rotation,
		TRANSITION_DURATION,
	)
	_transition.tween_property(_sun, "light_color", profile.sun_color, TRANSITION_DURATION)
	_transition.tween_property(_sun, "light_energy", profile.sun_energy, TRANSITION_DURATION)
	_transition.tween_property(
		_environment,
		"ambient_light_energy",
		profile.ambient_energy,
		TRANSITION_DURATION,
	)
	_transition.tween_property(
		_environment,
		"background_energy_multiplier",
		profile.background_energy,
		TRANSITION_DURATION,
	)
	_transition.tween_property(
		_environment,
		"tonemap_exposure",
		profile.exposure,
		TRANSITION_DURATION,
	)
	_transition.tween_property(
		_environment,
		"fog_light_color",
		profile.fog_color,
		TRANSITION_DURATION,
	)
	_transition.tween_property(
		_environment,
		"fog_density",
		profile.fog_density,
		TRANSITION_DURATION,
	)
	if _sky_material != null:
		_transition.tween_property(
			_sky_material,
			"energy_multiplier",
			profile.sky_energy,
			TRANSITION_DURATION,
		)
	_tween_streetlights(float(profile.streetlight_energy))


func _on_time_of_day_changed(stage: int) -> void:
	apply_stage(stage, true)


func _apply_profile_immediately(profile: Dictionary) -> void:
	_sun.rotation_degrees = profile.sun_rotation
	_sun.light_color = profile.sun_color
	_sun.light_energy = float(profile.sun_energy)
	_environment.ambient_light_energy = float(profile.ambient_energy)
	_environment.background_energy_multiplier = float(profile.background_energy)
	_environment.tonemap_exposure = float(profile.exposure)
	_environment.fog_light_color = profile.fog_color
	_environment.fog_density = float(profile.fog_density)
	if _sky_material != null:
		_sky_material.energy_multiplier = float(profile.sky_energy)
	_set_streetlights_immediately(float(profile.streetlight_energy))


func _tween_streetlights(target_energy: float) -> void:
	for node in get_tree().get_nodes_in_group("time_of_day_streetlight"):
		var light := node as OmniLight3D
		if light == null:
			continue
		if target_energy > 0.0:
			light.visible = true
		_transition.tween_property(
			light,
			"light_energy",
			target_energy,
			TRANSITION_DURATION,
		)


func _set_streetlights_immediately(target_energy: float) -> void:
	for node in get_tree().get_nodes_in_group("time_of_day_streetlight"):
		var light := node as OmniLight3D
		if light == null:
			continue
		light.light_energy = target_energy
		light.visible = target_energy > 0.0
