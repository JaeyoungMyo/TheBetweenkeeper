# 컴포넌트 정의 (Components)

**기준**: `requirements.md` (FR-01~31, NFR-01~09, D-01~18), `application-design-plan.md` (AD-1~AD-9 답변 반영)

## 설계 원칙 (AD 답변 반영)

- **AD-1 (B)**: 오토로드는 4개. 나머지는 오토로드가 소유하는 순수 클래스 또는 씬 노드
- **AD-2 (A)**: 입력공간과 출력공간은 맵 위의 실제 시설 (플레이어가 걸어가서 옮김)
- **AD-3 (A)**: 계산 로직은 노드가 없는 순수 GDScript 클래스로 둠. PBT 대상
- **AD-4 (A)**: 컴포넌트 간 통신은 Godot 시그널 중심. 호출 방향은 상위 → 하위 메서드 호출, 하위 → 상위는 시그널
- **AD-5 (A)**: 던전 흐름은 명시적 상태 머신 하나 (`DungeonFlow`)
- **AD-6 (A)**: 긴급 요청 시간은 `RequestController._process` 에서 누적
- **AD-7 (C)**: 아이템 · 시설 데이터는 `.tres`, 던전 · 상점 표는 JSON
- **AD-8 (A) + AD-9 (B)**: 세이브는 JSON + HMAC 서명. 데이터 파일은 암호화 (웹 지원 여부는 Build 단계에서 검증, 미지원 시 평문 유지 후 기록)
- **AD-1 과 AD-6 의 조정**: 요청 기능은 AD-1 에 따라 `DungeonManager` 소속이다. AD-6 의 "RequestManager" 는 그 안의 하위 컴포넌트 `RequestController` 로 구현한다 (오토로드로 두지 않음)

---

## 1. 오토로드 (Autoload, 전역 소유)

### 1-1. GameManager
- **목적**: 게임 전체 상태 소유, 저장 · 불러오기 조정, 게임오버 처리
- **책임**
  - 현재 던전 번호, 완료 던전 수, 긴급 요청 누적 실패 수 (`request_fail_count`) 보관
  - 저장 시점 (던전 완료 시, FR-25) 에 스냅샷 생성 요청
  - 게임오버 (누적 실패 3회, FR-21) 전환
  - 씬 전환 (Main 이 소유하는 화면 전환)
- **소유 하위 컴포넌트**: `SaveService` (직렬화 조정), `SaveCodec` (순수 클래스)

### 1-2. DungeonManager
- **목적**: 던전 흐름 (전투, 완료, 수면, 상점 방문, 다음 던전) 과 긴급 요청, 상점 흐름을 소유
- **책임**
  - `DungeonFlow` 상태 머신 실행 (FR-12~FR-17)
  - 전투마다 신규 아이템 입고 요청 (ItemManager 에 위임)
  - 던전 완료 판정 (정리 여부와 무관, FR-13)
  - 30초 수면 이벤트 시간 관리 (FR-14)
  - 미정리 아이템 누적 (FR-15, 상태는 그대로 두고 다음 던전 목록에 포함)
  - 상점 방문 흐름 시작 (판매 요청 → 출력공간, 구매 → 입력공간, FR-16, FR-30, FR-31)
  - 긴급 요청 (생성, 제한 시간, 성공 · 실패, FR-20~22)
- **소유 하위 컴포넌트**: `DungeonFlow` (상태 머신), `RequestController` (요청 시간), `ShopFlow` (상점 단계)

### 1-3. ItemManager
- **목적**: 아이템 인스턴스 · 공간 · 무게 규칙을 소유
- **책임**
  - `ItemInstance` 생성 · 상태 전환 (FR-09)
  - 입력공간 무작위 입고 (FR-31)
  - 출력공간 적재 · 판매 대상 관리 (FR-30)
  - 플레이어의 줍기, 내려놓기, 적재 요청 처리 (FR-03~05)
  - 무게 한도 검사 결과로 적재 거부 · 손에 유지 처리 (FR-06, FR-07)
  - 시설 목록 (`StorageFacility`, `InputSpace`, `OutputSpace`) 관리
- **소유 하위 컴포넌트**: `WeightRules`, `PlacementRules` (순수 클래스)

### 1-4. EconomyManager
- **목적**: 공유 골드, EXP, 판매 · 구매 가격, 시설 구매를 소유 (D-03의 골드 단일 원본, NFR-04)
- **책임**
  - 골드 잔액 단일 원본 (`GoldLedger`, 증감은 이 매니저 메서드로만 허용, NFR-04)
  - 판매 가격 계산, 판매 처리 (FR-23)
  - 구매 품목 가중치 추첨 (`PurchaseRoller`, D-05 POC 범위, FR-18)
  - 구매 비용 차감 (FR-19), 시설 구매 · 확장 (FR-24)
  - EXP 지급 (중복 방지, FR-10), 레벨업, 증강 후보 선택 (`AugmentPool`, FR-11)

---

## 2. 순수 클래스 (Pure, 노드 없음, PBT 대상)

