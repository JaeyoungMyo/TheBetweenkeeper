# U5 저장 · 플랫폼 코드 생성 계획 (Code Generation Plan)

**unit**: U5 저장 · 플랫폼 (Save & Platform)
**기준 (single source of truth)**:
- `construction/u5-save-platform/functional-design/` (BR-U5-01 ~ 12, 산출물 4종)
- `construction/plans/u5-save-platform-functional-design-plan.md` (FD-U5-1 ~ 11 답변)
- `inception/user-stories/stories.md` (SYS-01, SYS-04. SYS-02 웹 내보내기는 FD-U5-5 B 로 제외, SYS-03 웹 배포는 빌드 설정)
- `inception/requirements/requirements.md` (FR-25, FR-27, FR-28, NFR-03, NFR-07, NFR-08)

**의존**: U1 (ItemManager, StorageRoom, StorageFacility/FacilityState), U2 (EconomyManager), U3 (DungeonManager, DungeonFlow), U4 (ShopFlow, 상점 완료 신호)
**범위 밖**: 영어 번역 (FR-28, MVP 이후), 웹 내보내기 · 불러오기 (SYS-02), 수동 저장 버튼, 진행 중 퀘스트 저장

**구현 원칙**: 저장은 `user://` 파일 하나 (`save.dat`). 내용은 JSON 을 암호화하고 HMAC-SHA256 서명을 붙인다. 웹에서 암호화가 안 되면 서명만 쓴다 (BR-U5-03). 키는 상수 (BR-U5-04).

## 계획 단계 (Steps)

### Step 1. 저장 코덱 `scripts/save/save_codec.gd` (BR-U5-03, 04, 05)
- [ ] `encode(data: Dictionary) -> String`: JSON → 암호화 (`FileAccess.open_encrypted_with_pass` 또는 `Crypto` 기반) → 서명 포함 봉투 (`{"payload", "signature"}`)
- [ ] `decode(text: String) -> Dictionary`: 서명 검사. 틀리면 빈 딕셔너리 (거부)
- [ ] 키 상수 `KEY` 는 한 곳에 둔다 (빌드 시 교체 대상, V-4 A)
- [ ] 암호화 지원 여부 검사. 미지원이면 서명만 쓰는 모드 (V-1)
- 스토리: SYS-01 (AC-SYS-01-2), SYS-02 기준 (AC-SYS-02-3 의 거부 규칙)

### Step 2. 저장 데이터 조립 `scripts/save/save_data.gd` (BR-U5-06, 08; FD-U5-11 A)
- [ ] `capture() -> Dictionary`: 던전 번호 · 완료 횟수, 골드, 레벨 · EXP, 증강, 아이템 (instance_id, item_id, stage_id, 상태 (incoming · stored · delivered 는 delivered 제외 → 전달 선반 아이템은 incoming 으로 저장 · carried 는 incoming 으로 저장), 위치, 시설 ID, 칸), 선반 (종류 · 위치 · 칸 수 · 칸별 아이템), 실패 수, 튜토리얼 완료, 상점 방문 수, 저장 지점
- [ ] `restore(data: Dictionary)`: 역순. 아이템 인스턴스는 저장된 instance_id 를 그대로 쓴다 (중복 생성 방지, NFR-03). 골드와 EXP 는 EconomyManager 한 곳으로만 설정
- [ ] 진행 중 퀘스트 · 판매 퀘스트는 저장하지 않는다 (BR-U5-06)
- 스토리: SYS-01 (AC-SYS-01-1, 01-2), NFR-03

### Step 3. 저장 서비스 `autoload/save_service.gd`
- [ ] `SaveService` 오토로드 (project.godot 등록). `save_point(kind: "dungeon_clear" | "shop_clear")`: capture → encode → `user://save.dat` 쓰기
- [ ] `has_save()`, `load_save() -> bool`: 읽기 → decode → restore. 실패 시 false (새 게임)
- [ ] `delete_save()`: 게임오버 시 (BR-U5-07)
- [ ] 쓰기 실패 시 메시지만 띄우고 게임은 계속 (안전)
- 스토리: SYS-01 (AC-SYS-01-1, 01-2)

### Step 4. 저장 지점 연결
- [ ] `DungeonManager.finish_battle` 에서 던전 완료 시 `SaveService.save_point("dungeon_clear")` (BR-U5-01)
- [ ] 상점 DONE 시 `ShopFlow` 완료 신호에서 `save_point("shop_clear")`. 상점 방문 수 +1
- [ ] 복원 지점: dungeon_clear 저장이면 수면 · 상점 직전 (상점 방문 전), shop_clear 면 다음 던전 시작 전 (FD-U5-6 B)
- 스토리: SYS-01 (AC-SYS-01-1)

