# SaveService (오토로드, U5). 던전 완료 · 상점 완료 시 자동 저장, 이어하기, 게임오버 시 삭제 (SYS-01)
extends Node

const PATH := "user://save.dat"

var tutorial_done := false
var village_visits := 0
## 선반 배치를 돌려주는 콜백 (StorageRoom 이 등록). 반환: [{facility_id, position, slot_count, slot_items}]
var shelves_provider: Callable


## point: "dungeon_clear" 또는 "village_clear". 실패해도 게임은 계속 (메시지만)
func save_point(point: String) -> bool:
	var shelves: Array = shelves_provider.call() if shelves_provider.is_valid() else []
	var data := SaveData.capture(shelves, point, tutorial_done, village_visits)
	return _write(SaveCodec.encode(data))


func has_save() -> bool:
	return FileAccess.file_exists(PATH)


## 이어하기. 성공하면 저장된 데이터를 돌려주고, 실패 (없음 · 변조) 면 빈 딕셔너리
func load_save() -> Dictionary:
	var text := _read()
	if text == "":
		return {}
	var d := SaveData.migrate(SaveCodec.decode(text))
	if d.is_empty() or not SaveData.is_valid(d):
		return {}
	SaveData.restore(d)
	tutorial_done = bool(d["tutorial_done"])
	village_visits = int(d["village_visits"])
	return d


const SETTINGS_PATH := "user://settings.cfg"


## 튜토리얼 완료 표시 (저장 파일과 별도, 게임 진행 저장을 지워도 남는다)
func tutorial_done_saved() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return false
	return bool(cfg.get_value("progress", "tutorial_done", false))


func mark_tutorial_done() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("progress", "tutorial_done", true)
	cfg.save(SETTINGS_PATH)


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func _write(text: String) -> bool:
	var f := FileAccess.open_encrypted_with_pass(PATH, FileAccess.WRITE, SaveCodec.KEY)
	if f == null:
		return false
	f.store_string(text)
	f.close()
	return true


func _read() -> String:
	if not has_save():
		return ""
	var f := FileAccess.open_encrypted_with_pass(PATH, FileAccess.READ, SaveCodec.KEY)
	if f == null:
		return ""
	var text := f.get_as_text()
	f.close()
	return text
