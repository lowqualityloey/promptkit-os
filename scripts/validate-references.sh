#!/usr/bin/env bash
# Validation Script: Verify all workflow→template references exist
# Run from repository root: ./.promptkit/scripts/validate-references.sh

set +e  # Don't exit on first error

# Usage: validate-references.sh [--strict] [promptkit-dir]
#   --strict  CI gate mode: exit non-zero when warnings are present. Errors always
#             exit non-zero; without --strict a warning-only tree exits 0.
STRICT_MODE=0
PROMPTKIT_DIR=""
for arg in "$@"; do
    case "$arg" in
        --strict) STRICT_MODE=1 ;;
        -h|--help)
            echo "Usage: validate-references.sh [--strict] [promptkit-dir]"
            exit 0
            ;;
        *)
            if [ -z "$PROMPTKIT_DIR" ]; then
                PROMPTKIT_DIR="$arg"
            else
                echo "Error: unknown argument: $arg" >&2
                exit 2
            fi
            ;;
    esac
done
PROMPTKIT_DIR="${PROMPTKIT_DIR:-.promptkit}"
ERROR_COUNT=0
WARNING_COUNT=0

echo ""
echo "🔍 PromptKit OS Reference Validation"
echo ""

# Resolve paths
if [ ! -d "$PROMPTKIT_DIR" ]; then
    echo "❌ ERROR: PromptKit directory not found: $PROMPTKIT_DIR"
    exit 1
fi

PROMPTKIT_ROOT="$(cd "$PROMPTKIT_DIR" && pwd)"

# Define directories
WORKFLOWS_DIR="$PROMPTKIT_ROOT/workflows"
PROTOCOLS_DIR="$PROMPTKIT_ROOT/protocols"
TEMPLATES_DIR="$PROMPTKIT_ROOT/templates"
ACTIVITIES_DIR="$PROMPTKIT_ROOT/activities"
DOCS_DIR="$PROMPTKIT_ROOT/docs"
EXAMPLES_DIR="$PROMPTKIT_ROOT/examples"
NOTES_DIR="$PROMPTKIT_ROOT/notes"

echo "📂 Scanning directories:"
echo "   - $WORKFLOWS_DIR"
echo "   - $PROTOCOLS_DIR"
echo "   - $TEMPLATES_DIR"
echo "   - $ACTIVITIES_DIR"
echo "   - $DOCS_DIR"
echo "   - $EXAMPLES_DIR"
echo "   - $NOTES_DIR"
echo "   - $PROMPTKIT_ROOT (top level)"
echo ""

# Find all markdown files. The content directories are scanned recursively and
# the repository root only at its top level, so -maxdepth cannot be shared
# between the two searches.
ALL_MD_FILES=()
while IFS= read -r -d '' file; do
    ALL_MD_FILES+=("$file")
done < <(find "$WORKFLOWS_DIR" "$PROTOCOLS_DIR" "$TEMPLATES_DIR" "$ACTIVITIES_DIR" "$DOCS_DIR" "$EXAMPLES_DIR" "$NOTES_DIR" -name "*.md" -type f -print0 2>/dev/null)
while IFS= read -r -d '' file; do
    ALL_MD_FILES+=("$file")
done < <(find "$PROMPTKIT_ROOT" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null)

echo "📄 Found ${#ALL_MD_FILES[@]} markdown files to validate"
echo ""

# Anti-typo check for setup script commands
echo "🔍 Checking for setup script typos..."
TYPO_PATTERN="i"" ""nit.ps1"
TYPO_FILES=$(grep -rn "$TYPO_PATTERN" "$PROMPTKIT_ROOT" 2>/dev/null | grep -v "validate-references")
if [ -n "$TYPO_FILES" ]; then
    echo "  ❌ BROKEN: Setup typo found in repository:"
    echo "$TYPO_FILES"
    ((ERROR_COUNT++))
else
    echo "  ✅ No setup script typos found"
fi
echo ""

