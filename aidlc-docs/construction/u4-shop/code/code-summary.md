# U4 상점 코드 요약

**계획**: `construction/plans/u4-shop-code-generation-plan.md` (Step 1~12)
**상태**: 구현 완료 (로직, 데이터, UI 연결, 테스트). 화면 조작 (출력공간 클릭 · 드래그) 은 전달 선반과 같은 방식이라 기존 조작 그대로.
**검증**: Godot 4.7.2 headless. `PBT seed=20261124 tests=67 failed=0`. 메인 씬 300 프레임 실행 시 스크립트 오류 없음.

## 스토리별 파일

| 스토리 | 파일 | 테스트 |
| --- | --- | --- |
| US-18 던전 완료 후 상점 방문 | scripts/ui_dungeon/dungeon_ui.gd (`_on_shop_visit`, `_finish_shop`), scripts/shop/shop_flow.gd | test_shop_flow, test_dungeon_ui (기존) |
| US-19 판매 퀘스트 | scripts/shop/shop_flow.gd, scripts/dungeon/quest_controller.gd (value_of 훅), scripts/dungeon/delivery_space.gd (take, remove_all) | test_quest_value, test_shop_rules, test_shop_properties, test_shop_flow |
| US-20 구매품 맵에 받기 | scripts/shop/shop_flow.gd (_run_buy), scripts/shop/shop_rules.gd (roll_purchases) | test_shop_properties, test_shop_flow |
| US-21 골드 부족 구매 실패 | scripts/shop/shop_flow.gd (품목별 spend_gold) | test_shop_flow |

## 데이터
- `data/shop/shop.json`: 판매 퀘스트 (수량 12, 줄 최대 3, 120초, EXP 80), 제외 카테고리 (물약), 구매 4개, 구매 품목 (회복약 30/5, 주문서 50/3, 광석 상자 120/2)

## 기존 파일 수정
- `delivery_space.gd`: `take` (필요 개수만 꺼냄), `remove_all`. 기존 `consume` 은 `take` 를 쓴다.
- `quest_controller.gd`: `value_of` 훅 (판매가 합계 골드). 없으면 U3 동작 그대로.
- `dungeon_manager.gd`: `delivery_changed` 신호 (출력공간 변화를 상점에 알림).
- `storage_room.gd`: `attach_item` (기존 아이템을 맵에 표시).
- `dungeon_ui.gd`: 상점 열기 · 닫기, 판매 퀘스트 패널 (긴급 요청 패널 재사용), 다음 던전 자동 시작, 입력 조작은 게임오버 전까지 항상 가능 (상점 중에도 전달 선반 사용).

## 한계 · 후속
- 출력공간 = 전달 선반 공유 (확정). 상점 중 전달 선반에 넣은 아이템은 판매 퀘스트에 세진다.
- 구매 품목 가격 · 가중치는 초기값이다.
- 직업별 판매 (자기 장비 제외) 는 직업 도입 후 (BR-U4-08).
- 대량 상자 · 상점 연출은 제외 · 후순위.
- 판매 골드 검증 테스트는 "골드 증가" 수준으로 느슨하다. 정확한 금액 검증은 수동 테스트에서 확인.
