# CLI UX Remediation Plan

## Objective
Eliminate the "ragged", ambiguous CLI output described in `UI-DeepDive.md` by delivering a consistent badge system, correct stream separation, and a stateful task UI across all installer/update scripts.

## Guiding Principles
- **Visibility of system status**: Every action must emit a clearly aligned badge + message.
- **Machine compatibility**: Reserve `stdout` for machine-readable results; route badges/logs to `stderr`.
- **Composable architecture**: Provide a `--quiet/--json` path that suppresses human-friendly logs without altering exit codes.

## Workstreams & Tasks

### 1. Stream Architecture Hardening
1. Inventory scripts that currently print to `stdout` (`scripts/install/*.sh`, `tools/*.py`, `bin/*.js`).
2. Add a shared helper per language (`log.sh`, `cli/logging.py`, `cli/logging.ts`) that:
   - Routes badges to `stderr` by default.
   - Exposes `QUIET` env flag to short-circuit logging.
3. Update every CLI entry point to exclusively emit machine results on `stdout` and human diagnostics on `stderr`.

### 2. Badge & Alignment System
1. Bash: drop in the "Production-Grade Bash Logging Function" (Section IV) and replace ad-hoc `printf` calls.
2. Python: introduce a `rich.Table`-based logger wrapper (`cli/logging.py`) with:
   - Fixed-width badge column (15 chars) and auto-wrapping message column.
   - Helpers for `info`, `await`, `success`, `warn`, `error` that embed icons + semantic colors.
3. Node.js: add a shared `signale` instance configured with Franklin-specific badges and replace all `console.log` badge logic.
4. Document the canonical badge list, formatting rules, and usage in `docs/cli-style.md`.

### 3. Task-Runner UX
1. Identify multi-step flows (e.g., `franklin setup`, `deploy`, `bootstrap`).
2. For Node scripts, wrap sequences with `listr2` so users see pending/active/done states.
3. For Python flows, compose `rich.Progress` + `Table` to mirror the same task dashboard.
4. Ensure failures halt the task list, surface the error detail, and suggest remediation inline.

### 4. Testing & Validation
1. Add snapshot tests (per language) that capture stderr output for success/failure scenarios to guard alignment regressions.
2. Add CI checks that run key scripts with `--quiet` to confirm machine-readable stdout is untouched.
3. Smoke-test in narrow terminals (80 cols) to verify wrapping and truncation rules.

### 5. Rollout Checklist
- [ ] Stream helpers merged & imported everywhere.
- [ ] Badge libraries wired and legacy printf/chalk calls removed.
- [ ] Task-runner UI live for all scripts with ≥3 sequential steps.
- [ ] Docs updated (`UI-DeepDive.md` summary + `cli-style.md`).
- [ ] Tests and CI guards green.

## Timeline (Suggested)
- **Week 1**: Stream audit + helpers, Bash logger rollout.
- **Week 2**: Python rich logger + Node signale adoption.
- **Week 3**: Implement task-runner UX for top 2 flows; add regression tests.
- **Week 4**: Extend to remaining scripts, finalize docs, demo to stakeholders.

## Success Metrics
- Zero scripts emit badges on `stdout` (verified via CI check).
- All user-facing logs share the same badge catalog + alignment.
- Task-based flows show full progress context with ≤1s latency between steps.
- Quiet mode keeps stderr silent while maintaining accurate exit codes.
