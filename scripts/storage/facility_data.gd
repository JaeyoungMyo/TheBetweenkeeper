# 시설 정의 (FacilityData). 칸당 무게 한도는 12 고정 (FD-U1-7 정정)
class_name FacilityData
extends Resource

@export var facility_id: String = ""
@export var display_name: String = ""
@export var slot_count: int = 3
@export var slot_weight_limit: int = WeightRules.SLOT_WEIGHT_LIMIT


func max_weight() -> int:
	return SlotRules.facility_max(slot_count, slot_weight_limit)
