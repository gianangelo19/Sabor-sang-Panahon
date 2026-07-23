extends Node2D

signal minigame_completed(score: int)
signal minigame_failed(score: int)
signal minigame_retry_requested

const SCREEN_CENTER := Vector2(576, 324)
const REQUIRED_MEATS: Array[String] = ["belly", "liver", "spleen"]
const ALL_MEATS: Array[String] = [
	"belly", "liver", "spleen",
	"pork_chop", "pork_hock", "pork_ribs", "pork_shoulder",
	"bone_cut", "fat_scraps", "old_meat",
]
const MISTAKE_LIMIT := 5

const ENDING_SCENE := preload(
	"res://features/minigames/ending_sequence/scenes/collectible_ending_scene.tscn"
)
const ENDING_COLLECTIBLE := preload(
	"res://features/minigames/ending_sequence/assets/collectibles/collectible_meat_set_bag.png"
)
const FAIL_SCREEN_SCENE := preload(
	"res://features/minigames/fail_screen/scenes/minigame_fail_screen.tscn"
)
const INTRODUCTION_SCENE := preload(
	"res://features/minigames/introduction/scenes/minigame_introduction.tscn"
)
const SHARED_FONT := preload(
	"res://features/minigames/shared/fonts/VCR_OSD_MONO_1.001.ttf"
)

const BASKET_TEXTURE := preload(
	"res://features/minigames/snatch_battle/assets/ui/basket_ui_topdown.png"
)
const TRASH_TEXTURE := preload(
	"res://features/minigames/snatch_battle/assets/ui/trashcan_ui_topdown.png"
)
const ORDER_TEXTURE := preload(
	"res://features/minigames/snatch_battle/assets/ui/order_board_required_meats_vertical.png"
)
const LEFT_HAND_TEXTURE := preload(
	"res://features/minigames/snatch_battle/assets/hands/npc_arm_left.png"
)
const RIGHT_HAND_TEXTURE := preload(
	"res://features/minigames/snatch_battle/assets/hands/npc_arm_right.png"
)

const MEAT_TEXTURES: Dictionary = {
	"belly": preload("res://features/minigames/snatch_battle/assets/meats/meat_required_belly.png"),
	"liver": preload("res://features/minigames/snatch_battle/assets/meats/meat_required_liver_atay.png"),
	"spleen": preload("res://features/minigames/snatch_battle/assets/meats/meat_required_spleen_lapay.png"),
	"pork_chop": preload("res://features/minigames/snatch_battle/assets/meats/meat_extra_pork_chop.png"),
	"pork_hock": preload("res://features/minigames/snatch_battle/assets/meats/meat_extra_pork_hock.png"),
	"pork_ribs": preload("res://features/minigames/snatch_battle/assets/meats/meat_extra_pork_ribs.png"),
	"pork_shoulder": preload("res://features/minigames/snatch_battle/assets/meats/meat_extra_pork_shoulder.png"),
	"bone_cut": preload("res://features/minigames/snatch_battle/assets/meats/meat_bad_bone_cut.png"),
	"fat_scraps": preload("res://features/minigames/snatch_battle/assets/meats/meat_bad_fat_scraps.png"),
	"old_meat": preload("res://features/minigames/snatch_battle/assets/meats/meat_bad_old_meat.png"),
}

const MUSIC := preload(
	"res://features/minigames/snatch_battle/assets/audio/music/bgm_snatch_battle_loop.ogg"
)
const AMBIENCE := preload(
	"res://features/minigames/snatch_battle/assets/audio/ambience/amb_meat_market_stall_loop.ogg"
)
const SFX_PICKUP := preload(
	"res://features/minigames/snatch_battle/assets/audio/sfx/sfx_meat_pickup_01.wav"
)
const SFX_ACCEPT := preload(
	"res://features/minigames/snatch_battle/assets/audio/sfx/sfx_basket_accept.wav"
)
const SFX_WRONG := preload(
	"res://features/minigames/snatch_battle/assets/audio/sfx/sfx_basket_wrong.wav"
)
const SFX_TRASH := preload(
	"res://features/minigames/snatch_battle/assets/audio/sfx/sfx_trash_accept.wav"
)
const SFX_STOLEN := preload(
	"res://features/minigames/snatch_battle/assets/audio/sfx/sfx_meat_stolen.wav"
)

@onready var active_items: Node2D = $ActiveItems
@onready var spawn_points: Array[Node] = $SpawnPoints.get_children()

