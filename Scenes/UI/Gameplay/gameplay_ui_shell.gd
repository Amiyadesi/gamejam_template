class_name GameplayUiShell
extends CanvasLayer

signal pause_changed(paused: bool)
signal quit_to_menu_requested

const EXIT_TRANSITION := preload("res://resources/scene_transitions/stage_exit_fade_to_black.tres")
const ENTER_TRANSITION := preload("res://resources/scene_transitions/stage_enter_fade_to_black.tres")

@export_file("*.tscn") var menu_scene_path := "res://Scenes/UI/Menu/menu.tscn"

@onready var feedback_overlay: Node = get_tree().root.get_node("FeedbackOverlay")
@onready var scene_manager: Node = get_tree().root.get_node("SceneManager")
@onready var pause_screen: PauseScreen = %PauseScreen
@onready var setting_screen: SettingScreen = %SettingScreen

var _transitioning := false
var _quit_pending := false


# 接好 authored 暂停控件，并保持初始玩法运行。
func _ready() -> void:
	pause_screen.continue_pressed.connect(resume_game)
	pause_screen.setting_pressed.connect(open_settings)
	pause_screen.quit_pressed.connect(_confirm_quit_to_menu)
	setting_screen.closed.connect(_on_settings_closed)
	setting_screen.is_in_menu_flag = false


# 用统一入口处理 Esc，不让玩法场景各自重复接线。
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause") or _transitioning:
		return
	get_viewport().set_input_as_handled()
	if setting_screen.visible:
		setting_screen.request_return()
	elif pause_screen.visible:
		resume_game()
	else:
		pause_game()


# 暂停玩法并打开 authored 暂停页。
func pause_game() -> void:
	if _transitioning or pause_screen.visible:
		return
	get_tree().paused = true
	pause_screen.open_modal()
	pause_changed.emit(true)


# 关闭暂停页后再恢复玩法时间。
func resume_game() -> void:
	if _transitioning or not get_tree().paused or setting_screen.visible:
		return
	_transitioning = true
	var tween := pause_screen.close_modal()
	if tween != null:
		await tween.finished
	get_tree().paused = false
	_transitioning = false
	pause_changed.emit(false)


# 关闭暂停页后打开设置，并始终保留暂停状态。
func open_settings() -> void:
	if _transitioning or not get_tree().paused or not pause_screen.visible:
		return
	_transitioning = true
	var tween := pause_screen.close_modal()
	if tween != null:
		await tween.finished
	setting_screen.open_modal()
	_transitioning = false


# 设置关闭后重新展示暂停页，不触碰玩法时间。
func _on_settings_closed() -> void:
	if not get_tree().paused:
		return
	pause_screen.open_modal()


# 询问玩家是否离开；取消后继续保持暂停界面。
func _confirm_quit_to_menu() -> void:
	if _quit_pending or _transitioning:
		return
	_quit_pending = true
	var confirmed: bool = await feedback_overlay.call(
		"ask",
		"返回主菜单",
		"确定要离开当前游戏吗？",
		"返回",
		"取消"
	)
	if confirmed:
		await quit_to_menu()
		return
	_quit_pending = false
	pause_screen.continue_button.grab_focus()


# 在黑幕下恢复时间并切回 authored 主菜单。
func quit_to_menu() -> void:
	if _transitioning:
		return
	if menu_scene_path.is_empty() or not ResourceLoader.exists(menu_scene_path, "PackedScene"):
		_restore_after_quit_failure(
			"GameplayUiShell.menu_scene_path must reference a valid PackedScene: '%s'." % menu_scene_path
		)
		return

	_transitioning = true
	quit_to_menu_requested.emit()
	var tween := scene_manager.call("transition_start", EXIT_TRANSITION) as Tween
	if tween != null:
		await tween.finished
	get_tree().paused = false
	pause_changed.emit(false)
	var error := int(scene_manager.call("change_scene_to_file", menu_scene_path))
	if error != OK:
		_restore_after_quit_failure(
			"GameplayUiShell failed to open menu '%s' (Error %d)." % [menu_scene_path, error]
		)


# 场景切换失败时恢复可操作的暂停页并显式报错。
func _restore_after_quit_failure(message: String) -> void:
	push_error(message)
	get_tree().paused = true
	_transitioning = false
	_quit_pending = false
	scene_manager.call("transition_start", ENTER_TRANSITION, true)
	if not pause_screen.visible:
		pause_screen.open_modal()
