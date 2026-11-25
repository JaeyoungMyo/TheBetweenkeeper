# U1 코드 요약

- 검증: Godot 4.7.2 헤드리스 테스트 21개 통과 (예시 · 통합 + PBT, 속성당 200회), 메인 씬 60프레임 실행 오류 없음
- 실행: `godot --headless --path . --import` 후 `godot --headless --path . -s res://tests/run_tests.gd`

| 스토리 | 파일 |
| --- | --- |
| US-01 | scripts/storage/tutorial_storage.gd, data/items/ |
| US-02, US-03 | scripts/ui/ |
| US-04 ~ US-06 | autoload/item_manager.gd, scripts/storage/storage_service.gd, storage_room.gd |
| US-07, US-08 | scripts/storage/player_controller.gd |

| BR | 테스트 |
| --- | --- |
| 01, 02, 10, 11, 16, 17 | test_weight_rules, test_storage_properties |
| 04 ~ 07, 12, 13 | test_storage_flow, test_storage_properties |
| 09 | test_movement_speed |
| 03 | test_weight_rules (칸 · 선반 한도) |
| 05 (화면), 08, 14, 15 | 수동 |

## 계획과 다른 점
- 입력 맵은 project.godot 대신 player_controller.gd 에서 등록
- 씬은 루트와 스크립트만 두고 자식 노드는 코드로 생성
- PlacementRules 는 겹침 검사만 구현. 빈 자리 선택은 U4 에서 구현
- test_item_manager 는 test_storage_flow 에 포함

## 한계
- 드래그 앤 드롭, 호버, 벽 충돌은 화면에서 확인하지 않음
- 시설의 허용 카테고리 검사는 미구현
- 테스트 종료 시 ObjectDB 누수 경고 있음 (테스트가 만든 노드)
- 그래픽은 임시 사각형. 웹 빌드용 한글 폰트는 U5 에서 포함 필요
- CI 없음 (PBT-08 의 CI 항목은 N/A). 기본 seed 고정
