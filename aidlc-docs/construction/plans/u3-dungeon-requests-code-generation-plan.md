# U3 던전 · 요청 코드 생성 계획 (Code Generation Plan)

**unit**: U3 던전 · 요청 (Dungeon & Requests)
**기준 (single source of truth)**:
- `inception/application-design/unit-of-work.md` (U3 정의, 소유 컴포넌트)
- `inception/application-design/unit-of-work-story-map.md` (US-11 ~ US-17)
- `inception/user-stories/stories.md` (US-11 ~ US-17 의 AC)
- `inception/requirements/requirements.md` (FR-12 ~ 15, FR-20 ~ 23, D-04, D-06, D-14, D-15)
- `construction/u3-dungeon-requests/functional-design/` (BR-U3-01 ~ 24, business-logic-model, domain-entities, frontend-components)
- `construction/plans/u3-dungeon-requests-functional-design-plan.md` (FD 답변 + 정정)

**의존**: U1 (ItemInstance, ItemManager, StorageService, FacilityState), U2 (EconomyManager 보상 · 판매 차단)
**범위 밖**: 상점 내부 (U4), 저장 파일 (U5). U3 는 상점 호출 신호까지만 낸다 (BR-U3-22).

**프로젝트 구조 (aidlc-state.md 기준 Greenfield 다중 unit 이지만 Godot 단일 프로젝트)**: 애플리케이션 코드는 workspace 루트 (`/home/user/TheBetweenkeeper`) 아래 `autoload/`, `scripts/`, `scenes/`, `data/`, `tests/` 에 둔다. 문서는 `aidlc-docs/construction/u3-dungeon-requests/code/` 에만 둔다.

---

## 계획 단계 (Steps)

### Step 1. 던전 데이터 테이블
- [ ] `data/dungeons/dungeons.json` 생성. 던전 1 값은 기획서 8.2 와 FD 가정 (T = 10, N = 3~5, R = 1, Q = 2, 줄 1~2, 수면 30초, 제한 시간 30초) 을 넣는다. 던전 2~10 은 기획서 8.2 표 값으로 채우고 Q 는 2~10 범위 안에서 난이도에 따라 늘린다 (BR-U3-18, 24)
- 스토리: US-11 (AC-11-1), US-12, FR-12
- 확인 항목: 던전 2 이후 Q, 줄 수 값은 밸런스 조정 대상 (코드 외 데이터)

### Step 2. 전투 · 입고 규칙 (DungeonRules)
- [ ] `scripts/dungeon/dungeon_rules.gd`: 전투 수 N 무작위 (3~5), 던전 신규 아이템 총량 T 를 N 으로 균등 분배하고 나머지는 마지막 전투에 더함 (BR-U3-01, 03)
- [ ] 던전 완료 판정 함수: 남은 전투 수 = 0 만 본다. 아이템 상태를 보지 않는다 (BR-U3-02)
- 스토리: US-11 (AC-11-1, AC-11-2), US-12 (AC-12-1)

### Step 3. 퀘스트 규칙 (QuestRules)
- [ ] `scripts/dungeon/quest_rules.gd`: 줄 구성 — 창고에 있는 종류 중에서 고르고, 필요 개수 합 = Q, 나머지는 앞 줄에 더함. 쓸 종류가 없으면 생성하지 않음 (BR-U3-08, 18)
- [ ] 퀘스트 발생 시점 (전투 진행 중 무작위, 던전 1 = 1건) 계산 (BR-U3-14, 19)
- 스토리: US-15 (AC-15-1, AC-15-3), FR-20

### Step 4. 아이템 상태 확장
- [ ] `scripts/storage/item_instance.gd`: `State` enum 에 `DELIVERED` (전달 공간에 올라간 상태) 추가. 판매 불가 대상 (BR-U3-23)
- [ ] `autoload/item_manager.gd`: 전달 공간 이동 함수 추가, `mark_sold` 와 같은 방식으로 상태 변경 시그널 발행
- [ ] 기존 U1 · U2 테스트가 깨지지 않는지 확인
- 스토리: US-17 (AC-17-1), FR-23

### Step 5. 전달 공간 (DeliverySpace)
- [ ] `scripts/dungeon/delivery_space.gd`: 올라온 아이템 목록 관리. 성공 시 줄별 필요 개수만큼만 삭제, 실패 시 전부 유지 (BR-U3-12, 13, 15)
- 스토리: US-15 (AC-15-2), FR-22

