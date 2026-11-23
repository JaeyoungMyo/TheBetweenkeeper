# 애플리케이션 설계 통합 문서 (Application Design)

**입력 문서**: `components.md`, `component-methods.md`, `services.md`, `component-dependency.md`
**기준**: `requirements.md`, `application-design-plan.md` (AD-1~AD-9 답변)

## 1. 설계 요약

- **엔진**: Godot 4.7.2, Compatibility 렌더러, 1280x720 고정, 웹 + 데스크톱 빌드
- **오토로드 4개**: GameManager (상태 · 저장), DungeonManager (던전 흐름 · 요청 · 상점), ItemManager (아이템 · 공간 · 무게), EconomyManager (골드 · EXP · 판매 · 구매)
- **순수 클래스 8개**: 계산 로직을 노드 없이 두어 PBT 가능 (NFR-09)
- **통신**: 시그널 중심 (AD-4). 상위 → 하위는 메서드 호출, 하위 → 상위는 시그널
- **던전 흐름**: 명시적 상태 머신 `DungeonFlow` (IDLE → BATTLE → DUNGEON_CLEAR → SLEEP → SHOP → NEXT_DUNGEON)
- **긴급 요청**: `RequestController` 가 `_process` 에서 제한 시간 누적 (AD-6). DungeonManager 소속 (AD-1 B)
- **데이터**: 아이템 · 시설은 `.tres`, 던전 · 상점 · 증강 표는 JSON (AD-7 C)
- **세이브**: JSON + HMAC-SHA256 서명 (AD-8 A, AD-9 B). 데이터 파일은 암호화 (AD-9 B, 웹 지원은 검증 V-1)

## 2. 요구사항 → 컴포넌트 매핑

| 요구사항 | 담당 컴포넌트 | 서비스 |
| --- | --- | --- |
| FR-01 이동 · 충돌 | Player, StorageRoom | - |
| FR-02 아이템 목록 상시 표시 | ItemListPanel | - |
| FR-03 선반 패널 적재 | StorageFacility, ShelfPanel, ItemManager | StorageService |
| FR-04 맵 드롭 (버리기) | ItemManager, Player | StorageService |
| FR-05 바닥 줍기 (호버 후 클릭, 키보드) | Item, Player, ItemManager | StorageService |
| FR-06 시설 최대 무게 | WeightRules, StorageFacility | StorageService |
| FR-07 무게 초과 낙하 · 메시지 | ItemManager, HUD | StorageService |
| FR-08 무게에 따른 이동 속도 | WeightRules, Player | - |
| FR-09 아이템 상태 | ItemManager | - |
| FR-10 수납 EXP (중복 방지) | EconomyManager (ExpCalculator) | ProgressionService |
| FR-11 레벨업 증강 | EconomyManager (AugmentPool), AugmentSelection | ProgressionService |
| FR-12 던전 전투 3~5회 | DungeonManager (DungeonFlow) | DungeonFlowService |
| FR-13 완료 판정 (정리 무관) | DungeonManager | DungeonFlowService |
| FR-14 30초 수면 | DungeonManager, SleepOverlay | DungeonFlowService |
| FR-15 미정리 누적 | ItemManager | DungeonFlowService |
| FR-16 상점 방문 (판매 · 구매) | DungeonManager (ShopFlow), EconomyManager | ShopService |
| FR-17 던전마다 상점 | DungeonFlow | DungeonFlowService |
| FR-18 가중치 구매 | EconomyManager (PurchaseRoller) | ShopService |
| FR-19 구매 골드 차감 · 실패 | EconomyManager (GoldLedger) | ShopService |
| FR-20 긴급 요청 (전투 중) | DungeonManager (RequestController), RequestPanel | RequestService |
| FR-21 누적 실패 3회 게임오버 | DungeonManager (RequestRules), GameManager | RequestService |
| FR-22 요청 성공 보상 | EconomyManager | RequestService |
| FR-23 판매 · 예약 보호 | EconomyManager, ItemManager | ShopService |
| FR-24 시설 구매 · 확장 | EconomyManager, StorageFacility | - |
| FR-25 던전 완료 자동 저장 | GameManager (SaveService), SaveCodec | SaveService |
| FR-26 웹 내보내기 · 불러오기 | SaveTransferPanel, SaveCodec | SaveService |
| FR-27 1280x720 고정 | Main, HUD | - |
| FR-28 한국어 UI | 모든 UI 노드 (번역 리소스) | - |
| FR-29 튜토리얼 아이템 10개 | DungeonTable (튜토리얼 항목) | DungeonFlowService |
| FR-30 판매 요청 → 출력공간 | OutputSpace, ItemManager, DungeonManager | ShopService |
| FR-31 구매품 입력공간 무작위 입고 | InputSpace, ItemManager (PlacementRules) | ShopService |

