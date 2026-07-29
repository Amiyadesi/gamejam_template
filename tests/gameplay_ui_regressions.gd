extends RefCounted

const SETTING_SCREEN_PATH := "res://Scenes/UI/Menu/setting_screen.tscn"
const GAMEPLAY_UI_SHELL_PATH := "res://Scenes/UI/Gameplay/gameplay_ui_shell.tscn"


# 运行玩法 UI 的暂停所有权回归。
func run(context, tree: SceneTree) -> void:
	_expect_16_9_display_contract(context)
	_expect_generated_folders_are_excluded_from_import(context)
	await _expect_settings_return_preserves_pause(context, tree)
	await _expect_shell_owns_pause_and_resume(context, tree)
	await _expect_shell_keeps_pause_through_settings(context, tree)
	await _expect_quit_cancel_preserves_pause(context, tree)
	await _expect_pause_action_toggles_shell(context, tree)
	await _expect_pause_action_returns_from_settings(context, tree)
	await _expect_invalid_menu_path_restores_pause(context, tree)


# 验证模板只承诺三组 16:9 分辨率并保持画面比例。
func _expect_16_9_display_contract(context) -> void:
	context.expect_equal(
		ProjectSettings.get_setting("display/window/stretch/aspect"),
		"keep",
		"template should preserve its authored 16:9 aspect ratio"
	)
	context.expect_equal(
		SettingScreen.WINDOW_RESOLUTIONS,
		[Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)],
		"settings should expose only the supported 16:9 window presets"
	)


# 验证导出与截图目录不会进入 Godot 资源扫描。
func _expect_generated_folders_are_excluded_from_import(context) -> void:
	context.expect_true(
		FileAccess.file_exists("res://build/.gdignore"),
		"build directory should carry a tracked .gdignore"
	)
	context.expect_true(
		FileAccess.file_exists("res://screenshots/.gdignore"),
		"screenshots directory should carry a tracked .gdignore"
	)


# 验证设置页关闭时不会擅自恢复玩法时间。
func _expect_settings_return_preserves_pause(context, tree: SceneTree) -> void:
	var setting_scene := load(SETTING_SCREEN_PATH) as PackedScene
	context.expect_true(setting_scene != null, "settings scene should load for gameplay pause tests")
	if setting_scene == null:
		return
	var setting_screen := setting_scene.instantiate() as SettingScreen
	setting_screen.closing_duration = 0.0
	tree.root.add_child(setting_screen)
	await tree.process_frame

	tree.paused = true
	setting_screen.return_button.pressed.emit()
	await tree.process_frame
	context.expect_true(tree.paused, "settings return should preserve the caller-owned pause state")

	tree.paused = false
	setting_screen.queue_free()
	await tree.process_frame


# 验证 authored shell 通过公共接口统一暂停和继续。
func _expect_shell_owns_pause_and_resume(context, tree: SceneTree) -> void:
	var shell_scene := load(GAMEPLAY_UI_SHELL_PATH) as PackedScene
	context.expect_true(shell_scene != null, "gameplay UI shell should be an authored reusable scene")
	if shell_scene == null:
		return
	var shell := shell_scene.instantiate()
	tree.root.add_child(shell)
	await tree.process_frame
	var pause_screen := shell.get_node("PauseScreen") as PauseScreen
	pause_screen.opening_duration = 0.0
	pause_screen.closing_duration = 0.0

	shell.call("pause_game")
	await tree.process_frame
	context.expect_true(tree.paused, "pause_game should pause the scene tree")
	context.expect_true(pause_screen.visible, "pause_game should display the authored pause screen")

	shell.call("resume_game")
	await tree.process_frame
	await tree.process_frame
	context.expect_true(not tree.paused, "resume_game should resume the scene tree")
	context.expect_true(not pause_screen.visible, "resume_game should close the authored pause screen")

	shell.queue_free()
	await tree.process_frame


# 验证真实 pause 输入可打开并关闭统一暂停页。
func _expect_pause_action_toggles_shell(context, tree: SceneTree) -> void:
	var shell_scene := load(GAMEPLAY_UI_SHELL_PATH) as PackedScene
	var shell := shell_scene.instantiate()
	tree.root.add_child(shell)
	await tree.process_frame
	var pause_screen := shell.get_node("PauseScreen") as PauseScreen
	pause_screen.opening_duration = 0.0
	pause_screen.closing_duration = 0.0

	var press_event := InputEventAction.new()
	press_event.action = "pause"
	press_event.pressed = true
	tree.root.push_input(press_event, true)
	await tree.process_frame
	context.expect_true(tree.paused, "pause action should pause gameplay through the shell")
	context.expect_true(pause_screen.visible, "pause action should open the authored pause screen")

	var release_event := press_event.duplicate() as InputEventAction
	release_event.pressed = false
	tree.root.push_input(release_event, true)
	await tree.process_frame
	tree.root.push_input(press_event, true)
	await tree.process_frame
	await tree.process_frame
	context.expect_true(not tree.paused, "a second pause action should resume gameplay")
	context.expect_true(not pause_screen.visible, "a second pause action should close the pause screen")

	shell.queue_free()
	await tree.process_frame


