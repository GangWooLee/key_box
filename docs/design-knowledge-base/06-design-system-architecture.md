# Phase 6 — 디자인 시스템 아키텍처

**Version**: 1.0
**Target Audience**: 15+ years UI/UX expertise
**Date**: 2026-02-27

---

## 개요 (Overview)

본 문서는 현대 디자인 시스템의 아키텍처 구성을 기업급(enterprise-grade) 관점에서 다룹니다. Atomic Design의 진화, W3C Design Token Community Group (DTCG) 표준화, 크로스 플랫폼 토큰 파이프라인, 그리고 거버넌스 모델까지 체계적으로 검토합니다. 특히 K-Beauty SaaS 컨텍스트에서 확장 가능하고 유지보수 가능한 디자인 시스템 구축을 목표로 합니다.

---

## 1. Atomic Design 재고찰: 진화 그리고 현실

### 1.1 Brad Frost (2013) 정의 — 다시 읽기

Brad Frost의 Atomic Design은 chemistry 은유를 통해 컴포넌트 계층 구조를 정의했습니다.

```
Atoms → Molecules → Organisms → Templates → Pages
```

**각 레이어 정의:**

| 레이어 | 특징 | 예시 |
|--------|------|------|
| **Atoms** | 최소 단위, 더 이상 분해 불가 | Button, Input, Label, Icon |
| **Molecules** | Atoms의 단순 조합 | SearchBox, FormField, Card |
| **Organisms** | 복잡한 상호작용 | Header, Footer, ProductGrid |
| **Templates** | Layout 스켈레톤, 재사용 패턴 | ProductDetailTemplate |
| **Pages** | 실제 콘텐츠가 입혀진 인스턴스 | ProductDetailPage (SKU:12345) |

### 1.2 2025 비판점 — 명명과 경계의 모호함

**문제점:**
1. **명명의 과학성 부재**: "Atom"이 정확한가? JavaScript의 "Component"가 더 명확.
2. **경계의 불명확함**: Button이 atom인가, molecule인가? 상황에 따라 다름.
3. **Template의 오버로드**: Layout template과 Component template을 혼동.
4. **Figma/개발 간극**: Figma에서는 atom/molecule 구분하지만, 코드는 모두 component.

### 1.3 현대 대안: Component → Pattern → Template

더 명확한 계층 구조:

```
Primitive Components
  ├── Button, Input, Select, Checkbox
  └── 재사용성 100%, 스타일링 완전 제어 가능

Composite Components (Patterns)
  ├── SearchBox = Input + Icon + Button
  ├── FormField = Label + Input + ErrorMessage + HelpText
  └── Card = Container + Typography + Actions

Layouts/Templates
  ├── PageLayout = Header + Sidebar + Main + Footer
  ├── FormTemplate = PageLayout + FormSteps
  └── ListTemplate = PageLayout + FilterBar + List
```

**Figma에서의 구현:**

```
Components/
├── 1-Primitives/
│   ├── Button/
│   │   ├── Button (base)
│   │   ├── Button/Primary
│   │   ├── Button/Variant=Icon
│   │   └── Button/Size=Large
│   └── Input/...
│
├── 2-Patterns/
│   ├── SearchBox/
│   │   ├── SearchBox (base)
│   │   ├── SearchBox/Variant=Expanded
│   │   └── SearchBox/State=Focused
│   └── FormField/...
│
└── 3-Templates/
    ├── ProductDetailLayout
    └── ListPageLayout
```

### 1.4 Dan Mall의 "Hot Potato" 프로세스

컴포넌트 검토 및 거버넌스 시스템:

1. **Design System Team**이 새 컴포넌트 제안
2. **Product Teams**에서 실제 사용 가능성 검증
3. **Feedback Loop** → Refinement
4. **Adoption & Feedback** → System으로 정식화

**라운드 트립 (Round-trip) 설정:**
- Q1: 신규 컴포넌트 제안 수집
- Q2: Design System 검토 및 프로토타입
- Q3: Product teams 파일럿 적용
- Q4: Feedback 기반 정식화 또는 폐기

---

## 2. 다층 토큰 시스템: 3-Tier Architecture

### 2.1 개념: Primitive → Semantic → Component

