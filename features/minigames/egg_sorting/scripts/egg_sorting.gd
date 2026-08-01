extends Node2D

signal minigame_completed
signal minigame_failed
signal minigame_retry_requested

const DIALOGUE_SCENE := preload("res://features/minigames/shared/dialogue/shared_dialogue.tscn")
const FAIL_SCREEN_SCENE: PackedScene = preload(
	"res://features/minigames/fail_screen/scenes/minigame_fail_screen.tscn"
)
const NO_MISTAKE := preload("res://features/minigames/egg_sorting/assets/ui/no_mistake.png")
const YES_MISTAKE := preload("res://features/minigames/egg_sorting/assets/ui/yes_mistake.png")
const ROOT := "res://features/minigames/egg_sorting/assets/"
const AUDIO_ROOT := ROOT + "audio/"
const MUSIC_PATH := AUDIO_ROOT + "music/bgm_egg_sorting_loop.wav"
const AMBIENCE_PATH := AUDIO_ROOT + "ambience/amb_egg_market_stall_loop.wav"
const UI_CLICK_PATH := AUDIO_ROOT + "ui/sfx_ui_click.wav"
const UI_HOVER_PATH := AUDIO_ROOT + "ui/sfx_ui_hover.wav"
const EGG_PICKUP_PATH := AUDIO_ROOT + "sfx/sfx_egg_pickup.wav"
const EGG_PLACE_PATH := AUDIO_ROOT + "sfx/sfx_egg_place_basket.wav"
const EGG_RETURN_PATH := AUDIO_ROOT + "sfx/sfx_egg_return.wav"
const BASKET_OPEN_PATH := AUDIO_ROOT + "sfx/sfx_basket_open.wav"
const BASKET_CLOSE_PATH := AUDIO_ROOT + "sfx/sfx_basket_close.wav"
const CANDLE_REVEAL_PATH := AUDIO_ROOT + "sfx/sfx_candle_reveal.wav"
const WRONG_CHECK_PATH := AUDIO_ROOT + "sfx/sfx_wrong_check.wav"
const SUCCESS_PATH := AUDIO_ROOT + "sfx/sfx_success.wav"
const FAILURE_PATH := AUDIO_ROOT + "sfx/sfx_failure.wav"
const TOTAL_EGGS := 15
const MIN_GOOD_EGGS := 6
const MAX_GOOD_EGGS := 9
const MAX_MISTAKES := 3
const MAX_BASKET_EGGS := 12
const SCREEN_CENTER := Vector2(576, 324)
const INSPECTION_CENTER := Vector2(782, 313)
const INSPECTION_RADIUS := 180.0
# The basket artwork occupies the lower-right portion of the logical 1152x648
# playfield. Keep the drop target aligned with its visible interior instead of
# requiring the egg's center to land in the upper half of the artwork.
const BASKET_DROP_RECT := Rect2(520, 420, 550, 228)
const EGG_DROP_HALF_EXTENTS := Vector2(42, 56)
const UNSORTED_RECT := Rect2(38, 95, 350, 425)
const BASKET_VISIBLE_POSITION := Vector2(792, 648)
const BASKET_HIDDEN_POSITION := Vector2(792, 970)
const BASKET_EGG_LAYOUT_OFFSET := Vector2(-60, 50)
const BASKET_SLOTS := [
	# Back row
	Vector2(675, 460), Vector2(755, 450), Vector2(835, 458),
	Vector2(915, 450), Vector2(995, 460),
	# Middle row
	Vector2(700, 515), Vector2(780, 505), Vector2(860, 512),
	Vector2(940, 505), Vector2(1020, 515),
	# Front row
	Vector2(730, 570), Vector2(810, 562), Vector2(890, 568),
	Vector2(970, 562), Vector2(1050, 570),
]

var rng := RandomNumberGenerator.new()
var dialogue: SharedDialogue
var eggs_root := Node2D.new()
var eggs: Array[Dictionary] = []
var review_open := false
var confirmation_open := false
var dragging_id := -1
var drag_started_in_basket := false
var drag_offset := Vector2.ZERO
var mistakes := 0
var total_good_eggs := 0
var accepted_good_eggs := 0
var game_over := false
var basket_root: Node2D
var basket_sprite: Sprite2D
var basket_tween: Tween
var mistake_markers: Array[Sprite2D] = []
var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer
var fail_screen: Node
var failure_exit_emitted := false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rng.randomize()
	SharedCursor.install()
	_create_board()
	_create_ui()
	_create_dialogue()
	_create_audio()
	_setup_fail_screen()
	add_child(eggs_root)
	_spawn_eggs()


