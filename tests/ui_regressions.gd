extends RefCounted

const SHADER_BUTTON_SCENE := preload("res://Scenes/UIorgan/ShaderButton/shader_button.tscn")
const ACTIVE_UI_FONT := preload("res://assets/fonts/ui_font.tres")
const HD_UI_FONT := preload("res://assets/fonts/ui_hd_font.tres")
const PIXEL_UI_FONT := preload("res://assets/fonts/ui_pixel_font.tres")


# Runs interaction, font, and authored-theme regressions for reusable UI.
func run(context, tree: SceneTree) -> void:
	await _expect_hover_moves_focus(context, tree)
	_expect_bundled_font_profiles(context)
	_expect_feedback_overlay_uses_authored_theme(context, tree)


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
