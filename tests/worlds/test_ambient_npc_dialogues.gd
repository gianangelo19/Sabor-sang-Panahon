extends SceneTree

class MockPlayer extends Node:
	var can_move := true
	var mouse_released := false
	var mouse_captured := false

	func release_mouse() -> void:
		mouse_released = true

	func capture_mouse() -> void:
		mouse_captured = true


const AMBIENT_NPC_SCENES := [
	"res://game/characters/npcs/citizens/npc_milk.tscn",
	"res://game/characters/npcs/citizens/npc_woman.tscn",
	"res://game/characters/npcs/citizens/npc_man.tscn",
	"res://game/characters/npcs/citizens/npc_lola.tscn",
	"res://game/characters/npcs/citizens/npc_lolo.tscn",
	"res://game/characters/npcs/citizens/npc_student.tscn",
	"res://game/characters/npcs/citizens/npc_panda.tscn",
	"res://game/characters/npcs/citizens/npc_cpu_hm_student.tscn",
	"res://game/characters/npcs/citizens/npc_cpu_student.tscn",
	"res://game/characters/npcs/citizens/npc_sanag_student.tscn",
	"res://game/characters/npcs/citizens/npc_sanag_talking.tscn",
	"res://game/characters/npcs/citizens/npc_ui_student.tscn",
	"res://game/characters/npcs/citizens/npc_isatu_student_male_01.tscn",
	"res://game/characters/npcs/citizens/npc_traffic_enforcer.tscn",
]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.reset()
	var loaded_npcs: Array[Node] = []
	for scene_path in AMBIENT_NPC_SCENES:
		var scene := load(scene_path) as PackedScene
		_check(scene != null, scene_path.get_file() + " loads")
		if scene == null:
			continue
		var npc := scene.instantiate()
		loaded_npcs.append(npc)
		root.add_child(npc)
		_check(npc.has_method("interact"), npc.name + " is optionally interactable")
		_check(not npc.npc_display_name.is_empty(), npc.name + " has a character name")
		_check(
			not npc.repeat_exchange.is_empty() or not npc.repeat_lines.is_empty(),
			npc.name + " has a repeat conversation",
		)

	var player := MockPlayer.new()
	player.name = "ProtoController"
	root.add_child(player)
	var milk_vendor := loaded_npcs[0]
	milk_vendor.interact()
	await process_frame
	var dialogue := root.find_child("dialogue_ui", true, false)
	_check(dialogue != null, "Ambient interaction opens the shared dialogue UI")
	if dialogue:
		_check(dialogue.dialogue_lines.size() >= 3, "First ambient interaction has a complete exchange")
		_check(dialogue.dialogue_lines[0].speaker == "Milk", "Ambient NPC opens in their own voice")
		_check(dialogue.dialogue_lines[1].speaker == "You", "The player participates in ambient banter")
		_check(dialogue._line_speaker_target == milk_vendor, "Ambient speech bubble tracks its NPC")
		for line_index in range(dialogue.dialogue_lines.size()):
			dialogue._complete_typewriter()
			dialogue._on_continue_pressed()
	await process_frame
	_check(player.can_move and player.mouse_captured, "Ambient conversation restores player controls")
	_check(game_state.clues.is_empty(), "Ambient conversation does not change story clues")
	_check(game_state.unlocked_destinations.is_empty(), "Ambient conversation does not change story progression")

	for npc in loaded_npcs:
		npc.queue_free()
	player.queue_free()
	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	if failures.is_empty():
		print("Ambient NPC dialogue verification passed.")
		quit(0)
	else:
		print("Ambient NPC dialogue verification failed: " + ", ".join(failures))
		quit(1)
