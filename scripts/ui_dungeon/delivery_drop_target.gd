# 전달 선반 드롭 칸 (U3). 아이템 목록에서 끌어온 들고 있는 아이템을 1개씩 넣는다 (선반 칸과 같은 드래그 방식)
class_name DeliveryDropTarget
extends Control

## 받을 수 있는지 확인 (들고 있고, 선반 가까이 있을 때). 인자: item_id
var accept_check: Callable
## 드롭되었을 때 처리. 인자: item_id
var on_drop: Callable


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("item_id")):
		return false
	return accept_check.is_valid() and accept_check.call(data["item_id"])


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if on_drop.is_valid():
		on_drop.call(data["item_id"])
