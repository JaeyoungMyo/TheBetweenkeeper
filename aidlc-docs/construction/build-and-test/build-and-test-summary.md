# 빌드 및 테스트 요약 (Build and Test Summary)

## 빌드 상태
- **빌드 도구**: Godot 4.7.2 (stable), Compatibility 렌더러
- **빌드 상태**: Success (데스크톱 프로젝트 임포트 · 헤드리스 실행)
- **빌드 산출물**: `.godot/` 캐시, `.uid` · `.import` 파일 (저장소에 포함)
- **웹 빌드**: 제외 (사용자 결정: 데스크톱만 진행)
- **빌드 시간**: 임포트 + 전체 테스트 약 16초

## 테스트 실행 요약

### 단위 테스트 (Unit Tests)
- **전체 테스트 (Total Tests)**: 79 (단위 · 통합 · PBT · 동작 합계)
- **통과 (Passed)**: 79
- **실패 (Failed)**: 0
- **커버리지 (Coverage)**: 기준 80% (사용자 결정). **보류** (측정 안 함, `coverage-hold.md` 참고)
- **상태 (Status)**: Pass (테스트 통과). 커버리지 기준은 미충족 가능성 있음, 측정 필요

### 통합 테스트 (Integration Tests)
- **테스트 시나리오 (Test Scenarios)**: 튜토리얼, 클릭 이동, 던전 슬라이스, 던전 화면 흐름, 상점 흐름, 저장 흐름 (6)
- **통과 (Passed)**: 6 + 동작 테스트 5 (실제 키보드 · 마우스 입력 이벤트로 조작)
- **실패 (Failed)**: 0
- **상태 (Status)**: Pass

### 동작 테스트 (Behavior Tests, 신규)
- 실제 입력 이벤트 (`root.push_input`) 로 게임을 조작한다. 파일: `tests/integration/test_behavior_input.gd`
- 항목: X 줍기 → 선반 열기 → 1 키 칸 적재, Z 바닥 내려놓기, F1 · F2 메뉴 토글, 빈 바닥 클릭 이동, 전달 선반 클릭 후 1 키로 1개 넣기
- 결과: 5/5 통과

### 성능 테스트 (Performance Tests)
- **응답 시간 · 처리량**: 미실행 (헤드리스에서 측정 불가, 기준 PC 미확정 → 사용자가 모름, 나중에 정함)
- **상태 (Status)**: 보류

### 추가 테스트 (Additional Tests)
- **계약 테스트 (Contract Tests)**: N/A (마이크로서비스 아님)
- **보안 테스트 (Security Tests)**: N/A (서버 없음, 저장 서명은 단위 테스트에 포함)
- **E2E 테스트 (E2E Tests)**: 미실행 (화면 조작은 수동, TEST.md 참고)

### 스크립트 점검
- 메인 씬 300 프레임 실행: `SCRIPT ERROR` 0건
- 시작 시 `SCRIPT ERROR` 0건

## 전체 상태
- **빌드 (Build)**: Success (데스크톱)
- **전체 테스트 (All Tests)**: Pass (74 / 74)
- **Operations 준비 (Ready for Operations)**: No. 웹 빌드 (NFR-06, NFR-07) 와 화면 수동 테스트가 남아 있다.

## 미결 항목
1. **커버리지 80% 측정**: 기준은 80% 로 정했지만 Godot 에는 기본 커버리지 도구가 없어 아직 측정하지 못했습니다. 측정 방법 후보: gdUnit4 의 커버리지 애드온 (외부 코드를 저장소에 추가해야 하므로 승인 필요).
2. **웹 빌드**: 제외 (데스크톱만 진행, 사용자 결정).
3. **성능 기준 PC 사양**: 정해지지 않음. NFR-01 (60 FPS) 은 보류.
4. **수동 테스트**: `TEST.md` 의 항목을 집에서 확인해 주세요. 자동 동작 테스트로 일부는 대체되었습니다.

## 다음 단계
- 자동 테스트는 모두 통과했습니다. 수동 테스트와 위 미결 항목을 정리한 뒤 Operations 단계 (배포 · 성능 검증) 를 판단합니다.
- 실행 계획상 Operations 는 Deployment Execution · Performance Validation 이 EXECUTE 입니다. 웹 빌드와 성능 기준이 정해져야 진행할 수 있습니다.
