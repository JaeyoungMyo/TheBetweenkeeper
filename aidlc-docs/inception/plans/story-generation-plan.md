# 스토리 생성 계획 (Story Generation Plan)

**기준**: `requirements/requirements.md` (FR-01~31, NFR-01~09, D-01~18, 가정 A-01~A-07), `plans/user-stories-assessment.md`

이 계획은 스토리를 만들기 전에 결정할 항목을 정리한 것입니다. 각 질문의 `[Answer]:` 뒤에 선택지 문자를 적어 주세요. 맞는 선택지가 없으면 `X) Other` 를 고르고 내용을 함께 적어 주세요. 모든 답변이 끝나면 알려 주세요.

**생성 예정 산출물 (답변 후)**
- `aidlc-docs/inception/user-stories/stories.md`: INVEST 기준 스토리와 인수 조건
- `aidlc-docs/inception/user-stories/personas.md`: 플레이어 유형과 특성, 스토리 매핑

---

## Question US-1: 플레이어 persona 를 몇 명으로 나눌까요?

A) 1명: 아공간을 정리하는 플레이어 한 명

B) 2명: 정리 중심 플레이어 (수납 · 배치를 즐김) 와 긴급 요청 중심 플레이어 (용사 요청 대응을 즐김)

C) 3명 이상: 신규 플레이어 (튜토리얼 중심), 숙련 플레이어 (효율 최적화), 캐주얼 플레이어 (짧은 세션)

X) Other (please describe after [Answer]: tag below)

[Answer]: 2명: 아공간 정리 플레이어 / 신규 플레이어(튜토리얼 중심)

---

## Question US-2: 스토리를 어떤 방식으로 나눌까요?

A) 사용자 여정 기반: 튜토리얼 → 정리 → 성장 → 던전 → 요청 → 상점 → 저장 순서의 플레이 흐름을 따름

B) 기능 기반: FR 묶음 (조작, 아이템, 성장, 경제, 던전, 상점, 저장) 으로 구성

C) Epic 기반: 큰 epic (예: 정리 시스템, 던전 루프, 상점 루프) 아래에 세부 스토리를 둠

D) 혼합: epic 으로 묶되 각 epic 안은 사용자 여정 순서로 배치

X) Other (please describe after [Answer]: tag below)

[Answer]: 추천

---

## Question US-3: 스토리 문장 형식은 무엇으로 할까요?

A) 표준 형식: "[persona] 로서, [행동] 을 하고 싶다. [이유] 를 위해서"

B) 한국어 간단 형식: "[persona] 는 [행동] 을 할 수 있다" 로 짧게 씀

C) 문장 형식 없이 제목과 인수 조건만 씀

X) Other (please describe after [Answer]: tag below)

[Answer]: 추천

---

## Question US-4: 인수 조건은 어떤 형식으로 쓸까요?

A) Given / When / Then (전제, 행동, 결과)

B) 체크리스트 (확인할 항목을 나열)

C) 자연어 문장 (조건을 문장으로 설명)

D) Given/When/Then 을 기본으로 하고, 단순 항목은 체크리스트로 씀

X) Other (please describe after [Answer]: tag below)

[Answer]: 추천

---

## Question US-5: 어느 범위까지 스토리로 만들까요?

A) 전체: FR-01~31 전부를 스토리로 만든다

B) MVP 우선: 정리 · 성장 (FR-01~11) 을 먼저 만들고, 경제 · 던전 · 상점 · 저장은 2차로 미룸

C) 튜토리얼 + 던전 1 까지: 아이템 10개 튜토리얼과 던전 1 흐름만 스토리로 만든다

X) Other (please describe after [Answer]: tag below)

[Answer]: 추천

---

## Question US-6: 스토리의 세분화 수준은 어느 정도로 할까요?

A) 큰 단위 (약 10개 내외). 한 스토리에 하나의 플레이 흐름

B) 중간 단위 (약 20~30개). 한 스토리에 하나의 행동

C) 세부 단위 (약 50개 이상). 한 스토리에 하나의 조작 또는 확인 항목

X) Other (please describe after [Answer]: tag below)

[Answer]: 추천

---

## Question US-7: 플레이어가 아닌 시스템 관점의 스토리도 넣을까요?

예: 자동 저장, 세이브 서명 검증, 웹 내보내기 · 불러오기, 게임오버 처리

A) 플레이어 관점 스토리만 만든다. 시스템 동작은 인수 조건 안에 넣는다

B) 시스템 관점 스토리를 별도로 만든다 (저장, 내보내기, 게임오버 등)

C) 플레이어 관점 스토리를 기본으로 하고, 저장 · 배포 관련만 별도 시스템 스토리로 만든다

X) Other (please describe after [Answer]: tag below)

[Answer]: 추천

---

## 확인 완료 (질문 없음)

- 스토리 언어는 한국어로 쓴다 (CLAUDE.md, 한국어 규칙)
- 스토리 ID 는 `US-01`, `AC-01-1` 형식을 쓴다 (traceability-check 와 맞춤)
- 스토리는 requirements.md 의 FR ID 와 연결한다
- 실행 시점은 Workflow Planning 에서 정한 흐름을 따르고, 이후 Units Generation 의 근거로 쓴다
