# KeyBox — Pencil 기반 상세 UI/UX 아키텍처 및 시안 설계서

이 문서는 빈 Pencil 캔버스(`key_box_pensil.pen`)를 채우기 위한 15년 차 시니어 프로덕트 디자이너 관점의 체계화된 가이드라인입니다. macOS 환경의 네이티브 느낌과 최신 트렌드(미니멀리즘, 높은 정보 밀도, 부드러운 전환)를 완벽히 반영하기 위한 구체적인 **유저 플로우**, **컴포넌트 구조**, 그리고 **Pencil.dev용 프롬프트**를 담고 있습니다.

---

## 1. 핵심 유저 플로우 (User Flow)

개발자의 작업 맥락을 끊지 않는 것을 목표로 설계된 4가지 주요 흐름입니다.

### A. 빠른 사용 흐름 (Context-free Usage)
사용자는 코딩 중 언제든 빠르게 API 키를 복사해야 합니다.
1. 글로벌 단축키 `⌘ + Shift + K` 입력 (어느 앱에서나)
2. 화면 중앙에 **Command Palette (Spotlight 스타일)** 팝업 노출
3. 키보드로 타이핑 (예: "stripe prod") → 실시간 결과 필터링
4. `Enter` 키 입력 시 **즉시 값 복사 및 팝업 종료** (알림 표시)

### B. 탐색 및 관리 흐름 (Main Dashboard)
일반적인 시크릿 열람 및 관리입니다.
1. 앱 실행 시 **3-Column Layout** 표시 (사이드바 + 테이블 뷰 + 디테일 패널)
2. 좌측 **사이드바**에서 카테고리(All Keys, API Keys 등) 또는 서비스(Stripe, AWS 등) 선택
3. 중앙 **테이블 뷰**에서 필터링된 시크릿 목록이 4컬럼(Name/Service/Env/Last Used)으로 표시
4. 테이블 행 클릭 시 우측 **디테일 패널**(340px)에 상세 정보 표시
5. 디테일의 Value Box에서 복사/노출 즉시 접근 가능

### C. 시크릿 생성 흐름 (Sheet Modal)
웹스타일의 중앙 모달을 피하고 Mac 네이티브 UX를 따릅니다.
1. 상단 바의 `+` 버튼 클릭 (또는 `⌘ + N`)
2. 상단 윈도우 크롬에서 **Sheet 팝업**이 아래로 미끄러지듯(Slide-down) 내려옴
3. 포커스가 즉시 '시크릿 이름' 입력 필드에 잡힘
4. 필수 필드 채운 후 `Enter`를 누르면 Sheet가 닫히며 중앙 리스트 맨 위에 아이템이 추가됨 (Pulse 강조 애니메이션)

---

## 2. 화면 구성 요소 아키텍처 (Pencil Components)

최신 macOS 환경에 어울리는 3-Column 레이아웃의 컴포넌트로 화면을 구성합니다.

### 2.1 사이드바 (Sidebar — 200px)

> **V6 전환 (2026-02-28):** 드롭다운 폴더 필터 → 사이드바 복원. 분류 구조의 항시 가시성 확보.

- **위치**: 좌측 200px 고정
- **배경**: `rgba(15, 23, 42, 0.6)` + `backdrop-blur-xl` (Vibrancy)
- **구성**:
  - 검색 바 (⌘K 단축키, 36px)
  - 카테고리 목록: All Keys, API Keys, Tokens, Passwords, Certificates (32px per item)
  - 서비스 트리: SERVICES 헤더 + 서비스별 항목 (hash color dot + 이름 + 카운트)
- **선택 상태**: `bg-brand-600/10` + left accent 2px

### 2.2 테이블 뷰 (Table View — fluid)
- 카드 형태(그림자 있는 블록)를 **사용하지 않습니다.**
- **테이블 레이아웃**: 4컬럼 (Name / Service / Environment / Last Used)
- **행 높이**: 44px (단일 행, 고밀도)
- **밀도**: Name (14px Medium) + Service (14px) + Env Badge + Last Used (12px)
- **호버 (Hover)**: 부드러운 `bg-slate-800/50` 페이드 인 적용.
- **정렬**: 컬럼 헤더 클릭으로 정렬 가능
- **하단 바**: "+ Add Secret" 버튼 + 아이템 카운트

### 2.3 디테일 패널 (Detail Panel — 340px) — 3-Layer Progressive Disclosure

> **V6 전환 (2026-02-28):** 1120px → 340px. 정보량 대비 영역 크기 비례 원칙 적용.

우측 340px 고정. 배경은 `#020617` (pure dark).

**Layer 1: Core (항상 보임)**
- 시크릿 이름 (16px Semibold) + 환경 뱃지 (우측 정렬)
- 서비스 아이콘 (32px, hash color) + 서비스명 + 타임스탬프
- **키 노출 박스**: `bg-slate-900` 패딩 안에 `JetBrains Mono` 폰트로 표현
- 박스 내: 마스킹 값 + 눈 아이콘(reveal) + [Copy] 버튼 (즉시 접근)

**Layer 2: Details (접이식, 기본 닫힘)**
- "▶ Details" 토글 헤더 (14px Semibold, `text-secondary`)
- 내용: Description, Type, Folder, Tags, Created, Last used — `grid-cols-2` 배치
- `max-height` transition (200ms)으로 부드러운 펼침/접힘

**Layer 3: Related (접이식, 기본 닫힘)**
- "▶ Related Secrets (N)" 토글 헤더
- 관련 시크릿 목록. 클릭 시 해당 시크릿으로 이동
- 0개일 때 섹션 자체 숨김

