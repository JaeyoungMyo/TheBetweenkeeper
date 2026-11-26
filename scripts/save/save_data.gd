# 저장 데이터 조립 · 복원 (U5 BR-U5-06, 08; FD-U5-11 A). 진행 중 퀘스트는 저장하지 않는다
class_name SaveData
extends RefCounted

const VERSION := 1
const REQUIRED := ["version", "point", "dungeon_no", "failures", "gold", "level", "exp", "augments", "bag_size", "carry_multiplier", "tutorial_done", "shop_visits", "items", "shelves", "pending_choices"]


## 형식 검사: 버전과 필수 키가 모두 있어야 한다 (잘못된 저장은 새 게임으로 처리)
static func is_valid(d: Dictionary) -> bool:
	if int(d.get("version", -1)) != VERSION:
		return false
	for key in REQUIRED:
		if not d.has(key):
			return false
	return d["items"] is Array and d["shelves"] is Array


## 아이템 상태 저장값. 전달 선반 · 들고 있는 아이템은 바닥 (incoming) 으로 되돌린다 (BR-U5-06)
static func _saved_state(state: ItemInstance.State) -> String:
	match state:
		ItemInstance.State.STORED:
			return "stored"
		ItemInstance.State.SOLD:
			return "sold"
		_:
			return "incoming"


static func capture(shelves: Array, point: String, tutorial_done: bool, shop_visits: int) -> Dictionary:
	var items := []
	for item: ItemInstance in ItemManager.items.values():
		if item.state == ItemInstance.State.SOLD:
			continue
		items.append({
			"id": item.instance_id,
			"kind": item.data.item_id,
			"stage": item.stage_id,
			"state": _saved_state(item.state),
			"facility": item.facility_id,
			"slot": item.slot_index,
			"exp_claimed": item.is_exp_claimed,
			"pos": [item.world_position.x, item.world_position.y],
		})
	return {
		"version": VERSION,
		"point": point,
		"dungeon_no": DungeonManager.flow.dungeon_no,
		"failures": DungeonManager.failures.count,
		"gold": EconomyManager.gold(),
		"level": EconomyManager.level,
		"pending_choices": EconomyManager.pending_choices,
		"exp": EconomyManager.exp_points,
		"augments": EconomyManager.augments.duplicate(),
		"bag_size": ItemManager.bag_size,
		"carry_multiplier": ItemManager.carry_multiplier,
		"tutorial_done": tutorial_done,
		"shop_visits": shop_visits,
		"items": items,
		"shelves": shelves,
	}


## 저장값을 자동 로드 (아이템 · 골드 · EXP · 실패 · 던전 번호 · 가방). 선반 배치는 StorageRoom 이 맡는다
static func restore(d: Dictionary) -> void:
	ItemManager.items.clear()
	ItemManager.carried_ids.clear()
	ItemManager.bag_size = int(d["bag_size"])
	ItemManager.carry_multiplier = int(d["carry_multiplier"])
	var max_id := 0
	for row: Dictionary in d["items"]:
		var data: ItemData = load("res://data/items/%s.tres" % row["kind"])
		var item := ItemInstance.new(int(row["id"]), data, int(row["stage"]))
		item.state = ItemInstance.State.STORED if row["state"] == "stored" else (ItemInstance.State.SOLD if row["state"] == "sold" else ItemInstance.State.INCOMING)
		item.facility_id = row["facility"]
		item.slot_index = int(row["slot"])
		item.is_exp_claimed = bool(row["exp_claimed"])
		item.world_position = Vector2(float(row["pos"][0]), float(row["pos"][1]))
		ItemManager.items[item.instance_id] = item
		max_id = maxi(max_id, item.instance_id)
	ItemManager._next_id = max_id + 1
	# 골드 · EXP · 증강 (EconomyManager 한 곳으로만 바꾼다, NFR-04)
	EconomyManager.reset_run()
	var diff := int(d["gold"]) - EconomyManager.gold()
	if diff > 0:
		EconomyManager.add_gold(diff)
	elif diff < 0:
		EconomyManager.spend_gold(-diff)
	EconomyManager.level = int(d["level"])
	EconomyManager.exp_points = int(d["exp"])
	EconomyManager.augments = d["augments"]
	EconomyManager.pending_choices = int(d["pending_choices"])
	DungeonManager.failures.count = int(d["failures"])
	DungeonManager.flow.dungeon_no = int(d["dungeon_no"])
