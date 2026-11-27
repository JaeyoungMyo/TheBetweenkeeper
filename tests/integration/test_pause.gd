# 일시정지: P 키로 멈춤 · 재개, 레벨업으로 멈춘 상태는 건드리지 않음
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


func test_p_key_pauses_and_resumes() -> void:
	var room = load("res://scenes/storage/tutorial_storage.tscn").instantiate()
	tree.root.add_child(room)
	await tree.process_frame
	await _key(KEY_P)
	expect(tree.paused, "P pauses the game")
	await _key(KEY_P)
	expect(not tree.paused, "P resumes the game")
	room.free()


func test_pause_does_not_override_level_up_pause() -> void:
	var room = load("res://scenes/storage/tutorial_storage.tscn").instantiate()
	tree.root.add_child(room)
	await tree.process_frame
	tree.paused = true  # 레벨업 증강 선택으로 멈춘 상태
	var pm = room.get_node("PauseMenu")
	pm.toggle()
	expect(tree.paused and not pm._user_paused, "P does not resume a level-up pause")
	tree.paused = false
	room.free()
