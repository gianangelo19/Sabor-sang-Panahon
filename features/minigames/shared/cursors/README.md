# Shared cursors

Install the shared cursor set once when a minigame starts:

```gdscript
func _ready() -> void:
	SharedCursor.install()
```

Change the active cursor as interaction changes:

```gdscript
SharedCursor.set_normal()
SharedCursor.set_pointer()
SharedCursor.set_grab()
SharedCursor.set_dragging()
```

For buttons and other `Control` nodes, set their cursor shape to
`Control.CURSOR_POINTING_HAND` after calling `install()`. Godot will use the
shared pointing-hand artwork registered for that shape.
