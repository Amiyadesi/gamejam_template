extends Node2D
## Deletable example. Shows pause, save, and "the last run still exists".
## Point Menu.start_scene_path here only while evaluating the template.

const SANDBOX_SCENE := "res://Scenes/Examples/echo_sandbox.tscn"

@onready var actor: CharacterBody2D = %Actor
@onready var ghost: Node2D = %Ghost
@onready var status: Label = %Status

var _speed := 280.0


func _ready() -> void:
	var player := PlayerModule.instance
	if player != null and player.scene_path == SANDBOX_SCENE:
		actor.global_position = player.position
		ghost.global_position = player.position
		ghost.visible = true
	else:
		ghost.visible = false
	_refresh_status("Move. Attack plants a trace. Pause still works.")
	_announce_return()


func _physics_process(delta: float) -> void:
	var stats := StatsModule.instance
	if stats != null:
		stats.tick(delta)
	var motion := Input.get_vector("left", "right", "up", "down")
	actor.velocity = motion * _speed
	actor.move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		_plant_trace()
		get_viewport().set_input_as_handled()


func _announce_return() -> void:
	var stats := StatsModule.instance
	if stats == null:
		return
	if stats.had_unclean_exit():
		FeedbackOverlay.toast(2.4, "Unclean exit", "The last session did not close cleanly.")
		return
	var waited := stats.get_seconds_since_last_exit()
	if waited >= 0.0:
		FeedbackOverlay.toast(2.0, "Returned", "%.0f seconds since the previous close." % waited)


func _plant_trace() -> void:
	var player := PlayerModule.instance
	if player == null:
		_refresh_status("SaveSystem is not ready.")
		return
	player.scene_path = SANDBOX_SCENE
	player.position = actor.global_position
	player.custom["traces"] = int(player.custom.get("traces", 0)) + 1
	ghost.global_position = actor.global_position
	ghost.visible = true
	var saved := false
	if SaveSystem != null and SaveSystem.has_method("save_slot"):
		SaveSystem.save_slot()
		saved = true
	var traces := int(player.custom.get("traces", 0))
	if saved:
		FeedbackOverlay.toast(1.6, "Trace kept", "Slot now holds %d traces." % traces)
		_refresh_status("Saved at %s · traces %d" % [Vector2i(actor.global_position), traces])
	else:
		_refresh_status("Trace recorded in memory only.")


func _refresh_status(text: String) -> void:
	status.text = text
