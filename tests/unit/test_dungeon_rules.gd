# U3 BR-U3-01, 02, 03 (DungeonRules, DungeonTable)
extends TestBase


func test_battle_count_in_range() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for i in 200:
		var n := DungeonRules.roll_battle_count(rng, 3, 5)
		expect(n >= 3 and n <= 5, "battle count %d" % n)


func test_intake_split_last_battle_gets_remainder() -> void:
	var parts := DungeonRules.split_intake(10, 3)
	expect(parts == [3, 3, 4], "10 over 3 battles = [3,3,4], got %s" % str(parts))


func test_completion_depends_only_on_battles_left() -> void:
	expect(DungeonRules.is_complete(0), "no battles left = complete")
	expect(not DungeonRules.is_complete(1), "one battle left = not complete")


func test_dungeon_table_values_valid() -> void:
	var all := DungeonTable.load_all()
	expect(all.size() == 10, "10 dungeons in table")
	expect(DungeonTable.is_valid(all), "Q in 2..10, non-decreasing, lines 1..3")
	expect(int(DungeonTable.get_config(1)["new_item_total"]) == 10, "dungeon 1 = 10 items (기획서 8.2)")
	expect(int(DungeonTable.get_config(1)["quest_count"]) == 1, "dungeon 1 = 1 quest")
