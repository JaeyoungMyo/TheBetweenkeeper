# 이어하기 씬 흐름: 던전 완료 저장 → 상점, 상점 완료 저장 → 다음 던전, 손상 저장 → 새 게임
extends TestBase

var tree: SceneTree


func _room() -> Node:
	var room = load("res://scenes/storage/tutorial_storage.tscn").instantiate()
	tree.root.add_child(room)
	return room


func _frames(n: int) -> void:
	for i in n:
		await tree.process_frame


func test_continue_after_dungeon_clear_opens_shop() -> void:
	SaveService.delete_save()
	var first = _room()
	await _frames(2)
	first.free()
	DungeonManager.start_dungeon(1)
	DungeonManager.flow.battle_index = 0
	SaveService.save_point("dungeon_clear")
	var room = _room()
	await _frames(2)
	var ui = room.find_child("DungeonUi", true, false)
	expect(room.tutorial_items.is_empty(), "continue screen skips tutorial items")
	room._continue_game()
	await _frames(2)
	ui._process(3.0)  # 상점 방문 중 표시 (2.5초) 가 지난 뒤 상점이 열린다
	expect(ui._shop_active, "dungeon_clear save resumes at the shop")
	room.free()
	SaveService.delete_save()


func test_continue_after_shop_clear_starts_next_dungeon() -> void:
	SaveService.delete_save()
	DungeonManager.start_dungeon(2)
	SaveService.save_point("shop_clear")
	var room = _room()
	await _frames(2)
	room._continue_game()
	await _frames(2)
	var ui = room.find_child("DungeonUi", true, false)
	expect(not ui._shop_active and DungeonManager.flow.dungeon_no == 3, "shop_clear save starts dungeon 3")
	expect(DungeonManager.flow.state == DungeonFlow.State.IN_BATTLE, "battle started")
	room.free()
	SaveService.delete_save()


func test_corrupt_save_falls_back_to_new_game() -> void:
	SaveService.delete_save()
	var f := FileAccess.open_encrypted_with_pass(SaveService.PATH, FileAccess.WRITE, SaveCodec.KEY)
	f.store_string("garbage")
	f.close()
	var room = _room()
	await _frames(2)
	room._continue_game()
	await _frames(2)
	expect(room.tutorial_items.size() == 5, "corrupt save: tutorial items created (new game)")
	room.free()
	SaveService.delete_save()
