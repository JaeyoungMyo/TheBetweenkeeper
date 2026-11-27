# U4 BR-U4-03, 07, 10, 15 (ShopRules, DeliverySpace.take/remove_all, 판매 퀘스트 값 훅)
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
	var kinds := ShopRules.sellable_kinds(items, ["물약"])
	expect(kinds.has("sword") and kinds.has("armor") and kinds.has("ore_box"), "weapons, armor, materials sellable")
	expect(not kinds.has("potion_hp"), "potions excluded")
	expect(not kinds.has("scroll"), "delivered items not counted")


func test_roll_purchases_count_and_pool() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var pool := [{"item_id": "a", "weight": 1, "price": 1}, {"item_id": "b", "weight": 3, "price": 2}]
	var picks := ShopRules.roll_purchases(pool, 4, rng)
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
