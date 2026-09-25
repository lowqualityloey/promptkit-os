#!/usr/bin/env bash
# PromptKit OS Playbook Contract Validator
# Validates that stack playbooks (docs/stacks/*.md) conform to the Playbook Contract:
# - Required YAML frontmatter fields (name, category, version, token_budget, activation, verification, invariants, anti_patterns)
# - Clean YAML arrays (no shell composition operators like '&&', '||', ';')
# - Strict token budget ceiling (<= 1,500 tokens using bytes/4 convention)
set -euo pipefail

TARGET_PATH=""
TEST_SCHEMA=0

for arg in "$@"; do
    case "$arg" in
        --test-schema) TEST_SCHEMA=1 ;;
        -h|--help)
            echo "Usage: validate-playbooks.sh [--test-schema] [path/to/playbook.md | path/to/dir]"
            exit 0
            ;;
        *) TARGET_PATH="$arg" ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

validate_single_playbook() {
    local file="$1"
    local errors=0
    local filename
    filename="$(basename "$file")"

    if [[ ! -f "$file" ]]; then
        echo "❌ ERROR: File not found: $file"
        return 1
    fi

    # 1. Check frontmatter boundaries
    local first_line
    first_line="$(head -n 1 "$file" | tr -d '\r')"
    if [[ "$first_line" != "---" ]]; then
        echo "❌ $filename: Missing opening frontmatter delimiter (--- on line 1)"
        return 1
    fi

    local end_line
    end_line="$(tr -d '\r' < "$file" | grep -n "^---$" | sed -n '2p' | cut -d: -f1)"
    if [[ -z "$end_line" || "$end_line" -le 1 ]]; then
        echo "❌ $filename: Missing closing frontmatter delimiter (---)"
        return 1
    fi

    local frontmatter
    frontmatter="$(sed -n "2,$((end_line - 1))p" "$file" | tr -d '\r')"

    # 2. Check required fields
    check_field() {
        local regex="$1"
        local desc="$2"
        if ! echo "$frontmatter" | grep -qE "$regex"; then
            echo "❌ $filename: Missing required frontmatter field: $desc"
            errors=$((errors + 1))
        fi
    }

    check_field "^name:[[:space:]]+[a-zA-Z0-9_-]+" "name: <string>"
    check_field "^version:[[:space:]]+[0-9]+" "version: <integer>"
    check_field "^token_budget:[[:space:]]+[0-9]+" "token_budget: <integer <= 1500>"

    local declared_budget
    declared_budget="$(echo "$frontmatter" | grep -E "^token_budget:[[:space:]]+[0-9]+" | head -n 1 | awk '{print $2}' | tr -d '\r')"
    if [[ -n "$declared_budget" && "$declared_budget" -gt 1500 ]]; then
        echo "❌ $filename: Declared token_budget ($declared_budget) exceeds 1500 limit"
        errors=$((errors + 1))
    fi

    local category
    category="$(echo "$frontmatter" | grep -E "^category:[[:space:]]+" | head -n 1 | awk '{print $2}' | tr -d '\r')"

    if [[ "$category" == "recipe" ]]; then
        check_field "^description:[[:space:]]+.+" "description: <string>"
    elif [[ "$category" =~ ^(web|database|cloud|mobile|systems|cli)$ ]]; then
        # Check activation block
        if ! echo "$frontmatter" | grep -q "^activation:"; then
            echo "❌ $filename: Missing 'activation:' block"
            errors=$((errors + 1))
        fi
        if ! echo "$frontmatter" | grep -q "manifests:"; then
            echo "❌ $filename: Missing 'manifests:' array under activation"
            errors=$((errors + 1))
        fi

        # Check verification block
        if ! echo "$frontmatter" | grep -q "^verification:"; then
            echo "❌ $filename: Missing 'verification:' block"
            errors=$((errors + 1))
        fi
        if ! echo "$frontmatter" | grep -q "fast:"; then
            echo "❌ $filename: Missing 'fast:' verification tier"
            errors=$((errors + 1))
        fi
        if ! echo "$frontmatter" | grep -q "required:"; then
            echo "❌ $filename: Missing 'required:' verification tier"
            errors=$((errors + 1))
        fi
        if ! echo "$frontmatter" | grep -q "extended:"; then
            echo "❌ $filename: Missing 'extended:' verification tier"
            errors=$((errors + 1))
        fi

        # Check invariants and anti_patterns
        if ! echo "$frontmatter" | grep -q "^invariants:"; then
            echo "❌ $filename: Missing 'invariants:' block"
            errors=$((errors + 1))
        fi
        if ! echo "$frontmatter" | grep -q "^anti_patterns:"; then
            echo "❌ $filename: Missing 'anti_patterns:' block"
            errors=$((errors + 1))
        fi

        # 3. Check for shell composition anti-patterns in verification (prohibit &&, ||, ;)
        local verification_block
        verification_block="$(echo "$frontmatter" | awk '/^verification:/{flag=1; next} /^[a-zA-Z0-9_-]+:/{flag=0} flag')"
        if echo "$verification_block" | grep -E "(-[[:space:]]+.*(&&|\|\||;))" >/dev/null; then
            echo "❌ $filename: Prohibited shell composition (&&, ||, ;) found in verification arrays. Use discrete array items."
            errors=$((errors + 1))
        fi
    else
        echo "❌ $filename: Invalid or missing category '${category:-<empty>}': must be 'recipe' or one of (web|database|cloud|mobile|systems|cli)"
        errors=$((errors + 1))
    fi

    # 4. Token budget check (bytes/4 <= 1500)
    local chars
    chars="$(tr -d '\r' < "$file" | wc -c | tr -d ' ')"
    local tokens=$(( (chars + 2) / 4 ))
    if [[ "$tokens" -gt 1500 ]]; then
        echo "❌ $filename: Exceeds token budget ($tokens tok > 1500 limit)"
        errors=$((errors + 1))
    fi

    if [[ "$errors" -eq 0 ]]; then
        echo "✅ $filename: PASS ($tokens tok, schema valid)"
        return 0
    else
        echo "❌ $filename: FAILED with $errors error(s)"
        return 1
    fi
}

