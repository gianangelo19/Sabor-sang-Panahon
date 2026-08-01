extends SceneTree

const ENTRY_SCENES := {
	"res://features/minigames/box_unboxing/scenes/box_unboxing.tscn": "BoxUnboxing",
	"res://features/minigames/snatch_battle/scenes/snatch_battle.tscn": "SnatchBattle",
	"res://features/minigames/guinamos_jar_pick/scenes/guinamos_jar_pick.tscn": "GuinamosJarPick",
	"res://features/minigames/egg_sorting/scenes/egg_sorting.tscn": "EggSorting",
	"res://features/minigames/chicharon_beat/scenes/chicharon_beat.tscn": "ChicharonBeat",
	"res://features/minigames/miki_noodle_crank/scenes/miki_noodle_crank.tscn": "MikiNoodleCrank",
	"res://features/minigames/final_cooking/scenes/final_cooking.tscn": "FinalCooking",
}
const SHARED_SCENES := [
	"res://features/minigames/shared/dialogue/shared_dialogue.tscn",
	"res://features/minigames/introduction/scenes/minigame_introduction.tscn",
	"res://features/minigames/fail_screen/scenes/minigame_fail_screen.tscn",
	"res://features/minigames/ending_sequence/scenes/collectible_ending_scene.tscn",
	"res://features/minigames/final_ending/scenes/final_ending_scene.tscn",
]
const TEXT_EXTENSIONS := ["gd", "gdshader", "tscn", "tres", "cfg", "md", "txt"]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path in ENTRY_SCENES:
		await _verify_scene(scene_path, str(ENTRY_SCENES[scene_path]))
	for scene_path in SHARED_SCENES:
		await _verify_scene(scene_path, "")

	_scan_text_resources("res://features/minigames")
	if not failures.any(func(label: String): return label.contains("reference")):
		print("PASS: Minigame text resources contain no excluded references")
	_check(
		not DirAccess.dir_exists_absolute(
			ProjectSettings.globalize_path(
				"res://features/minigames/guinamos_jar_pick/archive"
			)
		),
		"Archived Guinamos assets are excluded",
	)
	_finish()


func _verify_scene(scene_path: String, expected_name: String) -> void:
	_check(ResourceLoader.exists(scene_path), scene_path + " exists")
	var scene := load(scene_path) as PackedScene
	_check(scene != null, scene_path + " and all dependencies load")
	if scene == null:
		return
	var instance := scene.instantiate()
	_check(instance != null, scene_path + " instantiates")
	if instance == null:
		return
	if not expected_name.is_empty():
		_check(instance.name == expected_name, scene_path + " keeps its entry root")
	root.add_child(instance)
	await process_frame
	paused = false
	instance.queue_free()
	await process_frame


func _scan_text_resources(directory_path: String) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		_check(false, directory_path + " can be scanned")
		return
	for file_name in directory.get_files():
		if not file_name.get_extension().to_lower() in TEXT_EXTENSIONS:
			continue
		var file_path := directory_path.path_join(file_name)
		var contents := FileAccess.get_file_as_string(file_path)
		if contents.contains("res://minigames-main"):
			_check(false, file_path + " has a stale source-package reference")
		if contents.contains("palit_sa_mercado"):
			_check(false, file_path + " has an archived market-game reference")
	for child_directory in directory.get_directories():
		_scan_text_resources(directory_path.path_join(child_directory))


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	paused = false
	if failures.is_empty():
		print("Minigame scene-load verification passed.")
		quit(0)
	else:
		print("Minigame scene-load verification failed: " + ", ".join(failures))
		quit(1)
