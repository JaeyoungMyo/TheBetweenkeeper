# 바닥 칸 규칙 (순수 로직). 바닥 한 칸 (32px) 에 최대 10개
class_name FloorRules
extends RefCounted

const CELL := 32.0
const MAX_STACK := 10


static func cell_of(pos: Vector2) -> Vector2i:
	return Vector2i((pos / CELL).floor())


## 칸이 비어 있으면 그대로, 가득 찼으면 가장 가까운 빈 칸의 중심.
## bounds 는 방 안쪽 (넓이 0 이면 제한 없음), blocked 는 시설 영역
static func resolve(pos: Vector2, counts: Dictionary, bounds := Rect2(), blocked: Array = []) -> Vector2:
	var origin := cell_of(pos)
	if counts.get(origin, 0) < MAX_STACK:
		return pos
	for radius in range(1, 60):
		var best := Vector2.INF
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				if maxi(absi(x), absi(y)) != radius:
					continue
				var cell := origin + Vector2i(x, y)
				var center := (Vector2(cell) + Vector2(0.5, 0.5)) * CELL
				if counts.get(cell, 0) >= MAX_STACK or (bounds.has_area() and not bounds.has_point(center)):
					continue
				if blocked.any(func(r: Rect2) -> bool: return r.has_point(center)):
					continue
				if best == Vector2.INF or center.distance_to(pos) < best.distance_to(pos):
					best = center
		if best != Vector2.INF:
			return best
	return pos
