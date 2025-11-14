#!/bin/bash
# Smoke Test: Platform Detection Acceptance Test
#
# Runs acceptance tests for platform detection on the current system.
# Tests that OS_FAMILY and HAS_HOMEBREW are correctly exported.
#
# Usage: bash test/smoke.zsh

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Utilities
_assert_equals() {
  local expected="$1"
  local actual="$2"
  local msg="$3"

  ((TESTS_RUN++))

  if [ "$expected" = "$actual" ]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓ PASS${NC}: $msg"
    echo "  Expected: $expected"
    echo "  Actual:   $actual"
  else
    ((TESTS_FAILED++))
    echo -e "${RED}✗ FAIL${NC}: $msg"
    echo "  Expected: $expected"
    echo "  Actual:   $actual"
  fi
}

_assert_set() {
  local var_name="$1"
  local msg="$2"

  ((TESTS_RUN++))

  # Use indirect variable reference compatible with bash
  local var_value
  eval "var_value=\$$var_name"

  if [ -n "$var_value" ]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓ PASS${NC}: $msg"
    echo "  Variable $var_name = $var_value"
  else
    ((TESTS_FAILED++))
    echo -e "${RED}✗ FAIL${NC}: $msg"
    echo "  Variable $var_name is not set"
  fi
}

# ============================================================================
# Smoke Tests
# ============================================================================

echo "=========================================="
echo "Platform Detection Smoke Test"
echo "=========================================="
echo ""

# Test 1: Source os_detect.zsh
echo "Test 1: Sourcing lib/os_detect.zsh"
source lib/os_detect.zsh >/dev/null 2>&1
exit_code=$?

if [ $exit_code -eq 0 ]; then
  echo -e "${GREEN}✓ Sourcing succeeded${NC} (exit code $exit_code)"
else
  echo -e "${YELLOW}⊘ WARNING${NC}: Sourcing returned exit code $exit_code (may indicate fallback)"
fi
echo ""

# Test 2: Verify OS_FAMILY is set
_assert_set OS_FAMILY "OS_FAMILY variable is exported"

# Test 3: Verify OS_FAMILY is valid
valid_families="macos ubuntu debian fedora"
if echo "$valid_families" | grep -q "$OS_FAMILY"; then
  ((TESTS_RUN++))
  ((TESTS_PASSED++))
  echo "${GREEN}✓ PASS${NC}: OS_FAMILY has valid value"
  echo "  OS_FAMILY = $OS_FAMILY"
else
  ((TESTS_RUN++))
  ((TESTS_FAILED++))
  echo "${RED}✗ FAIL${NC}: OS_FAMILY has invalid value: $OS_FAMILY"
fi

# Test 4: Verify HAS_HOMEBREW is set
_assert_set HAS_HOMEBREW "HAS_HOMEBREW variable is exported"

# Test 5: Verify HAS_HOMEBREW is valid
if [ "$HAS_HOMEBREW" = "true" ] || [ "$HAS_HOMEBREW" = "false" ]; then
  ((TESTS_RUN++))
  ((TESTS_PASSED++))
  echo "${GREEN}✓ PASS${NC}: HAS_HOMEBREW has valid value"
  echo "  HAS_HOMEBREW = $HAS_HOMEBREW"
else
  ((TESTS_RUN++))
  ((TESTS_FAILED++))
  echo "${RED}✗ FAIL${NC}: HAS_HOMEBREW has invalid value: $HAS_HOMEBREW"
fi

echo ""

# Test 6: Platform-specific assertions
platform_name="Unknown"
uname_output=$(uname -s)

case "$uname_output" in
  Darwin)
    platform_name="macOS"
    _assert_equals "macos" "$OS_FAMILY" "macOS should have OS_FAMILY=macos"
    ;;
  Linux)
    platform_name="Linux"
    if [ -f /etc/os-release ]; then
      local distro_id=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"' | tr -d "'")
      case "$distro_id" in
        ubuntu)
          _assert_equals "ubuntu" "$OS_FAMILY" "Ubuntu should have OS_FAMILY=ubuntu"
          ;;
        debian)
          _assert_equals "debian" "$OS_FAMILY" "Debian should have OS_FAMILY=debian"
          ;;
        fedora)
          _assert_equals "fedora" "$OS_FAMILY" "Fedora should have OS_FAMILY=fedora"
          ;;
        *)
          echo "${YELLOW}⊘ SKIP${NC}: Unknown Linux distro: $distro_id"
          ;;
      esac
    else
      _assert_equals "debian" "$OS_FAMILY" "No /etc/os-release: should fallback to debian"
    fi
    ;;
  *)
    echo "${YELLOW}⊘ SKIP${NC}: Unknown platform: $uname_output"
    ;;
