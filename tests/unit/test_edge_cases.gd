# 경계값 · 상태 가드 · 저장 형식 검사 (조사 결과 반영)
extends TestBase


func test_shelf_price_out_of_range_is_minus_one() -> void:
	expect(EconomyManager.shelf_price(0) == -1, "0 shelves: no price (not the last entry)")
	expect(EconomyManager.shelf_price(99) == -1, "beyond table: no price")


func test_slot_price_covers_six_shelves_and_rejects_out_of_range() -> void:
	var f := FacilityState.new("shelf_x", 3)
	expect(EconomyManager.slot_price(f, 4) > 0, "5th shelf has slot prices")
	expect(EconomyManager.slot_price(f, 5) > 0, "6th shelf has slot prices")
	expect(EconomyManager.slot_price(f, 6) == -1, "7th shelf: no slot price")
	expect(EconomyManager.slot_price(f, -1) == -1, "negative index: no price")


func test_bag_price_bounds() -> void:
	var items := ItemManager
	var saved: int = items.bag_size
	items.bag_size = 0
	expect(EconomyManager.bag_price(items) == -1, "bag size 0: no price")
	items.bag_size = saved


func test_sell_price_falls_back_to_weight_when_no_base() -> void:
	var d := ItemData.new()
	d.weight = 4
	d.base_price = 0
	expect(EconomyManager.sell_price(d) == 40, "weight x 10 when base_price is 0")


func test_exp_negative_gain_changes_nothing() -> void:
	var r := ExpCalculator.apply(1, 10, -5, 50, 25)
	expect(r["level"] == 1 and r["exp"] == 10 and r["gained"] == 0, "negative gain ignored")


func test_pending_choices_survive_save_restore() -> void:
	ItemManager.reset_run()
	EconomyManager.reset_run()
	EconomyManager.pending_choices = 2
	var d := SaveData.capture([], "dungeon_clear", true, 0)
	EconomyManager.reset_run()
	SaveData.restore(d)
	expect(EconomyManager.pending_choices == 2, "pending augment choices kept")
	EconomyManager.reset_run()


func test_empty_inventory_roundtrip() -> void:
	ItemManager.reset_run()
	EconomyManager.reset_run()
	var d := SaveCodec.decode(SaveCodec.encode(SaveData.capture([], "shop_clear", true, 1)))
	expect(SaveData.is_valid(d), "valid save")
	SaveData.restore(d)
	expect(ItemManager.items.is_empty() and ItemManager._next_id == 1, "no items, ids start at 1")


func test_sold_items_are_not_saved() -> void:
	ItemManager.reset_run()
	var d_item := ItemData.new()
	d_item.item_id = "sword"
	d_item.weight = 3
	var it := ItemInstance.new(1, load("res://data/items/sword.tres"), 1)
	it.state = ItemInstance.State.SOLD
	ItemManager.items[1] = it
	var d := SaveData.capture([], "dungeon_clear", true, 0)
	expect((d["items"] as Array).is_empty(), "sold item not in save")
	ItemManager.reset_run()


func test_invalid_save_rejected_by_format_check() -> void:
	expect(not SaveData.is_valid({}), "empty rejected")
	expect(not SaveData.is_valid({"version": 9}), "wrong version rejected")
	var d := SaveData.capture([], "dungeon_clear", true, 0)
	d.erase("gold")
	expect(not SaveData.is_valid(d), "missing key rejected")


func test_flow_guards_ignore_calls_in_wrong_state() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var flow := DungeonFlow.new()
	flow.start(1, rng)
	flow.begin_battle()
	var idx := flow.battle_index
	expect(flow.begin_battle() == 0 and flow.battle_index == idx, "begin_battle ignored while fighting")
	flow.finish_battle()
	flow.begin_sleep()
	var before := flow.state
	var r := flow.finish_battle()
	expect(not bool(r["completed"]) and flow.state == before, "finish_battle ignored while sleeping")


func test_spawn_battles_caps_at_battle_count() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var picks := DungeonRules.spawn_battles(3, 6, rng)
	expect(picks.size() == 3, "at most one quest per battle")
	expect(picks == [1, 2, 3], "all battles, sorted, no duplicates")


func test_quest_tick_ignored_when_not_active() -> void:
	var q := Quest.new([{"item_kind": "a", "required": 1}], 30.0, 0, 0)
	expect(not q.tick(100.0) and q.remaining == 0.0, "pending quest does not tick")
	q.start()
	q.status = Quest.Status.SUCCESS
	expect(not q.tick(100.0), "finished quest does not time out")


func test_dungeon_one_fixed_intake_and_quest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var flow := DungeonFlow.new()
	flow.start(1, rng)
	flow.begin_battle()
	var r := flow.finish_battle()
	expect((r["fixed_kinds"] as Array).size() == 5 and r["intake"] == 5, "battle 1 intake is the fixed list")
	expect(flow.quest_spec().has("fixed_lines"), "dungeon 1 quest has fixed lines")
	expect(flow.quest_battles == [2], "fixed quest at battle 2")


func test_tutorial_choices_disabled_gives_no_augment() -> void:
	EconomyManager.reset_run()
	EconomyManager.choices_enabled = false
	EconomyManager.add_exp(60)
	expect(EconomyManager.level == 2 and EconomyManager.pending_choices == 0, "level up without augment choice")
	EconomyManager.reset_run()
