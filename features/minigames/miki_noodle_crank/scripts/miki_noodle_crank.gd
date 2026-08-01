extends Node2D

signal minigame_finished
signal minigame_failed
signal minigame_retry_requested

const DIALOGUE_SCENE := preload("res://features/minigames/shared/dialogue/shared_dialogue.tscn")
const FAIL_SCREEN_SCENE: PackedScene = preload(
	"res://features/minigames/fail_screen/scenes/minigame_fail_screen.tscn"
)
const PROGRESS_PANEL := preload("res://features/minigames/miki_noodle_crank/assets/ui/miki_progress_panel.png")
const PROGRESS_GREEN := preload("res://features/minigames/miki_noodle_crank/assets/ui/miki_progress_green.png")
const PROGRESS_FRAME := preload("res://features/minigames/miki_noodle_crank/assets/ui/miki_progress_frame.png")
const TENSION_GREEN := preload("res://features/minigames/miki_noodle_crank/assets/sprites/sweet_spot_zone.png")
const TENSION_FRAME := preload("res://features/minigames/miki_noodle_crank/assets/sprites/tension_meter_frame_canvas.png")
const TENSION_NEEDLE := preload("res://features/minigames/miki_noodle_crank/assets/sprites/needle_canvas.png")
const WARNING_PANEL := preload("res://features/minigames/miki_noodle_crank/assets/ui/miki_warning_panel.png")
const NO_MISTAKE := preload("res://features/minigames/miki_noodle_crank/assets/ui/no_mistake.png")
const YES_MISTAKE := preload("res://features/minigames/miki_noodle_crank/assets/ui/yes_mistake.png")

const CRANK_SOUNDS := [
	preload("res://features/minigames/miki_noodle_crank/assets/audio/sfx/sfx_crank_turn_01.wav"),
	preload("res://features/minigames/miki_noodle_crank/assets/audio/sfx/sfx_crank_turn_02.wav"),
	preload("res://features/minigames/miki_noodle_crank/assets/audio/sfx/sfx_crank_turn_03.wav"),
]
const COMPLETE_SOUND := preload("res://features/minigames/miki_noodle_crank/assets/audio/sfx/sfx_progress_complete.wav")
const FAIL_SOUND := preload("res://features/minigames/miki_noodle_crank/assets/audio/sfx/sfx_failure_transition.wav")
const START_SOUND := preload("res://features/minigames/chicharon_beat/assets/audio/sfx/sfx_round_start.wav")
const MUSIC := preload("res://features/minigames/miki_noodle_crank/assets/audio/music/bgm_miki_crank_loop.ogg")
const AMBIENCE := preload("res://features/minigames/miki_noodle_crank/assets/audio/ambience/amb_market_machine_loop.ogg")
const EXTRUSION := preload("res://features/minigames/miki_noodle_crank/assets/audio/sfx/sfx_noodles_extrude_loop.ogg")

@onready var crank_pivot: Node2D = $CrankPivot
@onready var noodles_output: Sprite2D = $NoodlesOutput
@onready var machine_body: Sprite2D = $MachineBody
@onready var machine_body_front: Sprite2D = $MachineBody2

@export var tension_decay := 0.27
@export var crank_boost := 0.11
@export_range(0.01, 1.0, 0.01) var progress_speed := 0.14
@export_range(1, 3, 1) var max_strikes := 3

const NEEDLE_TOP_Y := 150.0
const NEEDLE_BOTTOM_Y := 500.0
const TENSION_VERTICAL_OFFSET := -20.0
const NOODLE_START_Y := 250.0
const NOODLE_END_Y := 620.0

var tension := 0.48
var progress := 0.0
var noodle_extension_progress := 0.0
var strike_count := 0
var noodle_cycle_active := false
var sweet_center := 0.52
var sweet_size := 0.28
var sweet_target_center := 0.52
var sweet_target_size := 0.28
var sweet_change_timer := 0.0
var extreme_latched := false
var gameplay_started := false
var game_finished := false
var seen_sweet_spot := false
var seen_outside_spot := false
var halfway_line_done := false
var noodle_start := Vector2.ZERO
var machine_home_position := Vector2.ZERO
var machine_front_home_position := Vector2.ZERO

