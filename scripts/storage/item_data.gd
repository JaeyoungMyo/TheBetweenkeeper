# 아이템 종류 정의 (ItemData). NFR-05: 종류 데이터와 개체 상태 분리
class_name ItemData
extends Resource

@export var item_id: String = ""
@export var display_name: String = ""
@export var category: String = ""
@export var weight: int = 1
@export var footprint: Vector2 = Vector2(16, 16)
@export var base_price: int = 0
@export var exp_value: int = 0
@export var allowed_facilities: Array[String] = ["shelf_basic"]


func is_valid() -> bool:
	return WeightRules.is_valid_item_weight(weight) and item_id != ""


func weight_class() -> String:
	return WeightRules.weight_class(weight)