## 3. 비기능 요구사항 대응

| NFR | 설계 대응 |
| --- | --- |
| NFR-01 60 FPS | 순수 로직과 씬 분리, 무거운 계산 없음 (검증은 Performance Validation) |
| NFR-02 웹 로딩 · 입력 지연 | Compatibility 렌더러, 스레드 미사용, 데이터 로딩을 시작 시 1회 |
| NFR-03 저장 무결성 | SaveCodec 왕복 테스트, 복원 후 아이템 수 · 상태 비교 |
| NFR-04 골드 단일 원본 | GoldLedger 를 EconomyManager 가 소유, 외부 직접 대입 금지 |
| NFR-05 데이터 분리 | ItemData (종류) 와 ItemInstance (개체) 분리 |
| NFR-06 itch.io zip | 웹 Export 결과 `index.html` 포함 (Build 단계에서 검증) |
| NFR-07 스레드 미사용 | Export 설정 (Build 단계) |
| NFR-08 Compatibility | 프로젝트 렌더러 설정 |
| NFR-09 PBT | 순수 클래스 8개를 PBT 대상으로 지정 |

## 4. 주요 설계 결정 (ADR 요약)

| 결정 | 이유 | 출처 |
| --- | --- | --- |
| 오토로드 4개로 통합 | 기획서 8개는 책임이 겹침. 전역 접근이 필요한 것만 전역으로 둠 | AD-1 (B) |
| 입력 · 출력공간을 맵 시설로 구현 | 플레이어가 옮기는 행동이 정리 시뮬레이션의 핵심 재미 (기획서 1.3) | AD-2 (A) |
| 계산을 순수 클래스로 분리 | 씬 없이 PBT 가능, 무게와 골드 회귀 방지 | AD-3 (A), NFR-09 |
| 시그널 중심 통신 | 노드 간 결합 낮춤, 연출 노드를 나중에 바꾸기 쉬움 | AD-4 (A) |
| 던전 흐름 상태 머신 | 완료, 수면, 상점 순서가 중요. 순서 버그를 한 곳에서 막음 | AD-5 (A) |
| 요청 타이머는 `_process` 누적 | 일시정지 · 연출 중 정지를 쉽게 처리 | AD-6 (A) |
| 데이터는 `.tres` + JSON 혼합 | 아이템은 에디터 편집, 표는 텍스트로 빠르게 조정 | AD-7 (C) |
| 세이브 JSON + HMAC 서명 | 값 변조를 감지. 완전 차단은 불가 (웹 특성) | AD-8 (A), AD-9 (B) |
| 요청 소속을 DungeonManager 로 | 요청은 던전 흐름에 묶인 기능. 오토로드 수를 줄임 | AD-1 (B), AD-6 조정 |

## 5. 위험과 확인 항목

| ID | 항목 | 영향 | 처리 시점 |
| --- | --- | --- | --- |
| V-1 | 웹에서 데이터 파일 암호화 지원 여부 | 미지원 시 데이터 평문 | Build 단계 |
| V-2 | 웹 세이브 파일 다운로드 구현 (`JavaScriptBridge`) | 내보내기 기능 | Functional Design (SaveService) |
| V-3 | 입력공간이 가득 찬 상태의 구매 처리 (A-07) | 구매 흐름 | 사용자 확인 필요 |
| V-4 | HMAC 키 보관 방식 (빌드 시 주입) | 세이브 보호 수준 | Code Generation |

## 6. 다음 단계

- Units Generation 에서 이 설계를 기준으로 unit 을 나눈다 (잠정 U1~U5, execution-plan.md)
- V-3 은 사용자 확인이 필요하다. Units Generation 전에 답을 받는 것을 권장한다
