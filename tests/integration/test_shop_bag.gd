# 상점 (C): 가방 확장 구매. 골드가 충분하면 누를 수 있고, 누르면 골드를 내고 가방이 늘어난다
extends TestBase

var tree: SceneTree


func _find_button(node: Node, text: String):
	if node is Button and node.text.begins_with(text):
		return node
	for c in node.get_children():
		var r = _find_button(c, text)
		if r != null:
			return r
	return null


func test_shop_menu_buys_bag() -> void:
	SaveService.delete_save()
	var room = load("res://scenes/storage/tutorial_storage.tscn").instantiate()
	room.auto_return = false
	tree.root.add_child(room)
	await tree.process_frame
	var growth = room.get_node("GrowthUi")
	expect(growth.get_node_or_null("shop-open-button") != null or growth.find_child("shop-open-button", true, false) != null, "top-right shop button exists")
	growth._fill_menu()
	var bag_button = _find_button(growth.menu, "가방 확장")
	expect(bag_button != null, "bag purchase is in the shop menu")
	var before := ItemManager.bag_size
	EconomyManager.add_gold(1000)
	growth._fill_menu()
	bag_button = _find_button(growth.menu, "가방 확장")
	var gold_before := EconomyManager.gold()
	bag_button.pressed.emit()
	expect(ItemManager.bag_size == before + 1, "bag grows by one (%d -> %d)" % [before, ItemManager.bag_size])
	expect(EconomyManager.gold() < gold_before, "bag price is paid")
	room.free()
