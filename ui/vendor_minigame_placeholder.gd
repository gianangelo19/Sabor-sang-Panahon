extends Control

signal minigame_won
signal dismissed

@onready var title_label: Label = %TitleLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var reward_label: Label = %RewardLabel


func _ready() -> void:
	%CompleteButton.pressed.connect(_on_complete_pressed)
	%LaterButton.pressed.connect(_on_later_pressed)
	%CompleteButton.grab_focus()


func start_minigame(title: String, instructions: String, reward: String) -> void:
	title_label.text = title
	instruction_label.text = instructions
	reward_label.text = "Reward: " + reward
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_complete_pressed() -> void:
	minigame_won.emit()
	queue_free()


func _on_later_pressed() -> void:
	dismissed.emit()
	queue_free()
