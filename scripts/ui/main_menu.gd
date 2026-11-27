# 메인 메뉴: 새 게임 / 이어하기 / 튜토리얼 (튜토리얼 완료 표시)
extends Control

const GAME_SCENE := "res://scenes/game/game.tscn"
const TUTORIAL_SCENE := "res://scenes/storage/tutorial_storage.tscn"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.09, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.position = Vector2(500, 200)
	box.custom_minimum_size = Vector2(280, 0)
	add_child(box)
	var title := Label.new()
	title.text = "아공간 관리인"
	title.add_theme_font_size_override("font_size", 40)
	box.add_child(title)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	box.add_child(spacer)
	box.add_child(_button("새 게임", _new_game))
	var cont := _button("이어하기", _continue)
	cont.disabled = not SaveService.has_save()
	box.add_child(cont)
	var done := "  ✔ 완료" if SaveService.tutorial_done_saved() else ""
	box.add_child(_button("튜토리얼" + done, _tutorial))


func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(280, 48)
	b.pressed.connect(action)
	return b


func _new_game() -> void:
	SaveService.delete_save()
	EconomyManager.reset_run()
	ItemManager.reset_run()
	DungeonManager.reset_run()
	GameSession.continue_requested = false
	get_tree().change_scene_to_file(GAME_SCENE)


func _continue() -> void:
	GameSession.continue_requested = true
	get_tree().change_scene_to_file(GAME_SCENE)


func _tutorial() -> void:
	GameSession.continue_requested = false
	get_tree().change_scene_to_file(TUTORIAL_SCENE)
