extends RefCounted

const ACTION_REBIND := "__regression_input_rebind"
const ACTION_PRIMARY := "__regression_input_primary"
const ACTION_CTRL_KEY := "__regression_input_ctrl_key"
const ACTION_LEFT_SHIFT := "__regression_input_left_shift"
const ACTION_AXIS_POSITIVE := "__regression_input_axis_positive"
const ACTION_DEVICE_WILDCARD := "__regression_input_device_wildcard"
const ACTION_DEVICE_ZERO := "__regression_input_device_zero"
const ACTION_DEVICE_ONE := "__regression_input_device_one"
const KEY_LOCATION_LEFT := 1
const KEY_LOCATION_RIGHT := 2

const TEST_ACTIONS := [
	ACTION_REBIND,
	ACTION_PRIMARY,
	ACTION_CTRL_KEY,
	ACTION_LEFT_SHIFT,
	ACTION_AXIS_POSITIVE,
	ACTION_DEVICE_WILDCARD,
	ACTION_DEVICE_ZERO,
	ACTION_DEVICE_ONE,
]


# Runs input persistence and rebinding regressions against public APIs.
func run(context) -> void:
	_remove_test_actions()
	_test_event_round_trips(context)
	_test_legacy_events_restore_wildcard_device(context)
	var module := KeybindingModule.new()
	_test_rebind_preserves_event_order(context, module)
	_test_primary_rebind_preserves_event_order(context, module)
	_test_exact_conflicts_respect_event_details(context, module)
	_test_conflicts_respect_device_overlap(context, module)
	_remove_test_actions()


# Verifies every supported event retains gameplay-relevant fields after saving.
func _test_event_round_trips(context) -> void:
	var key := InputEventKey.new()
	key.device = 7
	key.keycode = KEY_K
	key.physical_keycode = KEY_SHIFT
	key.key_label = KEY_K
	key.location = KEY_LOCATION_LEFT
	key.ctrl_pressed = true
	key.shift_pressed = true
	key.alt_pressed = true
	key.meta_pressed = true
	var key_device := key.device
	var restored_key := ResourceSerializer.deserialize_event(
		ResourceSerializer.serialize_event(key)
	) as InputEventKey
	context.expect_equal(restored_key.device, key_device, "key device should round-trip")
	context.expect_equal(restored_key.keycode, KEY_K, "keycode should round-trip")
	context.expect_equal(
		restored_key.physical_keycode,
		KEY_SHIFT,
		"physical keycode should round-trip"
	)
	context.expect_equal(restored_key.key_label, KEY_K, "key label should round-trip")
	context.expect_equal(
		restored_key.location,
		KEY_LOCATION_LEFT,
		"key location should round-trip"
	)
	context.expect_true(restored_key.ctrl_pressed, "key Ctrl modifier should round-trip")
	context.expect_true(restored_key.shift_pressed, "key Shift modifier should round-trip")
	context.expect_true(restored_key.alt_pressed, "key Alt modifier should round-trip")
	context.expect_true(restored_key.meta_pressed, "key Meta modifier should round-trip")

	var autoremap_key := InputEventKey.new()
	autoremap_key.device = InputEvent.DEVICE_ID_EMULATION
	autoremap_key.keycode = KEY_F13
	autoremap_key.command_or_control_autoremap = true
	var restored_autoremap_key := ResourceSerializer.deserialize_event(
		ResourceSerializer.serialize_event(autoremap_key)
	) as InputEventKey
	context.expect_true(
		restored_autoremap_key.command_or_control_autoremap,
		"key command/control autoremap should round-trip"
	)

	var mouse := InputEventMouseButton.new()
	mouse.device = 3
	mouse.button_index = MOUSE_BUTTON_XBUTTON1
	mouse.ctrl_pressed = true
	mouse.shift_pressed = true
	mouse.alt_pressed = true
	mouse.meta_pressed = true
	var mouse_device := mouse.device
	var restored_mouse := ResourceSerializer.deserialize_event(
		ResourceSerializer.serialize_event(mouse)
	) as InputEventMouseButton
	context.expect_equal(restored_mouse.device, mouse_device, "mouse device should round-trip")
	context.expect_equal(
		restored_mouse.button_index,
		MOUSE_BUTTON_XBUTTON1,
		"mouse button should round-trip"
	)
	context.expect_true(restored_mouse.ctrl_pressed, "mouse Ctrl modifier should round-trip")
	context.expect_true(restored_mouse.shift_pressed, "mouse Shift modifier should round-trip")
	context.expect_true(restored_mouse.alt_pressed, "mouse Alt modifier should round-trip")
	context.expect_true(restored_mouse.meta_pressed, "mouse Meta modifier should round-trip")

	var autoremap_mouse := InputEventMouseButton.new()
	autoremap_mouse.device = InputEvent.DEVICE_ID_EMULATION
	autoremap_mouse.button_index = MOUSE_BUTTON_MIDDLE
	autoremap_mouse.command_or_control_autoremap = true
	var restored_autoremap_mouse := ResourceSerializer.deserialize_event(
		ResourceSerializer.serialize_event(autoremap_mouse)
	) as InputEventMouseButton
	context.expect_true(
		restored_autoremap_mouse.command_or_control_autoremap,
		"mouse command/control autoremap should round-trip"
	)

	var joy_button := InputEventJoypadButton.new()
	joy_button.device = 1
	joy_button.button_index = JOY_BUTTON_RIGHT_SHOULDER
	var restored_joy_button := ResourceSerializer.deserialize_event(
		ResourceSerializer.serialize_event(joy_button)
	) as InputEventJoypadButton
	context.expect_equal(restored_joy_button.device, 1, "joypad button device should round-trip")
	context.expect_equal(
		restored_joy_button.button_index,
		JOY_BUTTON_RIGHT_SHOULDER,
		"joypad button should round-trip"
	)

	var joy_motion := InputEventJoypadMotion.new()
	joy_motion.device = 2
	joy_motion.axis = JOY_AXIS_RIGHT_Y
	joy_motion.axis_value = -0.75
	var restored_joy_motion := ResourceSerializer.deserialize_event(
		ResourceSerializer.serialize_event(joy_motion)
	) as InputEventJoypadMotion
	context.expect_equal(restored_joy_motion.device, 2, "joypad axis device should round-trip")
	context.expect_equal(restored_joy_motion.axis, JOY_AXIS_RIGHT_Y, "joypad axis should round-trip")
	context.expect_near(
		restored_joy_motion.axis_value,
		-0.75,
		0.0001,
		"joypad axis direction and value should round-trip"
	)


