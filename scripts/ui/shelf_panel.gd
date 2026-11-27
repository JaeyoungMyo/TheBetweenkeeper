# 선반 패널: 칸 3개와 X 버튼 (FR-03)
class_name ShelfPanel
extends PanelContainer

signal slot_dropped(slot_index: int, item_id: int)
signal closed
signal slot_purchase_requested
## 선반 칸의 아이템을 클릭했을 때 (바로 들기)
signal item_clicked(item_id: int)

var _box := VBoxContainer.new()
## 키보드 선택: ↑↓ 로 칸을 고르고, ←→ 로 그 칸 안의 아이템을 고른다
var _order: Array[int] = []
## 칸별 아이템 id 목록과 선택된 칸
var _slot_ids: Array = []
var _sel_slot := 0
var _slot_bgs: Array = []
var _buttons := {}
var _selected_id := -1
## 아이템 id → 칸 번호
var _slot_of := {}


func _ready() -> void:
	custom_minimum_size = Vector2(260, 480)
	add_child(_box)
	hide()


func show_for(state: FacilityState, items: Dictionary, title := "", price := -2) -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	var x := Button.new()
	x.name = "shelf-close-button"
	x.text = "선반 닫기 (E)"
	x.focus_mode = Control.FOCUS_NONE
	x.pressed.connect(func() -> void: closed.emit())
	_box.add_child(x)
	if title != "":
		var buy := Button.new()
		buy.name = "shelf-buy-slot-button"
		buy.text = "%s 칸 추가 (+ 키) - %s" % [title, "최대" if price < 0 else "%d 골드" % price]
		buy.disabled = price < 0 or price > EconomyManager.gold()
		buy.focus_mode = Control.FOCUS_NONE
		buy.pressed.connect(func() -> void: slot_purchase_requested.emit())
		_box.add_child(buy)
	_order.clear()
	_buttons.clear()
	_slot_of.clear()
	_slot_ids.clear()
	_slot_bgs.clear()
	for i in state.slot_count:
		_box.add_child(_make_slot(state, items, i))
	_sel_slot = clampi(_sel_slot, 0, state.slot_count - 1)
	if _slot_of.has(_selected_id):
		_sel_slot = _slot_of[_selected_id]
	else:
		_selected_id = _first_in(_sel_slot)
	_highlight()
	show()


## ←/→ (delta -1/+1): 선택된 칸 안의 아이템을 고른다 (칸 안에서 순환)
func move_selection(delta: int) -> void:
	var ids: Array = _slot_ids[_sel_slot] if _sel_slot < _slot_ids.size() else []
	if ids.is_empty():
		return
	var idx := ids.find(_selected_id)
	_selected_id = ids[posmod(idx + delta, ids.size())] if idx >= 0 else ids[0]
	_highlight()


## ↑/↓ (delta -1/+1): 칸 1 ↔ 칸 N 사이를 옮긴다 (순환). 옮긴 칸의 첫 아이템을 고른다
func move_slot(delta: int) -> void:
	if _slot_ids.is_empty():
		return
	_sel_slot = posmod(_sel_slot + delta, _slot_ids.size())
	_selected_id = _first_in(_sel_slot)
	_highlight()


## 선반을 새로 열었을 때: 칸 1 의 첫 아이템을 고른다 (없으면 -1)
func reset_selection() -> void:
	_sel_slot = 0
	_selected_id = _first_in(0)
	_highlight()


func selected_slot() -> int:
	return _sel_slot


func _first_in(slot: int) -> int:
	if slot < 0 or slot >= _slot_ids.size() or _slot_ids[slot].is_empty():
		return -1
	return _slot_ids[slot][0]


## X: 선택된 아이템 id (없으면 -1)
func selected_id() -> int:
	return _selected_id


func _highlight() -> void:
	for id in _buttons:
		var b: Button = _buttons[id]
		b.modulate = Color(1.0, 0.92, 0.45) if id == _selected_id else Color.WHITE
	for i in _slot_bgs.size():
		_slot_bgs[i].color = Color(0.36, 0.28, 0.14) if i == _sel_slot else Color(0.2, 0.16, 0.12)


func _make_slot(state: FacilityState, items: Dictionary, i: int) -> Control:
	var slot := preload("res://scripts/ui/drop_target.gd").new()
	slot.name = "shelf-slot-%d" % i
	slot.slot_index = i
	slot.custom_minimum_size = Vector2(250, 470.0 / state.slot_count - 10)
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
	_slot_bgs.append(bg)
	_slot_ids.append(state.slot_items[i].duplicate())
	# 칸 안의 아이템은 스크롤 격자에 작은 칸으로 보인다 (6개 이상도 모두 보이고 누를 수 있다)
	var label := Label.new()
	label.text = "[%d] 칸 %d: %d / %d" % [i + 1, i + 1, WeightRules.total(state.slot_weights[i]), state.slot_limit]
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = Vector2(4, 2)
	slot.add_child(label)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, 22)
	scroll.size = Vector2(250, slot.custom_minimum_size.y - 24)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	slot.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	scroll.add_child(grid)
	for id in state.slot_items[i]:
		var item: ItemInstance = items[id]
		var entry := _compact_entry(item)
		entry.tooltip_text = "%s (무게 %d)" % [item.data.display_name, item.weight()]
		var clicked_id: int = id
		entry.pressed.connect(func() -> void: item_clicked.emit(clicked_id))
		grid.add_child(entry)
		_order.append(id)
		_buttons[id] = entry
		_slot_of[id] = i
	return slot


## 선반 칸용 작은 항목: 아이콘 + 짧은 이름 (칸에 많이 들어가도록)
func _compact_entry(item: ItemInstance) -> Button:
	var b: Button = preload("res://scripts/ui/item_list_entry.gd").new()
	b.name = "item-entry-%d" % item.instance_id
	b.item_id = item.instance_id
	b.text = item.data.display_name
	b.icon = item.data.icon()
	b.expand_icon = true
	b.custom_minimum_size = Vector2(76, 30)
	b.clip_text = true
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.focus_mode = Control.FOCUS_NONE
	return b
