# 아공간 방: 벽, 선반, 플레이어, UI 연결 (U1)
class_name StorageRoom
extends Node2D

const ITEM_IDS := ["potion_hp", "scroll", "sword", "dagger", "axe", "helmet", "shield", "boots", "armor", "ore_box"]
const ROOM := Rect2(320, 110, 640, 460)
const START_SHELVES := 3
## 선반 최대 6개 (economy.json 의 선반 가격 5단계 + 기본 1개)
## 선반 그림은 최대 96 x 85 (6칸). 위치는 선반 바닥선 중심보다 42 위. 줄 사이에 서서 지나갈 공간을 둔다
const SHELF_POSITIONS := [Vector2(640, 175), Vector2(435, 175), Vector2(845, 175), Vector2(435, 365), Vector2(640, 365), Vector2(845, 365)]

var player: PlayerController
## 마지막으로 다가간 선반
var shelf: StorageFacility
var shelves: Array[StorageFacility] = []
var views: Dictionary = {}
var list_panel: ItemListPanel
var shelf_panel: ShelfPanel
var message: Label
var hover_list: Label
var _map: Control


func _ready() -> void:
	ItemManager.floor_blocked = []
	_build_room()
	ItemManager.floor_bounds = ROOM
	_build_ui()
	ItemManager.item_state_changed.connect(_on_state_changed)
	ItemManager.weight_rejected.connect(_on_weight_rejected)
	ItemManager.capacity_changed.connect(_on_capacity_changed)
	_refresh()


func _build_room() -> void:
	var floor_rect := TextureRect.new()
	floor_rect.texture = load("res://art/floor/floor_tile.png")
	floor_rect.stretch_mode = TextureRect.STRETCH_TILE
	floor_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	floor_rect.position = ROOM.position
	floor_rect.size = ROOM.size
	floor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floor_rect)
	var t := 20.0
	_wall(Rect2(ROOM.position.x - t, ROOM.position.y - t, ROOM.size.x + t * 2, t))
	_wall(Rect2(ROOM.position.x - t, ROOM.end.y, ROOM.size.x + t * 2, t))
	_wall(Rect2(ROOM.position.x - t, ROOM.position.y, t, ROOM.size.y))
	_wall(Rect2(ROOM.end.x, ROOM.position.y, t, ROOM.size.y))
	# 초기 선반: 본 게임 3개 (한 던전 입고 약 108 무게). 튜토리얼은 1개 (_initial_shelf_count 재정의)
	for i in _initial_shelf_count():
		add_shelf()
	shelf = shelves[0]
	player = preload("res://scenes/storage/player.tscn").instantiate()
	player.position = ROOM.get_center()
	player.z_index = 1
	add_child(player)


func _initial_shelf_count() -> int:
	return START_SHELVES


## 저장용 선반 목록 (SaveService 가 호출)
func _capture_shelves() -> Array:
	var out := []
	for s in shelves:
		out.append({
			"facility_id": s.state.facility_id,
			"slot_count": s.state.slot_count,
			"slot_items": s.state.slot_items.duplicate(true),
			"slot_weights": s.state.slot_weights.duplicate(true),
		})
	return out


## 이어하기: 저장된 선반 배치와 모든 아이템 표시를 다시 만든다. JSON 숫자는 float 이므로 int 로 바꾼다
func restore_layout(rows: Array) -> void:
	for v in views.values():
		v.queue_free()
	views.clear()
	for s in shelves:
		s.queue_free()
	shelves.clear()
	ItemManager.floor_blocked = []
	for row: Dictionary in rows:
		add_shelf()
		var st: FacilityState = shelves[-1].state
		shelves[-1].facility_id = row["facility_id"]
		st.facility_id = row["facility_id"]
		while st.slot_count < int(row["slot_count"]):
			st.add_slot()
		for i in st.slot_count:
			st.slot_items[i] = []
			st.slot_weights[i] = []
			for id in row["slot_items"][i]:
				st.slot_items[i].append(int(id))
			for w in row["slot_weights"][i]:
				st.slot_weights[i].append(int(w))
	for item: ItemInstance in ItemManager.items.values():
		if item.state != ItemInstance.State.SOLD:
			attach_item(item)
	refresh()


