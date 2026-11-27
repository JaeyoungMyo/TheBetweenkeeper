# 던전 상태 머신 (U3 DungeonFlow). READY → IN_BATTLE ↔ READY → DUNGEON_COMPLETE → SLEEP → VILLAGE_HANDOFF (BR-U3-01, 02, 20, 22)
class_name DungeonFlow
extends RefCounted

enum State { READY, IN_BATTLE, DUNGEON_COMPLETE, SLEEP, VILLAGE_HANDOFF, GAME_OVER }

var state: State = State.READY
var dungeon_no := 0
var config: Dictionary = {}
var battle_total := 0
var battle_index := 0
var rng: RandomNumberGenerator
var quest_battles: Array[int] = []
var sleep_left := 0.0
var village_handoffs := 0


func start(no: int, rng: RandomNumberGenerator) -> void:
	dungeon_no = no
	config = DungeonTable.get_config(no)
	battle_total = DungeonRules.roll_battle_count(rng, int(config["battle_min"]), int(config["battle_max"]))
	self.rng = rng
	quest_battles = DungeonRules.spawn_battles(battle_total, int(config["quest_count"]), rng)
	if config.has("fixed_quest_battle"):
		quest_battles = [int(config["fixed_quest_battle"])]  # 고정 퀘스트 (던전 1)
	battle_index = 0
	village_handoffs = 0
	state = State.READY


## 전투 시작. 이번 전투에서 발생할 퀘스트 수를 돌려준다
func begin_battle() -> int:
	if state != State.READY:
		return 0
	battle_index += 1
	state = State.IN_BATTLE
	return quest_battles.count(battle_index)


func finish_battle() -> Dictionary:
	if state != State.IN_BATTLE:
		return {"intake": 0, "completed": false, "fixed_kinds": []}  # 전투 중이 아니면 아무 일도 없다
	var intake := DungeonRules.roll_intake(rng, int(config["intake_min"]), int(config["intake_max"]))
	if battle_index == 1 and config.has("fixed_intake_battle1"):
		intake = (config["fixed_intake_battle1"] as Array).size()  # 고정 입고 (던전 1, 첫 전투)
	var fixed := fixed_intake_kinds()
	if DungeonRules.is_complete(battle_total - battle_index):
		state = State.DUNGEON_COMPLETE
		return {"intake": intake, "completed": true, "fixed_kinds": fixed}
	state = State.READY
	return {"intake": intake, "completed": false, "fixed_kinds": fixed}


func begin_sleep() -> void:
	state = State.SLEEP
	sleep_left = float(config["sleep_sec"])


## 수면 건너뛰기: 다음 tick_sleep 에서 바로 마을 방문으로 넘어간다
func wake_up() -> void:
	if state == State.SLEEP:
		sleep_left = 0.0


## 수면이 끝나면 true. 상점 호출은 던전마다 정확히 한 번 (BR-U3-22)
func tick_sleep(delta: float) -> bool:
	if state != State.SLEEP:
		return false
	sleep_left = maxf(0.0, sleep_left - delta)
	if sleep_left > 0.0:
		return false
	state = State.VILLAGE_HANDOFF
	village_handoffs += 1
	return true


## 이번 전투의 고정 입고 품목 (없으면 빈 배열, 무작위)
func fixed_intake_kinds() -> Array:
	if battle_index == 1 and config.has("fixed_intake_battle1"):
		return config["fixed_intake_battle1"]
	return []


func quest_spec() -> Dictionary:
	var spec := {
		"quantity": int(config["quest_quantity"]),
		"line_max": int(config["line_max"]),
		"time_limit": float(config["quest_time_limit_sec"]),
		"gold": int(config["quest_reward_gold"]),
		"exp": int(config["quest_reward_exp"]),
	}
	if config.has("fixed_quest_lines"):
		spec["fixed_lines"] = config["fixed_quest_lines"]  # 고정 퀘스트 줄 (던전 1)
	return spec


func is_ticking_quests() -> bool:
	return state == State.IN_BATTLE or state == State.READY


func game_over() -> void:
	state = State.GAME_OVER