# Function to check file existence
check_file_reference() {
    local source_file="$1"
    local ref_type="$2"
    local ref_path="$3"
    local line_num="$4"
    
    local full_path="$PROMPTKIT_ROOT/$ref_path"
    
    if [ ! -f "$full_path" ]; then
        local rel_source="${source_file#"$PROMPTKIT_ROOT"/}"
        echo "  ❌ BROKEN: $rel_source:$line_num"
        echo "     Type: $ref_type"
        echo "     Missing: $ref_path"
        echo ""
        ((ERROR_COUNT++))
        return 1
    fi
    return 0
}

# Generic markdown-link resolution: a reader-facing relative link in a scanned
# file must resolve. Historical records are exempt (same policy as the
# canonical-count drift guard), placeholder/anchor/absolute/external targets are
# skipped, and inline code spans are ignored so illustrative examples cannot
# trip the gate. Without this, a root-relative link inside docs/ passes every
# gate while 404ing for readers on the host.
LINK_EXEMPT_DIRS="docs/releases/ docs/tasks/ docs/archive/ docs/internal/ docs/spikes/"

# The trigger/workflow correspondence check cannot be applied to public
# specifications: a spec's subject is frequently the trigger it proposes to add, so
# issue-547 legitimately names `pk:doctor` while `workflows/doctor.md` does not exist
# yet. Without this, committing an accurate spec fails the build for being accurate,
# and the only ways out are to mangle the trigger token out of the prose or to ship the
# workflow early. The correspondence is still enforced where triggers actually ship --
# the directive templates and protocols/setup.md -- and by the behavioral contract that
# asserts zero warnings. Same exemption policy as LINK_EXEMPT_DIRS.
TRIGGER_SCAN_EXEMPT_DIRS="docs/specs/"

is_trigger_scan_exempt() {
    local rel="$1"
    local exempt
    for exempt in $TRIGGER_SCAN_EXEMPT_DIRS; do
        case "$rel" in
            "$exempt"*) return 0 ;;
        esac
    done
    return 1
}

is_link_exempt() {
    local rel="$1"
    local exempt
    for exempt in $LINK_EXEMPT_DIRS; do
        case "$rel" in
            "$exempt"*) return 0 ;;
        esac
    done
    return 1
}

