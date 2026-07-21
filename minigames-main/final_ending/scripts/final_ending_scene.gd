extends Node2D

signal ending_finished

const SCREEN_SIZE: Vector2 = Vector2(1152, 648)

const FONT_PATH: String = "res://minigames-main/shared/fonts/VCR_OSD_MONO_1.001.ttf"

const SLIDES_PATH: String = "res://minigames-main/final_ending/assets/slides/"
const DIALOGUE_BOX_PATH: String = SLIDES_PATH + "dialogue_box_memory.png"

const FADE_TIME: float = 1.0
const TYPE_SPEED: float = 0.035

const SFX_SPACE: String = "res://minigames-main/final_ending/assets/audio/sfx_space_press.ogg"
const SFX_TYPE: String = "res://minigames-main/final_ending/assets/audio/sfx_typewriter_tick.ogg"
const SFX_IMAGE_FADE: String = "res://minigames-main/final_ending/assets/audio/sfx_image_fade_in.ogg"
const SFX_BLACK_FADE: String = "res://minigames-main/final_ending/assets/audio/sfx_black_fade.ogg"
const SFX_MEMORY_CHIME: String = "res://minigames-main/final_ending/assets/audio/sfx_memory_soft_chime.ogg"

enum EndingState {
	INTRO_BLACK_TEXT,
	IMAGE_ONLY,
	IMAGE_DIALOGUE,
	BATCHOY_BLACK_TEXT,
	RESTAURANT_IMAGE,
	RESTAURANT_DIALOGUE,
	FINAL_BLACK,
	DONE
}

var canvas_layer: CanvasLayer
var slide_image: TextureRect
var black_overlay: ColorRect
var dialogue_box: TextureRect
var dialogue_text: Label
var continue_label: Label
var center_text: Label

var shared_font: Font
var type_player: AudioStreamPlayer

var current_slide_index: int = 0
var state: EndingState = EndingState.INTRO_BLACK_TEXT

var input_locked: bool = false
var is_typing: bool = false
var current_full_text: String = ""

var intro_black_text: String = "Oh... a bowl...\nSo this is what I was looking for all along."
var batchoy_black_text: String = "So this is what batchoy tastes like..."
var final_black_text: String = "And now, I remember."

var slides: Array[Dictionary] = [
	{
		"image": SLIDES_PATH + "final_01_meat_slicing.png",
		"dialogue": "Every cut feels careful.\nLike these hands have done this before.\nLike the house still remembers.",
		"sfx": "res://minigames-main/final_ending/assets/audio/sfx_meat_slice_soft.ogg"
	},
	{
		"image": SLIDES_PATH + "final_02_miki_noodles.png",
		"dialogue": "Something soft falls into warmth.\nQuiet, golden, familiar.\nA memory taking shape without needing to explain itself.",
		"sfx": "res://minigames-main/final_ending/assets/audio/sfx_noodle_water_soft.ogg"
	},
	{
		"image": SLIDES_PATH + "final_03_guinamos_broth.png",
		"dialogue": "The flavor deepens slowly.\nNot loud. Not hurried.\nJust something old returning to the surface.",
		"sfx": "res://minigames-main/final_ending/assets/audio/sfx_broth_stir_soft.ogg"
	},
	{
		"image": SLIDES_PATH + "final_04_chicharon.png",
		"dialogue": "Then comes the sound.\nCrisp and bright.\nLike laughter finding its way back into an empty room.",
		"sfx": "res://minigames-main/final_ending/assets/audio/sfx_chicharon_crackle_soft.ogg"
	},
	{
		"image": SLIDES_PATH + "final_05_batchoy_bowls.png",
		"dialogue": "It all comes together here.\nNot as a recipe.\nNot as a clue.\nBut as something I somehow already knew.",
		"sfx": "res://minigames-main/final_ending/assets/audio/sfx_bowl_place_soft.ogg"
	}
]

var restaurant_slide: Dictionary = {
	"image": SLIDES_PATH + "final_06_restaurant.png",
	"dialogue": "Some traditions survive not because they are written down,\nbut because someone chooses to remember them.",
	"sfx": "res://minigames-main/final_ending/assets/audio/sfx_restaurant_memory_soft.ogg"
}


func _ready() -> void:
	shared_font = load(FONT_PATH)

	_find_or_create_nodes()
	_setup_nodes()
	_create_audio_players()
	_start_intro()


func _input(event: InputEvent) -> void:
	if input_locked:
		return

	if event.is_action_pressed("ui_accept"):
		_play_sfx(SFX_SPACE)

		if is_typing:
			_finish_typewriter_now()
			get_viewport().set_input_as_handled()
			return

		_advance()
		get_viewport().set_input_as_handled()


func _find_or_create_nodes() -> void:
	canvas_layer = get_node_or_null("CanvasLayer") as CanvasLayer

	if canvas_layer == null:
		canvas_layer = CanvasLayer.new()
		canvas_layer.name = "CanvasLayer"
		add_child(canvas_layer)

	slide_image = _get_texture_rect(["SlideImag", "SlideImage"], "SlideImage")
	black_overlay = _get_color_rect(["BlackOverl", "BlackOverlay"], "BlackOverlay")
	dialogue_box = _get_texture_rect(["DialogueB", "DialogueBox"], "DialogueBox")
	dialogue_text = _get_label(["DialogueTe", "DialogueText"], "DialogueText")
	continue_label = _get_label(["ContinueL", "ContinueLabel"], "ContinueLabel")
	center_text = _get_label(["CenterText", "CenterTextLabel"], "CenterTextLabel")