**Action Footer (하단 고정)**
- [Edit] (Secondary) + [Delete] (Danger ghost), `border-top: 1px`
- Delete는 인라인 확인 (별도 모달 없음)

**유저 플로우 (핵심 태스크)**:
```
1. 사이드바에서 카테고리/서비스 선택 (필터링)
2. 테이블에서 시크릿 행 클릭
3. 디테일 패널 Layer 1에서 이름 확인 ← 즉시
4. Copy 버튼 클릭 → 값 복사 ← 2클릭 완료
5. (선택) Details 펼침 → 메타데이터 확인
6. (선택) Related 펼침 → 관련 시크릿 탐색
```

---

## 3. 고도화된 Pencil AI 생성 프롬프트 (For Claude Opus)

AI 디자인 모델(특히 Claude 4.6 Opus)이 15년 차 시니어 수준의 역량을 발휘할 수 있도록 고안된 **극세사(Micro-detailed) 프롬프트 가이드**입니다. 단일 문서 관리를 위해 이 곳에 통합합니다.

### 3.0 사전 주입 프롬프트 (System Instruction)
Claude AI가 디자인을 시작하기 전, 반드시 먼저 인지해야 하는 기본 디자인 철학입니다. 캔버스 혹은 채팅창에서 가장 먼저 주입하세요.

```text
[SYSTEM: Design Philosophy & Global Tokens]
You are a 15-year experienced Senior UI/UX Designer specialized in creating hyper-modern, high-density macOS native desktop applications.

We are building a native Credential Manager app called 'KeyBox'.
Your design MUST strictly adhere to these global tokens:
1. Palette: Deep Dark Mode. Surface Primary: #0f172a, Sidebar: rgba(15, 23, 42, 0.6) with deep background blur (Vibrancy). Accent: #4f46e5 (Indigo 600).
2. Typography: 'Inter' for UI labels, 'JetBrains Mono' for secrets/codes. No fonts larger than 24px except for empty state illustrations.
3. Density: High structural density. Inputs are 28px or 32px height. List items are 56px height max.
4. Styling: NO blocky shadows for list items. NO thick borders. Use hair-line borders (1px with low opacity like rgba(255,255,255,0.1)).
5. Corner Radius: Rounded-md (6px) or Rounded-lg (8px) for interactive elements.
```

### 3.1 화면 시안 1: 메인 대시보드 (3-Column)
```text
Generate a full screen (1440x900) UI design for the 'KeyBox' main dashboard using a native macOS 3-column layout.

- Left Column (Sidebar, 200px width): Vibrancy background (rgba(15,23,42,0.6) + backdrop-blur). Top: Search bar (36px) with "⌘K" shortcut. Categories: All Keys, API Keys, Tokens, Passwords, Certificates (32px items). Below divider: Services section with hash-colored dots + service names + counts.
- Center Column (Table View, fluid ~900px): Dark background #0f172a. Sortable header row (Name/Service/Env/Last Used). Data rows 44px high, single-line, environment badges. Selected row has indigo accent. Bottom bar: "+ Add Secret" button + item count.
- Right Column (Detail Panel, 340px): Pure dark #020617 background. Compact layout: Name + env badge, service dot, Value Box (masked + Reveal + Copy), collapsible Details/Related toggles, Edit/Delete footer.
```

### 3.2 화면 시안 2: 시크릿 생성 모달 (macOS Sheet)
```text
Design the "Create New Secret" flow. This MUST be a native macOS "Sheet" style panel sliding down from the absolute top edge of the window.

- Width: 460px.
- Body Form fields (Progressive Disclosure UX): 
  - ONLY show three basic inputs by default: "Title" (Input), "Description" (Input), and "Value" (Textarea, 3 lines).
  - Below these, place a simple, subtle standard macOS accordion/toggle button labeled "Advanced Options ▼". DO NOT show other inputs.
- Action Footer: Subdued 'Cancel' button and a prominent filled 'Save Secret' button aligned to the right.
- Vibe: Zero cognitive load. Utilitarian, clean, zero wasted space. User should be able to paste a key and hit save immediately.
```

### 3.3 화면 시안 3: Command Palette (Spotlight 스타일)
```text
Design a central "Command Palette" overlay for KeyBox (Cmd+K).

- Background: Heavily blurred out app background.
- Floating modal (560px width) at exact center. Dark translucent background, thin sharp border glowing slightly at top edge. Drop a heavy 24px blur deep shadow.
- Top: Large borderless text input field with a search icon. Font size 18px.
- Middle: List of 3 search results. First one is active with subtle Indigo tint.
- Bottom: Footer with keyboard shortcut hints: "↵ to Copy", "↑↓ to Navigate", "Esc to Close".
```

---

## 4. 디자이너의 조언 (마이크로 인터랙션 포인트)

훌륭한 UI는 정지 화면이 아닌 **상태 변화의 부드러움**에서 완성됩니다.
- **클릭 피드백 (Tactile Feel)**: [복사] 버튼을 누를 때 0.95배율로 살짝 줄어들었다가 돌아오는 스케일 트랜지션을 Pencil 컴포넌트 Variants로 만들어두세요.
- **상태 변화 표기**: 복사를 완료하면 'Copy' 아이콘이 1.5초간 녹색 체크(Check) 아이콘으로 디졸브(Fade in/out) 되어야 합니다.
- **텍스트 트랜케이션 (Truncation)**: 시크릿 이름이 길어질 경우 끝을 잘라내지 말고 부드럽게 페이드 아웃되는 효과(CSS mask-image: linear-gradient)를 사용하면 훨씬 고급스럽습니다.
