# Unit of Work 계획 (Units Generation Plan)

**기준**: `application-design/application-design.md` (컴포넌트 · 서비스 · 요구사항 매핑), `plans/execution-plan.md` (잠정 U1~U5)
**참고**: 사용자 스토리가 없으므로 unit 매핑은 FR-01~31 기준으로 한다 (UG-6 확인)

이 계획은 시스템을 unit 으로 나누기 전에 결정할 항목을 정리한 것입니다. 각 질문의 `[Answer]:` 뒤에 선택지 문자를 적어 주세요. 맞는 선택지가 없으면 `X) Other` 를 고르고 내용을 함께 적어 주세요. 모든 답변이 끝나면 알려 주세요.

**생성 예정 산출물 (답변 후)**
- `aidlc-docs/inception/application-design/unit-of-work.md`: unit 정의, 책임, 코드 구성 전략
- `aidlc-docs/inception/application-design/unit-of-work-dependency.md`: unit 간 의존성 매트릭스
- `aidlc-docs/inception/application-design/unit-of-work-story-map.md`: FR → unit 매핑 (스토리 대신)

---

## 잠정 unit (execution-plan.md 기준)

| 잠정 Unit | 범위 |
| --- | --- |
| U1 창고 · 조작 | 이동, 아이템 목록, 선반 패널, 맵 드롭, 바닥 줍기, 무게 적재 |
| U2 성장 · 경제 | EXP, 증강, 골드, 판매 · 구매 계산, 시설 구매 |
| U3 던전 · 요청 | 던전 흐름 상태 머신, 30초 수면, 완료 판정, 미정리 누적, 긴급 요청, 게임오버 |
| U4 상점 | 상점 방문 흐름, 판매 요청 · 출력공간, 구매 · 입력공간 무작위 입고, 대량 상자 |
| U5 저장 · 플랫폼 | 자동 저장, 세이브 서명, 웹 내보내기 · 불러오기, 해상도, 한국어 UI, 웹 빌드 설정 |

---

## Question UG-1
Godot 프로젝트 안에서 unit 을 어떻게 나눌까요? (Greenfield 코드 구성)

A) 한 Godot 프로젝트 안에서 폴더 단위 모듈 (`scripts/items/`, `scripts/dungeon/` 등). unit 은 폴더 묶음

B) 기능별 Godot 플러그인 (`addons/`) 으로 분리. 각 unit 이 독립 플러그인

C) unit 마다 별도 씬 폴더 (`scenes/u1_storage/` 등) 와 스크립트 폴더를 함께 둠

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question UG-2
unit 개수를 몇 개로 나눌까요?

A) 잠정 5개 그대로 (U1 창고 · 조작, U2 성장 · 경제, U3 던전 · 요청, U4 상점, U5 저장 · 플랫폼)

B) 3개로 묶음: 코어 (U1 + U2), 진행 (U3 + U4), 플랫폼 (U5)

C) 7개로 세분화: U1 을 입력공간 · 출력공간으로 분리, U3 를 요청 · 던전 흐름으로 분리

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question UG-3
unit 의 구현 순서를 어떻게 할까요?

A) 순차 진행: U1 → U2 → U3 → U4 → U5 (기존 MVP 순서)

B) 수직 슬라이스: 튜토리얼 (아이템 10개) 을 먼저 끝까지 연결한 뒤, 던전 1 → 상점 → 저장 순으로 얇게 확장

C) 순차 진행하되 U5 (저장 · 플랫폼) 를 U3 과 같은 단계에서 병행

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question UG-4
Functional Design (unit 별 상세 비즈니스 규칙) 을 어느 unit 에 적용할까요?

A) 규칙이 복잡한 unit 만: U1 (무게 적재, 줍기), U3 (던전 흐름, 완료, 요청), U4 (상점 구매 · 판매)

B) 모든 unit 에 적용

C) 적용하지 않음 (Code Generation 에서 바로 설계 포함)

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question UG-5 (V-3 확인): 입력공간이 가득 찬 상태에서 구매하면 어떻게 할까요?

Application Design 의 V-3 항목입니다. 입력공간 용량은 설계 단계에서 정하지만, 가득 찼을 때 처리 방식은 아직 정해지지 않았습니다.

A) 구매 전에 입력공간 여유를 확인하고, 공간이 부족하면 구매 자체를 막음

B) 구매는 허용하고, 자리가 없는 구매품은 다음 던전 신규 목록으로 넘김

C) 구매는 허용하고, 자리가 없는 구매품은 출력공간으로 자동 이동 (플레이어가 처리)

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question UG-6 (스토리 대체): 사용자 스토리 없이 unit 을 나눌까요?

현재 User Stories 는 건너뛰었습니다. unit 매핑은 FR-01~31 기준으로 진행하려고 합니다.

A) FR 기준으로 진행 (User Stories 는 건너뛰기 유지)

B) 지금 User Stories stage 를 추가로 실행한 뒤 스토리 기준으로 unit 을 나눔

X) Other (please describe after [Answer]: tag below)

[Answer]: B (사용자 답변: User Stories 추가. Units Generation 은 User Stories 완료 후 재개, 스토리 기준으로 unit 을 나눔)

---

## 확인 완료 (질문 없음)

- unit 은 Godot 프로젝트 안에서 나눈다 (단일 저장소, 단일 프로젝트)
- 공통 자원 (오토로드 4개, 순수 클래스 8개) 은 특정 unit 에 귀속되며, 다른 unit 은 인터페이스만 사용한다
- 웹 · 데스크톱 빌드는 U5 에서 설정하고, 나머지 unit 은 두 빌드 모두에서 동작해야 한다 (NFR-06, NFR-08)
- PBT 대상 순수 클래스는 해당 unit 의 테스트 산출물에 포함한다 (NFR-09)
