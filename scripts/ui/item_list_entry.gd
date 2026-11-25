# 아이템 목록 항목. 드래그 원본 (FR-02, D-14)
extends Button

var item_id: int = -1


func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview := Label.new()
	preview.text = text
	set_drag_preview(preview)
	return {"item_id": item_id}
