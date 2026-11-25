# 골드 잔액 (순수 로직). NFR-04: EconomyManager 만 소유한다
class_name GoldLedger
extends RefCounted

var _amount: int = 0


func amount() -> int:
	return _amount


func add(value: int) -> bool:
	if value < 0:
		return false
	_amount += value
	return true


func try_spend(cost: int) -> bool:
	if cost < 0 or cost > _amount:
		return false
	_amount -= cost
	return true
