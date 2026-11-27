# EconomyManager (오토로드, U2). 골드 · EXP · 증강 · 판매 · 구매의 단일 창구
extends Node

signal gold_changed(amount: int)
signal exp_changed(level: int, exp: int)
signal level_up(level: int)

var config: Dictionary
var augment_table: Array
var level := 1
var exp_points := 0
var pending_choices := 0
var augments: Dictionary = {}
var rng := RandomNumberGenerator.new()
var _ledger := GoldLedger.new()


func _init() -> void:
	config = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy/economy.json"))
	augment_table = JSON.parse_string(FileAccess.get_file_as_string("res://data/augments/augments.json"))
	_ledger.add(int(config["start_gold"]))
	rng.randomize()


func _ready() -> void:
	ItemManager.item_stored.connect(func(item: ItemInstance) -> void: grant_exp(item))


## 새 게임: 골드 · EXP · 증강을 처음으로 되돌린다
func reset_run() -> void:
	level = 1
	exp_points = 0
	pending_choices = 0
	augments = {}
	_ledger = GoldLedger.new()
	_ledger.add(int(config["start_gold"]))
	gold_changed.emit(gold())


func gold() -> int:
	return _ledger.amount()


func add_gold(value: int) -> void:
	if _ledger.add(value):
		gold_changed.emit(gold())


func spend_gold(cost: int) -> bool:
	if not _ledger.try_spend(cost):
		return false
	gold_changed.emit(gold())
	return true


func augment_bonus(id: String) -> float:
	for a: Dictionary in augment_table:
		if a["id"] == id:
			return float(a["value"]) * augments.get(id, 0)
	return 0.0


func exp_to_next() -> int:
	return ExpCalculator.to_next(level, int(config["level_base"]), int(config["level_step"]))


## 아이템마다 최초 1회만 지급 (FR-10)
func grant_exp(item: ItemInstance) -> bool:
	if item.is_exp_claimed:
		return false
	item.is_exp_claimed = true
	var base: int = item.data.exp_value if item.data.exp_value > 0 else item.weight() * int(config["exp_per_weight"])
	add_exp(roundi(base * (1.0 + augment_bonus("exp"))))
	return true


func add_exp(amount: int) -> void:
	var r := ExpCalculator.apply(level, exp_points, amount, int(config["level_base"]), int(config["level_step"]))
	level = r["level"]
	exp_points = r["exp"]
	pending_choices += r["gained"]
	exp_changed.emit(level, exp_points)
	if r["gained"] > 0:
		level_up.emit(level)


func draw_choices() -> Array:
	return AugmentPool.draw(augment_table, augments, 3, rng)


func choose_augment(id: String, items: Node) -> bool:
	if pending_choices <= 0:
		return false
	for a: Dictionary in augment_table:
		if a["id"] == id and augments.get(id, 0) < int(a["max"]):
			augments[id] = augments.get(id, 0) + 1
			pending_choices -= 1
			if id == "carry":
				items.upgrade_multiplier()
			return true
	return false


func sell_price(data: ItemData) -> int:
	var base: int = data.base_price if data.base_price > 0 else data.weight * int(config["price_per_weight"])
	return roundi(base * (1.0 + augment_bonus("sell")))


## 판매 화면은 U4 에서 연결한다
func sell(item: ItemInstance, items: Node, facility: FacilityState = null) -> bool:
	if item.state == ItemInstance.State.DELIVERED:  # U3 BR-U3-23: 전달 공간 아이템은 판매 불가
		return false
	if not items.mark_sold(item, facility):
		return false
	add_gold(sell_price(item.data))
	return true


## 가격이 -1 이면 더 살 수 없음
func bag_price(items: Node) -> int:
	if items.bag_size < 1 or items.bag_size >= CarryRules.MAX_BAG:
		return -1
	return int(config["bag_prices"][items.bag_size - 1])


func shelf_price(shelf_count: int) -> int:
	if shelf_count < 1 or shelf_count > config["shelf_prices"].size():
		return -1
	return int(config["shelf_prices"][shelf_count - 1])


## 선반마다 따로 확장한다. shelf_index 는 0 부터 (나중에 산 선반일수록 비쌈)
func slot_price(facility: FacilityState, shelf_index: int) -> int:
	var i := facility.slot_count - 3
	if shelf_index < 0 or shelf_index >= config["slot_prices"].size() or i < 0:
		return -1
	var prices: Array = config["slot_prices"][shelf_index]
	return int(prices[i]) if i < prices.size() else -1


func buy_bag(items: Node) -> bool:
	var price := bag_price(items)
	return price >= 0 and spend_gold(price) and items.upgrade_bag()


func buy_shelf(shelf_count: int) -> bool:
	var price := shelf_price(shelf_count)
	return price >= 0 and spend_gold(price)


func buy_slot(facility: FacilityState, shelf_index: int) -> bool:
	var price := slot_price(facility, shelf_index)
	if price < 0 or not spend_gold(price):
		return false
	facility.add_slot()
	return true
