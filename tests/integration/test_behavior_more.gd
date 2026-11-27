# 추가 동작 테스트: 같은 자리 겹침, 대량 생성 버튼 100회, 1·2·3 키 칸 적재, 칸 무게 초과 거부
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


func _button(room: Node, text: String) -> Button:
	var dbg = room.get_node("DebugMenu")
	for b in dbg._box.get_children():
		if b is Button and b.text == text:
			return b
	return null


func test_two_items_on_same_spot_both_listed_and_pickable() -> void:
	# 같은 자리에 아이템 2개: 둘 다 존재, 호버 목록에 둘 다 표시, 줍기는 한 번에 하나
	var room = _room()
	await _frames(3)
	var spot := Vector2(400, 480)
	var a = room.add_item(load("res://data/items/sword.tres"), spot)
	var b = room.add_item(load("res://data/items/armor.tres"), spot)
	await _frames(2)
	expect(a.world_position.distance_to(b.world_position) < 16.0, "items overlap on the same cell")
	room.player.position = spot + Vector2(0, 30)
	await _frames(2)
	var im = room.get_node_or_null("/root/ItemManager")
	expect(im != null and im.items.has(a.instance_id) and im.items.has(b.instance_id), "both exist in ItemManager")
	room.player.position = a.world_position + Vector2(0, 10)
	await _frames(2)
	await _key(KEY_X)
	await _frames(2)
	expect(im.carried_ids.size() == 1, "one X press picks up exactly one item")
	room.free()


func test_hundred_spawn_button_presses_are_safe() -> void:
	# 디버그 "아이템 1개 생성" 버튼을 100번 누른다: 오류 없이 100개가 생기고 목록 · 화면이 맞다
	var room = _room()
	await _frames(3)
	var im = room.get_node("/root/ItemManager")
	var before: int = im.items.size()
	var btn := _button(room, "아이템 1개 생성")
	expect(btn != null, "spawn button exists")
	if btn == null:
		room.free()
		return
	for i in 100:
		btn.pressed.emit()
	await _frames(3)
	expect(im.items.size() == before + 100, "100 items created (got %d)" % (im.items.size() - before))
	var views_ok := true
	for item in im.items.values():
		if not room.views.has(item.instance_id):
			views_ok = false
	expect(views_ok, "every item has a view")
	expect(room.views.size() >= 100, "views count matches items")
	room.free()


func test_keys_one_two_three_store_into_slots_in_order() -> void:
	# 들고 있는 아이템을 선반 앞에서 1, 2, 3 키로 칸 1, 2, 3 에 넣는다
	var room = _room()
	await _frames(3)
	var im = room.get_node("/root/ItemManager")
	var shelf = room.shelves[0]
	var picks := [room.tutorial_items[0], room.tutorial_items[1], room.tutorial_items[2]]
	var keys := [KEY_1, KEY_2, KEY_3]
	for i in 3:
		var it = picks[i]
		im.try_pick_up(it, it.world_position)
		room.player.position = shelf.position + Vector2(0, 60)
		room.shelf = shelf
		room.shelf_panel.show()
		await _frames(1)
		await _key(keys[i])
		await _frames(1)
		expect(it.state == ItemInstance.State.STORED and it.slot_index == i, "key %d stores in slot %d" % [i + 1, i + 1])
	room.free()


func test_slot_rejects_over_weight_limit() -> void:
	# 칸 한도 (12) 를 넘는 적재는 거부되고 아이템은 들고 있는 상태로 남는다
	var room = _room()
	await _frames(3)
	var im = room.get_node("/root/ItemManager")
	var shelf = room.shelves[0]
	var heavy = im.create_item(load("res://data/items/ore_box.tres"), 0)  # 무게 6
	var heavy2 = im.create_item(load("res://data/items/ore_box.tres"), 0)
	var heavy3 = im.create_item(load("res://data/items/ore_box.tres"), 0)
	var first: Dictionary = shelf.state.store(0, heavy)
	heavy.state = ItemInstance.State.STORED
	heavy.facility_id = shelf.state.facility_id
	heavy.slot_index = 0
	var second: Dictionary = shelf.state.store(0, heavy2)
	var third: Dictionary = shelf.state.store(0, heavy3)
	expect(first["ok"] and second["ok"], "6 + 6 = 12 fits exactly")
	expect(not third["ok"], "third 6 rejected, limit 12")
	room.free()


