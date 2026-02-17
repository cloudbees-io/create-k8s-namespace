#!/usr/bin/env bash

set -euo pipefail

# sanitize-name.sh - Sanitize namespace name to be RFC 1123 compliant
#
# Usage: sanitize-name.sh <name> <sanitize>
#
# Arguments:
#   name      - The namespace name to sanitize
#   sanitize  - 'true' to enable sanitization, any other value to skip
#
# Output: Prints the sanitized name to stdout

main() {
    local NAME="${1:-}"
    local SANITIZE="${2:-true}"

    if [ -z "$NAME" ]; then
        echo "Error: Name argument is required" >&2
        exit 1
    fi

    if [ "$SANITIZE" = "true" ]; then
        # Generate hash for uniqueness (keep full output including trailing chars)
        local HASH
        HASH="$(printf %s "$NAME" | sha256sum)"

        # Convert to lowercase and replace all non-alphanumeric chars with hyphens
        NAME="$(printf %s "$NAME" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g')"

        # Truncate and add hash suffix, then clean up any remaining invalid chars
        NAME="$(printf b%.8s-%.7s "$NAME" "$HASH" | sed -E 's/[^a-z0-9]+/-/g' | sed -E 's/^-+|-+$//')"
    fi

    printf %s "$NAME"
}

main "$@"
