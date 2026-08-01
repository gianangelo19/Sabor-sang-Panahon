class_name MinigameInstructionDialogue
extends Node

## A reusable, non-invasive start overlay for the minigames.  It pauses the
## scene beneath it, so existing gameplay logic does not run until the player
## has read the instruction dialogue and the countdown has completed.

signal instructions_finished(minigame_id: String)

const DIALOGUE_SCENE := preload("res://features/minigames/shared/dialogue/shared_dialogue.tscn")
const FONT := preload("res://features/minigames/shared/fonts/VCR_OSD_MONO_1.001.ttf")
const INSTRUCTION_MUSIC := preload("res://features/minigames/introduction/assets/audio/music/bgm_instruction_loop.ogg")
const COUNTDOWN_SOUNDS := [
	preload("res://features/minigames/introduction/assets/audio/sfx/sfx_countdown_3.wav"),
	preload("res://features/minigames/introduction/assets/audio/sfx/sfx_countdown_2.wav"),
	preload("res://features/minigames/introduction/assets/audio/sfx/sfx_countdown_1.wav"),
	preload("res://features/minigames/introduction/assets/audio/sfx/sfx_countdown_go.wav"),
]

const INSTRUCTIONS := {
	"box_unboxing": "Let's open the old box.\nDrag each item to inspect it.\nFind every important memory.",
	"chicharon_beat": "Watch the moving timing line.\nTake chicharon at each target.\nAvoid wasting seven pieces.",
	"egg_sorting": "Inspect every egg carefully.\nPlace only good eggs in the basket.\nThree mistakes end the sorting.",
	"guinamos_jar_pick": "Study the jars with your senses.\nUse hints only when you need them.\nChoose the properly aged guinamos.",
	"miki_noodle_crank": "Turn the crank steadily.\nKeep the needle in the green zone.\nThree strikes ruin the dough.",
	"snatch_battle": "Follow the order on the board.\nSave the required cuts from hands.\nThrow unwanted meat in the trash.",
	"final_cooking": "Complete each cooking step.\nFollow the tools and ingredient cues.\nFinish the batchoy with Lola.",
}

const SPEAKERS := {
	"box_unboxing": "mc",
	"chicharon_beat": "vendor_chicharon",
	"egg_sorting": "vendor_egg",
	"guinamos_jar_pick": "vendor_guinamos",
	"miki_noodle_crank": "vendor_miki",
	"snatch_battle": "vendor_snatch",
	"final_cooking": "lola",
}

@export_enum(
	"box_unboxing", "chicharon_beat", "egg_sorting", "guinamos_jar_pick",
	"miki_noodle_crank", "snatch_battle", "final_cooking"
) var minigame_id := "box_unboxing"

## Optional entry point on the parent game, called after the countdown.
@export var parent_start_method := ""
@export_range(0.3, 2.0, 0.05) var countdown_step_seconds := 0.70
@export_range(0.0, 5.0, 0.1) var post_countdown_pause_seconds := 2.0

var _dim_layer: CanvasLayer
var _dialogue: SharedDialogue
var _music: AudioStreamPlayer
var _countdown_sound: AudioStreamPlayer
var _countdown_label: Label
var _started := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("start_instructions")


func start_instructions() -> void:
	if _started:
		return
	_started = true
	get_tree().paused = true
	_create_overlay()
	_play_instruction_music()
	_dialogue.dialogue_finished.connect(_start_countdown, CONNECT_ONE_SHOT)
	_dialogue.say(
		str(INSTRUCTIONS.get(minigame_id, "Get ready to begin.\nFollow the instructions carefully.\nGood luck!")),
		"neutral",
		-1.0,
		str(SPEAKERS.get(minigame_id, "mc"))
	)


func _create_overlay() -> void:
	_dim_layer = CanvasLayer.new()
	_dim_layer.name = "InstructionDim"
	_dim_layer.layer = 500
	_dim_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_dim_layer)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	# Gameplay nodes are paused; leaving this pass-through lets SharedDialogue
	# receive the click used to advance the instruction.
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim_layer.add_child(dim)

	_countdown_label = Label.new()
	_countdown_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_countdown_label.offset_left = -160.0
	_countdown_label.offset_top = -82.0
	_countdown_label.offset_right = 160.0
	_countdown_label.offset_bottom = 82.0
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_countdown_label.add_theme_font_override("font", FONT)
	_countdown_label.add_theme_font_size_override("font_size", 92)
	_countdown_label.add_theme_color_override("font_color", Color("f6d99d"))
	_countdown_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_countdown_label.add_theme_constant_override("outline_size", 8)
	_countdown_label.visible = false
	_countdown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim_layer.add_child(_countdown_label)

	_dialogue = DIALOGUE_SCENE.instantiate() as SharedDialogue
	_dialogue.name = "InstructionDialogue"
	_dialogue.layer = 501
	_dialogue.process_mode = Node.PROCESS_MODE_ALWAYS
	_dialogue.maximum_text_lines = 3
	add_child(_dialogue)

	_music = AudioStreamPlayer.new()
	_music.stream = INSTRUCTION_MUSIC
	_music.volume_db = -15.0
	_music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music)

	_countdown_sound = AudioStreamPlayer.new()
	_countdown_sound.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_countdown_sound)


func _play_instruction_music() -> void:
	if _music.stream != null:
		_music.play()


func _start_countdown() -> void:
	if not is_instance_valid(_countdown_label):
		_finish()
		return
	_countdown_label.visible = true
	for index: int in range(COUNTDOWN_SOUNDS.size()):
		_countdown_label.text = "GO!" if index == 3 else str(3 - index)
		_countdown_sound.stream = COUNTDOWN_SOUNDS[index]
		_countdown_sound.play()
		await get_tree().create_timer(countdown_step_seconds, true).timeout
	if post_countdown_pause_seconds > 0.0:
		await get_tree().create_timer(
			post_countdown_pause_seconds,
			true
		).timeout
	_countdown_label.visible = false
	_finish()


func _finish() -> void:
	if not parent_start_method.is_empty() and get_parent().has_method(parent_start_method):
		get_parent().call(parent_start_method)
	if is_instance_valid(_music):
		_music.stop()
	get_tree().paused = false
	instructions_finished.emit(minigame_id)
	queue_free()