# 验证重绑定后的 pause 动作也能从设置页返回暂停页。
func _expect_pause_action_returns_from_settings(context, tree: SceneTree) -> void:
	var shell_scene := load(GAMEPLAY_UI_SHELL_PATH) as PackedScene
	var shell := shell_scene.instantiate()
	tree.root.add_child(shell)
	await tree.process_frame
	var pause_screen := shell.get_node("PauseScreen") as PauseScreen
	var setting_screen := shell.get_node("SettingScreen") as SettingScreen
	pause_screen.opening_duration = 0.0
	pause_screen.closing_duration = 0.0
	setting_screen.opening_duration = 0.0
	setting_screen.closing_duration = 0.0
	shell.call("pause_game")
	await tree.process_frame
	shell.call("open_settings")
	await tree.process_frame
	await tree.process_frame

	var pause_event := InputEventAction.new()
	pause_event.action = "pause"
	pause_event.pressed = true
	tree.root.push_input(pause_event, true)
	await tree.process_frame
	await tree.process_frame
	context.expect_true(tree.paused, "pause action in settings should keep gameplay paused")
	context.expect_true(pause_screen.visible, "pause action in settings should reopen the pause screen")
	context.expect_true(not setting_screen.visible, "pause action in settings should close settings")

	tree.paused = false
	shell.queue_free()
	await tree.process_frame


# 验证无效主菜单路径会恢复暂停页，而不是解冻玩法。
func _expect_invalid_menu_path_restores_pause(context, tree: SceneTree) -> void:
	var shell_scene := load(GAMEPLAY_UI_SHELL_PATH) as PackedScene
	var shell := shell_scene.instantiate()
	shell.set("menu_scene_path", "res://tests/fixtures/missing_menu.tscn")
	tree.root.add_child(shell)
	await tree.process_frame
	var pause_screen := shell.get_node("PauseScreen") as PauseScreen
	pause_screen.opening_duration = 0.0
	pause_screen.closing_duration = 0.0
	shell.call("pause_game")
	await tree.process_frame

	var print_errors := Engine.print_error_messages
	Engine.print_error_messages = false
	shell.call("quit_to_menu")
	await tree.process_frame
	Engine.print_error_messages = print_errors
	context.expect_true(tree.paused, "invalid menu path should restore the paused scene tree")
	context.expect_true(pause_screen.visible, "invalid menu path should restore the pause screen")

	tree.paused = false
	shell.queue_free()
	await tree.process_frame


# 验证取消返回主菜单后仍停留在暂停状态。
func _expect_quit_cancel_preserves_pause(context, tree: SceneTree) -> void:
	var shell_scene := load(GAMEPLAY_UI_SHELL_PATH) as PackedScene
	var shell := shell_scene.instantiate()
	tree.root.add_child(shell)
	await tree.process_frame
	var pause_screen := shell.get_node("PauseScreen") as PauseScreen
	pause_screen.opening_duration = 0.0
	pause_screen.closing_duration = 0.0
	var feedback_overlay := tree.root.get_node("FeedbackOverlay")
	var dialog_backdrop := feedback_overlay.get_node("DialogBackdrop") as SceneManagerBackdrop
	dialog_backdrop.opening_duration = 0.0
	dialog_backdrop.closing_duration = 0.0

	shell.call("pause_game")
	await tree.process_frame
	context.expect_true(shell.has_method("quit_to_menu"), "gameplay UI shell should expose quit_to_menu")
	if not shell.has_method("quit_to_menu"):
		tree.paused = false
		shell.queue_free()
		await tree.process_frame
		return
	pause_screen.quit_pressed.emit()
	await tree.process_frame
	context.expect_true(dialog_backdrop.visible, "quit command should open the shared confirmation dialog")
	feedback_overlay.get_node("%CancelButton").pressed.emit()
	await tree.process_frame
	await tree.process_frame
	context.expect_true(tree.paused, "cancelling quit should keep gameplay paused")
	context.expect_true(pause_screen.visible, "cancelling quit should keep the pause screen visible")

	tree.paused = false
	shell.queue_free()
	await tree.process_frame


# 验证设置往返全程保持暂停，并回到暂停页。
func _expect_shell_keeps_pause_through_settings(context, tree: SceneTree) -> void:
	var shell_scene := load(GAMEPLAY_UI_SHELL_PATH) as PackedScene
	var shell := shell_scene.instantiate()
	tree.root.add_child(shell)
	await tree.process_frame
	var pause_screen := shell.get_node("PauseScreen") as PauseScreen
	var setting_screen := shell.get_node("SettingScreen") as SettingScreen
	pause_screen.opening_duration = 0.0
	pause_screen.closing_duration = 0.0
	setting_screen.opening_duration = 0.0
	setting_screen.closing_duration = 0.0

	shell.call("pause_game")
	await tree.process_frame
	context.expect_true(shell.has_method("open_settings"), "gameplay UI shell should expose open_settings")
	if not shell.has_method("open_settings"):
		tree.paused = false
		shell.queue_free()
		await tree.process_frame
		return
	shell.call("open_settings")
	await tree.process_frame
	await tree.process_frame
	context.expect_true(tree.paused, "opening settings should keep gameplay paused")
	context.expect_true(setting_screen.visible, "open_settings should display the authored settings screen")
	context.expect_true(not pause_screen.visible, "open_settings should hide the pause screen")

	setting_screen.return_button.pressed.emit()
	await tree.process_frame
	await tree.process_frame
	context.expect_true(tree.paused, "returning from settings should keep gameplay paused")
	context.expect_true(pause_screen.visible, "settings return should reopen the pause screen")
	context.expect_true(not setting_screen.visible, "settings return should close the settings screen")

	shell.call("resume_game")
	await tree.process_frame
	await tree.process_frame
	tree.paused = false
	shell.queue_free()
	await tree.process_frame
