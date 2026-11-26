# 전투 수 · 입고 분배 · 완료 판정 (U3 BR-U3-01, 02, 03, 14)
class_name DungeonRules
extends RefCounted


static func roll_battle_count(rng: RandomNumberGenerator, min_n: int, max_n: int) -> int:
	return rng.randi_range(min_n, max_n)


## 신규 아이템 총량을 전투마다 균등 분배. 나머지는 마지막 전투에 더한다 (합 = total)
static func split_intake(total: int, battles: int) -> Array[int]:
	var out: Array[int] = []
	if battles <= 0:
		return out
	var base := total / battles
	var rem := total % battles
	for i in battles:
		out.append(base + (rem if i == battles - 1 else 0))
	return out


## 퀘스트가 발생할 전투 번호 (1부터, 오름차순, 서로 다름)
static func spawn_battles(battle_total: int, quest_count: int, rng: RandomNumberGenerator) -> Array[int]:
	var pool: Array[int] = []
	for i in range(1, battle_total + 1):
		pool.append(i)
	var picked: Array[int] = []
	for k in mini(quest_count, battle_total):
		var idx := rng.randi_range(0, pool.size() - 1)
		picked.append(pool[idx])
		pool.remove_at(idx)
	picked.sort()
	return picked


## BR-U3-02: 남은 전투가 0 이면 완료. 아이템 상태는 보지 않는다
static func is_complete(battles_left: int) -> bool:
	return battles_left <= 0
