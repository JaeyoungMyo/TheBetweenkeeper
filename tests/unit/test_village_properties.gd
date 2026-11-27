# U4 PBT: 구매 추첨 개수, 판매 삭제 = 줄 필요 합, 출력공간 잔여 보존
extends TestBase


func _rng(i: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = Pbt.base_seed() + 1000 + i
	return rng


func test_purchase_count_always_matches_config() -> void:
	var pool := [{"item_id": "a", "weight": 5, "price": 1}, {"item_id": "b", "weight": 3, "price": 1}, {"item_id": "c", "weight": 2, "price": 1}]
	for i in Pbt.RUNS:
		var picks := VillageRules.roll_purchases(pool, 4, _rng(i))
		expect(picks.size() == 4, "4 purchases per visit")


func test_sell_removes_exactly_required_and_keeps_rest() -> void:
	for i in Pbt.RUNS:
		var rng := _rng(i)
		var kinds := ["sword", "armor", "ore_box"]
		var quantity := rng.randi_range(2, 12)
		var space := DeliverySpace.new()
		var placed := 0
		for kind in kinds:
			for k in rng.randi_range(0, 6):
				var d := ItemData.new()
				d.item_id = kind
				d.weight = 1
				space.put(ItemInstance.new(placed + 1, d, 1))
				placed += 1
		var lines := QuestRules.build_lines(kinds, quantity, 3, rng)
		var q := Quest.new(lines, 120.0, 0, 0)
		q.start()
		q.apply_counts(space.counts())
		if q.all_complete():
			var taken := space.take(q.consume_plan())
			expect(taken.size() == quantity, "sold = quantity")
			expect(space.size() == placed - quantity, "excess kept")
		else:
			expect(space.size() == placed, "failure keeps all in output")
