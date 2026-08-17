extends RefCounted

const FIRST_STREAM: AudioStream = preload("res://assets/sfx/ui/confirm_ingame/Fantasy_UI (4).wav")
const SECOND_STREAM: AudioStream = preload("res://assets/sfx/ui/cancel/Fantasy_UI (27).wav")
const THIRD_STREAM: AudioStream = preload("res://assets/sfx/ui/confirm_menu/Fantasy_UI (5).wav")
const SHADER_BUTTON_SCENE: PackedScene = preload("res://Scenes/UIorgan/ShaderButton/shader_button.tscn")
const SETTINGS_SCENE: PackedScene = preload("res://Scenes/UI/Menu/setting_screen.tscn")


# Runs the public audio facade and authored component regressions.
func run(context, tree: SceneTree) -> void:
	await _expect_music_keys_deduplicate_semantic_tracks(context, tree)
	await _expect_crossfade_and_audio_buses(context, tree)
	await _expect_ambient_target_volume(context, tree)
	await _expect_authored_buttons_play_once(context, tree)
	_expect_empty_streams_are_silent(context)


# Keeps one semantic music track active even if a caller supplies another stream.
func _expect_music_keys_deduplicate_semantic_tracks(context, tree: SceneTree) -> void:
	var game_audio := tree.root.get_node("GameAudio")
	game_audio.call("stop_music", 0.0)
	await tree.create_timer(0.03).timeout
	var first_player := game_audio.call("play_music", &"test_track", FIRST_STREAM, 0.0) as AudioStreamPlayer
	var duplicate_player := game_audio.call("play_music", &"test_track", SECOND_STREAM, 0.0) as AudioStreamPlayer
	context.expect_equal(duplicate_player, first_player, "the same track key should not start music twice in one frame")
	context.expect_equal(first_player.stream, FIRST_STREAM, "track-key deduplication should keep the active semantic track")
	game_audio.call("stop_music", 0.0)
	await tree.process_frame


# Exposes SoundManager's fade and authored bus behavior through GameAudio.
func _expect_crossfade_and_audio_buses(context, tree: SceneTree) -> void:
	var game_audio := tree.root.get_node("GameAudio")
	var music_player := game_audio.call("play_music", &"fade_test", THIRD_STREAM, 0.1) as AudioStreamPlayer
	context.expect_equal(music_player.bus, &"Music", "music should use the Music bus")
	context.expect_true(music_player.volume_db < -70.0, "crossfade should begin from silence")
	await tree.create_timer(0.14).timeout
	context.expect_near(music_player.volume_db, 0.0, 0.5, "SoundManager should finish the delegated music fade")

	var sfx_player := game_audio.call("play_sfx", SECOND_STREAM, -7.0, 1.2) as AudioStreamPlayer
	var ui_player := game_audio.call("play_ui", FIRST_STREAM, -9.0, 0.9) as AudioStreamPlayer
	context.expect_equal(sfx_player.bus, &"SFX", "sound effects should use the SFX bus")
	context.expect_near(sfx_player.volume_db, -7.0, 0.01, "sound effects should keep authored volume")
	context.expect_near(sfx_player.pitch_scale, 1.2, 0.01, "sound effects should keep authored pitch")
	context.expect_equal(ui_player.bus, &"UI", "interface sounds should use the UI bus")
	context.expect_near(ui_player.volume_db, -9.0, 0.01, "interface sounds should keep authored volume")
	context.expect_near(ui_player.pitch_scale, 0.9, 0.01, "interface sounds should keep authored pitch")
	game_audio.call("stop_music", 0.0)
	await tree.process_frame


# Keeps ambient fades on the authored bus and local target volume.
func _expect_ambient_target_volume(context, tree: SceneTree) -> void:
	var game_audio := tree.root.get_node("GameAudio")
	var player := game_audio.call("play_ambient", THIRD_STREAM, 0.1, -6.0) as AudioStreamPlayer
	context.expect_equal(player.bus, &"Ambient", "ambience should use the Ambient bus")
	context.expect_true(player.volume_db < -70.0, "ambient fades should begin from silence")
	await tree.create_timer(0.14).timeout
	context.expect_near(player.volume_db, -6.0, 0.5, "ambient fades should finish at the authored target volume")

	var reused := game_audio.call("play_ambient", THIRD_STREAM, 0.1, -3.0) as AudioStreamPlayer
	context.expect_equal(reused, player, "replaying one ambient stream should reuse its pooled player")
	await tree.create_timer(0.14).timeout
	context.expect_near(player.volume_db, -3.0, 0.5, "reused ambience should retarget its active fade")
	game_audio.call("stop_ambient", THIRD_STREAM, 0.0)
	await tree.process_frame


# Confirms ShaderButton owns its stream and its effect module does not double-play it.
func _expect_authored_buttons_play_once(context, tree: SceneTree) -> void:
	var button := SHADER_BUTTON_SCENE.instantiate() as ShaderButton
	tree.root.add_child(button)
	await tree.process_frame
	var before_count := _count_busy_ui_players(tree, FIRST_STREAM)
	button.pressed.emit()
	await tree.process_frame
	context.expect_equal(
		_count_busy_ui_players(tree, FIRST_STREAM),
		before_count + 1,
		"ShaderButton and ButtonEffectModule should produce one UI sound per press"
	)
	context.expect_true(button.get_node_or_null("PressAudio") == null, "ShaderButton should not keep a PressAudio child")
	context.expect_true(button.get_node_or_null("SelectAudio") == null, "ShaderButton should not keep a SelectAudio child")
	button.queue_free()

	var settings := SETTINGS_SCENE.instantiate()
	context.expect_true(settings.get_node("%DisplayModeOption/ButtonEffectModule").get("press_sound") != null, "settings option should author its press stream")
	context.expect_true(settings.get_node("%VSyncToggle/ButtonEffectModule").get("press_sound") != null, "settings toggle should author its press stream")
	settings.free()
	await tree.process_frame


# Treats missing optional streams as a no-op at the facade boundary.
func _expect_empty_streams_are_silent(context) -> void:
	var main_loop := Engine.get_main_loop() as SceneTree
	var game_audio := main_loop.root.get_node("GameAudio")
	context.expect_true(game_audio.call("play_music", &"empty", null) == null, "empty music should be silent")
	context.expect_true(game_audio.call("play_sfx", null) == null, "empty sound effects should be silent")
	context.expect_true(game_audio.call("play_ui", null) == null, "empty interface sounds should be silent")
	context.expect_true(game_audio.call("play_ambient", null) == null, "empty ambience should be silent")


# Counts active UI players for one authored stream.
func _count_busy_ui_players(tree: SceneTree, stream: AudioStream) -> int:
	var count := 0
	var sound_manager := tree.root.get_node("SoundManager")
	var ui_sound_effects: Node = sound_manager.get("ui_sound_effects")
	var busy_players: Array = ui_sound_effects.get("busy_players")
	for player in busy_players:
		if player.stream == stream:
			count += 1
	return count