func _get_texture_rect(possible_names: Array[String], fallback_name: String) -> TextureRect:
	for node_name in possible_names:
		var found_node := canvas_layer.get_node_or_null(node_name)
		if found_node is TextureRect:
			return found_node

	var new_node := TextureRect.new()
	new_node.name = fallback_name
	canvas_layer.add_child(new_node)
	return new_node


func _get_color_rect(possible_names: Array[String], fallback_name: String) -> ColorRect:
	for node_name in possible_names:
		var found_node := canvas_layer.get_node_or_null(node_name)
		if found_node is ColorRect:
			return found_node

	var new_node := ColorRect.new()
	new_node.name = fallback_name
	canvas_layer.add_child(new_node)
	return new_node


func _get_label(possible_names: Array[String], fallback_name: String) -> Label:
	for node_name in possible_names:
		var found_node := canvas_layer.get_node_or_null(node_name)
		if found_node is Label:
			return found_node

	var new_node := Label.new()
	new_node.name = fallback_name
	canvas_layer.add_child(new_node)
	return new_node


func _setup_nodes() -> void:
	slide_image.position = Vector2.ZERO
	slide_image.size = SCREEN_SIZE
	slide_image.stretch_mode = TextureRect.STRETCH_SCALE
	slide_image.visible = false

	black_overlay.position = Vector2.ZERO
	black_overlay.size = SCREEN_SIZE
	black_overlay.color = Color(0, 0, 0, 1)
	black_overlay.visible = true

	if ResourceLoader.exists(DIALOGUE_BOX_PATH):
		dialogue_box.texture = load(DIALOGUE_BOX_PATH)

	dialogue_box.position = Vector2.ZERO
	dialogue_box.size = SCREEN_SIZE
	dialogue_box.stretch_mode = TextureRect.STRETCH_SCALE
	dialogue_box.visible = false

	dialogue_text.position = Vector2(205, 450)
	dialogue_text.size = Vector2(750, 95)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_text.visible = false

	continue_label.visible = false
	continue_label.text = ""

	center_text.position = Vector2(120, 220)
	center_text.size = Vector2(920, 210)
	center_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center_text.visible = false

	_apply_fonts()


func _apply_fonts() -> void:
	if shared_font == null:
		return

	dialogue_text.add_theme_font_override("font", shared_font)
	dialogue_text.add_theme_font_size_override("font_size", 22)
	dialogue_text.add_theme_color_override("font_color", Color(0.16, 0.10, 0.06, 1.0))

	center_text.add_theme_font_override("font", shared_font)
	center_text.add_theme_font_size_override("font_size", 34)
	center_text.add_theme_color_override("font_color", Color.WHITE)


func _create_audio_players() -> void:
	type_player = AudioStreamPlayer.new()
	type_player.name = "TypePlayer"
	type_player.volume_db = -18
	add_child(type_player)


func _start_intro() -> void:
	state = EndingState.INTRO_BLACK_TEXT
	current_slide_index = 0

	slide_image.visible = false
	dialogue_box.visible = false
	dialogue_text.visible = false
	continue_label.visible = false

	black_overlay.visible = true
	black_overlay.color = Color(0, 0, 0, 1)

	_show_center_text_typewriter(intro_black_text)
	_play_sfx(SFX_MEMORY_CHIME)


func _advance() -> void:
	match state:
		EndingState.INTRO_BLACK_TEXT:
			_hide_center_text()
			_show_current_image()

		EndingState.IMAGE_ONLY:
			_show_current_dialogue()

		EndingState.IMAGE_DIALOGUE:
			_hide_dialogue()
			current_slide_index += 1

			if current_slide_index >= slides.size():
				_start_batchoy_black_text()
			else:
				_show_current_image()

		EndingState.BATCHOY_BLACK_TEXT:
			_hide_center_text()
			_show_restaurant_image()

		EndingState.RESTAURANT_IMAGE:
			_show_restaurant_dialogue()

		EndingState.RESTAURANT_DIALOGUE:
			_hide_dialogue()
			_start_final_black()

		EndingState.FINAL_BLACK:
			_finish_ending()

		EndingState.DONE:
			return


func _show_current_image() -> void:
	state = EndingState.IMAGE_ONLY
	input_locked = true

	var slide_data: Dictionary = slides[current_slide_index]

	_set_slide_image(str(slide_data["image"]))

	slide_image.visible = true
	center_text.visible = false
	dialogue_box.visible = false
	dialogue_text.visible = false
	continue_label.visible = false

	black_overlay.visible = true
	black_overlay.color = Color(0, 0, 0, 1)

	_play_sfx(SFX_IMAGE_FADE)
	_play_sfx(str(slide_data["sfx"]))

	var tween := create_tween()
	tween.tween_property(black_overlay, "color:a", 0.0, FADE_TIME)

	await tween.finished

	black_overlay.visible = false
	input_locked = false


