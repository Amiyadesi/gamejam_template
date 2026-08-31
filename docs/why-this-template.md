# Why this template

Most Godot jam templates sell a menu shell. Maaack, hatmix, and kylelynn already do that well. Do not compete with them on "has a pause screen".

This template is for jams where **the next run is allowed to know the last run**.

## Keep the basics

Table stakes, already in the project:

- Main menu, settings, credits, pause, start gating
- Keyboard and gamepad focus on template UI
- Volume, display, and accessibility settings that persist
- Input rebinding with device-aware defaults
- Scene fades and a toast/confirm overlay
- Web and Windows export presets
- A copy checklist so you do not ship the template name

If a jam only needs those, Maaack is enough and lighter.

## The actual difference

1. **Memory is a first-class system.** Slot + global modules cover settings, bindings, player, level, narrative progress, and stats. Stats can notice an unclean exit and how long the player has been away. That is the author's usual design territory, not a bolted-on `ConfigFile`.
2. **Dialogue progress is a snapshot, not a pile of flags.** The bundled balloon can remember resource, line id, cue, chapter, speaker, and a text snippet without writing a file on every line.
3. **Web is a real target, not an afterthought.** GL Compatibility is the default renderer. Resolution, VSync, fullscreen, and Quit behave differently on Web on purpose.
4. **Pinned and patched plugins.** Dialogue Manager, SoundManager, SceneManager, and the save addon carry local fixes. Upgrading means re-applying those fixes, which is documented instead of hidden.
5. **A verifier that refuses a sloppy ship.** `tools/verify_template.ps1 -ReleaseReadiness` fails on the default project name, a missing gameplay entry, and leftover `.godot` references.

## What this is not

- Not a character-controller pack. The sandbox is a square you can delete.
- Not a promise to track every Godot minor release.
- Not lighter than Maaack. LimboAI binaries make the clone large; delete `addons/limboai` and `demo` when unused.
- Not a support product. The itch page should say there is no integration help.

## When to tell people to use something else

- They want GitHub Actions that upload to itch on every tag: hatmix.
- They want a huge options suite and Asset Library install: Maaack.
- They want example platformer / top-down controllers: kylelynn.
- They want the smallest possible title+pause overlay: ShaolinDave.
