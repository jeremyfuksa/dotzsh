# Task Completion Checklist

When completing a development task for dotzsh, follow this checklist:

## 1. Code Quality
- [ ] Code follows style conventions (see code_style_conventions.md)
- [ ] Functions are documented with purpose and parameters
- [ ] Error handling is implemented (exit codes, error messages)
- [ ] No hardcoded paths (use variables like `$SCRIPT_DIR`, `$DOTZSH_HOME`)

## 2. Testing
- [ ] Run relevant unit tests: `bash test/_os_detect_tests.sh`
- [ ] Run motd tests if applicable: `bash test/motd-tests.sh`
- [ ] Test on target platform (macOS/Linux)
- [ ] Verify idempotency (run scripts multiple times)
- [ ] Check verbose output: `--verbose` flag

## 3. Cross-Platform Compatibility
- [ ] Test platform detection works correctly
- [ ] Verify POSIX compliance for .sh scripts
- [ ] Check macOS-specific code (Darwin checks)
- [ ] Verify Linux-specific code (distro detection)

## 4. Documentation
- [ ] Update README.md if user-facing changes
- [ ] Update function headers with accurate descriptions
- [ ] Add inline comments for complex logic
- [ ] Update specs if behavior changes

## 5. Integration
- [ ] Source files correctly in `.zshrc`
- [ ] Verify symlinks work correctly
- [ ] Check environment variables are exported
- [ ] Test `reload` command works

## 6. Performance
- [ ] Scripts execute quickly (<100ms for detection)
- [ ] No unnecessary network calls
- [ ] Lazy-loading implemented where appropriate

## 7. Git
- [ ] Meaningful commit message
- [ ] No sensitive data committed
- [ ] `.gitignore` properly configured
- [ ] Branch naming follows convention

## Common Issues to Avoid
- Don't use bash-specific syntax in POSIX .sh files
- Don't forget to export variables that need to be available in shell
- Don't break idempotency (check before creating/installing)
- Don't hardcode paths (use variables)
- Don't assume specific shell environment
