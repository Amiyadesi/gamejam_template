extends RefCounted

const SHADER_BUTTON_SCENE := preload("res://Scenes/UIorgan/ShaderButton/shader_button.tscn")
const ACTIVE_UI_FONT := preload("res://assets/fonts/ui_font.tres")
const HD_UI_FONT := preload("res://assets/fonts/ui_hd_font.tres")
const PIXEL_UI_FONT := preload("res://assets/fonts/ui_pixel_font.tres")


# 运行可复用 UI 的交互、字体、主题与鼠标穿透回归。
func run(context, tree: SceneTree) -> void:
	await _expect_hover_moves_focus(context, tree)
	_expect_bundled_font_profiles(context)
	_expect_feedback_overlay_uses_authored_theme(context, tree)
	await _expect_toast_overlay_ignores_pointer_input(context, tree)


# Verifies pointer focus, exclusive selection, label sizing, and disabled behavior.
func _expect_hover_moves_focus(context, tree: SceneTree) -> void:
	var host := HBoxContainer.new()
	var first := SHADER_BUTTON_SCENE.instantiate() as Button
	var second := SHADER_BUTTON_SCENE.instantiate() as Button
	host.add_child(first)
	host.add_child(second)
	tree.root.add_child(host)
	await tree.process_frame

	first.grab_focus()
	second.call("_on_mouse_entered")
	await tree.process_frame
	context.expect_equal(
		second.get_viewport().gui_get_focus_owner(),
		second,
		"mouse hover should move the shared selection focus"
	)
	context.expect_true(
		second.get_theme_stylebox("focus") is StyleBoxEmpty,
		"ShaderButton should suppress the native duplicate focus frame"
	)
	var second_label := second.get_node("Label") as RichTextLabel
	context.expect_true(
		second_label.has_theme_font_size_override("normal_font_size"),
		"ShaderButton should override the visible rich-text font size"
	)
	context.expect_equal(
		second_label.get_theme_font_size("normal_font_size"),
		second.get_theme_font_size("font_size"),
		"ShaderButton should pass its authored font size to the visible rich-text label"
	)
	first.grab_focus()
	await tree.create_timer(0.2).timeout
	context.expect_near(
		float((second.material as ShaderMaterial).get("shader_parameter/time2")),
		0.0,
		0.01,
		"keyboard focus should clear the previous pointer-selected outline"
	)

	second.disabled = true
	second.call("_on_mouse_entered")
	await tree.process_frame
	context.expect_equal(
		first.get_viewport().gui_get_focus_owner(),
		first,
		"disabled buttons should not take focus on hover"
	)

	host.queue_free()
	await tree.process_frame


# Confirms both bundled profiles contain Chinese glyphs and HD is the default.
func _expect_bundled_font_profiles(context) -> void:
	var sample_text := "Game Jam Template 设置感谢返回恢复默认按键·…「」"
	context.expect_equal(
		ACTIVE_UI_FONT.base_font.resource_path,
		HD_UI_FONT.resource_path,
		"the active UI font should default to the HD profile"
	)
	for character in sample_text:
		var codepoint := character.unicode_at(0)
		context.expect_true(
			HD_UI_FONT.base_font.has_char(codepoint),
			"the HD profile should contain every common UI glyph"
		)
		context.expect_true(
			PIXEL_UI_FONT.base_font.has_char(codepoint),
			"the pixel profile should contain every common UI glyph"
		)


# Confirms standalone feedback branches receive the authored shared theme.
func _expect_feedback_overlay_uses_authored_theme(context, tree: SceneTree) -> void:
	var overlay := tree.root.get_node("FeedbackOverlay")
	var toast_margin := overlay.get_node("ToastMargin") as Control
	var dialog_backdrop := overlay.get_node("DialogBackdrop") as Control
	context.expect_true(
		toast_margin.theme != null,
		"feedback toasts should use the authored UI font theme"
	)
	context.expect_equal(
		dialog_backdrop.theme,
		toast_margin.theme,
		"feedback dialogs and toasts should share the authored theme"
	)


# 验证隐藏 Toast 区域不会截断其下方真实鼠标点击。
func _expect_toast_overlay_ignores_pointer_input(context, tree: SceneTree) -> void:
	var overlay := tree.root.get_node("FeedbackOverlay")
	var toast_margin := overlay.get_node("ToastMargin") as Control
	var target_button := Button.new()
	target_button.position = toast_margin.position
	target_button.size = toast_margin.size
	tree.root.add_child(target_button)
	await tree.process_frame

	var state := {"pressed": false}
	target_button.pressed.connect(func() -> void: state["pressed"] = true)
	var click_position := toast_margin.get_global_rect().get_center()
	var motion_event := InputEventMouseMotion.new()
	motion_event.position = click_position
	motion_event.global_position = click_position
	tree.root.push_input(motion_event, true)
	await tree.process_frame

	var press_event := InputEventMouseButton.new()
	press_event.button_index = MOUSE_BUTTON_LEFT
	press_event.button_mask = MOUSE_BUTTON_MASK_LEFT
	press_event.position = click_position
	press_event.global_position = click_position
	press_event.pressed = true
	tree.root.push_input(press_event, true)
	await tree.process_frame

	var release_event := press_event.duplicate() as InputEventMouseButton
	release_event.button_mask = 0
	release_event.pressed = false
	tree.root.push_input(release_event, true)
	await tree.process_frame
	context.expect_true(bool(state["pressed"]), "toast overlay should let pointer clicks reach controls below it")

	target_button.queue_free()
	await tree.process_frame
