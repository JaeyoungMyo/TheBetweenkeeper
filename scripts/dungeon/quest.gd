# 퀘스트 1건 (Quest). 줄 진행 · 제한 시간 · 성공 시 소비량 (U3 BR-U3-05, 06, 09~12)
class_name Quest
extends RefCounted

enum Status { PENDING, ACTIVE, SUCCESS, FAILED }

var lines: Array[Dictionary] = []  # {item_kind, required, delivered}
var time_limit := 30.0
var remaining := 0.0
var status: Status = Status.PENDING
var reward_gold := 0
var reward_exp := 0


func _init(line_list: Array, limit: float, gold: int, exp_value: int) -> void:
	for l: Dictionary in line_list:
		lines.append({"item_kind": l["item_kind"], "required": int(l["required"]), "delivered": 0})
	time_limit = limit
	reward_gold = gold
	reward_exp = exp_value


func start() -> void:
	status = Status.ACTIVE
	remaining = time_limit


## 시간이 다 되면 true 를 돌려준다
func tick(delta: float) -> bool:
	if status != Status.ACTIVE:
		return false
	remaining = maxf(0.0, remaining - delta)
	return remaining <= 0.0


func total_quantity() -> int:
	var total := 0
	for l in lines:
		total += int(l["required"])
	return total


## 전달 공간의 종류별 개수로 줄 진행을 다시 계산한다. 필요 개수를 넘지 않는다 (BR-U3-09, 11)
func apply_counts(counts: Dictionary) -> void:
	for l in lines:
		l["delivered"] = mini(int(l["required"]), int(counts.get(l["item_kind"], 0)))


func is_line_complete(index: int) -> bool:
	var l: Dictionary = lines[index]
	return int(l["delivered"]) >= int(l["required"])


func all_complete() -> bool:
	for l in lines:
		if int(l["delivered"]) < int(l["required"]):
			return false
	return true


## 성공 시 줄별 필요 개수 (BR-U3-12)
func consume_plan() -> Dictionary:
	var plan := {}
	for l in lines:
		plan[l["item_kind"]] = plan.get(l["item_kind"], 0) + int(l["required"])
	return plan