var dialogue: SharedDialogue
var hud: CanvasLayer
var progress_green: Sprite2D
var tension_green: Sprite2D
var tension_needle: Sprite2D
var warning_markers: Array[Sprite2D] = []
var sfx: AudioStreamPlayer
var extrusion_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var fail_screen: Node

func _ready() -> void:
	noodle_start = Vector2(noodles_output.position.x, NOODLE_START_Y)
	machine_home_position = machine_body.position
	machine_front_home_position = machine_body_front.position
	_setup_shared_overlays()
	_setup_hud()
	_setup_audio()
	_setup_fail_screen()
	_reset_game()

func _process(delta: float) -> void:
	if not gameplay_started or game_finished:
		return
	tension = clampf(tension - tension_decay * delta, 0.0, 1.0)
	_update_sweet_spot(delta)
	_update_gameplay(delta)
	_update_hud()
	_update_extrusion_audio()

func _unhandled_input(event: InputEvent) -> void:
	if not gameplay_started or game_finished:
		return
	if event.is_action_pressed("crank") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		crank()
		get_viewport().set_input_as_handled()

func crank() -> void:
	if not gameplay_started or game_finished:
		return
	tension = clampf(tension + crank_boost, 0.0, 1.0)
	_animate_machine()
	sfx.stream = CRANK_SOUNDS.pick_random()
	sfx.play()

func _update_gameplay(delta: float) -> void:
	var in_sweet_spot := _is_in_sweet_spot()
	if in_sweet_spot:
		progress = minf(1.0, progress + progress_speed * delta)
		noodle_extension_progress = maxf(noodle_extension_progress, progress)
		if not seen_sweet_spot:
			seen_sweet_spot = true
			dialogue.say("That's it. Keep the needle in the green.", "happy", 2.3, "vendor_miki")
	elif seen_sweet_spot and not seen_outside_spot:
		seen_outside_spot = true
		dialogue.say("Not there - the noodles only move in the green.", "concerned", 2.5, "vendor_miki")
	# Progress represents noodles already extruded. Leaving the green zone
	# pauses production, but must not retract progress the player already earned.

	if progress >= 0.5 and not halfway_line_done:
		halfway_line_done = true
		dialogue.say("Steady now. Don't let the tension run away.", "neutral", 2.5, "vendor_miki")

	if tension <= 0.02 or tension >= 0.98:
		if not extreme_latched:
			extreme_latched = true
			_register_strike()
	elif tension > 0.06 and tension < 0.94:
		extreme_latched = false

	noodles_output.position.y = lerpf(
		NOODLE_START_Y,
		NOODLE_END_Y,
		noodle_extension_progress
	)
	if progress >= 0.98 and in_sweet_spot:
		noodles_output.position.x = noodle_start.x + sin(Time.get_ticks_msec() * 0.045) * 2.0
	else:
		noodles_output.position.x = noodle_start.x

	if progress >= 1.0 and not noodle_cycle_active:
		_complete_noodle_cycle()

func _register_strike() -> void:
	strike_count += 1
	_pulse_marker(strike_count - 1)
	if strike_count >= max_strikes:
		_finish_failure()
		return
	var expression := "concerned" if strike_count == 1 else "angry"
	dialogue.say("Careful - strike %d of %d. Keep it away from the ends." % [strike_count, max_strikes], expression, 2.8, "vendor_miki")

func _update_sweet_spot(delta: float) -> void:
	sweet_change_timer -= delta
	if sweet_change_timer <= 0.0:
		sweet_target_center = randf_range(0.22, 0.78)
		sweet_target_size = randf_range(0.12, 0.34)
		sweet_change_timer = randf_range(0.35, 0.75)
	var movement_weight := clampf(10.0 * delta, 0.0, 1.0)
	sweet_center = lerpf(sweet_center, sweet_target_center, movement_weight)
	sweet_size = lerpf(sweet_size, sweet_target_size, movement_weight)

func _is_in_sweet_spot() -> bool:
	return tension >= sweet_center - sweet_size * 0.5 and tension <= sweet_center + sweet_size * 0.5

func _setup_shared_overlays() -> void:
	dialogue = DIALOGUE_SCENE.instantiate() as SharedDialogue
	add_child(dialogue)
	dialogue.set_character("vendor_miki", "neutral")
	SharedCursor.install()
	SharedCursor.set_grab()

