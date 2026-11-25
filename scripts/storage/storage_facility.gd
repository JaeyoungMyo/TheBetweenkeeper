# 선반 (StaticBody2D). 칸 3개, 칸당 12 (FD-U1-7). 클릭하면 선반 패널을 연다 (FR-03)
class_name StorageFacility
extends StaticBody2D

@export var data: FacilityData
var state: FacilityState
var facility_id := ""

const SIZE := Vector2(96, 40)


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
	var body := ColorRect.new()
	body.color = Color(0.55, 0.4, 0.25)
	body.size = SIZE
	body.position = -SIZE / 2
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)
	var label := Label.new()
	label.text = data.display_name
	label.position = Vector2(-20, -40)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)


func bounds() -> Rect2:
	return Rect2(global_position - SIZE / 2, SIZE)


func hit(point: Vector2) -> bool:
	return bounds().has_point(point)
