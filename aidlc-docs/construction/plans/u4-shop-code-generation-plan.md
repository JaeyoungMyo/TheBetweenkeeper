# U4 상점 코드 생성 계획 (Code Generation Plan)

**unit**: U4 상점 (Shop)
**기준 (single source of truth)**:
- `construction/u4-shop/functional-design/` (business-logic-model, business-rules BR-U4-01 ~ 15, domain-entities, frontend-components — 판매 퀘스트 변경 반영본)
- `construction/plans/u4-shop-functional-design-plan.md` (FD-U4-1 ~ 11 답변)
- `inception/user-stories/stories.md` (US-18 ~ US-21, US-19 는 판매 퀘스트로 변경됨)
- `inception/requirements/requirements.md` (FR-16 ~ 18, FR-19, FR-30, FR-31)

**의존**: U1 (ItemManager, FloorRules), U2 (EconomyManager 판매가 · 골드 · EXP), U3 (DungeonManager 의 SHOP_HANDOFF 신호, Quest · QuestRules · QuestController · DeliverySpace)
**범위 밖**: 대량 상자 (제외), 무기 · 방어구 구매 (POC 제외), 직업별 판매 (예정, BR-U4-08), 상점 연출 (후순위)

**재사용**: U3 의 `Quest`, `QuestRules.build_lines`, `QuestController`, `DeliverySpace` 를 판매 퀘스트에 그대로 쓴다. 판매 시 골드는 판매가 합계로 계산하도록 `QuestController` 에 보상 계산 훅을 추가한다.

## 계획 단계 (Steps)

### Step 1. 상점 데이터 `data/shop/shop.json`
- [ ] 판매 퀘스트: 수량 12, 줄 수 최대 3, 제한 시간 120초, EXP 80 (던전 1 초기값, BR-U4-04)
- [ ] 제외 카테고리: `물약` (BR-U4-07, 가정)
- [ ] 구매: 방문당 4개 (BR-U4-10). 품목 (무기 · 방어구 제외, BR-U4-15): 회복약 (물약, 가중치 5, 비용 30), 주문서 (가중치 3, 비용 50), 광석 상자 (재료, 가중치 2, 비용 120)
- 스토리: US-18, US-19, US-20, US-21

### Step 2. 상점 규칙 `scripts/shop/shop_rules.gd`
- [ ] `sellable_kinds(items)`: 창고 (선반 · 바닥 · 들고 있는 것) 중 판매 가능 카테고리의 고유 종류 (BR-U4-03, 07)
- [ ] `roll_purchases(count, pool, rng)`: 가중치 추첨, 같은 품목 중복 가능 (BR-U4-10)
- [ ] `can_afford(gold, cost)` 및 품목별 차감 계산 (BR-U4-11)
- 스토리: US-20 (AC-20-3), US-21

### Step 3. 출력공간 확장 `scripts/dungeon/delivery_space.gd`
- [ ] `take(plan) -> Array[ItemInstance]`: 줄별 필요 개수만큼 꺼내고 삭제 상태로 바꾼 아이템 목록을 돌려준다. 기존 `consume` 은 `take(plan).size()` 로 바꾼다 (기존 테스트 유지)
- [ ] `remove_all() -> Array[ItemInstance]`: 상점 종료 시 남은 아이템 전부 꺼내기 (BR-U4-06)
- 스토리: US-19 (AC-19-2, AC-19-3)

### Step 4. 퀘스트 보상 훅 `scripts/dungeon/quest_controller.gd`
- [ ] 생성자 · 설정으로 `value_of: Callable` 을 받는다. 있으면 성공 골드 = 소비된 아이템들의 `value_of` 합계 (판매가), 없으면 기존처럼 `quest.reward_gold` (U3 동작 유지)
- [ ] 기존 U3 테스트가 그대로 통과해야 한다
- 스토리: US-19 (AC-19-2)

### Step 5. 판매 · 구매 흐름 `scripts/shop/shop_flow.gd`
- [ ] 상태: CLOSED → SELL (판매 퀘스트) → BUY (구매 추첨) → DONE. SELL 은 퀘스트 성공 · 실패 · 시간 초과 어느 경우든 끝난다
- [ ] 판매 퀘스트 발생: 줄 후보는 `sellable_kinds`, 줄 구성은 `QuestRules.build_lines` (BR-U4-03)
- [ ] 판매 결과: 성공 시 판매가 합계를 골드, EXP 80 지급 (`EconomyManager.add_gold`, `add_exp`). 실패 시 출력공간 아이템은 삭제하지 않는다 (BR-U4-05, 06)
- [ ] SELL 종료 시 출력공간 잔여 아이템 전부 맵 무작위 위치로 이동 (BR-U4-06, FD-U4-5 X)
- [ ] BUY: 4번 추첨 → 품목마다 골드 확인 후 차감. 부족하면 그 품목만 건너뛰고 메시지 (BR-U4-11). 구매품은 맵 무작위 위치에 `incoming` 으로 생성 (BR-U4-12). 구매 수량 = 생성 수 (BR-U4-10)
- [ ] 판매 · 구매 골드는 상점 방문 골드 흐름에 그대로 반영 (HUD 갱신은 기존 `gold_changed`)
- 스토리: US-18 (AC-18-1), US-19, US-20, US-21

