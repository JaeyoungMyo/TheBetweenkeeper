# 클릭 이동: 도착, 선반에 막힘, 먼 아이템 · 선반 클릭 (비동기라 러너가 직접 실행)
extends TestBase


func run(tree: SceneTree) -> void:
	var room = load("res://scenes/storage/tutorial_storage.tscn").instantiate()
	tree.root.add_child(room)
	await _click(tree, room, Vector2(400, 300))
	expect(room.player.position.distance_to(Vector2(400, 300)) < 5, "arrives at %s" % room.player.position)
	var target = room.tutorial_items[9]
	await _click(tree, room, target.world_position)
	expect(target.state == ItemInstance.State.INCOMING, "far item click only moves")
	expect(room.player.position.distance_to(target.world_position) < 5, "moved to item")
	await _click(tree, room, room.shelf.position)
	expect(not room.player.has_target(), "stops when blocked by shelf")
	expect(room.near_shelf() and not room.shelf.bounds().has_point(room.player.position), "stands in front of shelf")
	room.free()


func _click(tree: SceneTree, room, pos: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = pos
	room._on_map_input(ev)
	for i in 300:
		await tree.physics_frame
		if not room.player.has_target():
			return
