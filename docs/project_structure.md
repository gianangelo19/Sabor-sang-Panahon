# Project structure

The active Godot project is organized by responsibility rather than file type.
Keep related scenes, scripts, and small feature-specific resources together.

```text
addons/                   Third-party Godot add-ons
assets/
  art/                    First-party images, characters, materials, shaders
  audio/                  Shared game audio
  fonts/                  Shared fonts
  ...                     Third-party asset packs
core/
  autoload/               Project-wide state and settings singletons
  audio/                  Reusable audio helpers
  interaction/            Reusable interaction components
  navigation/             Reusable navigation components
  world/                  Reusable world helpers
features/
  minigames/              Self-contained minigame features and shared code
game/
  characters/npcs/        NPC scenes and dialogue behavior
  props/                   Artifacts, environment props, signage, vehicles
  ui/                      Dialogue, HUD, phone, menus, and overlays
  worlds/la_paz/           Main world and its interior/location scenes
tests/
  core/                    Project services and save/settings tests
  minigames/               Minigame integration tests
  ui/                      HUD, dialogue, and phone tests
  worlds/                  World, NPC, ambience, and navigation tests
tools/                     Asset utilities and test runner
archive/                   Files intentionally excluded from Godot imports
```

## Placement guidelines

- Put globally reusable engine behavior in `core/`.
- Put gameplay content used by the main story in `game/`.
- Keep each minigame inside its own `features/minigames/<name>/` folder.
- Put media shared by multiple features in `assets/`; keep feature-only media
  beside its feature.
- Add tests to the category that owns the behavior being tested.
- Use `res://` paths that match this layout; do not depend on editor UIDs alone
  when moving resources between branches.

The `archive/` directory contains a legacy nested Godot project and source
assets that Godot 4.7 cannot import. Its `.gdignore` file prevents those files
from being scanned as part of the active game.
