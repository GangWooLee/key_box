# Phase 5 — 컴포넌트 설계 원칙

## 개요

컴포넌트 설계는 단순한 UI 요소 조립이 아닌, 견고한 시스템 아키텍처를 구축하는 핵심 역량입니다. 성숙한 디자인 시스템은 합성 가능한(composable) 컴포넌트, 접근 가능한(accessible) 상호작용, 그리고 예측 가능한 상태 관리를 통해 제품의 일관성과 개발 생산성을 동시에 달성합니다.

이 문서는 React 기반 현대 웹 애플리케이션에서 엔터프라이즈급 컴포넌트를 설계하고 구현하기 위한 원칙과 실전 패턴을 다룹니다.

---

## 1. 합성 컴포넌트 패턴 (Compound Components)

### 1.1 개념과 장점

합성 컴포넌트 패턴은 여러 작은 컴포넌트가 상호작용하면서 기능을 제공하는 구조입니다. React Context를 통해 부모-자식 컴포넌트 간 상태를 암묵적으로 공유하며, 복잡한 prop drilling을 회피합니다.

**주요 장점:**
- **표현적 API**: `<Select><SelectTrigger /><SelectContent /></Select>` 형태로 의도가 명확함
- **유연성**: 자식 컴포넌트의 순서 및 조합 변경 가능
- **캡슐화**: 내부 상태 관리가 은폐되고 외부 인터페이스만 노출

### 1.2 구현 비교: Radix UI vs React Aria vs Headless UI

| 라이브러리 | 접근성 | 상태관리 | 스타일링 | 번들크기 |
|----------|-------|---------|---------|---------|
| **Radix UI** | WAI-ARIA APG 완벽준수 | 자체 로직 | CSS-in-JS 친화 | ~45KB |
| **React Aria** (Adobe) | ARIA spec 기준 | 훅 기반 | Tailwind 최적화 | ~65KB |
| **Headless UI** | 제한적 ARIA | Headless 최소화 | 스타일링 자유 | ~22KB |

### 1.3 Select 컴포넌트 구현 예제

```jsx
// Context 정의
const SelectContext = React.createContext(undefined);

export function Select({ value, onValueChange, children }) {
  const [open, setOpen] = React.useState(false);
  const [highlightedIndex, setHighlightedIndex] = React.useState(0);

  const contextValue = React.useMemo(
    () => ({
      value,
      onValueChange,
      open,
      setOpen,
      highlightedIndex,
      setHighlightedIndex,
    }),
    [value, onValueChange, open, highlightedIndex]
  );

  return (
    <SelectContext.Provider value={contextValue}>
      <div className="select-root" role="combobox">
        {children}
      </div>
    </SelectContext.Provider>
  );
}

function useSelectContext() {
  const context = React.useContext(SelectContext);
  if (!context) {
    throw new Error('Select 컴포넌트 내에서만 사용 가능합니다.');
  }
  return context;
}

export function SelectTrigger({ className, children, ...props }) {
  const { open, setOpen, value } = useSelectContext();
  const triggerRef = React.useRef(null);

  return (
    <button
      ref={triggerRef}
      className={`select-trigger ${className}`}
      onClick={() => setOpen(!open)}
      aria-haspopup="listbox"
      aria-expanded={open}
      {...props}
    >
      {children || value}
      <ChevronIcon aria-hidden="true" />
    </button>
  );
}

export function SelectContent({ className, ...props }) {
  const { open, value, onValueChange, setOpen } = useSelectContext();
  const contentRef = React.useRef(null);

  React.useEffect(() => {
    if (!open) return;

    const handleKeyDown = (e) => {
      switch (e.key) {
        case 'ArrowDown':
          e.preventDefault();
          break;
        case 'ArrowUp':
          e.preventDefault();
          break;
        case 'Enter':
          e.preventDefault();
          break;
        case 'Escape':
          setOpen(false);
          break;
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [open, setOpen]);

  if (!open) return null;

  return (
    <div
      ref={contentRef}
      className={`select-content ${className}`}
      role="listbox"
      {...props}
    >
      {/* SelectItem children 렌더링 */}
    </div>
  );
}

export function SelectItem({ value, children, disabled = false }) {
  const { value: selectedValue, onValueChange } = useSelectContext();

  return (
    <div
      role="option"
      aria-selected={selectedValue === value}
      aria-disabled={disabled}
      onClick={() => !disabled && onValueChange(value)}
      className={`select-item ${selectedValue === value ? 'selected' : ''} ${
        disabled ? 'disabled' : ''
      }`}
    >
      {children}
    </div>
  );
}

// 사용 예
export default function Demo() {
  const [selected, setSelected] = React.useState('option1');

  return (
    <Select value={selected} onValueChange={setSelected}>
      <SelectTrigger />
      <SelectContent>
        <SelectItem value="option1">Option 1</SelectItem>
        <SelectItem value="option2">Option 2</SelectItem>
        <SelectItem value="option3" disabled>
          Option 3 (disabled)
        </SelectItem>
      </SelectContent>
    </Select>
  );
}
```

