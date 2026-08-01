class_name BoilAndRemoveFoamStage
extends FinalCookingStage

const BACKGROUND_PATH: String = (
	"res://features/minigames/final_cooking/assets/backgrounds/bg_cooking_station_front.png"
)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func start_stage() -> void:
	_clear_runtime_nodes()
	super.start_stage()
	_build_stage()


func _build_stage() -> void:
	_build_background(BACKGROUND_PATH)

	# This stage is intentionally code-driven.
	# Create scene-specific props, UI, gameplay objects, and effects here.


func restart_stage() -> void:
	_clear_runtime_nodes()
	super.restart_stage()


func cleanup_stage() -> void:
	_clear_runtime_nodes()
