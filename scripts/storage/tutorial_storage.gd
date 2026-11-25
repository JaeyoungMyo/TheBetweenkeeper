# 튜토리얼 슬라이스 (US-01): 아이템 10개를 모두 선반에 적재하면 완료
extends StorageRoom

signal tutorial_completed

var tutorial_items: Array[ItemInstance] = []
var completed := false


func _ready() -> void:
	super()
	for i in ITEM_IDS.size():
		var pos := Vector2(330 + (i % 5) * 140, 500 + floori(i / 5.0) * 80)
		tutorial_items.append(add_item(load("res://data/items/%s.tres" % ITEM_IDS[i]), pos))


func _on_state_changed(id: int, state: int) -> void:
	super(id, state)
	if completed or tutorial_items.size() < ITEM_IDS.size():
		return
	if tutorial_items.all(func(it: ItemInstance) -> bool: return it.state == ItemInstance.State.STORED):
		completed = true
		show_message("튜토리얼 완료!")
		tutorial_completed.emit()