```
┌─────────────────────────────────────────────┐
│ Component-Level Tokens                      │
│ (button-primary-background-hover)           │
│ 구체적 용도, 변경 최소                       │
└────────────────┬────────────────────────────┘
                 │
┌─────────────────▼────────────────────────────┐
│ Semantic Tokens                              │
│ (color-brand, color-success, spacing-md)    │
│ 목적-지향적, 언어적 의미                     │
└────────────────┬────────────────────────────┘
                 │
┌─────────────────▼────────────────────────────┐
│ Primitive Tokens (Design Tokens)             │
│ (#FF5733, 16px, 4px 8px 12px 16px)         │
│ 원본 값, 디자인 시스템의 기초                 │
└─────────────────────────────────────────────┘
```

### 2.2 명명 규칙: category-property-variant-state

```
{category}-{property}-{variant}-{state}

예시:
color-brand-primary              (Semantic: Primary Brand)
color-bg-default                 (Semantic: Default Background)
button-primary-background-hover  (Component: Button primary hover bg)
spacing-xs                        (Primitive: Extra Small = 4px)
```

**JSON 토큰 정의 (W3C DTCG 호환):**

```json
{
  "color": {
    "brand": {
      "primary": {
        "$value": "#FF5733",
        "$type": "color",
        "$description": "Primary brand color for interactive elements"
      },
      "secondary": {
        "$value": "#FFC4A3",
        "$type": "color"
      }
    },
    "semantic": {
      "success": {
        "$value": "{color.brand.primary}",
        "$type": "color",
        "$description": "Success state indicator"
      }
    }
  },
  "spacing": {
    "xs": {
      "$value": "4px",
      "$type": "dimension"
    },
    "sm": {
      "$value": "8px",
      "$type": "dimension"
    },
    "md": {
      "$value": "16px",
      "$type": "dimension"
    }
  }
}
```

### 2.3 업계 사례

| 기업 | 토큰 구조 | 특징 |
|------|---------|------|
| **Salesforce (Lightning)** | Primitive → Component | 엔터프라이즈급, tier 분리 명확 |
| **GitHub (Primer)** | Functional → Component | Open source, 커뮤니티 기반 |
| **Atlassian (Tokens)** | Global → Alias → Component | 크로스-플랫폼, dark mode 강점 |
| **Apple (HIG)** | Semantic → Component | 문서화 우수, 하지만 폐쇄적 |

**GitHub Primer 예시:**

```json
{
  "color": {
    "bgCanvas": {
      "$value": "#ffffff",
      "$description": "Primary background color"
    },
    "fgDefault": {
      "$value": "#24292f",
      "$description": "Primary text color"
    },
    "accentBg": {
      "$value": "#0969da",
      "$description": "Accent background"
    }
  }
}
```

---

## 3. W3C DTCG 표준 (2025.10 Stable Release)

### 3.1 표준 개요 및 영향

W3C Design Token Community Group이 2025년 10월 stable release를 발표했습니다. 이는 Cross-platform token 호환성을 보장하며, 업계 표준화의 기초가 됩니다.

**핵심 특징:**
- 📋 JSON 기반 포맷
- 🔗 Token 참조 및 alias 지원
- 🎨 Built-in type system (color, dimension, shadow 등)
- 🌍 Platform-agnostic 설계

### 3.2 JSON 포맷 구조

```json
{
  "token-name": {
    "$value": "actual-value",
    "$type": "type-name",
    "$description": "Human-readable explanation",
    "$extensions": {
      "com.example.custom": "custom-value"
    }
  }
}
```

### 3.3 지원 타입 (Complete Type List)

```
color              #FF5733, hsla(9, 100%, 57%, 1)
dimension          16px, 1.5rem, 40%
fontFamily         "Roboto", serif
fontSize           16px, 1.5rem
fontWeight         400, "bold"
lineHeight         1.5, 24px, 150%
letterSpacing      0.05em, 1px
shadow             0px 4px 8px rgba(0,0,0,0.12)
opacity            1, 0.5
textDecoration     underline
textTransform      uppercase
strokeStyle        solid, dashed
rotation           45deg
transition         200ms ease-in-out
border             1px solid #FF5733
gradient           linear-gradient(90deg, #FF5733 0%, #FFC4A3 100%)
```

### 3.4 참조 (Token References)

