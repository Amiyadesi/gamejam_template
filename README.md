# Game Jam Template

Godot 4.7 GDScript-only starter for game jams. It provides a reusable menu, settings, credits, pause UI, input rebinding, save modules, audio routing, feedback overlays, and scene transitions without prescribing gameplay.

This is not another generic pause-menu pack. The shell is built so **the next run can know the last run**: slot/global saves, dialogue line snapshots, unclean-exit detection, and stats that survive across sessions. Use it when the jam idea cares about memory. Use Maaack or hatmix when you only need menus.

Current template release: **0.1.0-beta.2** (`v0.1.0-beta.2`).

Positioning, itch copy, and a ship checklist live in:

- `docs/why-this-template.md`
- `docs/itch-listing.md`
- `docs/packaging-checklist.md`
- `ATTRIBUTION.md`

## Quick Start

1. Open the repository with Godot 4.7 and let imports finish.
2. Open `Scenes/UI/Menu/menu.tscn`.
3. Select the root `Menu` and set `start_scene_path` to the first gameplay scene.
4. Select `KeybindingUI` in `Scenes/UI/Menu/setting_screen.tscn` and edit its authored `action_allowlist` and `label_map` for your game's controls.
5. Instance `Scenes/UI/Gameplay/gameplay_ui_shell.tscn` once under the gameplay scene root.
6. Run the menu and verify Start, Settings, Credits, keyboard/gamepad focus, and Pause before adding gameplay.

The template intentionally has no default gameplay scene. Start stays disabled until `start_scene_path` points to a valid packed scene.

To feel the memory path without writing a game first, point `start_scene_path` at `res://Scenes/Examples/echo_sandbox.tscn`. Attack plants a trace; reopen the scene to see the ghost. Delete `Scenes/Examples/` when you start real work.

## Copy Checklist

After copying the template into a new game:

1. Change `application/config/name`, icons, boot splash, and export metadata.
2. Set `Menu.start_scene_path` to a real gameplay `PackedScene`.
3. Decide whether the copied project needs the bundled `Dialogue/Examples/demo` content, `Scenes/Examples`, and `addons/limboai`; delete them when they are not used.
4. Keep the five core editor plugins enabled: Dialogue Manager, Enhanced Save System, Richer Text Label, SceneManager, and SoundManager.
5. Leave Phantom Camera, Simple GUI Transitions, and Project Time Tracker disabled unless the game explicitly adopts them. Re-enable their autoloads only together with their project code.
6. Credit shipped third-party addons in `thank_screen` using `ATTRIBUTION.md`.
7. Run `pwsh ./tools/verify_template.ps1 -ReleaseReadiness -GodotPath <Godot-4.7-console>` before making a release build.

The readiness command intentionally fails while the project still has the template name or an empty `Menu.start_scene_path`.
