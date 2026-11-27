# 메인 메뉴: 새 게임 · 이어하기 · 튜토리얼 세 버튼, 저장이 없으면 이어하기는 비활성
extends TestBase

var tree: SceneTree


func test_main_menu_has_three_options_and_continue_depends_on_save() -> void:
	SaveService.delete_save()
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	tree.root.add_child(menu)
	await tree.process_frame
	var texts := []
	var cont: Button = null
	for n in menu.find_children("*", "Button", true, false):
		texts.append(n.text)
		if n.text == "이어하기":
			cont = n
	var has_tutorial := texts.any(func(t: String) -> bool: return t.begins_with("튜토리얼"))
	expect(texts.has("새 게임") and has_tutorial and cont != null, "three options: %s" % str(texts))
	expect(cont != null and cont.disabled, "continue disabled without a save")
	SaveService.save_point("dungeon_clear")
	menu.free()
	var menu2 = load("res://scenes/main_menu.tscn").instantiate()
	tree.root.add_child(menu2)
	await tree.process_frame
	for n in menu2.find_children("*", "Button", true, false):
		if n.text == "이어하기":
			expect(not n.disabled, "continue enabled with a save")
	menu2.free()
	SaveService.delete_save()
