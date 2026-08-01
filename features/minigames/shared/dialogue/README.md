# Shared dialogue overlay

Add `shared_dialogue.tscn` as a child of a minigame scene. The MC portrait is
always visible; the bubble appears in front of it only while a line or dialogue
queue is active. Dialogue bubbles display at most three wrapped text lines.

```gdscript
@onready var dialogue: SharedDialogue = $SharedDialogue

dialogue.say("There should be something else in here.", "concerned")

dialogue.play([
	{"text": "That was close!", "expression": "surprised"},
	{"text": "I need to be more careful.", "expression": "concerned"},
])

dialogue.say_random([
	"There should be something else in here.",
	"Am I really done looking?",
	"Maybe I should check beneath everything.",
], SharedDialogue.Emotion.CONCERNED)

dialogue.ask("Close the box now?", [
	{"id": "keep_looking", "text": "Keep looking"},
	{"id": "close", "text": "Close the box"},
], "concerned")

dialogue.choice_selected.connect(func(choice_id, _index, _text):
	if choice_id == "close":
		close_box()
)
```

Click, Space, or Enter reveals a typing line immediately; pressing again moves
to the next line. Pass a positive `auto_hide` value to advance automatically.
The signals `dialogue_started`, `line_started`, `line_finished`, and
`dialogue_finished` can pause or resume game mechanics. Conditional prompts
emit `choice_presented` and `choice_selected`. During a choice, gameplay is
darkened behind the portrait and bubble, while the choices appear in a centered
screen panel. Their sample selection icon is `assets/choice_selection_cursor.png`,
which can be replaced later without changing minigame code.

For future speakers, register their expression textures once:

```gdscript
dialogue.register_character("egg_vendor", {
	"neutral": preload("res://path/to/vendor_neutral.png"),
	"angry": preload("res://path/to/vendor_angry.png"),
	"super_angry": preload("res://path/to/vendor_super_angry.png"),
})
dialogue.say("Inspect those eggs again.", "angry", -1.0, "egg_vendor")
```

The included character IDs are `mc`, `lola`, `vendor_chicharon`, `vendor_egg`,
`vendor_guinamos`, `vendor_miki`, `vendor_seasoning`, `vendor_snatch`, and
`vendor_vegetable`. Their available expression files are discovered
automatically when the dialogue scene starts.