func _show_current_dialogue() -> void:
	state = EndingState.IMAGE_DIALOGUE

	var slide_data: Dictionary = slides[current_slide_index]
	_show_dialogue_typewriter(str(slide_data["dialogue"]))


func _start_batchoy_black_text() -> void:
	state = EndingState.BATCHOY_BLACK_TEXT
	input_locked = true

	_play_sfx(SFX_BLACK_FADE)

	black_overlay.visible = true
	black_overlay.color = Color(0, 0, 0, 0)

	var tween := create_tween()
	tween.tween_property(black_overlay, "color:a", 1.0, FADE_TIME)

	await tween.finished

	slide_image.visible = false
	dialogue_box.visible = false
	dialogue_text.visible = false

	_show_center_text_typewriter(batchoy_black_text)
	_play_sfx(SFX_MEMORY_CHIME)

	input_locked = false


func _show_restaurant_image() -> void:
	state = EndingState.RESTAURANT_IMAGE
	input_locked = true

	_set_slide_image(str(restaurant_slide["image"]))

	slide_image.visible = true
	center_text.visible = false
	dialogue_box.visible = false
	dialogue_text.visible = false
	continue_label.visible = false

	black_overlay.visible = true
	black_overlay.color = Color(0, 0, 0, 1)

	_play_sfx(SFX_IMAGE_FADE)
	_play_sfx(str(restaurant_slide["sfx"]))

	var tween := create_tween()
	tween.tween_property(black_overlay, "color:a", 0.0, FADE_TIME)

	await tween.finished

	black_overlay.visible = false
	input_locked = false


func _show_restaurant_dialogue() -> void:
	state = EndingState.RESTAURANT_DIALOGUE
	_show_dialogue_typewriter(str(restaurant_slide["dialogue"]))


func _start_final_black() -> void:
	state = EndingState.FINAL_BLACK
	input_locked = true

	_play_sfx(SFX_BLACK_FADE)

	black_overlay.visible = true
	black_overlay.color = Color(0, 0, 0, 0)

	var tween := create_tween()
	tween.tween_property(black_overlay, "color:a", 1.0, FADE_TIME)

	await tween.finished

	slide_image.visible = false
	dialogue_box.visible = false
	dialogue_text.visible = false

	_show_center_text_typewriter(final_black_text)
	_play_sfx(SFX_MEMORY_CHIME)

	input_locked = false


func _set_slide_image(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("Missing final ending image: " + path)
		return

	var texture: Texture2D = load(path)
	slide_image.texture = texture

	slide_image.position = Vector2.ZERO
	slide_image.size = SCREEN_SIZE
	slide_image.stretch_mode = TextureRect.STRETCH_SCALE


func _show_dialogue_typewriter(text: String) -> void:
	dialogue_box.visible = true
	dialogue_text.visible = true
	center_text.visible = false
	continue_label.visible = false

	current_full_text = text
	dialogue_text.text = ""

	_start_typewriter(dialogue_text, text)


func _show_center_text_typewriter(text: String) -> void:
	center_text.visible = true
	dialogue_box.visible = false
	dialogue_text.visible = false
	continue_label.visible = false

	current_full_text = text
	center_text.text = ""

	_start_typewriter(center_text, text)


func _start_typewriter(target_label: Label, text: String) -> void:
	is_typing = true
	input_locked = false

	var output := ""

	for i in range(text.length()):
		if not is_typing:
			return

		var character := text.substr(i, 1)
		output += character
		target_label.text = output

		if i % 3 == 0 and character != " " and character != "\n":
			_play_type_tick()

		await get_tree().create_timer(TYPE_SPEED, false).timeout

	is_typing = false
	current_full_text = ""
	continue_label.visible = false


func _finish_typewriter_now() -> void:
	is_typing = false

	if dialogue_text.visible:
		dialogue_text.text = current_full_text
	elif center_text.visible:
		center_text.text = current_full_text

	current_full_text = ""
	continue_label.visible = false


func _hide_dialogue() -> void:
	dialogue_box.visible = false
	dialogue_text.visible = false
	continue_label.visible = false


func _hide_center_text() -> void:
	center_text.visible = false
	continue_label.visible = false


func _finish_ending() -> void:
	state = EndingState.DONE
	input_locked = true

	ending_finished.emit()

	# Change this later if you want to go to credits or main menu.
	# get_tree().change_scene_to_file("res://main_menu/scenes/main_menu.tscn")


func _play_sfx(path: String) -> void:
	if path == "":
		return

	if not ResourceLoader.exists(path):
		return

	var stream: AudioStream = load(path)

	if stream == null:
		return

	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = -6
	add_child(player)

	player.play()
	player.finished.connect(player.queue_free)


func _play_type_tick() -> void:
	if not ResourceLoader.exists(SFX_TYPE):
		return

	if type_player.playing:
		return

	var stream: AudioStream = load(SFX_TYPE)

	if stream == null:
		return

	type_player.stream = stream
	type_player.play()
