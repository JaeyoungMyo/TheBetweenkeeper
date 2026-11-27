# 키보드 전용: 마우스 클릭은 버튼을 누르지 못하고, 일시정지 메뉴는 키보드 포커스 · Enter 로 동작한다
extends TestBase

var tree: SceneTree


func _key(k: Key) -> void:
	for p in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = k
		ev.physical_keycode = k
		ev.pressed = p
		Input.parse_input_event(ev)
		await tree.process_frame
		await tree.process_frame


func _click_at(pos: Vector2) -> void:
	for p in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.position = pos
		ev.global_position = pos
		ev.pressed = p
		Input.parse_input_event(ev)
		await tree.process_frame
		await tree.process_frame


func test_mouse_click_does_not_press_buttons() -> void:
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	tree.root.add_child(holder)
	var b := Button.new()
	b.position = Vector2(100, 100)
	b.size = Vector2(200, 60)
	holder.add_child(b)
	var pressed := [0]
	b.pressed.connect(func() -> void: pressed[0] += 1)
	await tree.process_frame
	await _click_at(Vector2(180, 130))
	expect(pressed[0] == 0, "mouse click does not press a button (got %d)" % pressed[0])
	holder.free()


func test_pause_menu_is_keyboard_operated() -> void:
	# P 로 일시정지하면 "계속하기" 에 포커스가 가고, Enter 로 다시 시작한다
	var room = load("res://scenes/storage/tutorial_storage.tscn").instantiate()
	room.auto_return = false
	tree.root.add_child(room)
	await tree.process_frame
	await _key(KEY_P)
	await tree.process_frame
	expect(tree.paused, "P pauses the game")
	var pause = room.get_node("PauseMenu")
	await tree.process_frame
	expect(pause._resume_button.has_focus(), "resume button has keyboard focus")
	await _key(KEY_ENTER)
	await tree.process_frame
	expect(not tree.paused, "Enter on the focused resume button resumes the game")
	tree.paused = false
	room.free()
