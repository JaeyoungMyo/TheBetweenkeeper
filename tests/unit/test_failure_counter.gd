# U3 BR-U3-16, 17
extends TestBase


func test_third_failure_is_game_over() -> void:
	var c := FailureCounter.new()
	expect(not c.add_failure(), "1st")
	expect(not c.add_failure(), "2nd")
	expect(c.add_failure(), "3rd = game over")
	expect(c.count == 3, "count 3")


func test_reset_clears_count() -> void:
	var c := FailureCounter.new()
	c.add_failure()
	c.reset()
	expect(c.count == 0 and not c.is_game_over(), "reset")
