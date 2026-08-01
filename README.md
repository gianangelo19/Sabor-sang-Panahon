# Sabor sang Panahon

**Sabor sang Panahon** is a first-person 3D cultural mystery game set in La Paz, Iloilo. Follow Cultural Echoes, recover the ingredients of a forgotten dish through vendor minigames, and find the Batchoy Bowl before Grandma returns.

## Download and play on Windows

The packaged Windows version does not require Godot, an installer, an account, or an internet connection.

1. Open the [GitHub Releases page](https://github.com/gianangelo19/Sabor-sang-Panahon/releases).
2. Download `Sabor-sang-Panahon-Windows-x86_64.zip` from the latest release.
3. Right-click the downloaded ZIP and select **Extract All**.
4. Open the extracted folder and run `Sabor sang Panahon.exe`.

Do not run the executable from inside the ZIP. Extract it first. The release is currently unsigned, so Windows SmartScreen may display a warning. If it does, select **More info**, verify that the file came from this repository, and select **Run anyway**.

### Windows requirements

- 64-bit Windows 10 or Windows 11
- A Vulkan-compatible graphics card with current drivers
- Keyboard and mouse
- Approximately 3 GB of free storage for the download and extracted game

## Controls

| Action | Input |
| --- | --- |
| Move | `W`, `A`, `S`, `D` |
| Look | Mouse |
| Interact | `E` |
| Jump | `Space` |
| Phone | `P` |
| Pause / Settings | `Esc` |

The story uses seven installed minigames: Box Unboxing, Snatch Battle,
Guinamos Jar Pick, Egg Sorting, Chicharon Beat, Miki Noodle Crank, and the
final Batchoy Cooking sequence. Each challenge starts with its instruction and
countdown flow, uses the shared failure/retry and collectible-ending screens,
and returns its result to the story. The herbs and seasoning stops are
dialogue-only rewards and advance through the same vendor reward pipeline.

## Run from source

Developers can run the project directly with Godot:

1. Install [Godot Engine 4.7](https://godotengine.org/download/archive/4.7-stable/).
2. Clone or download this repository.
3. In the Godot Project Manager, select **Import** and choose `project.godot`.
4. Open the project and press `F5` to run it.

The repository is organized by responsibility: reusable engine code is under
`core/`, playable content is under `game/`, self-contained minigames are under
`features/minigames/`, and source media is under `assets/`. See
[`docs/project_structure.md`](docs/project_structure.md) for the full layout.

Run the complete headless test suite with:

```bash
tools/run_tests.sh
```

## Build the Windows executable

Install the Godot 4.7 export templates, then run this command from the repository root:

```powershell
godot --headless --path . --export-release "Windows Desktop" "build/windows/Sabor sang Panahon.exe"
```

The Windows preset embeds the project data into the executable, producing a portable build under `build/windows/`. Local builds and release archives are intentionally excluded from Git.

## Procedural artifact placement

The final Batchoy Bowl hunt runs entirely inside Godot. It checks the authored hiding markers in `game/worlds/la_paz/grandma_house/lapaz_home.tscn`, filters blocked locations using a bowl-sized collision volume, and uniformly selects among safe locations that have not recently been used.

The 30-second countdown starts after a location is selected. No model, local server, API key, or internet connection is required.
