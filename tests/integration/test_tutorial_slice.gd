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
	# 숫자 키는 꺼내지 않는다: 손이 비어 있으면 아무것도 꺼내지 않고 안내만 한다
	room.store_in_slot(0)
	expect(room.take_out_count == 0 and im.carried_ids.is_empty(), "key 1 with empty hands does not take out")
	# 꺼내기는 ←→ 로 고르고 X (= 선택 아이템 꺼내기)
	room.open_panel()
	room._on_take_out(room.shelf_panel.selected_id())
	expect(room.take_out_count == 1 and im.carried_ids.size() == 1, "selected item taken out")
	room.store_in_slot(0)
	expect(room.take_out_count == 1 and room.tutorial_items.all(func(it): return it.state == ItemInstance.State.STORED), "key 1 while carrying stores it back")
	room.store_in_slot(2)
	expect(room.take_out_count == 1, "empty slot with empty hands does nothing")
	expect(room._steps.size() >= 12, "step-by-step guide is built")
	room.free()


func test_tutorial_refills_missing_shelf_item() -> void:
	# 선반에 회복약이 없어도 긴급 퀘스트 단계에서 바닥의 회복약을 선반에 넣어 채운다 (새로 만들지 않는다)
	SaveService.delete_save()
	var room = load("res://scenes/storage/tutorial_storage.tscn").instantiate()
	tree.root.add_child(room)
	await tree.process_frame
	var im = room.get_node("/root/ItemManager")
	expect(not room._stored_kind("potion_hp"), "potion starts off the shelf")
	room._ensure_on_shelf("potion_hp")
	expect(room._stored_kind("potion_hp"), "missing potion is put on the shelf")
	var total := 0
	for id in im.items:
		if im.items[id].data.item_id == "potion_hp":
			total += 1
	expect(total == 1, "no duplicate potion created (total %d)" % total)
	room._ensure_on_shelf("potion_hp")
	expect(im.carried_ids.is_empty(), "already on shelf: nothing happens")
	room.free()


func test_tutorial_shelf_close_step_waits_for_close() -> void:
	# 선반 닫기 단계: 열린 뒤 닫혀야 통과한다 (처음부터 닫혀 있으면 통과하지 않는다)
	SaveService.delete_save()
	var room = load("res://scenes/storage/tutorial_storage.tscn").instantiate()
	room.auto_return = false
	tree.root.add_child(room)
	await tree.process_frame
	room._guide_running = true
	room._steps = room._build_steps()
	var idx := -1
	for i in room._steps.size():
		if "선반을 닫아 볼까요" in room._steps[i]["text"]:
			idx = i
	expect(idx >= 0, "shelf close step exists")
	room._step = idx
	room._show_step()
	expect(not room._steps[idx]["check"].call(), "closed shelf does not pass the close step")
	room.shelf_panel.show()
	expect(not room._steps[idx]["check"].call(), "open shelf does not pass yet")
	room.shelf_panel.hide()
	expect(room._steps[idx]["check"].call(), "closing the open shelf passes the close step")
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
			await _key(KEY_E)
		await _key(KEY_1 if i < 4 else KEY_2)
	expect(room._all_stored(), "all five stored by keys")
	await tree.process_frame
	expect(room._step >= 6, "lesson 1 done, lesson 2 started (step %d)" % room._step)
	expect(EconomyManager.pending_choices == 0 and not tree.paused, "no augment choice during lesson 1")
	room._finish_tutorial()
	expect(SaveService.tutorial_done_saved(), "tutorial completion is saved")
	room.free()


func test_tutorial_quest_panel_shows_when_quest_starts() -> void:
	# 튜토리얼 중 긴급 퀘스트가 나오면 패널이 바로 보인다
	SaveService.delete_save()
	var room = load("res://scenes/storage/tutorial_storage.tscn").instantiate()
	room.auto_return = false
	tree.root.add_child(room)
	await tree.process_frame
	var it = room.tutorial_items[0]
	ItemManager.try_pick_up(it, it.world_position)
	ItemManager.place_carried(it.instance_id, room.shelves[0].state, 0)
	room._spawn_potion_quest()
	expect(room.tutorial_items[0].data.item_id == "potion_hp", "tutorial quest needs the potion")
	var ui = room.find_child("DungeonUi", true, false)
	ui._process(0.1)
	expect(ui._quest_box.visible, "quest panel visible during the tutorial")
	DungeonManager.quests.quest = null
	room.free()
