# U3 Step 15~16 화면 연결 (헤드리스): 던전 1 을 화면 흐름으로 끝까지 진행하면 상점 호출은 정확히 한 번
extends TestBase

var tree: SceneTree


func test_dungeon_ui_runs_to_shop_handoff() -> void:
	var room = load("res://scenes/storage/tutorial_storage.tscn").instantiate()
	tree.root.add_child(room)
	var ui = room.find_child("DungeonUi", true, false)
	expect(ui != null, "DungeonUi attached to storage room")
	if ui == null:
		room.free()
		return
	ui.start_run()
	expect(DungeonManager.flow.state == DungeonFlow.State.IN_BATTLE, "first battle started")
	var guard := 0
	while DungeonManager.flow.state != DungeonFlow.State.SHOP_HANDOFF and guard < 5000:
		ui._process(0.1)
		DungeonManager._process(0.1)
		guard += 1
	expect(DungeonManager.flow.state == DungeonFlow.State.SHOP_HANDOFF, "reaches shop handoff")
	ui._process(3.0)
	expect(ui._shop_active, "shop opens after the visit message")
	expect(DungeonManager.flow.shop_handoffs == 1, "shop handoff exactly once")
	expect(not DungeonManager.failures.is_game_over(), "no game over without quests")
	tree.root.remove_child(room)
	room.free()
