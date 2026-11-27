# 운반 개수: 기본 1, 가방 최대 5, 배수 최대 3
extends TestBase


func test_upgrades_reach_fifteen_and_stop() -> void:
	var mgr = load("res://autoload/item_manager.gd").new()
	expect(mgr.capacity() == 2, "default 2")
	for i in 3:
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


## 가방 확장과 증강 2배/3배는 순서와 상관없이 같은 운반 개수가 된다
## 가방 2 → 가방 3 → 2배 = 2배 → 가방 3 (둘 다 6). 최대치까지 모두 같아야 한다
func test_bag_and_multiplier_order_independent() -> void:
	var bag_first = load("res://autoload/item_manager.gd").new()
	bag_first.upgrade_bag()
	bag_first.upgrade_multiplier()
	var mult_first = load("res://autoload/item_manager.gd").new()
	mult_first.upgrade_multiplier()
	mult_first.upgrade_bag()
	expect(bag_first.capacity() == 6, "bag then x2 = 6 (got %d)" % bag_first.capacity())
	expect(bag_first.capacity() == mult_first.capacity(), "bag then x2 == x2 then bag")
	# 최대치까지 순서를 섞어도 같다: 가방 5 · 3배 = 15
	var a = load("res://autoload/item_manager.gd").new()
	var b = load("res://autoload/item_manager.gd").new()
	for i in 3:
		a.upgrade_bag()
	a.upgrade_multiplier()
	a.upgrade_multiplier()
	b.upgrade_multiplier()
	b.upgrade_multiplier()
	for i in 3:
		b.upgrade_bag()
	expect(a.capacity() == 15 and b.capacity() == 15, "max bag 5 x3 = 15 in both orders (%d, %d)" % [a.capacity(), b.capacity()])
	# 가방 구매가 배수 뒤에 와도 한도(10)와 증강 상태는 그대로 유지된다
	var c = load("res://autoload/item_manager.gd").new()
	c.upgrade_multiplier()
	c.upgrade_bag()
	expect(c.bag_size == 3 and c.carry_multiplier == 2, "bag and multiplier keep their own values")


func _prop(v: Array) -> String:
	if v.size() < 2:
		return ""
	var cap := CarryRules.capacity(v[0], v[1])
	if cap < 1 or cap > 15:
		return "out of range"
	if v[0] in range(1, 6) and v[1] in range(1, 4) and cap != v[0] * v[1]:
		return "not product"
	return ""
