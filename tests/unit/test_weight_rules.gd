# BR-U1-01, 02, 09, 10, 11, 16, 17
extends TestBase


func test_exact_fill_with_same_item_combinations() -> void:
	# 칸 한도 12 를 정확히 채울 수 있어야 한다 (사용자 정정, BR-U1-17)
	var combos := [[6, 6], [4, 4, 4], [3, 3, 3, 3], [2, 2, 2, 2, 2, 2], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [6, 4, 2], [4, 3, 3, 2]]
	for combo in combos:
		var fs := FacilityState.new("shelf_basic", 3)
		var ok := true
		for w in combo:
			var item := _carried(1, w)
			if not fs.store(0, item)["ok"]:
				ok = false
		expect(ok, "combo %s should fit exactly in 12" % str(combo))
		expect(WeightRules.total(fs.slot_weights[0]) == 12, "combo %s total should be 12" % str(combo))


func test_overflow_rejected() -> void:
	var fs := FacilityState.new("shelf_basic", 3)
	fs.store(0, _carried(1, 6))
	fs.store(0, _carried(2, 6))
	var r: Dictionary = fs.store(0, _carried(3, 1))
	expect(not r["ok"] and r["reason"] == "slot_overweight", "13 in a 12 slot must be rejected")


func test_invalid_weight_rejected() -> void:
	expect(not WeightRules.is_valid_item_weight(5), "weight 5 is not an allowed item weight")
	expect(WeightRules.is_valid_item_weight(6), "weight 6 is allowed")


func test_weight_class_boundaries() -> void:
	expect(WeightRules.weight_class(1) == "light", "1 is light")
	expect(WeightRules.weight_class(2) == "light", "2 is light")
	expect(WeightRules.weight_class(3) == "medium", "3 is medium")
	expect(WeightRules.weight_class(4) == "medium", "4 is medium")
	expect(WeightRules.weight_class(6) == "heavy", "6 is heavy")


func test_carry_speed_does_not_depend_on_weight() -> void:
	# BR-U1-09: 무게 1 과 6 모두 같은 속도
	expect(WeightRules.carry_speed(180.0, 1) == WeightRules.carry_speed(180.0, 6), "speed must not change with weight")


func test_facility_max_is_36_for_3_slots() -> void:
	var fs := FacilityState.new("shelf_basic", 3)
	expect(fs.max_weight() == 36, "shelf max must be 3 x 12 = 36")


func _data(w: int) -> ItemData:
	var d := ItemData.new()
	d.item_id = "w%d" % w
	d.weight = w
	return d


func _carried(id: int, w: int) -> ItemInstance:
	var item := ItemInstance.new(id, _data(w), 1)
	item.state = ItemInstance.State.CARRIED
	return item
