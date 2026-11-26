# 퀘스트 줄 구성 (U3 BR-U3-08)
class_name QuestRules
extends RefCounted


## kinds: 창고에 있는 고유 종류 목록. 줄 = {item_kind, required}. 합계 = quantity.
## 줄 수 = min(line_max, 종류 수, quantity). 나머지는 앞 줄부터 1개씩 더한다.
static func build_lines(kinds: Array, quantity: int, line_max: int, rng: RandomNumberGenerator) -> Array:
	var pool: Array = kinds.duplicate()
	var n := mini(line_max, mini(pool.size(), quantity))
	var out: Array = []
	if n <= 0:
		return out
	var picked: Array = []
	for i in n:
		var idx := rng.randi_range(0, pool.size() - 1)
		picked.append(pool[idx])
		pool.remove_at(idx)
	var base := quantity / n
	var rem := quantity % n
	for i in n:
		out.append({"item_kind": picked[i], "required": base + (1 if i < rem else 0)})
	return out
