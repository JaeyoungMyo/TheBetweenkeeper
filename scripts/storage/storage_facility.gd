# 선반 (StaticBody2D). 칸 3개, 칸당 12 (FD-U1-7). 클릭하면 선반 패널을 연다 (FR-03)
class_name StorageFacility
extends StaticBody2D

@export var data: FacilityData
var state: FacilityState
var facility_id := ""
## 선반 번호 (0부터). 번호마다 색이 달라진다
var shelf_index := 0
var body: TextureRect

## 선반 번호별 색 (1, 2, 3, ...)
const TINTS := [Color(1, 1, 1), Color(0.7, 0.85, 1.0), Color(0.75, 1.0, 0.7), Color(1.0, 0.8, 0.7), Color(0.9, 0.75, 1.0), Color(1.0, 1.0, 0.7)]
const EMPTY_TEX := preload("res://art/shelf/shelf_empty.png")
const FULL_TEX := preload("res://art/shelf/shelf_full.png")

const SIZE := Vector2(40, 40)


func _ready() -> void:
	if data == null:
		data = FacilityData.new()
		data.facility_id = "shelf_basic"
		data.display_name = "선반"
	state = FacilityState.new(facility_id if facility_id != "" else data.facility_id, data.slot_count, data.slot_weight_limit)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	shape.shape = rect
	add_child(shape)
	body = TextureRect.new()
	body.stretch_mode = TextureRect.STRETCH_SCALE
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.size = SIZE
	body.position = -SIZE / 2
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)
	refresh_look()
	var label := Label.new()
	label.text = data.display_name
	label.position = Vector2(-20, -40)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)


func bounds() -> Rect2:
	return Rect2(global_position - SIZE / 2, SIZE)


func hit(point: Vector2) -> bool:
	return bounds().has_point(point)


## 빈 선반과 아이템이 있는 선반의 그림을 다르게 보여 준다 (번호별 색 + 안에 든 아이템 아이콘)
var _icons: HBoxContainer

func refresh_look() -> void:
	if body == null or state == null:
		return
	if _icons == null:
		_icons = HBoxContainer.new()
		_icons.position = Vector2(-SIZE.x / 2 + 6, -4)
		_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_icons)
	for c in _icons.get_children():
		_icons.remove_child(c)
		c.queue_free()
	var shown := 0
	for ids in state.slot_items:
		for id in ids:
			if shown >= 5 or not ItemManager.items.has(id):
				continue
			var r := TextureRect.new()
			r.texture = ItemManager.items[id].data.icon()
			r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			r.custom_minimum_size = Vector2(16, 16)
			r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_icons.add_child(r)
			shown += 1
	body.texture = FULL_TEX if shown > 0 else EMPTY_TEX
	body.modulate = TINTS[shelf_index % TINTS.size()]
