# 추가 동작 테스트: 같은 자리 겹침, 대량 생성 버튼 100회, 1·2·3 키 칸 적재, 칸 무게 초과 거부
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
	var spot := Vector2(600, 200)
	var a = room.add_item(load("res://data/items/sword.tres"), spot)
	var b = room.add_item(load("res://data/items/armor.tres"), spot)
	await _frames(2)
	expect(a.world_position.distance_to(b.world_position) < 16.0, "items overlap on the same cell")
	var under: Array = room.items_under(a.world_position)
	expect(under.size() == 2, "hover lists both overlapping items (got %d)" % under.size())
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
