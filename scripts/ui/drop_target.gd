# 드롭 대상. 선반 칸 (slot_index >= 0) 또는 맵 (slot_index = -1, 패널 닫힘 상태에서만)
extends Control

signal dropped(slot_index: int, item_id: int)

var slot_index: int = -1
var accept_check: Callable


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("item_id")):
		return false
	if accept_check.is_valid():
		return accept_check.call(slot_index, data["item_id"])
	return true


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	dropped.emit(slot_index, data["item_id"])
