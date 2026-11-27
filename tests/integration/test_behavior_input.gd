# 동작 테스트 (헤드리스): 실제 입력 이벤트 (키보드 · 마우스) 를 뷰포트에 넣어 게임 씬을 조작한다
extends TestBase

var tree: SceneTree


func _key(keycode: Key) -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = keycode
		ev.physical_keycode = keycode
		ev.pressed = pressed
		tree.root.push_input(ev)
		await tree.process_frame


func _click(pos: Vector2) -> void:
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = pos
		ev.global_position = pos
		tree.root.push_input(ev)
		await tree.process_frame


func _frames(n: int) -> void:
	for i in n:
		await tree.process_frame


func _room() -> Node:
	var room = load("res://scenes/storage/tutorial_storage.tscn").instantiate()
	tree.root.add_child(room)
	return room


func test_keyboard_pickup_and_store_in_slot() -> void:
	# X 로 주운 아이템을 선반 앞에서 숫자 키로 칸에 넣는다
	var room = _room()
	await _frames(3)
	var target = room.tutorial_items[0]
	room.player.position = target.world_position + Vector2(0, 20)
	await _frames(2)
	await _key(KEY_X)
	await _frames(2)
	expect(ItemManager.carried_ids.has(target.instance_id), "X picks up nearby item")
	room.player.position = room.shelves[0].position + Vector2(0, 60)
	await _frames(2)
	await _key(KEY_X)
	expect(room.shelf_panel.visible, "X in front of shelf opens panel")
	await _key(KEY_1)
	expect(target.state == ItemInstance.State.STORED, "key 1 stores carried item in slot 1")
	room.free()


func test_drop_key_puts_item_on_floor() -> void:
	# Z 는 들고 있는 맨 위 아이템을 발 아래 바닥에 내려놓는다
	var room = _room()
	await _frames(3)
	var target = room.tutorial_items[1]
	room.player.position = target.world_position + Vector2(0, 20)
	await _frames(2)
	await _key(KEY_X)
	await _frames(2)
	await _key(KEY_Z)
	await _frames(2)
	expect(target.state == ItemInstance.State.INCOMING and not ItemManager.carried_ids.has(target.instance_id), "Z drops to floor")
	room.free()


func test_menu_keys_open_and_close() -> void:
	# F1 디버그 메뉴, F2 설정 패널 토글
	var room = _room()
	await _frames(3)
	var debug = room.get_node("DebugMenu")
	await _key(KEY_F1)
	await _frames(2)
	expect(debug.panel.visible, "F1 opens debug menu")
	await _key(KEY_F1)
	await _frames(2)
	expect(not debug.panel.visible, "F1 closes debug menu")
	var settings = room.get_node("SettingsPanel")
	await _key(KEY_F2)
	await _frames(2)
	expect(settings._panel.visible, "F2 opens settings")
	await _key(KEY_F2)
	await _frames(2)
	expect(not settings._panel.visible, "F2 closes settings")
	room.free()


func test_click_walks_player_to_point() -> void:
	# 빈 바닥 클릭은 플레이어를 그 지점으로 보낸다
	var room = _room()
	await _frames(3)
	var goal := Vector2(420, 300)
	await _click(goal)
	var guard := 0
	while room.player.has_target() and guard < 600:
		await _frames(1)
		guard += 1
	expect(room.player.position.distance_to(goal) < 6, "walked to clicked point")
	room.free()


func test_delivery_shelf_z_moves_one_item_not_floor() -> void:
	# 전달 선반 근처에서 Z 는 들고 있는 아이템 1개를 선반에 넣는다 (바닥에 내려놓지 않음)
	var room = _room()
	await _frames(3)
	var ui = room.find_child("DungeonUi", true, false)
	var a = room.tutorial_items[2]
	var b = room.tutorial_items[3]
	ItemManager.try_pick_up(a, a.world_position)
	ItemManager.try_pick_up(b, b.world_position)
	var shelf_pos: Vector2 = ui.DELIVERY_SHELF.get_center()
	room.player.position = shelf_pos + Vector2(0, -30)
	await _frames(2)
	var before: int = DungeonManager.delivery.size()
	await _key(KEY_Z)
	await _frames(2)
	expect(DungeonManager.delivery.size() == before + 1, "Z moves exactly one item to the delivery shelf")
	expect(ItemManager.carried_ids.size() == 1, "one item still carried")
	expect(not ui.DELIVERY_SHELF.has_point(a.world_position), "item was not dropped on the floor")
	room.free()
