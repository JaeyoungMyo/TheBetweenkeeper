# 퀘스트 진행 관리 (U3 BR-U3-05~07, 09~15, 21). 한 번에 1건만 진행, 나머지는 대기열
class_name QuestController
extends RefCounted

var quest: Quest = null
var delivery: DeliverySpace
var pending: Array[Dictionary] = []


func _init(space: DeliverySpace) -> void:
	delivery = space


func is_active() -> bool:
	return quest != null and quest.status == Quest.Status.ACTIVE


## spec: {quantity, line_max, time_limit, gold, exp}. 진행 중이면 대기열에 넣는다 (BR-U3-07)
func spawn(spec: Dictionary, kinds: Array, rng: RandomNumberGenerator) -> Dictionary:
	if is_active():
		pending.append(spec)
		return {"status": "queued"}
	return _start(spec, kinds, rng)


func _start(spec: Dictionary, kinds: Array, rng: RandomNumberGenerator) -> Dictionary:
	var lines := QuestRules.build_lines(kinds, int(spec["quantity"]), int(spec["line_max"]), rng)
	if lines.is_empty():
		return {"status": "skipped"}  # BR-U3-08
	quest = Quest.new(lines, float(spec["time_limit"]), int(spec["gold"]), int(spec["exp"]))
	quest.start()
	return {"status": "started", "result": _evaluate()}


## 전달 공간이 바뀔 때마다 호출. 끝났으면 결과 (빈 딕셔너리 = 변화 없음)
func on_delivery_changed() -> Dictionary:
	if not is_active():
		return {}
	return _evaluate()


func tick(delta: float) -> Dictionary:
	if not is_active():
		return {}
	if quest.tick(delta):
		quest.status = Quest.Status.FAILED
		return {"result": "failed"}
	return {}


## 던전 완료 시 진행 중 퀘스트 실패 처리 (BR-U3-21). 전달 공간은 건드리지 않는다
func fail_active() -> Dictionary:
	if not is_active():
		return {}
	quest.status = Quest.Status.FAILED
	return {"result": "failed"}


## 끝난 뒤 대기 중인 퀘스트를 차례로 시작한다. 시작 결과 중 끝난 것만 돌려준다
func activate_pending(kinds: Array, rng: RandomNumberGenerator) -> Array:
	var ended: Array = []
	while not is_active() and not pending.is_empty():
		var spec: Dictionary = pending.pop_front()
		var inner: Dictionary = _start(spec, kinds, rng).get("result", {})
		if not inner.is_empty():
			ended.append(inner)
	return ended


func clear_pending() -> void:
	pending.clear()


func _evaluate() -> Dictionary:
	quest.apply_counts(delivery.counts())
	if not quest.all_complete():
		return {}
	delivery.consume(quest.consume_plan())  # BR-U3-12: 필요 개수만 삭제
	quest.status = Quest.Status.SUCCESS
	return {"result": "success", "gold": quest.reward_gold, "exp": quest.reward_exp}
