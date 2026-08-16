@tool
class_name PauseScreen
extends SceneManagerBackdrop

signal setting_pressed
signal quit_pressed
signal continue_pressed

@onready var continue_button: ShaderButton = %ContinueButton
@onready var setting_button: ShaderButton = %SettingButton
@onready var quit_button: ShaderButton = %QuitButton

# Connects the authored pause commands.
func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	continue_button.pressed.connect(continue_pressed.emit)
	setting_button.pressed.connect(setting_pressed.emit)
	quit_button.pressed.connect(quit_pressed.emit)
