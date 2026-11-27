# 상점 규칙 (U4): 판매 가능 품목, 구매 추첨 (BR-U4-03, 07, 10)
class_name VillageRules
extends RefCounted

const PATH := "res://data/village/village.json"


static func load_config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(PATH))


## 창고 (선반 · 바닥 · 들고 있는 것) 에 있는 판매 가능 종류 (고유 목록). 제외 카테고리는 뺀다
static func sellable_kinds(items: Array, excluded: Array) -> Array:
	var kinds: Array = []
	for item: ItemInstance in items:
		var holding: bool = item.state == ItemInstance.State.STORED or item.state == ItemInstance.State.INCOMING or item.state == ItemInstance.State.CARRIED
		if holding and not excluded.has(item.data.category) and not kinds.has(item.data.item_id):
			kinds.append(item.data.item_id)
	return kinds


## 창고에 있는 판매 가능 아이템의 종류별 개수 (kind → 개수)
static func sellable_stock(items: Array, excluded: Array) -> Dictionary:
	var stock := {}
	for item: ItemInstance in items:
		var holding: bool = item.state == ItemInstance.State.STORED or item.state == ItemInstance.State.INCOMING or item.state == ItemInstance.State.CARRIED
		if holding and not excluded.has(item.data.category):
			stock[item.data.item_id] = int(stock.get(item.data.item_id, 0)) + 1
	return stock


## 판매 퀘스트 줄: 실제 가진 개수를 넘지 않게 나눈다. 총량 = min(quantity, 고른 종류의 재고 합)
static func sell_lines(stock: Dictionary, quantity: int, line_max: int, rng: RandomNumberGenerator) -> Array:
	var pool: Array = stock.keys()
	var picked: Array = []
	while picked.size() < line_max and not pool.is_empty():
		var idx := rng.randi_range(0, pool.size() - 1)
		picked.append(pool[idx])
		pool.remove_at(idx)
	var req := {}
	var left := quantity
	var progress := true
	while left > 0 and progress:
		progress = false
		for k in picked:
			if left > 0 and int(req.get(k, 0)) < int(stock[k]):
				req[k] = int(req.get(k, 0)) + 1
				left -= 1
				progress = true
	var out: Array = []
	for k in picked:
		if int(req.get(k, 0)) > 0:
			out.append({"item_kind": k, "required": int(req[k])})
	return out


## 가중치 추첨. 같은 품목이 여러 번 나올 수 있다
static func roll_purchases(pool: Array, count: int, rng: RandomNumberGenerator) -> Array:
	var total := 0
	for p: Dictionary in pool:
		total += int(p["weight"])
	var out: Array = []
	if total <= 0:
		return out
	for i in count:
		var r := rng.randi_range(1, total)
		var acc := 0
		for p: Dictionary in pool:
			acc += int(p["weight"])
			if r <= acc:
				out.append(p)
				break
	return out