---

## 2. 접근성 우선 컴포넌트 설계

### 2.1 WAI-ARIA APG 패턴

WAI-ARIA Authoring Practices Guide는 W3C의 표준 패턴 라이브러리입니다. 컴포넌트 설계 시 다음을 필수로 확인하세요:

**Dialog (Modal) 패턴:**
- `role="dialog"` 또는 `role="alertdialog"`
- `aria-modal="true"`
- `aria-labelledby` (제목 연결)
- 초기 포커스 설정 (보통 첫 입력 또는 닫기 버튼)
- Escape 키로 닫기 / Focus trap (포커스 순환)

**Combobox (자동완성) 패턴:**
- `role="combobox"` (trigger에 적용)
- `aria-owns="listbox-id"` (리스트와 trigger 연결)
- `aria-autocomplete="list"` 또는 `"both"`
- `aria-expanded` (목록 열림 상태)
- 키보드 네비게이션: ArrowUp/Down, Enter, Escape

### 2.2 포커스 관리 (Focus Management)

```jsx
// FocusTrap 훅 구현
export function useFocusTrap(initialFocusRef, finalFocusRef) {
  const containerRef = React.useRef(null);

  React.useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    const focusableElements = container.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );

    const firstElement = focusableElements[0];
    const lastElement = focusableElements[focusableElements.length - 1];

    const handleKeyDown = (e) => {
      if (e.key !== 'Tab') return;

      if (e.shiftKey) {
        if (document.activeElement === firstElement) {
          e.preventDefault();
          lastElement?.focus();
        }
      } else {
        if (document.activeElement === lastElement) {
          e.preventDefault();
          firstElement?.focus();
        }
      }
    };

    // 초기 포커스 설정
    (initialFocusRef?.current || firstElement)?.focus();

    container.addEventListener('keydown', handleKeyDown);
    return () => {
      container.removeEventListener('keydown', handleKeyDown);
      finalFocusRef?.current?.focus();
    };
  }, []);

  return containerRef;
}

// Dialog 예제
export function Modal({ isOpen, onClose, title, children }) {
  const dialogRef = useFocusTrap();
  const closeButtonRef = React.useRef(null);

  if (!isOpen) return null;

  return (
    <>
      <div className="modal-overlay" onClick={onClose} />
      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby="modal-title"
        className="modal"
      >
        <h2 id="modal-title">{title}</h2>
        {children}
        <button ref={closeButtonRef} onClick={onClose}>
          Close
        </button>
      </div>
    </>
  );
}
```

### 2.3 Screen Reader 호환성

```jsx
// 숨겨진 라벨 (visually hidden)
const visuallyHidden = {
  position: 'absolute',
  width: '1px',
  height: '1px',
  padding: '0',
  margin: '-1px',
  overflow: 'hidden',
  clip: 'rect(0, 0, 0, 0)',
  whiteSpace: 'nowrap',
  borderWidth: '0',
};

export function HiddenLabel({ htmlFor, children }) {
  return (
    <label htmlFor={htmlFor} style={{ all: 'unset', ...visuallyHidden }}>
      {children}
    </label>
  );
}

// 상태 공지 (Live Region)
export function Toast({ message, type = 'info' }) {
  return (
    <div
      role="status"
      aria-live="polite"
      aria-atomic="true"
      className={`toast toast-${type}`}
    >
      {message}
    </div>
  );
}

// 로딩 상태 공지
export function LoadingSpinner({ ariaLabel = 'Loading' }) {
  return (
    <div role="status" aria-label={ariaLabel}>
      <div className="spinner" aria-hidden="true" />
    </div>
  );
}
```

