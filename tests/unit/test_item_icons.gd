# 아이템 아이콘 (art/items 스프라이트 시트, 16px 칸): 모든 아이템이 시트 안의 칸을 가진다
extends TestBase


func test_every_item_has_icon_inside_sheet() -> void:
	var count := 0
	for f in DirAccess.get_files_at("res://data/items"):
		if not f.ends_with(".tres"):
			continue
		count += 1
		var data: ItemData = load("res://data/items/" + f)
		var tex := data.icon()
		expect(tex != null, "%s has icon" % f)
		if tex == null:
			continue
		var r: Rect2 = (tex as AtlasTexture).region
		var sheet: Texture2D = data.icon_sheet
		expect(r.position.x >= 0 and r.position.y >= 0, "%s region not negative" % f)
		expect(r.end.x <= sheet.get_width() and r.end.y <= sheet.get_height(), "%s region inside sheet" % f)
	expect(count == 10, "10 item resources")