```json
{
  "primitives": {
    "color": {
      "red": {
        "$value": "#FF5733",
        "$type": "color"
      }
    }
  },
  "semantic": {
    "color": {
      "error": {
        "$value": "{primitives.color.red}",
        "$type": "color"
      }
    }
  },
  "component": {
    "button": {
      "error": {
        "background": {
          "$value": "{semantic.color.error}",
          "$type": "color"
        }
      }
    }
  }
}
```

### 3.5 호환 도구 생태계 (2025-26)

| 도구 | 버전 | 기능 | 링크 |
|------|------|------|------|
| **Style Dictionary** | 4.x+ | Token 변환, CLI, 플러그인 | github.com/amzn/style-dictionary |
| **Tokens Studio** | 2.0+ | Figma 플러그인, 동기화 | tokens.studio |
| **Parity** | 1.5+ | Token 검증, 성능 분석 | Figma plugin |
| **Specify** | 2.x | Headless token 관리 | specify.app |

---

## 4. 합성 vs 상속 패턴: 현대 철학

### 4.1 합성 (Composition) Philosophy

React와 모던 JavaScript는 **composition over inheritance**를 권장합니다.

**합성 기반 컴포넌트 설계:**

```tsx
// ❌ 상속 기반 (구식)
class PrimaryButton extends Button {
  constructor() {
    super();
    this.style = 'primary';
  }
}

// ✅ 합성 기반 (모던)
const PrimaryButton = (props) => (
  <Button {...props} variant="primary" />
);
```

### 4.2 Slot-based vs Prop-based

**Slot 기반 (복합 구조에 강함):**

```tsx
function Card({ header, body, footer }) {
  return (
    <div className="card">
      <div className="card-header">{header}</div>
      <div className="card-body">{body}</div>
      <div className="card-footer">{footer}</div>
    </div>
  );
}

// 사용
<Card
  header={<h2>Title</h2>}
  body={<p>Content</p>}
  footer={<Button>Action</Button>}
/>
```

**Prop 기반 (단순 구조에 강함):**

```tsx
function Button({ label, size = 'md', variant = 'primary', disabled }) {
  return <button className={`btn btn-${size} btn-${variant}`}>{label}</button>;
}

// 사용
<Button label="Click me" size="lg" variant="primary" disabled={false} />
```

**Best Practice:** 복합도에 따라 혼합 사용.

### 4.3 HOC → Render Props → Hooks 진화

```tsx
// 1️⃣ High-Order Component (2015-2018)
const withAnalytics = (Component) => (props) => {
  useEffect(() => {
    trackComponentView(Component.name);
  }, []);
  return <Component {...props} />;
};

// 2️⃣ Render Props (2017-2020)
<Analytics>
  {(analyticsData) => <Component {...analyticsData} />}
</Analytics>

// 3️⃣ Hooks (2019-현재) ✨ 권장
function Component() {
  const analyticsData = useAnalytics();
  return <div>{/* ... */}</div>;
}
```

### 4.4 CSS Cascade Layers (@layer)

Modern CSS의 계층 구조 관리:

```css
/* 토큰 레이어 */
@layer tokens {
  :root {
    --color-primary: #FF5733;
    --spacing-md: 16px;
  }
}

/* 컴포넌트 레이어 */
@layer components {
  .button {
    background: var(--color-primary);
    padding: var(--spacing-md);
  }

  .button:hover {
    opacity: 0.9;
  }
}

/* 유틸리티 레이어 */
@layer utilities {
  .sr-only {
    position: absolute;
    width: 1px;
    height: 1px;
    overflow: hidden;
  }
}

/* 명시적 스타일 (항상 이기는 계층) */
.button[data-custom] {
  /* 이 스타일은 @layer를 무시함 */
}
```

---

## 5. Design API 개념: Props + Slots + Events + CSS Custom Properties

### 5.1 Design API 정의

컴포넌트의 **공개 계약(public contract)**을 정의합니다.

```typescript
interface ButtonAPI {
  // Props: 행동과 스타일 제어
  props: {
    variant: 'primary' | 'secondary' | 'tertiary';
    size: 'sm' | 'md' | 'lg';
    disabled: boolean;
    loading: boolean;
    fullWidth: boolean;
    onClick: (event: ClickEvent) => void;
  };

  // Slots: 내부 콘텐츠 삽입 포인트
  slots: {
    default: ReactNode;    // 버튼 텍스트
    icon?: ReactNode;      // 아이콘 (선택)
  };

  // Events: 발생하는 이벤트
  events: {
    onClick: ButtonClickEvent;
    onHover: ButtonHoverEvent;
    onFocus: ButtonFocusEvent;
  };

  // CSS Custom Properties: 스타일 오버라이드
  cssVars: {
    '--button-bg-color': string;
    '--button-text-color': string;
    '--button-padding': string;
    '--button-border-radius': string;
  };
}
```

