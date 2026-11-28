# 메뉴 (P 키 또는 ESC). 열면 게임이 멈추고 메뉴가 나온다: 계속하기 · 구매 (C) · 전체 화면 · 조작 안내 · 메인 메뉴로
# 레벨업 증강 선택으로 자동 멈춘 상태는 건드리지 않는다 (선택을 끝내야 풀린다)
class_name PauseMenu
extends CanvasLayer

const CONTROLS := "[조작 안내]\n\n이동: 방향키\n줍기: X        선반 열기 · 닫기: E\n선반 고르기: ↑↓ 칸 · ←→ 아이템 · 꺼내기 X\n넣기: 1 ~ 3 (들고 있을 때)\n전달 선반에 넣기: Z\n칸 추가: +        구매: C        메뉴: P 또는 ESC"

var _user_paused := false
var _overlay: ColorRect
var _hint: Label
var _buttons: VBoxContainer
var _help: Label
var _back: Button
var _resume_button: Button


func _ready() -> void:
	layer = 7
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 오른쪽 위 안내 (오른쪽 여백 32px 에 맞춘다)
	_hint = _corner_label("메뉴 (P · ESC)", 1098, 8)
	add_child(_hint)
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.6)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.visible = false
	add_child(_overlay)
	# 모든 줄을 화면 가운데에 쌓는다 (글자와 버튼이 같은 중심선에 맞는다)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_top = 140
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	column.add_theme_constant_override("separation", 10)
	_overlay.add_child(column)
	var title := _centered_label("메뉴", 36)
	column.add_child(title)
	_buttons = VBoxContainer.new()
	_buttons.custom_minimum_size = Vector2(280, 0)
	_buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_buttons.add_theme_constant_override("separation", 8)
	column.add_child(_buttons)
	_resume_button = _add_button("계속하기 (P)", toggle)
	_add_button("전체 화면 전환", func() -> void: _toggle_fullscreen())
	_add_button("조작 안내", _show_help)
	_add_button("메인 메뉴로", go_to_menu)
	_help = _centered_label(CONTROLS, 20)
	_help.visible = false
	column.add_child(_help)
	_back = Button.new()
	_back.text = "뒤로"
	_back.custom_minimum_size = Vector2(160, 44)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.visible = false
	_back.pressed.connect(_hide_help)
	column.add_child(_back)
	column.add_child(_centered_label("(마지막 자동 저장 이후 진행은 저장되지 않습니다)", 16))


func _centered_label(text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _corner_label(text: String, x: float, y: float) -> Label:
	var l := Label.new()
	l.text = text
	l.position = Vector2(x, y)
	l.size = Vector2(1248 - x, 24)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _add_button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(280, 44)
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.pressed.connect(action)
	_buttons.add_child(b)
	return b


func _show_help() -> void:
	_buttons.visible = false
	_help.visible = true
	_back.visible = true
	_back.call_deferred("grab_focus")


func _hide_help() -> void:
	_buttons.visible = true
	_help.visible = false
	_back.visible = false
	_resume_button.call_deferred("grab_focus")


func _toggle_fullscreen() -> void:
	var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)


func go_to_menu() -> void:
	_user_paused = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		toggle()


func toggle() -> void:
	if not _user_paused:
		# 증강 선택 등 다른 이유로 멈춰 있으면 끼어들지 않는다
		if get_tree().paused:
			return
		_user_paused = true
		get_tree().paused = true
		_overlay.visible = true
		_hide_help()
		_resume_button.call_deferred("grab_focus")
	else:
		_user_paused = false
		get_tree().paused = false
		_overlay.visible = false
