# 증강 후보 추첨 (순수 로직). 중복 없음, 최대치 제외 (FR-11)
class_name AugmentPool
extends RefCounted


static func draw(table: Array, taken: Dictionary, count: int, rng: RandomNumberGenerator) -> Array:
	var pool := table.filter(func(a: Dictionary) -> bool: return taken.get(a["id"], 0) < int(a["max"]))
	var out := []
	while out.size() < count and not pool.is_empty():
		out.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	return out
