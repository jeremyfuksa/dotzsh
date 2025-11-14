#!/bin/bash
# Update-All Test Suite

set -o pipefail

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

assert_equals() {
  local expected="$1"
  local actual="$2"
  local msg="$3"

  ((TESTS_RUN++))

  if [ "$expected" = "$actual" ]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓ PASS${NC}: $msg"
  else
    ((TESTS_FAILED++))
    echo -e "${RED}✗ FAIL${NC}: $msg"
    echo "  Expected: $expected"
    echo "  Actual:   $actual"
  fi
}

assert_contains() {
  local needle="$1"
  local haystack="$2"
  local msg="$3"

  ((TESTS_RUN++))

  if [[ "$haystack" == *"$needle"* ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓ PASS${NC}: $msg"
  else
    ((TESTS_FAILED++))
    echo -e "${RED}✗ FAIL${NC}: $msg"
    echo "  Expected to find: $needle"
    echo "  Output: $haystack"
  fi
}

test_update_all_help() {
  echo "Test: update-all.sh --help output"
  local output
  output=$(bash update-all.sh --help 2>&1)
  local exit_code=$?
  assert_equals "0" "$exit_code" "--help returns success"
  assert_contains "Usage" "$output" "--help prints usage text"
}

test_step_nvm_missing_installation() {
  echo "Test: step_nvm skips when NVM missing"
  local tmp_home
  tmp_home=$(mktemp -d)
  local output
  output=$(HOME="$tmp_home" NVM_DIR="$tmp_home/.nvm" FRANKLIN_TEST_MODE=1 bash -c '
set +e
source ./update-all.sh
set +e
step_nvm' 2>&1)
  local exit_code=$?
  assert_equals "1" "$exit_code" "step_nvm returns warning when NVM missing"
  assert_contains "NVM not installed" "$output" "Warning mentions missing NVM"
  rm -rf "$tmp_home"
}

test_step_nvm_detects_local_changes() {
  echo "Test: step_nvm skips when local git changes exist"
  local tmp_home
  tmp_home=$(mktemp -d)
  local remote_repo="$tmp_home/nvm_remote.git"
  local working_repo="$tmp_home/.nvm"

  git init --bare "$remote_repo" >/dev/null 2>&1
  git clone "$remote_repo" "$working_repo" >/dev/null 2>&1

  pushd "$working_repo" >/dev/null || exit 1
  git config user.name "franklin-test" >/dev/null 2>&1
  git config user.email "franklin@example.com" >/dev/null 2>&1
  cat <<'EOF' > nvm.sh
#!/bin/bash
nvm() { :; }
EOF
  git add nvm.sh >/dev/null 2>&1
  git commit -m "Initial NVM stub" >/dev/null 2>&1
  git tag v0.1.0 >/dev/null 2>&1
  git push origin HEAD --tags >/dev/null 2>&1
  echo "# local changes" >> nvm.sh
  popd >/dev/null || exit 1

  local output
  output=$(HOME="$tmp_home" NVM_DIR="$working_repo" FRANKLIN_TEST_MODE=1 bash -c '
set +e
source ./update-all.sh
set +e
step_nvm' 2>&1)
  local exit_code=$?
  assert_equals "1" "$exit_code" "step_nvm returns warning when repo dirty"
  assert_contains "local modifications" "$output" "Warning mentions local modifications"

  rm -rf "$tmp_home"
}

run_tests() {
  test_update_all_help
  test_step_nvm_missing_installation
  test_step_nvm_detects_local_changes

  echo ""
  echo -e "${YELLOW}Summary:${NC} $TESTS_PASSED passed, $TESTS_FAILED failed (total $TESTS_RUN)"

  if [ $TESTS_FAILED -ne 0 ]; then
    exit 1
  fi
}

run_tests
