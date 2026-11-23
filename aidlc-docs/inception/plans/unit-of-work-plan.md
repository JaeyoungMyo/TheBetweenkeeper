# Unit of Work 계획 (Units Generation Plan)

**기준**: `application-design/application-design.md`, `user-stories/stories.md` (US-01~22, SYS-01~04), `requirements/requirements.md`
**답변 상태**: UG-1 ~ UG-6 모두 확정 (사용자 "모두 추천대로 진행" 응답)

---

## Question UG-1: Godot 프로젝트 안에서 unit 을 어떻게 나눌까요?

A) 한 Godot 프로젝트 안에서 폴더 단위 모듈 (`scripts/items/`, `scripts/dungeon/` 등). unit 은 폴더 묶음

B) 기능별 Godot 플러그인 (`addons/`) 으로 분리. 각 unit 이 독립 플러그인

C) unit 마다 별도 씬 폴더 (`scenes/u1_storage/` 등) 와 스크립트 폴더를 함께 둠

X) Other (please describe after [Answer]: tag below)

[Answer]: A (추천안 확정)

---

## Question UG-2: unit 개수를 몇 개로 나눌까요?

A) 잠정 5개 그대로 (U1 창고 · 조작, U2 성장 · 경제, U3 던전 · 요청, U4 상점, U5 저장 · 플랫폼)

B) 3개로 묶음: 코어 (U1 + U2), 진행 (U3 + U4), 플랫폼 (U5)

C) 7개로 세분화: U1 을 입력공간 · 출력공간으로 분리, U3 를 요청 · 던전 흐름으로 분리

X) Other (please describe after [Answer]: tag below)

[Answer]: A (추천안 확정)

---

## Question UG-3: unit 의 구현 순서를 어떻게 할까요?

A) 순차 진행: U1 → U2 → U3 → U4 → U5 (기존 MVP 순서)

B) 수직 슬라이스: 튜토리얼 (아이템 10개) 을 먼저 끝까지 연결한 뒤, 던전 1 → 상점 → 저장 순으로 얇게 확장

C) 순차 진행하되 U5 (저장 · 플랫폼) 를 U3 과 같은 단계에서 병행

X) Other (please describe after [Answer]: tag below)

[Answer]: B (추천안 확정)

---

## Question UG-4: Functional Design (unit 별 상세 비즈니스 규칙) 을 어느 unit 에 적용할까요?

A) 규칙이 복잡한 unit 만: U1 (무게 적재, 줍기), U3 (던전 흐름, 완료, 요청), U4 (상점 구매 · 판매)

B) 모든 unit 에 적용

C) 적용하지 않음 (Code Generation 에서 바로 설계 포함)

X) Other (please describe after [Answer]: tag below)

[Answer]: A (추천안 확정)

---

## Question UG-5 (V-3 확인): 입력공간이 가득 찬 상태에서 구매하면 어떻게 할까요?

A) 구매 전에 입력공간 여유를 확인하고, 공간이 부족하면 구매 자체를 막음

B) 구매는 허용하고, 자리가 없는 구매품은 다음 던전 신규 목록으로 넘김

C) 구매는 허용하고, 자리가 없는 구매품은 출력공간으로 자동 이동 (플레이어가 처리)

X) Other (please describe after [Answer]: tag below)

[Answer]: A (추천안 확정)

---

## Question UG-6 (스토리 대체): 사용자 스토리 없이 unit 을 나눌까요?

A) FR 기준으로 진행 (User Stories 는 건너뛰기 유지)

B) 지금 User Stories stage 를 추가로 실행한 뒤 스토리 기준으로 unit 을 나눔

X) Other (please describe after [Answer]: tag below)

[Answer]: B (사용자 답변: User Stories 추가. 스토리 승인 완료, 스토리 기준으로 진행)

---

## 확정 사항 요약

- Godot 프로젝트 안 폴더 단위 모듈 (UG-1 A)
- unit 5개: U1 ~ U5 (UG-2 A)
- 구현 순서: 튜토리얼 수직 슬라이스 → 던전 1 → 상점 → 저장 · 플랫폼 (UG-3 B)
- Functional Design: U1, U3, U4 에 적용 (UG-4 A)
- 입력공간 가득 참: 구매 전에 여유를 확인하고 부족하면 구매를 막음 (UG-5 A, V-3 해소)
- 매핑 기준: 사용자 스토리 (US-01~22, SYS-01~04) 26개 (UG-6 B)
