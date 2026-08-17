# Game Jam Template

Godot 4.7 GDScript-only starter for game jams. It provides a reusable menu, settings, credits, pause UI, input rebinding, save modules, audio routing, feedback overlays, and scene transitions without prescribing gameplay.

Current template release: **0.1.0-beta.2** (`v0.1.0-beta.2`).

## Quick Start

1. Open the repository with Godot 4.7 and let imports finish.
2. Open `Scenes/UI/Menu/menu.tscn`.
3. Select the root `Menu` and set `start_scene_path` to the first gameplay scene.
4. Select `KeybindingUI` in `Scenes/UI/Menu/setting_screen.tscn` and edit its authored `action_allowlist` and `label_map` for your game's controls.
5. Instance `Scenes/UI/Gameplay/gameplay_ui_shell.tscn` once under the gameplay scene root.
6. Run the menu and verify Start, Settings, Credits, keyboard/gamepad focus, and Pause before adding gameplay.

The template intentionally has no gameplay scene. Start stays disabled until `start_scene_path` points to a valid packed scene.

## Copy Checklist

After copying the template into a new game:

1. Change `application/config/name`, icons, boot splash, and export metadata.
2. Set `Menu.start_scene_path` to a real gameplay `PackedScene`.
3. Decide whether the copied project needs the bundled `Dialogue/Examples/demo` content and `addons/limboai`; delete them when they are not used.
4. Keep the five core editor plugins enabled: Dialogue Manager, Enhanced Save System, Richer Text Label, SceneManager, and SoundManager.
5. Leave Phantom Camera, Simple GUI Transitions, and Project Time Tracker disabled unless the game explicitly adopts them. Re-enable their autoloads only together with their project code.
6. Run `pwsh ./tools/verify_template.ps1 -ReleaseReadiness -GodotPath <Godot-4.7-console>` before making a release build.

The readiness command intentionally fails while the project still has the template name or an empty `Menu.start_scene_path`.

## Editor Preview

The menu entry check, `ShaderButton`, and the settings light effect are `@tool` scripts. They preview as soon as their Inspector values change; no editor plugin needs to be enabled.

- On a `ShaderButton`, edit `BBcode > Bb Text`, `Panel Style Box`, or `Outline Color` to update the visible label, panel, and shader outline in the editor.
- On the root `Menu`, change `start_scene_path` to update the Start button and its validation message immediately.
- In settings, credits, or pause scenes, change `SettingLocalLightVFX.intensity` to preview the moving lights directly in the 2D viewport.

Audio, save data, input, transitions, and button presses remain runtime-only so editor previews cannot mutate game state.

## Included Systems

- Main menu: `Scenes/UI/Menu/menu.tscn`
- Settings and key rebinding: `Scenes/UI/Menu/setting_screen.tscn`
- Credits: `Scenes/UI/Menu/thank_screen.tscn`
- Pause UI: `Scenes/UI/PauseScreen/pause_screen.tscn`
- Gameplay UI shell: `Scenes/UI/Gameplay/gameplay_ui_shell.tscn`
- UI components: `ShaderButton`, `ButtonEffectModule`, and `floating_text`
- Audio router: `Scenes/Autoload/game_audio.gd`
- Feedback overlay: `Scenes/UI/Common/feedback_overlay.tscn`
- Scene transitions: `resources/scene_transitions/`
- Dialogue runtime and project save modules: `Dialogue/Runtime/`, `Dialogue/Examples/`, `Scripts/Save/`, and `Config/save_modules.cfg`

Third-party plugins remain under `addons/`. Bundled upstream license files remain authoritative; the project-owned Enhanced Save System is covered by the root MIT license.

## Plugin Matrix

