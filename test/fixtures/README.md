# Test Fixtures

This directory contains mock data for testing franklin features without requiring actual systems or complex setup.

## os-release.d/

Mock `/etc/os-release` files for testing platform detection without needing actual Linux systems.

### Files

| File | Represents | Description |
|------|-----------|-------------|
| `macos` | macOS | Placeholder (macOS has no /etc/os-release) |
| `ubuntu` | Ubuntu 20.04+ | Real /etc/os-release from Ubuntu 20.04 |
| `debian` | Debian 11+ | Real /etc/os-release from Debian 11 |
| `fedora` | Fedora 36+ | Real /etc/os-release from Fedora 36 |
| `unknown` | Unknown distro | Custom unknown distro for fallback testing |

### Usage in Tests

To test platform detection without actual systems:

```bash
#!/bin/bash
source test/_os_detect_tests.sh

# Test Ubuntu detection with mock
OS_RELEASE_FILE="test/fixtures/os-release.d/ubuntu" \
  run_test "Ubuntu detection" \
  test_ubuntu_detection

# Test fallback with missing os-release
unset OS_RELEASE_FILE
run_test "Fallback to debian" \
  test_debian_fallback
```

### Adding New Fixtures

1. Copy a real `/etc/os-release` from target system
2. Save to `os-release.d/<distro-name>`
3. Ensure ID field is set correctly
4. Document in this README

Example structure for new distro:

```
NAME="CustomLinux"
VERSION="2.0"
ID=customlinux
VERSION_ID=2.0
PRETTY_NAME="CustomLinux 2.0"
HOME_URL="https://example.com/"
```

