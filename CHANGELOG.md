# Changelog

## 0.1.0-beta.2 - 2026-08-17

### Changed

- Upgraded Dialogue Manager from 3.10.4 to 4.0.2 and migrated project-owned dialogue progress terminology from titles to cues.
- Upgraded SoundManager from 2.6.1 to 2.6.2 while retaining the template's ambient, autoload, authored bus, and pooled-player compatibility patches.
- Updated Dialogue Manager import metadata from importer version 15 to 18.

### Added

- Ambient audio regressions for target volume, authored bus selection, pooled-player reuse, and fade retargeting.

### Fixed

- Fresh headless editor imports now give Dialogue Manager 4 a default code font size until `EditorSettings` initializes the persisted value.
- SoundManager's currently-playing music-track query now calls the correct backend method.

## 0.1.0-beta.1 - 2026-08-17

### Added

- Reusable menu, settings, credits, pause shell, input rebinding, save modules, audio facade, feedback overlay, and scene transitions.
- Formal modular dialogue runtime with exact in-memory dialogue snapshots and three example scenes.
- LimboAI 1.8.0 GDExtension binaries plus showcase, tutorial agents, and playable demo.
- `tools/verify_template.ps1` modes for template release checks and copied-game release readiness.

### Changed

- Idle `ModularBalloon` instances stop processing between conversations.
- `ShaderButton` avoids unchanged per-frame alpha writes.
- LimboAI's in-game behavior-tree view refreshes at 10 Hz instead of every physics frame.

### Known Limitations

- The template intentionally has no gameplay entry until `Menu.start_scene_path` is authored.
- Dialogue Manager remains on patched 3.10.4 because 4.0.2 fails a clean Godot 4.7.1 editor parse.
- SoundManager remains on patched 2.6.1 because 2.6.2 changes ambient target-volume fade behavior.
- Bundled LimboAI multi-platform binaries increase clone size; copied games can remove `addons/limboai` and `demo` when unused.