### Step 6. 퀘스트 진행 (QuestController)
- [ ] `scripts/dungeon/quest_controller.gd`:
  - 아이템 올림 → 같은 종류 줄의 전달 수 +1, 필요 개수 초과 세지 않음 (BR-U3-09)
  - 줄 완료 표시 (BR-U3-10), 종류가 안 맞는 아이템은 세지 않음 (BR-U3-11)
  - 모든 줄 완료 → SUCCESS, 보상 지급 신호 (BR-U3-05)
  - 제한 시간 (30초) 경과 → FAILED, 실패 누적 +1 (BR-U3-06, 16)
  - 동시 1건만 (BR-U3-07)
- 스토리: US-15 (AC-15-1, AC-15-2), US-16 (AC-16-1, AC-16-3), FR-20, FR-21

### Step 7. 실패 누적 · 게임오버 (FailureCounter)
- [ ] `scripts/dungeon/failure_counter.gd`: F 누적, F = 3 이면 GAME_OVER 신호 (BR-U3-16, 17)
- [ ] 새 게임 시 모든 진행 값 초기화 함수
- 스토리: US-16 (AC-16-2)

### Step 8. 던전 흐름 상태 머신 (DungeonFlow)
- [ ] `scripts/dungeon/dungeon_flow.gd`: READY → IN_BATTLE (반복) → DUNGEON_COMPLETE → SLEEP (30초) → SHOP_HANDOFF. GAME_OVER 는 어느 상태에서든 전이 (business-logic-model 1절)
- [ ] 던전 완료 시 진행 중 퀘스트는 FAILED 처리 (BR-U3-21)
- [ ] 수면 중 전투 · 퀘스트 생성 없음, 정리는 가능 (BR-U3-20)
- [ ] 상점 호출 신호는 던전 1 개 완료마다 정확히 한 번 (BR-U3-22)
- 스토리: US-11 (AC-11-1), US-12 (AC-12-2), US-13 (AC-13-1, 13-2, 13-3), US-14 (AC-14-1, 14-2), US-18 (AC-18-1, 18-2)

### Step 9. DungeonManager 오토로드
- [ ] `autoload/dungeon_manager.gd` 생성, `project.godot` 의 autoload 에 등록. DungeonFlow, QuestController, FailureCounter, DeliverySpace 를 묶음
- [ ] 오토로드 간 통신은 시그널로 (U2 economy_manager 와 같은 방식)
- 스토리: 전체 (US-11 ~ US-17)

### Step 10. 보상 · 판매 연결
- [ ] 퀘스트 SUCCESS 보상을 `EconomyManager` 의 골드 · EXP 로 지급 (BR-U3-05)
- [ ] 전달 공간 아이템은 `EconomyManager.sell` 에서 거부 (BR-U3-23)
- 스토리: US-15 (AC-15-2), US-17 (AC-17-1, 17-2)

### Step 11. 단위 테스트
- [ ] `tests/unit/test_dungeon_rules.gd`: 전투 수 범위, 입고 분배 합 = T, 완료 판정이 아이템 상태와 무관함 (Step 2)
- [ ] `tests/unit/test_quest_rules.gd`: 줄 구성, 후보 없음 → 미생성, Q 범위 (Step 3)
- [ ] `tests/unit/test_quest_progress.gd`: 4개 올림 → 3/3 + 초과 1 남음, 종류 불일치 무시, 시간 초과 실패, 실패 시 전달 공간 보존 (Step 5, 6)
- [ ] `tests/unit/test_failure_counter.gd`: 3회 게임오버, 초기화 (Step 7)
- 스토리: US-11 ~ US-16

### Step 12. 속성 기반 테스트 (PBT)
- [ ] `tests/unit/test_dungeon_properties.gd` (기존 `tests/support/pbt.gd` 사용)
  - 임의 시퀀스에서 줄 전달 수 ≤ 필요 개수 (BR-U3-09)
  - 성공 시 삭제 개수 = Σ 필요 개수, 남은 수 = 올린 수 − 필요 개수 (BR-U3-12)
  - 실패 시 전달 공간 아이템 수 불변 (BR-U3-13)
  - 전투 분배 합 = T, 전투 수 ∈ [3,5] (BR-U3-01, 03)
  - 진행 중 퀘스트 ≤ 1 (BR-U3-07)
- 스토리: 전체 (PBT 확장 규칙)

### Step 13. 통합 테스트 (던전 1 슬라이스)
- [ ] `tests/integration/test_dungeon_slice.gd`: 던전 1 시작 → 전투 3~5회 → 퀘스트 1건 → 완료 → 수면 30초 → 상점 호출 1회 (BR-U3-22). 던전 완료 → 수면 → 상점 직전 상태
- 스토리: US-11 ~ US-18 (완료 기준)

