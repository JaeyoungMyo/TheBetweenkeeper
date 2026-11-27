# 본 게임 씬: 새 게임 (던전 1 바로 시작) 또는 이어하기 (저장 지점에서 재개)
extends StorageRoom


func _ready() -> void:
	super()
	var ui := find_child("DungeonUi", true, false) as DungeonUi
	if GameSession.continue_requested:
		_continue_game(ui)
	else:
		SaveService.delete_save()
		ui.start_run()


func _continue_game(ui: DungeonUi) -> void:
	var d := SaveService.load_save()
	if d.is_empty():
		show_message("저장 파일이 손상되어 새 게임으로 시작합니다")
		ui.start_run()
		return
	restore_layout(d["shelves"])
	if d["point"] == "dungeon_clear":
		ui.resume_at_shop()
	else:
		ui.resume_next_dungeon()
