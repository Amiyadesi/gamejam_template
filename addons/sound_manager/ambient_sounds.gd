extends "./abstract_audio_player_pool.gd"


# Plays one ambient resource or retargets its active fade.
func play(resource: AudioStream, fade_in_duration: float, override_bus: String = "", volume_db: float = 0.0) -> AudioStreamPlayer:
	var player = get_busy_player_with_resource(resource)

	# If it's already playing then don't play it again
	if is_instance_valid(player):
		fade_volume(player, player.volume_db, volume_db, fade_in_duration)
		return player

	player = prepare(resource, override_bus)
	fade_volume(player, -80.0, volume_db, fade_in_duration)
	player.call_deferred("play")
	return player


func stop(resource: AudioStream, fade_out_duration: float = 0.0) -> void:
	if fade_out_duration <= 0.0:
			fade_out_duration = 0.01

	for player in busy_players:
		if player.stream == resource:
			fade_volume(player, player.volume_db, -80, fade_out_duration)


func stop_all(fade_out_duration: float = 0.0) -> void:
	if fade_out_duration <= 0.0:
			fade_out_duration = 0.01

	for player in busy_players:
		fade_volume(player, player.volume_db, -80, fade_out_duration)
