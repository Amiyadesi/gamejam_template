@tool
extends Button
class_name ShaderButton
## 着色器风格按钮。
##
## 职责：稳定描边、共享 hover/focus 状态、克制的点击反馈。
## 不负责：业务逻辑、对话触发、提示系统。

const HIGHLIGHT_GLOW := 0.22
const HIGHLIGHT_PROGRESS := 1.0

@export var panel_style_box: StyleBox:
	set(value):
		panel_style_box = value
		if is_node_ready():
			_sync_panel_style()
@export var outline_color := Color(0.98, 0.72, 0.32, 1.0):
	set(value):
		outline_color = value
		if is_node_ready():
			_sync_shader_geometry()
@export_group("Audio")
@export var press_sound: AudioStream
@export_range(-80.0, 6.0, 0.5) var press_volume_db := -13.0
@export var select_sound: AudioStream
@export_range(-80.0, 6.0, 0.5) var select_volume_db := -18.0
@export_group("BBcode")
@export_multiline var bb_text: String:
	set(value):
		bb_text = value
		if is_node_ready():
			_sync_text()

@onready var text_label: RichTextLabel = $Label
@onready var panel: Panel = $Panel

var _press_tween: Tween
var _highlight_tween: Tween
var _has_selection_focus := false
var _was_disabled := false
var _last_modulate_alpha := -1.0
var _original_label_modulate := Color.WHITE


func _ready() -> void:
	var authored_material := material as ShaderMaterial
	material = authored_material.duplicate()
	material.set("shader_parameter/time1", 1.0)
	material.set("shader_parameter/time2", 0.0)
	material.set("shader_parameter/center1", Vector2(0.5, 0.5))

	if not resized.is_connected(_sync_shader_geometry):
		resized.connect(_sync_shader_geometry)

	_original_label_modulate = text_label.modulate
	_sync_panel_style()
	_sync_text()
	_sync_shader_geometry()
	if Engine.is_editor_hint():
		return

	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)


func _process(_delta: float) -> void:
	if disabled != _was_disabled:
		_was_disabled = disabled
		_update_highlight()
	var target_alpha := 0.46 if disabled else 1.0
	if not is_equal_approx(_last_modulate_alpha, target_alpha):
		_last_modulate_alpha = target_alpha
		modulate.a = target_alpha


# Replaces the displayed rich text without rebuilding the authored button scene.
func set_bbtext(bbtext: String) -> void:
	bb_text = bbtext


# Applies an authored panel resource supplied by the owning scene.
func set_panel_box(style_box: StyleBox) -> void:
	panel_style_box = style_box


# Mirrors the authored text and font size into the visible rich-text child.
func _sync_text() -> void:
	text_label.text = bb_text if not bb_text.is_empty() else text
	text_label.add_theme_font_size_override("normal_font_size", get_theme_font_size("font_size"))
	text = ""


# Applies the optional Inspector style to the authored panel child.
func _sync_panel_style() -> void:
	if panel_style_box != null:
		panel.add_theme_stylebox_override("panel", panel_style_box)


# Returns pooled buttons to their neutral interaction state.
func reset_visuals() -> void:
	_has_selection_focus = false
	if _press_tween:
		_press_tween.kill()
	if _highlight_tween:
		_highlight_tween.kill()
	if material:
		material.set("shader_parameter/time1", 1.0)
		material.set("shader_parameter/time2", 0.0)
		material.set("shader_parameter/glow", 0.0)
	if text_label:
		text_label.modulate = _original_label_modulate
	_last_modulate_alpha = 0.46 if disabled else 1.0
	modulate.a = _last_modulate_alpha


# Plays a short centered confirmation trace independent of pointer position.
func _on_pressed() -> void:
	_play_press_sound()
	if _press_tween:
		_press_tween.kill()
	_press_tween = create_tween().set_ignore_time_scale(true)
	_press_tween.tween_property(material, "shader_parameter/time1", 1.0, 0.24).from(0.0)


# Moves the single selection focus to an enabled button under the pointer.
func _on_mouse_entered() -> void:
	if disabled:
		return
	_play_select_sound()
	grab_focus()
	_update_highlight()


# Marks keyboard, controller, or pointer-transferred focus for highlighting.
func _on_focus_entered() -> void:
	_has_selection_focus = true
	_update_highlight()


# Clears the outline when another control becomes the focus owner.
func _on_focus_exited() -> void:
	_has_selection_focus = false
	_update_highlight()


# Transitions between neutral and highlighted outlines without layout movement.
func _update_highlight() -> void:
	if material == null:
		return
	var highlighted := not disabled and _has_selection_focus
	if _highlight_tween:
		_highlight_tween.kill()
	_highlight_tween = create_tween().set_parallel().set_ignore_time_scale(true)
	_highlight_tween.tween_property(
		material,
		"shader_parameter/time2",
		HIGHLIGHT_PROGRESS if highlighted else 0.0,
		0.16
	)
	_highlight_tween.tween_property(
		material,
		"shader_parameter/glow",
		HIGHLIGHT_GLOW if highlighted else 0.0,
		0.16
	)
	text_label.modulate = _original_label_modulate


# Keeps the outline distance field aligned with the authored control bounds.
func _sync_shader_geometry() -> void:
	if material == null or size.y <= 0.0:
		return
	material.set("shader_parameter/size", size)
	material.set("shader_parameter/color", outline_color)
	var panel_box := panel.get_theme_stylebox("panel")
	if panel_box is StyleBoxFlat:
		material.set(
			"shader_parameter/corner_radius",
			(panel_box as StyleBoxFlat).corner_radius_top_left / size.y * 2.0
		)


# Plays the authored press sound through the project audio facade.
func _play_press_sound() -> void:
	if press_sound == null:
		return
	var game_audio := _get_game_audio()
	if game_audio != null:
		game_audio.call("play_ui", press_sound, press_volume_db)


# Plays the authored selection sound through the project audio facade.
func _play_select_sound() -> void:
	if select_sound == null:
		return
	var game_audio := _get_game_audio()
	if game_audio != null:
		game_audio.call("play_ui", select_sound, select_volume_db)


# Finds the optional global audio router at the project boundary.
func _get_game_audio() -> Node:
	if get_tree() == null or get_tree().root == null:
		return null
	return get_tree().root.get_node_or_null("GameAudio")
