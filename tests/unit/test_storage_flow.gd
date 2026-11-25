# BR-U1-04, 05, 06, 07, 12, 13 / FD-U1-4, 5, 6
extends TestBase


func test_pick_up_then_store_sets_stored() -> void:
	var mgr = load("res://autoload/item_manager.gd").new()
	var item = mgr.create_item(_data(2), 1)
	expect(mgr.try_pick_up(item, Vector2.ZERO), "pick up at distance 0 must succeed")
	expect(item.state == ItemInstance.State.CARRIED, "picked item must be carried")
	var fs := FacilityState.new("shelf_basic", 3)
	var r: Dictionary = mgr.place_carried(item.instance_id, fs, 0, Vector2(100, 100))
	expect(r["ok"], "store 2 into empty slot must succeed")
	expect(item.state == ItemInstance.State.STORED, "stored item must be STORED")
	expect(fs.total_weight() == 2, "shelf total should be 2")


func test_default_capacity_is_one() -> void:
	var mgr = load("res://autoload/item_manager.gd").new()
	var a = mgr.create_item(_data(1), 1)
	var b = mgr.create_item(_data(1), 1)
	expect(mgr.try_pick_up(a, Vector2.ZERO), "first pick must succeed")
	expect(not mgr.try_pick_up(b, Vector2.ZERO), "second pick while holding must fail")


func test_pickup_range_48() -> void:
	var item := _incoming(1, 3, Vector2(48, 0))
	expect(StorageService.can_pick_up(item, Vector2.ZERO, true), "distance 48 must be pickable")
	var far := _incoming(2, 3, Vector2(49, 0))
	expect(not StorageService.can_pick_up(far, Vector2.ZERO, true), "distance 49 must not be pickable")


func test_overweight_drops_at_feet_as_incoming() -> void:
	var mgr = load("res://autoload/item_manager.gd").new()
	var fs := FacilityState.new("shelf_basic", 3)
	var a = mgr.create_item(_data(6), 1)
	var b = mgr.create_item(_data(6), 1)
	var c = mgr.create_item(_data(1), 1)
	mgr.try_pick_up(a, Vector2.ZERO)
	mgr.place_carried(a.instance_id, fs, 0, Vector2.ZERO)
	mgr.try_pick_up(b, Vector2.ZERO)
	mgr.place_carried(b.instance_id, fs, 0, Vector2.ZERO)
	mgr.try_pick_up(c, Vector2.ZERO)
	var feet := Vector2(10, 20)
	var r: Dictionary = mgr.place_carried(c.instance_id, fs, 0, feet)
	expect(not r["ok"], "1 into a full-12 slot must be rejected")
	expect(c.state == ItemInstance.State.INCOMING, "rejected item must be INCOMING")
	expect(c.world_position == feet, "rejected item must land at player's feet")


func test_drop_on_map_goes_to_feet() -> void:
	var mgr = load("res://autoload/item_manager.gd").new()
	var item = mgr.create_item(_data(3), 1)
	mgr.try_pick_up(item, Vector2.ZERO)
	mgr.drop_carried_at(item.instance_id, Vector2(200, 300))
	expect(item.state == ItemInstance.State.INCOMING, "dropped item must be INCOMING")
	expect(item.world_position == Vector2(200, 300), "dropped item must be at feet")
	expect(mgr.carried_ids.is_empty(), "hand must be empty after drop")


func test_duplicate_store_rejected() -> void:
	var fs := FacilityState.new("shelf_basic", 3)
	var item := _incoming(1, 2, Vector2.ZERO)
	item.state = ItemInstance.State.STORED
	var r: Dictionary = fs.store(0, item)
	expect(not r["ok"], "already stored item must not be stored again")


func test_take_out_removes_from_total() -> void:
	var mgr = load("res://autoload/item_manager.gd").new()
	var fs := FacilityState.new("shelf_basic", 3)
	var item = mgr.create_item(_data(4), 1)
	mgr.try_pick_up(item, Vector2.ZERO)
	mgr.place_carried(item.instance_id, fs, 1, Vector2.ZERO)
	expect(fs.total_weight() == 4, "total should be 4 after store")
	expect(mgr.take_out(item, fs), "take out must succeed")
	expect(fs.total_weight() == 0, "total should be 0 after take out")
	expect(item.state == ItemInstance.State.CARRIED, "taken item must be carried")


func _data(w: int) -> ItemData:
	var d := ItemData.new()
	d.item_id = "w%d" % w
	d.weight = w
	return d


func _incoming(id: int, w: int, pos: Vector2) -> ItemInstance:
	var item := ItemInstance.new(id, _data(w), 1)
	item.world_position = pos
	return item
