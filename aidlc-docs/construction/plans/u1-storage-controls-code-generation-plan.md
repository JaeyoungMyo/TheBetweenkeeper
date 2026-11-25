# U1 창고 · 조작 코드 생성 계획 (Code Generation Plan)

**unit**: U1 창고 · 조작 (Storage & Controls)
**기준 (단일 기준 문서, single source of truth)**:
- `construction/u1-storage-controls/functional-design/` (business-logic-model, business-rules, domain-entities)
- `inception/application-design/unit-of-work.md` (U1 범위, 폴더 구조), `components.md`, `component-methods.md`
- `inception/user-stories/stories.md` (US-01 ~ US-08), `inception/requirements/requirements.md` (FR-01 ~ FR-09, FR-29 조작 부분, FR-30, FR-31 배치 계산)

**확정 전제**
- 칸당 무게 한도 12 고정, 선반 3칸 (최대 36), 손에 드는 아이템 1개 (FD-U1-2)
- 아이템 무게 정수 1, 2, 3, 4, 6. 무게 등급 (경량 ≤2, 중량 ≤4, 고중량 >4) 은 분류 정보
- 이동 속도는 아이템 무게와 무관하게 일정 (사용자 정정, FR-08, BR-U1-09)
- 드롭은 항상 플레이어 발 아래 (FD-U1-6 X), 무게 초과 낙하도 플레이어 발 아래, 상태 `incoming` (FD-U1-5)
- 줍기 거리 48px, 호버 64px (FD-U1-4)

**코드 위치**: 워크스페이스 루트 `d:\Desktop\game\아공간관리인` 아래 Godot 프로젝트 (`project.godot`). `aidlc-docs/` 에는 코드를 두지 않는다.

**검증 한계**: 이 환경에서 Godot 에디터 화면 조작은 하지 않는다. 순수 로직은 GDScript 테스트 (PBT 스타일 반복 검증) 로 확인하고, 조작감과 연출은 수동 확인 (Build and Test 단계) 으로 넘긴다.

---

## 단계 (Steps)

### Step 1: 프로젝트 기본 구성 (Project Structure Setup, Greenfield)
- [x] `project.godot` 생성 (Godot 4.7, Compatibility 렌더러, 1280x720 고정, 16:9 비율 유지 설정) — FR-27, NFR-08, D-10
- [x] `res://` 폴더 구조 생성 (`autoload/`, `scripts/storage/`, `scenes/storage/`, `scenes/ui_storage/`, `data/items/`, `data/facilities/`, `tests/unit/`)
- [x] 입력 맵 설정 (WASD, 방향키, 상호작용 키) — FR-01, D-16
- [x] 기준 story: US-08 (이동 기반)

### Step 2: 순수 규칙 클래스 (Business Logic Generation)
- [x] `scripts/storage/weight_rules.gd` (`WeightRules`): 합계, 칸 적재 가능 여부 (합 ≤ 12), 무게 등급 분류 — BR-U1-01, 03, 10, 11
- [x] `scripts/storage/placement_rules.gd` (`PlacementRules`): 사각 겹침 검사, 빈 자리 선택 — FR-03, FR-31 계산 기반
- [x] `scripts/storage/slot_rules.gd` (`SlotRules`, 신규): 칸 상태 기준 적재 결과 (배정, 거부 사유) — BR-U1-01, 02, 12, 13
- [x] 기준 story: US-03, US-06

### Step 3: 데이터 리소스 (Business Logic Generation, 데이터)
- [x] `scripts/storage/item_data.gd` (`ItemData`, Resource): `weight` (int, 1·2·3·4·6), `weight_class`, `footprint`, `base_price`, `exp_value`, `allowed_facilities`, 검증 함수 — BR-U1-16
- [x] `scripts/storage/facility_data.gd` (`FacilityData`, Resource): `slot_count` (선반 3), `slot_weight_limit` (12 고정), `max_weight` = 칸 수 × 12 — BR-U1-02
- [x] `data/items/` 튜토리얼 아이템 10개 `.tres` (무게 1, 2, 3, 4, 6 조합. 12 를 정확히 채우는 조합 포함) — FR-29
- [x] `data/facilities/shelf_basic.tres` (선반, 3칸)
- [x] 기준 story: US-01

### Step 4: 아이템 상태와 관리자 (Business Logic Generation, 핵심)
- [x] `autoload/item_manager.gd` (`ItemManager`, 오토로드): `ItemInstance` 생성, 상태 전환 (`incoming`, `carried`, `stored`), 줍기 · 드롭 · 적재 · 꺼내기 — BR-U1-04 ~ 07, 12, 13, 14
- [x] `scripts/storage/storage_service.gd` (`StorageService`): 줍기 (거리 48px, 손 1개), 적재 (패널 열림 필수, 칸 · 선반 검사), 무게 초과 낙하 (발 아래 + `incoming`), 맵 드롭 (발 아래) — FD-U1-4, FD-U1-5, FD-U1-6
- [x] 시그널: `item_state_changed`, `item_dropped`, `weight_rejected` — AD-4
- [x] 기준 story: US-02, US-03, US-04, US-05, US-06