func _setup_audio() -> void:
	music_player = _make_loop_player(MUSIC, -16.0)
	ambience_player = _make_loop_player(AMBIENCE, -25.0)
	extrusion_player = _make_loop_player(EXTRUSION, -22.0)
	sfx = AudioStreamPlayer.new()
	sfx.volume_db = -8.0
	add_child(sfx)

func _make_loop_player(stream: AudioStream, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	var runtime_stream := stream.duplicate()
	if runtime_stream is AudioStreamOggVorbis:
		(runtime_stream as AudioStreamOggVorbis).loop = true
	player.stream = runtime_stream
	player.volume_db = volume_db
	add_child(player)
	return player

func _start_game_audio() -> void:
	if not music_player.playing:
		music_player.play()
	if not ambience_player.playing:
		ambience_player.play()

func _stop_game_audio() -> void:
	extrusion_player.stop()
	music_player.stop()
	ambience_player.stop()

func _update_extrusion_audio() -> void:
	if _is_in_sweet_spot():
		if not extrusion_player.playing:
			extrusion_player.play()
	elif extrusion_player.playing:
		extrusion_player.stop()

func _setup_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "MikiHUD"
	# Vendor minigames render on MinigameSession's gameplay layer (80).
	# Keep the HUD above gameplay while leaving shared dialogue (100) on top.
	hud.layer = 90
	add_child(hud)
	_add_sprite("ProgressPanel", PROGRESS_PANEL, Vector2(516, 88), 0)
	progress_green = _add_sprite("ProgressGreen", PROGRESS_GREEN, Vector2(516, 88), 1)
	progress_green.region_enabled = true
	progress_green.centered = false
	progress_green.region_rect = Rect2(0, 0, 1, 177)
	_add_sprite("ProgressFrame", PROGRESS_FRAME, Vector2(516, 88), 2)
	var tension_frame := _add_sprite("TensionFrame", TENSION_FRAME, Vector2(676, 304), 1)
	tension_frame.scale = Vector2(0.6, 0.6)
	tension_green = _add_sprite("TensionGreen", TENSION_GREEN, Vector2(676, 304), 2)
	tension_green.scale = Vector2(0.6, 0.6)
	tension_needle = _add_sprite("TensionNeedle", TENSION_NEEDLE, Vector2(676, 304), 3)
	tension_needle.scale = Vector2(0.6, 0.6)
	_setup_warning_markers()

func _add_sprite(node_name: String, texture: Texture2D, position: Vector2, z: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.position = position
	sprite.z_index = z
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hud.add_child(sprite)
	return sprite

func _setup_warning_markers() -> void:
	# Matches Snatch Battle: origin (851, 8) + half of 293 x 350.
	_add_sprite("WarningPanel", WARNING_PANEL, Vector2(997.5, 183.0), 0)
	var snatch_wasted_positions := [925.9, 969.825, 1013.75]
	for index in max_strikes:
		var marker := _add_sprite("WarningMarker%d" % index, NO_MISTAKE, Vector2(snatch_wasted_positions[index], 97.5), 2)
		marker.scale = Vector2(0.44, 0.44)
		warning_markers.append(marker)

func _update_hud() -> void:
	var progress_width := maxf(1.0, 414.0 * progress)
	progress_green.region_rect = Rect2(0, 0, progress_width, 177.0)
	progress_green.position = Vector2(309.0, -0.5)
	tension_green.position.x = 676.0
	tension_green.position.y = lerpf(NEEDLE_BOTTOM_Y, NEEDLE_TOP_Y, sweet_center) + TENSION_VERTICAL_OFFSET
	var size_percent := inverse_lerp(0.12, 0.34, sweet_size)
	tension_green.scale.y = lerpf(0.14, 0.50, size_percent)
	tension_needle.position.x = 676.0
	tension_needle.position.y = lerpf(NEEDLE_BOTTOM_Y, NEEDLE_TOP_Y, tension) + TENSION_VERTICAL_OFFSET

func _animate_machine() -> void:
	var tween := create_tween()
	tween.tween_property(crank_pivot, "rotation_degrees", crank_pivot.rotation_degrees + 34.0, 0.09)
	tween.parallel().tween_property(machine_body, "position:x", machine_home_position.x + 2.0, 0.04)
	tween.parallel().tween_property(machine_body_front, "position:x", machine_front_home_position.x + 2.0, 0.04)
	tween.tween_property(machine_body, "position:x", machine_home_position.x, 0.08)
	tween.parallel().tween_property(machine_body_front, "position:x", machine_front_home_position.x, 0.08)

func _complete_noodle_cycle() -> void:
	noodle_cycle_active = true
	var falling_noodles := Sprite2D.new()
	falling_noodles.texture = noodles_output.texture
	falling_noodles.position = noodles_output.position
	falling_noodles.rotation = noodles_output.rotation
	falling_noodles.scale = noodles_output.scale
	falling_noodles.z_index = noodles_output.z_index
	falling_noodles.z_as_relative = false
	falling_noodles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(falling_noodles)
	noodles_output.visible = false
	var fall_tween := create_tween()
	fall_tween.tween_property(falling_noodles, "position:y", NOODLE_END_Y + 180.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall_tween.parallel().tween_property(falling_noodles, "modulate:a", 0.0, 0.42)
	await fall_tween.finished
	falling_noodles.queue_free()
	noodle_cycle_active = false
	_finish_success()

func _pulse_marker(index: int) -> void:
	if index < 0 or index >= warning_markers.size():
		return
	var marker := warning_markers[index]
	marker.texture = YES_MISTAKE
	var tween := create_tween()
	marker.scale = Vector2(0.65, 0.65)
	tween.tween_property(marker, "scale", Vector2(0.44, 0.44), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _reset_game() -> void:
	tension = 0.48
	progress = 0.0
	noodle_extension_progress = 0.0
	strike_count = 0
	noodle_cycle_active = false
	game_finished = false
	gameplay_started = false
	seen_sweet_spot = false
	seen_outside_spot = false
	halfway_line_done = false
	extreme_latched = false
	sweet_center = 0.5
	sweet_size = 0.25
	sweet_target_center = sweet_center
	sweet_target_size = sweet_size
	sweet_change_timer = 0.0
	noodles_output.position = noodle_start
	noodles_output.visible = true
	for marker in warning_markers:
		marker.texture = NO_MISTAKE
		marker.scale = Vector2(0.44, 0.44)
	_update_hud()

func _start_game_sequence() -> void:
	_start_game_audio()
	dialogue.say(
		"Keep the needle in the green and turn the crank steadily. Three strikes ruin the dough.",
		"neutral",
		2.8,
		"vendor_miki"
	)
	for index in 3:
		sfx.stream = START_SOUND
		sfx.pitch_scale = 0.88 + float(index) * 0.08
		sfx.play()
		await get_tree().create_timer(0.42).timeout
	sfx.pitch_scale = 1.0
	gameplay_started = true


## Used by the shared instruction overlay after its countdown finishes.
func start_after_instructions() -> void:
	_start_game_audio()
	gameplay_started = true

func _finish_success() -> void:
	if game_finished:
		return
	game_finished = true
	_stop_game_audio()
	sfx.stream = COMPLETE_SOUND
	sfx.play()
	dialogue.say("Beautiful miki. That's the smooth pull we want.", "happy", 2.8, "vendor_miki")
	dialogue.dialogue_finished.connect(
		func(): $CollectibleEnding.play(),
		CONNECT_ONE_SHOT,
	)

func _finish_failure() -> void:
	if game_finished:
		return
	game_finished = true
	_stop_game_audio()
	fail_screen.call(
		"start_fail_screen",
		"Three strikes. The dough is ruined - we'll have to start over.",
		"The tension reached the danger ends three times and ruined the dough.",
		0,
		false
	)


func _setup_fail_screen() -> void:
	fail_screen = FAIL_SCREEN_SCENE.instantiate()
	fail_screen.name = "MinigameFailScreen"
	add_child(fail_screen)
	fail_screen.connect(
		"retry_requested",
		Callable(self, "_on_fail_retry_requested")
	)
	fail_screen.connect(
		"exit_requested",
		Callable(self, "_on_fail_exit_requested")
	)


func _on_fail_retry_requested() -> void:
	if get_tree().current_scene == self:
		get_tree().reload_current_scene()
	else:
		minigame_retry_requested.emit()


func _on_fail_exit_requested() -> void:
	minigame_failed.emit()
