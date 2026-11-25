# 운반 개수 (순수 로직). 기본 1, 상점 구매로 최대 5, 증강 배수 최대 3 → 최대 15
class_name CarryRules
extends RefCounted

const MAX_BAG := 5
const MAX_MULTIPLIER := 3


static func capacity(bag: int, multiplier: int) -> int:
	return clampi(bag, 1, MAX_BAG) * clampi(multiplier, 1, MAX_MULTIPLIER)