| Plugin | Version | Default | Purpose | Upgrade source |
| --- | --- | --- | --- | --- |
| Dialogue Manager | 4.0.2 | Enabled | Dialogue resources, runtime parsing, balloon integration | [v4.0.2](https://github.com/nathanhoad/godot_dialogue_manager/releases/tag/v4.0.2) |
| Enhanced Save System | 2.0.0 | Enabled | Slot/global modules, settings, input persistence | Bundled project version |
| Richer Text Label | 1.14 | Enabled | Rich text effects and project font picker | [v1.14](https://github.com/chairfull/GodotRichTextLabel2/releases/tag/v1.14) |
| SceneManager | 2.0 | Enabled | Scene changes, fades, modal transitions | [Upstream](https://github.com/m-canton/godot-scene-manager) |
| SoundManager | 2.6.2 | Enabled | Pooled SFX/UI/ambient/music backend | [v2.6.2](https://github.com/nathanhoad/godot_sound_manager/releases/tag/v2.6.2) |
| LimboAI | 1.8.0 | Loaded GDExtension | Behavior trees, HSM, debugger, tutorial demo | [v1.8.0](https://github.com/limbonaut/limboai/releases/tag/v1.8.0) |
| Phantom Camera | 0.11.0.1 | Disabled | Optional 2D/3D camera rigs | [Upstream](https://github.com/ramokz/phantom-camera) |
| Simple GUI Transitions | 0.4.3 | Disabled | Optional standalone GUI transitions | [v0.4.3](https://github.com/murikistudio/simple-gui-transitions/releases/tag/v0.4.3) |
| Project Time Tracker | 2.0.8 | Disabled | Optional editor time statistics in `user://` | Bundled plugin folder |

LimboAI does not use an editor-plugin toggle here; Godot loads its GDExtension when the project opens. If a copied game does not need AI, delete both `addons/limboai` and `demo`.

### Demo Entrypoints

- Dialogue basics: `Dialogue/Examples/demo/demo_scene.tscn`
- Dialogue modules and history: `Dialogue/Examples/demo/enhanced_demo.tscn`
- Dialogue illustrations: `Dialogue/Examples/demo/illustration_test_scene.tscn`
- LimboAI showcase and tutorial button: `demo/scenes/showcase.tscn`
- LimboAI playable scene: `demo/scenes/game.tscn`

Dialogue Manager 4 uses **cues** where version 3 used titles. Response conditions are self-closing (`[if condition /]`), `DialogueLine.translation_key` is now `static_id`, and `DialogueResource.raw_text` was removed. The project runtime and narrative snapshot API use cue terminology.

SoundManager 2.6.2 separates UI volume from gameplay SFX and fixes `get_currently_playing_music_tracks()`. The template keeps its project-specific ambient target-volume, autoload, authored bus, and player-pool patches.

## Reskin Checklist

- Replace project-wide colors, fonts, and control styles in `resources/main_theme.tres` and `resources/settings_theme.tres`.
- Choose the global UI font in `assets/fonts/ui_font.tres`: keep `ui_hd_font.tres` for normal games or set its base font to `ui_pixel_font.tres` for pixel games. Pixel layouts should use 10 px font-size multiples and integer viewport scaling.
- Restyle `ShaderButton` through its scene, material, and external shader together; its hover and focus outline is shared by mouse, keyboard, and gamepad navigation.
- Edit the authored menu, settings, credits, and pause scenes for layout or copy changes. Keep their named nodes and script contracts intact.
- Assign menu music to `Menu.menu_music`, assign UI streams directly on `ShaderButton`/`ButtonEffectModule` Inspector fields, and keep the existing `Master`, `SFX`, `Music`, `Ambient`, and `UI` buses.
- Replace the fade resources in `resources/scene_transitions/` if the game needs a different scene-change style.
- Change `config/name`, icons, boot splash, and export metadata before publishing.

## Settings And Platform Behavior

Display, volume, accessibility, and input settings apply immediately. `SettingsModule` persists global settings, while Enhanced Save System serializes input bindings.

The authored viewport is `1920×1080` with `Stretch Aspect = Keep`. Desktop window presets are limited to `1280×720`, `1600×900`, and `1920×1080`.

| Behavior | Windows | Web |
| --- | --- | --- |
| Exit command | Shown | Hidden |
| Resolution selector | Shown and persisted | Hidden |
| VSync | Shown and persisted | Hidden |
| Fullscreen | Native setting, persisted | Browser button, only changed by a user click and not persisted |

The Web restrictions are intentional: browser fullscreen requires user activation, and browser/window ownership makes desktop resolution and VSync controls misleading.

The default keybinding list contains `left`, `right`, `up`, `down`, `attack`, `sprint`, and `pause`. The reset command on the keybinding page changes bindings only; the general reset command changes display, sound, and accessibility settings only.

## Audio, Feedback, And Transitions

Play menu music through the authored property or the audio router:

```gdscript
GameAudio.play_music("menu", your_stream)
```

Project code calls `GameAudio` only. `SoundManager` remains the pooled backend. The facade API is:

```gdscript
GameAudio.play_music(track_key, stream, 0.6)
GameAudio.stop_music(0.3)
GameAudio.play_sfx(stream, -6.0, 1.0)
GameAudio.play_ui(stream, -12.0, 1.0)
GameAudio.play_ambient(stream, 0.5, -8.0)
GameAudio.stop_ambient(stream, 0.3)
GameAudio.refresh_runtime_volumes()
```

`track_key` is semantic: calling the same key while it is playing does not restart music. `SettingsModule` emits setting changes, `GameAudio` reads them, and only `GameAudio` writes runtime audio bus volumes. Empty streams are silent. UI sounds belong to the authored control, so a copied game can replace them without editing a singleton.

## Dialogue And Save API

The reusable balloon and all runtime modules live under `Dialogue/Runtime/`. `Dialogue/Examples/` contains only demos, dialogue text, and the demo save-slot UI. The formal save modules are registered in `Config/save_modules.cfg`:

`DialogueManager.show_dialogue_balloon()` is configured to instantiate `Dialogue/Runtime/modular_balloon.tscn`; use the demo scenes when you want a working reference UI.

```gdscript
var slot_narrative = SaveSystem.get_module("narrative_slot")
slot_narrative.record_dialogue_progress(
    dialogue_resource,
    current_line.id,
    start_title,
    "Chapter 1",
    current_line.character,
    current_line.text,
)
SaveSystem.save_slot()
```

`NarrativeSlotModule` stores the resource path, exact line id, starting cue, chapter, character, and a plain-text snippet. Use `has_dialogue_progress()`, `load_dialogue_resource()`, and `clear_dialogue_progress()` for resume UI. `NarrativeGlobalModule` is limited to cross-slot `flags`, `values`, and `events`.

`ModularBalloon.track_dialogue_progress` (and the matching `SaveModule` property) updates the slot snapshot in memory on each line. It never writes a file. Use explicit `SaveSystem.save_slot()` or the project's periodic autosave policy for persistence.

Use the global feedback overlay for short notices and confirmations:

```gdscript
FeedbackOverlay.toast(2.0, "Saved", "Progress written to disk.")

if await FeedbackOverlay.ask("Quit", "Leave the current run?", "Quit", "Cancel"):
	get_tree().quit()
```

Use the bundled SceneManager fade resources for scene changes:

```gdscript
const EXIT_FADE := preload("res://resources/scene_transitions/stage_exit_fade_to_black.tres")

func leave_scene() -> void:
	var tween := SceneManager.transition_start(EXIT_FADE)
	if tween:
		await tween.finished
	SceneManager.change_scene_to_file("res://Scenes/Game/game.tscn")
```

## Gameplay Pause Shell

`GameplayUiShell` owns the complete gameplay pause route: `Esc`, Continue, Settings, Settings return, and confirmed return to the title menu. Settings never changes `SceneTree.paused` by itself; the shell keeps gameplay paused until Continue or a successful scene change.

Instance the authored shell instead of duplicating pause scripts in each level. Change its `menu_scene_path` only when the project uses a different title scene. The public methods are `pause_game()`, `resume_game()`, `open_settings()`, and `quit_to_menu()`.

Run the complete local verification with one command:

```powershell
pwsh ./tools/verify_template.ps1
```

Before tagging this template repository, include bundled demo smoke tests and template-specific release checks:

```powershell
pwsh ./tools/verify_template.ps1 -TemplateRelease
```

If `godot` is not on `PATH`, pass the Godot 4.7 console executable explicitly:

```powershell
pwsh ./tools/verify_template.ps1 -GodotPath C:/Tools/Godot_v4.7-stable_win64_console.exe
```

Add `-ReleaseReadiness` after copying the template into a real game. It rejects the default project name, a missing gameplay entry, and `res://.godot/` references while keeping LimboAI/demo/Time Tracker reminders non-blocking.

## Export

Install the official Godot 4.7 export templates first. Web export must use the standard non-.NET Godot 4.7 editor; Godot's Mono/.NET editor cannot export Web projects. The Web preset uses the no-threads variant with GDExtension support enabled so the bundled LimboAI runtime can load:

```powershell
New-Item -ItemType Directory -Force build/web, build/windows | Out-Null
$godotStandard = "C:/Tools/Godot_v4.7-stable_win64_console.exe"
& $godotStandard --headless --path . --export-release "Web" "build/web/index.html"
& $godotStandard --headless --path . --export-release "Windows Desktop" "build/windows/GameJamTemplate.exe"
```

All presets keep `all_resources` for dynamic `preload()`, autoload, and `class_name` dependencies, while excluding addon editor UI, Dialogue Manager's C#-only scene, and bundled examples that are not needed at runtime.

### Optional Smaller Windows Export

Most of the default Windows package is Godot's general-purpose runtime rather than project data. The `Windows Desktop Small` preset uses a locally compiled Godot 4.7 release template with `size_extra`, full LTO, GL Compatibility only, and unused networking/video modules disabled. It does not use ZIP, UPX, or another post-build compressor, and it keeps 2D/3D nodes, Advanced GUI, advanced text shaping, Brotli/WOFF2 fonts, Jolt, `RegEx`, noise, and `mbedtls` for the bundled systems.

Install SCons and Visual Studio Build Tools with the C++ workload, check out the exact `4.7-stable` Godot source, then run:

```powershell
pwsh ./tools/build_small_windows_template.ps1 -GodotSource C:/src/godot-4.7-stable
godot --headless --path . --export-release "Windows Desktop Small" "build/windows-small/GameJamTemplate.exe"
```

The script writes `custom_templates/windows_release.exe`, which is intentionally ignored by Git. The preset embeds the PCK into one executable. Keep using the standard Windows preset when a game needs Vulkan, D3D12, XR, multiplayer, WebRTC/WebSocket, UPnP, Theora video, or another module disabled in `build_profiles/windows_small.gdbuild`. Treat the profile as hand-authored JSON; resaving it through Godot's build-profile editor can drop module keys that the editor UI does not expose.

See Godot's [optimizing for size](https://docs.godotengine.org/en/4.7/engine_details/development/compiling/optimizing_for_size.html) guide for the engine-level tradeoffs.

Replace `godot` with the local Godot 4.7 executable name when it is not on `PATH`. Serve the Web build over HTTP rather than opening `index.html` directly:

```powershell
python -m http.server 8000 --directory build/web
```

Then open `http://127.0.0.1:8000/`.

## Local Addon Patches

This template deliberately patches four bundled addons:

- **Enhanced Save System 2.0.0:** complete keyboard, mouse, and joypad event serialization; legacy wildcard-device fallback; stable in-place rebinding; and exact, device-aware conflict detection.
- **SceneManager 2.0:** modal backdrops close from their current open progress, so closing during the opening animation neither jumps to fully open nor uses the wrong duration.
- **Dialogue Manager 4.0.2:** fresh headless imports fall back to Godot's default code font size until `EditorSettings` creates its persisted key.
- **SoundManager 2.6.2:** existing autoloads are preserved; ambient playback keeps authored bus detection and per-stream target volume; pooled players safely prune invalid references.

Replacing any patched addon directory during an upgrade will remove these changes. Reapply the behavior or port the changes before accepting an upstream replacement. Project-owned dialogue and save modules remain outside the addon directories.

## License

The root MIT license covers project-owned template files. Third-party addon licenses continue to apply to their respective directories.
