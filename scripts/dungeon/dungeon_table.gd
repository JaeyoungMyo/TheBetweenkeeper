# 던전 데이터 (DungeonTable). 값은 data/dungeons/dungeons.json (BR-U3-24). 던전 11 이후는 마지막 값을 반복한다.
class_name DungeonTable
extends RefCounted

const PATH := "res://data/dungeons/dungeons.json"


static func load_all() -> Array:
	return JSON.parse_string(FileAccess.get_file_as_string(PATH))


static func get_config(no: int) -> Dictionary:
	var all := load_all()
	return all[clampi(no - 1, 0, all.size() - 1)]


## BR-U3-18: 퀘스트 총 수량 Q 는 2~10, 줄 수 1~3, 던전 번호에 따라 비감소
static func is_valid(entries: Array) -> bool:
	var prev_q := 0
	for e: Dictionary in entries:
		var q := int(e["quest_quantity"])
		if q < 2 or q > 10 or q < prev_q:
			return false
		if int(e["line_max"]) < 1 or int(e["line_max"]) > 3:
			return false
		prev_q = q
	return true