---

## 3. 상태 관리 패턴

### 3.1 컴포넌트 상태 분류

UI 컴포넌트는 다음 7가지 상태를 갖습니다:

```
default → hover → focus → active → {disabled, loading, error, success}
```

**예: Button 컴포넌트**

```jsx
// 상태 정의
const BUTTON_STATES = {
  DEFAULT: 'default',
  HOVER: 'hover',
  FOCUS: 'focus',
  ACTIVE: 'active',
  DISABLED: 'disabled',
  LOADING: 'loading',
};

export function Button({
  variant = 'primary',
  size = 'md',
  disabled = false,
  isLoading = false,
  children,
  onClick,
  ...props
}) {
  const [state, setState] = React.useState(BUTTON_STATES.DEFAULT);

  const handleMouseEnter = () => setState(BUTTON_STATES.HOVER);
  const handleMouseLeave = () => setState(BUTTON_STATES.DEFAULT);
  const handleFocus = () => setState(BUTTON_STATES.FOCUS);
  const handleBlur = () => setState(BUTTON_STATES.DEFAULT);
  const handleMouseDown = () => setState(BUTTON_STATES.ACTIVE);
  const handleMouseUp = () => setState(BUTTON_STATES.HOVER);

  const finalState = isLoading ? BUTTON_STATES.LOADING : disabled ? BUTTON_STATES.DISABLED : state;

  return (
    <button
      className={`btn btn-${variant} btn-${size} btn-${finalState}`}
      disabled={disabled || isLoading}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      onFocus={handleFocus}
      onBlur={handleBlur}
      onMouseDown={handleMouseDown}
      onMouseUp={handleMouseUp}
      onClick={onClick}
      aria-busy={isLoading}
      {...props}
    >
      {isLoading ? <Spinner size="sm" /> : children}
    </button>
  );
}
```

### 3.2 XState를 이용한 상태 머신

복잡한 UI(예: 결제 플로우)는 Finite State Machine으로 관리하면 버그를 줄일 수 있습니다.

```jsx
import { createMachine, interpret } from 'xstate';

const checkoutMachine = createMachine({
  id: 'checkout',
  initial: 'idle',
  states: {
    idle: {
      on: { START: 'validating' },
    },
    validating: {
      on: {
        VALID: 'processing',
        INVALID: 'error',
      },
    },
    processing: {
      on: {
        SUCCESS: 'success',
        FAILURE: 'error',
      },
    },
    error: {
      on: { RETRY: 'validating' },
    },
    success: {
      type: 'final',
    },
  },
});

export function useCheckout() {
  const [state, setState] = React.useState(checkoutMachine.initialState);
  const machineService = React.useRef(interpret(checkoutMachine).start());

  React.useEffect(() => {
    machineService.current.onTransition((nextState) => {
      setState(nextState);
    });
  }, []);

  return {
    state: state.value,
    send: (event) => machineService.current.send(event),
  };
}
```

---

## 4. 폼 컴포넌트 설계

### 4.1 Inline Validation 전략

Luke Wroblewski의 연구에 따르면, **inline validation은 폼 완성률을 22% 향상**시킵니다.

