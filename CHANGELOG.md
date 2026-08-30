# Changelog

## Unreleased - 2026-08-31

### Added

- Deletable Echo sandbox under `Scenes/Examples/` that plants a saved trace and reloads the last position.
- Packaging notes: `docs/why-this-template.md`, `docs/itch-listing.md`, `docs/packaging-checklist.md`, and `ATTRIBUTION.md`.

### Changed

- README now states the memory-first pitch and points at the sandbox without making it the default start scene.

## Unreleased - 2026-08-21

### Changed

- Upgraded Dialogue Manager from 4.0.2 to 4.0.3 for Godot 4.7, retaining the headless editor font fallback.
- Versioned keybinding saves now preserve new project-default device families when loading legacy binding data; movement and attack ship with wildcard `device=-1` gamepad defaults.
- Template verification now performs static release checks plus editor parse only; scene smoke and regression invocations were removed.

### Fixed

- Godot verification now captures the child process exit code directly instead of relying on PowerShell's shared `$LASTEXITCODE`.

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
- Bundled LimboAI multi-platform binaries increase clone size; copied games can remove `addons/limboai` and `demo` when unused.