| 클래스 | 소유 | 책임 | 관련 요구사항 |
| --- | --- | --- | --- |
| `WeightRules` | ItemManager | 시설 적재 무게 합, 적재 가능 여부, 이동 속도 감소율 | FR-06, FR-08 |
| `PlacementRules` | ItemManager | 맵 위 겹침 검사 (사각 충돌 영역), 무작위 입고 위치 선택 | FR-03, FR-31 |
| `GoldLedger` | EconomyManager | 잔액 증감, 부족 시 실패 반환 | FR-19, NFR-04 |
| `ExpCalculator` | EconomyManager | 수납 EXP 계산, 레벨업 필요량 | FR-10 |
| `AugmentPool` | EconomyManager | 증강 후보 추첨, 중복 제한 | FR-11 |
| `PurchaseRoller` | EconomyManager | 가중치 기반 구매 품목과 수량 추첨 (시드 주입 가능) | FR-18 |
| `RequestRules` | DungeonManager | 누적 실패 수 증가, 게임오버 판정 (3회) | FR-21 |
| `SaveCodec` | GameManager | 스냅샷 ↔ JSON, HMAC 서명 생성 · 검증 | FR-25, FR-26, NFR-03 |

---

## 3. 씬 노드 (Scene Nodes)

| 노드 (씬) | 종류 | 책임 | 관련 요구사항 |
| --- | --- | --- | --- |
| `Main` | 루트 | 전체 씬 조립, 화면 전환 실행 (GameManager 요청 수신) | FR-27 |
| `StorageRoom` | 맵 | 바닥 · 벽, 충돌 타일, 시설 배치 | FR-01 |
| `Player` | CharacterBody2D | 이동, 충돌, 들고 있는 아이템 표시, 줍기 입력 | FR-01, FR-05, FR-08 |
| `Item` | Node2D | 아이템 시각 표현, 호버 이름 표시, 클릭 · 드래그 감지 | FR-05 |
| `StorageFacility` | StaticBody2D | 선반. 적재 패널 열기, 최대 무게 표시, 칸 목록 | FR-03, FR-06 |
| `InputSpace` | StorageFacility 파생 | 구매품이 무작위로 쌓이는 입력공간 (AD-2 맵 시설) | FR-31, A-07 |
| `OutputSpace` | StorageFacility 파생 | 판매 요청 아이템을 모으는 출력공간 (AD-2 맵 시설) | FR-30, A-07 |
| `ItemListPanel` | UI (Control) | 들고 있는 아이템 목록 상시 표시, 드래그 원본 | FR-02 |
| `ShelfPanel` | UI (Control) | 선반 열림 상태, 칸 목록, X 버튼 닫기 | FR-03 |
| `RequestPanel` | UI (Control) | 요청 아이템, 제한 시간, 누적 실패 표시 | FR-20, FR-21 |
| `HUD` | UI (Control) | 1280x720 기준 던전 번호, 골드, 레벨 · EXP, 운반 아이템 | FR-27, FR-28 |
| `BattleView` | 연출 (Control) | 전투 연출, 전투 번호, 아이템 쏟아짐 연출 | FR-12 |
| `SleepOverlay` | 연출 (Control) | 30초 수면 연출, 남은 시간 | FR-14 |
| `ShopView` | 연출 (Control) | 판매 요청 표시, 구매 목록, 구매 결과 | FR-16 |
| `AugmentSelection` | UI (Control) | 레벨업 증강 3택 등 선택 화면 | FR-11 |
| `GameOverScreen` | UI (Control) | 누적 실패 3회 게임오버 화면 | FR-21 |
| `SaveTransferPanel` | UI (Control) | 세이브 내보내기 · 불러오기 버튼 (웹) | FR-26 |

---

## 4. 리소스 · 데이터 (Data)

| 리소스 | 형식 | 내용 | 관련 요구사항 |
| --- | --- | --- | --- |
| `ItemData` | `.tres` (Resource) | 아이템 종류 고정 정보 (무게, 판매가, EXP, 허용 시설) | FR-06, FR-08, NFR-05 |
| `FacilityData` | `.tres` (Resource) | 시설 종류, 허용 카테고리, 최대 무게, 구매 비용 | FR-06, FR-24 |
| `DungeonTable` | JSON | 던전별 전투 횟수 (3~5), 신규 아이템 수, 수면 시간 (30초) | FR-12, FR-14 |
| `ShopTable` | JSON | 구매 품목 가중치, 수량 범위 | FR-18 |
| `AugmentTable` | JSON | 증강 목록, 중복 제한 설정 | FR-11 |

데이터 파일은 AD-9 (B) 에 따라 암호화 대상이다. 웹에서 지원되지 않으면 평문으로 두고 이 문서를 갱신한다 (검증 항목 V-1).

---

## 5. 보안 · 저장 경계 (AD-8 + AD-9)

| 대상 | 보호 방식 | 한계 |
| --- | --- | --- |
| 세이브 (JSON) | HMAC-SHA256 서명. 불러올 때 서명 불일치면 거부 | 서명 키가 클라이언트에 있으므로 숙련자는 우회 가능 |
| 내보내기 파일 | 세이브와 동일 (같은 JSON + 서명) | 동일 |
| 데이터 파일 | Godot 내보내기 암호화 (웹 지원 여부 검증 필요) | 브라우저에서 실행되므로 완전 차단 불가 |

이 보호는 "쉽게 고치지 못하게" 하는 수준이다. 완전한 치트 방지를 보장하지 않는다.
