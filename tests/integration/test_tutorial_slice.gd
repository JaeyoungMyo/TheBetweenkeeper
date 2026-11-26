# US-01: 실제 튜토리얼 씬에서 10개를 모두 적재하면 완료된다 (AC-01-1, AC-01-3)
extends TestBase

var tree: SceneTree


func test_tutorial_scene_completes() -> void:
	var room = load("res://scenes/storage/tutorial_storage.tscn").instantiate()
	tree.root.add_child(room)
	var mgr = tree.root.get_node("ItemManager")
	expect(room.tutorial_items.size() == 10, "10 items")
	var slots := {1: 0, 2: 0, 3: 0, 4: 1, 6: 2}
	for item in room.tutorial_items:
		expect(not room.completed, "not complete early")
		expect(mgr.try_pick_up(item, item.world_position), "pick")
		expect(room.list_panel.find_child("item-entry-%d" % item.instance_id, true, false) != null, "shown in list")
		expect(mgr.place_carried(item.instance_id, room.shelf.state, slots[item.weight()])["ok"], "place %s" % item.data.item_id)
	expect(room.shelf.state.total_weight() == 36, "shelf exactly full")
	expect(room.completed, "tutorial completed")
	var eco = tree.root.get_node("EconomyManager")
	var ui = room.get_node("GrowthUi")
	expect(eco.level == 3 and eco.exp_points == 55, "36 x 5 = 180 EXP")
	expect(tree.paused and ui.choice_panel.visible, "level up pauses for a choice")
	ui.pick("speed")
	expect(tree.paused and eco.pending_choices == 1, "second choice follows")
	ui.pick("speed")
	expect(not tree.paused and is_equal_approx(room.player.current_speed(), 216.0), "resumes, +20% speed")
	eco.add_gold(1000)
	room.player.position = room.SHELF_POSITIONS[1]
	ui.toggle_menu()
	expect(room.shelves.size() == 3, "starts with 3 shelves")
	expect(room.buy_shelf() and room.shelves.size() == 4, "fourth shelf bought")
	expect(not room.shelves[3].bounds().has_point(room.player.position), "player moved out")
	room.interact()
	room.shelf = room.shelves[0]
	ui.toggle_menu()
	room.player.position = Vector2(610, 400)
	room.toggle_shelf()
	expect(not room.shelf_panel.visible, "far from shelf: stays closed")
	room.player.position = room.shelf.position + Vector2(0, 60)
	room.interact()
	expect(room.shelf_panel.visible, "X in front of shelf opens")
	room.interact()
	expect(not room.shelf_panel.visible, "X closes")
	# 바닥에 겹친 아이템: X 로 줍기가 선반 열기보다 우선, 호버 목록은 전부 표시
	var a = room.tutorial_items[0]
	var b = room.tutorial_items[1]
	for it in [a, b]:
		expect(mgr.take_out(it, room.shelf.state), "take out")
		mgr.drop_carried_at(it.instance_id, room.player.feet_position())
	expect(room.items_under(a.world_position).size() == 2, "hover lists both stacked items")
	expect(ItemListPanel.describe([a, b]).split("
").size() == 2, "two lines")
	room.interact()
	expect(mgr.carried_ids.size() == 1 and not room.shelf_panel.visible, "X picks up first")
	room.interact()
	expect(room.shelf_panel.visible, "hands full: X opens shelf")
	var gold_before: int = eco.gold()
	room.buy_current_slot()
	expect(room.shelves[0].state.slot_count == 4 and room.shelves[1].state.slot_count == 3, "only this shelf grows")
	expect(eco.gold() == gold_before - 50, "shelf 1 slot costs 50")
	var dbg = room.get_node("DebugMenu")
	var before: int = room.views.size()
	dbg.spawn(10)
	expect(room.views.size() == before + 10, "debug spawn")
	dbg.clear_floor()
	expect(mgr.items.values().all(func(it): return it.state != ItemInstance.State.INCOMING), "debug clear")
	var lv: int = eco.level
	eco.add_exp(eco.exp_to_next() - eco.exp_points)
	expect(eco.level == lv + 1 and tree.paused, "debug level up")
	ui.pick("sell")
	var c = room.tutorial_items[5]
	room.drop_to_floor(c.instance_id)
	expect(c.state == ItemInstance.State.INCOMING and room.shelf_panel.visible, "shelf item dropped to floor, panel stays")
	var held = mgr.items[mgr.carried_ids[0]]
	room.shelf_panel.hide()
	room.store_in_slot(0)
	expect(held.state == ItemInstance.State.CARRIED, "number key ignored while closed")
	room.toggle_shelf()
	room.store_in_slot(0)
	expect(held.state == ItemInstance.State.STORED and held.slot_index == 0, "key 1 stores in slot 1")
	room.store_in_slot(1)
	expect(mgr.carried_ids.is_empty(), "empty hand is safe")
	for n in [1, 2, 3]:
		expect(InputMap.has_action("slot_%d" % n), "key %d bound" % n)
	room.drop_first()
	expect(mgr.take_out(held, room.shelf.state), "take out again")
	room.drop_first()
	expect(held.state == ItemInstance.State.INCOMING and held.world_position == room.player.feet_position(), "Z drops at feet")
	expect(InputMap.has_action("drop_item"), "Z bound")
	# 운반배수: 2배만 → 보유 후 3배만 → 이후 나오지 않음
	for step in ["운반배수 2배", "운반배수 3배", ""]:
		var seen := {}
		for i in 60:
			eco.pending_choices = 1
			ui.show_choices()
			for btn in ui._choice_box.get_children():
				if btn.text.begins_with("운반배수"):
					seen[btn.text] = true
		expect(seen.keys() == ([step] if step != "" else []), "expected '%s' got %s" % [step, seen.keys()])
		if step != "":
			ui.pick("carry")
	eco.pending_choices = 0
	ui.show_choices()
	mgr.carry_multiplier = 1
	eco.augments.clear()
	room.free()