esac

echo ""

# Test 7: Verify Homebrew detection on macOS
if [ "$OS_FAMILY" = "macos" ]; then
  echo "Test: Homebrew Detection (macOS-specific)"
  if command -v brew &>/dev/null; then
    _assert_equals "true" "$HAS_HOMEBREW" "Homebrew is installed: HAS_HOMEBREW should be true"
  else
    _assert_equals "false" "$HAS_HOMEBREW" "Homebrew is not installed: HAS_HOMEBREW should be false"
  fi
  echo ""
fi

# Test 8: Idempotency
echo "Test: Idempotency (sourcing twice)"
OS_FAMILY_FIRST="$OS_FAMILY"
HAS_HOMEBREW_FIRST="$HAS_HOMEBREW"

# Re-source to verify idempotency
source lib/os_detect.zsh >/dev/null 2>&1

((TESTS_RUN++))
if [ "$OS_FAMILY_FIRST" = "$OS_FAMILY" ]; then
  ((TESTS_PASSED++))
  echo "${GREEN}✓ PASS${NC}: OS_FAMILY unchanged after re-sourcing"
else
  ((TESTS_FAILED++))
  echo "${RED}✗ FAIL${NC}: OS_FAMILY changed after re-sourcing"
  echo "  Before: $OS_FAMILY_FIRST"
  echo "  After:  $OS_FAMILY"
fi

((TESTS_RUN++))
if [ "$HAS_HOMEBREW_FIRST" = "$HAS_HOMEBREW" ]; then
  ((TESTS_PASSED++))
  echo "${GREEN}✓ PASS${NC}: HAS_HOMEBREW unchanged after re-sourcing"
else
  ((TESTS_FAILED++))
  echo "${RED}✗ FAIL${NC}: HAS_HOMEBREW changed after re-sourcing"
  echo "  Before: $HAS_HOMEBREW_FIRST"
  echo "  After:  $HAS_HOMEBREW"
fi

echo ""

# Test 9: JSON output
echo "Test: JSON Output Mode"
json_output=$(bash lib/os_detect.sh --json 2>&1)

if echo "$json_output" | grep -q '"OS_FAMILY"'; then
  ((TESTS_RUN++))
  ((TESTS_PASSED++))
  echo "${GREEN}✓ PASS${NC}: JSON output contains OS_FAMILY"
else
  ((TESTS_RUN++))
  ((TESTS_FAILED++))
  echo "${RED}✗ FAIL${NC}: JSON output missing OS_FAMILY"
fi

if echo "$json_output" | grep -q '"HAS_HOMEBREW"'; then
  ((TESTS_RUN++))
  ((TESTS_PASSED++))
  echo "${GREEN}✓ PASS${NC}: JSON output contains HAS_HOMEBREW"
else
  ((TESTS_RUN++))
  ((TESTS_FAILED++))
  echo "${RED}✗ FAIL${NC}: JSON output missing HAS_HOMEBREW"
fi

if echo "$json_output" | grep -q '"detection_ms"'; then
  ((TESTS_RUN++))
  ((TESTS_PASSED++))
  echo "${GREEN}✓ PASS${NC}: JSON output contains detection_ms"
else
  ((TESTS_RUN++))
  ((TESTS_FAILED++))
  echo "${RED}✗ FAIL${NC}: JSON output missing detection_ms"
fi

echo ""

# Test 10: Verbose output
echo "Test: Verbose Output Mode"
verbose_output=$(bash lib/os_detect.sh --verbose 2>&1)

if echo "$verbose_output" | grep -q "\[os_detect\]"; then
  ((TESTS_RUN++))
  ((TESTS_PASSED++))
  echo "${GREEN}✓ PASS${NC}: Verbose output contains [os_detect] prefix"
else
  ((TESTS_RUN++))
  ((TESTS_FAILED++))
  echo "${RED}✗ FAIL${NC}: Verbose output missing [os_detect] prefix"
fi

echo ""
echo "=========================================="
echo "Test Results"
echo "=========================================="
echo "Platform detected: $platform_name ($OS_FAMILY)"
echo "Homebrew available: $HAS_HOMEBREW"
echo ""
echo "Tests run:    $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo "=========================================="

if [ $TESTS_FAILED -eq 0 ]; then
  echo "${GREEN}✓ All smoke tests passed!${NC}"
  exit 0
else
  echo "${RED}✗ Some smoke tests failed${NC}"
  exit 1
fi
