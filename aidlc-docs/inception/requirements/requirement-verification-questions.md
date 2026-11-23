# 요구사항 확인 질문 (Requirements Verification Questions)

기획서 `아공간_관리인_최종_게임_기획서_Godot_개발명세서_v1.0.md`를 분석했습니다. 기획은 상세하지만, 구현 전에 확정해야 할 부분이 남아 있습니다. 각 질문의 `[Answer]:` 태그 뒤에 선택지 문자를 적어 주세요. 맞는 선택지가 없으면 `X) Other`를 고르고 내용을 함께 적어 주세요.

---

## Question 1
Godot 엔진 버전은 어느 것으로 고정할까요?

A) Godot 4.4 (안정 버전)

B) Godot 4.5 이상 최신 안정 버전

C) 현재 설치된 버전 그대로 사용

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question 2
웹(HTML5) 배포를 어느 수준으로 지원할까요? (Godot 웹 빌드는 Compatibility 렌더러를 사용해야 합니다.)

A) 웹과 데스크톱 모두 Compatibility 렌더러로 통일

B) 데스크톱 우선 (Forward+ 등 고급 렌더러 허용), 웹은 단순화된 버전으로 별도 대응

C) 웹 배포는 하지 않고 데스크톱 전용으로 진행

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question 3
웹 배포 시 세이브 데이터는 어떻게 보관할까요? (브라우저 저장은 사용자가 브라우저 데이터를 지우면 사라집니다.)

A) 브라우저 저장만 사용 (IndexedDB, user://)

B) 브라우저 저장 + 세이브 파일 내보내기/불러오기 기능 추가

C) 파일 내보내기/불러오기만 사용

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question 4
플레이어가 던전(용사의 모험) 자체를 조작하나요? 기획서에서는 던전이 아이템을 "입고"하는 연출로만 보입니다.

A) 아니요. 던전은 연출과 텍스트 결과로만 표현하고, 플레이어는 아공간 정리만 함

B) 아니요. 던전은 간단한 선택지(진행 · 후퇴 등)로 결정하고, 결과가 아이템 입고로 이어짐

C) 예. 던전 내 간단한 조작(이동 · 전투 등)을 MVP 이후에 추가

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question 5
용사의 상점 구매 품목은 어떤 규칙으로 결정할까요? (기획서 9.2의 직업 · 성향 · 다음 던전 특성)

A) 가중치 기반 무작위 (직업과 성향에 따라 확률 가중치 부여)

B) 다음 던전의 특성에 맞춘 규칙 기반 (예: 독 던전이면 해독약 우선)

C) 미리 정해진 고정 목록 (MVP 단계)

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question 6
긴급 요청에 실패했을 때의 페널티는 무엇으로 할까요? (기획서 7.3 "보상 없음 또는 설정된 페널티")

A) 보상 없음 (페널티 없음)

B) 골드 감소

C) 용사 신뢰도 감소 (이후 상점 구매 가격 상승 등)

D) 다음 요청의 제한 시간 단축

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question 7
MVP 1차에서 사용할 아이템 종류는 몇 가지로 시작할까요? (기획서 16장은 "아이템 10개 생성"만 명시)

A) 10개 (아이템 개수만 맞추는 테스트용, 종류는 카테고리 대표 위주)

B) 카테고리별 대표 3개씩 총 약 24종

C) 기획서 8.2 기준 던전 1 (신규 아이템 10개, 종류 3개)과 같은 방식으로 시작

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question 8
아이템을 집고 내려놓는 입력 방식은 무엇으로 할까요?

A) 좌클릭으로 집기 · 다시 좌클릭으로 내려놓기 (토글)

B) 좌클릭 누른 채 드래그 · 놓으면 내려놓기

C) 집기는 좌클릭, 내려놓기는 우클릭

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question 9
시설 적재 무게가 한도를 넘을 때 플레이어 피드백은 어떻게 할까요?

A) 배치 프리뷰를 경고 색으로 표시하고 내려놓기만 막음

B) A와 함께 "무게 초과" 메시지 표시

C) A와 함께 다른 시설 추천 표시

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question 10
게임 화면 해상도와 비율은 어떻게 할까요?

A) 1280x720 (16:9) 고정, 창 크기 조절 시 비율 유지

B) 1920x1080 (16:9) 기준, 창 크기 조절 시 비율 유지

C) 반응형 (화면 크기에 따라 가변)

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question 11
UI 언어는 어떻게 할까요?

A) 한국어만

B) 한국어 기본 + 영어 번역 추가 (MVP 이후)

C) 한국어 · 영어 처음부터 동시 지원

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question 12
자동 저장 시점은 언제로 할까요?

A) 아이템 정리, 판매, 요청 완료 등 주요 행동마다

B) 던전(스테이지) 완료 시마다

C) 수동 저장만 허용

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## 확장 사용 동의 (Extension Opt-In)

아래 세 가지는 확장 규칙 사용 여부입니다. 각 질문에 답해 주세요.

## Question 13: 복원력 확장 (Resiliency Extensions)
이 프로젝트에 복원력 기준 (resiliency baseline) 을 적용할까요?

이 확장은 장애 허용, 고가용성, 관측 가능성, 복구 가능성 측면의 방향 제시용 설계 모범 사례를 적용합니다. 운영 인증이나 가용성 보장은 하지 않습니다. 이 게임은 PC/웹 싱글플레이 배포 대상이므로 서버 복원력은 해당 범위가 작습니다.

A) 예 — 복원력 기준을 방향 제시용 모범 사례 및 설계 단계 지침으로 적용 (비즈니스 핵심 워크로드에 권장. 운영 개시 전에 검증 · 강화할 수 있는, 근거 있는 출발점)

B) 아니오 — 복원력 기준 생략 (신뢰성보다 빠른 반복이 중요한 PoC, 프로토타입, 실험 프로젝트에 적합)

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question 14: 보안 확장 (Security Extensions)
이 프로젝트에 보안 확장 규칙을 강제할까요?

A) 예 — 모든 SECURITY 규칙을 차단성 제약으로 강제 (운영 수준 애플리케이션에 권장)

B) 아니요 — 모든 SECURITY 규칙 건너뜀 (PoC, 프로토타입, 실험 프로젝트에 적합)

X) Other (please describe after [Answer]: tag below)

[Answer]: 

---

## Question 15: 속성 기반 테스트 확장 (Property-Based Testing Extension)
이 프로젝트에 속성 기반 테스트 (PBT) 규칙을 강제할까요?

A) 예 — 모든 PBT 규칙을 차단성 제약으로 강제 (비즈니스 로직, 데이터 변환, 직렬화, 상태를 가진 구성요소가 있는 프로젝트에 권장)

B) 부분 — 순수 함수와 직렬화 왕복 (round-trip) 에만 PBT 규칙 강제 (알고리즘 복잡도가 낮은 프로젝트에 적합)

C) 아니요 — 모든 PBT 규칙 건너뜀 (단순 CRUD 애플리케이션, UI 전용 프로젝트, 중요한 비즈니스 로직이 없는 얇은 통합 계층에 적합)

X) Other (please describe after [Answer]: tag below)

[Answer]: 
