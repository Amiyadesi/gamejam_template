extends Node
## Template-wide audio router for music, UI sounds, and runtime bus volume.

const DEFAULT_BUS_LAYOUT: AudioBusLayout = preload("res://default_bus_layout.tres")
const SILENCE_DB := -80.0

var _current_music_key: StringName
var _current_music_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	AudioServer.set_bus_layout(DEFAULT_BUS_LAYOUT)
	_apply_sound_manager_buses()
	refresh_runtime_volumes()


# Starts one semantic music track through SoundManager.
func play_music(
		track_key: StringName,
		stream: AudioStream,
		crossfade_duration := 0.6) -> AudioStreamPlayer:
	if stream == null:
		return null
	if (
		_current_music_key == track_key
		and is_instance_valid(_current_music_player)
	):
		return _current_music_player

	_current_music_key = track_key
	_current_music_player = SoundManager.play_music(stream, maxf(crossfade_duration, 0.0), "Music")
	if is_instance_valid(_current_music_player):
		var finished_callback := _on_music_finished.bind(_current_music_player)
		if not _current_music_player.finished.is_connected(finished_callback):
			_current_music_player.finished.connect(finished_callback, CONNECT_ONE_SHOT)
	return _current_music_player


# Stops the active music and clears semantic deduplication state.
func stop_music(fade_out_duration := 0.3) -> void:
	SoundManager.stop_music(maxf(fade_out_duration, 0.0))
	_current_music_key = &""
	_current_music_player = null


# Plays a one-shot gameplay sound through the SFX pool.
func play_sfx(
		stream: AudioStream,
		volume_db := 0.0,
		pitch_scale := 1.0) -> AudioStreamPlayer:
	return _configure_player(SoundManager.play_sound(stream, "SFX") if stream != null else null, volume_db, pitch_scale)


# Plays a one-shot interface sound through the UI pool.
func play_ui(
		stream: AudioStream,
		volume_db := 0.0,
		pitch_scale := 1.0) -> AudioStreamPlayer:
	return _configure_player(SoundManager.play_ui_sound(stream, "UI") if stream != null else null, volume_db, pitch_scale)


# Plays or reuses ambience with backend-owned fading.
func play_ambient(
		stream: AudioStream,
		fade_in_duration := 0.0,
		volume_db := 0.0) -> AudioStreamPlayer:
	if stream == null:
		return null
	return SoundManager.play_ambient_sound(
		stream,
		maxf(fade_in_duration, 0.0),
		"Ambient",
		volume_db
	) as AudioStreamPlayer


# Stops one ambient stream through the backend pool.
func stop_ambient(stream: AudioStream, fade_out_duration := 0.0) -> void:
	if stream != null:
		SoundManager.stop_ambient_sound(stream, maxf(fade_out_duration, 0.0))


# Applies current settings to the authored runtime audio buses.
func refresh_runtime_volumes() -> void:
	_apply_sound_manager_buses()
	var master_volume := _get_setting("master_volume", 0.8)
	var music_volume := _get_setting("music_volume", 0.8)
	var sfx_volume := _get_setting("sfx_volume", 0.8)
	var ui_volume := _get_setting("ui_volume", 0.8)
	var ambient_volume := _get_setting("ambient_volume", 0.8)
	_set_bus_volume_linear("Master", master_volume)
	_set_bus_volume_linear("Music", music_volume)
	_set_bus_volume_linear("SFX", sfx_volume)
	_set_bus_volume_linear("UI", ui_volume)
	_set_bus_volume_linear("Ambient", ambient_volume)


# Applies per-play volume and pitch to a pooled one-shot player.
func _configure_player(
		player: AudioStreamPlayer,
		volume_db: float,
		pitch_scale: float) -> AudioStreamPlayer:
	if player == null:
		return null
	player.volume_db = volume_db
	player.pitch_scale = maxf(pitch_scale, 0.01)
	return player


# Releases semantic deduplication after the active track ends naturally.
func _on_music_finished(player: AudioStreamPlayer) -> void:
	if _current_music_player == player:
		_current_music_key = &""
		_current_music_player = null


# Keeps SoundManager's pools bound to the template bus layout.
func _apply_sound_manager_buses() -> void:
	SoundManager.set_default_sound_bus("SFX")
	SoundManager.set_default_ui_sound_bus("UI")
	SoundManager.set_default_ambient_sound_bus("Ambient")
	SoundManager.set_default_music_bus("Music")


# Reads one normalized volume setting from the registered save module.
func _get_setting(key: String, fallback: float) -> float:
	return float(SettingsModule.instance.get_value(key, fallback)) if SettingsModule.instance != null else fallback


# Writes one linear volume value to an authored audio bus.
func _set_bus_volume_linear(bus_name: String, linear_volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var clamped_volume := clampf(linear_volume, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, clamped_volume <= 0.001)
	AudioServer.set_bus_volume_db(bus_index, SILENCE_DB if clamped_volume <= 0.001 else linear_to_db(clamped_volume))
