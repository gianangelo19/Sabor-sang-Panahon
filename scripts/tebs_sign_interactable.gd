extends Node3D

@export var covered_texture: Texture2D
@export var revealed_texture: Texture2D
@export var sign_mesh_path: NodePath = ^"MeshInstance3D"
@export var required_ingredient_ids: Array[String] = [
	"fresh_miki",
	"pork_and_liver",
	"crushed_chicharon",
	"egg",
]
@export var revealed_clue := "Teb's Old La Paz Batchoyan signage revealed."
@export var reveal_objective := "Find the hidden Batchoy Bowl artifact."
@export var reveal_ambot_status := "AMBot tokens depleted. Cultural Echo search required."
@export var reveal_duration := 0.8

var _mesh: MeshInstance3D
var _material: StandardMaterial3D
var _revealed := false
var _revealing := false


func _ready() -> void:
	_mesh = get_node_or_null(sign_mesh_path) as MeshInstance3D
	_prepare_material()
	_revealed = GameState.clues.has(revealed_clue)
	_apply_texture(revealed_texture if _revealed else covered_texture)


func get_interaction_text() -> String:
	if _revealed:
		return "Press E to inspect Teb's sign"
	if _has_required_ingredients():
		return "Press E to uncover Teb's sign"
	return "Press E to inspect covered sign"


func interact() -> void:
	if _revealing:
		return
	if _revealed:
		print("The sign reads: Teb's Old La Paz Batchoyan.")
		return
	if not _has_required_ingredients():
		print("The sign is still covered. The memory feels incomplete.")
		return

	_reveal_sign()


func _prepare_material() -> void:
	if _mesh == null:
		return
	var base_material := _mesh.get_active_material(0) as StandardMaterial3D
	if base_material:
		_material = base_material.duplicate() as StandardMaterial3D
	else:
		_material = StandardMaterial3D.new()
	_material.resource_local_to_scene = true
	_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.albedo_color = Color(1, 1, 1, 1)
	_mesh.material_override = _material


func _has_required_ingredients() -> bool:
	var has_required_ids := true
	for ingredient_id in required_ingredient_ids:
		if not GameState.has_ingredient(ingredient_id):
			has_required_ids = false
			break
	return has_required_ids or GameState.ingredients_found >= GameState.ingredients_total


func _reveal_sign() -> void:
	_revealing = true
	_revealed = true
	GameState.add_clue(revealed_clue)
	GameState.set_objective(reveal_objective)
	GameState.set_ambot_status(reveal_ambot_status)

	if _material == null:
		_apply_texture(revealed_texture)
		_revealing = false
		return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(Callable(self, "_set_material_brightness"), 1.0, 0.35, reveal_duration * 0.45)
	tween.tween_callback(Callable(self, "_swap_to_revealed_texture"))
	tween.tween_method(Callable(self, "_set_material_brightness"), 0.35, 1.0, reveal_duration * 0.55)
	tween.tween_callback(Callable(self, "_finish_reveal"))


func _apply_texture(texture: Texture2D) -> void:
	if _material == null or texture == null:
		return
	_material.albedo_texture = texture
	_set_material_brightness(1.0)


func _swap_to_revealed_texture() -> void:
	if _material == null or revealed_texture == null:
		return
	_material.albedo_texture = revealed_texture
	_set_material_brightness(0.35)


func _set_material_brightness(brightness: float) -> void:
	if _material == null:
		return
	var value := clampf(brightness, 0.0, 1.0)
	_material.albedo_color = Color(value, value, value, 1.0)


func _finish_reveal() -> void:
	_revealing = false
