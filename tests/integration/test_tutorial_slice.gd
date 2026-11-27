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


func test_tutorial_lesson_one_with_keys_then_finish_marks_done() -> void:
	# 1단계 (적재) 를 실제 키 입력으로 끝낸다. 튜토리얼 완료 표시는 설정 파일에 남는다
	SaveService.delete_save()
	var room = load("res://scenes/storage/tutorial_storage.tscn").instantiate()
	room.auto_return = false
	tree.root.add_child(room)
	await tree.process_frame
	var shelf = room.shelves[0]
	var front: Vector2 = shelf.position + Vector2(0, 60)
	for i in room.tutorial_items.size():
		var it = room.tutorial_items[i]
		room.player.position = it.world_position + Vector2(0, 8)
		await tree.process_frame
		await _key(KEY_X)
		room.player.position = front
		await tree.process_frame
		if not room.shelf_panel.visible:
			await _key(KEY_X)
		await _key(KEY_1 if i < 4 else KEY_2)
	expect(room._all_stored(), "all five stored by keys")
	await tree.process_frame
	expect(room._step >= 6, "lesson 1 done, lesson 2 started (step %d)" % room._step)
	expect(EconomyManager.pending_choices == 0 and not tree.paused, "no augment choice during lesson 1")
	room._finish_tutorial()
	expect(SaveService.tutorial_done_saved(), "tutorial completion is saved")
	room.free()
