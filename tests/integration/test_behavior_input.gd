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
	# F1 디버그 메뉴, ESC 메뉴 토글
	var room = _room()
	await _frames(3)
	var debug = room.get_node("DebugMenu")
	await _key(KEY_F1)
	await _frames(2)
	expect(debug.panel.visible, "F1 opens debug menu")
	await _key(KEY_F1)
	await _frames(2)
	expect(not debug.panel.visible, "F1 closes debug menu")
	# 설정은 메뉴 (P · ESC) 안에 있다. F2 는 더 이상 쓰지 않는다
	await _key(KEY_ESCAPE)
	await _frames(2)
	expect(room.get_node("PauseMenu")._overlay.visible, "ESC opens the menu")
	await _key(KEY_ESCAPE)
	await _frames(2)
	expect(not room.get_node("PauseMenu")._overlay.visible, "ESC closes the menu")
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
	# 숫자 키는 넣기만 하고, 꺼내기는 패널에서 ←→ 로 고른 뒤 X 로 한다
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
	await _key(KEY_X)
	await _frames(2)
	expect(im.carried_ids.has(it.instance_id), "X takes the selected shelf item")
	expect(shelf.state.slot_items[0].is_empty(), "slot empty after X take-out")
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
	# ←→ 는 선택된 칸 안의 아이템을 고르고, ↑↓ 는 같은 선반의 칸 1 ↔ 칸 N 을 옮긴다
	var room = _room()
	await _frames(3)
	var im = room.get_node("/root/ItemManager")
	var shelf0 = room.shelves[0]
	var a = room.tutorial_items[0]
	var b = room.tutorial_items[1]
	var c = room.tutorial_items[2]
	im.try_pick_up(a, a.world_position)
	im.place_carried(a.instance_id, shelf0.state, 0)
	im.try_pick_up(b, b.world_position)
	im.place_carried(b.instance_id, shelf0.state, 0)
	im.try_pick_up(c, c.world_position)
	im.place_carried(c.instance_id, shelf0.state, 1)
	room.player.position = shelf0.position + Vector2(0, 60)
	room.shelf = shelf0
	room.open_panel()
	room.shelf_panel.reset_selection()
	await _frames(1)
	expect(room.shelf_panel.selected_id() == a.instance_id, "slot 1 first item is selected")
	await _key(KEY_RIGHT)
	await _frames(1)
	expect(room.shelf_panel.selected_id() == b.instance_id, "RIGHT moves to the next item in the slot")
	await _key(KEY_RIGHT)
	await _frames(1)
	expect(room.shelf_panel.selected_id() == a.instance_id, "RIGHT wraps inside the slot, not into slot 2")
	await _key(KEY_DOWN)
	await _frames(1)
	expect(room.shelf == shelf0, "DOWN stays on the same shelf")
	expect(room.shelf_panel.selected_slot() == 1 and room.shelf_panel.selected_id() == c.instance_id, "DOWN moves to slot 2")
	await _key(KEY_DOWN)
	await _frames(1)
	expect(room.shelf_panel.selected_slot() == 2 and room.shelf_panel.selected_id() == -1, "empty slot 3 has no item")
	await _key(KEY_DOWN)
	await _frames(1)
	expect(room.shelf_panel.selected_slot() == 0, "DOWN on the last slot wraps to slot 1")
	await _key(KEY_UP)
	await _frames(1)
	expect(room.shelf_panel.selected_slot() == 2, "UP on slot 1 wraps to the last slot")
	room.free()