### 5.2 구현 예제

```tsx
// 컴포넌트 정의
export const Button = React.forwardRef<
  HTMLButtonElement,
  ButtonProps
>(({
  variant = 'primary',
  size = 'md',
  disabled = false,
  loading = false,
  fullWidth = false,
  className,
  style,
  children,
  icon,
  onClick,
  ...rest
}, ref) => {
  const [isLoading, setIsLoading] = React.useState(loading);

  const handleClick = async (e: React.MouseEvent<HTMLButtonElement>) => {
    if (!disabled && !isLoading) {
      try {
        setIsLoading(true);
        await onClick?.(e);
      } finally {
        setIsLoading(false);
      }
    }
  };

  return (
    <button
      ref={ref}
      className={classNames(
        'button',
        `button--${variant}`,
        `button--${size}`,
        {
          'button--disabled': disabled,
          'button--loading': isLoading,
          'button--full-width': fullWidth,
        },
        className
      )}
      style={{
        '--button-bg-color': 'var(--color-primary)',
        '--button-text-color': 'var(--color-text-inverse)',
        ...style,
      } as React.CSSProperties}
      disabled={disabled || isLoading}
      onClick={handleClick}
      {...rest}
    >
      {icon && <span className="button__icon">{icon}</span>}
      <span className="button__label">{children}</span>
      {isLoading && <Spinner size="sm" />}
    </button>
  );
});
```

### 5.3 API 설계 원칙

| 원칙 | 설명 | 예시 |
|------|------|------|
| **Single Responsibility** | 하나의 목적만 | Button은 click만, Form은 submission만 |
| **Composition Ready** | 다른 컴포넌트와 결합 가능 | `<Card><Button>...</Button></Card>` |
| **Prop Stability** | Breaking change 최소화 | 새 prop은 선택사항, 기본값 제공 |
| **Accessibility First** | ARIA, 키보드 네비게이션 | `role`, `aria-label`, `onKeyDown` |
| **Extensibility** | 커스터마이제이션 가능 | CSS vars, className override, style prop |

---

## 6. 거버넌스 모델: Nathan Curtis 프레임워크

### 6.1 세 가지 거버넌스 모델

Nathan Curtis (EightShapes)가 정의한 기본 모델:

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  Standalone        Centralized        Federated       │
│  (팀별 독립)       (중앙 집중)        (분산 협력)      │
│  ❌ 중복 증가      ✅ 통일성 강함     ✅ 유연성 강함   │
│                   ❌ 병목 위험        ⚠️ 동기화 어려움 │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 6.2 K-Beauty Startup을 위한 하이브리드 모델

**초기 단계 (Series A):** Centralized
- Design System Team 5명 (Design Lead, 2 Designer, 1 Engineer, 1 PM)
- 모든 컴포넌트 변경사항 중앙 검토
- 주간 Design System Sync 회의

**성장 단계 (Series B):** Federated
- Design System Team (Core)
- Platform Teams (각자 소유권)
- RFC (Request for Comments) 프로세스

### 6.3 RFC 프로세스 (Request for Comments)

**목표:** Major change에 대한 커뮤니티 의견 수렴

**단계:**

```
1️⃣ DRAFT (1주)
   └─ 제안자가 RFC 문서 작성
      - 문제 정의
      - 제안 솔루션
      - 대안 검토
      - Breaking changes 여부

2️⃣ DISCUSSION (1-2주)
   └─ GitHub Discussions / Slack에서 의견 수렴
      - Design 관점
      - Engineering 관점
      - UX 관점

3️⃣ DECISION (1주)
   └─ Design System Lead가 APPROVED/REJECTED 판정
      - APPROVED: Implementation 단계로
      - REJECTED: 반려, 재제안 가능

4️⃣ IMPLEMENTATION (변동)
   └─ 담당자가 구현
      - 단위 테스트
      - 통합 테스트
      - Design 검증

5️⃣ RELEASE
   └─ Package release with changelog
```

**RFC 템플릿:**

