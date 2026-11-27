# 실패 누적 (U3 BR-U3-16, 17). 퀘스트 종류와 무관하게 하나의 값
class_name FailureCounter
extends RefCounted

const LIMIT := 3

var count := 0


## 실패 1회 추가. 게임오버이면 true
func add_failure() -> bool:
	count += 1
	return is_game_over()


func is_game_over() -> bool:
	return count >= LIMIT


func reset() -> void:
	count = 0
