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
	expect(room.buy_shelf() and room.shelves.size() == 2, "second shelf")
	expect(not room.shelves[1].bounds().has_point(room.player.position), "player moved out")
	room.interact()
	expect(room.shelf == room.shelves[1] and room.shelf_panel.visible, "new shelf opens")
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
	room.free()
