extends SceneTree

const TEST_CONTEXT := preload("res://tests/support/test_context.gd")

var _context := TEST_CONTEXT.new()


# Starts the regression suite after the SceneTree is initialized.
func _initialize() -> void:
	call_deferred("_run")


# Runs all registered regressions and exits with a CI-friendly status code.
func _run() -> void:
	_test_harness_reports_success()
	print("Regression tests: %d assertions, %d failures" % [_context.assertions, _context.failures])
	quit(1 if _context.failures > 0 else 0)


# Proves the custom assertion harness is available before behavior tests use it.
func _test_harness_reports_success() -> void:
	_context.expect_true(true, "headless regression harness should execute")