func add_shelf() -> void:
	var s: StorageFacility = preload("res://scenes/storage/storage_facility.tscn").instantiate()
	s.data = load("res://data/facilities/shelf_basic.tres")
	s.facility_id = "shelf_%d" % (shelves.size() + 1)
	s.position = SHELF_POSITIONS[shelves.size()]
	add_child(s)
	shelves.append(s)
	ItemManager.floor_blocked.append(s.bounds())


## 새 선반 자리에 있던 아이템과 플레이어는 선반 앞으로 옮긴다
func buy_shelf() -> bool:
	if not EconomyManager.buy_shelf(shelves.size()):
		return false
	add_shelf()
	var area := shelves[-1].bounds().grow(12)
	var front := Vector2(area.get_center().x, area.end.y + 14)
	for v: ItemView in views.values():
		if v.item.state == ItemInstance.State.INCOMING and area.has_point(v.item.world_position):
			v.item.world_position = ItemManager.floor_position(front)
			v.sync()
	if area.has_point(player.position):
		player.position = front
		player.stop_moving()
	return true


func open_panel() -> void:
	var i := shelves.find(shelf)
	shelf_panel.show_for(shelf.state, ItemManager.items, "선반 %d" % (i + 1), EconomyManager.slot_price(shelf.state, i))


## ↑↓: 패널이 열린 채로 앞/뒤 선반으로 포커스를 옮긴다 (끝에서는 멈춘다). 선반 바꾸면 첫 칸 첫 아이템을 고른다
func _focus_shelf(step: int) -> void:
	var i := shelves.find(shelf) + step
	if i < 0 or i >= shelves.size():
		return
	shelf = shelves[i]
	open_panel()
	shelf_panel.reset_selection()


func buy_current_slot() -> void:
	EconomyManager.buy_slot(shelf.state, shelves.find(shelf))
	_refresh()


func refresh() -> void:
	_refresh()


func shelf_of(item: ItemInstance) -> FacilityState:
	for s in shelves:
		if s.state.facility_id == item.facility_id:
			return s.state
	return shelf.state


func _wall(r: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = r.get_center()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = r.size
	shape.shape = box
	body.add_child(shape)
	var c := ColorRect.new()
	c.size = r.size
	c.position = -r.size / 2
	c.color = Color(0.4, 0.36, 0.5)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(c)
	add_child(body)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_map = preload("res://scripts/ui/drop_target.gd").new()
	_map.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map.accept_check = func(_s: int, id: int) -> bool: return id in ItemManager.items
	_map.dropped.connect(func(_s: int, id: int) -> void: drop_to_floor(id))
	_map.gui_input.connect(_on_map_input)
	layer.add_child(_map)
	list_panel = preload("res://scenes/ui_storage/item_list_panel.tscn").instantiate()
	list_panel.position = Vector2(0, 40)
	layer.add_child(list_panel)
	list_panel.take_out_requested.connect(_on_take_out)
	shelf_panel = preload("res://scenes/ui_storage/shelf_panel.tscn").instantiate()
	shelf_panel.position = Vector2(1015, 60)
	layer.add_child(shelf_panel)
	shelf_panel.closed.connect(shelf_panel.hide)
	shelf_panel.slot_purchase_requested.connect(buy_current_slot)
	shelf_panel.item_clicked.connect(_on_take_out)
	shelf_panel.slot_dropped.connect(func(s: int, id: int) -> void: ItemManager.place_carried(id, shelf.state, s))
	hover_list = Label.new()
	hover_list.name = "hover-item-list"
	hover_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.8)
	style.set_content_margin_all(6)
	hover_list.add_theme_stylebox_override("normal", style)
	hover_list.hide()
	layer.add_child(hover_list)
	message = Label.new()
	message.position = Vector2(560, 20)
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(message)
	var dungeon := DungeonUi.new()
	dungeon.name = "DungeonUi"
	dungeon.room = self
	add_child(dungeon)
	SaveService.shelves_provider = Callable(self, "_capture_shelves")
	var settings := SettingsPanel.new()
	settings.name = "SettingsPanel"
	add_child(settings)
	var pause := PauseMenu.new()
	pause.name = "PauseMenu"
	add_child(pause)
	var growth := GrowthUi.new()
	growth.name = "GrowthUi"
	growth.room = self
	add_child(growth)
	EconomyManager.gold_changed.connect(_on_gold_changed)
	if OS.is_debug_build():
		var debug := DebugMenu.new()
		debug.name = "DebugMenu"
		debug.room = self
		add_child(debug)


