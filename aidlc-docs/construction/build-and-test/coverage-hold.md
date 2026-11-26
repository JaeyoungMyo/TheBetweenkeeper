# 커버리지 측정 보류 기록

**기준**: 라인 커버리지 80% (사용자 결정)
**상태**: 보류 (측정 안 함)
**보류일**: 2026-11-26

## 경위
1. Godot 4.7 에는 기본 커버리지 도구가 없다.
2. gdUnit4 (v7.0.0) 는 테스트 프레임워크이고 커버리지 기능이 없어 도입하지 않았다.
3. jamie-pate/godot-code-coverage 는 Godot 3.5 전용이라 사용할 수 없다.
4. IgorBayerl/nano-coverage-godot 는 Godot 4 를 지원하지만 C++ 확장을 직접 빌드해야 한다 (SCons, 엔진 · 라이브러리 다운로드). 빌드 스크립트 실행이 자동 보안 정책에 막혔다.
5. 사용자가 모바일이라 권한 규칙을 추가할 수 없어서 보류로 결정했다.

## 재개 방법 (PC 에서)
1. 저장소 `IgorBayerl/nano-coverage-godot` 를 확인한 뒤 `python scripts/setup.py`, `python scripts/build.py` 실행
2. 생성된 `addons/nano_coverage_godot` 를 프로젝트에 복사하고 플러그인 활성화
3. 헤드리스 테스트 실행 중 측정하거나, 에디터에서 Instrument 를 켜고 게임을 실행
4. lcov 결과의 라인 커버리지 확인. 80% 미만이면 빠진 파일 목록을 보고

## 재개 시 확인할 것
- 측정 대상: `scripts/`, `autoload/` (테스트 · 애드온 · contrib 제외)
- 80% 미달 시 보강 방법은 사용자와 함께 결정
