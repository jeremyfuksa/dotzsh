# Code Style & Conventions

## Shell Scripts (.sh files)
- **Shebang**: Use `#!/bin/bash` for bash scripts, `#!/bin/sh` for POSIX scripts
- **Error Handling**: Use `set -e` for fail-fast behavior
- **Functions**: Prefix internal functions with `_` (e.g., `_os_detect_log`)
- **Variables**: Use uppercase for exported variables (e.g., `OS_FAMILY`), lowercase for local vars
- **Quoting**: Always quote variables: `"$variable"`
- **Exit Codes**: 0 (success), 1 (warning/optional), 2 (error)

## Zsh Scripts (.zsh files)
- **Shebang**: Use `#!/bin/zsh` or `#!/usr/bin/env zsh`
- **Functions**: Prefix internal helpers with `_motd_` or `_` for private functions
- **Arrays**: Use zsh array syntax: `array=(item1 item2)`
- **Sourcing**: Use `. filename` or `source filename`

## Naming Conventions
- **Files**: lowercase with underscores (e.g., `os_detect.sh`)
- **Functions**: lowercase with underscores (e.g., `install_macos_dependencies`)
- **Private Functions**: prefix with `_` (e.g., `_motd_render_banner`)
- **Variables**: 
  - Exported: `UPPERCASE_WITH_UNDERSCORES`
  - Local: `lowercase_with_underscores`
  - Temp/internal: `_prefixed_with_underscore`

## Comments & Documentation
- **File Headers**: Include purpose, usage, and exit codes
- **Function Documentation**: Describe purpose, parameters, return values
- **Inline Comments**: Explain complex logic, not obvious code

## Error Messages
- **Format**: Use color-coded prefixes
  - `✓` (green) for success
  - `⚠` (yellow) for warnings
  - `✗` (red) for errors
  - `ℹ` (blue) for info
- **Verbosity**: Support `--verbose` flag for debug output
- **Stderr**: Write errors/warnings to stderr (`>&2`)

## Testing
- **Unit Tests**: Place in `test/` directory with descriptive names
- **Test Functions**: Prefix with `test_` (e.g., `test_macos_detection`)
- **Assertions**: Use simple assert functions (no external framework)
- **Exit Codes**: Return 0 for pass, 1 for fail

## Idempotency
- All installation/update scripts must be idempotent (safe to run multiple times)
- Check for existing installations before installing
- Never overwrite without backup