### Step 5: 플레이어 · 이동 (Business Logic Generation, 씬 연결)
- [x] `scenes/storage/player.tscn` + `scripts/storage/player_controller.gd` (CharacterBody2D): WASD/방향키 이동, 벽 · 시설 충돌, 기본 속도 (무게와 무관, BR-U1-09) — FR-01, FR-08
- [x] 손에 든 아이템 1개 (`PlayerCarry`), 들고 있을 때 아이템 위치를 플레이어 손에 붙임 — BR-U1-06
- [x] 기준 story: US-07, US-08

### Step 6: 맵 · 시설 · 아이템 씬 (API Layer 에 해당하는 씬 연결)
- [x] `scenes/storage/storage_room.tscn`: 바닥, 벽, 시설 배치, 맵 드롭 입력
- [x] `scenes/storage/item.tscn` + `item.gd`: 시각 표현, 호버 이름 표시 (64px), 클릭 · 줍기 입력
- [x] `scenes/storage/storage_facility.tscn` + `storage_facility.gd`: 칸 3개 표시, 칸별 적재 상태, 패널 열기 입력
- [x] 기준 story: US-04, US-05

### Step 7: UI (Frontend Components Generation)
- [x] `scenes/ui_storage/item_list_panel.tscn`: 들고 있는 아이템 목록 상시 표시, 드래그 원본 — FR-02, US-02
- [x] `scenes/ui_storage/shelf_panel.tscn`: 선반 패널 (칸 3개, X 버튼, 다시 클릭으로 닫기), 칸 드롭 대상 — FR-03, US-03
- [x] `무게 초과` 메시지 표시 (HUD 공용 메시지 영역) — FR-07, D-09
- [x] 기준 story: US-02, US-03, US-06

### Step 8: 단위 테스트 (Business Logic Unit Testing, PBT 스타일)
- [x] `tests/unit/test_weight_rules.gd`: 임의 적재 시퀀스로 칸 합 ≤ 12 불변식, 경계값 (12 허용, 13 거부), 무게 등급 경계 (2, 3, 4, 5)
- [x] `tests/unit/test_slot_rules.gd`: 동일 아이템 조합으로 12 정확히 채우기 (6+6, 4+4+4, 3+3+3+3, 2×6, 1×12), 중복 적재 거부
- [x] `tests/unit/test_item_manager.gd`: 상태 전환 규칙 (incoming → carried → stored, 낙하 시 incoming), 손 1개 제한, 꺼내기 후 합계 불변
- [x] `tests/unit/test_placement_rules.gd`: 겹침 검사, 빈 자리 선택
- [x] `tests/unit/test_movement_speed.gd`: 무게 1 과 6 아이템을 들었을 때 이동 속도 동일 (BR-U1-09)
- [x] 기준 story: US-01 ~ US-08 의 체크리스트와 BR 전체

### Step 9: 튜토리얼 통합 (Integration, 슬라이스 1)
- [x] `scenes/storage/tutorial_storage.tscn`: 아이템 10개 생성, 목록 표시, 선반 3칸 배치 — US-01
- [x] 튜토리얼 종료 조건: 10개 모두 `stored` — US-01 AC-01-3
- [x] `tests/integration/test_tutorial_slice.gd`: 시나리오 흐름 확인 (목록 → 선반 → 적재 → 종료)

### Step 10: 요약 (Business Logic Summary, API Summary)
- [x] `aidlc-docs/construction/u1-storage-controls/code/code-summary.md` (Markdown 요약만. 코드 자체는 워크스페이스에 둠)
- [x] 스토리 → 파일 매핑, BR → 테스트 매핑 표 작성
- [x] 알려진 한계와 수동 검증 목록 (조작감, 호버 타이밍, 드롭 위치 연출)

### Step 11: 배포 산출물 (Deployment Artifacts, U1 범위)
- [x] U1 은 배포 산출물을 따로 만들지 않는다. 웹 Export 설정은 U5 에서 처리 (unit-of-work.md 기준)

---

## 추적성 요약

| 단계 | 스토리 | BR | FR |
| --- | --- | --- | --- |
| Step 1 | US-08 | - | FR-01, FR-27 |
| Step 2 | US-03, US-06 | BR-U1-01, 03, 10, 11 | FR-03, FR-06 |
| Step 3 | US-01 | BR-U1-02, 16 | FR-06, FR-29 |
| Step 4 | US-02 ~ US-06 | BR-U1-04 ~ 07, 12 ~ 14 | FR-02 ~ FR-07, FR-09 |
| Step 5 | US-07, US-08 | BR-U1-06, 09 | FR-01, FR-08 |
| Step 6 | US-04, US-05 | BR-U1-05, 07, 08 | FR-04, FR-05 |
| Step 7 | US-02, US-03, US-06 | - | FR-02, FR-03, FR-07 |
| Step 8 | US-01 ~ US-08 | BR-U1-01 ~ 17 | 전체 |
| Step 9 | US-01 | BR-U1-06 | FR-29 |

## 확인 사항

- 이 계획은 코드 생성의 기준이다. 승인 후에는 이 단계 순서대로만 진행한다
- 워크스페이스에 Godot 프로젝트가 아직 없으므로 Step 1 에서 새로 만든다
- 승인 후 Step 1 부터 실행하고, 단계마다 체크박스를 [x] 로 표시한다
