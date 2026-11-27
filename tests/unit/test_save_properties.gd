# U5 PBT: 저장 · 복원 10회 왕복에서 아이템 수와 상태가 같다 (NFR-03, BR-U5-08)
extends TestBase


func _rng(i: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = Pbt.base_seed() + 2000 + i
	return rng


func _snapshot() -> Array:
	var out := []
	for item: ItemInstance in ItemManager.items.values():
		out.append([item.instance_id, item.data.item_id, item.state, item.slot_index])
	out.sort_custom(func(a, b) -> bool: return a[0] < b[0])
	return out


func test_ten_roundtrips_keep_items_identical() -> void:
	var kinds := ["potion_hp", "scroll", "sword", "dagger", "axe", "helmet", "shield", "boots", "armor", "ore_box"]
	for i in 20:
		var rng := _rng(i)
		ItemManager.reset_run()
		EconomyManager.reset_run()
		for k in rng.randi_range(1, 40):
			var item := ItemManager.create_item(load("res://data/items/%s.tres" % kinds[rng.randi_range(0, kinds.size() - 1)]), 0)
			item.state = [ItemInstance.State.INCOMING, ItemInstance.State.STORED][rng.randi_range(0, 1)]
			item.world_position = Vector2(rng.randf_range(0, 900), rng.randf_range(0, 600))
		var before := _snapshot()
		for r in 10:
			var text := SaveCodec.encode(SaveData.capture([], "dungeon_clear", true, 0))
			var d := SaveCodec.decode(text)
			SaveData.restore(d)
		expect(_snapshot() == before, "items identical after 10 roundtrips (case %d)" % i)