var pieces: Array[Node2D] = []
var collected_required: Array[String] = []
var dragged_piece: Node2D
var drag_offset := Vector2.ZERO
var basket_rect := Rect2(Vector2(575, 500), Vector2(550, 148))
var trash_rect := Rect2(Vector2(25, 500), Vector2(550, 148))
var wrong_basket_count := 0
var good_discard_count := 0
var score := 100
var gameplay_active := false
var result_emitted := false
var customer_elapsed := 0.0
var customer_interval := 4.5

var order_status_label: Label
var mistake_label: Label
var feedback_label: Label
var introduction: CanvasLayer
var ending_sequence: CanvasLayer
var fail_screen: CanvasLayer
var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer


func _ready() -> void:
	randomize()
	_setup_targets_and_hud()
	_setup_audio()
	_setup_support_scenes()
	_spawn_initial_selection()
	_set_pieces_enabled(false)
	call_deferred("_start_introduction")


func _process(delta: float) -> void:
	if not gameplay_active:
		return
	customer_elapsed += delta
	if customer_elapsed >= customer_interval:
		customer_elapsed = 0.0
		customer_interval = randf_range(3.5, 5.5)
		_send_customer_hand()


func _input(event: InputEvent) -> void:
	if not gameplay_active:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_end_drag(event.position)
	elif event is InputEventMouseMotion and dragged_piece != null:
		dragged_piece.position = event.position + drag_offset


func _setup_targets_and_hud() -> void:
	var order_board := Sprite2D.new()
	order_board.name = "OrderBoard"
	order_board.texture = ORDER_TEXTURE
	order_board.position = SCREEN_CENTER
	order_board.scale = Vector2(0.6, 0.6)
	order_board.z_index = 4
	add_child(order_board)

	var basket := Sprite2D.new()
	basket.name = "Basket"
	basket.texture = BASKET_TEXTURE
	basket.position = SCREEN_CENTER
	basket.scale = Vector2(0.6, 0.6)
	basket.z_index = 5
	add_child(basket)

	var trash := Sprite2D.new()
	trash.name = "TrashCan"
	trash.texture = TRASH_TEXTURE
	trash.position = SCREEN_CENTER
	trash.scale = Vector2(0.6, 0.6)
	trash.z_index = 5
	add_child(trash)

	order_status_label = _make_label(Vector2(24, 338), Vector2(250, 82), 20)
	mistake_label = _make_label(Vector2(365, 18), Vector2(422, 36), 20)
	feedback_label = _make_label(Vector2(300, 586), Vector2(552, 44), 22)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_update_hud()


