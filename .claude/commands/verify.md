---
description: "코드베이스 종합 검증을 실행합니다. 빌드, 린트, 테스트, 보안을 순차 검증합니다. 옵션: quick, full, pre-pr"
---

# 종합 검증 워크플로우

`$ARGUMENTS`에 따라 검증 범위를 결정합니다 (기본: full).

## 검증 순서

순차적으로 실행하며, **빌드 실패 시 즉시 중단**합니다.

### 1. 빌드 검증
```bash
bin/rails runner "puts 'OK'"
```

### 2. 린트 검사 (quick 모드에서는 생략)
```bash
# RuboCop이 설치된 경우
bundle exec rubocop --format simple
```

### 3. 테스트 실행
```bash
# quick 모드
bin/rails test test/models/ test/services/

# full 모드
bin/rails test

# pre-pr 모드
bin/rails test && bin/rails test:system
```

### 4. 보안 스캔 (pre-pr 모드만)
```bash
# Brakeman이 설치된 경우
bundle exec brakeman -q --no-pager

# 하드코딩된 시크릿 검색
grep -rn "password\|secret\|api_key\|token" --include="*.rb" app/ config/ | grep -v "\.example\|test\|spec\|password_digest\|has_secure_password\|password_params\|password_confirmation"
```

### 5. Git 상태 확인
```bash
git status
git diff --stat
```

## 결과 보고서

```
📋 검증 결과 (모드: full)
━━━━━━━━━━━━━━━━━━━━━━━━━━━
빌드:    ✅ / ❌
린트:    ✅ / ❌ / ⏭️ (건너뜀)
테스트:  ✅ X개 통과 / ❌ Y개 실패
보안:    ✅ / ❌ / ⏭️ (건너뜀)
━━━━━━━━━━━━━━━━━━━━━━━━━━━
PR 준비: ✅ 가능 / ❌ 수정 필요
```

## 이슈 보고 기준
- 린트 오류: 파일 경로와 라인 번호
- 테스트 실패: 테스트명과 에러 메시지
- 보안: 파일 위치와 위험 수준
