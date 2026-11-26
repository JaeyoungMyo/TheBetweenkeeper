# U3 던전 · 요청 기능 설계 계획 (Functional Design Plan)

**unit**: U3 던전 · 요청 (Dungeon & Requests)
**기준**: `inception/application-design/unit-of-work.md` (U3 정의), `unit-of-work-story-map.md`, `user-stories/stories.md` (US-11 ~ US-17), `requirements/requirements.md` (FR-12 ~ FR-15, FR-20 ~ FR-23, D-04, D-06, D-14, D-15), 기획서 2.2 · 2.3 · 7 · 8.2 절

이 계획은 U3 의 비즈니스 규칙 중 명확하지 않은 부분을 정리한 것입니다. 각 질문의 `[Answer]:` 뒤에 선택지 문자를 적어 주세요. 맞는 선택지가 없으면 `X) Other` 를 고르고 내용을 함께 적어 주세요. 추천안이 있는 질문은 "추천" 으로 표시했습니다. 추천을 그대로 쓰면 "추천" 이라고 적어 주셔도 됩니다.

**생성 예정 산출물 (답변 후)**
- `aidlc-docs/construction/u3-dungeon-requests/functional-design/business-logic-model.md`
- `aidlc-docs/construction/u3-dungeon-requests/functional-design/business-rules.md`
- `aidlc-docs/construction/u3-dungeon-requests/functional-design/domain-entities.md`

**참고**: U3 는 UI 컴포넌트 (BattleView, SleepOverlay, RequestPanel, GameOverScreen) 를 포함하므로 `frontend-components.md` 도 생성 대상입니다. 화면 구성은 그 단계에서 다룹니다. 여기서는 상태 · 규칙 · 수치 위주로 묻습니다.

---

## Question FD-U3-1: 던전 1개의 전투 횟수 결정 방식
던전마다 전투 횟수 (3~5회) 를 어떻게 정할까요? (US-11, FR-12)

A) 던전 시작 때 3~5 사이 무작위로 정함. 추천

B) 던전 번호별 고정값 테이블 (데이터 파일에 둠)

C) 항상 4회 고정 (MVP 단순화)

X) Other (please describe after [Answer]: tag below)

[Answer]: A (추천 전부 채택)

---

## Question FD-U3-2: 전투마다 입고되는 아이템 수
던전 1 의 신규 아이템 10개 (기획서 8.2) 를 전투 몇 번에 걸쳐 나눠 넣을까요? (US-11 AC-11-2)

A) 전투마다 균등 배분 (던전 총량 ÷ 전투 횟수, 나머지는 마지막 전투). 추천

B) 전투마다 무작위 개수, 던전 총량은 맞춤

C) 전투마다 고정 개수 (예: 던전 1 은 항상 3 · 3 · 4)

X) Other (please describe after [Answer]: tag below)

[Answer]: A (추천 전부 채택)

---

## Question FD-U3-3: 전투 · 던전 1 의 수치를 어디에 둘지
던전별 신규 아이템 수, 종류 수, 요청 수, 전투 횟수 같은 수치를 어디서 관리할까요? (기획서 8.2, 8.1)

A) 던전 테이블 데이터 파일 (`DungeonTable`, JSON). 추천

B) 코드 상수

C) 던전 1 값만 먼저 두고, 던전 2 이후 값은 U3 범위 밖으로 둠

X) Other (please describe after [Answer]: tag below)

[Answer]: A (추천 전부 채택)

---

## Question FD-U3-4: 요청 발생 시점과 빈도
긴급 요청은 던전 안에서 언제, 몇 번 생길까요? (FR-20, 기획서 8.2 "예상 요청 수")

A) 던전당 요청 수를 정하고, 그 수만큼 전투 중 무작위 시점에 발생. 추천

B) 전투 시작 때마다 일정 확률로 발생

C) 던전당 요청 수 고정, 전투 시작 직후 발생

X) Other (please describe after [Answer]: tag below)

[Answer]: A (추천 전부 채택)

---

## Question FD-U3-5: 요청 아이템이 창고에 없을 때 (AC-15-3)
요청 생성 시 요청할 아이템이 창고에 없으면 어떻게 할까요? (기획서 7.3)

A) 요청 생성 후보에서 제외하고, 후보가 없으면 그 요청은 만들지 않음. 추천

B) 요청은 만들되 "찾을 수 없음" 으로 즉시 실패 처리 (실패 누적 1 증가)

C) 요청은 만들되 보상 없이 취소 (실패 누적 없음)

X) Other (please describe after [Answer]: tag below)

[Answer]: A (추천 전부 채택)

---

## Question FD-U3-6: 요청 제한 시간
요청 1건의 제한 시간은 얼마로 할까요? (FR-20, 기획서 7.2)

A) 고정 값을 설정 데이터에 둠 (초기값 30초). 추천

B) 요청 종류 · 던전 번호별로 다르게 설정

C) 전투 길이에 맞춰 전투 종료 시점까지로 설정 (제한 시간 없음에 가까움)

X) Other (please describe after [Answer]: tag below)

[Answer]: A (추천 전부 채택)

---

## Question FD-U3-7: 요청 중 아이템 예약 해제 시점 (AC-17-2)
요청 대상 아이템의 `reserved` 상태는 언제 풀릴까요? (FR-23, 기획서 7.3)

