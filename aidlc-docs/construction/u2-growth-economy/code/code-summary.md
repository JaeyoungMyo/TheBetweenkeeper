# U2 코드 요약

- 검증: 헤드리스 테스트 33개 통과 (U1 포함). 버튼 클릭과 화면 배치는 수동 확인 필요
- 수치: data/economy/economy.json, data/augments/augments.json

| 스토리 | 파일 | 테스트 |
| --- | --- | --- |
| US-09 | autoload/economy_manager.gd, scripts/growth/exp_calculator.gd | test_economy, test_economy_properties |
| US-10 | scripts/growth/augment_pool.gd, scripts/ui/growth_ui.gd | test_economy, test_economy_properties, test_tutorial_slice |
| US-22 | economy_manager.gd, storage_room.gd, growth_ui.gd | test_economy, test_tutorial_slice |

## 한계
- 판매 기능은 구현했으나 화면은 U4 에서 연결. 그 전까지 골드를 벌 방법이 없음
- 예약 아이템 판매 금지는 예약 상태가 생기는 U3 에서 구현
