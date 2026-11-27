# 동작 테스트 (헤드리스): 실제 입력 이벤트 (키보드 · 마우스) 를 뷰포트에 넣어 게임 씬을 조작한다
extends TestBase

var tree: SceneTree


func _key(keycode: Key) -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = keycode
		ev.physical_keycode = keycode
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await tree.process_frame
		await tree.process_frame


func _click(pos: Vector2) -> void:
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = pos
		ev.global_position = pos
		Input.parse_input_event(ev)
		await tree.process_frame
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
	await _key(KEY_E)
	expect(room.shelf_panel.visible, "E in front of shelf opens panel")
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
	# 헤드리스에서는 마우스 위치가 없어서 GUI 입력 대신 맵 클릭 처리를 직접 호출한다 (화면 클릭은 TEST.md 에서 확인)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = goal
	room._on_map_input(ev)
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


func test_enter_takes_selected_shelf_item() -> void:
	# 숫자 키는 넣기만 하고, 꺼내기는 패널에서 ↑↓ 로 고른 뒤 Enter 로 한다
	var room = _room()
	await _frames(3)
	var im = room.get_node("/root/ItemManager")
	var shelf = room.shelves[0]
	var it = room.tutorial_items[0]
	im.try_pick_up(it, it.world_position)
	room.player.position = shelf.position + Vector2(0, 60)
	room.shelf = shelf
	room.open_panel()
	await _frames(1)
	await _key(KEY_1)
	await _frames(1)
	expect(shelf.state.slot_items[0].size() == 1, "1 key stores into slot 1")
	expect(im.carried_ids.is_empty(), "hands empty after storing")
	await _key(KEY_1)
	await _frames(1)
	expect(im.carried_ids.is_empty(), "number key with empty hands does not take out")
	room.open_panel()
	await _frames(1)
	await _key(KEY_ENTER)
	await _frames(2)
	expect(im.carried_ids.has(it.instance_id), "Enter takes the selected shelf item")
	expect(shelf.state.slot_items[0].is_empty(), "slot empty after Enter take-out")
	room.free()


func test_only_e_closes_shelf() -> void:
	# 선반 닫기는 E 로만 한다. X 는 열린 패널을 닫지 않는다
	var room = _room()
	await _frames(3)
	var shelf = room.shelves[0]
	room.player.position = shelf.position + Vector2(0, 60)
	room.shelf = shelf
	room.open_panel()
	await _frames(1)
	await _key(KEY_X)
	await _frames(1)
	expect(room.shelf_panel.visible, "X does not close the shelf")
	await _key(KEY_E)
	await _frames(1)
	expect(not room.shelf_panel.visible, "E closes the shelf")
	room.free()


func test_arrows_move_items_in_slot_and_switch_shelves() -> void:
	# ←→ 는 같은 칸 안에서 아이템을 고르고, ↑↓ 는 앞뒤 선반으로 포커스를 옮긴다
	var room = _room()
	await _frames(3)
	room.add_shelf()
	var im = room.get_node("/root/ItemManager")
	var shelf0 = room.shelves[0]
	var a = room.tutorial_items[0]
	var b = room.tutorial_items[1]
	im.try_pick_up(a, a.world_position)
	im.place_carried(a.instance_id, shelf0.state, 0)
	im.try_pick_up(b, b.world_position)
	im.place_carried(b.instance_id, shelf0.state, 0)
	room.player.position = shelf0.position + Vector2(0, 60)
	room.shelf = shelf0
	room.open_panel()
	await _frames(1)
	var first: int = room.shelf_panel.selected_id()
	expect(first == a.instance_id or first == b.instance_id, "first item of slot 1 is selected")
	await _key(KEY_RIGHT)
	await _frames(1)
	expect(room.shelf_panel.selected_id() != first, "RIGHT moves to the next item in the slot")
	await _key(KEY_RIGHT)
	await _frames(1)
	expect(room.shelf_panel.selected_id() != first, "RIGHT stops at the end of the slot")
	await _key(KEY_LEFT)
	await _frames(1)
	expect(room.shelf_panel.selected_id() == first, "LEFT moves back")
	await _key(KEY_DOWN)
	await _frames(1)
	expect(room.shelf == room.shelves[1], "DOWN focuses the next shelf")
	expect(room.shelf_panel.visible, "panel stays open when switching shelves")
	await _key(KEY_UP)
	await _frames(1)
	expect(room.shelf == shelf0, "UP focuses the previous shelf")
	room.free()