### Step 14. 테스트 러너 등록
- [ ] `tests/run_tests.gd` 의 `TEST_FILES` 에 위 테스트 파일 추가

### Step 15. UI: 퀘스트 목록 · 전달 공간
- [ ] `scripts/ui_dungeon/quest_panel.gd`, `scenes/ui_dungeon/quest_panel.tscn`: 줄마다 `품목 (전달 수/필요 수)`, 완료 줄은 체크 · 흐린 글씨, 남은 시간 표시 (BR-U3-10, AC-15-1)
- [ ] 전달 공간 표시 (`delivery_space` 위젯). 위치는 Q-U3-1 답변 후 확정
- 스토리: US-15 (AC-15-1), US-17 (AC-17-2 예약 표시)

### Step 16. UI: 전투 · 수면 · 게임오버
- [ ] `scripts/ui_dungeon/battle_view.gd`: `k / N` 전투 번호 표시, 입고 연출
- [ ] `scripts/ui_dungeon/sleep_overlay.gd`, `scenes/ui_dungeon/sleep_overlay.tscn`: 30초 카운트다운 (AC-13-1)
- [ ] `scripts/ui_dungeon/game_over_screen.gd`, `scenes/ui_dungeon/game_over_screen.tscn`: `F / 3` 표시, 새 게임 버튼 (US-16 체크리스트)
- 스토리: US-11 (체크리스트 전투 번호), US-13 (AC-13-1), US-16 (AC-16-2)

### Step 17. 디버그 연결 (선택, 기존 F1 메뉴)
- [ ] `scripts/ui/debug_menu.gd` 에 퀘스트 강제 발생 · 던전 다음 단계 버튼 추가 (테스트 편의, 기능 영향 없음)
- 스토리: 없음 (개발 보조)

### Step 18. 문서
- [ ] `aidlc-docs/construction/u3-dungeon-requests/code/code-summary.md`: 스토리별 파일 · 테스트 표, 실행 결과, 한계 (상점 연결은 U4, 전달 공간 위치 확정 여부)

---

## 추적성 (Traceability)

| 스토리 | 관련 Step |
| --- | --- |
| US-11 던전 전투 진행 | 1, 2, 8, 9, 11, 13, 16 |
| US-12 던전 완료 판정 | 2, 8, 11, 13 |
| US-13 30초 수면 중 정리 | 8, 16 |
| US-14 미정리 아이템 누적 | 2, 8, 11 |
| US-15 긴급 요청 대응 | 3, 5, 6, 9, 10, 11, 15 |
| US-16 요청 실패 누적과 게임오버 | 6, 7, 11, 16 |
| US-17 요청 중 아이템 보호 | 4, 10, 15 |

모든 U3 스토리 (US-11 ~ US-17) 가 최소 한 Step 에 들어 있다 (CG-1).

---

## 질문

### Question U3-CG-1: 전달 공간 위치
전달 공간을 화면 어디에 둘까요?

A) 창고 방 안의 고정 위치 한 곳. 추천 (다른 선반 · 바닥과 함께 맵 안에서 조작)

B) 화면 한쪽에 항상 보이는 별도 패널

X) Other (please describe after [Answer]: tag below)

[Answer]:

### Question U3-CG-2: 던전 시작 시점
튜토리얼 이후 던전을 어떻게 시작할까요?

A) 튜토리얼 완료 직후 던전 1 을 자동 시작. 추천

B) 메뉴 버튼으로 시작 (플레이어가 준비한 뒤 시작)

X) Other (please describe after [Answer]: tag below)

[Answer]:

---

## 계획 요약 (Step 5)
- 생성 파일: 데이터 1, 던전 · 퀘스트 로직 파일 8, 오토로드 1, UI 장면 · 스크립트 약 6, 테스트 파일 5~6, 문서 1
- 전체 Step: 18
- 기존 파일 수정: `item_instance.gd`, `item_manager.gd`, `economy_manager.gd`, `project.godot`, `tests/run_tests.gd`, `debug_menu.gd`
- 판매 · 보상 · 상태 추가는 U1 · U2 테스트를 깨뜨리지 않아야 한다 (Step 4 확인)

## 승인 요청
이 계획으로 U3 Code Generation (Part 2) 을 진행할까요? 질문 2개 (U3-CG-1, U3-CG-2) 의 답을 함께 알려 주세요.