func _make_label(position_value: Vector2, size_value: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = position_value
	label.size = size_value
	label.add_theme_font_override("font", SHARED_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("fff0c2"))
	label.add_theme_color_override("font_shadow_color", Color("28130b"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.z_index = 40
	add_child(label)
	return label


func _setup_audio() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.stream = MUSIC
	music_player.volume_db = -14.0
	add_child(music_player)

	ambience_player = AudioStreamPlayer.new()
	ambience_player.stream = AMBIENCE
	ambience_player.volume_db = -20.0
	add_child(ambience_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.volume_db = -4.0
	add_child(sfx_player)


func _setup_support_scenes() -> void:
	ending_sequence = ENDING_SCENE.instantiate()
	add_child(ending_sequence)
	ending_sequence.ending_finished.connect(_on_ending_finished)

	fail_screen = FAIL_SCREEN_SCENE.instantiate()
	add_child(fail_screen)
	fail_screen.retry_requested.connect(_on_fail_retry_requested)
	fail_screen.exit_requested.connect(_on_fail_exit_requested)

	introduction = INTRODUCTION_SCENE.instantiate()
	introduction.set("auto_start_for_testing", false)
	add_child(introduction)
	introduction.countdown_finished.connect(_on_countdown_finished)


func _start_introduction() -> void:
	if introduction != null and introduction.has_method("start_introduction"):
		introduction.call("start_introduction", "snatch_battle")
	else:
		_on_countdown_finished()


func _on_countdown_finished() -> void:
	gameplay_active = true
	_set_pieces_enabled(true)
	music_player.play()
	ambience_player.play()
	feedback_label.text = "Drag the three required cuts into the basket."


func _spawn_initial_selection() -> void:
	var starting_ids: Array[String] = REQUIRED_MEATS.duplicate()
	var optional_ids: Array[String] = ALL_MEATS.slice(REQUIRED_MEATS.size())
	optional_ids.shuffle()
	for index in range(spawn_points.size()):
		var meat_id: String
		if index < starting_ids.size():
			meat_id = starting_ids[index]
		else:
			meat_id = optional_ids[(index - starting_ids.size()) % optional_ids.size()]
		_spawn_piece(meat_id, index)


func _spawn_piece(meat_id: String, spawn_index: int = -1) -> void:
	if spawn_points.is_empty() or not MEAT_TEXTURES.has(meat_id):
		return
	if spawn_index < 0:
		spawn_index = _find_open_spawn_index()
	if spawn_index < 0:
		return

	var piece := Node2D.new()
	piece.name = "Meat_" + meat_id
	piece.position = (spawn_points[spawn_index] as Marker2D).position
	piece.set_meta("meat_id", meat_id)
	piece.set_meta("spawn_index", spawn_index)
	piece.set_meta("reserved", false)
	piece.z_index = 10

	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = MEAT_TEXTURES[meat_id]
	sprite.scale = Vector2(0.30, 0.30)
	piece.add_child(sprite)
	active_items.add_child(piece)
	pieces.append(piece)


func _find_open_spawn_index() -> int:
	var open_indices: Array[int] = []
	for index in range(spawn_points.size()):
		var occupied := false
		for piece in pieces:
			if is_instance_valid(piece) and int(piece.get_meta("spawn_index")) == index:
				occupied = true
				break
		if not occupied:
			open_indices.append(index)
	if open_indices.is_empty():
		return -1
	return open_indices.pick_random()


func _choose_replacement_id() -> String:
	for required_id in REQUIRED_MEATS:
		if collected_required.has(required_id):
			continue
		var available := false
		for piece in pieces:
			if is_instance_valid(piece) and piece.get_meta("meat_id") == required_id:
				available = true
				break
		if not available:
			return required_id
	return ALL_MEATS.pick_random()


func _begin_drag(mouse_position: Vector2) -> void:
	for index in range(pieces.size() - 1, -1, -1):
		var piece := pieces[index]
		if not is_instance_valid(piece) or bool(piece.get_meta("reserved")):
			continue
		if _piece_rect(piece).has_point(mouse_position):
			dragged_piece = piece
			drag_offset = piece.position - mouse_position
			piece.z_index = 35
			_play_sfx(SFX_PICKUP)
			return


func _end_drag(mouse_position: Vector2) -> void:
	if dragged_piece == null or not is_instance_valid(dragged_piece):
		dragged_piece = null
		return
	var piece := dragged_piece
	dragged_piece = null
	if basket_rect.has_point(mouse_position):
		_drop_in_basket(piece)
	elif trash_rect.has_point(mouse_position):
		_drop_in_trash(piece)
	else:
		_return_piece(piece)


func _piece_rect(piece: Node2D) -> Rect2:
	var sprite := piece.get_node("Sprite") as Sprite2D
	var size := sprite.texture.get_size() * sprite.scale.abs()
	return Rect2(piece.position - size * 0.5, size)


func _drop_in_basket(piece: Node2D) -> void:
	var meat_id: String = piece.get_meta("meat_id")
	if REQUIRED_MEATS.has(meat_id) and not collected_required.has(meat_id):
		collected_required.append(meat_id)
		feedback_label.text = _display_name(meat_id) + " added to the order."
		_play_sfx(SFX_ACCEPT)
		_remove_piece(piece, false)
		_update_hud()
		if collected_required.size() == REQUIRED_MEATS.size():
			_start_success_ending()
	else:
		wrong_basket_count += 1
		score = maxi(0, score - 10)
		feedback_label.text = "That cut is not needed for this order."
		_play_sfx(SFX_WRONG)
		_return_piece(piece)
		_update_hud()
		_check_mistake_limits()


func _drop_in_trash(piece: Node2D) -> void:
	var meat_id: String = piece.get_meta("meat_id")
	if meat_id.begins_with("bone") or meat_id == "fat_scraps" or meat_id == "old_meat":
		feedback_label.text = "Spoiled or unusable meat discarded."
	else:
		good_discard_count += 1
		score = maxi(0, score - 10)
		feedback_label.text = "That was still a usable cut."
	_play_sfx(SFX_TRASH)
	_remove_piece(piece, true)
	_update_hud()
	_check_mistake_limits()


func _return_piece(piece: Node2D) -> void:
	piece.z_index = 10
	var spawn_index := int(piece.get_meta("spawn_index"))
	var target := (spawn_points[spawn_index] as Marker2D).position
	create_tween().tween_property(piece, "position", target, 0.18).set_trans(Tween.TRANS_BACK)


func _remove_piece(piece: Node2D, spawn_replacement: bool) -> void:
	pieces.erase(piece)
	piece.queue_free()
	if spawn_replacement and gameplay_active:
		var timer := get_tree().create_timer(0.45, false)
		timer.timeout.connect(func():
			if gameplay_active:
				_spawn_piece(_choose_replacement_id())
		)


func _send_customer_hand() -> void:
	var candidates: Array[Node2D] = []
	for piece in pieces:
		if is_instance_valid(piece) and piece != dragged_piece and not bool(piece.get_meta("reserved")):
			candidates.append(piece)
	if candidates.is_empty():
		return

	var target: Node2D = candidates.pick_random()
	target.set_meta("reserved", true)
	var hand := Sprite2D.new()
	hand.texture = LEFT_HAND_TEXTURE if bool(randi() % 2) else RIGHT_HAND_TEXTURE
	var hand_target_position := SCREEN_CENTER + Vector2(
		target.position.x - 970.0,
		target.position.y - 318.0
	)
	hand.position = hand_target_position + Vector2(-1200, 0)
	hand.scale = Vector2(0.6, 0.6)
	hand.z_index = 32
	add_child(hand)

	var approach := create_tween()
	approach.tween_property(hand, "position", hand_target_position, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	approach.finished.connect(func():
		if is_instance_valid(target):
			_play_sfx(SFX_STOLEN)
			_remove_piece(target, true)
		var exit_position := hand.position + Vector2(-1200, 0)
		var retreat := create_tween()
		retreat.tween_property(hand, "position", exit_position, 0.40)
		retreat.finished.connect(hand.queue_free)
	)


func _check_mistake_limits() -> void:
	if wrong_basket_count >= MISTAKE_LIMIT:
		_start_failure(
			"Too many incorrect cuts were placed in the basket.",
			"The order cannot be completed with the wrong meat."
		)
	elif good_discard_count >= MISTAKE_LIMIT:
		_start_failure(
			"Too many usable cuts were thrown away.",
			"The stall has run out of meat for the order."
		)


func _start_failure(dialogue: String, reason: String) -> void:
	if not gameplay_active:
		return
	gameplay_active = false
	_set_pieces_enabled(false)
	_stop_audio()
	fail_screen.call("start_fail_screen", dialogue, reason, score, true)


func _start_success_ending() -> void:
	gameplay_active = false
	_set_pieces_enabled(false)
	feedback_label.text = "Order complete!"
	_stop_audio()
	ending_sequence.call("start_ending", ENDING_COLLECTIBLE, Vector2(0.6, 0.6))


func _on_ending_finished() -> void:
	if result_emitted:
		return
	result_emitted = true
	minigame_completed.emit(score)


func _on_fail_retry_requested() -> void:
	if get_tree().current_scene == self:
		get_tree().reload_current_scene()
	else:
		minigame_retry_requested.emit()


func _on_fail_exit_requested() -> void:
	if result_emitted:
		return
	result_emitted = true
	minigame_failed.emit(score)


func _set_pieces_enabled(enabled: bool) -> void:
	for piece in pieces:
		if is_instance_valid(piece):
			piece.modulate = Color.WHITE if enabled else Color(0.72, 0.72, 0.72, 1.0)
	if not enabled:
		dragged_piece = null


func _update_hud() -> void:
	var collected_names: Array[String] = []
	for meat_id in collected_required:
		collected_names.append(_display_name(meat_id))
	order_status_label.text = "Collected: %d/3\n%s" % [
		collected_required.size(),
		", ".join(collected_names) if not collected_names.is_empty() else "Find the marked cuts",
	]
	mistake_label.text = "Wrong basket: %d/5     Good meat discarded: %d/5     Score: %d" % [
		wrong_basket_count, good_discard_count, score,
	]


func _display_name(meat_id: String) -> String:
	match meat_id:
		"belly":
			return "Pork belly"
		"liver":
			return "Atay"
		"spleen":
			return "Lapay"
		_:
			return meat_id.replace("_", " ").capitalize()


func _play_sfx(stream: AudioStream) -> void:
	sfx_player.stream = stream
	sfx_player.play()


func _stop_audio() -> void:
	music_player.stop()
	ambience_player.stop()
