# Sabor-sang-Panahon
Sabor sang Panahon is a first-person 3D cultural mystery game where a hungry player returns to La Paz, Iloilo to reconstruct a forgotten dish through elder memories, Cultural Echoes, procedural artifact placement, and a timed search for the Memory Bowl before Grandma comes home for dinner.

## How to Launch the Game

1. **Download Godot Engine**: This project requires [Godot 4](https://godotengine.org/download) (specifically built with Godot 4.7).
2. **Import the Project**: 
   - Open the Godot Project Manager.
   - Click **Import** and navigate to the folder containing this repository.
   - Select the `project.godot` file and click **Import & Edit**.
3. **Play**: Once the editor opens, press the **Play** button (▶) in the top right corner, or press `F5` on your keyboard to start the game!

## Procedural Artifact Placement

The final Batchoy Bowl hunt is handled entirely by Godot. It checks the eight authored hiding markers in `lapaz_home.tscn` with a collision box larger than the bowl, then makes a uniform random choice among the safe, unused locations.

The selector saves every used marker and excludes it from later searches until all safe markers have been used. The 30-second countdown starts immediately after a location is selected. No model, local server, API key, or internet connection is required.
