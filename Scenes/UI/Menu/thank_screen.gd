@tool
class_name ThankScreen
extends SceneManagerBackdrop

signal return_requested

@onready var return_button: ShaderButton = %ReturnButton
@onready var credits_text: RichTextLabel = %CreditsText

var _returning := false


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	var game_audio := get_tree().root.get_node_or_null("GameAudio")
	if game_audio != null and game_audio.has_method("setup_menu_shader_button"):
		game_audio.call("setup_menu_shader_button", return_button)
	if game_audio != null and game_audio.has_method("setup_plain_button"):
		game_audio.call("setup_plain_button", return_button, "cancel")
	return_button.pressed.connect(_request_return)
	credits_text.meta_clicked.connect(_on_credit_link_clicked)
	visibility_changed.connect(_on_visibility_changed)


func _input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	_request_return()


# Emits one return request per modal opening, even under repeated input.
func _request_return() -> void:
	if _returning:
		return
	_returning = true
	return_requested.emit()


# Restores keyboard or controller focus whenever credits becomes interactive.
func _on_visibility_changed() -> void:
	if visible:
		_returning = false
		call_deferred("_restore_focus")


# Focuses the authored return command after the modal has entered the tree.
func _restore_focus() -> void:
	if visible:
		return_button.grab_focus()


# Opens authored public credit links in the system browser.
func _on_credit_link_clicked(meta: Variant) -> void:
	var url := str(meta)
	var error := OS.shell_open(url)
	if error != OK:
		push_warning("Unable to open credit link '%s': %s" % [url, error_string(error)])
