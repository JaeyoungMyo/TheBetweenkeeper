# U4 상점 흐름 (헤드리스): 판매 성공 · 실패, 구매 골드 부족, 출력공간 잔여 이동
extends TestBase

var _placed: Array = []


func _place(item: ItemInstance) -> void:
	_placed.append(item)


func _store(kind: String, id: int, category: String) -> ItemInstance:
	var data := load("res://data/items/%s.tres" % kind) as ItemData
	var item := ItemManager.create_item(data, 0)
	item.state = ItemInstance.State.STORED
	return item


func test_sell_success_then_buy_and_leftovers_move_to_map() -> void:
	ItemManager.reset_run()
	EconomyManager.reset_run()
	_placed = []
	for i in 14:
		_store("sword", i, "무기")
	var space := DeliverySpace.new()
	var flow := VillageFlow.new(space, Callable(self, "_place"))
	var gold_before := EconomyManager.gold()
	var exp_before := EconomyManager.exp_points
	flow.open()
	expect(flow.state == VillageFlow.State.SELL and flow.quests.is_active(), "sell quest active")
	var line: Dictionary = flow.quests.quest.lines[0]
	for k in int(line["required"]):
		var it := ItemManager.create_item(load("res://data/items/sword.tres"), 0)
		it.state = ItemInstance.State.DELIVERED
		space.put(it)
	var extra := ItemManager.create_item(load("res://data/items/sword.tres"), 0)
	extra.state = ItemInstance.State.DELIVERED
	space.put(extra)
	flow.on_output_changed()
	expect(flow.state == VillageFlow.State.DONE, "village finished after sale and buys")
	expect(EconomyManager.gold() > gold_before - 200, "gold changed by sale and purchases")
	expect(EconomyManager.exp_points >= exp_before + 80 or EconomyManager.level > 1, "sale gives 80 exp")
	expect(_placed.size() >= 1, "leftover excess and purchases placed on map")


func test_sell_timeout_keeps_no_gold_and_moves_output_to_map() -> void:
	ItemManager.reset_run()
	EconomyManager.reset_run()
	_placed = []
	for i in 3:
		_store("armor", i, "방어구")
	var space := DeliverySpace.new()
	var flow := VillageFlow.new(space, Callable(self, "_place"))
	flow.open()
	var one := ItemManager.create_item(load("res://data/items/armor.tres"), 0)
	one.state = ItemInstance.State.DELIVERED
	space.put(one)
	var gold_before := EconomyManager.gold()
	var guard := 0
	while flow.state == VillageFlow.State.SELL and guard < 5000:
		flow.tick(0.1)
		guard += 1
	expect(flow.state == VillageFlow.State.DONE, "village ends after timeout")
	expect(space.size() == 0, "output emptied")
	expect(_placed.has(one), "undelivered output item moved to map")
	expect(one.state == ItemInstance.State.INCOMING, "moved item is incoming")
	expect(EconomyManager.gold() <= gold_before, "no sale gold on failure (only purchases)")


func test_purchase_skipped_when_gold_short() -> void:
	ItemManager.reset_run()
	EconomyManager.reset_run()
	EconomyManager.spend_gold(EconomyManager.gold())
	_placed = []
	var space := DeliverySpace.new()
	var flow := VillageFlow.new(space, Callable(self, "_place"))
	var gold_before := EconomyManager.gold()
	flow.open()
	var guard := 0
	while flow.state == VillageFlow.State.SELL and guard < 5000:
		flow.tick(0.1)
		guard += 1
	expect(flow.state == VillageFlow.State.DONE, "village done")
	expect(_placed.size() == 0 and EconomyManager.gold() == gold_before, "no gold, no items when poor")