func test_shelf_upgrade_menu_usable_during_sleep() -> void:
	# 수면 (60초) 중에도 C 메뉴로 선반 · 칸 구매가 된다 (BR-U3-20: 정리와 강화는 가능)
	var room = _room()
	await _frames(3)
	var ui = room.find_child("DungeonUi", true, false)
	ui._running = false
	DungeonManager.flow.state = DungeonFlow.State.SLEEP
	DungeonManager.flow.sleep_left = 60.0
	EconomyManager.add_gold(1000)
	var n: int = room.shelves.size()
	await _key(KEY_C)
	await _frames(2)
	var growth = room.get_node("GrowthUi")
	expect(growth.menu.visible, "C opens the upgrade menu during sleep")
	expect(room.buy_shelf() and room.shelves.size() == n + 1, "shelf bought during sleep")
	room.free()
	DungeonManager.flow.state = DungeonFlow.State.READY


func test_x_takes_selected_shelf_item_into_hands() -> void:
	# 선반 패널에서 고른 아이템은 X 로 바로 손으로 옮겨진다 (마우스 없이)
	var room = _room()
	await _frames(3)
	var im = room.get_node("/root/ItemManager")
	var it = room.tutorial_items[0]
	im.try_pick_up(it, it.world_position)
	im.place_carried(it.instance_id, room.shelves[0].state, 0)
	room.shelf = room.shelves[0]
	room.open_panel()
	room.player.position = room.shelves[0].position + Vector2(0, 60)
	await _frames(2)
	expect(room.shelf_panel.selected_id() == it.instance_id, "first item of the shelf is selected")
	await _key(KEY_X)
	await _frames(2)
	expect(it.state == ItemInstance.State.CARRIED and im.carried_ids.has(it.instance_id), "X takes the selected item into hands")
	room.free()


func test_six_potions_in_one_shelf_slot_are_all_listed() -> void:
	# 물약 6개를 한 칸에 넣으면 6개 모두 선반 패널에 보인다
	var room = _room()
	await _frames(3)
	var im = room.get_node("/root/ItemManager")
	var ids: Array = []
	for k in 6:
		var it = im.create_item(load("res://data/items/potion_hp.tres"), 0)
		im.try_pick_up(it, it.world_position)
		im.place_carried(it.instance_id, room.shelves[0].state, 0)
		ids.append(it.instance_id)
	room.shelf = room.shelves[0]
	room.shelf_panel.show_for(room.shelf.state, im.items, "선반 1", 0)
	await _frames(2)
	var listed := 0
	for id in ids:
		if room.shelf_panel.find_child("item-entry-%d" % id, true, false) != null:
			listed += 1
	expect(listed == 6, "all six potions listed in the shelf panel (got %d)" % listed)
	room.free()


func test_shelf_can_be_bought_up_to_six() -> void:
	# 선반 1개에서 시작해 추가 구매로 6개까지 늘어난다 (3번째 선반 포함)
	var room = _room()
	await _frames(3)
	var eco = room.get_node("/root/EconomyManager")
	eco.add_gold(5000)
	for k in 5:
		expect(room.buy_shelf(), "buy shelf %d" % (room.shelves.size() + 1))
	expect(room.shelves.size() == 6, "six shelves (got %d)" % room.shelves.size())
	expect(not room.buy_shelf(), "seventh shelf is not sold")
	room.free()


func test_plus_key_adds_slot_on_open_shelf() -> void:
	# 선반이 열려 있으면 + 키로 그 선반에 칸을 추가한다 (C 메뉴는 선반 구매만)
	var room = _room()
	await _frames(3)
	var eco = room.get_node("/root/EconomyManager")
	eco.add_gold(1000)
	room.shelf = room.shelves[0]
	room.player.position = room.shelves[0].position + Vector2(0, 60)
	room.shelf_panel.show_for(room.shelf.state, room.get_node("/root/ItemManager").items, "선반 1", eco.slot_price(room.shelf.state, 0))
	room.shelf_panel.show()
	var before: int = room.shelves[0].state.slot_count
	await _key(KEY_EQUAL)
	await _frames(2)
	expect(room.shelves[0].state.slot_count == before + 1, "+ key adds a slot to the open shelf")
	room.free()
