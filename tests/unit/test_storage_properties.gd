# 속성 기반 테스트 (PBT-03, 05, 06). 예시 기반 테스트는 다른 파일에 있다
extends TestBase


func test_prop_total_matches_oracle_and_order_free() -> void:
	var err := Pbt.check(func(r): return Pbt.gen_weights(r), _total_prop)
	expect(err == "", err)


func test_prop_stateful_commands_match_model() -> void:
	var err := Pbt.check(func(r): return Pbt.gen_commands(r), _run_model)
	expect(err == "", err)


func test_shrinker_finds_minimal_input() -> void:
	var err := Pbt.check(func(r): return Pbt.gen_weights(r), func(ws: Array) -> String: return "has 6" if 6 in ws else "")
	expect("minimal=[6]" in err and "seed=" in err, "shrinker must reduce to [6]: " + err)


func _total_prop(ws: Array) -> String:
	var rev := ws.duplicate()
	rev.reverse()
	var oracle: int = ws.reduce(func(a, b): return a + b, 0)
	return "" if WeightRules.total(ws) == oracle and WeightRules.total(rev) == oracle else "total mismatch"


func _run_model(cmds: Array) -> String:
	var mgr = load("res://autoload/item_manager.gd").new()
	mgr.bag_size = 1  # 모델은 한 손 (1개) 기준. 기본 가방은 2개
	var err := _drive(mgr, cmds)
	mgr.free()
	return err


func _drive(mgr, cmds: Array) -> String:
	var fs := FacilityState.new("s", 3)
	var model := [[], [], []]
	var hand: ItemInstance = null
	for c in cmds:
		var slot: int = c[1]
		match c[0]:
			0:
				if hand == null:
					var d := ItemData.new()
					d.item_id = "x"
					d.weight = c[2]
					hand = mgr.create_item(d, 0)
					if not mgr.try_pick_up(hand, Vector2.ZERO):
						return "pickup failed"
				var fits: bool = WeightRules.total(model[slot]) + hand.weight() <= 12
				if mgr.place_carried(hand.instance_id, fs, slot)["ok"] != fits:
					return "place mismatch"
				if fits:
					model[slot].append(hand.weight())
					hand = null
			1:
				if fs.slot_items[slot].size() > 0:
					var it: ItemInstance = mgr.items[fs.slot_items[slot].back()]
					if mgr.take_out(it, fs) != (hand == null):
						return "take_out mismatch"
					if hand == null:
						hand = it
						model[slot].pop_back()
			2:
				if mgr.drop_carried_at(hand.instance_id if hand else -1, Vector2.ZERO) != (hand != null):
					return "drop mismatch"
				hand = null
		var bad := _invariants(mgr, fs, model, hand)
		if bad != "":
			return bad
	return ""


func _invariants(mgr, fs: FacilityState, model: Array, hand: ItemInstance) -> String:
	if fs.slot_weights != model:
		return "slot contents differ from model"
	for w in fs.slot_weights:
		if WeightRules.total(w) > 12:
			return "slot over 12"
	if fs.total_weight() > fs.max_weight():
		return "shelf over max"
	if mgr.carried_ids.is_empty() != (hand == null):
		return "hand differs from model"
	for it: ItemInstance in mgr.items.values():
		var in_shelf: bool = fs.slot_items.any(func(s): return it.instance_id in s)
		if in_shelf != (it.state == ItemInstance.State.STORED):
			return "state and shelf disagree"
		if (it.state == ItemInstance.State.CARRIED) != (it == hand):
			return "carried state differs from hand"
	return ""
