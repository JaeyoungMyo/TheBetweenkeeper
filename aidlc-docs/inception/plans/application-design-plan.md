# Application Design 계획 (Application Design Plan)

**기준 문서**: `aidlc-docs/inception/requirements/requirements.md` (FR-01~31, NFR-01~09, D-01~18), `aidlc-docs/inception/plans/execution-plan.md`

**답변 상태**: AD-1 ~ AD-6 확정. AD-7 · AD-8 은 "웹에서 해킹할 수 없게" 조건이 있어 AD-9 로 후속 확인합니다.

**설계 산출물 (생성 예정)**
- `aidlc-docs/inception/application-design/components.md`: 컴포넌트 이름, 목적, 책임
- `aidlc-docs/inception/application-design/component-methods.md`: 메서드 시그니처, 입출력 타입
- `aidlc-docs/inception/application-design/services.md`: 서비스 정의, 오케스트레이션
- `aidlc-docs/inception/application-design/component-dependency.md`: 의존성 매트릭스, 데이터 흐름
- `aidlc-docs/inception/application-design/application-design.md`: 위 문서 통합

---

## Question AD-1
오토로드(전역 매니저)를 어떻게 구성할까요? 기획서 12.2는 8개(GameManager, DungeonManager, ItemManager, GoldManager, ExpManager, RequestManager, ShopManager, SaveManager)를 제시합니다.

A) 기획서 8개 그대로 사용

B) 4개로 통합: GameManager(상태, 저장), DungeonManager(던전 흐름, 요청, 상점 흐름), ItemManager(아이템, 무게, 입력·출력 공간), EconomyManager(골드, EXP, 판매, 구매)

C) 최소 구성: 오토로드는 GameManager 1개만 두고, 나머지는 씬 노드로 둠

X) Other (please describe after [Answer]: tag below)

[Answer]: B (사용자 "추천" 응답 → 추천안 B 채택)

---

## Question AD-2
입력공간과 출력공간(D-18)은 어떤 형태로 구현할까요?

A) 맵 위의 실제 시설 (플레이어가 걸어가서 아이템을 옮김)

B) UI 패널 전용 (맵 밖 화면에서만 옮김, 걸어갈 필요 없음)

C) 맵 위 시설과 UI 패널 둘 다 사용 (걸어가서 옮기거나, 패널에서 옮기거나 선택 가능)

X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question AD-3
무게 계산, 적재 가능 여부, 증강 중복 제한, 골드 계산 같은 순수 로직을 어디에 둘까요? (NFR-09 PBT 대상)

A) 노드가 없는 순수 GDScript 클래스 (씬 없이 단위 테스트 가능)

B) 각 씬 노드(StorageFacility 등)의 스크립트 안

C) A 와 B 를 섞음 (계산은 A, 씬 연결은 B)

X) Other (please describe after [Answer]: tag below)

[Answer]: A (사용자 "추천" 응답 → 추천안 A 채택)

---

## Question AD-4
매니저끼리 통신하는 방식은 무엇으로 할까요?

A) Godot 시그널 중심 (발신자가 시그널을 내고 수신자가 구독)

B) 직접 메서드 호출 (매니저가 다른 매니저 메서드를 직접 호출)

C) 중앙 이벤트 버스 autoload 하나를 두고 모든 이벤트를 거기로 보냄

X) Other (please describe after [Answer]: tag below)

[Answer]: A (사용자 "추천" 응답 → 추천안 A 채택)

---

## Question AD-5
던전 흐름 (전투 3~5회, 완료, 30초 수면, 상점 방문, 다음 던전) 은 어떤 방식으로 관리할까요?

A) 명시적 상태 머신 (IDLE → BATTLE → DUNGEON_CLEAR → SLEEP → SHOP → NEXT_DUNGEON), 상태 전환은 한 곳에서만

B) 코루틴 (await 로 순서대로 실행하는 함수 하나)

C) 상태 머신과 코루틴 혼합 (상태는 상태 머신, 연출 대기는 코루틴)

X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question AD-6
긴급 요청의 제한 시간은 어디에서 셀까요?

A) RequestManager 가 `_process` 에서 시간을 누적 (일시정지 상태 반영이 쉬움)

B) 요청마다 Godot Timer 노드를 생성

C) 전투 상태 머신의 틱에 맞춰 셈 (DungeonManager 가 관리)

X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question AD-7
아이템과 시설 데이터는 어떤 형식으로 저장할까요? (기획서는 `ItemData` Resource 와 `data/` 폴더를 제시)

A) Godot Resource (.tres) 파일 사용, 에디터에서 편집

B) JSON 파일 사용 (텍스트 편집 쉬움, 테스트에서 직접 읽기 쉬움)

C) A 와 B 를 섞음 (아이템은 .tres, 던전 난이도 표는 JSON)

X) Other (please describe after [Answer]: tag below)

[Answer]: C (사용자 "추천" 응답 → 추천안 C 채택). 웹 보호 방식은 AD-9 에서 확인

---

## Question AD-8
저장 파일(세이브) 형식은 무엇으로 할까요? (D-03 웹 내보내기와 연결)

A) JSON 텍스트 (내보내기 파일도 같은 JSON, 사람이 읽을 수 있음)

B) Godot 바이너리 Resource (.res)

C) JSON 을 base64 로 감싼 파일 (내보내기 파일이 짧고 손대기 어려움)

X) Other (please describe after [Answer]: tag below)

[Answer]: A (사용자 "추천" 응답 → 추천안 A 채택). 웹 보호 방식은 AD-9 에서 확인

---

## Question AD-9 (후속 질문): 웹에서 데이터와 세이브를 어느 수준으로 보호할까요?

AD-7, AD-8 답변에 "웹상에서 해킹할 수 없게"라는 조건이 있었습니다. 다만 웹 빌드는 플레이어 브라우저에서 실행되므로, 데이터와 세이브를 **완전히 막을 수는 없습니다**. 다음 중 보호 수준을 골라 주세요.

**세이브 (AD-8 관련)**

A) 평문 JSON (보호 없음, 가장 단순하고 디버깅이 쉬움)

B) JSON + 서명(HMAC) 검사: 값을 고치면 불러올 때 거부. 서명 키가 클라이언트에 있어 숙련자는 우회 가능

C) JSON 을 암호화 + 서명: 쉽게 읽거나 고치기 어렵게 함. 구현이 가장 복잡하고, 키는 여전히 클라이언트에 있음

X) Other (please describe after [Answer]: tag below)

[Answer]: B

**데이터 파일 (AD-7 관련)**

A) 평문 유지 (밸런스 데이터는 공개되어도 문제없음)

B) 데이터 파일 암호화 (Godot 내보내기 암호화 사용. 웹 빌드에서 지원되는지는 설계 단계에서 확인 필요)

X) Other (please describe after [Answer]: tag below)

[Answer]: B

---

## 확인 완료 (질문 없음)

- 오토로드 · 씬 구조: 기획서 12장과 12.1 (Main, StorageRoom, Player, Item, StorageFacility) 을 기준으로 함. AD-1 에서 오토로드는 4개로 통합 (B)
- 상점 흐름: 던전 완료 → 30초 수면 → 판매(출력공간) · 구매(입력공간 무작위 입고), D-18 기준
- 입력 · 출력공간: 맵 위 실제 시설 (AD-2 A)
- 웹 빌드: Compatibility 렌더러, 스레드 미사용 (D-02, NFR-07, NFR-08)
- 해상도: 1280x720 고정 (D-10)