```markdown
# RFC-2026-001: 버튼 크기 토큰 표준화

## Summary
현재 Button 컴포넌트의 size prop 값이 일관성 없음.
sm/md/lg 값 통일 및 spacing 토큰 연계.

## Motivation
- 디자인 일관성 저하
- 개발자 혼동 (sm vs small)
- 반응형 처리 어려움

## Detailed Design
```

### 6.4 Conventional Commits 규칙

```
feat(button): add icon slot support
^    ^       ^
│    │       └─ 설명
│    └─────────── 영향 범위 (component name)
└──────────────── 타입 (feat, fix, docs, refactor, test)

BREAKING CHANGE: button.size prop values changed from
'small'/'medium'/'large' to 'sm'/'md'/'lg'
```

**타입 정의:**
- `feat`: 새로운 기능
- `fix`: 버그 수정
- `docs`: 문서화만
- `refactor`: 코드 리팩토링 (행동 변화 없음)
- `test`: 테스트 추가/수정
- `chore`: 빌드, 의존성 등

### 6.5 Deprecation 전략

**3-Phase Deprecation:**

```
Phase 1: DEPRECATED (v1.5.0)
└─ Old API 계속 작동
   console.warn("Button 'small' size is deprecated...")

Phase 2: REMOVAL DATE ANNOUNCED (v2.0.0-beta)
└─ 2025년 12월 제거 예정 공지

Phase 3: REMOVED (v2.1.0)
└─ 완전 제거
   Error: "Button 'small' size removed in v2.1.0"
```

**Deprecation 예제:**

```typescript
export interface ButtonProps {
  size?: 'sm' | 'md' | 'lg' | 'small' | 'medium' | 'large';
  // ↑ 구식 값도 지원하되 warning 발생
}

function Button({ size = 'md', ...props }: ButtonProps) {
  // 구식 값 매핑
  const normalizedSize = {
    'small': 'sm',
    'medium': 'md',
    'large': 'lg',
  }[size as string] || size;

  if (['small', 'medium', 'large'].includes(size as string)) {
    console.warn(
      `[Deprecation Warning] Button size="${size}" is deprecated in v1.5.0. ` +
      `Use size="${normalizedSize}" instead. ` +
      `Will be removed in v2.1.0.`
    );
  }

  return <button className={`btn--${normalizedSize}`}>{/* ... */}</button>;
}
```

### 6.6 채택 메트릭 (Adoption Metrics)

**추적할 지표:**

```
1. Component Usage
   └─ 각 컴포넌트별 사용 빈도 (Google Analytics)
   └─ 목표: 신규 컴포넌트 60% 채택률 (6개월)

2. Token Compliance
   └─ 하드코딩된 색상/크기 개수 (Stylelint)
   └─ 목표: 0 hardcoded values

3. Design Debt
   └─ 레거시 패턴 사용 비율
   └─ 목표: 월 3% 감소

4. Bug Fix Time
   └─ Design system 버그 평균 해결 시간
   └─ 목표: 72시간 이내

5. Design System ROI
   └─ 월간 시간 절감 = (컴포넌트 사용 수) × (재작업 시간 감소)
   └─ 예: 50 컴포넌트 × 2시간 = 100시간/월
```

---

## 7. 크로스 플랫폼 토큰 파이프라인: Figma → Web → iOS → Android

### 7.1 전체 파이프라인 아키텍처

```
┌──────────────────┐
│  Figma Tokens   │ (Tokens Studio 플러그인)
│  (Single Source) │
└────────┬─────────┘
         │
         ▼
┌──────────────────────┐
│  Tokens Studio       │
│  (JSON 생성 & 검증)  │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────────────────────────┐
│  GitHub Repository (Design Tokens)       │
│  └─ tokens/                              │
│     ├─ global.json                       │
│     ├─ color.json                        │
│     ├─ typography.json                   │
│     ├─ spacing.json                      │
│     └─ $themes/                          │
│        ├─ light.json                     │
│        └─ dark.json                      │
└────────┬─────────────────────────────────┘
         │
    ┌────┴────┬─────────────┬──────────────┐
    ▼         ▼             ▼              ▼
  Web      iOS          Android       Design
  (CSS)  (Swift)       (Kotlin)      (Docs)
```

### 7.2 Figma → JSON 자동화

**Tokens Studio 설정:**

