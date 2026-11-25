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
		expect(mgr.place_carried(item.instance_id, room.shelf.state, slots[item.weight()], Vector2.ZERO)["ok"], "place %s" % item.data.item_id)
	expect(room.shelf.state.total_weight() == 36, "shelf exactly full")
	expect(room.completed, "tutorial completed")
	room.shelf_panel.show_for(room.shelf.state, mgr.items)
	expect(room.shelf_panel.visible, "panel opens")
	room.free()
