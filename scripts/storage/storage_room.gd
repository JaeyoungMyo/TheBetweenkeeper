# 아공간 방: 벽, 선반, 플레이어, UI 연결 (U1)
class_name StorageRoom
extends Node2D

const ROOM := Rect2(220, 60, 780, 600)

var player: PlayerController
var shelf: StorageFacility
var views: Dictionary = {}
var list_panel: ItemListPanel
var shelf_panel: ShelfPanel
var message: Label
var hover_list: Label
var _map: Control


func _ready() -> void:
	_build_room()
	_build_ui()
	ItemManager.item_state_changed.connect(_on_state_changed)
	ItemManager.weight_rejected.connect(_on_weight_rejected)
	ItemManager.capacity_changed.connect(_on_capacity_changed)
	_refresh()


func _build_room() -> void:
	var floor_rect := ColorRect.new()
	floor_rect.position = ROOM.position
	floor_rect.size = ROOM.size
	floor_rect.color = Color(0.16, 0.14, 0.22)
	floor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floor_rect)
	var t := 20.0
	_wall(Rect2(ROOM.position.x - t, ROOM.position.y - t, ROOM.size.x + t * 2, t))
	_wall(Rect2(ROOM.position.x - t, ROOM.end.y, ROOM.size.x + t * 2, t))
	_wall(Rect2(ROOM.position.x - t, ROOM.position.y, t, ROOM.size.y))
	_wall(Rect2(ROOM.end.x, ROOM.position.y, t, ROOM.size.y))
	shelf = preload("res://scenes/storage/storage_facility.tscn").instantiate()
	shelf.data = load("res://data/facilities/shelf_basic.tres")
	shelf.position = Vector2(610, 140)
	add_child(shelf)
	player = preload("res://scenes/storage/player.tscn").instantiate()
	player.position = ROOM.get_center()
	player.z_index = 1
	add_child(player)


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
	_map.accept_check = func(_s: int, id: int) -> bool: return not shelf_panel.visible and id in ItemManager.carried_ids
	_map.dropped.connect(func(_s: int, id: int) -> void: ItemManager.drop_carried_at(id, player.feet_position()))
	_map.gui_input.connect(_on_map_input)
	layer.add_child(_map)
	list_panel = preload("res://scenes/ui_storage/item_list_panel.tscn").instantiate()
	list_panel.position = Vector2(0, 60)
	layer.add_child(list_panel)
	list_panel.take_out_requested.connect(_on_take_out)
	shelf_panel = preload("res://scenes/ui_storage/shelf_panel.tscn").instantiate()
	shelf_panel.position = Vector2(1015, 60)
	layer.add_child(shelf_panel)
	shelf_panel.closed.connect(shelf_panel.hide)
	shelf_panel.slot_dropped.connect(func(s: int, id: int) -> void: ItemManager.place_carried(id, shelf.state, s, player.feet_position()))
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


func add_item(data: ItemData, pos: Vector2) -> ItemInstance:
	var item: ItemInstance = ItemManager.create_item(data, 0)
	item.world_position = pos
	var view: ItemView = preload("res://scenes/storage/item.tscn").instantiate()
	add_child(view)
	view.setup(item)
	views[item.instance_id] = view
	return item


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
	if shelf_panel.visible and not near_shelf():
		shelf_panel.hide()
	if Input.is_action_just_pressed("interact"):
		interact()


func near_shelf() -> bool:
	return StorageService.near_rect(player.global_position, shelf.bounds())


## X (또는 E): 열린 패널 닫기 → 가까운 아이템 줍기 → 선반 앞이면 패널 열기
func interact() -> void:
	if shelf_panel.visible:
		shelf_panel.hide()
	elif not _pick_nearest():
		toggle_shelf()


func toggle_shelf() -> void:
	if shelf_panel.visible:
		shelf_panel.hide()
	elif near_shelf():
		shelf_panel.show_for(shelf.state, ItemManager.items)


## 마우스 아래 겹쳐 있는 바닥 아이템 전체
func items_under(point: Vector2) -> Array:
	var found := []
	for v: ItemView in views.values():
		if v.hit(point) and StorageService.can_hover(v.item, player.position):
			found.append(v.item)
	return found


func _update_hover(mouse: Vector2) -> void:
	var found := items_under(mouse)
	hover_list.visible = not found.is_empty()
	if hover_list.visible:
		hover_list.text = ItemListPanel.describe(found)
		hover_list.reset_size()
		hover_list.position = (mouse + Vector2(16, 16)).min(Vector2(1280, 720) - hover_list.size)


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
			if not ItemManager.try_pick_up(v.item, player.position):
				show_message("주울 수 없습니다")
			return
	if shelf.hit(event.position):
		if not near_shelf():
			show_message("선반 앞으로 가까이 가세요")
		toggle_shelf()


func _on_take_out(id: int) -> void:
	if not ItemManager.take_out(ItemManager.items[id], shelf.state):
		show_message("더 들 수 없습니다")


func _on_weight_rejected(_facility_id: String, text: String) -> void:
	show_message(text)


func _on_state_changed(id: int, _state: int) -> void:
	if views.has(id):
		views[id].sync()
	_refresh()


func _refresh() -> void:
	list_panel.refresh(ItemManager.carried_items(), ItemManager.capacity())
	if shelf_panel.visible:
		shelf_panel.show_for(shelf.state, ItemManager.items)


func _on_capacity_changed(_capacity: int) -> void:
	_refresh()
