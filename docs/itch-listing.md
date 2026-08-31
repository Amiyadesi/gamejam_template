# itch listing draft

Title: Amiya Godot 4.7 Jam Shell

Short: A memory-first jam template: menus, rebinding, dialogue snapshots, and saves that notice the last run.

Price: $9, PWYW minimum $5. GitHub stays MIT.

## Description

Godot 4.7, GDScript only.

Open the project, point `Menu.start_scene_path` at your first scene, instance `gameplay_ui_shell.tscn`, and spend the jam on the game instead of the shell.

Included:

- Menu, settings, credits, pause
- Input rebinding that keeps keyboard and wildcard gamepad defaults
- Modular save system (settings, bindings, player, narrative, stats)
- Dialogue balloon that can snapshot the exact line you left on
- Web-aware display settings
- Windows and Web export presets
- A deletable Echo sandbox that plants a trace and reloads it

Not included:

- A gameplay genre
- Touch virtual controls
- Automatic itch uploads
- Support tickets or custom wiring

Third-party addons keep their own licenses. This page sells the assembled shell and the docs, not exclusive rights to Dialogue Manager or LimboAI.

Evaluate the public repo first: https://github.com/Amiyadesi/gamejam_template

## After download

1. Open with Godot 4.7 (standard editor, not Mono, if you need Web).
2. Optional: set `Menu.start_scene_path` to `res://Scenes/Examples/echo_sandbox.tscn` and press Start.
3. Copy the project, change the game name, replace the sandbox with your scene.
4. Delete `Scenes/Examples`, `Dialogue/Examples`, `demo`, and `addons/limboai` if unused.
5. Run `pwsh ./tools/verify_template.ps1 -ReleaseReadiness` before you export.

## Tags

Godot, Godot 4, game jam, template, UI, save system, dialogue
