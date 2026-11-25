# 들고 있는 아이템 목록, 상시 표시 (FR-02). 선반에서 꺼내기 드롭도 받는다.
class_name ItemListPanel
extends PanelContainer

signal take_out_requested(item_id: int)

var _box := VBoxContainer.new()


func _ready() -> void:
	custom_minimum_size = Vector2(200, 300)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)


func refresh(items: Array, capacity: int) -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	var title := Label.new()
	title.text = "아이템 목록 (%d / %d)" % [items.size(), capacity]
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(title)
	for item in items:
		_box.add_child(make_entry(item))


static func make_entry(item: ItemInstance) -> Button:
	var b: Button = preload("res://scripts/ui/item_list_entry.gd").new()
	b.name = "item-entry-%d" % item.instance_id
	b.item_id = item.instance_id
	b.text = "%s (무게 %d)" % [item.data.display_name, item.weight()]
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.focus_mode = Control.FOCUS_NONE
	return b


func _can_drop_data(_p: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("item_id") and data["item_id"] not in ItemManager.carried_ids


func _drop_data(_p: Vector2, data: Variant) -> void:
	take_out_requested.emit(data["item_id"])