## 들고 있거나 선반에 있는 아이템을 플레이어 발 아래 바닥에 떨어뜨린다
func drop_to_floor(id: int) -> void:
	if not ItemManager.drop_carried_at(id, player.feet_position()):
		ItemManager.drop_stored(ItemManager.items[id], shelf_of(ItemManager.items[id]), player.feet_position())


func add_item(data: ItemData, pos: Vector2) -> ItemInstance:
	var item: ItemInstance = ItemManager.create_item(data, 0)
	item.world_position = ItemManager.floor_position(pos)
	attach_item(item)
	return item


## 이미 만들어진 아이템에 맵 표시 (상점 구매품, 출력공간에서 나온 아이템)
func attach_item(item: ItemInstance) -> void:
	var view: ItemView = preload("res://scenes/storage/item.tscn").instantiate()
	add_child(view)
	view.setup(item)
	views[item.instance_id] = view


func show_message(text: String) -> void:
	message.text = text
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(func() -> void: message.text = "")


func _process(_d: float) -> void:
	for v: ItemView in views.values():
		if v.item.state == ItemInstance.State.CARRIED:
			v.position = player.position + Vector2(0, -18 - 8 * ItemManager.carried_ids.find(v.item.instance_id))
	_update_hover(get_global_mouse_position())
	if shelf_panel.visible and not _near_any_shelf():
		shelf_panel.hide()
	if shelf_panel.visible and Input.is_action_just_pressed("slot_add"):
		buy_current_slot()
	# X: 선반이 열려 있고 고른 아이템이 있으면 그것을 꺼내고, 아니면 가까운 아이템을 줍는다
	if Input.is_action_just_pressed("interact"):
		if shelf_panel.visible and shelf_panel.selected_id() >= 0:
			_on_take_out(shelf_panel.selected_id())
		else:
			interact()
	if Input.is_action_just_pressed("open_shelf"):
		toggle_shelf()
	# 선반 패널이 열려 있으면 이동을 잠그고, ←→ 로 고른 뒤 X 로 꺼낸다
	player.locked = shelf_panel.visible
	if shelf_panel.visible:
		# ←→: 같은 칸 안에서 아이템 고르기 / ↑↓: 다른 선반으로 포커스 이동
		if Input.is_action_just_pressed("shelf_left"):
			shelf_panel.move_selection(-1)
		if Input.is_action_just_pressed("shelf_right"):
			shelf_panel.move_selection(1)
		if Input.is_action_just_pressed("shelf_up"):
			_focus_shelf(-1)
		if Input.is_action_just_pressed("shelf_down"):
			_focus_shelf(1)
	if Input.is_action_just_pressed("drop_item"):
		drop_first()
	for i in 6:
		if Input.is_action_just_pressed("slot_%d" % (i + 1)):
			store_in_slot(i)


## Z: 목록 맨 위 아이템을 발 아래에 내려놓는다
## 전달 선반 등 다른 곳이 Z 를 가로챌 때 쓴다. true 를 돌려주면 바닥에 내려놓지 않는다
var drop_override: Callable


func drop_first() -> void:
	if drop_override.is_valid() and drop_override.call():
		return
	if not ItemManager.carried_ids.is_empty():
		drop_to_floor(ItemManager.carried_ids[0])


## 숫자 키 1~6: 패널이 열려 있으면 목록 맨 위 아이템을 해당 칸에 적재
## 숫자 키 1~6 (선반 열림 상태): 들고 있는 맨 위 아이템을 그 칸에 넣는다 (꺼내기는 ←→ 고른 뒤 X 또는 클릭)
func store_in_slot(slot: int) -> void:
	if not shelf_panel.visible or slot >= shelf.state.slot_count:
		return
	if ItemManager.carried_ids.is_empty():
		show_message("들고 있는 아이템이 없습니다. ←→ 로 고르고 X 로 꺼내세요")
		return
	ItemManager.place_carried(ItemManager.carried_ids[0], shelf.state, slot)


## 선반에서 꺼낸 뒤 호출 (튜토리얼이 확인에 쓴다)
func on_take_out_done() -> void:
	pass


## 앞에 있는 선반을 현재 선반으로 고른다 (패널이 열려 있으면 유지)
## 어느 선반이든 가까이 있는지 (↑↓ 로 먼 선반을 보고 있어도 패널을 유지한다)
func _near_any_shelf() -> bool:
	for s in shelves:
		if StorageService.near_rect(player.global_position, s.bounds()):
			return true
	return false


