extends RefCounted

const SLOT_SCRIPT: Script = preload("res://Scripts/Save/Modules/narrative_slot_module.gd")
const GLOBAL_SCRIPT: Script = preload("res://Scripts/Save/Modules/narrative_global_module.gd")
const SAVE_MODULE_SCRIPT: Script = preload("res://Dialogue/Runtime/modules/save_module.gd")
const DIALOGUE_LINE_SCRIPT: Script = preload("res://addons/dialogue_manager/dialogue_line.gd")
const DIALOGUE_RESOURCE: DialogueResource = preload("res://Dialogue/Examples/demo/demo_dialogue.dialogue")
const BALLOON_SCENE: PackedScene = preload("res://Dialogue/Runtime/modular_balloon.tscn")


# Runs the exact dialogue snapshot and memory-only tracking regressions.
func run(context, tree: SceneTree) -> void:
	_expect_runtime_balloon_is_configured(context)
	_expect_dialogue_cache_handles_first_import(context)
	await _expect_balloon_processing_follows_dialogue(context, tree)
	_expect_slot_snapshot_round_trip(context)
	_expect_global_scope_only_keeps_flags_values_events(context)
	await _expect_line_tracking_does_not_write_disk(context, tree)


# Keeps Dialogue Manager's default runtime balloon on the formal template path.
func _expect_runtime_balloon_is_configured(context) -> void:
	var balloon_path := str(ProjectSettings.get_setting("dialogue_manager/runtime/balloon_path", ""))
	context.expect_equal(
		balloon_path,
		"res://Dialogue/Runtime/modular_balloon.tscn",
		"Dialogue Manager should use the formal ModularBalloon runtime"
	)
	context.expect_true(
		ResourceLoader.exists(balloon_path),
		"the configured runtime balloon scene should exist"
	)


# Keeps clean-project imports safe before the editor plugin creates its timer.
func _expect_dialogue_cache_handles_first_import(context) -> void:
	DMCache.add_file(DIALOGUE_RESOURCE.resource_path)
	DMCache._on_dependency_timer_timeout()
	context.expect_true(DMCache.has_file(DIALOGUE_RESOURCE.resource_path), "Dialogue cache should accept imports before its editor timer exists")


# Keeps the balloon idle between conversations and active while dialogue is running.
func _expect_balloon_processing_follows_dialogue(context, tree: SceneTree) -> void:
	var balloon := BALLOON_SCENE.instantiate() as ModularBalloon
	tree.root.add_child(balloon)
	await tree.process_frame
	context.expect_true(not balloon.is_processing(), "ModularBalloon should not process while idle")
	balloon.start(DIALOGUE_RESOURCE, "start")
	await tree.process_frame
	context.expect_true(balloon.is_processing(), "ModularBalloon should process during dialogue")
	balloon.force_end()
	await tree.process_frame
	context.expect_true(not balloon.is_processing(), "ModularBalloon should stop processing after dialogue")
	balloon.queue_free()
	await tree.process_frame


