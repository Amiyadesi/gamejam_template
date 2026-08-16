extends SceneTree

const TEST_CONTEXT := preload("res://tests/support/test_context.gd")
const AUDIO_REGRESSIONS := preload("res://tests/audio_regressions.gd")
const NARRATIVE_REGRESSIONS := preload("res://tests/narrative_regressions.gd")
const INPUT_REGRESSIONS := preload("res://tests/input_regressions.gd")
const MODAL_REGRESSIONS := preload("res://tests/modal_regressions.gd")
const UI_REGRESSIONS := preload("res://tests/ui_regressions.gd")
const GAMEPLAY_UI_REGRESSIONS := preload("res://tests/gameplay_ui_regressions.gd")

var _context := TEST_CONTEXT.new()


# Starts the regression suite after the SceneTree is initialized.
func _initialize() -> void:
	call_deferred("_run")


# 运行全部回归，并用退出码报告最终结果。
func _run() -> void:
	_test_harness_reports_success()
	await AUDIO_REGRESSIONS.new().run(_context, self)
	await NARRATIVE_REGRESSIONS.new().run(_context, self)
	INPUT_REGRESSIONS.new().run(_context)
	await MODAL_REGRESSIONS.new().run(_context, self)
	await UI_REGRESSIONS.new().run(_context, self)
	await GAMEPLAY_UI_REGRESSIONS.new().run(_context, self)
	print("Regression tests: %d assertions, %d failures" % [_context.assertions, _context.failures])
	quit(1 if _context.failures > 0 else 0)


# Proves the custom assertion harness is available before behavior tests use it.
func _test_harness_reports_success() -> void:
	_context.expect_true(true, "headless regression harness should execute")
