# DungeonManager (오토로드, U3). 던전 흐름 · 퀘스트 · 전달 공간 · 실패 누적을 묶는 창구
extends Node

signal intake_ready(count: int, kinds: Array)
signal quest_result(result: Dictionary)
signal game_over_reached(failures: int)
signal village_visit_ready()
signal delivery_changed()
signal quest_started()

var flow := DungeonFlow.new()
var delivery := DeliverySpace.new()
var quests := QuestController.new(delivery)
var failures := FailureCounter.new()
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()


## 새 게임: 던전 진행 값을 처음으로 되돌린다
func reset_run() -> void:
	quests.clear_pending()
	quests.quest = null
	delivery.items.clear()
	failures.reset()


## 지정한 퀘스트를 바로 발생 (튜토리얼용)
func spawn_quest_now(spec: Dictionary) -> void:
	var r := quests.spawn(spec, _stored_kinds(), rng)
	if r["status"] == "started":
		quest_started.emit()
	_handle(_outcome(r))


## F1 디버그: 전투 중이면 퀘스트를 바로 발생시킨다
func debug_spawn_quest() -> void:
	if flow.state == DungeonFlow.State.IN_BATTLE:
		_handle(_outcome(quests.spawn(flow.quest_spec(), _stored_kinds(), rng)))


func start_dungeon(no: int) -> void:
	quests.clear_pending()
	flow.start(no, rng)


func start_battle() -> void:
	var due := flow.begin_battle()
	for i in due:
		var r := quests.spawn(flow.quest_spec(), _stored_kinds(), rng)
		if r["status"] == "started":
			quest_started.emit()
		_handle(_outcome(r))


func finish_battle() -> void:
	var r := flow.finish_battle()
	intake_ready.emit(int(r["intake"]), r["fixed_kinds"])
	if r["completed"]:
		_handle(quests.fail_active())
		quests.clear_pending()
		flow.begin_sleep()
		SaveService.save_point("dungeon_clear")


## 전달 공간에 아이템을 올린다 (선반 · 바닥에서 빼는 처리는 UI 단계에서 연결)
func put_in_delivery(item: ItemInstance) -> void:
	delivery.put(item)
	_handle(quests.on_delivery_changed())
	delivery_changed.emit()


func _process(delta: float) -> void:
	if flow.is_ticking_quests() and quests.is_active():
		_handle(quests.tick(delta))
	if flow.tick_sleep(delta):
		village_visit_ready.emit()


## spawn 결과 중 끝난 퀘스트 결과만 꺼낸다
func _outcome(r: Dictionary) -> Dictionary:
	return r.get("result", {}) if r.get("status") == "started" else {}


## 끝난 퀘스트를 처리하고, 대기 중인 다음 퀘스트를 시작한다
func _handle(r: Dictionary) -> void:
	if r.is_empty():
		return
	if r["result"] == "success":
		EconomyManager.add_gold(int(r["gold"]))
		EconomyManager.add_exp(int(r["exp"]))
	elif r["result"] == "failed":
		if failures.add_failure():
			flow.game_over()
			game_over_reached.emit(failures.count)
	quest_result.emit(r)
	for ended in quests.activate_pending(_stored_kinds(), rng):
		_handle(ended)


## 퀘스트 후보 종류: 선반, 바닥, 들고 있는 아이템 (사용자 확정)
func _stored_kinds() -> Array:
	var kinds: Array = []
	for item: ItemInstance in ItemManager.items.values():
		var usable: bool = item.state == ItemInstance.State.STORED or item.state == ItemInstance.State.INCOMING or item.state == ItemInstance.State.CARRIED
		if usable and not kinds.has(item.data.item_id):
			kinds.append(item.data.item_id)
	return kinds