# Verifies exact line restoration, plain-text summaries, and clear behavior.
func _expect_slot_snapshot_round_trip(context) -> void:
	var module = SLOT_SCRIPT.new()
	module.record_dialogue_progress(
		DIALOGUE_RESOURCE,
		"line_42",
		"chapter_start",
		"第一章",
		"Alice",
		"[b]Hello[/b] [color=gold]world[/color]"
	)
	var snapshot: Dictionary = module.collect_data()
	context.expect_equal(snapshot["dialogue_resource_path"], DIALOGUE_RESOURCE.resource_path, "dialogue snapshot should retain resource path")
	context.expect_equal(snapshot["dialogue_line_id"], "line_42", "dialogue snapshot should retain the exact line id")
	context.expect_equal(snapshot.get("dialogue_cue", ""), "chapter_start", "dialogue snapshot should retain the starting cue")
	context.expect_true(not snapshot.has("dialogue_title"), "DM4 snapshots should not keep the legacy title key")
	context.expect_equal(snapshot["chapter_name"], "第一章", "dialogue snapshot should retain chapter label")
	context.expect_equal(snapshot["character_name"], "Alice", "dialogue snapshot should retain character label")
	context.expect_equal(snapshot["dialogue_snippet"], "Hello world", "dialogue snapshot should store plain text only")
	context.expect_true(module.has_dialogue_progress(), "a complete dialogue snapshot should be resumable")
	context.expect_equal(module.load_dialogue_resource(), DIALOGUE_RESOURCE, "dialogue snapshot should load its resource")

	var restored = SLOT_SCRIPT.new()
	restored.apply_data(snapshot)
	context.expect_equal(restored.collect_data(), snapshot, "dialogue snapshot should survive collect/apply")
	restored.clear_dialogue_progress()
	context.expect_true(not restored.has_dialogue_progress(), "clearing dialogue progress should remove the exact resume point")
	context.expect_equal(restored.collect_data()["dialogue_line_id"], "", "clearing dialogue progress should clear the line id")


# Keeps the global module limited to cross-slot flags, values, and events.
func _expect_global_scope_only_keeps_flags_values_events(context) -> void:
	var module = GLOBAL_SCRIPT.new()
	module.set_value("flags.met_alice", true)
	module.set_value("ending", "quiet")
	module.set_value("events.intro_seen", true)
	var snapshot: Dictionary = module.collect_data()
	context.expect_equal(snapshot.keys().size(), 3, "global narrative data should contain only three scopes")
	context.expect_true(snapshot.has("flags"), "global narrative data should expose flags")
	context.expect_true(snapshot.has("values"), "global narrative data should expose values")
	context.expect_true(snapshot.has("events"), "global narrative data should expose events")
	context.expect_true(not snapshot.has("dialogue_resource_path"), "global narrative data should not contain slot dialogue snapshots")

	var restored = GLOBAL_SCRIPT.new()
	restored.apply_data(snapshot)
	context.expect_equal(restored.get_value("flags.met_alice"), true, "global flags should survive collect/apply")
	context.expect_equal(restored.get_value("ending"), "quiet", "global values should survive collect/apply")
	context.expect_equal(restored.get_value("events.intro_seen"), true, "global events should survive collect/apply")
	restored.clear_value("flags.met_alice")
	context.expect_equal(restored.get_value("flags.met_alice", null), null, "global flags should clear independently")


# Confirms per-line tracking updates the registered module without saving a slot.
func _expect_line_tracking_does_not_write_disk(context, tree: SceneTree) -> void:
	var save_system := tree.root.get_node("SaveSystem")
	var module = save_system.get_module("narrative_slot")
	context.expect_true(module != null, "NarrativeSlotModule should be registered by default")
	if module == null:
		return
	module.clear_dialogue_progress()
	var save_emitted := {"value": false}
	var on_saved := func(_slot: int, _ok: bool) -> void: save_emitted["value"] = true
	save_system.slot_saved.connect(on_saved)

	var tracker = SAVE_MODULE_SCRIPT.new()
	tree.root.add_child(tracker)
	await tree.process_frame
	tracker.track_dialogue_progress = true
	tracker.chapter_name = "Tracked Chapter"
	tracker.on_dialogue_started(DIALOGUE_RESOURCE, "start")
	var line = DIALOGUE_LINE_SCRIPT.new()
	line.id = "tracked_line"
	line.character = "Bob"
	line.text = "[b]Tracked[/b] line"
	tracker.on_dialogue_line_changed(line)
	await tree.process_frame

	context.expect_equal(module.dialogue_line_id, "tracked_line", "line tracking should update the registered module in memory")
	context.expect_equal(module.dialogue_snippet, "Tracked line", "line tracking should normalize the snippet")
	context.expect_true(not bool(save_emitted["value"]), "line tracking should not trigger slot persistence")
	save_system.slot_saved.disconnect(on_saved)
	tracker.queue_free()
	await tree.process_frame
