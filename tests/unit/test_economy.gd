# US-09, US-10, US-22 예시 테스트
extends TestBase


func _eco():
	return load("res://autoload/economy_manager.gd").new()


func _item(w: int) -> ItemInstance:
	var d := ItemData.new()
	d.item_id = "x"
	d.weight = w
	return ItemInstance.new(1, d, 0)


func test_exp_once_per_item_and_level_up() -> void:
	var e = _eco()
	var it := _item(6)
	expect(e.grant_exp(it) and e.exp_points == 30, "6 x 5 = 30")
	expect(not e.grant_exp(it) and e.exp_points == 30, "no repeat")
	e.grant_exp(_item(4))
	expect(e.level == 2 and e.exp_points == 0 and e.pending_choices == 1, "exactly 50 levels up")
	expect(e.exp_to_next() == 75, "next 75")
	e.free()


func test_augments_apply() -> void:
	var e = _eco()
	var m = load("res://autoload/item_manager.gd").new()
	expect(not e.choose_augment("carry", m), "needs a pending choice")
	e.pending_choices = 20
	expect(e.choose_augment("carry", m) and e.choose_augment("carry", m), "carry x2")
	expect(m.capacity() == 3 and not e.choose_augment("carry", m), "x3 max")
	e.choose_augment("exp", m)
	e.choose_augment("sell", m)
	e.grant_exp(_item(6))
	expect(e.exp_points == 36, "exp +20%")
	expect(e.sell_price(_item(6).data) == 66, "sell +10%")
	e.free()
	m.free()


func test_purchases_and_gold_shortage() -> void:
	var e = _eco()
	var m = load("res://autoload/item_manager.gd").new()
	var fs := FacilityState.new("s", 3)
	expect(e.gold() == 100 and not e.buy_shelf(1) and e.gold() == 100, "shortage keeps gold")
	expect(e.buy_bag(m) and m.bag_size == 2 and e.gold() == 0, "bag 100")
	e.add_gold(5000)
	for i in 3:
		expect(e.buy_slot(fs), "slot")
	expect(fs.slot_count == 6 and fs.max_weight() == 72 and not e.buy_slot(fs), "6 slots max")
	expect(e.gold() == 4400, "100+200+300")
	for i in 3:
		expect(e.buy_bag(m), "bag")
	expect(m.bag_size == 5 and not e.buy_bag(m) and e.gold() == 3000, "bag max 5")
	expect(not e.buy_shelf(4) and e.buy_shelf(3), "max 4 shelves")
	e.free()
	m.free()


func test_sell_removes_item_once() -> void:
	var e = _eco()
	var m = load("res://autoload/item_manager.gd").new()
	var fs := FacilityState.new("s", 3)
	var it = m.create_item(_item(4).data, 0)
	m.try_pick_up(it, Vector2.ZERO)
	m.place_carried(it.instance_id, fs, 0)
	expect(e.sell(it, m, fs) and e.gold() == 140, "4 x 10")
	expect(it.state == ItemInstance.State.SOLD and fs.total_weight() == 0, "gone")
	expect(not e.sell(it, m, fs) and e.gold() == 140, "no double sale")
	e.free()
	m.free()
