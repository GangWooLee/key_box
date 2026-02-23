---
name: wrap-up
description: 작업 마무리 — 교훈 추출 + CLAUDE.md 업데이트 + 자동 커밋
---

# /wrap-up

작업 완료 후 자동 마무리를 실행합니다.

## 실행 단계

1. **변경 분석**: `git diff`로 변경된 파일 확인
2. **교훈 추출**: 새로운 패턴/버그/설계 결정 식별
3. **CLAUDE.md 업데이트**: Lessons Learned + 인벤토리 동기화
4. **자동 커밋**: 코드 + 문서 함께 커밋

## 사용법

```
/wrap-up              # 기본 실행
/wrap-up --no-commit  # 커밋 없이 문서만 업데이트
/wrap-up --dry-run    # 변경 사항 미리보기만
```

## 참고

상세 워크플로우: `.claude/skills/wrap-up/SKILL.md`
