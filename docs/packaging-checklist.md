# Packaging checklist

Public GitHub remains the sample. itch sells a dated zip of the same tree plus this checklist.

## Before zip

- [ ] Tag `v0.1.0-beta.2` or newer
- [ ] Confirm Echo sandbox opens from `Menu.start_scene_path` in a throwaway copy
- [ ] Confirm Esc pause, settings return, and slot save still work in that copy
- [ ] Export Web and Windows once; attach those builds only if they stay under itch size limits
- [ ] Screenshot: menu, settings/rebind, sandbox with ghost trace, pause
- [ ] `ATTRIBUTION.md` lists every bundled addon
- [ ] README still says copied games must rename the project

## Zip contents

Include source, `docs/`, `ATTRIBUTION.md`, `LICENSE`.
Exclude `.godot/`, `build/`, `custom_templates/`, local Godot editor settings.

Suggested name: `amiya-jam-shell-0.1.0-beta.2.zip`

## Page copy

Paste `docs/itch-listing.md`. Do not paste the full plugin matrix onto the storefront.

## Aftercare that is allowed

Fix a broken import or a wrong path. Do not take feature requests for other people's jam games.
