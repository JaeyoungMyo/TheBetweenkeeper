# BR-U1-09
extends TestBase


func test_same_speed_for_all_weights() -> void:
	for w in WeightRules.ALLOWED_ITEM_WEIGHTS:
		expect(WeightRules.carry_speed(180.0, w) == 180.0, "weight %d" % w)
