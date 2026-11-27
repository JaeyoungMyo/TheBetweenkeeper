# 튜토리얼 (US-01, 5개): 아이템 위치 · 선반 거리, 숫자 키로 넣기와 꺼내기, 단계 안내 구성
extends TestBase

var tree: SceneTree


func test_tutorial_pieces() -> void:
	SaveService.delete_save()
	var room = load("res://scenes/storage/tutorial_storage.tscn").instantiate()
	tree.root.add_child(room)
	await tree.process_frame
	expect(room.tutorial_items.size() == 5, "tutorial has 5 items")
	var shelf_center: Vector2 = room.shelves[0].position
	for it in room.tutorial_items:
		expect(it.world_position.distance_to(shelf_center) < 260.0, "item placed near the shelf")
	var im = room.get_node("/root/ItemManager")
	var slots := [0, 0, 0, 1, 1]
	for i in room.tutorial_items.size():
		var it = room.tutorial_items[i]
		im.try_pick_up(it, it.world_position)
		expect(im.place_carried(it.instance_id, room.shelves[0].state, slots[i])["ok"], "store %s" % it.data.item_id)
	expect(room._all_stored(), "all five stored")
	room.shelf_panel.show()
	room.store_in_slot(0)
	expect(room.take_out_count == 1 and im.carried_ids.size() == 1, "key 1 with empty hands takes the top item out")
	room.store_in_slot(0)
	expect(room.take_out_count == 1 and room.tutorial_items.all(func(it): return it.state == ItemInstance.State.STORED), "key 1 while carrying stores it back")
	room.store_in_slot(2)
	expect(room.take_out_count == 1, "empty slot with empty hands does nothing")
	expect(room._steps.size() >= 12, "step-by-step guide is built")
	room.free()


func _key(k: Key) -> void:
	for p in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = k
		ev.physical_keycode = k
		ev.pressed = p
		Input.parse_input_event(ev)
		await tree.process_frame
		await tree.process_frame


## 레벨업 증강 선택이 떠 있으면 (게임이 일시정지) 하나씩 고른다
func _resolve_levelups(room) -> void:
	var growth = room.get_node("GrowthUi")
	var ids := ["speed", "exp", "sell", "carry"]
	var k := 0
	while tree.paused or EconomyManager.pending_choices > 0:
		growth.pick(ids[k % ids.size()])
		k += 1
		await tree.process_frame


func test_tutorial_guide_end_to_end_with_keys() -> void:
	# 안내 단계를 실제 키 입력으로 끝까지 진행한다: 줍기 → 선반 열기 → 1 키 넣기 → 꺼내기 → 다시 넣기 → 설명 → 던전 1
	SaveService.delete_save()
	var room = load("res://scenes/storage/tutorial_storage.tscn").instantiate()
	tree.root.add_child(room)
	await tree.process_frame
	var shelf = room.shelves[0]
	var front: Vector2 = shelf.position + Vector2(0, 60)
	for i in room.tutorial_items.size():
		var it = room.tutorial_items[i]
		room.player.position = it.world_position + Vector2(0, 8)
		await tree.process_frame
		await _key(KEY_X)  # 줍기
		room.player.position = front
		await tree.process_frame
		if not room.shelf_panel.visible:
			await _key(KEY_X)  # 선반 열기
		await _key(KEY_1 if i < 4 else KEY_2)  # 칸에 넣기
		await _resolve_levelups(room)
	expect(room._all_stored(), "all five stored by keys")
	await tree.process_frame
	expect(room._step >= 6, "guide moved past storing steps (step %d)" % room._step)
	if not room.shelf_panel.visible:
		await _key(KEY_X)
	await _resolve_levelups(room)
	await _key(KEY_1)  # 손이 비어 있으니 꺼내기
	expect(room.take_out_count == 1, "key 1 with empty hands takes out")
	await _key(KEY_1)  # 다시 넣기
	await _resolve_levelups(room)
	expect(room._all_stored(), "stored again")
	await tree.process_frame
	expect(room._step >= 8, "guide reached the explanation pages (step %d)" % room._step)
	for i in 4:
		room._on_guide_next()
	await tree.process_frame
	expect(room.completed and not room._guide_running, "guide finished")
	var ui = room.find_child("DungeonUi", true, false)
	expect(DungeonManager.flow.state == DungeonFlow.State.IN_BATTLE, "dungeon 1 started after the tutorial")
	room.free()
