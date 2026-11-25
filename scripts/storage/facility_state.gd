# 선반 상태 (칸별 적재 목록). 적재 규칙은 SlotRules 에 위임
class_name FacilityState
extends RefCounted

var facility_id: String
var slot_count: int
var slot_limit: int
# 칸마다 아이템 instance_id 목록과 무게 목록을 함께 둔다
var slot_items: Array = []
var slot_weights: Array = []


func _init(id: String, count: int, limit: int = WeightRules.SLOT_WEIGHT_LIMIT) -> void:
	facility_id = id
	slot_count = count
	slot_limit = limit
	for i in count:
		slot_items.append([])
		slot_weights.append([])


func add_slot() -> void:
	slot_count += 1
	slot_items.append([])
	slot_weights.append([])


func total_weight() -> int:
	var sum := 0
	for w in slot_weights:
		sum += WeightRules.total(w)
	return sum


func max_weight() -> int:
	return SlotRules.facility_max(slot_count, slot_limit)


## 칸에 적재. 성공 시 {"ok": true}, 실패 시 사유 반환 (BR-U1-01, 03, 12)
func store(slot_index: int, item: ItemInstance) -> Dictionary:
	if slot_index < 0 or slot_index >= slot_count:
		return {"ok": false, "reason": "invalid_slot"}
	if item.state == ItemInstance.State.STORED:
		return {"ok": false, "reason": "already_stored"}
	var check := SlotRules.check_slot(slot_weights[slot_index], item.weight(), slot_limit)
	if not check["ok"]:
		return check
	slot_items[slot_index].append(item.instance_id)
	slot_weights[slot_index].append(item.weight())
	return {"ok": true, "reason": ""}


## 꺼내기 (BR-U1-13). 목록에서 제거하면 합계에서도 빠진다.
func remove(item: ItemInstance) -> bool:
	if item.facility_id != facility_id or item.slot_index < 0:
		return false
	var idx := item.slot_index
	var pos: int = slot_items[idx].find(item.instance_id)
	if pos < 0:
		return false
	slot_items[idx].remove_at(pos)
	slot_weights[idx].remove_at(pos)
	return true
