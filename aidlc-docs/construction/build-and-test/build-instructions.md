# 빌드 안내 (Build Instructions)

## 사전 조건
- **엔진**: Godot 4.7.2 (stable). 설치 경로는 자유. 이 저장소에서는 `/tmp/.../Godot_v4.7.2-stable_linux.x86_64` 로 실행했다.
- **의존성**: 외부 패키지 없음. Godot 기본 기능만 사용 (Compatibility 렌더러).
- **환경 변수**: 없음.
- **시스템**: 헤드리스 실행은 디스플레이 불필요. 화면 확인은 데스크톱 (Windows 등) 에서 Godot 에디터 또는 실행.

## 빌드 단계

### 1. 클래스 캐시 생성 (최초 1회, 파일을 추가하거나 바꾼 뒤 필요)
```
godot --headless --path . --import
```
- 기대 결과: 종료 코드 0. `.godot/` 와 `.uid` · `.import` 파일이 갱신된다.

### 2. 데스크톱 실행 (화면 확인)
```
godot --path .
```
- 메인 씬: `res://scenes/storage/tutorial_storage.tscn` (project.godot)

### 3. 웹 빌드 (NFR-06, 미실행)
- 현재 `export_presets.cfg` 가 없고 Web Export Template 설치를 확인하지 못했다.
- 필요 작업: Godot 에디터에서 Web 프리셋 생성 (스레드 끔, Compatibility) → `godot --headless --path . --export-release "Web" build/web/index.html`
- 상태: **미실행** (SYS-03 은 빌드 단계에서 확인, FD-U5-5 에 따라 웹 저장 내보내기는 제외).

## 빌드 성공 확인
- `godot --headless --path . --import` 종료 코드 0
- 메인 씬 300 프레임 실행 (`--quit-after 300`) 시 `SCRIPT ERROR` 0건
- 기대 출력: 스크립트 파싱 오류 없음

## 문제 해결

### 파싱 오류로 실행 실패
- **원인**: 타입 추론 실패 (`:=` 와 Variant), 내장 함수 이름과 충돌 (예: `sign`)
- **해결**: 타입을 명시하고 이름을 바꾼다. 로그의 `SCRIPT ERROR` 줄 번호를 확인한다.

### 클래스를 찾지 못함
- **원인**: 새 `class_name` 파일 뒤에 `--import` 를 안 함
- **해결**: 1단계 `--import` 를 다시 실행한다.