# Verifies old payloads without device data remain wildcard bindings.
func _test_legacy_events_restore_wildcard_device(context) -> void:
	var payloads := [
		{"event_type": "key", "keycode": KEY_F13},
		{"event_type": "mouse_button", "button_index": MOUSE_BUTTON_MIDDLE},
		{"event_type": "joypad_button", "button_index": JOY_BUTTON_A},
		{"event_type": "joypad_motion", "axis": JOY_AXIS_LEFT_X, "axis_value": 1.0},
	]
	for payload in payloads:
		var restored := ResourceSerializer.deserialize_event(payload)
		context.expect_equal(
			restored.device,
			InputEvent.DEVICE_ID_EMULATION,
			"legacy %s event should target every device" % payload["event_type"]
		)


# Verifies replacing an arbitrary binding does not move neighboring bindings.
func _test_rebind_preserves_event_order(context, module: KeybindingModule) -> void:
	_add_action_with_events(
		ACTION_REBIND,
		[_key_event(KEY_A), _key_event(KEY_B), _key_event(KEY_C)]
	)
	module.rebind_action_event(ACTION_REBIND, 1, _key_event(KEY_X))
	context.expect_equal(
		_event_keycodes(ACTION_REBIND),
		[KEY_A, KEY_X, KEY_C],
		"rebind_action_event should replace in place"
	)
	InputMap.erase_action(ACTION_REBIND)


# Verifies replacing the primary binding leaves it at index zero.
func _test_primary_rebind_preserves_event_order(context, module: KeybindingModule) -> void:
	_add_action_with_events(
		ACTION_PRIMARY,
		[_key_event(KEY_A), _key_event(KEY_B), _key_event(KEY_C)]
	)
	module.rebind_action_primary(ACTION_PRIMARY, _key_event(KEY_X))
	context.expect_equal(
		_event_keycodes(ACTION_PRIMARY),
		[KEY_X, KEY_B, KEY_C],
		"rebind_action_primary should replace index zero in place"
	)
	InputMap.erase_action(ACTION_PRIMARY)


