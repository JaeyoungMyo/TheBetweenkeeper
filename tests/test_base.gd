# 테스트 기반 클래스. expect() 실패를 모아 두고 러너가 보고한다.
class_name TestBase
extends RefCounted

var failures: Array = []


func expect(cond: bool, message: String) -> void:
	if not cond:
		failures.append(message)
