extends ComponentBase
class_name ButtonEffectModule

## 按钮轻量交互反馈组件。

## 缓动曲线类型。
@export var ease_type: Tween.EaseType
## 过渡类型。
@export var trans_type: Tween.TransitionType
## 单次动画时长。
@export var anim_duration := 0.09
## 按下时的轻微压缩；悬停不改变控件边界。
@export var press_scale := Vector2.ONE * 0.985
## 普通按钮按下时要播放的界面音类型。
@export_enum("none", "confirm", "cancel") var press_sound_kind := "confirm"

@onready var button: Button = get_parent()

var _tween: Tween


# Connects deterministic press feedback when the component becomes active.
func _component_ready() -> void:
	_on_enable()


# Disconnects only the signal owned by this component.
func _on_disable() -> void:
	if button.pressed.is_connected(_on_button_pressed):
		button.pressed.disconnect(_on_button_pressed)


# Enables a stable press response without hover scaling or random rotation.
func _on_enable() -> void:
	if not button.pressed.is_connected(_on_button_pressed):
		button.pressed.connect(_on_button_pressed)
	button.pivot_offset_ratio = Vector2.ONE / 2.0
	button.scale = Vector2.ONE
	button.rotation_degrees = 0.0


# Compresses and releases the button within a short confirmation window.
func _on_button_pressed() -> void:
	_play_press_sound()
	_reset_tween()
	_tween.tween_property(button, "scale", Vector2.ONE, anim_duration).from(press_scale)


# Replaces in-flight feedback so repeated presses never accumulate transforms.
func _reset_tween() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_ease(ease_type).set_trans(trans_type)
	_tween.set_ignore_time_scale(true)


# Routes non-shader button audio through the optional global audio service.
func _play_press_sound() -> void:
	if press_sound_kind == "none" or button is ShaderButton:
		return
	var game_audio := _get_game_audio()
	if game_audio == null:
		return
	match press_sound_kind:
		"confirm":
			if game_audio.has_method("play_ui_button_press"):
				game_audio.call("play_ui_button_press", button)
			else:
				game_audio.call("play_ui_confirm_ingame")
		"cancel":
			game_audio.call("play_ui_cancel")


# Finds the optional global audio router at the project boundary.
func _get_game_audio() -> Node:
	if get_tree() == null or get_tree().root == null:
		return null
	return get_tree().root.get_node_or_null("GameAudio")
