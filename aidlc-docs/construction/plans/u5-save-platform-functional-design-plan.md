# U5 저장 · 플랫폼 기능 설계 계획 (Functional Design Plan)

**unit**: U5 저장 · 플랫폼 (Save & Platform)
**기준**: `inception/application-design/unit-of-work.md` (U5 정의), `user-stories/stories.md` (SYS-01 ~ SYS-04), `requirements/requirements.md` (FR-25 ~ 28, NFR-03, NFR-06 ~ 08), `application-design/application-design.md` (V-1, V-2, V-4, AD-8, AD-9), 기획서 14.8 · 15 Phase 10
**의존**: U1 ~ U4 (모든 진행 값을 저장 · 복원)
**범위 밖**: 영어 번역 (FR-28, MVP 이후), 웹 배포 설정 자체 (NFR-06 ~ 08 은 빌드 설정이라 Code Generation 에서 처리)

이 계획은 U5 에서 명확하지 않은 규칙을 정리한 것입니다. 각 질문의 `[Answer]:` 뒤에 선택지 문자를 적어 주세요. 추천안은 "추천" 으로 표시했습니다. 추천을 그대로 쓰면 "추천 전부" 라고만 적어 주셔도 됩니다.

**생성 예정 산출물 (답변 후)**
- `aidlc-docs/construction/u5-save-platform/functional-design/business-logic-model.md`
- `aidlc-docs/construction/u5-save-platform/functional-design/business-rules.md`
- `aidlc-docs/construction/u5-save-platform/functional-design/domain-entities.md`
- `aidlc-docs/construction/u5-save-platform/functional-design/frontend-components.md`

---

## Question FD-U5-1: 저장 시점 (SYS-01, FR-25)
언제 저장할까요?

A) 던전 완료 시 자동 저장만. 수동 저장 버튼은 없음. 추천

B) 던전 완료 자동 저장 + 상점 방문 후에도 저장

C) 자동 저장 + 수동 저장 버튼 (언제든)

X) Other (please describe after [Answer]: tag below)

[Answer]:

---

## Question FD-U5-2: 저장 위치 (데스크톱 · 웹)
저장 파일은 어디에 둘까요?

A) 데스크톱: 사용자 데이터 폴더 (`user://`). 웹: 브라우저 저장소 (`user://` 가 브라우저에 저장됨). 추천

B) 데스크톱은 게임 폴더 옆 파일, 웹은 브라우저 저장소

X) Other (please describe after [Answer]: tag below)

[Answer]:

---

## Question FD-U5-3: 저장 파일 보호 (AD-8 A, AD-9 B, V-1)
저장 파일을 어떻게 보호할까요?

A) JSON 평문 + HMAC-SHA256 서명 (내용이 바뀌면 거부). 암호화는 하지 않음. 추천

B) JSON 암호화 + 서명 (웹에서 암호화가 지원되지 않으면 서명만 사용)

X) Other (please describe after [Answer]: tag below)

[Answer]:

---

## Question FD-U5-4: HMAC 키 보관 (V-4)
서명 키는 어디에 둘까요?

A) 빌드 시 코드에 상수로 주입. 추천 (단순, 개인용 MVP 수준 보호)

B) 첫 실행 때 무작위 키를 만들어 사용자 데이터 폴더에 저장

X) Other (please describe after [Answer]: tag below)

[Answer]:

---

## Question FD-U5-5: 웹 내보내기 · 불러오기 (SYS-02, FR-26, V-2)
웹에서 세이브 파일을 어떻게 다루게 할까요?

A) 설정 화면의 "내보내기" 버튼은 파일을 다운로드하고, "불러오기" 버튼은 파일을 선택해 서명을 검사한다. 추천

B) 이번 범위에서 제외. 브라우저 저장소만 사용

X) Other (please describe after [Answer]: tag below)

[Answer]:

---

## Question FD-U5-6: 복원 지점 (불러오기 후 어디서 시작할지)
불러오면 어느 지점부터 다시 시작할까요?

A) 마지막 저장 시점 (던전 완료 직후 = 수면 · 상점 직전). 수면은 처음부터 다시. 추천

B) 마지막 저장 시점의 상태 그대로 (수면 중이었다면 수면 남은 시간까지 복원)

X) Other (please describe after [Answer]: tag below)

[Answer]:

---

## Question FD-U5-7: 진행 중 퀘스트 · 판매 퀘스트 저장 (기획서 14.8 "진행 중 요청 상태(필요한 경우)")
진행 중인 퀘스트 (긴급 요청, 판매 퀘스트) 는 저장할까요?

A) 저장하지 않는다. 복원 시 진행 중 퀘스트는 없고, 전달 선반 아이템은 그대로 남는다. 추천

B) 퀘스트 상태 (줄 진행, 남은 시간) 까지 저장

X) Other (please describe after [Answer]: tag below)

[Answer]:

---

## Question FD-U5-8: 게임오버 상태 (AC-16 과 연결)
게임오버가 되면 저장을 어떻게 할까요?

A) 게임오버 시 저장 파일을 지운다. 다음 실행은 새 게임. 추천

B) 게임오버 상태를 저장하고, 새 게임 버튼을 누를 때까지 게임오버 화면을 유지

X) Other (please describe after [Answer]: tag below)

[Answer]:

---

## Question FD-U5-9: 화면 해상도 (SYS-04, FR-27, D-10)
화면 설정은 어떻게 할까요?

A) 1280x720 고정, 창 크기가 바뀌면 비율을 유지 (레터박스). 설정 메뉴 없음. 추천

B) 1280x720 고정 + 전체 화면 전환 버튼 추가

X) Other (please describe after [Answer]: tag below)

[Answer]:

---

## Question FD-U5-10: 언어 (FR-28, D-11)
언어 설정은 어떻게 할까요?

A) 한국어 고정. 설정 메뉴에 언어 항목 없음 (영어는 MVP 이후). 추천

B) 설정 메뉴에 언어 항목을 만들고 한국어만 선택 가능

X) Other (please describe after [Answer]: tag below)

[Answer]:

---

## Question FD-U5-11: 저장 대상 범위 (기획서 14.8, SYS-01 AC-SYS-01-1)
저장에 무엇을 넣을까요?

A) 던전 번호와 완료 횟수, 골드, 레벨과 EXP, 증강과 능력치, 모든 아이템 인스턴스 (위치 · 상태), 선반 종류 · 위치 · 칸 수, 실패 횟수, 튜토리얼 완료 여부, 상점 방문 횟수. 추천

B) A 에서 튜토리얼 완료 여부와 상점 방문 횟수만 뺀다

X) Other (please describe after [Answer]: tag below)

[Answer]:

---

## 승인 요청
질문 11개 (FD-U5-1 ~ 11) 의 답을 알려 주세요. "추천 전부" 라고 쓰셔도 됩니다. 답변 후 U5 기능 설계 산출물을 만들고, 그 뒤 승인을 요청하겠습니다.
