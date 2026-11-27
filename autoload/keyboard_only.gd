# 키보드 전용 입력 (오토로드). 마우스 · 터치 입력을 모두 막는다.
# 게임 동작과 메뉴 버튼은 키보드 (방향키 · Enter · Tab · E · X · Z · C · P · F2 등) 로만 한다
extends Node


func _input(event: InputEvent) -> void:
	if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:
		get_viewport().set_input_as_handled()
