# KeyBox Native App Design Proposal (macOS & iOS Focus)

KeyBox 애플리케이션의 초기 디자인 방향성과 스타일 가이드를 제안합니다. 사용자의 활용성을 극대화하기 위해 웹보다는 데스크탑(macOS) 및 모바일 네이티브 앱에 중점을 두어 디자인합니다.

## 1. 전반적인 분위기 (Vibe & Concept)

최신 Apple 플랫폼의 디자인 언어(Human Interface Guidelines)를 충실히 따며 네이티브 앱 특유의 빠르고 직관적인 경험을 제공합니다.

- **Native macOS Feel**: 데스크탑(Mac) 환경에서 이질감이 없도록 사이드바의 반투명(Translucent) 재질, 윈도우 컨트롤, 둥근 모서리를 적극 활용합니다.
- **Micro-interactions**: 버튼 클릭 및 호버 시 네이티브 앱다운 즉각적이고 부드러운 반응.
- **System Integration**: 메뉴 바(Menu Bar) 아이콘 지원, 시스템 글로벌 단축키(Global Hotkey) 연동을 통한 빠른 접근성 확보.

## 2. 컬러 시스템 및 다크모드 (Color & Dark Mode)

네이티브 앱의 가장 큰 특징 중 하나인 시스템 다크모드/라이트모드 전환을 완벽히 지원합니다.

- **Primary Accent**: `System Indigo` - Apple 시스템 컬러표의 Indigo를 사용하여 네이티브 앱다운 통일감을 줍니다.
- **Background**:
  - Light 모드: `System White` 배경에 약간의 회색 톤으로 계층 구분.
  - Dark 모드: 자극이 적은 깊은 어두운 회색(`System Gray 6`) 및 검은색을 활용한 하이 콘트라스트.
- **Vibrancy (사이드바)**: 데스크탑 앱의 특징인 뒷배경이 은은하게 비치는 블러 효과(Vibrancy) 적용.

## 3. 타이포그래피 및 아이콘 (Typography & Iconography)

- **UI 글꼴**: `San Francisco (SF Pro)` - Apple 플랫폼의 기본 폰트로 가장 깔끔하고 익숙한 가독성을 제공합니다.
- **코드 및 시크릿 값 글꼴**: `SF Mono` - 개발자용 데이터(API Key 등)는 명확한 구분을 위해 고정폭 폰트 사용.
- **아이콘**: `SF Symbols` - Apple 생태계 전반에 걸쳐 일관된 심볼을 사용하여 완벽한 네이티브 앱 룩 앤 필(Look & Feel) 구현.

## 4. 데스크탑 앱 핵심 레이아웃 패턴 (Layout Pattern)

### 4.1. macOS 스타일 사이드바 (Navigation)
- **Fluid Sidebar**: 투명도가 있는 사이드바로 폴더 및 메뉴 탐색. 모바일(iOS)에서는 하단 탭 바(Tab bar) 또는 네비게이션 스택으로 전환됩니다.
- **List View + Detail View (Split View)**: Mac의 메일(Mail)이나 메모(Notes) 앱처럼 좌측에는 시크릿 리스트, 우측에는 상세 내용을 보여주는 친숙한 Split View 구조.

### 4.2. 빠른 접근창 (Quick Access / Spotlight style)
- 앱을 완전히 열지 않아도, 바탕화면이나 다른 작업 중에 **글로벌 단축키(예: Cmd + Shift + K)**를 누르면 Spotlight(스포트라이트)나 Raycast 형태의 플로팅 검색창이 떠서 바로 복사할 수 있는 UX 제공.

## 5. 앱 시안 (Native App Mockup)

macOS의 반투명(Vibrancy) 효과와 Split View를 적용한 다크 모드 시안입니다. 왼쪽에는 폴더, 중간에는 시크릿 리스트, 우측에는 상세 내역이 표시됩니다.

![KeyBox macOS App Mockup](./keybox_mac_app_mockup.png)

## 6. 개발 스택에 대한 제언 (Rails 연계 방안)

기존 프로젝트 기반이 **Ruby on Rails**로 구축되어 있습니다 (인증 시스템, 암호화 모델 등). 웹 형태 대신 네이티브 앱을 구축하기 위해 다음과 같은 하이브리드 접근을 고려해 볼 수 있습니다.

1. **Hotwire Native (Turbo Native)**
   - **장점**: 기존 Rails 앱의 로직과 뷰를 80% 이상 재사용 가능. 모바일(iOS/Android)의 경우 네이티브 탭바/네비게이션 셸 안에 웹뷰를 띄워 네이티브에 가까운 경험 제공.
   - macOS의 경우, Catalyst나 별도의 Mac용 브라우저 기반 래핑(Tauri, Electron 등)을 검토.
2. **Tauri / Electron (크로스 플랫폼 데스크탑 앱)**
   - 웹뷰 기반이지만 OS 네이티브 기능(글로벌 단축키, 클립보드 제어, 시스템 트레이 아이콘)을 강력하게 결합할 수 있습니다. UI는 웹뷰로 그리되 상단 디자인 제안처럼 CSS(예: `backdrop-filter: blur()`)를 통해 네이티브 앱 흉내를 낼 수 있습니다. 이 경우 Rails 앱은 JSON API 서버 역할을 주로 담당하게 됩니다.
3. **완전한 네이티브 (Swift / SwiftUI)**
   - **장점**: 최고의 성능과 완벽한 OS 통합.
   - **단점**: Rails 서버와는 별개로 완전히 새로운 Swift 클라이언트 앱을 개발해야 합니다 (이 경우 Rails는 `Phase 3: API` 단계 기능을 먼저 구현하여 백엔드 역할만 수행).
