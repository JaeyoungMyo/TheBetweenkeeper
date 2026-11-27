# 상점에서 가방 확장: 상점 중에만 버튼이 보이고, 누르면 골드를 내고 가방이 늘어난다
extends TestBase

var tree: SceneTree


func test_shop_bag_button_expands_bag() -> void:
	root_reset()
	var room = load("res://scenes/storage/tutorial_storage.tscn").instantiate()
	room.auto_return = false
	tree.root.add_child(room)
	await tree.process_frame
	var ui = room.find_child("DungeonUi", true, false)
	expect(ui != null, "dungeon ui present")
	expect(not ui._shop_bag_button.visible, "bag button hidden outside the shop")
	ui._open_shop()
	expect(ui._shop_bag_button.visible, "bag button shown during the shop")
	var before := ItemManager.bag_size
	EconomyManager.add_gold(1000)
	ui._refresh_shop_bag_button()
	expect(not ui._shop_bag_button.disabled, "bag button enabled with enough gold")
	var gold_before := EconomyManager.gold()
	ui._on_shop_bag_pressed()
	expect(ItemManager.bag_size == before + 1, "bag grows by one (%d -> %d)" % [before, ItemManager.bag_size])
	expect(EconomyManager.gold() < gold_before, "bag price is paid")
	ui._finish_shop()
	expect(not ui._shop_bag_button.visible, "bag button hidden after the shop")
	room.free()


func root_reset() -> void:
	ItemManager.reset_run() if ItemManager.has_method("reset_run") else null
	EconomyManager.reset_run() if EconomyManager.has_method("reset_run") else null
