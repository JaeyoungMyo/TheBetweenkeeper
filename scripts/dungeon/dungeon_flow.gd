# 던전 상태 머신 (U3 DungeonFlow). READY → IN_BATTLE ↔ READY → DUNGEON_COMPLETE → SLEEP → SHOP_HANDOFF (BR-U3-01, 02, 20, 22)
class_name DungeonFlow
extends RefCounted

enum State { READY, IN_BATTLE, DUNGEON_COMPLETE, SLEEP, SHOP_HANDOFF, GAME_OVER }

var state: State = State.READY
var dungeon_no := 0
var config: Dictionary = {}
var battle_total := 0
var battle_index := 0
var intake_schedule: Array[int] = []
var quest_battles: Array[int] = []
var sleep_left := 0.0
var shop_handoffs := 0


func start(no: int, rng: RandomNumberGenerator) -> void:
	dungeon_no = no
	config = DungeonTable.get_config(no)
	battle_total = DungeonRules.roll_battle_count(rng, int(config["battle_min"]), int(config["battle_max"]))
	intake_schedule = DungeonRules.split_intake(int(config["new_item_total"]), battle_total)
	quest_battles = DungeonRules.spawn_battles(battle_total, int(config["quest_count"]), rng)
	battle_index = 0
	shop_handoffs = 0
	state = State.READY


## 전투 시작. 이번 전투에서 발생할 퀘스트 수를 돌려준다
func begin_battle() -> int:
	if state != State.READY:
		return 0
	battle_index += 1
	state = State.IN_BATTLE
	return quest_battles.count(battle_index)


func finish_battle() -> Dictionary:
	var intake: int = intake_schedule[battle_index - 1]
	if DungeonRules.is_complete(battle_total - battle_index):
		state = State.DUNGEON_COMPLETE
		return {"intake": intake, "completed": true}
	state = State.READY
	return {"intake": intake, "completed": false}


func begin_sleep() -> void:
	state = State.SLEEP
	sleep_left = float(config["sleep_sec"])


## 수면이 끝나면 true. 상점 호출은 던전마다 정확히 한 번 (BR-U3-22)
func tick_sleep(delta: float) -> bool:
	if state != State.SLEEP:
		return false
	sleep_left = maxf(0.0, sleep_left - delta)
	if sleep_left > 0.0:
		return false
	state = State.SHOP_HANDOFF
	shop_handoffs += 1
	return true


func quest_spec() -> Dictionary:
	return {
		"quantity": int(config["quest_quantity"]),
		"line_max": int(config["line_max"]),
		"time_limit": float(config["quest_time_limit_sec"]),
		"gold": int(config["quest_reward_gold"]),
		"exp": int(config["quest_reward_exp"]),
	}


func is_ticking_quests() -> bool:
	return state == State.IN_BATTLE or state == State.READY


func game_over() -> void:
	state = State.GAME_OVER
