# 바닥 한 칸 최대 10개, 선반에서 바닥으로 떨어뜨리기
extends TestBase


func _mgr_item(mgr, w := 1):
	var d := ItemData.new()
	d.item_id = "x"
	d.weight = w
	return mgr.create_item(d, 0)


func test_eleventh_goes_to_neighbor() -> void:
	var mgr = load("res://autoload/item_manager.gd").new()
	var feet := Vector2(100, 100)
	for i in 11:
		var it = _mgr_item(mgr)
		it.state = ItemInstance.State.CARRIED
		mgr.carried_ids.append(it.instance_id)
		mgr.drop_carried_at(it.instance_id, feet)
		expect((FloorRules.cell_of(it.world_position) == FloorRules.cell_of(feet)) == (i < 10), "item %d" % i)
	mgr.free()


func test_drop_stored_works_with_full_hands() -> void:
	var mgr = load("res://autoload/item_manager.gd").new()
	var fs := FacilityState.new("s", 3)
	var a = _mgr_item(mgr, 4)
	mgr.try_pick_up(a, Vector2.ZERO)
	mgr.place_carried(a.instance_id, fs, 0, Vector2.ZERO)
	var b = _mgr_item(mgr)
	mgr.try_pick_up(b, Vector2.ZERO)
	expect(mgr.drop_stored(a, fs, Vector2(9, 9)), "drop from shelf")
	expect(a.state == ItemInstance.State.INCOMING and a.world_position == Vector2(9, 9), "on floor")
	expect(fs.total_weight() == 0 and mgr.carried_ids == [b.instance_id], "shelf empty, hand unchanged")
	expect(not mgr.drop_stored(a, fs, Vector2.ZERO), "not stored: refused")
	mgr.free()


func test_prop_never_over_ten_and_in_bounds() -> void:
	var err := Pbt.check(func(r): return range(r.randi_range(0, 120)).map(func(_i): return Vector2(r.randf_range(1, 159), r.randf_range(1, 159))), _prop)
	expect(err == "", err)


func _prop(points: Array) -> String:
	var counts := {}
	var bounds := Rect2(0, 0, 160, 160)
	var blocked := [Rect2(64, 64, 32, 32)]
	for p in points:
		if blocked[0].has_point(p):
			continue
		var out := FloorRules.resolve(p, counts, bounds, blocked)
		var cell := FloorRules.cell_of(out)
		counts[cell] = counts.get(cell, 0) + 1
		if counts[cell] > 10:
			return "over 10"
		if not bounds.has_point(out) or blocked[0].has_point(out):
			return "outside floor"
	return ""
