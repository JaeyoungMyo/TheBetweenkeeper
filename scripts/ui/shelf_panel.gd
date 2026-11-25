# 선반 패널: 칸 3개와 X 버튼 (FR-03)
class_name ShelfPanel
extends PanelContainer

signal slot_dropped(slot_index: int, item_id: int)
signal closed

var _box := VBoxContainer.new()


func _ready() -> void:
	custom_minimum_size = Vector2(260, 480)
	add_child(_box)
	hide()


func show_for(state: FacilityState, items: Dictionary) -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	var x := Button.new()
	x.name = "shelf-close-button"
	x.text = "X"
	x.focus_mode = Control.FOCUS_NONE
	x.pressed.connect(func() -> void: closed.emit())
	_box.add_child(x)
	for i in state.slot_count:
		_box.add_child(_make_slot(state, items, i))
	show()


func _make_slot(state: FacilityState, items: Dictionary, i: int) -> Control:
	var slot := preload("res://scripts/ui/drop_target.gd").new()
	slot.name = "shelf-slot-%d" % i
	slot.slot_index = i
	slot.custom_minimum_size = Vector2(250, 500.0 / state.slot_count - 10)
	slot.dropped.connect(func(s: int, id: int) -> void: slot_dropped.emit(s, id))
	# 이미 선반에 있는 아이템은 먼저 목록으로 꺼내야 한다
	slot.accept_check = func(_s: int, id: int) -> bool: return id in ItemManager.carried_ids
	var slot_items: Array = state.slot_items[i].map(func(id: int) -> ItemInstance: return items[id])
	slot.tooltip_text = ItemListPanel.describe(slot_items)
	var bg := ColorRect.new()
	bg.color = Color(0.2, 0.16, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(bg)
	var flow := HFlowContainer.new()
	flow.set_anchors_preset(Control.PRESET_FULL_RECT)
	flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(flow)
	var label := Label.new()
	label.text = "[%d] 칸 %d: %d / %d" % [i + 1, i + 1, WeightRules.total(state.slot_weights[i]), state.slot_limit]
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flow.add_child(label)
	for id in state.slot_items[i]:
		var entry := ItemListPanel.make_entry(items[id])
		entry.tooltip_text = slot.tooltip_text
		flow.add_child(entry)
	return slot