func near_shelf() -> bool:
	if not shelf_panel.visible:
		for s in shelves:
			if StorageService.near_rect(player.global_position, s.bounds()):
				shelf = s
				return true
	return StorageService.near_rect(player.global_position, shelf.bounds())


## X: 가까운 아이템 줍기 (선반 열고 닫기는 E 만 쓴다)
func interact() -> void:
	if not _pick_nearest():
		if not ItemManager.has_room() and _has_pickable_nearby():
			show_message("더 들 수 없습니다 (손이 가득 찼습니다)")


## E 로 닫았는지 기록 (튜토리얼의 선반 닫기 단계가 본다. 멀어져서 닫힌 것과 구분)
var shelf_closed_by_key := false


func toggle_shelf() -> void:
	if shelf_panel.visible:
		shelf_panel.hide()
		shelf_closed_by_key = true
	elif near_shelf():
		open_panel()


## 마우스 아래 아이템과 같은 바닥 칸에 있는 아이템 전체
func items_under(point: Vector2) -> Array:
	var cells := {}
	for v: ItemView in views.values():
		if v.hit(point) and StorageService.can_hover(v.item, player.position):
			cells[FloorRules.cell_of(v.item.world_position)] = true
	var found := []
	for v: ItemView in views.values():
		if v.item.state == ItemInstance.State.INCOMING and cells.has(FloorRules.cell_of(v.item.world_position)):
			found.append(v.item)
	return found


func _update_hover(mouse: Vector2) -> void:
	var found := items_under(mouse)
	hover_list.visible = not found.is_empty()
	if hover_list.visible:
		hover_list.text = ItemListPanel.describe(found)
		hover_list.reset_size()
		hover_list.position = (mouse + Vector2(16, 16)).min(Vector2(1280, 720) - hover_list.size)


func _has_pickable_nearby() -> bool:
	for v: ItemView in views.values():
		if v.item.state == ItemInstance.State.INCOMING and player.position.distance_to(v.item.world_position) <= StorageService.PICKUP_RANGE:
			return true
	return false


func _pick_nearest() -> bool:
	var best: ItemInstance = null
	for v: ItemView in views.values():
		if StorageService.can_pick_up(v.item, player.position, ItemManager.has_room()):
			if best == null or v.item.world_position.distance_to(player.position) < best.world_position.distance_to(player.position):
				best = v.item
	return best != null and ItemManager.try_pick_up(best, player.position)


func _on_map_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	for v: ItemView in views.values():
		if v.item.state == ItemInstance.State.INCOMING and v.hit(event.position):
			if not ItemManager.has_room():
				show_message("더 들 수 없습니다")
			elif not ItemManager.try_pick_up(v.item, player.position):
				player.move_to(_walkable(event.position))
			return
	for s in shelves:
		if not s.hit(event.position):
			continue
		if shelf_panel.visible and s == shelf:
			shelf_panel.hide()
		elif StorageService.near_rect(player.global_position, s.bounds()):
			shelf = s
			open_panel()
		else:
			player.move_to(_walkable(event.position))
		return
	if ROOM.has_point(event.position):
		player.move_to(_walkable(event.position))


func _walkable(point: Vector2) -> Vector2:
	return point.clamp(ROOM.position + Vector2(10, 10), ROOM.end - Vector2(10, 10))


func _on_take_out(id: int) -> void:
	if not ItemManager.take_out(ItemManager.items[id], shelf_of(ItemManager.items[id])):
		show_message("더 들 수 없습니다")
	else:
		on_take_out_done()


func _on_weight_rejected(_facility_id: String, text: String) -> void:
	show_message(text)


func _on_state_changed(id: int, _state: int) -> void:
	if views.has(id):
		views[id].sync()
	_refresh()


func _refresh() -> void:
	ItemManager.floor_blocked = []
	for i in shelves.size():
		shelves[i].shelf_index = i
		shelves[i].refresh_look()
		ItemManager.floor_blocked.append(shelves[i].bounds())
	list_panel.refresh(ItemManager.carried_items(), ItemManager.capacity())
	if shelf_panel.visible:
		open_panel()


func _on_capacity_changed(_capacity: int) -> void:
	_refresh()


func _on_gold_changed(_amount: int) -> void:
	_refresh()
