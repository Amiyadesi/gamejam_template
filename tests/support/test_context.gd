class_name HeadlessTestContext
extends RefCounted

var assertions: int = 0
var failures: int = 0


# Records whether a boolean behavior matches its expectation.
func expect_true(condition: bool, message: String) -> void:
	assertions += 1
	if condition:
		return
	failures += 1
	printerr("FAIL: %s" % message)


# Records whether two values are equal and prints both values on failure.
func expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	assertions += 1
	if actual == expected:
		return
	failures += 1
	printerr("FAIL: %s (expected=%s, actual=%s)" % [message, str(expected), str(actual)])


# Records whether two floating-point values are close enough for tween checks.
func expect_near(actual: float, expected: float, tolerance: float, message: String) -> void:
	assertions += 1
	if absf(actual - expected) <= tolerance:
		return
	failures += 1
	printerr(
		"FAIL: %s (expected=%f, actual=%f, tolerance=%f)"
		% [message, expected, actual, tolerance]
	)
