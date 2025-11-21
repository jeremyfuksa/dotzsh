# Repository Guidelines

## Project Structure & Module Organization
- Franklin now ships as a Python package under `franklin/` (Typer CLI + Rich UI) with dependencies listed in `pyproject.toml` / `requirements.txt`.
- CLI entrypoint: `franklin/src/lib/main.py` (commands: doctor, update, update-all, config, motd) using the Campfire UI helpers in `franklin/src/lib/ui.py`.
- Shared palette/glyph/config constants live in `franklin/src/lib/constants.py`; MOTD rendering is in `franklin/src/lib/motd.py` and reads the root `VERSION` plus `~/.config/franklin/config.env`.
- Shell bootstrap/install wrappers remain in `franklin/src/bootstrap.sh` and `franklin/src/install.sh`; they mirror the Campfire UI hierarchy and handle platform detection, backups, and dependency installs.
- Tests/demos reside in `test/` (UI demo, Sheldon diagnostic); keep scripts idempotent.

## Development Workflow
- Always work in a repo-local venv: `cd franklin && python -m venv .venv && source .venv/bin/activate && pip install -e .`.
- Run the CLI via the installed `franklin` entrypoint or with `PYTHONPATH=franklin/src python -m lib.main ...` during development.
- When editing shell installers, preserve `set -euo pipefail`, quote all variable expansions, and keep FRANKLIN_ROOT/CONFIG paths consistent with `constants.py`/Campfire UI styling.

## Coding Style & UX Conventions
- Use Typer for new commands, keep docstrings short, and route UI/logging through the shared `ui` (CampfireUI) so stdout stays clean for machine-readable output (e.g., `--json`).
- Reuse glyph/color constants; maintain the structured indentation hierarchy (headers → branches → logic) and prefer Rich helpers for prompts/tables.
- Persist config as key/value pairs in `~/.config/franklin/config.env` (`CONFIG_DIR.mkdir(parents=True, exist_ok=True)` before writes); keep MOTD changes within `MOTD_MIN_WIDTH`/`MOTD_MAX_WIDTH` and reuse `load_motd_color`/`render_motd` helpers.
- Shell-side UI should mirror the Python Campfire style (glyphs, stdout/stderr separation) and remain TTY-aware.

## Testing Guidelines
- Add smoke coverage for new Typer commands (`franklin COMMAND --help`, `franklin doctor --json`); keep `test/*.sh` scripts repeatable without privileged installs.
- Prefer dry-run/TTY-safe execution when touching install/update flows; ensure stderr/stdout separation remains intact.

## Commit & Pull Request Guidelines
- Use action-oriented conventional messages (e.g., `feat: add doctor json output`). Include `@codex` in commit bodies when collaborator access is needed and add `Co-authored-by: Codex <codex-noreply@chatgpt.com>` when you author commits.
- Summarize PRs with changes and testing notes; add screenshots for UI-facing tweaks when applicable. Keep `CHANGELOG.md` under `[Unreleased]` up to date and sync `pyproject.toml` / `VERSION` when bumping versions.

## Agent Personas (see .codex/agents/)
- Detailed persona briefs live alongside this repo to keep this file lean:
  - `.codex/agents/cli-architect.md`
  - `.codex/agents/unix-polyglot.md`
  - `.codex/agents/docs-architect.md`
  - `.codex/agents/franklin-architect.md`
- Use **Franklin Architect** when work touches Franklin; combine with the above as needed (CLI for UX/flags, Unix for portability, Docs for information architecture).
