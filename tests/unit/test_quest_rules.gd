# U3 BR-U3-08, 14, 18, 19 (QuestRules)
extends TestBase


func _sum(lines: Array) -> int:
	var total := 0
	for l: Dictionary in lines:
		total += int(l["required"])
	return total


func test_lines_sum_to_quantity() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var lines := QuestRules.build_lines(["potion_hp", "antidote"], 4, 2, rng)
	expect(lines.size() == 2, "two lines")
	expect(_sum(lines) == 4, "sum = Q")


func test_remainder_goes_to_front_lines() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var lines := QuestRules.build_lines(["a", "b"], 5, 2, rng)
	expect(int(lines[0]["required"]) == 3 and int(lines[1]["required"]) == 2, "front line gets remainder")


func test_no_kinds_means_no_quest() -> void:
	var rng := RandomNumberGenerator.new()
	expect(QuestRules.build_lines([], 3, 2, rng).is_empty(), "no kinds = no lines")


func test_single_line_when_line_max_one() -> void:
	var rng := RandomNumberGenerator.new()
	var lines := QuestRules.build_lines(["a", "b", "c"], 6, 1, rng)
	expect(lines.size() == 1 and int(lines[0]["required"]) == 6, "one line with all 6")


func test_spawn_battles_distinct_sorted_in_range() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var picks := DungeonRules.spawn_battles(4, 2, rng)
	expect(picks.size() == 2, "2 quest battles")
	expect(picks[0] < picks[1], "sorted and distinct")
	expect(picks[0] >= 1 and picks[1] <= 4, "within 1..N")
