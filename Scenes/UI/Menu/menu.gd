@tool
extends Control

signal start_requested

enum CreditsOrigin {
	MAIN_MENU,
	SETTINGS,
}

const EXIT_TRANSITION := preload("res://resources/scene_transitions/stage_exit_fade_to_black.tres")
const ENTER_TRANSITION := preload("res://resources/scene_transitions/stage_enter_fade_to_black.tres")

@export_file("*.tscn") var start_scene_path := "":
	set(value):
		start_scene_path = value
		if is_node_ready():
			_refresh_start_button()
@export var menu_music: AudioStream

@onready var start_button: ShaderButton = %StartButton
@onready var setting_button: ShaderButton = %SettingButton
@onready var thanks_button: ShaderButton = %ThanksButton
@onready var exit_button: ShaderButton = %ExitButton
@onready var setting_screen: SettingScreen = %SettingScreen
@onready var thank_screen: ThankScreen = %ThankScreen
@onready var status_label: Label = %StatusLabel

var _credits_origin := CreditsOrigin.MAIN_MENU
var _settings_tab_before_credits := 0


func _ready() -> void:
	if Engine.is_editor_hint():
		_refresh_start_button()
		return
	setting_screen.is_in_menu_flag = true
	_configure_platform_commands()
	_configure_audio()
	_connect_signals()
	_refresh_start_button()
	SceneManager.transition_start(ENTER_TRANSITION, true)
	if menu_music != null:
		GameAudio.play_music("menu", menu_music, 0.4)
	call_deferred("_focus_first_enabled_command")


# Connects authored menu commands and modal handoffs.
func _connect_signals() -> void:
	start_button.pressed.connect(_on_start_pressed)
	setting_button.pressed.connect(setting_screen.open_modal)
	thanks_button.pressed.connect(_on_main_thanks_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	setting_screen.thanks_requested.connect(_on_setting_thanks_requested)
	setting_screen.closed.connect(_on_setting_closed)
	thank_screen.return_requested.connect(_on_thank_return_requested)


# Routes each authored menu command through the shared audio service.
func _configure_audio() -> void:
	GameAudio.setup_menu_shader_button(start_button)
	GameAudio.setup_menu_shader_button(setting_button)
	GameAudio.setup_menu_shader_button(thanks_button)
	GameAudio.setup_menu_shader_button(exit_button)
	GameAudio.setup_plain_button(exit_button, "cancel")


# Removes the desktop-only process exit command from Web builds.
func _configure_platform_commands() -> void:
	var is_web := OS.has_feature("web")
	exit_button.visible = not is_web
	exit_button.disabled = is_web
	exit_button.focus_mode = Control.FOCUS_NONE if is_web else Control.FOCUS_ALL


# Enables the start command only when the template has an authored game entry.
func _refresh_start_button() -> void:
	var has_start_path := not start_scene_path.is_empty()
	var ready_to_start := (
		has_start_path
		and ResourceLoader.exists(start_scene_path, "PackedScene")
		and ResourceLoader.load(start_scene_path, "PackedScene") is PackedScene
	)
	start_button.disabled = not ready_to_start
	if ready_to_start:
		status_label.text = ""
	elif has_start_path:
		status_label.text = "Menu.start_scene_path 必须指向有效的 PackedScene。"
	else:
		status_label.text = "在 Inspector 里给 Menu.start_scene_path 指定你的游戏入口场景。"


# Focuses the first visible command that can currently be activated.
func _focus_first_enabled_command() -> void:
	for button: ShaderButton in [start_button, setting_button, thanks_button, exit_button]:
		if button.is_visible_in_tree() and not button.disabled:
			button.grab_focus()
			return


# Starts the authored game scene after the menu exit transition.
func _on_start_pressed() -> void:
	start_requested.emit()
	var tween: Tween = SceneManager.transition_start(EXIT_TRANSITION)
	if tween != null:
		await tween.finished
	var error: Error = SceneManager.change_scene_to_file(start_scene_path)
	if error != OK:
		status_label.text = "无法打开游戏入口场景（Error %d）。" % error
		push_error("Menu failed to open start scene '%s' (Error %d)." % [start_scene_path, error])
		SceneManager.transition_start(ENTER_TRANSITION, true)
		start_button.grab_focus()


# Confirms before closing desktop builds.
func _on_exit_pressed() -> void:
	if await FeedbackOverlay.ask("退出游戏", "确定要退出当前游戏吗？", "退出", "取消"):
		get_tree().quit()
	else:
		exit_button.grab_focus()


# Opens credits from the title and records the matching return destination.
func _on_main_thanks_pressed() -> void:
	_credits_origin = CreditsOrigin.MAIN_MENU
	thank_screen.open_modal()


# Hands settings to credits only after its current close animation completes.
func _on_setting_thanks_requested() -> void:
	_credits_origin = CreditsOrigin.SETTINGS
	_settings_tab_before_credits = setting_screen.get_current_tab()
	var tween := setting_screen.close_modal()
	if tween != null:
		await tween.finished
	thank_screen.open_modal()


# Returns credits to its recorded origin and restores the intended focus target.
func _on_thank_return_requested() -> void:
	var tween := thank_screen.close_modal()
	if tween != null:
		await tween.finished
	if _credits_origin == CreditsOrigin.SETTINGS:
		setting_screen.reopen_after_credits(_settings_tab_before_credits)
		return
	thanks_button.grab_focus()


# Restores title focus after a normal settings return.
func _on_setting_closed() -> void:
	if not thank_screen.visible:
		setting_button.grab_focus()