### Step 5. 게임오버 연결 (BR-U5-07)
- [ ] `DungeonUi._on_game_over` 에서 `delete_save()`. 새 게임 버튼 흐름은 기존 `_new_game` 유지

### Step 6. 시작 흐름 (복원 선택)
- [ ] `tutorial_storage.gd` 시작 시: 저장이 있으면 "이어하기 / 새 게임" 버튼. 서명 실패면 "저장 파일이 손상되어 새 게임으로 시작합니다" 메시지 후 새 게임
- [ ] 이어하기: `load_save()` 후 저장 지점에 맞춰 던전 또는 상점 다음 단계 시작 (BR-U5-02 는 수동 저장 없음)
- 스토리: SYS-01 (AC-SYS-01-2)

### Step 7. 설정 패널 `scripts/ui/settings_panel.gd`
- [ ] 전체 화면 전환 버튼 (`DisplayServer.window_set_mode`, BR-U5-10)
- [ ] 언어 항목: 한국어만 (BR-U5-11). 선택 목록은 한국어 한 개
- [ ] 저장 안내 문구: 브라우저 데이터가 지워지면 진행이 사라진다 (웹 빌드 시)
- [ ] 열기 키: F2 (디버그 메뉴 F1 과 구분)
- 스토리: SYS-04 (AC-SYS-04-1, 04-2)

### Step 8. 해상도 · 렌더러 확인 (BR-U5-10, 12)
- [ ] `project.godot` 확인: 1280x720, `canvas_items`, `aspect="keep"` (이미 설정됨), `gl_compatibility`, Compatibility 기능. 변경 없음 확인만
- [ ] 스레드 미사용 (웹 Export 설정은 빌드 단계, 이번 계획은 설정 확인만)
- 스토리: SYS-03 (AC-SYS-03-2), SYS-04

### Step 9. 단위 테스트 `tests/unit/`
- [ ] `test_save_codec.gd`: 왕복 (encode → decode 동일), 1바이트 변조 시 거부, 키 다르면 거부
- [ ] `test_save_data.gd`: capture → restore 후 아이템 수 · 상태 · instance_id 동일, 골드 · EXP 동일, delivered 아이템은 incoming 으로 저장
- [ ] `test_save_properties.gd` (PBT, NFR-09): 임의 아이템 구성 (1~40개, 상태 무작위) 으로 왕복 10회 → 아이템 수와 상태 동일 (BR-U5-08, AC-SYS-01-3)
- 스토리: SYS-01 (AC-SYS-01-2, 01-3), NFR-03

### Step 10. 통합 테스트 `tests/integration/test_save_flow.gd`
- [ ] 던전 완료 저장 → 새 상태로 초기화 → 불러오기 → 골드 · 실패 수 · 던전 번호 · 아이템 수 동일
- [ ] 게임오버 시 저장 파일 삭제, 다음 `has_save()` false
- [ ] 변조된 파일 로드 → 새 게임 (false 반환)
- 스토리: SYS-01 (AC-SYS-01-1, 01-2), BR-U5-05, BR-U5-07

### Step 11. 테스트 러너 등록
- [ ] `tests/run_tests.gd` 에 신규 테스트 파일 추가

### Step 12. 문서
- [ ] `aidlc-docs/construction/u5-save-platform/code/code-summary.md`: 스토리별 파일 · 테스트, 실행 결과, 한계 (웹 Export 설정 · 웹 내보내기 제외, 영어 제외, HMAC 키 개인용 수준)

## 추적성

| 스토리 | 관련 Step |
| --- | --- |
| SYS-01 던전 완료 시 자동 저장 | 1, 2, 3, 4, 6, 9, 10 |
| SYS-03 웹 배포 | 8 (설정 확인), 빌드 단계로 이월 |
| SYS-04 화면과 언어 설정 | 7, 8 |
| SYS-02 웹 세이브 내보내기 | 제외 (FD-U5-5 B) |

## 가정 (확인 필요)
1. 키 상수는 소스에 들어가므로 저장 변조 방지는 개인용 수준입니다 (FD-U5-4 A).
2. 전체 화면 전환은 데스크톱에서 확실히 동작합니다. 웹은 브라우저 정책을 따릅니다.
3. 이어하기 시 상점 방문 중 저장 (shop_clear 전) 은 없다고 봅니다. 상점 중 종료하면 마지막 던전 완료 지점으로 돌아갑니다.

## 계획 요약
- 생성 파일: 코덱 1, 데이터 1, 오토로드 1, 설정 패널 1, 테스트 4, 문서 1
- 기존 파일 수정: `dungeon_manager.gd`, `dungeon_ui.gd`, `tutorial_storage.gd`, `project.godot`, `tests/run_tests.gd`
- 전체 Step: 12

## 승인 요청
이 계획으로 U5 코드 생성 (Part 2) 을 진행할지 승인해 주세요. 가정 1 ~ 3 을 확인해 주세요.