check_markdown_links() {
    local source_file="$1"
    local rel_source="$2"

    # One grep pass per file: only lines that actually carry a local .md link are
    # examined, so the check stays cheap across the whole tree.
    local hit lnum line_content sanitized targets
    while IFS= read -r hit; do
        [ -z "$hit" ] && continue
        lnum="${hit%%:*}"
        line_content="${hit#*:}"

        # Drop inline code spans so example links written inside backticks are ignored.
        sanitized="$(printf '%s' "$line_content" | sed "s/\`[^\`]*\`//g")"
        targets="$(printf '%s\n' "$sanitized" | grep -oE '\]\([^)]+\.md(#[^)]*)?\)' | sed -E 's/^\]\(//; s/\)$//; s/#.*$//')" || true
        [ -z "$targets" ] && continue

        local target candidate
        while IFS= read -r target; do
            [ -z "$target" ] && continue
            case "$target" in
                http*|/*|\#*|*"<"*|*"{"*|*'$'*|[A-Za-z]:*) continue ;;
            esac
            candidate="$(dirname "$source_file")/$target"
            if [ ! -e "$candidate" ]; then
                echo "  ❌ BROKEN LINK: $rel_source:$lnum"
                echo "     Link: $target"
                echo ""
                ((ERROR_COUNT++))
                file_has_issues=true
            fi
        done <<< "$targets"
    done < <(grep -nE '\]\([^)]+\.md' "$source_file" 2>/dev/null || true)
}

# Scan each file
for file in "${ALL_MD_FILES[@]}"; do
    rel_path="${file#"$PROMPTKIT_ROOT"/}"
    file_has_issues=false
    
    line_num=0
    while IFS= read -r line_content || [[ -n "$line_content" ]]; do
        ((line_num++))

        # Check template references (.promptkit/templates/*)
        if [[ "$line_content" =~ \.promptkit/templates/([a-zA-Z0-9_-]+\.md) ]]; then
            template_name="${BASH_REMATCH[1]}"
            if ! check_file_reference "$file" "Template" "templates/$template_name" "$line_num"; then
                file_has_issues=true
            fi
        fi

        # Check workflow references (.promptkit/workflows/*)
        if [[ "$line_content" =~ \.promptkit/workflows/([a-zA-Z0-9_-]+\.md) ]]; then
            workflow_name="${BASH_REMATCH[1]}"
            if ! check_file_reference "$file" "Workflow" "workflows/$workflow_name" "$line_num"; then
                file_has_issues=true
            fi
        fi

        # Check protocol references (.promptkit/protocols/*)
        if [[ "$line_content" =~ \.promptkit/protocols/([a-zA-Z0-9_-]+\.md) ]]; then
            protocol_name="${BASH_REMATCH[1]}"
            if ! check_file_reference "$file" "Protocol" "protocols/$protocol_name" "$line_num"; then
                file_has_issues=true
            fi
        fi

        # Check relative template references (templates/* without .promptkit prefix)
        if [[ ! "$line_content" =~ \.promptkit ]] && [[ "$line_content" =~ (^|[^./])templates/([a-zA-Z0-9_-]+\.md) ]]; then
            template_name="${BASH_REMATCH[2]}"
            if ! check_file_reference "$file" "Template (relative)" "templates/$template_name" "$line_num"; then
                file_has_issues=true
            fi
        fi
    done < <(cat -- "$file")

    # Check generic markdown links (reader-facing 404 guard). Historical records
    # are exempt, matching the canonical-count drift guard's exemption policy.
    if ! is_link_exempt "$rel_path"; then
        check_markdown_links "$file" "$rel_path"
    fi

    # Check for workflow triggers without matching files
    # Capture the whole trigger token. A pattern that stops at the first hyphen
    # truncates names such as pk:init-repo to "init", which hides the real token
    # behind an unrelated alias match.
    triggers=""
    if ! is_trigger_scan_exempt "$rel_path"; then
        triggers=$(grep -oE 'pk:[a-z][a-z0-9-]*' "$file" | sed 's/pk://' | sort -u)
    fi
    for trigger in $triggers; do
        expected_workflow="$WORKFLOWS_DIR/$trigger.md"
        if [ ! -f "$expected_workflow" ]; then
            # Check if it's a known alias
            case "$trigger" in
                # Documented aliases that route to an existing workflow.
                db|profile|research|reflect|handoff|issue|kanban|scan|latency|grill|spike|retro|design|init|init-repo|task|update|refresh)
                    # Known aliases, skip warning
                    ;;
                # A name that is deliberately NOT a trigger. The execution-control
                # design records reject a top-level pk:execution-control command;
                # existing workflows retain ownership.
                execution-control)
                    # Deliberately negated name, skip warning
                    ;;
                *)
                    echo "  ⚠️  WARNING: $rel_path"
                    echo "     Trigger 'pk:$trigger' may not have matching workflow"
                    echo "     Expected: workflows/$trigger.md"
                    echo ""
                    ((WARNING_COUNT++))
                    ;;
            esac
        fi
    done
    
    if [ "$file_has_issues" = false ]; then
        echo "  ✅ $rel_path"
    fi
done

# Validate template directory completeness from the filesystem inventory
echo ""
echo "📋 Checking template directory completeness..."

EXPECTED_TEMPLATE_COUNT=29
template_inventory=()
for template_path in "$TEMPLATES_DIR"/*.md; do
    [ -e "$template_path" ] || continue
    template_inventory+=("$(basename "$template_path")")
done

if [ "${#template_inventory[@]}" -ne "$EXPECTED_TEMPLATE_COUNT" ]; then
    echo "  ❌ MISSING templates: expected $EXPECTED_TEMPLATE_COUNT markdown templates, found ${#template_inventory[@]}"
    ((ERROR_COUNT++))
fi

for template in "${template_inventory[@]}"; do
    if [ -s "$TEMPLATES_DIR/$template" ]; then
        echo "  ✅ templates/$template"
    else
        echo "  ❌ EMPTY: templates/$template"
        ((ERROR_COUNT++))
    fi
done

# Workflows: the inventory is the directory itself; ADR 0002 requires each one
# to carry a reference row in protocols/setup.md.
echo ""
echo "🔄 Checking core workflow files..."

EXPECTED_WORKFLOW_COUNT=26
workflow_inventory=()
for workflow_path in "$WORKFLOWS_DIR"/*.md; do
    [ -e "$workflow_path" ] || continue
    workflow_inventory+=("$(basename "$workflow_path")")
done

if [ "${#workflow_inventory[@]}" -ne "$EXPECTED_WORKFLOW_COUNT" ]; then
    echo "  ❌ MISSING workflows: expected $EXPECTED_WORKFLOW_COUNT workflows, found ${#workflow_inventory[@]}"
    ((ERROR_COUNT++))
fi

for workflow in "${workflow_inventory[@]}"; do
    if [ ! -s "$WORKFLOWS_DIR/$workflow" ]; then
        echo "  ❌ EMPTY: workflows/$workflow"
        ((ERROR_COUNT++))
        continue
    fi
    if grep -Fq "workflows/$workflow" "$PROTOCOLS_DIR/setup.md"; then
        echo "  ✅ workflows/$workflow"
    else
        echo "  ❌ UNREGISTERED in protocols/setup.md: workflows/$workflow"
        ((ERROR_COUNT++))
    fi
done

# Protocols: same derivation, same registration requirement, setup.md included.
echo ""
echo "📜 Checking protocol files..."

EXPECTED_PROTOCOL_COUNT=9
protocol_inventory=()
for protocol_path in "$PROTOCOLS_DIR"/*.md; do
    [ -e "$protocol_path" ] || continue
    protocol_inventory+=("$(basename "$protocol_path")")
done

if [ "${#protocol_inventory[@]}" -ne "$EXPECTED_PROTOCOL_COUNT" ]; then
    echo "  ❌ protocols/: expected $EXPECTED_PROTOCOL_COUNT protocols, found ${#protocol_inventory[@]}"
    ((ERROR_COUNT++))
fi

for protocol in "${protocol_inventory[@]}"; do
    if [ ! -s "$PROTOCOLS_DIR/$protocol" ]; then
        echo "  ❌ EMPTY: protocols/$protocol"
        ((ERROR_COUNT++))
        continue
    fi
    if grep -Fq "protocols/$protocol" "$PROTOCOLS_DIR/setup.md"; then
        echo "  ✅ protocols/$protocol"
    else
        echo "  ❌ UNREGISTERED in protocols/setup.md: protocols/$protocol"
        ((ERROR_COUNT++))
    fi
done

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Validation Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ERROR_COUNT -eq 0 ] && [ $WARNING_COUNT -eq 0 ]; then
    echo ""
    echo -e "\n\033[0;32m✅ All references valid! No broken links found.\033[0m"
    echo "   PromptKit OS is ready for production use."
    echo ""
    exit 0
else
    echo ""
    if [ $ERROR_COUNT -gt 0 ]; then
        echo "  ❌ Errors: $ERROR_COUNT"
    fi
    if [ $WARNING_COUNT -gt 0 ]; then
        echo "  ⚠️  Warnings: $WARNING_COUNT"
    fi
    echo ""
    
    if [ $ERROR_COUNT -gt 0 ]; then
        echo "❌ Validation failed. Fix broken references before deployment."
        echo ""
        exit 1
    elif [ "$STRICT_MODE" -eq 1 ]; then
        echo "❌ Validation failed (strict): $WARNING_COUNT warning(s). Fix or justify them before deployment."
        echo ""
        exit 1
    else
        echo "⚠️  Validation passed with warnings. Review recommended."
        echo ""
        exit 0
    fi
fi
