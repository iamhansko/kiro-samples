# 프로젝트 구조

## 디렉토리 구성

```
/
├── .godot/              # Godot 엔진 캐시 (gitignored)
├── .kiro/               # Kiro AI 어시스턴트 설정
│   └── steering/        # AI 스티어링 문서
├── public/              # 정적 에셋
│   ├── flags/           # 국기 SVG 파일 (ISO 코드)
│   ├── earth.geo.json   # GeoJSON 국경선 데이터
│   └── icon.svg         # 애플리케이션 아이콘
├── scenes/              # Godot 씬 파일
│   └── main.tscn        # 메인 게임 씬
├── scripts/             # GDScript 소스 파일
│   ├── game_manager.gd       # 루트 코디네이터
│   ├── globe.gd              # 3D 지구본 컨트롤러
│   ├── ui.gd                 # UI 컨트롤러
│   ├── country_data.gd       # Autoload 싱글톤
│   ├── world_map_drawer.gd   # 국경선 렌더링
│   ├── pole_markers.gd       # 극점/참조 마커
│   └── crosshair_lines.gd    # 위도/경도 십자선
├── project.godot        # Godot 프로젝트 설정
└── README.md            # 프로젝트 문서
```

## 씬 계층 구조

메인 씬 (`main.tscn`)은 다음과 같은 구조를 따릅니다:

```
GameManager (Node)
├── Camera3D
├── DirectionalLight3D
├── Globe (Node3D)
│   ├── GlobeMesh (MeshInstance3D)
│   ├── WorldMapDrawer (Node3D)
│   ├── PoleMarkers (Node3D)
│   └── CrosshairLines (Node3D)
└── UI (CanvasLayer)
    └── Control (다양한 UI 요소)
```

## 아키텍처 패턴

### 의존성 주입 (Dependency Injection)
부모 노드가 하드코딩된 노드 경로 대신 자식에게 참조를 제공합니다. GameManager가 Globe와 UI에 의존성을 주입합니다.

### 시그널 기반 통신 (Signal-Based Communication)
컴포넌트들은 느슨한 결합을 위해 시그널을 통해 통신합니다:
- `globe.crosshair_moved` → GameManager → UI
- `ui.submit_pressed` → GameManager → Globe
- `ui.hint_pressed` → GameManager → Globe

### 단일 책임 원칙 (Single Responsibility)
각 스크립트는 자신의 영역을 관리합니다:
- **GameManager**: 컴포넌트 간 조정
- **Globe**: 3D 상호작용 및 회전 처리
- **UI**: 인터페이스 및 게임 상태 관리
- **CountryData**: 전역 데이터 접근 (autoload)
- **WorldMapDrawer**: 국경선 렌더링
- **PoleMarkers**: 참조 마커 표시
- **CrosshairLines**: 위도/경도 선 표시

### Autoload 사용
CountryData만 autoload 싱글톤입니다. 다른 객체의 상태를 방해하지 않으면서 전역 국가 데이터를 관리합니다. 정적 메서드를 통해 접근합니다.

## 파일 명명 규칙

- 스크립트: `snake_case.gd`
- 씬: `snake_case.tscn`
- 에셋: 국기는 ISO 코드를 사용한 `lowercase`
- UID 파일: `*.gd.uid` (Godot 자동 생성)
- Import 파일: `*.import` (Godot 자동 생성)
