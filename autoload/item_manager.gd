# ItemManager (오토로드, U1 소유). 아이템 개체 생성과 들고 있는 아이템 관리 (BR-U1-06)
extends Node

signal item_state_changed(item_id: int, state: int)
signal item_dropped(item_id: int, position: Vector2)
signal weight_rejected(facility_id: String, message: String)
signal item_stored(item: ItemInstance)
signal capacity_changed(capacity: int)

const REJECT_MESSAGE := "무게 초과"

var items: Dictionary = {}
var carried_ids: Array[int] = []
var bag_size: int = 1
var carry_multiplier: int = 1
var _next_id: int = 1
var floor_bounds := Rect2()
var floor_blocked: Array = []


func create_item(data: ItemData, stage_id: int) -> ItemInstance:
	var item := ItemInstance.new(_next_id, data, stage_id)
	items[_next_id] = item
	_next_id += 1
	return item


func capacity() -> int:
	return CarryRules.capacity(bag_size, carry_multiplier)


## 상점 구매 (U2 · U4 에서 호출). 늘었으면 true
func upgrade_bag() -> bool:
	if bag_size >= CarryRules.MAX_BAG:
		return false
	bag_size += 1
	capacity_changed.emit(capacity())
	return true


## 증강 (U2 에서 호출): 1배 → 2배 → 3배
func upgrade_multiplier() -> bool:
	if carry_multiplier >= CarryRules.MAX_MULTIPLIER:
		return false
	carry_multiplier += 1
	capacity_changed.emit(capacity())
	return true


## 바닥 칸 한도 (10개) 를 지키는 낙하 위치
func floor_position(pos: Vector2) -> Vector2:
	var counts := {}
	for it: ItemInstance in items.values():
		if it.state == ItemInstance.State.INCOMING:
			var cell := FloorRules.cell_of(it.world_position)
			counts[cell] = counts.get(cell, 0) + 1
	return FloorRules.resolve(pos, counts, floor_bounds, floor_blocked)


func has_room() -> bool:
	return carried_ids.size() < capacity()


func carried_items() -> Array:
	return carried_ids.map(func(id: int) -> ItemInstance: return items[id])


func try_pick_up(item: ItemInstance, player_pos: Vector2) -> bool:
	if not StorageService.pick_up(item, player_pos, has_room()):
		return false
	carried_ids.append(item.instance_id)
	item_state_changed.emit(item.instance_id, item.state)
	return true


func drop_carried_at(item_id: int, feet_pos: Vector2) -> bool:
	if item_id not in carried_ids:
		return false
	var item: ItemInstance = items[item_id]
	feet_pos = floor_position(feet_pos)
	StorageService.drop_at_feet(item, feet_pos)
	carried_ids.erase(item_id)
	item_dropped.emit(item_id, feet_pos)
	item_state_changed.emit(item_id, item.state)
	return true


func place_carried(item_id: int, facility: FacilityState, slot: int) -> Dictionary:
	if item_id not in carried_ids:
		return {"ok": false, "reason": "not_carried"}
	var item: ItemInstance = items[item_id]
	var result := StorageService.place_into_facility(item, facility, slot)
	if not result["ok"]:
		if result["reason"] == "slot_overweight":
			weight_rejected.emit(facility.facility_id, REJECT_MESSAGE)
		return result
	carried_ids.erase(item_id)
	item_state_changed.emit(item_id, item.state)
	item_stored.emit(item)
	return result


func take_out(item: ItemInstance, facility: FacilityState) -> bool:
	if not has_room() or not StorageService.take_out(item, facility):
		return false
	carried_ids.append(item.instance_id)
	item_state_changed.emit(item.instance_id, item.state)
	return true


## 선반에서 바닥으로 바로 떨어뜨리기 (운반 여유 불필요)
func drop_stored(item: ItemInstance, facility: FacilityState, feet_pos: Vector2) -> bool:
	if not StorageService.take_out(item, facility):
		return false
	var pos := floor_position(feet_pos)
	StorageService.drop_at_feet(item, pos)
	item_dropped.emit(item.instance_id, pos)
	item_state_changed.emit(item.instance_id, item.state)
	return true


## 판매 처리 (들고 있거나 선반 · 바닥에 있는 아이템)
func mark_sold(item: ItemInstance, facility: FacilityState = null) -> bool:
	if item.state == ItemInstance.State.SOLD:
		return false
	if item.state == ItemInstance.State.STORED and (facility == null or not facility.remove(item)):
		return false
	carried_ids.erase(item.instance_id)
	item.state = ItemInstance.State.SOLD
	item.facility_id = ""
	item.slot_index = -1
	item_state_changed.emit(item.instance_id, item.state)
	return true
