# 선반 (StaticBody2D). 칸 3개, 칸당 12 (FD-U1-7). 클릭하면 선반 패널을 연다 (FR-03)
# 그림: 칸 수에 따라 2단 · 3단 책장을 옆으로 붙인다 (3 = 3, 4 = 2+2, 5 = 3+2, 6 = 3+3)
# 찬 칸에는 들어 있는 아이템 아이콘을 단 위에 작게 그린다
class_name StorageFacility
extends StaticBody2D

@export var data: FacilityData
var state: FacilityState
var facility_id := ""
## 선반 번호 (0부터). 번호마다 색이 달라진다
var shelf_index := 0
var body: Node2D

## 선반 번호별 색 (1, 2, 3, ...)
const TINTS := [Color(1, 1, 1), Color(0.85, 0.92, 1.0), Color(0.88, 1.0, 0.85), Color(1.0, 0.9, 0.85), Color(0.95, 0.88, 1.0), Color(1.0, 1.0, 0.85)]
const SHEET := preload("res://art/shelf/shelf_sheet.png")
## 시트 안 책장 영역: 2단, 3단 (너비 48)
const PIECE_RECTS := {2: Rect2(216, 92, 48, 70), 3: Rect2(120, 77, 48, 85)}
## 칸 수별 조합 (왼쪽 → 오른쪽)
const COMBOS := {1: [2], 2: [2], 3: [3], 4: [2, 2], 5: [3, 2], 6: [3, 3]}
const PIECE_W := 48.0
## 단 안쪽: 첫 단 위쪽 y, 단 간격, 단 높이, 좌우 여백
const TIER_TOP := 22.0
const TIER_STEP := 15.0
const TIER_H := 12.0
const TIER_PAD := 6.0
const ICON_SIZE := 10.0
## 선반 바닥선은 position.y + FOOT 에 맞춘다 (칸 수가 바뀌어도 바닥은 그대로)
const FOOT := 42.0

var _shape: RectangleShape2D
var _icons: Array = []


func _ready() -> void:
	if data == null:
		data = FacilityData.new()
		data.facility_id = "shelf_basic"
		data.display_name = "선반"
	state = FacilityState.new(facility_id if facility_id != "" else data.facility_id, data.slot_count, data.slot_weight_limit)
	var shape := CollisionShape2D.new()
	_shape = RectangleShape2D.new()
	shape.shape = _shape
	add_child(shape)
	body = Node2D.new()
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(body)
	var label := Label.new()
	label.name = "ShelfLabel"
	label.text = data.display_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	refresh_look()


func combo() -> Array:
	return COMBOS[clampi(state.slot_count, 1, 6)]


## 현재 칸 수에서 그림 크기
func size() -> Vector2:
	var h := 0.0
	for tiers in combo():
		h = maxf(h, (PIECE_RECTS[tiers] as Rect2).size.y)
	return Vector2(PIECE_W * combo().size(), h)


func bounds() -> Rect2:
	var sz := size()
	return Rect2(global_position + Vector2(-sz.x / 2, FOOT - sz.y), sz)


func hit(point: Vector2) -> bool:
	return bounds().has_point(point)


## 칸 번호 → 그림 안 단 영역 (로컬 좌표). 왼쪽 책장의 위 단부터 차례로 센다
func tier_rect(slot: int) -> Rect2:
	var sz := size()
	var left := -sz.x / 2
	var n := slot
	var col := 0
	for tiers in combo():
		if n < tiers:
			var top: float = FOOT - (PIECE_RECTS[tiers] as Rect2).size.y
			return Rect2(left + col * PIECE_W + TIER_PAD, top + TIER_TOP + n * TIER_STEP, PIECE_W - TIER_PAD * 2, TIER_H)
		n -= tiers
		col += 1
	return Rect2()


## 칸 수에 맞는 책장 그림과 칸별 아이템 아이콘을 다시 그린다 (번호별 색)
func refresh_look() -> void:
	if body == null or state == null:
		return
	for c in body.get_children():
		c.queue_free()
	var sz := size()
	_shape.size = sz
	(get_child(0) as CollisionShape2D).position = Vector2(0, FOOT - sz.y / 2)
	body.modulate = TINTS[shelf_index % TINTS.size()]
	var x := -sz.x / 2
	for tiers in combo():
		var piece := Sprite2D.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = SHEET
		atlas.region = PIECE_RECTS[tiers]
		piece.texture = atlas
		piece.centered = false
		piece.position = Vector2(x, FOOT - atlas.region.size.y)
		body.add_child(piece)
		x += PIECE_W
	_draw_contents()
	var label := get_node_or_null("ShelfLabel") as Label
	if label:
		label.position = Vector2(-20, FOOT - sz.y - 22)


## 찬 칸: 들어 있는 아이템 아이콘을 단 위에 나란히 (넘치면 겹쳐서) 놓는다
func _draw_contents() -> void:
	for slot in state.slot_count:
		var ids: Array = state.slot_items[slot]
		if ids.is_empty():
			continue
		var r := tier_rect(slot)
		var step := minf(ICON_SIZE, (r.size.x - ICON_SIZE) / maxf(1, ids.size() - 1))
		for k in ids.size():
			var item: ItemInstance = ItemManager.items.get(ids[k])
			if item == null:
				continue
			var tex: Texture2D = item.data.icon()
			if tex == null:
				continue
			var icon := Sprite2D.new()
			icon.texture = tex
			icon.centered = false
			icon.scale = Vector2.ONE * ICON_SIZE / tex.get_size().x
			icon.position = Vector2(r.position.x + k * step, r.end.y - ICON_SIZE)
			icon.modulate = Color(1, 1, 1) / body.modulate  # 아이콘은 선반 색에 물들지 않게
			body.add_child(icon)
