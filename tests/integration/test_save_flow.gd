# U5 저장 흐름 (헤드리스): 저장 → 초기화 → 이어하기 복원, 변조 거부, 게임오버 삭제 (SYS-01)
extends TestBase


func test_save_then_restore_gold_failures_and_items() -> void:
	ItemManager.reset_run()
	EconomyManager.reset_run()
	DungeonManager.failures.reset()
	var a := ItemManager.create_item(load("res://data/items/sword.tres"), 0)
	a.state = ItemInstance.State.STORED
	var b := ItemManager.create_item(load("res://data/items/armor.tres"), 0)
	b.state = ItemInstance.State.INCOMING
	b.world_position = Vector2(300, 500)
	EconomyManager.add_gold(55)
	DungeonManager.failures.count = 2
	DungeonManager.flow.dungeon_no = 3
	expect(SaveService.save_point("dungeon_clear"), "save written")
	expect(SaveService.has_save(), "save exists")
	ItemManager.reset_run()
	EconomyManager.reset_run()
	DungeonManager.failures.reset()
	var d := SaveService.load_save()
	expect(not d.is_empty(), "load ok")
	expect(ItemManager.items.size() == 2, "two items restored, no duplicates")
	expect(ItemManager.items[a.instance_id].state == ItemInstance.State.STORED, "stored state kept")
	expect(ItemManager.items[b.instance_id].world_position.is_equal_approx(Vector2(300, 500)), "floor position kept")
	expect(EconomyManager.gold() == 155, "gold restored")
	expect(DungeonManager.failures.count == 2, "failures restored")
	expect(DungeonManager.flow.dungeon_no == 3, "dungeon number restored")
	SaveService.delete_save()
	expect(not SaveService.has_save(), "save deleted (game over path)")


func test_tampered_file_is_rejected_and_treated_as_new_game() -> void:
	SaveService.save_point("village_clear")
	var f := FileAccess.open_encrypted_with_pass(SaveService.PATH, FileAccess.WRITE, SaveCodec.KEY)
	f.store_string(SaveCodec.encode({"version": 1, "point": "x"}).replace("x", "y"))
	f.close()
	expect(SaveService.load_save().is_empty(), "tampered save rejected")
	SaveService.delete_save()
