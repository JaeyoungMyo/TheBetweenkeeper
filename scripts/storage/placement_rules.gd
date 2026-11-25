# 맵 위 겹침 검사 (순수 로직). 기획서 3.4
class_name PlacementRules
extends RefCounted


static func overlaps(a: Rect2, b: Rect2) -> bool:
	return a.intersects(b)
