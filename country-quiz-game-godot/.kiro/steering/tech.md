# 기술 스택

## 엔진 및 버전

- **Godot Engine 4.5** (Forward Plus 렌더러)
- 모든 게임 로직은 GDScript 사용

## 주요 라이브러리 및 데이터

- 국경선 데이터를 위한 GeoJSON (`earth.geo.json`)
- SVG 국기 에셋 (ISO 3166-1 alpha-2 국가 코드)
- Godot 내장 3D 렌더링 및 메시 생성

## 프로젝트 설정

- 뷰포트: 1280x720 (viewport stretch mode)
- 기본 텍스처 필터: nearest neighbor (픽셀 아트 스타일)
- 배경색: `Color(0.1, 0.1, 0.15, 1)`

## 주요 명령어

### 프로젝트 실행
- Godot 에디터에서 프로젝트를 열고 F5를 누르거나 "Run Project" 클릭
- 메인 씬: `res://scenes/main.tscn`

### 내보내기
- 대상 플랫폼에 맞는 Godot 내보내기 템플릿 사용
- Project > Export > 플랫폼 선택

### 개발
- Godot 에디터에서 씬 편집 (`.tscn` 파일)
- 외부 에디터 또는 Godot 내장 스크립트 에디터에서 스크립트 편집
- GDScript 파일은 `.gd` 확장자 사용

## Autoload 싱글톤

- **CountryData**: 전역 국가 데이터 관리 (`res://scripts/country_data.gd`)
