# 줍기 · 적재 · 드롭 규칙 (StorageService). FD-U1-4, FD-U1-5, FD-U1-6
class_name StorageService
extends RefCounted

const PICKUP_RANGE := 48.0
const HOVER_RANGE := 64.0


static func can_pick_up(item: ItemInstance, player_pos: Vector2, hand_empty: bool) -> bool:
	if not hand_empty:
		return false
	if item.state != ItemInstance.State.INCOMING:
		return false
	return item.world_position.distance_to(player_pos) <= PICKUP_RANGE


static func can_hover(item: ItemInstance, player_pos: Vector2) -> bool:
	return item.state == ItemInstance.State.INCOMING and item.world_position.distance_to(player_pos) <= HOVER_RANGE


static func pick_up(item: ItemInstance, player_pos: Vector2, hand_empty: bool) -> bool:
	if not can_pick_up(item, player_pos, hand_empty):
		return false
	item.state = ItemInstance.State.CARRIED
	return true


## 맵 드롭 · 무게 초과 낙하 모두 플레이어 발 아래에 놓는다 (FD-U1-6 X, BR-U1-05). 상태는 incoming.
static func drop_at_feet(item: ItemInstance, feet_pos: Vector2) -> void:
	item.state = ItemInstance.State.INCOMING
	item.world_position = feet_pos
	item.facility_id = ""
	item.slot_index = -1


## 적재 성공 시 {"ok": true}. 실패 시 낙하하고 {"ok": false, "reason": ...} 반환.
static func place_into_facility(item: ItemInstance, facility: FacilityState, slot: int, feet_pos: Vector2) -> Dictionary:
	if item.state != ItemInstance.State.CARRIED:
		return {"ok": false, "reason": "not_carried"}
	var result := facility.store(slot, item)
	if not result["ok"]:
		drop_at_feet(item, feet_pos)
		return result
	item.state = ItemInstance.State.STORED
	item.facility_id = facility.facility_id
	item.slot_index = slot
	return {"ok": true, "reason": ""}


## 선반에서 꺼내기 → carried (BR-U1-13)
static func take_out(item: ItemInstance, facility: FacilityState) -> bool:
	if item.state != ItemInstance.State.STORED:
		return false
	if not facility.remove(item):
		return false
	item.state = ItemInstance.State.CARRIED
	item.facility_id = ""
	item.slot_index = -1
	return true