```json
// tokens.config.json
{
  "version": "3",
  "exclude": ["node_modules"],
  "platforms": {
    "web": {
      "transformGroup": "web",
      "buildPath": "packages/tokens/web/",
      "files": [
        {
          "destination": "tokens.css",
          "format": "css/variables"
        },
        {
          "destination": "tokens.js",
          "format": "javascript/es6"
        }
      ]
    },
    "ios": {
      "transformGroup": "ios",
      "buildPath": "packages/tokens/ios/",
      "files": [
        {
          "destination": "Design-Tokens.swift",
          "format": "ios/strings.xml"
        }
      ]
    },
    "android": {
      "transformGroup": "android",
      "buildPath": "packages/tokens/android/",
      "files": [
        {
          "destination": "colors.xml",
          "format": "android/colors"
        }
      ]
    }
  }
}
```

### 7.3 Style Dictionary 4.x 구성

```javascript
// config.js
import StyleDictionary from 'style-dictionary';

const myStyleDictionary = new StyleDictionary({
  source: ['tokens/**/*.json'],
  platforms: {
    // Web (CSS)
    web: {
      transformGroup: 'web',
      buildPath: 'build/web/',
      files: [{
        destination: 'tokens.css',
        format: 'css/variables',
        options: {
          outputReferences: true,
        }
      }],
      transforms: [
        'attribute/cti',
        'name/cti/kebab',
        'time/seconds',
        'content/icon',
        'size/px',
        'color/css',
      ]
    },

    // iOS (Swift)
    ios: {
      transformGroup: 'ios',
      buildPath: 'build/ios/',
      files: [{
        destination: 'DesignTokens.swift',
        format: 'ios/assets',
      }]
    },

    // Android (Kotlin)
    android: {
      transformGroup: 'android',
      buildPath: 'build/android/',
      files: [{
        destination: 'colors.xml',
        format: 'android/colors',
      }]
    }
  }
});

await myStyleDictionary.buildAllPlatforms();
```

### 7.4 CI/CD 자동화 (GitHub Actions)

```yaml
# .github/workflows/design-tokens.yml
name: Design Token Release

on:
  workflow_dispatch:
  schedule:
    - cron: '0 10 * * 1'  # 매주 월요일 10:00 (KST 아침)

jobs:
  build-and-release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      packages: write

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          registry-url: 'https://npm.pkg.github.com'

      - name: Install dependencies
        run: npm ci

      - name: Build tokens
        run: npm run tokens:build

      - name: Validate tokens (W3C DTCG)
        run: npm run tokens:validate

      - name: Run tests
        run: npm run test:tokens

      - name: Create version bump
        id: version
        run: |
          VERSION=$(npm run tokens:next-version --silent)
          echo "::set-output name=version::$VERSION"

      - name: Commit and tag
        if: steps.version.outputs.version != ''
        run: |
          git config user.name "Token Release Bot"
          git config user.email "bot@designsystem.local"
          git add -A
          git commit -m "chore(tokens): release v${{ steps.version.outputs.version }}"
          git tag "tokens-v${{ steps.version.outputs.version }}"
          git push origin main --tags

      - name: Publish to npm
        if: steps.version.outputs.version != ''
        env:
          NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: npm publish

      - name: Create GitHub Release
        if: steps.version.outputs.version != ''
        uses: softprops/action-gh-release@v1
        with:
          tag_name: "tokens-v${{ steps.version.outputs.version }}"
          files: |
            build/web/tokens.css
            build/web/tokens.js
```

### 7.5 플랫폼별 출력 예제

**Web (CSS Variables):**

```css
/* tokens.css */
:root {
  --color-brand-primary: #FF5733;
  --color-brand-secondary: #FFC4A3;
  --color-semantic-success: var(--color-brand-primary);
  --color-semantic-error: #DC143C;

  --spacing-xs: 4px;
  --spacing-sm: 8px;
  --spacing-md: 16px;
  --spacing-lg: 24px;

  --typography-body-font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto;
  --typography-body-font-size: 16px;
  --typography-body-line-height: 1.5;

  --shadow-sm: 0px 1px 2px rgba(0, 0, 0, 0.05);
  --shadow-md: 0px 4px 6px rgba(0, 0, 0, 0.1);
}

@media (prefers-color-scheme: dark) {
  :root {
    --color-brand-primary: #FFC4A3;
    --color-bg-default: #1A1A1A;
  }
}
```

