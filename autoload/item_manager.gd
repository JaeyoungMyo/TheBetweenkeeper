# ItemManager (오토로드, U1 소유). 아이템 개체 생성과 손에 든 아이템 1개 관리 (BR-U1-06)
extends Node

signal item_state_changed(item_id: int, state: int)
signal item_dropped(item_id: int, position: Vector2)
signal weight_rejected(facility_id: String, message: String)

const REJECT_MESSAGE := "무게 초과"

var items: Dictionary = {}
var _next_id: int = 1
var carried_id: int = -1


func create_item(data: ItemData, stage_id: int) -> ItemInstance:
	var item := ItemInstance.new(_next_id, data, stage_id)
	items[_next_id] = item
	_next_id += 1
	return item


func hand_empty() -> bool:
	return carried_id == -1


func try_pick_up(item: ItemInstance, player_pos: Vector2) -> bool:
	if not StorageService.pick_up(item, player_pos, hand_empty()):
		return false
	carried_id = item.instance_id
	item_state_changed.emit(item.instance_id, item.state)
	return true


func drop_carried_at(feet_pos: Vector2) -> bool:
	if carried_id == -1:
		return false
	var item: ItemInstance = items[carried_id]
	StorageService.drop_at_feet(item, feet_pos)
	carried_id = -1
	item_dropped.emit(item.instance_id, feet_pos)
	item_state_changed.emit(item.instance_id, item.state)
	return true


func place_carried(facility: FacilityState, slot: int, feet_pos: Vector2) -> Dictionary:
	if carried_id == -1:
		return {"ok": false, "reason": "hand_empty"}
	var item: ItemInstance = items[carried_id]
	var result := StorageService.place_into_facility(item, facility, slot, feet_pos)
	carried_id = -1
	if not result["ok"]:
		weight_rejected.emit(facility.facility_id, REJECT_MESSAGE)
		item_dropped.emit(item.instance_id, feet_pos)
	item_state_changed.emit(item.instance_id, item.state)
	return result


func take_out(item: ItemInstance, facility: FacilityState) -> bool:
	if carried_id != -1:
		return false
	if not StorageService.take_out(item, facility):
		return false
	carried_id = item.instance_id
	item_state_changed.emit(item.instance_id, item.state)
	return true
