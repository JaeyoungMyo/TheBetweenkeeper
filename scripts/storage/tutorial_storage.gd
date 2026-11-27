# 튜토리얼 슬라이스 (US-01): 아이템 10개를 모두 선반에 적재하면 완료
extends StorageRoom

signal tutorial_completed

var tutorial_items: Array[ItemInstance] = []
var completed := false


func _ready() -> void:
	super()
	tutorial_completed.connect(_start_dungeon)
	if SaveService.has_save():
		_offer_continue()
	else:
		_create_tutorial_items()


func _create_tutorial_items() -> void:
	for i in ITEM_IDS.size():
		var pos := Vector2(330 + (i % 5) * 140, 500 + floori(i / 5.0) * 80)
		tutorial_items.append(add_item(load("res://data/items/%s.tres" % ITEM_IDS[i]), pos))


## 저장 파일이 있으면 이어하기 / 새 게임 중 고른다 (BR-U5, FD-U5 frontend)
func _offer_continue() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var box := VBoxContainer.new()
	box.position = Vector2(520, 300)
	layer.add_child(box)
	var label := Label.new()
	label.text = "저장된 진행이 있습니다"
	box.add_child(label)
	var cont := Button.new()
	cont.text = "이어하기"
	cont.pressed.connect(func() -> void:
		layer.queue_free()
		_continue_game())
	box.add_child(cont)
	var fresh := Button.new()
	fresh.text = "새 게임"
	fresh.pressed.connect(func() -> void:
		layer.queue_free()
		SaveService.delete_save()
		_create_tutorial_items())
	box.add_child(fresh)


## 저장 지점에 맞춰 다시 시작: 던전 완료 저장 → 상점부터, 상점 완료 저장 → 다음 던전
func _continue_game() -> void:
	var d := SaveService.load_save()
	if d.is_empty():
		show_message("저장 파일이 손상되어 새 게임으로 시작합니다")
		_create_tutorial_items()
		return
	restore_layout(d["shelves"])
	completed = true
	var ui := find_child("DungeonUi", true, false) as DungeonUi
	if ui == null:
		return
	if d["point"] == "dungeon_clear":
		ui.resume_at_shop()
	else:
		ui.resume_next_dungeon()


func _on_state_changed(id: int, state: int) -> void:
	super(id, state)
	if completed or tutorial_items.size() < ITEM_IDS.size():
		return
	if tutorial_items.all(func(it: ItemInstance) -> bool: return it.state == ItemInstance.State.STORED):
		completed = true
		SaveService.tutorial_done = true
		show_message("튜토리얼 완료!")
		tutorial_completed.emit()


## 튜토리얼 완료 후 던전 1 시작 (U3-CG-2 = A)
func _start_dungeon() -> void:
	var ui := find_child("DungeonUi", true, false) as DungeonUi
	if ui != null:
		ui.start_run()
