# FR-03, 기획서 3.4 겹침 검사
extends TestBase


func test_overlap_detection() -> void:
	expect(PlacementRules.overlaps(Rect2(0, 0, 10, 10), Rect2(5, 5, 10, 10)), "overlapping rects must overlap")
	expect(not PlacementRules.overlaps(Rect2(0, 0, 10, 10), Rect2(20, 20, 5, 5)), "separate rects must not overlap")