**iOS (Swift):**

```swift
// DesignTokens.swift
import UIKit

public enum DesignTokens {
    public enum Color {
        public static let brandPrimary = UIColor(red: 1.0, green: 0.34, blue: 0.2, alpha: 1.0)
        public static let brandSecondary = UIColor(red: 1.0, green: 0.77, blue: 0.64, alpha: 1.0)
        public static let semanticSuccess = Self.brandPrimary
        public static let semanticError = UIColor(red: 0.86, green: 0.08, blue: 0.24, alpha: 1.0)
    }

    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
    }

    public enum Typography {
        public static let bodyFont = UIFont.systemFont(ofSize: 16, weight: .regular)
        public static let bodyLineHeight: CGFloat = 1.5
    }
}
```

**Android (XML):**

```xml
<!-- colors.xml -->
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="color_brand_primary">#FF5733</color>
    <color name="color_brand_secondary">#FFC4A3</color>
    <color name="color_semantic_success">@color/color_brand_primary</color>
    <color name="color_semantic_error">#DC143C</color>

    <!-- Spacing (dimens.xml 파일) -->
    <dimen name="spacing_xs">4dp</dimen>
    <dimen name="spacing_sm">8dp</dimen>
    <dimen name="spacing_md">16dp</dimen>
    <dimen name="spacing_lg">24dp</dimen>
</resources>
```

---

## Design Review Checklist

디자인 시스템 컴포넌트를 검토할 때 사용할 체크리스트:

```markdown
## 신규 컴포넌트 / 변경사항 Design Review

### 아키텍처 & 설계
- [ ] Atomic Design 계층 명확: 위치가 Component/Pattern/Template 중 어디인가?
- [ ] 단일 책임 원칙 준수: 하나의 명확한 목적 보유?
- [ ] 합성 준비 상태: 다른 컴포넌트와 조합 가능한가?
- [ ] 명명 규칙 준수: 일관된 네이밍 사용?

### API 설계
- [ ] Props 명확성: 각 prop의 목적이 명확한가?
- [ ] 기본값 제공: 필수 props 최소화?
- [ ] Slots 정의됨: 콘텐츠 삽입 포인트 명확?
- [ ] Event 문서화: 발생하는 이벤트 명시?
- [ ] CSS 커스터마이제이션: --var 지원?

### 토큰 사용
- [ ] 색상: 하드코드 없음, 모두 토큰 사용?
- [ ] 크기/간격: Spacing 토큰 사용 (px 직접 입력 없음)?
- [ ] Typography: Font family/size/weight 모두 토큰?
- [ ] Shadow/Border: 미리 정의된 토큰만 사용?

### 접근성 (a11y)
- [ ] ARIA 속성: 스크린 리더 지원?
- [ ] 키보드 네비게이션: Tab/Enter/Space 작동?
- [ ] 색상 명도비: WCAG AA 이상 충족?
- [ ] Focus state: 시각적으로 명확?
- [ ] 라벨: 모든 입력 요소에 라벨 연계?

### 반응형
- [ ] 모바일 대응: 모바일 크기에서 적절?
- [ ] 터치 타겟: 최소 48x48px?
- [ ] 유연한 레이아웃: flex/grid 사용?
- [ ] 텍스트 가독성: 작은 화면에서도 읽히는가?

### 다크 모드
- [ ] 색상 토큰: Light/Dark 변형 정의?
- [ ] 명도비: 다크 모드에서도 WCAG 충족?
- [ ] 이미지/아이콘: 다크 모드에서 가시성 확보?

### 성능
- [ ] 번들 크기: 필요한 코드만 포함?
- [ ] 렌더링: 불필요한 리렌더 없는가?
- [ ] 메모리: 메모리 누수 없음?
- [ ] CSS: 셀렉터 깊이 3단계 이하?

### 테스트
- [ ] 단위 테스트: Props 조합별 테스트?
- [ ] 시각 회귀 테스트: 시각적 변화 감지?
- [ ] a11y 테스트: axe-core 등으로 검증?
- [ ] 크로스 브라우저: Chrome/Firefox/Safari?

### 문서화
- [ ] 컴포넌트 스토리: Storybook 스토리 작성?
- [ ] Props 문서: 각 prop 설명 명시?
- [ ] 사용 가이드: 언제 어디서 사용하는가?
- [ ] 코드 예제: 일반적인 사용 사례 제시?

### 크로스 플랫폼
- [ ] Web: React 컴포넌트 구현?
- [ ] iOS: SwiftUI 구현?
- [ ] Android: Compose 구현?
- [ ] 일관성: 플랫폼 간 동작 동일한가?
```

