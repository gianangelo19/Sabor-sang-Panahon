class_name CollectibleEndingTrigger
extends Node

## Starts the shared bag ending and relays the original completion signal only
## after the player has placed the collectible in the bag.

const ENDING_SCENE := preload(
	"res://features/minigames/ending_sequence/scenes/collectible_ending_scene.tscn"
)

@export var collectible_texture: Texture2D
@export var collectible_scale := Vector2(0.6, 0.6)
@export var completion_signal := ""

var _active := false
var _ending: CanvasLayer


func play() -> void:
	if _active or collectible_texture == null:
		return
	_active = true
	get_tree().paused = true
	_ending = ENDING_SCENE.instantiate() as CanvasLayer
	_ending.name = "CollectibleEndingScene"
	_ending.layer = 600
	add_child(_ending)
	_ending.ending_finished.connect(_on_ending_finished, CONNECT_ONE_SHOT)
	_ending.call_deferred("start_ending", collectible_texture, collectible_scale)


func _on_ending_finished() -> void:
	get_tree().paused = false
	_active = false
	if not completion_signal.is_empty() and get_parent().has_signal(completion_signal):
		get_parent().emit_signal(completion_signal)
