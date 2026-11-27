# U3 BR-U3-05, 06, 09~13 (Quest, DeliverySpace)
extends TestBase


func _item(kind: String, id: int) -> ItemInstance:
	var d := ItemData.new()
	d.item_id = kind
	d.weight = 1
	return ItemInstance.new(id, d, 1)


func _quest(limit: float = 30.0) -> Quest:
	var q := Quest.new([
		{"item_kind": "potion_hp", "required": 3},
		{"item_kind": "antidote", "required": 1},
	], limit, 10, 5)
	q.start()
	return q


func test_line_counts_capped_at_required() -> void:
	var q := _quest()
	q.apply_counts({"potion_hp": 1})
	expect(int(q.lines[0]["delivered"]) == 1, "1 of 3 delivered")
	q.apply_counts({"potion_hp": 4})
	expect(int(q.lines[0]["delivered"]) == 3, "capped at 3 (BR-09)")
	expect(not q.all_complete(), "antidote missing")
	expect(q.is_line_complete(0) and not q.is_line_complete(1), "completed line marked")


func test_unrelated_items_do_not_count() -> void:
	var q := _quest()
	q.apply_counts({"sword": 5})
	expect(int(q.lines[0]["delivered"]) == 0 and int(q.lines[1]["delivered"]) == 0, "wrong kind ignored (BR-11)")


func test_success_consumes_only_required_and_keeps_excess() -> void:
	var q := _quest()
	var space := DeliverySpace.new()
	for i in 4:
		space.put(_item("potion_hp", i + 1))
	space.put(_item("antidote", 10))
	q.apply_counts(space.counts())
	expect(q.all_complete(), "all lines complete")
	var removed := space.consume(q.consume_plan())
	expect(removed == 4, "4 removed = 3 + 1")
	expect(space.counts().get("potion_hp", 0) == 1, "1 excess potion stays (BR-12)")
	expect(space.counts().get("antidote", 0) == 0, "antidote consumed")


func test_failure_keeps_every_delivered_item() -> void:
	var q := _quest()
	var space := DeliverySpace.new()
	space.put(_item("potion_hp", 1))
	space.put(_item("potion_hp", 2))
	q.apply_counts(space.counts())
	expect(not q.all_complete(), "not complete")
	expect(space.size() == 2, "nothing removed without success (BR-13)")


func test_timeout_marks_time_up() -> void:
	var q := _quest(30.0)
	expect(not q.tick(29.9), "not yet")
	expect(q.tick(0.2), "time up at 30s")


func test_delivered_items_cannot_be_sold_state() -> void:
	var item := _item("potion_hp", 1)
	DeliverySpace.new().put(item)
	expect(item.state == ItemInstance.State.DELIVERED, "state DELIVERED (BR-23)")
