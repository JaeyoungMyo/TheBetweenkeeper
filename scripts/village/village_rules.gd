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
