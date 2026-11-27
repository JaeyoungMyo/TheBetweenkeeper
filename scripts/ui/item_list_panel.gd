# 들고 있는 아이템 목록, 상시 표시 (FR-02). 마우스 없이 보기만 한다.
class_name ItemListPanel
extends PanelContainer

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
	# 가방 확장은 상점(C)에서만 살 수 있다 (목록에는 버튼을 두지 않는다)


static func describe(items: Array) -> String:
	var lines := []
	for it: ItemInstance in items:
		lines.append("%s (무게 %d)" % [it.data.display_name, it.weight()])
	return "
".join(lines)


static func make_entry(item: ItemInstance) -> Button:
	var b := Button.new()
	b.name = "item-entry-%d" % item.instance_id
	b.text = "%s (무게 %d)" % [item.data.display_name, item.weight()]
	b.icon = item.data.icon()
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.focus_mode = Control.FOCUS_NONE
	return b
