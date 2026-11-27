# 상점 흐름 (U4): 판매 퀘스트 (출력공간 = 전달 선반) → 구매 추첨 → 닫힘 (BR-U4-01, 02, 05, 06, 10~12)
class_name ShopFlow
extends RefCounted

signal sell_finished(result: Dictionary)
signal buy_finished(lines: Array)

enum State { CLOSED, SELL, BUY, DONE }

var state: State = State.CLOSED
var output: DeliverySpace
var quests: QuestController
var config: Dictionary
var rng := RandomNumberGenerator.new()
## 아이템을 맵에 놓는 콜백. 인자: ItemInstance (위치는 콜백이 정한다)
var _place: Callable


func _init(space: DeliverySpace, place: Callable) -> void:
	output = space
	_place = place
	config = ShopRules.load_config()
	quests = QuestController.new(space)
	quests.value_of = Callable(EconomyManager, "sell_price")
	rng.randomize()


## override: 튜토리얼 등에서 판매 퀘스트 값을 바꿀 때 (예: fixed_lines, quantity, time_limit)
func open(override: Dictionary = {}) -> void:
	state = State.SELL
	var kinds := ShopRules.sellable_kinds(ItemManager.items.values(), config["sell_excluded_categories"])
	var spec := {
		"quantity": int(config["sell_quantity"]),
		"line_max": int(config["sell_line_max"]),
		"time_limit": float(config["sell_time_limit_sec"]),
		"gold": 0,
		"exp": int(config["sell_reward_exp"]),
	}
	spec.merge(override, true)
	var r := quests.spawn(spec, kinds, rng)
	if r["status"] == "skipped":
		_end_sell({"result": "skipped"})
	elif not r.get("result", {}).is_empty():
		_end_sell(r["result"])


## 매 프레임: 판매 퀘스트 시간 진행
func tick(delta: float) -> void:
	if state != State.SELL or not quests.is_active():
		return
	var r := quests.tick(delta)
	if not r.is_empty():
		_end_sell(r)


## 출력공간 (전달 선반) 이 바뀔 때마다 호출
func on_output_changed() -> void:
	if state != State.SELL or not quests.is_active():
		return
	var r := quests.on_delivery_changed()
	if not r.is_empty():
		_end_sell(r)


func close() -> void:
	state = State.CLOSED


func _end_sell(r: Dictionary) -> void:
	if r.get("result") == "success":
		EconomyManager.add_gold(int(r["gold"]))
		EconomyManager.add_exp(int(r["exp"]))
	sell_finished.emit(r)
	# 출력공간에 남은 아이템은 판매하지 않고 맵으로 옮긴다 (BR-U4-06)
	for item in output.remove_all():
		item.state = ItemInstance.State.INCOMING
		_place.call(item)
	_run_buy()


func _run_buy() -> void:
	state = State.BUY
	var lines: Array = []
	for p: Dictionary in ShopRules.roll_purchases(config["purchase_pool"], int(config["buy_count"]), rng):
		var ok := EconomyManager.spend_gold(int(p["price"]))  # BR-U4-11: 부족하면 이 품목만 건너뜀
		if ok:
			var data: ItemData = load("res://data/items/%s.tres" % p["item_id"])
			var item := ItemManager.create_item(data, 0)
			item.state = ItemInstance.State.INCOMING  # BR-U4-12: 맵에 떨어짐
			_place.call(item)
		lines.append({"item_id": p["item_id"], "bought": ok})
	state = State.DONE
	buy_finished.emit(lines)
