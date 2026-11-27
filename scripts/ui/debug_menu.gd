# F1 디버그 메뉴. 디버그 빌드에서만 동작 (배포 빌드에서는 생성하지 않음)
class_name DebugMenu
extends CanvasLayer

var room: StorageRoom
var panel := PanelContainer.new()
var _box := VBoxContainer.new()


func _ready() -> void:
	layer = 3
	panel.position = Vector2(230, 70)
	panel.add_child(_box)
	panel.hide()
	add_child(panel)
	_add("골드 +100", func() -> void: EconomyManager.add_gold(100))
	_add("골드 +1000", func() -> void: EconomyManager.add_gold(1000))
	_add("EXP +20", func() -> void: EconomyManager.add_exp(20))
	_add("레벨업", func() -> void: EconomyManager.add_exp(EconomyManager.exp_to_next() - EconomyManager.exp_points))
	_add("가방 +1", func() -> void: ItemManager.upgrade_bag())
	_add("아이템 1개 생성", func() -> void: spawn(1))
	_add("아이템 10개 생성", func() -> void: spawn(10))
	_add("퀘스트 발생", func() -> void: DungeonManager.debug_spawn_quest())
	_add("바닥 아이템 모두 제거", clear_floor)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_menu"):
		panel.visible = not panel.visible


func _add(text: String, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(func() -> void:
		action.call()
		room.refresh())
	_box.add_child(b)


func spawn(count: int) -> void:
	for i in count:
		var id: String = room.ITEM_IDS.pick_random()
		room.add_item(load("res://data/items/%s.tres" % id), room.player.feet_position())


func clear_floor() -> void:
	for item: ItemInstance in ItemManager.items.values():
		if item.state == ItemInstance.State.INCOMING:
			ItemManager.mark_sold(item)
