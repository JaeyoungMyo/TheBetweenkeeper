# 일시정지 (P 키 또는 오른쪽 위 버튼). 일시정지 중에는 전투 · 수면 타이머와 이동이 멈춘다
# 레벨업 증강 선택으로 자동 멈춘 상태는 건드리지 않는다 (선택을 끝내야 풀린다)
class_name PauseMenu
extends CanvasLayer

var _user_paused := false
var _overlay: ColorRect
var _hint: Label
var _resume_button: Button


func _ready() -> void:
	layer = 7
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 상단 표시만 (마우스 버튼 없음). 일시정지는 P 키
	_hint = Label.new()
	_hint.text = "일시정지 (P)"
	_hint.position = Vector2(1120, 8)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.55)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.visible = false
	add_child(_overlay)
	var label := Label.new()
	label.text = "일시정지\n\nP 키 또는 아래 버튼으로 계속합니다"
	label.position = Vector2(480, 280)
	label.add_theme_font_size_override("font_size", 28)
	_overlay.add_child(label)
	var resume := Button.new()
	resume.text = "계속하기 (P)"
	resume.position = Vector2(560, 400)
	resume.pressed.connect(toggle)
	_overlay.add_child(resume)
	_resume_button = resume
	# 튜토리얼 · 게임 중 초기 화면으로. 마지막 자동 저장 이후 진행은 남지 않는다
	var to_menu := Button.new()
	to_menu.text = "메인 메뉴로"
	to_menu.position = Vector2(560, 450)
	to_menu.pressed.connect(go_to_menu)
	_overlay.add_child(to_menu)
	var note := Label.new()
	note.text = "(마지막 자동 저장 이후 진행은 저장되지 않습니다)"
	note.position = Vector2(470, 495)
	_overlay.add_child(note)


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
		_resume_button.call_deferred("grab_focus")
	else:
		_user_paused = false
		get_tree().paused = false
		_overlay.visible = false
