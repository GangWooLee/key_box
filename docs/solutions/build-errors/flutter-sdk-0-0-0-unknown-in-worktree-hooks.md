---
title: Flutter SDK 0.0.0-unknown in linked-worktree git hooks — GIT_DIR poisoning
category: build-errors
module: lefthook
date: 2026-07-19
problem_type: build_error
component: development_workflow
severity: high
symptoms:
  - lefthook pre-commit flutter analyze and pre-push flutter test fail only inside linked git worktrees
  - "Hook output: Building flutter tool then Flutter SDK version reported as 0.0.0-unknown"
  - "pub version solving fails: lucide_icons ^0.257.0 requires Flutter >=1.17.0"
  - Same worktree interactive shell reports Flutter 3.41.2 with clean analyze and green tests
  - Main checkout hooks pass; only linked worktrees are affected
root_cause: config_error
resolution_type: config_change
related_components:
  - tooling
  - testing_framework
tags:
  - git-worktree
  - lefthook
  - flutter-sdk
  - git-dir
  - environment-variables
  - pre-commit-hook
  - version-detection
  - pub-solving
---

# Flutter SDK 0.0.0-unknown in linked-worktree git hooks — GIT_DIR poisoning

## Problem

In a git **linked worktree** (`.claude/worktrees/fervent-saha-37f003`), the lefthook quality gates failed on every run even though the exact same tools worked perfectly in an interactive shell on the same machine.

- lefthook pre-commit `analyze` (`flutter analyze`) and pre-push `tests` (`flutter test`) both aborted with:

```
Building flutter tool...
The current Flutter SDK version is 0.0.0-unknown
Because lucide_icons >=0.257.0 requires Flutter SDK version >=1.17.0 ... version solving failed
exit 1
```

- Meanwhile, an interactive shell on the same machine reported Flutter 3.41.2, `dart analyze` with 0 issues, and 509 tests green.

The failure was **worktree-only, hook-only, and deterministic** — it never reproduced in the main checkout and never reproduced outside a git hook. Because the commit and push were otherwise clean, they were forced through at the time with `LEFTHOOK_EXCLUDE=analyze` for the commit (`d6ad51f`) and `LEFTHOOK=0` for the push, double-checked against GHA CI. That is a workaround, not a fix — the gates were disabled rather than repaired.

## Symptoms

- Flutter reports its own version as `0.0.0-unknown` **only** when invoked from a git hook inside a linked worktree.
- Every hook run prints `Building flutter tool...` — the SDK rebuilds its tool snapshot on each invocation instead of using the cached one.
- Any `pub` constraint (e.g. `lucide_icons` requiring `Flutter >=1.17.0`) fails version solving because `0.0.0-unknown` satisfies nothing.
- Identical commands succeed in an interactive (login) shell and in the main checkout's hooks.
- `dart format` (the other hook step) is exposed to the same failure mode because `bin/dart` shares the same wrapper path.

## What Didn't Work

Three plausible causes were investigated and each was empirically ruled out:

- **PATH divergence** (a non-login hook shell missing `~/.zprofile`, resolving a different Flutter). Ruled out: the hook environment resolves the same single `/opt/homebrew/bin/flutter` (Homebrew cask → `/opt/homebrew/share/flutter`), and its version stamps plus `git describe` all say 3.41.2. The binary was never the problem.
- **fvm / puro / mise-managed Flutter remnants** shadowing the real SDK. Ruled out: `mise` manages only Ruby (the lefthook gem); there are no flutter shims anywhere on the path.
- **A second, stamp-less Flutter git checkout on disk** being picked up. Ruled out: a disk search found no other SDK copy.

The common thread: everyone assumed the *wrong binary* was being found. The binary was correct — its *environment* was poisoned.

## Solution

Git exports its own environment variables into hook processes, and in a linked worktree those exports are absolute paths that leak into any subprocess that runs git — including the Flutter SDK's own wrapper script.

**Root cause chain (each step verified):**

1. In a **linked worktree**, git exports an absolute `GIT_DIR=<repo>/.git/worktrees/<name>` (and absolute `GIT_INDEX_FILE`) to pre-commit hooks, and an absolute `GIT_DIR` to pre-push hooks. In the **main checkout**, no `GIT_DIR` is exported at all (pre-commit gets only a relative `GIT_INDEX_FILE=.git/index`; pre-push gets neither). Verified with a scratch repo whose hooks dump `env | grep ^GIT_`.
2. The Flutter SDK wrapper `/opt/homebrew/share/flutter/bin/internal/shared.sh:124` computes:

```sh
local revision="$(cd "$FLUTTER_ROOT"; git rev-parse HEAD)"
```

`GIT_DIR` overrides cwd-based repo discovery, so even after `cd "$FLUTTER_ROOT"` this `git rev-parse HEAD` reads **key_box's** `GIT_DIR`, returning key_box's HEAD instead of Flutter's revision. Verified directly:

```sh
GIT_DIR=<worktree-gitdir> git -C /opt/homebrew/share/flutter rev-parse HEAD    # → key_box HEAD (108cc96...)
GIT_DIR=<worktree-gitdir> git -C /opt/homebrew/share/flutter describe --tags   # → fatal: cannot describe anything
```

