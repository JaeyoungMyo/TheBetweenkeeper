# 통합 테스트 안내 (Integration Test Instructions)

통합 테스트는 같은 러너에서 실행된다 (`tests/integration/`). 별도 서비스 · 서버는 없다.

## 시나리오
| 시나리오 | 파일 | 확인 내용 |
| --- | --- | --- |
| 튜토리얼 씬 (U1, U2) | test_tutorial_slice, test_click_move | 10개 적재 → 완료, 레벨업 증강 선택, 클릭 이동 |
| 던전 1 슬라이스 (U3) | test_dungeon_slice | 전투 → 입고 5~10 → 퀘스트 → 완료 → 수면 → 상점 호출 1회 |
| 던전 화면 흐름 (U3) | test_dungeon_ui | 화면 흐름으로 던전 1 → 상점 호출 1회 |
| 상점 흐름 (U4) | test_shop_flow | 판매 성공 · 실패, 골드 부족 구매, 잔여 아이템 맵 이동 |
| 저장 흐름 (U5) | test_save_flow | 저장 → 초기화 → 복원, 변조 파일 거부 |
| 동작 (실제 입력) | test_behavior_input | X 줍기 · 1 키 적재, Z 내려놓기, F1 · F2 메뉴, 클릭 이동, 전달 선반 클릭 · 1 키 |

## 실행
```
godot --headless --path . -s res://tests/run_tests.gd
```
(단위 테스트와 같은 실행에서 함께 실행된다)

## 정리
- 러너가 시작할 때 `user://save.dat` 을 지운다. 종료 후 남은 저장 파일은 수동으로 지워도 된다.
