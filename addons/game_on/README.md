# GameOn Integration Plugin

Godot 4.x integration for GameOn browser authentication and artifact rewards.

## Project configuration

Enable the plugin in **Project Settings > Plugins**. It registers
`GameOnPortal` as an autoload and adds these settings:

- `game_on/api_url`: GameOn API origin. This project uses
  `https://staging.gameonportal.ph`.
- `game_on/game_id`: Game ID assigned in the GameOn dashboard. This project
  uses `b806524a-5cc5-41d9-9696-417683c6254c`.

Authentication credentials are kept in memory. A player must connect again
after restarting the application.

## Authentication

Open the provided authentication scene from the main menu:

```gdscript
get_tree().change_scene_to_file("res://addons/game_on/auth_panel.tscn")
```

The panel starts browser authentication, polls GameOn for completion, and
returns to `res://game/ui/menus/main_menu.tscn`. The main menu should permit
gameplay only while `GameOnPortal.is_authorized` is true.

Authentication state is reported through:

```gdscript
GameOnPortal.authorization_status_changed.connect(_on_status_changed)
```

Possible status values are `idle`, `connecting`, `pending`, `authorized`,
`expired`, and `error`.

## Unlocking an artifact

Call the unlock API only after the local win condition has succeeded:

```gdscript
func request_reward() -> void:
    if not GameOnPortal.unlock_artifact():
        return
```

`unlock_artifact() -> bool` returns false when the current session is not
authorized or another unlock request is already running. Only one request can
be in flight at a time.

Listen for both outcomes:

```gdscript
func _ready() -> void:
    GameOnPortal.artifact_unlocked.connect(_on_artifact_unlocked)
    GameOnPortal.artifact_unlock_failed.connect(_on_artifact_unlock_failed)

func _on_artifact_unlocked(data: Dictionary, is_new_unlock: bool) -> void:
    pass

func _on_artifact_unlock_failed(message: String, requires_auth: bool) -> void:
    pass
```

`artifact_unlocked` is emitted for a newly unlocked artifact and for a
server-confirmed already-owned artifact. Cached metadata may fill in the latter
response, but a network or server failure never becomes a cached success.

`artifact_unlock_failed` reports a displayable message and whether the player
must reconnect. An HTTP 401 or 403 clears the in-memory authorization state.

## Reward UI

`artifact_success.tscn` is designed to be instanced as an overlay so the active
gameplay scene remains loaded. Its public states are:

```gdscript
reward_ui.show_loading()
reward_ui.show_artifact(artifact_data, is_new_unlock)
reward_ui.show_error(message, requires_auth)
```

Signals:

- `retry_requested`: retry the unlock, or reconnect first when required.
- `continue_requested`: continue without a GameOn reward.
- `back_pressed`: compatibility signal emitted with Continue.

The game must preserve local completion even when GameOn is unavailable.

Sabor sang Panahon does not use the addon's default reward scene in its ending.
The ending instances `game/ui/artifact/artifact_discovery_popup.tscn` and feeds
the same loading, success, failure, and retry states into that styled local
screen. On success, its title, description, and optional thumbnail come from
the confirmed GameOn artifact response.

## Troubleshooting

- If authentication fails immediately, verify `game_on/game_id` in Project
  Settings and confirm it belongs to the staging project.
- If the browser completes but the game does not authorize, confirm the
  staging account and inspect the session polling response.
- If an unlock fails, verify that an artifact is assigned to the Game ID in the
  dashboard and inspect the reported HTTP error.
- If the thumbnail is missing, confirm the returned `thumbnailUrl` is reachable
  and uses PNG, JPEG, or WebP.
- Windows exports must be smoke-tested for browser launch, return-to-game
  polling, and thumbnail downloads.