---

## Vibe Coding Guide

"Vibe"란 컴포넌트의 **감성**과 **느낌**을 코드에 반영하는 것입니다.

### 원칙

1. **명확한 의도 (Intent Clarity)**
   ```tsx
   // ❌ 모호함
   <Button className="b1 p-16 h-48" />

   // ✅ 의도 명확
   <Button
     variant="primary"
     size="lg"
     onClick={handleProceed}
   />
   ```

2. **시각적 계층 (Visual Hierarchy)**
   ```tsx
   // 컴포넌트 복잡도가 코드 깊이에 반영

   // 단순 (Depth 1)
   <Button>Simple</Button>

   // 중간 (Depth 2)
   <Card>
     <CardHeader>Title</CardHeader>
     <CardContent>Body</CardContent>
   </Card>

   // 복잡 (Depth 3+, 이 경우 리팩토링 고려)
   <Section>
     <Container>
       <Grid>
         <GridCell>...</GridCell>
       </Grid>
     </Container>
   </Section>
   ```

3. **일관된 간격 (Consistent Spacing)**
   ```tsx
   // ❌ 랜덤한 간격
   <div style={{ marginBottom: '12px' }}>
     <div style={{ marginBottom: '24px' }}>
       <div style={{ marginBottom: '8px' }} />
     </div>
   </div>

   // ✅ 토큰 기반 일관성
   <div style={{ marginBottom: 'var(--spacing-sm)' }}>
     <div style={{ marginBottom: 'var(--spacing-md)' }}>
       <div style={{ marginBottom: 'var(--spacing-xs)' }} />
     </div>
   </div>
   ```

4. **색상의 의미 (Color Semantics)**
   ```tsx
   // ❌ 랜덤한 색상
   style={{ color: '#FF5733', backgroundColor: '#FFC4A3' }}

   // ✅ 의미 있는 색상
   style={{
     color: 'var(--color-text-default)',
     backgroundColor: 'var(--color-bg-featured)'
   }}
   ```

5. **타입 안정성 (Type Safety)**
   ```tsx
   // ❌ 문자열 prop (typo 위험)
   <Button variant="primmary" size="lg" />

   // ✅ Union type (IDE 자동완성, 타입 안정성)
   type ButtonVariant = 'primary' | 'secondary' | 'tertiary';
   <Button variant="primary" size="lg" />
   ```

### 체크리스트

- [ ] 각 prop의 목적이 코드에서 명확한가?
- [ ] 토큰만 사용하고 하드코드된 값이 없는가?
- [ ] 중첩 깊이가 적절한가? (3단계 초과 시 리팩토링)
- [ ] 변수명이 명확하고 자명한가?
- [ ] 타입 안정성이 보장되는가?
- [ ] 주석 없이도 코드 의도가 전달되는가?

---

## 참고 자료 (References)

### 책
- **"Atomic Design"** — Brad Frost (2013)
- **"Design Systems"** — Alla Kholmatova (2019)
- **"System Thinking for Design"** — Kimberlee Arguello & Sophia Voychuk (2021)

### 문서 & 표준
- [W3C Design Tokens Community Group](https://www.w3.org/community/design-tokens/) (2025 spec)
- [Nathan Curtis, "Structured Design Tokens"](https://www.eightshapes.com/)
- [Style Dictionary Documentation](https://amzn.github.io/style-dictionary/)
- [Tokens Studio for Figma](https://tokens.studio/)

### 오픈 소스 프로젝트
- [GitHub Primer (Design System)](https://primer.style/) — 오픈 소스, 정말 학습하기 좋음
- [Salesforce Lightning Design System](https://www.lightningdesignsystem.com/)
- [Atlassian Design System](https://atlassian.design/)
- [Material Design 3](https://m3.material.io/) — 현대 아키텍처 참고

### 팟캐스트 & 커뮤니티
- [Design Systems Podcast](https://www.designsystemspodcast.com/)
- [Design Tokens Community Slack](https://designtokens.org/)

---

**Last Updated**: 2026-02-27
**Maintainer**: Design System Team
**Status**: Active
