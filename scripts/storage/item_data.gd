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
## 아이콘: 스프라이트 시트와 16px 칸 좌표 (열, 행)
@export var icon_sheet: Texture2D
@export var icon_cell := Vector2i.ZERO

const ICON_PX := 16


func is_valid() -> bool:
	return WeightRules.is_valid_item_weight(weight) and item_id != ""


func weight_class() -> String:
	return WeightRules.weight_class(weight)


## 아이콘 한 칸을 잘라 낸 텍스처. 시트가 없으면 null
func icon() -> Texture2D:
	if icon_sheet == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = icon_sheet
	atlas.region = Rect2(Vector2(icon_cell) * ICON_PX, Vector2(ICON_PX, ICON_PX))
	return atlas
