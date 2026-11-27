# 성능 측정 (NFR-01 기준: 아이템 200개, 창고 1개): 프레임당 처리 시간 (CPU 로직 + 씬 갱신)
# 실행: godot --path . -s res://tests/perf/perf_items.gd   (화면 렌더링 비용은 포함되지 않음)
extends SceneTree

const FRAMES := 600
const ITEMS := 200


func _initialize() -> void:
	_run()


func _run() -> void:
	var room = load("res://scenes/storage/tutorial_storage.tscn").instantiate()
	root.add_child(room)
	await process_frame
	root.get_node("SaveService").delete_save()
	var kinds: Array = room.ITEM_IDS
	for i in ITEMS:
		var item = room.add_item(load("res://data/items/%s.tres" % kinds[i % kinds.size()]), Vector2(240 + (i * 37) % 740, 120 + (i * 53) % 560))
		if i % 3 == 0:
			item.state = ItemInstance.State.STORED
	room.refresh()
	var im = root.get_node("ItemManager")
	var worst := 0
	var total := 0
	for f in FRAMES:
		var t := Time.get_ticks_usec()
		room._process(1.0 / 60.0)
		room.list_panel.refresh(im.carried_items(), im.capacity())
		var dt := Time.get_ticks_usec() - t
		total += dt
		worst = maxi(worst, dt)
		await process_frame
	var avg_ms := float(total) / FRAMES / 1000.0
	print("PERF items=%d frames=%d avg_ms=%.3f worst_ms=%.3f budget_ms=16.667" % [ITEMS, FRAMES, avg_ms, float(worst) / 1000.0])
	quit(0 if avg_ms < 16.667 else 1)
