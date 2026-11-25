# 맵 위 아이템 표시. 호버 시 이름 표시 (FR-05, D-16)
class_name ItemView
extends Node2D

var item: ItemInstance
var _label: Label
var _box: ColorRect

const SIZE := Vector2(14, 14)
const COLORS := {"light": Color(0.6, 0.9, 0.5), "medium": Color(0.95, 0.8, 0.35), "heavy": Color(0.9, 0.45, 0.35)}


func setup(instance: ItemInstance) -> void:
	item = instance
	_box = ColorRect.new()
	_box.size = SIZE
	_box.position = -SIZE / 2
	_box.color = COLORS.get(item.data.weight_class(), Color.WHITE)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	_label = Label.new()
	_label.text = "%s (%d)" % [item.data.display_name, item.data.weight]
	_label.position = Vector2(-30, -28)
	_label.visible = false
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	sync()


func sync() -> void:
	position = item.world_position
	visible = item.state != ItemInstance.State.STORED


func set_hover(on: bool) -> void:
	if _label:
		_label.visible = on


func hit(point: Vector2) -> bool:
	return Rect2(position - SIZE / 2, SIZE).grow(2).has_point(point)
