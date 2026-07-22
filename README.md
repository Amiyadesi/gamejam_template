# Game Jam Template

Godot 4.7 GDScript-only starter for game jams. It provides a reusable menu, settings, credits, pause UI, input rebinding, save modules, audio routing, feedback overlays, and scene transitions without prescribing gameplay.

## Quick Start

1. Open the repository with Godot 4.7 and let imports finish.
2. Open `Scenes/UI/Menu/menu.tscn`.
3. Select the root `Menu` and set `start_scene_path` to the first gameplay scene.
4. Select `KeybindingUI` in `Scenes/UI/Menu/setting_screen.tscn` and edit its authored `action_allowlist` and `label_map` for your game's controls.
5. Run the menu and verify Start, Settings, Credits, keyboard/gamepad focus, and Pause before adding gameplay.

The template intentionally has no gameplay scene. Start stays disabled until `start_scene_path` points to a valid packed scene.

## Included Systems

- Main menu: `Scenes/UI/Menu/menu.tscn`
- Settings and key rebinding: `Scenes/UI/Menu/setting_screen.tscn`
- Credits: `Scenes/UI/Menu/thank_screen.tscn`
- Pause UI: `Scenes/UI/PauseScreen/pause_screen.tscn`
- UI components: `ShaderButton`, `ButtonEffectModule`, and `floating_text`
- Audio router: `Scenes/Autoload/game_audio.gd`
- Feedback overlay: `Scenes/UI/Common/feedback_overlay.tscn`
- Scene transitions: `resources/scene_transitions/`
- Dialogue and project save modules: `Dialogue/`, `Scripts/Save/`, and `Config/save_modules.cfg`

Third-party plugins remain under `addons/`. Each plugin keeps its own license.

## Reskin Checklist

- Replace project-wide colors, fonts, and control styles in `resources/main_theme.tres` and `resources/settings_theme.tres`.
- Choose the global UI font in `assets/fonts/ui_font.tres`: keep `ui_hd_font.tres` for normal games or set its base font to `ui_pixel_font.tres` for pixel games. Pixel layouts should use 10 px font-size multiples and integer viewport scaling.
- Restyle `ShaderButton` through its scene, material, and external shader together; its hover and focus outline is shared by mouse, keyboard, and gamepad navigation.
- Edit the authored menu, settings, credits, and pause scenes for layout or copy changes. Keep their named nodes and script contracts intact.
- Assign menu music to `Menu.menu_music`, replace the UI audio streams consumed by `GameAudio`, and keep the existing `Master`, `SFX`, `Music`, `Ambient`, and `UI` buses.
- Replace the fade resources in `resources/scene_transitions/` if the game needs a different scene-change style.
- Change `config/name`, icons, boot splash, and export metadata before publishing.

## Settings And Platform Behavior

Display, volume, accessibility, and input settings apply immediately. `SettingsModule` persists global settings, while Enhanced Save System serializes input bindings.

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

## Export

Install the official Godot 4.7 export templates first. Web export must use the standard non-.NET Godot 4.7 editor; Godot's Mono/.NET editor cannot export Web projects. The committed presets target Web without threads or extension support and Windows Desktop:

```powershell
New-Item -ItemType Directory -Force build/web, build/windows | Out-Null
$godotStandard = "C:/Tools/Godot_v4.7-stable_win64_console.exe"
& $godotStandard --headless --path . --export-release "Web" "build/web/index.html"
& $godotStandard --headless --path . --export-release "Windows Desktop" "build/windows/GameJamTemplate.exe"
```

All presets keep `all_resources` for dynamic `preload()`, autoload, and `class_name` dependencies, while excluding addon editor UI and bundled examples that are not needed at runtime.

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

This template deliberately patches two bundled addons:

- **Enhanced Save System 2.0.0:** complete keyboard, mouse, and joypad event serialization; legacy wildcard-device fallback; stable in-place rebinding; and exact, device-aware conflict detection.
- **SceneManager 2.0:** modal backdrops close from their current open progress, so closing during the opening animation neither jumps to fully open nor uses the wrong duration.

Replacing either addon directory during an upgrade will remove these patches. Reapply the behavior or port the changes before accepting an upstream replacement. Project-owned dialogue and save modules remain outside the addon directories.

## License

The root MIT license covers project-owned template files. Third-party addon licenses continue to apply to their respective directories.