```jsx
export function FormField({ label, type, value, onChange, onBlur, errors, ...props }) {
  const [touched, setTouched] = React.useState(false);
  const hasError = touched && errors?.length > 0;

  const handleBlur = (e) => {
    setTouched(true);
    onBlur?.(e);
  };

  return (
    <div className="form-field">
      <label htmlFor={props.id}>{label}</label>
      <input
        type={type}
        value={value}
        onChange={onChange}
        onBlur={handleBlur}
        aria-invalid={hasError}
        aria-describedby={hasError ? `${props.id}-error` : undefined}
        className={`input ${hasError ? 'input-error' : ''}`}
        {...props}
      />
      {hasError && (
        <span id={`${props.id}-error`} className="error-message" role="alert">
          {errors[0]}
        </span>
      )}
    </div>
  );
}

// 활용 예
export function RegistrationForm() {
  const [email, setEmail] = React.useState('');
  const [errors, setErrors] = React.useState([]);

  const validateEmail = (value) => {
    const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return regex.test(value) ? [] : ['Valid email required'];
  };

  const handleEmailChange = (e) => {
    const value = e.target.value;
    setEmail(value);
    if (value) {
      setErrors(validateEmail(value));
    }
  };

  return (
    <form>
      <FormField
        id="email"
        label="Email"
        type="email"
        value={email}
        onChange={handleEmailChange}
        errors={errors}
      />
    </form>
  );
}
```

### 4.2 에러 메시지 전략

```jsx
// 에러 메시지 우선순위
const ERROR_PRIORITIES = {
  required: 'This field is required',
  pattern: 'Invalid format',
  minLength: 'Too short',
  maxLength: 'Too long',
  custom: 'Invalid value',
};

export function getFirstError(errors) {
  if (!errors || errors.length === 0) return null;

  const sorted = Object.entries(ERROR_PRIORITIES).sort(([, aPri], [, bPri]) => {
    return Object.values(ERROR_PRIORITIES).indexOf(aPri) -
           Object.values(ERROR_PRIORITIES).indexOf(bPri);
  });

  for (const [key] of sorted) {
    if (errors[key]) return errors[key];
  }

  return errors.custom || 'Invalid input';
}
```

---

## 5. 반응형 컴포넌트 전략

### 5.1 Container Query 기반 설계

CSS Container Query는 뷰포트가 아닌 부모 컨테이너 크기에 반응합니다. 컴포넌트를 어디든 배치해도 자동 적응합니다.

```css
/* 부모 컨테이너를 쿼리 대상으로 설정 */
.card-container {
  container-type: inline-size;
}

/* 400px 이상일 때 */
@container (min-width: 400px) {
  .card {
    display: flex;
    flex-direction: row;
  }
}

/* 400px 미만일 때 */
@container (max-width: 399px) {
  .card {
    display: flex;
    flex-direction: column;
  }
}
```

### 5.2 컴포넌트 API 설계: Props vs Slots vs Variants

```jsx
// Variants 패턴 (Tailwind, shadcn/ui 방식)
export const buttonVariants = {
  primary: 'bg-blue-600 text-white',
  secondary: 'bg-gray-200 text-gray-900',
  ghost: 'bg-transparent text-gray-700',
};

export function Button({ variant = 'primary', size = 'md', className, ...props }) {
  return (
    <button
      className={`btn btn-${size} ${buttonVariants[variant]} ${className}`}
      {...props}
    />
  );
}

// Slots 패턴 (더 큰 유연성)
export function Card({ header, body, footer, className }) {
  return (
    <div className={`card ${className}`}>
      {header && <div className="card-header">{header}</div>}
      {body && <div className="card-body">{body}</div>}
      {footer && <div className="card-footer">{footer}</div>}
    </div>
  );
}

// Composition 패턴 (최고 유연성)
export function Card({ children, className }) {
  return <div className={`card ${className}`}>{children}</div>;
}

export function CardHeader({ children, className }) {
  return <div className={`card-header ${className}`}>{children}</div>;
}

export function CardBody({ children, className }) {
  return <div className={`card-body ${className}`}>{children}</div>;
}
```

---

## 6. 컴포넌트 문서화 (Storybook)

### 6.1 Storybook 기본 구조

```jsx
// Button.stories.jsx
import { Button } from './Button';

export default {
  title: 'Components/Button',
  component: Button,
  argTypes: {
    variant: {
      control: { type: 'select' },
      options: ['primary', 'secondary', 'ghost'],
    },
    size: {
      control: { type: 'select' },
      options: ['sm', 'md', 'lg'],
    },
    disabled: { control: { type: 'boolean' } },
    isLoading: { control: { type: 'boolean' } },
    onClick: { action: 'clicked' },
  },
};

export const Primary = {
  args: {
    variant: 'primary',
    children: 'Click me',
  },
};

export const Disabled = {
  args: {
    variant: 'primary',
    disabled: true,
    children: 'Disabled',
  },
};

export const Loading = {
  args: {
    variant: 'primary',
    isLoading: true,
    children: 'Loading...',
  },
};
```

