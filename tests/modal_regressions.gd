extends RefCounted

const MODAL_FIXTURE := preload("res://tests/fixtures/modal_fixture.tscn")
const PROGRESS_CASES: Array[float] = [0.0, 0.25, 0.5, 1.0]
const ALPHA_TOLERANCE := 0.01


# Verifies closing behavior at representative points in the opening animation.
func run(context, tree: SceneTree) -> void:
	for progress in PROGRESS_CASES:
		await _expect_close_from_progress(context, tree, progress)
	await _expect_repeated_close_is_ignored(context, tree)


# Proves close starts in place, scales its duration, and ends hidden.
func _expect_close_from_progress(
	context,
	tree: SceneTree,
	progress: float
) -> void:
	var backdrop := await _spawn_fixture(tree)
	_open_to_progress(backdrop, progress)

	var starting_alpha := backdrop.modulate.a
	context.expect_near(
		starting_alpha,
		progress,
		ALPHA_TOLERANCE,
		"modal should reach %.0f%% opening progress before closing" % (progress * 100.0)
	)

	var closing := backdrop.close_modal()
	context.expect_true(
		closing != null,
		"close should return a tween from %.0f%% progress" % (progress * 100.0)
	)
	if closing == null:
		await _free_fixture(backdrop, tree)
		return

	closing.pause()
	var expected_duration := backdrop.closing_duration * progress
	var probe_duration := 0.001 if is_zero_approx(expected_duration) else expected_duration * 0.01
	closing.custom_step(probe_duration)
	context.expect_true(
		backdrop.modulate.a <= starting_alpha + ALPHA_TOLERANCE,
		"close should not jump above %.0f%% progress" % (progress * 100.0)
	)

	if expected_duration > 0.0:
		closing.custom_step(expected_duration * 0.89)
		context.expect_true(
			backdrop.visible,
			"modal should remain visible before its scaled close duration elapses"
		)
		closing.custom_step(expected_duration * 0.11 + 0.001)

	await tree.process_frame
	context.expect_true(
		not backdrop.visible,
		"modal should be hidden after closing from %.0f%% progress" % (progress * 100.0)
	)
	context.expect_near(
		backdrop.modulate.a,
		0.0,
		ALPHA_TOLERANCE,
		"modal opacity should finish closed from %.0f%% progress" % (progress * 100.0)
	)
	await _free_fixture(backdrop, tree)


# Proves a second close request does not replace the active closing tween.
func _expect_repeated_close_is_ignored(
	context,
	tree: SceneTree
) -> void:
	var backdrop := await _spawn_fixture(tree)
	_open_to_progress(backdrop, 0.5)

	var closing := backdrop.close_modal()
	context.expect_true(closing != null, "first close request should start a tween")
	if closing == null:
		await _free_fixture(backdrop, tree)
		return

	closing.pause()
	var repeated_close := backdrop.close_modal()
	context.expect_true(repeated_close == null, "repeated close request should be ignored")

	closing.custom_step(backdrop.closing_duration * 0.5 + 0.001)
	await tree.process_frame
	context.expect_true(not backdrop.visible, "original close tween should still finish after a repeat")
	await _free_fixture(backdrop, tree)


# Instantiates the authored backdrop contract and waits for its ready state.
func _spawn_fixture(tree: SceneTree) -> SceneManagerBackdrop:
	var backdrop := MODAL_FIXTURE.instantiate() as SceneManagerBackdrop
	tree.root.add_child(backdrop)
	await tree.process_frame
	return backdrop


# Advances the public opening transition to a deterministic progress point.
func _open_to_progress(backdrop: SceneManagerBackdrop, progress: float) -> void:
	var opening := backdrop.open_modal()
	opening.pause()
	if progress > 0.0:
		opening.custom_step(backdrop.opening_duration * progress)


# Frees each fixture before the next progress case runs.
func _free_fixture(backdrop: SceneManagerBackdrop, tree: SceneTree) -> void:
	backdrop.queue_free()
	await tree.process_frame
