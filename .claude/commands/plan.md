---
description: "Manus 스타일 파일 기반 플래닝을 시작합니다. task_plan.md, findings.md, progress.md를 생성하여 복잡한 작업을 체계적으로 관리합니다."
---

Invoke the planning-with-files skill and follow it exactly as presented to you.

Create the three planning files in `docs/plans/` directory if they don't exist:
- task_plan.md — for phases, progress, and decisions
- findings.md — for research and discoveries
- progress.md — for session logging

Then guide the user through the planning workflow.

## Flutter macOS Desktop 프로젝트 구조 참고

계획 수립 시 다음 프로젝트 구조를 기반으로 영향 범위를 파악:

```
lib/
├── core/           # 상수, 테마, DB, 암호화, 라우터, 유틸
│   ├── constants/
│   ├── theme/
│   ├── database/   # Drift 테이블 + DAO
│   ├── encryption/
│   ├── router/
│   └── utils/
├── features/       # 기능별 domain + presentation
│   ├── auth/
│   ├── secrets/
│   ├── audit/
│   └── onboarding/
├── services/       # 윈도우 상태 등 플랫폼 서비스
└── main.dart

test/
├── core/
├── features/
├── helpers/
├── integration/
└── services/
```

기술 스택: Flutter 3.41.2 + Riverpod + Drift + SQLCipher + GoRouter + Material 3
