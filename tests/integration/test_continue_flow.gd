# 이어하기 (본 게임 씬): 던전 완료 저장 → 상점, 상점 완료 저장 → 다음 던전, 손상 저장 → 새 게임
extends TestBase

var tree: SceneTree


func _game() -> Node:
	var room = load("res://scenes/game/game.tscn").instantiate()
	tree.root.add_child(room)
	return room


func _frames(n: int) -> void:
	for i in n:
		await tree.process_frame


func test_continue_after_dungeon_clear_opens_shop() -> void:
	SaveService.delete_save()
	DungeonManager.start_dungeon(1)
	SaveService.save_point("dungeon_clear")
	GameSession.continue_requested = true
	var room = _game()
	await _frames(2)
	var ui = room.find_child("DungeonUi", true, false)
	ui._process(3.0)  # 상점 방문 중 표시 (2.5초) 가 지난 뒤 상점이 열린다
	expect(ui._shop_active, "dungeon_clear save resumes at the shop")
	room.free()
	GameSession.continue_requested = false
	SaveService.delete_save()


func test_continue_after_shop_clear_starts_next_dungeon() -> void:
	SaveService.delete_save()
	DungeonManager.start_dungeon(2)
	SaveService.save_point("shop_clear")
	GameSession.continue_requested = true
	var room = _game()
	await _frames(2)
	var ui = room.find_child("DungeonUi", true, false)
	expect(not ui._shop_active and DungeonManager.flow.dungeon_no == 3, "shop_clear save starts dungeon 3")
	expect(DungeonManager.flow.state == DungeonFlow.State.IN_BATTLE, "battle started")
	room.free()
	GameSession.continue_requested = false
	SaveService.delete_save()


func test_corrupt_save_falls_back_to_new_game() -> void:
	SaveService.delete_save()
	var f := FileAccess.open_encrypted_with_pass(SaveService.PATH, FileAccess.WRITE, SaveCodec.KEY)
	f.store_string("garbage")
	f.close()
	GameSession.continue_requested = true
	var room = _game()
	await _frames(2)
	var ui = room.find_child("DungeonUi", true, false)
	expect(DungeonManager.flow.state == DungeonFlow.State.IN_BATTLE and not ui._shop_active, "corrupt save starts a new game")
	room.free()
	GameSession.continue_requested = false
	SaveService.delete_save()
