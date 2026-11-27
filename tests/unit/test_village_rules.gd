# U4 BR-U4-03, 07, 10, 15 (VillageRules, DeliverySpace.take/remove_all, 판매 퀘스트 값 훅)
extends TestBase


func _item(kind: String, category: String, state: ItemInstance.State, id: int) -> ItemInstance:
	var d := ItemData.new()
	d.item_id = kind
	d.category = category
	d.weight = 1
	var it := ItemInstance.new(id, d, 1)
	it.state = state
	return it


func test_sellable_excludes_potions_and_delivered() -> void:
	var items := [
		_item("potion_hp", "물약", ItemInstance.State.STORED, 1),
		_item("sword", "무기", ItemInstance.State.STORED, 2),
		_item("armor", "방어구", ItemInstance.State.INCOMING, 3),
		_item("ore_box", "재료", ItemInstance.State.CARRIED, 4),
		_item("scroll", "주문서", ItemInstance.State.DELIVERED, 5),
	]
	var kinds := VillageRules.sellable_kinds(items, ["물약"])
	expect(kinds.has("sword") and kinds.has("armor") and kinds.has("ore_box"), "weapons, armor, materials sellable")
	expect(not kinds.has("potion_hp"), "potions excluded")
	expect(not kinds.has("scroll"), "delivered items not counted")


func test_roll_purchases_count_and_pool() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var pool := [{"item_id": "a", "weight": 1, "price": 1}, {"item_id": "b", "weight": 3, "price": 2}]
	var picks := VillageRules.roll_purchases(pool, 4, rng)
	expect(picks.size() == 4, "4 picks")
	for p in picks:
		expect(p["item_id"] == "a" or p["item_id"] == "b", "pick from pool")


func test_take_returns_only_required_and_keeps_excess() -> void:
	var space := DeliverySpace.new()
	for i in 4:
		space.put(_item("potion_hp", "물약", ItemInstance.State.INCOMING, 10 + i))
	var taken := space.take({"potion_hp": 3})
	expect(taken.size() == 3, "3 taken")
	expect(space.size() == 1, "1 excess stays")


func test_remove_all_empties_output() -> void:
	var space := DeliverySpace.new()
	space.put(_item("sword", "무기", ItemInstance.State.INCOMING, 1))
	space.put(_item("armor", "방어구", ItemInstance.State.INCOMING, 2))
	var all := space.remove_all()
	expect(all.size() == 2 and space.size() == 0, "all removed from output")


func test_sell_lines_never_exceed_stock() -> void:
	var items := [
		_item("sword", "무기", ItemInstance.State.STORED, 1),
		_item("sword", "무기", ItemInstance.State.INCOMING, 2),
		_item("armor", "방어구", ItemInstance.State.STORED, 3),
		_item("potion_hp", "물약", ItemInstance.State.STORED, 4),
		_item("helmet", "방어구", ItemInstance.State.DELIVERED, 5),
	]
	var stock := VillageRules.sellable_stock(items, ["물약"])
	expect(stock == {"sword": 2, "armor": 1}, "stock counts only owned sellable items")
	var rng := RandomNumberGenerator.new()
	for seed in 20:
		rng.seed = seed
		var lines := VillageRules.sell_lines(stock, 12, 3, rng)
		var total := 0
		for l: Dictionary in lines:
			expect(stock.has(l["item_kind"]), "only owned kinds are requested")
			expect(int(l["required"]) <= int(stock[l["item_kind"]]), "required never exceeds stock")
			total += int(l["required"])
		expect(total == 3, "total is capped by stock (2 + 1)")
	expect(VillageRules.sell_lines({}, 12, 3, rng).is_empty(), "no stock: no lines (quest skipped)")


func test_wake_up_skips_sleep() -> void:
	var flow := DungeonFlow.new()
	flow.begin_sleep()
	flow.wake_up()
	expect(flow.tick_sleep(0.0), "wake up ends sleep on the next tick")
	expect(flow.state == DungeonFlow.State.VILLAGE_HANDOFF, "goes to village handoff")
