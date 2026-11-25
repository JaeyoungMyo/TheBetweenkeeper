# Unit of Work 정의 (Unit of Work)

**기준**: `plans/unit-of-work-plan.md` (UG-1 ~ UG-6 확정), `application-design/application-design.md`, `user-stories/stories.md`

## 1. 코드 구성 전략 (UG-1 A, Greenfield)

단일 Godot 4.7.2 프로젝트 안에서 폴더 단위로 unit 을 나눈다. unit 은 독립 배포 단위가 아니라 코드와 씬의 묶음이다.

```text
res://
├── autoload/                 # 공통 오토로드 4개 (unit 간 공유, 소유 unit 명시)
│   ├── game_manager.gd       # U5 소유
│   ├── dungeon_manager.gd    # U3 소유 (ShopFlow 는 U4)
│   ├── item_manager.gd      # U1 소유
│   └── economy_manager.gd    # U2 소유
├── scripts/
│   ├── storage/              # U1: WeightRules, PlacementRules, StorageService
│   ├── growth/               # U2: ExpCalculator, AugmentPool, ProgressionService
│   ├── economy/              # U2: GoldLedger, 구매 · 판매 · 시설 구매
│   ├── dungeon/              # U3: DungeonFlow, RequestController, RequestRules
│   ├── shop/                 # U4: ShopFlow, PurchaseRoller, ShopService
│   └── save/                 # U5: SaveCodec, SaveService
├── scenes/
│   ├── storage/              # U1: StorageRoom, Player, Item, StorageFacility, InputSpace, OutputSpace
│   ├── ui_storage/           # U1: ItemListPanel, ShelfPanel
│   ├── ui_growth/            # U2: AugmentSelection, HUD (EXP 부분)
│   ├── ui_dungeon/           # U3: BattleView, SleepOverlay, RequestPanel, GameOverScreen
│   ├── ui_shop/              # U4: ShopView
│   └── ui_platform/          # U5: SaveTransferPanel, 해상도 · 언어 설정
├── data/
│   ├── items/                # U1: ItemData (.tres)
│   ├── facilities/           # U1: FacilityData (.tres)
│   ├── dungeons/             # U3: DungeonTable (JSON)
│   ├── shop/                 # U4: ShopTable (JSON)
│   └── augments/             # U2: AugmentTable (JSON)
├── tests/
│   ├── unit/                 # 순수 클래스 PBT (NFR-09), unit 별 폴더
│   └── integration/          # 흐름 테스트 (튜토리얼, 던전 1, 상점, 저장 왕복)
└── main.tscn                 # 전체 조립 (U5 소유, 나머지 unit 의 씬을 연결)
```

## 2. Unit 정의

### U1 창고 · 조작 (Storage & Controls)
- **목적**: 플레이어가 아이템을 직접 옮기는 기본 정리 경험
- **소유 범위**: 플레이어 이동, 아이템 목록, 선반 패널, 맵 드롭, 바닥 줍기, 무게 적재 규칙, 입력 · 출력공간 (시설 형태)
- **소유 컴포넌트**: `ItemManager` (오토로드), `WeightRules`, `PlacementRules`, `StorageService`, `Player`, `Item`, `StorageFacility`, `InputSpace`, `OutputSpace`, `ItemListPanel`, `ShelfPanel`, `ItemData`, `FacilityData`
- **관련 스토리**: US-01 (조작 부분), US-02, US-03, US-04, US-05, US-06, US-07, US-08
- **관련 FR**: FR-01 ~ FR-09, FR-29 (조작 부분), FR-31 (배치 위치 계산), FR-30 (출력공간 이동)
- **Functional Design**: 적용 (UG-4 A) — 무게 적재 규칙, 줍기 상태 전환, 적재 거부 처리
- **완료 기준**: US-02 ~ US-08 의 인수 조건을 통과하고, WeightRules · PlacementRules 의 PBT 가 통과
- **구현 순서**: 튜토리얼 슬라이스의 첫 단계 (조작 → 적재)

### U2 성장 · 경제 (Growth & Economy)
- **목적**: 정리에 따른 EXP · 증강 성장과 공유 골드 경제
- **소유 범위**: 공유 골드, 판매 가격, 시설 구매 · 확장, EXP 지급, 레벨업, 증강 선택
- **소유 컴포넌트**: `EconomyManager` (오토로드), `GoldLedger`, `ExpCalculator`, `AugmentPool`, `ProgressionService`, `AugmentSelection`, `HUD` (골드 · EXP 표시)
- **관련 스토리**: US-09, US-10, US-22
- **관련 FR**: FR-10, FR-11, FR-19 (잔액 차감 계산), FR-23 (판매 가격), FR-24
- **Functional Design**: 미적용 (UG-4 A 에 따라 규칙이 단순한 unit). Code Generation 에서 설계 포함
- **완료 기준**: US-09 ~ US-10, US-22 통과, GoldLedger · ExpCalculator · AugmentPool 의 PBT 통과
- **구현 순서**: 튜토리얼 슬라이스에 EXP 와 골드 표시를 포함