# Verifies exact matching distinguishes modifiers, key side, and axis direction.
func _test_exact_conflicts_respect_event_details(context, module: KeybindingModule) -> void:
	var ctrl_key := _key_event(KEY_K)
	ctrl_key.ctrl_pressed = true
	_add_action_with_events(ACTION_CTRL_KEY, [ctrl_key])

	var left_shift := InputEventKey.new()
	left_shift.device = InputEvent.DEVICE_ID_EMULATION
	left_shift.physical_keycode = KEY_SHIFT
	left_shift.location = KEY_LOCATION_LEFT
	_add_action_with_events(ACTION_LEFT_SHIFT, [left_shift])

	var axis_positive := InputEventJoypadMotion.new()
	axis_positive.device = InputEvent.DEVICE_ID_EMULATION
	axis_positive.axis = JOY_AXIS_TRIGGER_LEFT
	axis_positive.axis_value = 1.0
	_add_action_with_events(ACTION_AXIS_POSITIVE, [axis_positive])

	context.expect_true(
		not module.check_conflict(_key_event(KEY_K)).has(ACTION_CTRL_KEY),
		"Ctrl+K should not conflict with unmodified K"
	)
	context.expect_true(
		module.check_conflict(ctrl_key).has(ACTION_CTRL_KEY),
		"identical Ctrl+K bindings should conflict"
	)

	var right_shift := InputEventKey.new()
	right_shift.device = InputEvent.DEVICE_ID_EMULATION
	right_shift.physical_keycode = KEY_SHIFT
	right_shift.location = KEY_LOCATION_RIGHT
	context.expect_true(
		not module.check_conflict(right_shift).has(ACTION_LEFT_SHIFT),
		"left and right physical Shift bindings should not conflict"
	)
	context.expect_true(
		module.check_conflict(left_shift).has(ACTION_LEFT_SHIFT),
		"identical physical Shift sides should conflict"
	)

	var axis_negative := InputEventJoypadMotion.new()
	axis_negative.device = InputEvent.DEVICE_ID_EMULATION
	axis_negative.axis = JOY_AXIS_TRIGGER_LEFT
	axis_negative.axis_value = -1.0
	context.expect_true(
		not module.check_conflict(axis_negative).has(ACTION_AXIS_POSITIVE),
		"opposite joypad axis directions should not conflict"
	)
	context.expect_true(
		module.check_conflict(axis_positive).has(ACTION_AXIS_POSITIVE),
		"identical joypad axis directions should conflict"
	)

	InputMap.erase_action(ACTION_CTRL_KEY)
	InputMap.erase_action(ACTION_LEFT_SHIFT)
	InputMap.erase_action(ACTION_AXIS_POSITIVE)


# Verifies same-device and wildcard bindings conflict without crossing devices.
func _test_conflicts_respect_device_overlap(context, module: KeybindingModule) -> void:
	_add_action_with_events(
		ACTION_DEVICE_WILDCARD,
		[_joy_button_event(JOY_BUTTON_BACK, InputEvent.DEVICE_ID_EMULATION)]
	)
	_add_action_with_events(
		ACTION_DEVICE_ZERO,
		[_joy_button_event(JOY_BUTTON_BACK, 0)]
	)
	_add_action_with_events(
		ACTION_DEVICE_ONE,
		[_joy_button_event(JOY_BUTTON_BACK, 1)]
	)

	var device_zero_conflicts := module.check_conflict(_joy_button_event(JOY_BUTTON_BACK, 0))
	context.expect_true(
		device_zero_conflicts.has(ACTION_DEVICE_WILDCARD),
		"wildcard binding should conflict with device zero"
	)
	context.expect_true(
		device_zero_conflicts.has(ACTION_DEVICE_ZERO),
		"same joypad device should conflict"
	)
	context.expect_true(
		not device_zero_conflicts.has(ACTION_DEVICE_ONE),
		"different joypad devices should not conflict"
	)

	var device_one_conflicts := module.check_conflict(_joy_button_event(JOY_BUTTON_BACK, 1))
	context.expect_true(
		device_one_conflicts.has(ACTION_DEVICE_WILDCARD),
		"wildcard binding should conflict with device one"
	)
	context.expect_true(
		device_one_conflicts.has(ACTION_DEVICE_ONE),
		"matching device one should conflict"
	)
	context.expect_true(
		not device_one_conflicts.has(ACTION_DEVICE_ZERO),
		"device zero should not conflict with device one"
	)

	InputMap.erase_action(ACTION_DEVICE_WILDCARD)
	InputMap.erase_action(ACTION_DEVICE_ZERO)
	InputMap.erase_action(ACTION_DEVICE_ONE)


# Replaces any stale test action with the requested ordered bindings.
func _add_action_with_events(action: StringName, events: Array) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action)
	for event in events:
		InputMap.action_add_event(action, event)


# Builds a wildcard keyboard binding for concise order and conflict fixtures.
func _key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.device = InputEvent.DEVICE_ID_EMULATION
	event.keycode = keycode
	return event


# Builds a joypad binding on an explicit or wildcard device.
func _joy_button_event(button_index: JoyButton, device: int) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = button_index
	return event


# Returns keyboard keycodes in current InputMap order for observable assertions.
func _event_keycodes(action: StringName) -> Array:
	var keycodes: Array = []
	for event in InputMap.action_get_events(action):
		keycodes.append((event as InputEventKey).keycode)
	return keycodes


# Removes test-owned InputMap actions without touching project bindings.
func _remove_test_actions() -> void:
	for action in TEST_ACTIONS:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
