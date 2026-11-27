# 설정 패널 (U5 BR-U5-10, 11). F2 로 연다. 전체 화면 전환, 언어 (한국어만)
class_name SettingsPanel
extends CanvasLayer

var _panel: PanelContainer


func _ready() -> void:
	layer = 6
	_panel = PanelContainer.new()
	_panel.position = Vector2(440, 220)
	_panel.custom_minimum_size = Vector2(400, 0)
	_panel.visible = false
	add_child(_panel)
	var box := VBoxContainer.new()
	_panel.add_child(box)
	var title := Label.new()
	title.text = "설정"
	box.add_child(title)
	var full := Button.new()
	full.text = "전체 화면 전환"
	full.pressed.connect(_toggle_fullscreen)
	box.add_child(full)
	var lang := Label.new()
	lang.text = "언어: 한국어 (영어는 이후 추가)"
	box.add_child(lang)
	var close := Button.new()
	close.text = "닫기"
	close.pressed.connect(func() -> void: _panel.visible = false)
	box.add_child(close)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_F2:
		_panel.visible = not _panel.visible
		get_viewport().set_input_as_handled()


func _toggle_fullscreen() -> void:
	var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