### Step 6. 상점 오토로드 `autoload/shop_manager.gd`
- [ ] `ShopManager` 오토로드 등록 (`project.godot`). `ShopFlow`, 출력공간 `DeliverySpace`, `QuestController` (value_of = `EconomyManager.sell_price`) 를 묶는다
- [ ] 신호: `shop_opened`, `sell_result(result)`, `buy_result(lines)`, `shop_closed`
- [ ] `_process` 에서 판매 퀘스트 시간 진행
- [ ] `DungeonManager.shop_visit_ready` 를 받아 상점을 연다 (BR-U3-22 의 "한 번" 보장)
- 스토리: US-18 (AC-18-2)

### Step 7. 출력공간 · 상점 화면 `scripts/ui_shop/shop_ui.gd`
- [ ] 판매 퀘스트 패널 (U3 긴급 요청 패널과 같은 형태: 줄 `품목 (판매/필요)`, 완료 줄 표시, 남은 시간, 보상 골드 · EXP). 위치는 왼쪽 아래 (U3 퀘스트 패널 자리 재사용)
- [ ] 출력공간: 창고 방 안 고정 위치 (예: 전달 선반 위쪽 `OUTPUT_SHELF` 영역). 가까이 가서 클릭 → 1 키 또는 드래그로 1개씩 (전달 선반과 같은 조작)
- [ ] 구매 결과 · 판매 결과 · 골드 부족 메시지 (`room.show_message`)
- [ ] 상점 종료 후 다음 던전 시작 (`DungeonUi` 가 다음 던전 번호로 `start_dungeon(no + 1)` 호출)
- 스토리: US-19 (AC-19-1), US-21 (체크리스트 실패 메시지)

### Step 8. 던전 흐름 연결
- [ ] `DungeonUi._on_shop_visit`: 기존 "U4 에서 연결 예정" 을 제거하고 상점 열기 호출
- [ ] 상점 CLOSED 신호를 받으면 다음 던전을 시작 (`start_dungeon(dungeon_no + 1)`, `start_battle`)
- [ ] 새 게임 · 게임오버 흐름은 그대로 (BR-U3-17)
- 스토리: US-18 (AC-18-1, AC-18-2)

### Step 9. 단위 테스트 `tests/unit/`
- [ ] `test_shop_rules.gd`: 판매 가능 카테고리 필터 (물약 제외, 무기 · 방어구 포함), 구매 추첨 개수, 골드 부족 판정
- [ ] `test_delivery_take.gd`: `take` 가 필요 개수만큼만 꺼내고, 초과분은 남음, `remove_all` 이 전부 꺼냄
- [ ] `test_quest_value.gd`: `QuestController` 의 `value_of` 훅 (판매가 합계), 훅이 없을 때 U3 동작 유지
- [ ] `test_shop_properties.gd` (PBT): 구매 추첨 개수 = 4, 판매 후 판매 수 = 줄 필요 합, 실패 시 출력공간 수 불변, 골드 음수 없음
- 스토리: US-19, US-20, US-21

### Step 10. 통합 테스트 `tests/integration/test_shop_flow.gd`
- [ ] 던전 1 완료 → 상점 열림 → 판매 퀘스트 성공 → 골드와 EXP 증가 → 구매 4개 생성 (incoming) → 상점 닫힘 → 던전 2 시작
- [ ] 판매 퀘스트 실패 → 출력공간 아이템이 맵으로 이동, 골드 변화 없음
- [ ] 골드 부족 구매 → 그 품목만 건너뜀, 골드와 아이템 불변
- 스토리: US-18 ~ US-21 (완료 기준)

### Step 11. 테스트 러너 등록
- [ ] `tests/run_tests.gd` 에 신규 테스트 파일 추가

### Step 12. 문서
- [ ] `aidlc-docs/construction/u4-shop/code/code-summary.md`: 스토리별 파일 · 테스트, 실행 결과, 한계 (직업별 판매, 상자, 연출은 후순위)

## 추적성

| 스토리 | 관련 Step |
| --- | --- |
| US-18 던전 완료 후 상점 방문 | 5, 6, 8, 10 |
| US-19 판매 퀘스트에 응하기 | 2, 3, 4, 5, 6, 7, 9, 10 |
| US-20 구매품 맵에 받기 | 2, 5, 9, 10 |
| US-21 골드 부족 시 구매 실패 | 2, 5, 7, 9, 10 |

모든 U4 스토리 (US-18 ~ US-21) 가 한 Step 이상에 들어 있다 (CG-1).

## 가정 (확인 필요)
1. 구매 품목 가격 · 가중치 (회복약 30 / 가중치 5, 주문서 50 / 3, 광석 상자 120 / 2) 는 제가 정한 초기값입니다.
2. 판매 퀘스트 상점 화면 위치 (출력공간) 는 전달 선반 위쪽으로 둡니다.
3. 상점 종료 시 출력공간 잔여 아이템은 맵 무작위 위치로 옮깁니다 (FD-U4-5 답변).
4. 판매 퀘스트는 던전마다 1건입니다.

## 계획 요약
- 생성 파일: 데이터 1, 규칙 1, 흐름 1, 오토로드 1, UI 1, 테스트 5~6, 문서 1
- 기존 파일 수정: `delivery_space.gd`, `quest_controller.gd`, `dungeon_ui.gd`, `project.godot`, `tests/run_tests.gd`
- 전체 Step: 12

## 승인 요청
이 계획으로 U4 코드 생성 (Part 2) 을 진행할지 승인해 주세요. 가정 1~4 중 바꿀 부분이 있으면 함께 알려 주세요.