func _create_board() -> void:
	_add_fullscreen("Background", "background/egg_sorting_background.png", 0)
	_add_fullscreen("UnsortedBasket", "baskets/unsorted_egg_basket.png", 5)
	_add_fullscreen("InspectionMat", "inspection/inspection_mat.png", 10)
	_add_fullscreen("InspectionLight", "inspection/inspection_light.png", 15)
	_add_fullscreen("InspectionLamp", "inspection/inspection_lamp.png", 40)
	_add_fullscreen("UnsortedBasketRim", "baskets/unsorted_egg_basket_rim.png", 100)
	basket_root = Node2D.new()
	basket_root.name = "GoodBasketRoot"
	basket_root.position = BASKET_HIDDEN_POSITION
	add_child(basket_root)
	basket_sprite = Sprite2D.new()
	basket_sprite.name = "GoodBasket"
	basket_sprite.texture = load(ROOT + "baskets/good_egg_basket.png")
	basket_sprite.position = Vector2.ZERO
	basket_sprite.z_index = 60
	basket_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	basket_root.add_child(basket_sprite)


func _add_fullscreen(node_name: String, relative_path: String, z_value: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = load(ROOT + relative_path)
	sprite.position = SCREEN_CENTER
	sprite.z_index = z_value
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	return sprite


func _create_ui() -> void:
	var hud := CanvasLayer.new()
	hud.name = "EggSortingUI"
	hud.layer = 150
	add_child(hud)
	var review_button := _make_ui_button(
		"ReviewButton",
		"ui/review_button.png",
		Vector2(18, 18),
		Vector2(187, 74)
	)
	review_button.pressed.connect(_toggle_review)
	review_button.mouse_entered.connect(_play_ui_hover)
	hud.add_child(review_button)
	var check_button := _make_ui_button(
		"CheckButton",
		"ui/check_button.png",
		Vector2(218, 18),
		Vector2(187, 74)
	)
	check_button.pressed.connect(_request_check)
	check_button.mouse_entered.connect(_play_ui_hover)
	hud.add_child(check_button)
	hud.add_child(_make_ui_image(
		"MistakePanelVisual",
		"ui/mistake_panel.png",
		Vector2(851, 8),
		Vector2(293, 350)
	))
	var marker_positions := [
		Vector2(925.9, 97.5),
		Vector2(969.825, 97.5),
		Vector2(1013.75, 97.5),
	]
	for index in MAX_MISTAKES:
		var marker := Sprite2D.new()
		marker.name = "MistakeMarker%d" % (index + 1)
		marker.texture = NO_MISTAKE
		marker.position = marker_positions[index]
		marker.scale = Vector2(0.44, 0.44)
		marker.z_index = 1
		marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hud.add_child(marker)
		mistake_markers.append(marker)


func _make_ui_button(
	node_name: String,
	relative_path: String,
	ui_position: Vector2,
	size: Vector2
) -> TextureButton:
	var button := TextureButton.new()
	button.name = node_name
	button.texture_normal = load(ROOT + relative_path)
	button.position = ui_position
	button.size = size
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button


func _make_ui_image(
	node_name: String,
	relative_path: String,
	ui_position: Vector2,
	size: Vector2
) -> TextureRect:
	var image := TextureRect.new()
	image.name = node_name
	image.texture = load(ROOT + relative_path)
	image.position = ui_position
	image.size = size
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


func _create_dialogue() -> void:
	dialogue = DIALOGUE_SCENE.instantiate() as SharedDialogue
	add_child(dialogue)
	# Timed feedback is non-blocking. Choice buttons and Up/Down/Enter still
	# work during the explicit confirmation prompt.
	dialogue.accept_mouse_click = false
	dialogue.accept_ui_accept = false
	dialogue.set_character("vendor_egg", "neutral")
	dialogue.choice_selected.connect(_on_check_choice_selected)


func _create_audio() -> void:
	music_player = _make_loop_player(MUSIC_PATH, -20.0)
	ambience_player = _make_loop_player(AMBIENCE_PATH, -29.0)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "EggSFX"
	sfx_player.volume_db = -7.0
	sfx_player.max_polyphony = 6
	add_child(sfx_player)
	ui_player = AudioStreamPlayer.new()
	ui_player.name = "EggUISFX"
	ui_player.volume_db = -10.0
	ui_player.max_polyphony = 3
	add_child(ui_player)
	music_player.play()
	ambience_player.play()


func _make_loop_player(path: String, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	if player.stream is AudioStreamWAV:
		var wave_stream := player.stream as AudioStreamWAV
		wave_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wave_stream.loop_begin = 0
		wave_stream.loop_end = int(
			wave_stream.get_length() * float(wave_stream.mix_rate)
		)
	player.volume_db = volume_db
	add_child(player)
	return player


func _play_sfx(path: String, pitch := 1.0, volume_db := -7.0) -> void:
	if sfx_player == null:
		return
	sfx_player.stream = load(path)
	sfx_player.pitch_scale = pitch
	sfx_player.volume_db = volume_db
	sfx_player.play()


func _play_ui_click() -> void:
	if ui_player == null:
		return
	ui_player.stream = load(UI_CLICK_PATH)
	ui_player.pitch_scale = 1.0
	ui_player.play()


func _play_ui_hover() -> void:
	if ui_player == null:
		return
	ui_player.stream = load(UI_HOVER_PATH)
	ui_player.pitch_scale = 1.0
	ui_player.play()


func _spawn_eggs() -> void:
	total_good_eggs = rng.randi_range(MIN_GOOD_EGGS, MAX_GOOD_EGGS)
	var definitions: Array[Dictionary] = []
	for index in TOTAL_EGGS:
		definitions.append({
			"is_good": index < total_good_eggs,
			"difficulty": _random_difficulty(),
		})
	definitions.shuffle()
	var used_positions: Array[Vector2] = []
	for id in definitions.size():
		var spawn_position := _random_unsorted_position(used_positions)
		used_positions.append(spawn_position)
		_create_egg(id, definitions[id], spawn_position)


func _random_difficulty() -> String:
	return ["easy", "medium", "hard"][rng.randi_range(0, 2)]


func _random_unsorted_position(used_positions: Array[Vector2]) -> Vector2:
	for attempt in 80:
		var candidate := Vector2(
			rng.randf_range(90, 335),
			rng.randf_range(135, 470)
		)
		var valid := true
		for used in used_positions:
			if candidate.distance_to(used) < 48.0:
				valid = false
				break
		if valid:
			return candidate
	return Vector2(rng.randf_range(90, 335), rng.randf_range(135, 470))


func _create_egg(id: int, definition: Dictionary, start_position: Vector2) -> void:
	var area := Area2D.new()
	area.name = "Egg_%02d" % id
	area.position = start_position
	area.rotation = deg_to_rad(rng.randf_range(-20, 20))
	area.z_index = 25 + id
	var quality := "good" if bool(definition.is_good) else "bad"
	var difficulty := str(definition.difficulty)
	var exterior := Sprite2D.new()
	exterior.name = "Exterior"
	exterior.texture = load(ROOT + "eggs/exterior/egg_exterior_%s_%s_normal.png" % [difficulty, quality])
	exterior.scale = Vector2(1.1, 1.1)
	exterior.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	area.add_child(exterior)
	var interior := Sprite2D.new()
	interior.name = "Interior"
	interior.texture = load(ROOT + "eggs/interior/egg_interior_%s_%s_candled.png" % [difficulty, quality])
	interior.scale = Vector2(1.1, 1.1)
	interior.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	interior.visible = false
	area.add_child(interior)
	var collision := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 42
	capsule.height = 112
	collision.shape = capsule
	area.add_child(collision)
	area.input_event.connect(_on_egg_input.bind(id))
	eggs_root.add_child(area)
	eggs.append({
		"area": area,
		"is_good": bool(definition.is_good),
		"difficulty": difficulty,
		"accepted": false,
		"original_position": start_position,
		"original_rotation": area.rotation,
		"exterior": exterior,
		"interior": interior,
		"inspection_active": false,
	})


func _on_egg_input(
	_viewport: Node,
	event: InputEvent,
	_shape_index: int,
	id: int
) -> void:
	if game_over or confirmation_open or dragging_id >= 0:
		return
	if bool(eggs[id].accepted) and not review_open:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_play_sfx(EGG_PICKUP_PATH, rng.randf_range(0.96, 1.04), -9.0)
			drag_started_in_basket = bool(eggs[id].accepted)
			if drag_started_in_basket:
				_remove_egg_from_basket(id)
			dragging_id = id
			drag_offset = eggs[id].area.global_position - get_global_mouse_position()
			eggs[id].area.z_index = 200
			if not review_open:
				_show_basket()
			SharedCursor.set_dragging()
			get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if dragging_id < 0:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_finish_drag()
			get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	for index in eggs.size():
		var egg := eggs[index]
		if not bool(egg.accepted):
			var inspecting: bool = egg.area.global_position.distance_to(INSPECTION_CENTER) < INSPECTION_RADIUS
			egg.interior.visible = inspecting
			egg.exterior.visible = not inspecting
			if inspecting and not bool(egg.inspection_active):
				_play_sfx(CANDLE_REVEAL_PATH, rng.randf_range(0.98, 1.03), -13.0)
			egg.inspection_active = inspecting
			eggs[index] = egg
	if dragging_id >= 0:
		eggs[dragging_id].area.global_position = get_global_mouse_position() + drag_offset


func _finish_drag() -> void:
	var id := dragging_id
	dragging_id = -1
	var egg := eggs[id]
	if _egg_overlaps_basket(egg.area.global_position):
		if _accepted_egg_count() < MAX_BASKET_EGGS:
			_accept_egg(id)
		else:
			_return_egg(id)
	elif UNSORTED_RECT.has_point(egg.area.global_position) or egg.area.global_position.distance_to(INSPECTION_CENTER) < INSPECTION_RADIUS:
		egg.original_position = egg.area.global_position
		egg.original_rotation = egg.area.rotation
		egg.area.z_index = 25 + id
		eggs[id] = egg
	else:
		if drag_started_in_basket:
			_accept_egg(id)
		else:
			_return_egg(id)
	drag_started_in_basket = false
	if not review_open:
		_hide_basket()
	SharedCursor.set_grab()


func _egg_overlaps_basket(egg_position: Vector2) -> bool:
	var egg_rect := Rect2(
		egg_position - EGG_DROP_HALF_EXTENTS,
		EGG_DROP_HALF_EXTENTS * 2.0,
	)
	return BASKET_DROP_RECT.intersects(egg_rect, true)


func _remove_egg_from_basket(id: int) -> void:
	var egg := eggs[id]
	egg.area.reparent(eggs_root, true)
	egg.accepted = false
	egg.area.input_pickable = true
	if bool(egg.is_good):
		accepted_good_eggs = maxi(0, accepted_good_eggs - 1)
	eggs[id] = egg
	_place_accepted_eggs()


func _accept_egg(id: int) -> void:
	var egg := eggs[id]
	egg.accepted = true
	egg.area.input_pickable = review_open
	egg.interior.visible = false
	egg.exterior.visible = true
	egg.area.reparent(basket_root, true)
	eggs[id] = egg
	_play_sfx(EGG_PLACE_PATH, rng.randf_range(0.96, 1.04), -8.0)
	if bool(egg.is_good):
		accepted_good_eggs += 1
	_place_accepted_eggs()


func _accepted_egg_count() -> int:
	var count := 0
	for egg in eggs:
		if bool(egg.accepted):
			count += 1
	return count


func _place_accepted_eggs() -> void:
	var slot := 0
	for index in eggs.size():
		var egg := eggs[index]
		if not bool(egg.accepted):
			continue
		egg.area.position = (
			BASKET_SLOTS[mini(slot, BASKET_SLOTS.size() - 1)]
			+ BASKET_EGG_LAYOUT_OFFSET
			- BASKET_VISIBLE_POSITION
		)
		egg.area.rotation = deg_to_rad([-12, -7, 0, 7, 12][slot % 5])
		egg.area.z_index = 75 + slot
		egg.area.visible = true
		egg.area.input_pickable = review_open and not game_over
		eggs[index] = egg
		slot += 1


func _toggle_review() -> void:
	if game_over or confirmation_open or dragging_id >= 0:
		return
	_play_ui_click()
	review_open = not review_open
	if review_open:
		_show_basket()
	else:
		for egg in eggs:
			if bool(egg.accepted):
				egg.area.input_pickable = false
		_hide_basket()


func _request_check() -> void:
	if game_over or confirmation_open or dragging_id >= 0:
		return
	_play_ui_click()
	confirmation_open = true
	dialogue.ask(
		"Should I check this basket now?",
		[
			{"id": "confirm", "text": "Yes, check it"},
			{"id": "cancel", "text": "No, let me review"},
		],
		"concerned",
		"vendor_egg"
	)


func _on_check_choice_selected(
	choice_id: String,
	_index: int,
	_text: String
) -> void:
	if not confirmation_open:
		return
	_play_ui_click()
	confirmation_open = false
	if choice_id == "confirm":
		call_deferred("_evaluate_basket")
	else:
		call_deferred("_say_continue_reviewing")


func _say_continue_reviewing() -> void:
	dialogue.say(
		"Take another look. I will wait.",
		"neutral",
		1.8,
		"vendor_egg"
	)


func _evaluate_basket() -> void:
	if game_over:
		return
	var selected_good := 0
	var bad_egg: Dictionary = {}
	for egg in eggs:
		if not bool(egg.accepted):
			continue
		if bool(egg.is_good):
			selected_good += 1
		elif bad_egg.is_empty():
			bad_egg = egg
	if selected_good == total_good_eggs and bad_egg.is_empty():
		dialogue.say(
			"Perfect. These are all fresh eggs!",
			"happy",
			2.0,
			"vendor_egg"
		)
		_end_game(true)
		return
	_register_confirmation_mistake(selected_good, bad_egg)


func _register_confirmation_mistake(
	selected_good: int,
	bad_egg: Dictionary
) -> void:
	mistakes += 1
	_play_sfx(WRONG_CHECK_PATH, 1.0, -6.0)
	_update_mistake_marker(mistakes - 1)
	var feedback_parts: Array[String] = []
	if selected_good < total_good_eggs:
		feedback_parts.append(
			"There should be %d good eggs." % total_good_eggs
		)
	if not bad_egg.is_empty():
		feedback_parts.append(
			_bad_egg_clue(str(bad_egg.get("difficulty", "hard")))
		)
	var expression: String = [
		"concerned",
		"angry",
		"super_angry",
	][mini(mistakes - 1, 2)]
	if mistakes >= MAX_MISTAKES:
		_end_game(false, _basket_failure_reason(selected_good, bad_egg))
		return
	dialogue.say(
		" ".join(feedback_parts),
		expression,
		2.6,
		"vendor_egg"
	)


func _basket_failure_reason(
	selected_good: int,
	bad_egg: Dictionary
) -> String:
	var missing_good := selected_good < total_good_eggs
	var contains_bad := not bad_egg.is_empty()
	if missing_good and contains_bad:
		return "Good eggs were left behind and a bad egg was placed in the basket."
	if missing_good:
		return "Some good eggs were still left out of the basket."
	if contains_bad:
		return "A bad egg was still inside the basket."
	return "The basket was checked three times before the eggs were sorted correctly."


func _bad_egg_clue(difficulty: String) -> String:
	match difficulty:
		"easy":
			return "One selected egg is missing its yolk."
		"medium":
			return "One selected egg has a darkened yolk."
		_:
			return "One selected egg has visible discoloration inside."


func _update_mistake_marker(index: int) -> void:
	if index < 0 or index >= mistake_markers.size():
		return
	var marker := mistake_markers[index]
	marker.texture = YES_MISTAKE
	marker.scale = Vector2(0.65, 0.65)
	var tween := create_tween()
	tween.tween_property(
		marker,
		"scale",
		Vector2(0.44, 0.44),
		0.22
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _return_egg(id: int) -> void:
	var egg := eggs[id]
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(egg.area, "global_position", Vector2(egg.original_position), 0.25)
	egg.area.z_index = 25 + id
	eggs[id] = egg
	_play_sfx(EGG_RETURN_PATH, rng.randf_range(0.97, 1.03), -11.0)


func _show_basket() -> void:
	if basket_tween != null:
		basket_tween.kill()
	basket_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	basket_tween.tween_property(basket_root, "position", BASKET_VISIBLE_POSITION, 0.30)
	_play_sfx(BASKET_OPEN_PATH, 1.0, -11.0)
	_place_accepted_eggs()


func _hide_basket() -> void:
	if basket_tween != null:
		basket_tween.kill()
	basket_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	basket_tween.tween_property(basket_root, "position", BASKET_HIDDEN_POSITION, 0.23)
	_play_sfx(BASKET_CLOSE_PATH, 1.0, -11.0)


func _end_game(
	won: bool,
	failure_reason := "The eggs were not sorted correctly after three checks."
) -> void:
	if game_over:
		return
	game_over = true
	dragging_id = -1
	for egg in eggs:
		egg.area.input_pickable = false
	if won:
		_play_sfx(SUCCESS_PATH, 1.0, -4.0)
		$CollectibleEnding.play()
	else:
		music_player.stop()
		ambience_player.stop()
		fail_screen.call(
			"start_fail_screen",
			"Three checks, and the basket is still not ready. Let's inspect the eggs again.",
			failure_reason,
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
	if failure_exit_emitted:
		return
	failure_exit_emitted = true
	minigame_failed.emit()
