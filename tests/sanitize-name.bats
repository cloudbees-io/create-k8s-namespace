#!/usr/bin/env bats

# Test suite for scripts/sanitize-name.sh

setup() {
    # Load the script location
    SCRIPT_DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )/.." && pwd )"
    SANITIZE_SCRIPT="${SCRIPT_DIR}/scripts/sanitize-name.sh"
}

# Helper function to validate RFC 1123 compliance
is_rfc1123_compliant() {
    local name=$1
    # RFC 1123: lowercase alphanumeric or '-', start/end with alphanumeric, max 63 chars
    [[ "$name" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]] && [ ${#name} -le 63 ]
}

# Test: Original bug - underscore in name
@test "sanitize name with underscore (original bug)" {
    run "$SANITIZE_SCRIPT" "bfix-z_db-134751b" "true"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^b ]]
    # Should not contain underscore
    [[ ! "$output" =~ _ ]]
    # Should be RFC 1123 compliant
    is_rfc1123_compliant "$output"
}

# Test: Multiple underscores
@test "sanitize name with multiple underscores" {
    run "$SANITIZE_SCRIPT" "my_feature_branch" "true"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ _ ]]
    is_rfc1123_compliant "$output"
}

# Test: Slash in name
@test "sanitize name with slash" {
    run "$SANITIZE_SCRIPT" "fix/bug-123" "true"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ / ]]
    is_rfc1123_compliant "$output"
}

# Test: Mixed case and underscores
@test "sanitize mixed case with underscores" {
    run "$SANITIZE_SCRIPT" "Feature_Branch_With_Underscores" "true"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ [A-Z] ]]
    [[ ! "$output" =~ _ ]]
    is_rfc1123_compliant "$output"
}

# Test: Multiple special characters
@test "sanitize name with multiple special characters" {
    run "$SANITIZE_SCRIPT" 'branch@with#special$chars' "true"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ [@#\$] ]]
    is_rfc1123_compliant "$output"
}

# Test: Uppercase conversion
@test "sanitize uppercase name" {
    run "$SANITIZE_SCRIPT" "UPPERCASE-BRANCH" "true"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ [A-Z] ]]
    is_rfc1123_compliant "$output"
}

# Test: Multiple consecutive dashes
@test "sanitize name with consecutive dashes" {
    run "$SANITIZE_SCRIPT" "branch---with---dashes" "true"
    [ "$status" -eq 0 ]
    is_rfc1123_compliant "$output"
}

# Test: Leading underscore
@test "sanitize name with leading underscore" {
    run "$SANITIZE_SCRIPT" "_leading_underscore" "true"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ ^_ ]]
    [[ ! "$output" =~ _ ]]
    is_rfc1123_compliant "$output"
}

# Test: Trailing underscore
@test "sanitize name with trailing underscore" {
    run "$SANITIZE_SCRIPT" "trailing_underscore_" "true"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ _$ ]]
    [[ ! "$output" =~ _ ]]
    is_rfc1123_compliant "$output"
}

# Test: Dots (another common issue)
@test "sanitize name with dots" {
    run "$SANITIZE_SCRIPT" "a.b.c.d.e.f.g" "true"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ \. ]]
    is_rfc1123_compliant "$output"
}

# Test: Version string with special chars
@test "sanitize version string" {
    run "$SANITIZE_SCRIPT" "my-branch@v1.2.3" "true"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ [@.] ]]
    is_rfc1123_compliant "$output"
}

# Test: Complex combination
@test "sanitize complex name" {
    run "$SANITIZE_SCRIPT" "user/repo_name-feature_123" "true"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ [/_] ]]
    is_rfc1123_compliant "$output"
}

# Test: Already valid name
@test "sanitize already valid name" {
    run "$SANITIZE_SCRIPT" "valid-branch-name" "true"
    [ "$status" -eq 0 ]
    is_rfc1123_compliant "$output"
}

# Test: Sanitization disabled
@test "skip sanitization when disabled" {
    run "$SANITIZE_SCRIPT" "valid-branch-name" "false"
    [ "$status" -eq 0 ]
    [ "$output" = "valid-branch-name" ]
}

# Test: No arguments
@test "error when no arguments provided" {
    run "$SANITIZE_SCRIPT"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: Name argument is required" ]]
}

# Test: Output starts with 'b' prefix
@test "sanitized name starts with 'b' prefix" {
    run "$SANITIZE_SCRIPT" "any-name" "true"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^b ]]
}

# Test: Output length is within limits
@test "sanitized name is within 63 character limit" {
    run "$SANITIZE_SCRIPT" "very-long-branch-name-that-would-normally-exceed-kubernetes-namespace-length-limits" "true"
    [ "$status" -eq 0 ]
    [ ${#output} -le 63 ]
    is_rfc1123_compliant "$output"
}

# Test: Deterministic output (same input = same output)
@test "sanitization is deterministic" {
    run "$SANITIZE_SCRIPT" "test-name_123" "true"
    first_output="$output"

    run "$SANITIZE_SCRIPT" "test-name_123" "true"
    second_output="$output"

    [ "$first_output" = "$second_output" ]
}

# Test: Different inputs produce different outputs
@test "different inputs produce different outputs" {
    run "$SANITIZE_SCRIPT" "name-one" "true"
    output_one="$output"

    run "$SANITIZE_SCRIPT" "name-two" "true"
    output_two="$output"

    [ "$output_one" != "$output_two" ]
}
