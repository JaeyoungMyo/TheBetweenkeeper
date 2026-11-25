# 아이템 개체 상태 (ItemInstance). FR-09 상태 (U1 범위: incoming, carried, stored)
class_name ItemInstance
extends RefCounted

enum State { INCOMING, CARRIED, STORED, SOLD }

var instance_id: int
var data: ItemData
var stage_id: int
var state: State = State.INCOMING
var world_position: Vector2 = Vector2.ZERO
var facility_id: String = ""
var slot_index: int = -1
var is_exp_claimed := false


func _init(id: int, item_data: ItemData, stage: int) -> void:
	instance_id = id
	data = item_data
	stage_id = stage


func weight() -> int:
	return data.weight
