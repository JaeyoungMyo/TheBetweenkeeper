# 전달 공간 (DeliverySpace). 올라온 아이템 보관, 성공 시에만 소비 (U3 BR-U3-13, 15, 18, 23)
class_name DeliverySpace
extends RefCounted

var items: Array[ItemInstance] = []


func put(item: ItemInstance) -> void:
	item.state = ItemInstance.State.DELIVERED
	items.append(item)


func size() -> int:
	return items.size()


func counts() -> Dictionary:
	var c := {}
	for item in items:
		c[item.data.item_id] = c.get(item.data.item_id, 0) + 1
	return c


## plan: 종류 → 소비 개수. 종류별로 먼저 올라온 아이템부터 꺼낸다. 꺼낸 아이템 목록을 돌려준다 (상태는 SOLD)
func take(plan: Dictionary) -> Array[ItemInstance]:
	var taken: Array[ItemInstance] = []
	for kind in plan.keys():
		var left: int = int(plan[kind])
		for item in items.duplicate():
			if left <= 0:
				break
			if item.data.item_id == kind:
				item.state = ItemInstance.State.SOLD
				items.erase(item)
				taken.append(item)
				left -= 1
	return taken


func consume(plan: Dictionary) -> int:
	return take(plan).size()


## 출력공간 전부 꺼낸다 (상태는 호출한 쪽에서 정한다)
func remove_all() -> Array[ItemInstance]:
	var all: Array[ItemInstance] = items.duplicate()
	items.clear()
	return all