### 6.2 Interaction Testing

```jsx
// Button.stories.jsx (Playwright 통합)
export const ClickHandler = {
  args: { children: 'Click me' },
  play: async ({ canvasElement }) => {
    const button = canvasElement.querySelector('button');
    expect(button).toBeInTheDocument();
    await userEvent.click(button);
  },
};
```

---

## 디자인 리뷰 체크리스트

컴포넌트 PR/MR 시 다음을 검증하세요:

### 기능성 (Functionality)
- [ ] 모든 상태 조합이 정상 작동하는가? (default, hover, focus, active, disabled, loading, error)
- [ ] Edge case 처리: 긴 텍스트, 특수문자, 빈 값, null/undefined
- [ ] 성능: 불필요한 리렌더링 없는가? (React.memo, useMemo 활용)

### 접근성 (Accessibility)
- [ ] WAI-ARIA 역할(role), 상태(aria-*) 올바른가?
- [ ] 키보드 네비게이션 완전한가? (Tab, Arrow, Enter, Escape)
- [ ] Screen reader 테스트 완료? (NVDA, JAWS, VoiceOver)
- [ ] 색상 대비율 4.5:1 이상? (WCAG AA 기준)
- [ ] 포커스 표시 가시적인가?

### 반응형 (Responsive)
- [ ] Mobile, Tablet, Desktop에서 정상 표시?
- [ ] 텍스트 크기 조정(200%)에도 레이아웃 유지?
- [ ] Touch target 최소 44x44px?

### 문서화 (Documentation)
- [ ] Storybook 스토리 모두 작성?
- [ ] Props 설명서 완전한가?
- [ ] 사용 예제 2개 이상?
- [ ] 접근성 주의사항 명시?

### 성능 (Performance)
- [ ] 번들 크기 증가 최소화?
- [ ] 불필요한 의존성 없는가?
- [ ] SSR 호환성 검증?

---

## Vibe Coding Guide: 컴포넌트 개발의 느낌

컴포넌트 설계는 기술 이상의 감각입니다. 다음은 경험 많은 개발자의 직관입니다:

**1. 작게 생각하라**
- 컴포넌트는 한 가지 책임만 가져야 합니다.
- Button vs PrimaryButton + SecondaryButton: 전자가 더 우수합니다.

**2. 합성을 위해 설계하라**
- 컴포넌트는 조합 가능한 상태여야 합니다.
- 자식 컴포넌트를 제약하지 않으세요. 대신 명확한 인터페이스를 제공하세요.

**3. 상태 관리를 단순하게 하라**
- 부모가 상태를 소유하고 자식은 표현만 담당합니다 (presentational component).
- State machine을 과신하지 마세요. 대부분의 UI는 단순한 상태 객체로 충분합니다.

**4. 접근성을 마지막이 아닌 처음부터 설계하라**
- ARIA는 마크업 수리 도구가 아닙니다. 의미있는 HTML을 먼저 작성하세요.
- div role="button" 대신 button 사용.

**5. 문서화는 코드보다 먼저**
- Storybook 스토리를 먼저 작성하고, 구현은 그 다음.
- 어떻게보다 왜를 설명하세요.

---

## 참고 자료

- WAI-ARIA Authoring Practices Guide: https://www.w3.org/WAI/ARIA/apg/
- Radix UI Primitives: https://www.radix-ui.com/
- Adobe React Aria: https://react-spectrum.adobe.com/react-aria/
- XState Documentation: https://stately.ai/docs/xstate
- Luke Wroblewski - Web Form Design: Forms that work
- CSS Container Queries: https://developer.mozilla.org/en-US/docs/Web/CSS/container-query
- Storybook Official Docs: https://storybook.js.org/

---

## 버전 이력

| 버전 | 날짜 | 변경 사항 |
|------|------|---------|
| 1.0 | 2026-02-27 | 초판 작성 |
