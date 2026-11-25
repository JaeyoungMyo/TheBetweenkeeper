# 무게 규칙 (순수 로직, 노드 없음). BR-U1-01, 09, 10, 11, 16
class_name WeightRules
extends RefCounted

const SLOT_WEIGHT_LIMIT := 12
const ALLOWED_ITEM_WEIGHTS := [1, 2, 3, 4, 6]


static func total(weights: Array) -> int:
	var sum := 0
	for w in weights:
		sum += int(w)
	return sum


## 칸 합계가 한도와 같으면 허용 (BR-U1-11).
static func can_add(current_total: int, add_weight: int, limit: int = SLOT_WEIGHT_LIMIT) -> bool:
	return current_total + add_weight <= limit


static func is_valid_item_weight(weight: int) -> bool:
	return weight in ALLOWED_ITEM_WEIGHTS


## 분류 정보 (BR-U1-10). 속도 계산에는 쓰지 않는다.
static func weight_class(weight: int) -> String:
	if weight <= 2:
		return "light"
	if weight <= 4:
		return "medium"
	return "heavy"


## 이동 속도는 아이템 무게와 무관하게 일정 (BR-U1-09, 사용자 정정).
static func carry_speed(base_speed: float, _carried_weight: int) -> float:
	return base_speed
