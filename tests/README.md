# Unit Tests

This directory contains unit tests for the action's shell scripts.

## Test Framework

Tests are written using [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core).

## Installation

### macOS
```bash
brew install bats-core
```

### Linux (Debian/Ubuntu)
```bash
sudo apt-get install bats
```

### Linux (RHEL/CentOS)
```bash
sudo yum install bats
```

### Manual Installation
```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

## Running Tests

### Run all tests
```bash
bats tests/
```

### Run specific test file
```bash
bats tests/sanitize-name.bats
```

### Verbose output
```bash
bats tests/sanitize-name.bats --verbose
```

### Tap output (for CI/CD)
```bash
bats tests/sanitize-name.bats --tap
```

## Test Coverage

### sanitize-name.bats

Tests the `scripts/sanitize-name.sh` script that sanitizes namespace names to be RFC 1123 compliant.

**Test Cases:**
- ✅ Underscore handling (original bug)
- ✅ Multiple underscores
- ✅ Slash characters
- ✅ Mixed case conversion
- ✅ Multiple special characters
- ✅ Uppercase to lowercase
- ✅ Consecutive dashes
- ✅ Leading invalid characters
- ✅ Trailing invalid characters
- ✅ Dots in names
- ✅ Version strings with special chars
- ✅ Complex combinations
- ✅ Already valid names
- ✅ Sanitization disabled
- ✅ Error handling (no arguments)
- ✅ Output format validation
- ✅ Length constraints
- ✅ Deterministic behavior
- ✅ Uniqueness

## Running in CI/CD

Add to your workflow:

```yaml
- name: Install BATS
  uses: docker://alpine:3.18
  run: |
    apk add --no-cache bash
    wget -O /tmp/bats.tar.gz https://github.com/bats-core/bats-core/archive/v1.10.0.tar.gz
    tar -xzf /tmp/bats.tar.gz -C /tmp
    /tmp/bats-core-1.10.0/install.sh /usr/local

- name: Run unit tests
  uses: docker://alpine:3.18
  run: |
    cd $CLOUDBEES_WORKSPACE
    bats tests/
```

## Writing New Tests

When adding new scripts, create corresponding BATS test files:

1. Create `tests/your-script.bats`
2. Follow the pattern in `sanitize-name.bats`:
   ```bash
   #!/usr/bin/env bats

   setup() {
       SCRIPT_DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )/.." && pwd )"
       YOUR_SCRIPT="${SCRIPT_DIR}/scripts/your-script.sh"
   }

   @test "description of test" {
       run "$YOUR_SCRIPT" arg1 arg2
       [ "$status" -eq 0 ]
       [ "$output" = "expected output" ]
   }
   ```

## Best Practices

1. **Test one thing per test case** - Keep tests focused and atomic
2. **Use descriptive test names** - Make failures easy to understand
3. **Test edge cases** - Empty strings, special characters, boundary conditions
4. **Test error conditions** - Invalid inputs should be handled gracefully
5. **Keep tests fast** - Unit tests should run in milliseconds
6. **Make tests deterministic** - Same input should always produce same output

## Debugging Tests

To debug a failing test:

```bash
# Run single test by line number
bats tests/sanitize-name.bats:42

# Add debug output in your test
@test "my test" {
    echo "DEBUG: variable=$variable" >&3
    run "$SCRIPT" "$variable"
    [ "$status" -eq 0 ]
}

# Run with verbose output
bats --verbose tests/sanitize-name.bats
```

## RFC 1123 Validation

The tests include an RFC 1123 compliance validator:

```bash
is_rfc1123_compliant() {
    local name=$1
    # RFC 1123: lowercase alphanumeric or '-', start/end with alphanumeric, max 63 chars
    [[ "$name" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]] && [ ${#name} -le 63 ]
}
```

This ensures all sanitized names meet Kubernetes namespace requirements.
