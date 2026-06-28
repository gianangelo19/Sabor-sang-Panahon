extends StaticBody3D

@export var interaction_label: String = "interact"
@export_multiline var interaction_message: String = ""
@export var clue_to_add: String = ""
@export var next_objective: String = ""
@export var ambot_status_after_interaction: String = ""

func get_interaction_text() -> String:
	return "Press E to " + interaction_label

func interact() -> void:
	if clue_to_add.strip_edges() != "":
		GameState.add_clue(clue_to_add)
	if next_objective.strip_edges() != "":
		GameState.set_objective(next_objective)
	if ambot_status_after_interaction.strip_edges() != "":
		GameState.set_ambot_status(ambot_status_after_interaction)

	if interaction_message.strip_edges() != "":
		print(interaction_message)
	else:
		print("Interacted with " + name)
