# U2 속성 기반 테스트
extends TestBase


func test_prop_ledger_matches_model() -> void:
	var err := Pbt.check(func(r): return range(r.randi_range(0, 40)).map(func(_i): return [r.randi_range(0, 1), r.randi_range(-20, 200)]), _ledger)
	expect(err == "", err)


func _ledger(cmds: Array) -> String:
	var l := GoldLedger.new()
	var model := 0
	for c in cmds:
		var v: int = c[1]
		var ok: bool
		if c[0] == 0:
			ok = v >= 0
			if l.add(v) != ok:
				return "add"
			model += v if ok else 0
		else:
			ok = v >= 0 and v <= model
			if l.try_spend(v) != ok:
				return "spend"
			model -= v if ok else 0
		if l.amount() != model or model < 0:
			return "balance"
	return ""


func test_prop_exp_split_equals_lump() -> void:
	var err := Pbt.check(func(r): return Pbt.gen_weights(r, 60), _exp)
	expect(err == "", err)


func _exp(ws: Array) -> String:
	var lv := 1
	var xp := 0
	for w in ws:
		var r := ExpCalculator.apply(lv, xp, w * 5, 50, 25)
		lv = r["level"]
		xp = r["exp"]
		if xp < 0 or xp >= ExpCalculator.to_next(lv, 50, 25):
			return "range"
	var lump := ExpCalculator.apply(1, 0, WeightRules.total(ws) * 5, 50, 25)
	return "" if lump["level"] == lv and lump["exp"] == xp else "split differs"


func test_prop_augment_draw() -> void:
	var table: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/augments/augments.json"))
	var prop := func(v: Array) -> String:
		if v.size() < 5:
			return ""
		var taken := {}
		var open := 0
		for i in 4:
			taken[table[i]["id"]] = v[i]
			open += 1 if v[i] < table[i]["max"] else 0
		var rng := RandomNumberGenerator.new()
		rng.seed = v[4]
		var seen := {}
		for a in AugmentPool.draw(table, taken, 3, rng):
			if seen.has(a["id"]) or taken[a["id"]] >= a["max"]:
				return "duplicate or maxed"
			seen[a["id"]] = true
		return "" if seen.size() == mini(3, open) else "count"
	var err := Pbt.check(func(r): return [r.randi_range(0, 5), r.randi_range(0, 5), r.randi_range(0, 5), r.randi_range(0, 5), r.randi()], prop)
	expect(err == "", err)


func test_prop_restore_gives_exp_once() -> void:
	var err := Pbt.check(func(r): return Pbt.gen_weights(r, 10), func(ws: Array) -> String:
		var e = load("res://autoload/economy_manager.gd").new()
		for w in ws:
			var d := ItemData.new()
			d.weight = w
			var it := ItemInstance.new(1, d, 0)
			e.grant_exp(it)
			var snap := [e.level, e.exp_points]
			e.grant_exp(it)
			if snap != [e.level, e.exp_points]:
				e.free()
				return "repeat exp"
		e.free()
		return "")
	expect(err == "", err)
