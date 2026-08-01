class_name SharedCursor
extends RefCounted

enum CursorType {
	NORMAL,
	POINTER,
	GRAB,
	DRAGGING,
}

const NORMAL_TEXTURE: Texture2D = preload(
	"res://features/minigames/shared/cursors/assets/cursor_normal.png"
)
const POINTER_TEXTURE: Texture2D = preload(
	"res://features/minigames/shared/cursors/assets/cursor_pointer.png"
)
const GRAB_TEXTURE: Texture2D = preload(
	"res://features/minigames/shared/cursors/assets/cursor_grab.png"
)
const DRAGGING_TEXTURE: Texture2D = preload(
	"res://features/minigames/shared/cursors/assets/cursor_dragging.png"
)

const NORMAL_HOTSPOT := Vector2(4.0, 4.0)
const POINTER_HOTSPOT := Vector2(31.0, 3.0)
const GRAB_HOTSPOT := Vector2(32.0, 27.0)
const DRAGGING_HOTSPOT := Vector2(32.0, 29.0)

static var _installed := false


static func install() -> void:
	Input.set_custom_mouse_cursor(
		NORMAL_TEXTURE,
		Input.CURSOR_ARROW,
		NORMAL_HOTSPOT
	)
	Input.set_custom_mouse_cursor(
		POINTER_TEXTURE,
		Input.CURSOR_POINTING_HAND,
		POINTER_HOTSPOT
	)
	Input.set_custom_mouse_cursor(
		GRAB_TEXTURE,
		Input.CURSOR_DRAG,
		GRAB_HOTSPOT
	)
	Input.set_custom_mouse_cursor(
		DRAGGING_TEXTURE,
		Input.CURSOR_CAN_DROP,
		DRAGGING_HOTSPOT
	)

	_installed = true
	set_normal()


static func set_cursor(cursor_type: int) -> void:
	if not _installed:
		install()

	match cursor_type:
		CursorType.POINTER:
			Input.set_default_cursor_shape(
				Input.CURSOR_POINTING_HAND
			)
		CursorType.GRAB:
			Input.set_default_cursor_shape(Input.CURSOR_DRAG)
		CursorType.DRAGGING:
			Input.set_default_cursor_shape(
				Input.CURSOR_CAN_DROP
			)
		_:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)


static func set_normal() -> void:
	if not _installed:
		install()
		return
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


static func set_pointer() -> void:
	if not _installed:
		install()
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


static func set_grab() -> void:
	if not _installed:
		install()
	Input.set_default_cursor_shape(Input.CURSOR_DRAG)


static func set_dragging() -> void:
	if not _installed:
		install()
	Input.set_default_cursor_shape(Input.CURSOR_CAN_DROP)
