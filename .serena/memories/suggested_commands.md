# Suggested Commands for dotzsh Development

## Testing
```bash
# Run platform detection tests
bash test/_os_detect_tests.sh

# Run motd helper tests
bash test/motd-tests.sh

# Run installation smoke tests
bash test/test_install.sh

# Run end-to-end tests
bash test/smoke.zsh
```

## Installation
```bash
# Fresh install
bash install.sh

# Verbose install
bash install.sh --verbose
```

## Updates
```bash
# Update all components
bash update-all.sh

# Verbose update
bash update-all.sh --verbose
```

## Development
```bash
# Reload shell after changes
source .zshrc
# or
reload

# Test platform detection manually
bash lib/os_detect.sh --json
bash lib/os_detect.sh --verbose
```

## Git Operations
```bash
# Standard git commands
git status
git add .
git commit -m "message"
git push
```

## macOS Specific
```bash
# Homebrew commands
brew update
brew upgrade
```

## Debugging
- Set `VERBOSE=1` for verbose output in install/update scripts
- Use `--verbose` flag with platform detection scripts
- Check `/tmp/os_detect_test.out` for test artifacts
