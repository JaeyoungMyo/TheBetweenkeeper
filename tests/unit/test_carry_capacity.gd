# 운반 개수: 기본 1, 가방 최대 5, 배수 최대 3
extends TestBase


func test_upgrades_reach_fifteen_and_stop() -> void:
	var mgr = load("res://autoload/item_manager.gd").new()
	expect(mgr.capacity() == 1, "default 1")
	for i in 4:
		expect(mgr.upgrade_bag(), "bag up")
	expect(mgr.capacity() == 5 and not mgr.upgrade_bag(), "bag max 5")
	expect(mgr.upgrade_multiplier() and mgr.capacity() == 10, "x2")
	expect(mgr.upgrade_multiplier() and mgr.capacity() == 15, "x3")
	expect(not mgr.upgrade_multiplier(), "max x3")
	for i in 16:
		var d := ItemData.new()
		d.item_id = "x"
		var item = mgr.create_item(d, 0)
		expect(mgr.try_pick_up(item, Vector2.ZERO) == (i < 15), "pick %d" % i)
	mgr.free()


func test_prop_capacity_bounds_and_product() -> void:
	var err := Pbt.check(func(r): return [r.randi_range(-2, 8), r.randi_range(-2, 6)], _prop)
	expect(err == "", err)


func _prop(v: Array) -> String:
	if v.size() < 2:
		return ""
	var cap := CarryRules.capacity(v[0], v[1])
	if cap < 1 or cap > 15:
		return "out of range"
	if v[0] in range(1, 6) and v[1] in range(1, 4) and cap != v[0] * v[1]:
		return "not product"
	return ""