A) 성공 · 실패 · 제한 시간 만료 중 어느 경우든 해제. 추천

B) 성공 시에만 아이템을 소비 처리하고, 실패 · 만료 시 해제

C) 요청 종료 후 던전 완료 시점까지 유지

X) Other (please describe after [Answer]: tag below)

[Answer]: A (추천 전부 채택)

---

## Question FD-U3-8: 동시 요청 허용 여부
한 시점에 요청이 여러 건 떠 있을 수 있을까요? (FR-20)

A) 한 번에 1건만. 새 요청은 현재 요청이 끝난 뒤 발생. 추천

B) 여러 건 동시 허용 (던전당 요청 수와 별개로 관리)

X) Other (please describe after [Answer]: tag below)

[Answer]: A (추천 전부 채택)

---

## Question FD-U3-9: 요청 실패 판정과 실패 누적 (AC-16-1, AC-16-3)
요청 실패는 언제 확정되고, 어떻게 누적될까요? (FR-21, D-06)

A) 제한 시간이 끝나는 순간 실패 확정, 누적 수 +1. 추천

B) 던전 완료 시점에 미전달 요청을 일괄 실패 처리

C) 요청 종류별로 누적 수를 따로 셈 (3회는 종류마다)

X) Other (please describe after [Answer]: tag below)

[Answer]: A (추천 전부 채택)

---

## Question FD-U3-10: 요청 성공 보상 (FR-22, AC-15-2)
요청 성공 보상은 어떻게 정할까요? (기획서 7.3: 골드, 추가 EXP 또는 특별 보상)

A) 요청 데이터마다 골드 · EXP 양을 고정 값으로 지정. 추천

B) 골드만 지급 (EXP · 특별 보상은 U3 에서 제외)

C) 요청 종류에 따라 보상 종류 (골드 / EXP / 특별) 를 무작위 선택

X) Other (please describe after [Answer]: tag below)

[Answer]: A (추천 전부 채택)

---

## Question FD-U3-11: 수면 중 전투 · 요청 발생 (AC-13-2, D-15)
30초 수면 중에 새 전투나 요청이 생길 수 있을까요?

A) 수면 중에는 전투 · 요청 모두 멈춤. 정리만 가능. 추천

B) 수면 중에도 요청은 발생 가능 (전투는 멈춤)

X) Other (please describe after [Answer]: tag below)

[Answer]: A (추천 전부 채택)

---

## Question FD-U3-12: 던전 완료 시 미완료 요청 처리
마지막 전투가 끝났을 때 아직 진행 중인 요청이 있으면 어떻게 할까요? (FR-13, AC-12-1)

A) 던전 완료와 무관하게 해당 요청은 실패 처리 (누적 +1). 추천

B) 요청을 던전 완료 후 상점 전까지 이어서 진행

C) 요청은 취소 (실패 누적 없음)

X) Other (please describe after [Answer]: tag below)

[Answer]: A (추천 전부 채택)

---

## Question FD-U3-13: 게임오버 후 흐름 (AC-16-2)
누적 실패 3회로 게임오버가 되면 다음 동작은 무엇일까요?

A) 게임오버 화면에서 누적 실패 수 표시 후 새 게임 (처음부터). 추천

B) 게임오버 화면에서 마지막 저장 시점부터 재개

C) 게임오버 화면에서 던전 1 부터 재시작 (정리 아이템은 유지)

X) Other (please describe after [Answer]: tag below)

[Answer]: A (추천 전부 채택)

---

## Question FD-U3-14: 던전 상태 전이 범위 (DungeonFlow)
`DungeonFlow` 의 상태는 어디까지 포함할까요? (U3 소유 범위, 기획서 1.0 흐름)

A) 던전 시작 → 전투 (반복) → 던전 완료 → 수면 → 상점 호출 직전 (상점 자체는 U4). 추천

B) 던전 시작부터 상점 종료 후 다음 던전 시작까지 전체

X) Other (please describe after [Answer]: tag below)

[Answer]: A (추천 전부 채택)

---

## 답변 기록
사용자가 "모두 추천으로 진행해줘" 라고 답변했습니다. FD-U3-1 ~ FD-U3-14 모두 추천안 (A) 을 채택합니다.

**가정 (답변에 없는 부분, 설계에서 명시)**
- 요청 1건은 아이템 1개를 요구합니다 (기획서 7.2 의 "수량" 은 U3 에서 1로 고정).
- 요청 제한 시간 30초는 초기 설정값입니다 (FD-U3-6 추천의 예시값).
- 요청 성공 시 전달한 아이템의 처리 (창고에서 제거 여부) 는 답변에 없습니다. 설계에서는 `reserved` 해제로만 정의하고, 제거 여부는 검토 시 확인 항목으로 남깁니다.

**정정 (사용자 입력)**
- 요청 성공 = 요청 대상 아이템을 모두 특정 전달 공간으로 옮긴 순간. 전달된 아이템은 삭제 (열린 항목 해소, BR-U3-18, BR-U3-19)
- 요청 수량 = 2~10개, 던전 난이도에 따라 증가 (BR-U3-17). 던전 1 초기값 2 는 설계 가정

---

## 변경 기록 (2026-11-27)
- FD-U3-2 (전투마다 균등 배분) 의 답은 이후 사용자 변경으로 **전투마다 5~10개 무작위** 로 대체되었습니다 (BR-U3-03 참고).
