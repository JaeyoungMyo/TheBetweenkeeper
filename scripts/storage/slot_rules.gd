# 칸 · 시설 적재 규칙 (순수 로직). BR-U1-01, 02, 03, 12, 13
class_name SlotRules
extends RefCounted


## 칸 적재 결과: {"ok": bool, "reason": String}
static func check_slot(slot_weights: Array, add_weight: int, limit: int) -> Dictionary:
	if not WeightRules.is_valid_item_weight(add_weight):
		return {"ok": false, "reason": "invalid_weight"}
	if not WeightRules.can_add(WeightRules.total(slot_weights), add_weight, limit):
		return {"ok": false, "reason": "slot_overweight"}
	return {"ok": true, "reason": ""}


static func facility_max(slot_count: int, slot_limit: int) -> int:
	return slot_count * slot_limit
