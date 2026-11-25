# EXP 와 레벨 (순수 로직). FR-10
class_name ExpCalculator
extends RefCounted


static func to_next(level: int, base: int, step: int) -> int:
	return base + step * (level - 1)


## 반환: {"level", "exp", "gained"}. 남은 EXP 는 이월
static func apply(level: int, current: int, gain: int, base: int, step: int) -> Dictionary:
	var lv := level
	var left := current + maxi(gain, 0)
	while left >= to_next(lv, base, step):
		left -= to_next(lv, base, step)
		lv += 1
	return {"level": lv, "exp": left, "gained": lv - level}