### U3 던전 · 요청 (Dungeon & Requests)
- **목적**: 던전 흐름 (전투, 완료, 수면, 누적) 과 긴급 요청 게임 루프
- **소유 범위**: `DungeonFlow` 상태 머신, 전투마다 입고 요청, 던전 완료 판정, 30초 수면, 미정리 누적, 긴급 요청 (`RequestController`), 누적 실패 게임오버
- **소유 컴포넌트**: `DungeonManager` (오토로드, ShopFlow 제외), `DungeonFlow`, `RequestController`, `RequestRules`, `BattleView`, `SleepOverlay`, `RequestPanel`, `GameOverScreen`, `DungeonTable`
- **관련 스토리**: US-11, US-12, US-13, US-14, US-15, US-16, US-17
- **관련 FR**: FR-12 ~ FR-15, FR-20 ~ FR-23 (요청 부분)
- **Functional Design**: 적용 (UG-4 A) — 상태 전환 규칙, 완료 판정, 요청 시간 누적, 실패 누적
- **완료 기준**: US-11 ~ US-17 통과. 던전 1 흐름 통합 테스트 통과 (완료 → 수면 → 상점 직전 상태)
- **구현 순서**: 튜토리얼 이후 던전 1 슬라이스

### U4 상점 (Shop)
- **목적**: 던전마다 열리는 상점 방문 (판매 요청, 구매, 입력공간 입고)
- **소유 범위**: `ShopFlow`, 판매 요청 · 출력공간 판매 확정, 구매 추첨 (`PurchaseRoller`), 구매 차감, 입력공간 무작위 입고, 골드 부족 실패, 입력공간 여유 확인 (UG-5 A)
- **소유 컴포넌트**: `ShopFlow`, `ShopService`, `PurchaseRoller`, `ShopView`, `ShopTable`
- **관련 스토리**: US-18, US-19, US-20, US-21
- **관련 FR**: FR-16, FR-17, FR-18, FR-19 (구매 실패 처리), FR-30, FR-31
- **Functional Design**: 적용 (UG-4 A) — 가중치 추첨, 판매 · 구매 순서, 입력공간 여유 검사
- **완료 기준**: US-18 ~ US-21 통과. 입력공간이 가득 찬 상태에서 구매가 막히는 테스트 (UG-5 A) 통과
- **구현 순서**: 던전 1 이후 상점 슬라이스

### U5 저장 · 플랫폼 (Save & Platform)
- **목적**: 자동 저장, 웹 세이브 내보내기 · 불러오기, 웹 배포, 화면 · 언어 설정
- **소유 범위**: `GameManager` (오토로드), `SaveService`, `SaveCodec` (HMAC 서명), 데이터 암호화 설정 (V-1), 웹 Export 설정, 해상도, 한국어 UI 리소스, `main.tscn` 조립
- **소유 컴포넌트**: `GameManager` (오토로드), `SaveService`, `SaveCodec`, `SaveTransferPanel`, `Main`
- **관련 스토리**: SYS-01, SYS-02, SYS-03, SYS-04
- **관련 FR**: FR-25, FR-26, FR-27, FR-28, NFR-03, NFR-06, NFR-07, NFR-08
- **Functional Design**: 미적용 (UG-4 A). 서명 · 암호화 세부는 Code Generation 에서 설계 포함, 검증 항목 V-1, V-2, V-4 를 여기서 처리
- **완료 기준**: SYS-01 ~ SYS-04 통과. 저장 10회 왕복 테스트 통과 (NFR-03). 웹 Export 에서 "Play in browser" 실행 확인 (NFR-06)
- **구현 순서**: 마지막 슬라이스 (저장 · 플랫폼). 단, 자동 저장 훅은 던전 1 슬라이스에서 최소 형태로 먼저 연결

## 3. 구현 슬라이스 순서 (UG-3 B, 수직 슬라이스)

| 순서 | 슬라이스 | 포함 unit | 결과 |
| --- | --- | --- | --- |
| 1 | 튜토리얼 | U1 (조작 · 적재), U2 (EXP · 골드 최소 표시) | 아이템 10개를 목록 → 선반으로 옮김 (US-01) |
| 2 | 던전 1 | U3 (전투 · 완료 · 수면 · 누적 · 요청), U5 (자동 저장 최소) | 전투 3~5회, 완료, 30초 수면, 미정리 누적 |
| 3 | 상점 | U4 (판매 · 구매 · 입력공간), U2 (구매 골드 차감) | 던전 완료 후 상점 방문, 구매품 입고 |
| 4 | 저장 · 플랫폼 | U5 (세이브 서명, 내보내기, 웹 배포), 나머지 unit 의 세부 보완 | 재실행 복원, 웹 zip 배포 |

## 4. 테스트 배치

- **순수 클래스 PBT** (NFR-09): 각 unit 의 `tests/unit/` 폴더에 둔다
  - U1: WeightRules, PlacementRules
  - U2: GoldLedger, ExpCalculator, AugmentPool
  - U3: RequestRules
  - U4: PurchaseRoller
  - U5: SaveCodec (서명 왕복)
- **흐름 테스트** (`tests/integration/`): 슬라이스마다 하나씩 추가
- **수동 검증**: 연출, 조작감, 웹 실행 (Performance Validation, Build and Test 에서 수행)

## 5. 확인된 가정

- unit 은 배포 단위가 아니다. 단일 Godot 프로젝트 안의 코드 묶음이다.
- 오토로드 4개는 특정 unit 이 소유하고, 다른 unit 은 공개 메서드와 시그널만 사용한다 (application-design.md 의 규칙)
- UG-5 A 에 따라 V-3 는 해소되었다. 입력공간 용량 값 자체는 Code Generation 에서 정한다
