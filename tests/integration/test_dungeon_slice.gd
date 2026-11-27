# U3 던전 1 슬라이스 (헤드리스): 전투 → 입고 → 퀘스트 → 완료 → 수면 → 상점 호출 1회 (BR-U3-22)
extends TestBase


func _item(kind: String, id: int) -> ItemInstance:
	var d := ItemData.new()
	d.item_id = kind
	d.weight = 1
	return ItemInstance.new(id, d, 1)


func test_dungeon_one_full_flow_without_scene() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var flow := DungeonFlow.new()
	var space := DeliverySpace.new()
	var quests := QuestController.new(space)
	var failures := FailureCounter.new()
	var kinds := ["potion_hp", "antidote"]
	flow.start(1, rng)
	expect(flow.state == DungeonFlow.State.READY, "starts READY")

	var intake_total := 0
	var quests_seen := 0
	var completed := false
	while not completed:
		var due := flow.begin_battle()
		for i in due:
			quests_seen += 1
			var spawn := quests.spawn(flow.quest_spec(), kinds, rng)
			expect(spawn["status"] == "started", "quest started")
			# 퀘스트 줄 요구량만큼 전달 공간에 올린다
			for l in quests.quest.lines:
				for k in int(l["required"]):
					space.put(_item(l["item_kind"], 1000 + k))
			var r := quests.on_delivery_changed()
			expect(r.get("result") == "success", "quest succeeds after delivery")
		var fin := flow.finish_battle()
		intake_total += int(fin["intake"])
		completed = bool(fin["completed"])

	expect(flow.battle_index == flow.battle_total, "all battles fought")
	expect(intake_total >= 4 * flow.battle_total and intake_total <= 8 * flow.battle_total, "intake 4..8 per battle")
	expect(quests_seen == 1, "dungeon 1 has 1 quest")
	expect(flow.state == DungeonFlow.State.DUNGEON_COMPLETE, "dungeon complete")
	expect(not quests.is_active(), "no active quest after completion")

	flow.begin_sleep()
	expect(not flow.tick_sleep(59.0), "still sleeping at 59s")
	expect(flow.tick_sleep(1.0), "sleep over at 60s")
	expect(flow.state == DungeonFlow.State.SHOP_HANDOFF and flow.shop_handoffs == 1, "shop handoff exactly once")
	expect(not failures.is_game_over(), "no failures")
