# U3 PBT (속성 기반 테스트). 시드 고정 무작위 생성, Pbt.RUNS 회 반복
extends TestBase


func _rng(i: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = Pbt.base_seed() + i
	return rng


func test_intake_always_in_range() -> void:
	for i in Pbt.RUNS:
		var n := DungeonRules.roll_intake(_rng(i), 4, 8)
		expect(n >= 4 and n <= 8, "intake in 4..8")


func test_battle_count_always_in_range() -> void:
	for i in Pbt.RUNS:
		var n := DungeonRules.roll_battle_count(_rng(i), 3, 5)
		expect(n >= 3 and n <= 5, "N in 3..5")


func test_delivery_success_removes_exactly_required() -> void:
	for i in Pbt.RUNS:
		var rng := _rng(i)
		var kinds := ["a", "b", "c"]
		var quantity := rng.randi_range(2, 10)
		var lines := QuestRules.build_lines(kinds, quantity, 3, rng)
		var q := Quest.new(lines, 30.0, 0, 0)
		q.start()
		var space := DeliverySpace.new()
		var placed := 0
		for kind in kinds:
			var n := rng.randi_range(0, 6)
			for k in n:
				var d := ItemData.new()
				d.item_id = kind
				space.put(ItemInstance.new(placed + 1, d, 1))
				placed += 1
		q.apply_counts(space.counts())
		for l in q.lines:
			expect(int(l["delivered"]) <= int(l["required"]), "delivered never exceeds required (BR-09)")
		if q.all_complete():
			var removed := space.consume(q.consume_plan())
			expect(removed == quantity, "removed = Q (%d)" % quantity)
			expect(space.size() == placed - quantity, "excess kept (BR-12)")
		else:
			expect(space.size() == placed, "failure keeps all (BR-13)")
