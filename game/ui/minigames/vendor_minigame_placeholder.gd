extends Control

signal minigame_completed
signal minigame_failed

@onready var title_label: Label = %TitleLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var reward_label: Label = %RewardLabel


func _ready() -> void:
	%ContinueButton.pressed.connect(_on_continue_pressed)
	%ReturnButton.pressed.connect(_on_return_pressed)
	%ContinueButton.grab_focus()


func configure_placeholder(context: Dictionary) -> void:
	title_label.text = str(context.get("title", "Challenge Coming Soon"))
	instruction_label.text = str(context.get("instructions", "This challenge is being updated."))
	reward_label.text = "Story reward: " + str(context.get("reward", "Continue the story"))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_continue_pressed() -> void:
	minigame_completed.emit()
	queue_free()


func _on_return_pressed() -> void:
	minigame_failed.emit()
	queue_free()
