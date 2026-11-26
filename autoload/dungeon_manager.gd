# DungeonManager (오토로드, U3). 던전 흐름 · 퀘스트 · 전달 공간 · 실패 누적을 묶는 창구
extends Node

signal intake_ready(count: int)
signal quest_result(result: Dictionary)
signal game_over_reached(failures: int)
signal shop_visit_ready()

var flow := DungeonFlow.new()
var delivery := DeliverySpace.new()
var quests := QuestController.new(delivery)
var failures := FailureCounter.new()
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()


func start_dungeon(no: int) -> void:
	quests.clear_pending()
	flow.start(no, rng)


func start_battle() -> void:
	var due := flow.begin_battle()
	for i in due:
		_handle(_outcome(quests.spawn(flow.quest_spec(), _stored_kinds(), rng)))


func finish_battle() -> void:
	var r := flow.finish_battle()
	intake_ready.emit(int(r["intake"]))
	if r["completed"]:
		_handle(quests.fail_active())
		quests.clear_pending()
		flow.begin_sleep()


## 전달 공간에 아이템을 올린다 (선반 · 바닥에서 빼는 처리는 UI 단계에서 연결)
func put_in_delivery(item: ItemInstance) -> void:
	delivery.put(item)
	_handle(quests.on_delivery_changed())


func _process(delta: float) -> void:
	if flow.is_ticking_quests() and quests.is_active():
		_handle(quests.tick(delta))
	if flow.tick_sleep(delta):
		shop_visit_ready.emit()


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


func _stored_kinds() -> Array:
	var kinds: Array = []
	for item in ItemManager.items.values():
		if item.state == ItemInstance.State.STORED and not kinds.has(item.data.item_id):
			kinds.append(item.data.item_id)
	return kinds