# Self-test mode
if [[ "$TEST_SCHEMA" -eq 1 ]]; then
    echo "🧪 Running Playbook & Recipe Contract Schema Self-Tests..."
    TMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TMP_DIR"' EXIT

    # Valid stack fixture
    cat <<'EOF' > "$TMP_DIR/valid-stack.md"
---
name: sample-rust
category: systems
version: 1
token_budget: 1500
activation:
  manifests:
    - Cargo.toml
verification:
  fast:
    - cargo check
  required:
    - cargo test
  extended:
    - cargo clippy -- -D warnings
invariants:
  - "Prefer borrowed references over cloning"
  - "Errors must be propagated explicitly"
anti_patterns:
  - "Unnecessary cloning"
  - "Broad unwrap usage"
---
# Sample Rust Stack Playbook
EOF

    # Invalid stack fixture (shell composition && missing required tier)
    cat <<'EOF' > "$TMP_DIR/invalid-stack.md"
---
name: invalid-stack
category: unknown-category
version: 1
token_budget: 2000
activation:
  manifests:
    - package.json
verification:
  fast:
    - pnpm tsc && pnpm lint
invariants:
  - "Do something"
anti_patterns:
  - "Avoid something"
---
# Invalid Stack Playbook
EOF

    # Valid recipe fixture
    cat <<'EOF' > "$TMP_DIR/valid-recipe.md"
---
name: sample-recipe
category: recipe
version: 1
token_budget: 1500
description: Sample recipe description for self-test.
---
# Sample Recipe
EOF

    # Invalid recipe fixture (missing description, budget > 1500)
    cat <<'EOF' > "$TMP_DIR/invalid-recipe.md"
---
name: invalid-recipe
category: recipe
version: 1
token_budget: 2000
---
# Invalid Recipe
EOF

    echo "--- Testing Valid Stack Fixture ---"
    if ! validate_single_playbook "$TMP_DIR/valid-stack.md"; then
        echo "❌ Schema Self-Test Failed: valid stack fixture was rejected"
        exit 1
    fi

    echo "--- Testing Invalid Stack Fixture (Should Fail) ---"
    if validate_single_playbook "$TMP_DIR/invalid-stack.md" >/dev/null 2>&1; then
        echo "❌ Schema Self-Test Failed: invalid stack fixture was incorrectly accepted"
        exit 1
    else
        echo "✅ Invalid stack fixture properly caught and rejected"
    fi

    echo "--- Testing Valid Recipe Fixture ---"
    if ! validate_single_playbook "$TMP_DIR/valid-recipe.md"; then
        echo "❌ Schema Self-Test Failed: valid recipe fixture was rejected"
        exit 1
    fi

    echo "--- Testing Invalid Recipe Fixture (Should Fail) ---"
    if validate_single_playbook "$TMP_DIR/invalid-recipe.md" >/dev/null 2>&1; then
        echo "❌ Schema Self-Test Failed: invalid recipe fixture was incorrectly accepted"
        exit 1
    else
        echo "✅ Invalid recipe fixture properly caught and rejected"
    fi

    echo "✅ Playbook & Recipe Contract Schema Self-Tests PASSED"
    exit 0
fi

# Main execution
TOTAL_CHECKED=0
TOTAL_FAILED=0

if [[ -n "$TARGET_PATH" ]]; then
    if [[ -f "$TARGET_PATH" ]]; then
        validate_single_playbook "$TARGET_PATH" || TOTAL_FAILED=$((TOTAL_FAILED + 1))
        TOTAL_CHECKED=1
    elif [[ -d "$TARGET_PATH" ]]; then
        while IFS= read -r file; do
            TOTAL_CHECKED=$((TOTAL_CHECKED + 1))
            validate_single_playbook "$file" || TOTAL_FAILED=$((TOTAL_FAILED + 1))
        done < <(find "$TARGET_PATH" -maxdepth 1 -name "*.md" ! -name "README.md" -type f 2>/dev/null)
    else
        echo "❌ ERROR: Target path not found: $TARGET_PATH"
        exit 1
    fi
else
    STACKS_DIR="$KIT_ROOT/docs/stacks"
    if [[ -d "$STACKS_DIR" ]]; then
        while IFS= read -r file; do
            TOTAL_CHECKED=$((TOTAL_CHECKED + 1))
            validate_single_playbook "$file" || TOTAL_FAILED=$((TOTAL_FAILED + 1))
        done < <(find "$STACKS_DIR" -maxdepth 1 -name "*.md" ! -name "README.md" -type f 2>/dev/null)
    fi
    RECIPES_DIR="$KIT_ROOT/docs/recipes"
    if [[ -d "$RECIPES_DIR" ]]; then
        while IFS= read -r file; do
            TOTAL_CHECKED=$((TOTAL_CHECKED + 1))
            validate_single_playbook "$file" || TOTAL_FAILED=$((TOTAL_FAILED + 1))
        done < <(find "$RECIPES_DIR" -maxdepth 1 -name "*.md" ! -name "README.md" -type f 2>/dev/null)
    fi
fi

echo ""
echo "📊 Playbook Contract Validation Summary: $TOTAL_CHECKED checked, $TOTAL_FAILED failed."
if [[ "$TOTAL_FAILED" -gt 0 ]]; then
    exit 1
fi
exit 0
