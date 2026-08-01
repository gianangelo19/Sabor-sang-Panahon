class_name FinalCookingAudio
extends Node

const MUSIC: AudioStreamOggVorbis = preload(
	"res://features/minigames/final_cooking/assets/audio/music/bgm_final_cooking_loop.ogg"
)

const SFX: Dictionary = {
	"cut_slice": preload("res://features/minigames/final_cooking/assets/audio/sfx/sfx_cut_slice.wav"),
	"item_pickup": preload("res://features/minigames/final_cooking/assets/audio/sfx/sfx_item_pickup.wav"),
	"ingredient_ready": preload("res://features/minigames/final_cooking/assets/audio/sfx/sfx_ingredient_ready.wav"),
	"ui_navigate": preload("res://features/minigames/final_cooking/assets/audio/sfx/sfx_ui_navigate.wav"),
	"water_pour": preload("res://features/minigames/final_cooking/assets/audio/sfx/sfx_water_pour.wav"),
	"ingredient_drop": preload("res://features/minigames/final_cooking/assets/audio/sfx/sfx_ingredient_drop.wav"),
	"burner_knob": preload("res://features/minigames/final_cooking/assets/audio/sfx/sfx_burner_knob.wav"),
	"foam_skim": preload("res://features/minigames/final_cooking/assets/audio/sfx/sfx_foam_skim.wav"),
	"seasoning_pour": preload("res://features/minigames/final_cooking/assets/audio/sfx/sfx_seasoning_pour.wav"),
	"correct": preload("res://features/minigames/final_cooking/assets/audio/sfx/sfx_correct.wav"),
	"wrong": preload("res://features/minigames/final_cooking/assets/audio/sfx/sfx_wrong.wav"),
	"chicharon_crush": preload("res://features/minigames/final_cooking/assets/audio/sfx/sfx_chicharon_crush.wav"),
	"bowl_place": preload("res://features/minigames/final_cooking/assets/audio/sfx/sfx_bowl_place.wav"),
	"egg_crack": preload("res://features/minigames/final_cooking/assets/audio/sfx/sfx_egg_crack.wav"),
	"stage_complete": preload("res://features/minigames/final_cooking/assets/audio/sfx/sfx_stage_complete.wav"),
	"final_complete": preload("res://features/minigames/final_cooking/assets/audio/sfx/sfx_final_complete.wav"),
}

const SFX_POOL_SIZE := 8

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var next_sfx_player := 0


func _ready() -> void:
	add_to_group("final_cooking_audio")

	music_player = AudioStreamPlayer.new()
	music_player.name = "FinalCookingMusic"
	var music_stream := MUSIC.duplicate() as AudioStreamOggVorbis
	music_stream.loop = true
	music_player.stream = music_stream
	music_player.volume_db = -13.0
	add_child(music_player)

	for index in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "FinalCookingSfx%02d" % (index + 1)
		add_child(player)
		sfx_players.append(player)



func start_music() -> void:
	if music_player != null and not music_player.playing:
		music_player.play()


func stop_music() -> void:
	if music_player != null:
		music_player.stop()


func play_sfx(sound_name: String, volume_db := -5.0, pitch_scale := 1.0) -> void:
	if not SFX.has(sound_name) or sfx_players.is_empty():
		return

	var player := sfx_players[next_sfx_player]
	next_sfx_player = (next_sfx_player + 1) % sfx_players.size()
	player.stop()
	player.stream = SFX[sound_name] as AudioStream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()