(Flutter's real revision is `90673a4eef...`; key_box has no tags, hence the `describe` failure.)

3. The revision the wrapper computes no longer matches the `bin/cache` stamp, so Flutter rebuilds its tool (`Building flutter tool...`) on every hook run. The rebuilt tool derives the SDK version via git against the effectively tag-less key_box repo → `0.0.0-unknown` → any `pub` constraint fails version solving.
4. `bin/dart` runs the same `shared::execute` → `upgrade_flutter` path (unconditional, `shared.sh:262`), so the `dart format` hook step is equally exposed.

**The fix** — strip the leaked git env vars from each tool invocation in `lefthook.yml`:

```yaml
# before
    analyze:
      glob: "*.dart"
      run: flutter analyze
```

```yaml
# after
    analyze:
      glob: "*.dart"
      run: env -u GIT_DIR -u GIT_INDEX_FILE -u GIT_WORK_TREE flutter analyze
```

The same `env -u GIT_DIR -u GIT_INDEX_FILE -u GIT_WORK_TREE` prefix was applied to the `dart format --set-exit-if-changed {staged_files}` and `flutter test` commands.

**Design decisions worth capturing:**

- **Scoped per-command, not a global `unset`.** Stripping these vars in a global lefthook `rc` file would break lefthook's own `{staged_files}` computation, which uses git and needs the intact hook env. In particular `GIT_INDEX_FILE` can point at a *temporary* index during `git commit --only` flows; stripping it globally could make the format gate inspect the wrong snapshot. Only the tool subprocess that misuses the env gets it removed.
- **`env -u NAME` on an unset variable is a no-op**, so main-checkout behavior (where `GIT_DIR` is never exported) is entirely unchanged. macOS `/usr/bin/env` supports `-u`.

## Why This Works

The bug is not "wrong Flutter" — it is "right Flutter, poisoned environment." The SDK wrapper trusts ambient `GIT_DIR`/`GIT_INDEX_FILE`/`GIT_WORK_TREE` when it shells out to git to identify its own revision. `env -u` removes exactly those variables for the tool process, so the wrapper's `git rev-parse HEAD` falls back to normal cwd-based discovery inside `$FLUTTER_ROOT` and reads Flutter's real revision again. No stamp mismatch → no rebuild → correct `3.41.2` version → `pub` version solving succeeds.

**Verification performed:**

- **Poisoned-env simulation** from a real worktree, exporting `GIT_DIR`/`GIT_INDEX_FILE` exactly as git does: the fixed command form reported Flutter 3.41.2 with no tool rebuild. The control (no `env -u`) reproduced the wrapper's git call returning key_box HEAD — i.e. the poison is present and the fix neutralizes it.
- **Mutation proof of the restored gate.** A fresh worktree first needed `dart run build_runner build --delete-conflicting-outputs` — `*.g.dart` is gitignored, so without codegen `flutter analyze` shows 648 pre-existing errors (the same class of gap as CI fix `f425aa1`). After codegen, baseline `flutter analyze` = 0 issues. A single injected `undefined_identifier` probe made a real `git commit` attempt block **RED** with exactly that one error, dart-format green, HEAD unchanged — proving the gate actually gates. The pre-push command form ran green under poison on a test file (21 tests).

A gate that has only ever been observed green is decoration; this one was shown to fail on a real defect and pass without one.

## Prevention

- **Diagnostic signature → suspect git's hook env, not PATH.** A gate that fails **only** inside git hooks and **only** in linked worktrees, accompanied by tool-version weirdness, points at git's exported `GIT_DIR`/`GIT_INDEX_FILE`/`GIT_WORK_TREE`, not at PATH resolution. Quick checks:

```sh
# from inside a hook:
env | grep ^GIT_
# or reproduce directly:
GIT_DIR=$(git rev-parse --absolute-git-dir) <tool> --version
```

- **Guard any hook command that invokes a tool wrapping its own git repo.** Flutter's SDK, other SDKs installed as git checkouts, and git-based version managers all run git internally and will inherit the leaked env. Prefix such hook commands with `env -u GIT_DIR -u GIT_INDEX_FILE -u GIT_WORK_TREE`.
- **Scope the strip to the tool, never globally.** lefthook's own git operations (e.g. `{staged_files}`, `--only` temporary indexes) depend on the intact hook env; a global `unset` risks gating the wrong snapshot.
- **Fresh-worktree prerequisite:** run `dart run build_runner build --delete-conflicting-outputs` before expecting `analyze`/`tests` to pass — `*.g.dart` is gitignored, so a fresh checkout has no generated code and analyze will drown in errors.
- **Mutation-test gates after repairing them.** Inject a known defect, confirm the gate goes RED on the real commit/push path, then remove it — otherwise a "fixed" gate may just be silently permissive.

## Related Issues

- `lefthook.yml` — the fixed artifact (all three SDK-invoking hook commands carry the `env -u` prefix, with a why-comment at the top).
- `.claude/rules/common/git-workflow.md` — "Git Worktrees (병렬 개발)" section recommends worktrees but does not warn about hook env leakage; this doc is the missing caveat.
- CI fix `f425aa1` — same fresh-checkout `*.g.dart` gap on the GHA side (build_runner step was missing); GHA runners are unaffected by the GIT_DIR issue itself (no worktree, no hook).
- Bypass record: commit `d6ad51f` (`LEFTHOOK_EXCLUDE=analyze`) and the accompanying `LEFTHOOK=0` push — obsolete once this fix is merged.
