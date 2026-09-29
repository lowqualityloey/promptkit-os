#!/usr/bin/env bash
set -euo pipefail

repo_root=$(builtin cd -- "$(dirname -- "$0")/../.." && pwd -P)
scanner="$repo_root/scripts/scan-staged-secrets.sh"
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

positive="$tmp/positive"
mkdir -p "$positive"
git -C "$positive" init -q
git -C "$positive" config user.name "PromptKit scanner fixture"
git -C "$positive" config user.email "scanner-fixture@example.invalid"
printf '%s\n' one two three four five six seven >"$positive/context.txt"
printf '%s\n' 'ordinary staged baseline' >"$positive/masked.fixture"
printf '%s\n' 'masked.fixture diff=mask' >"$positive/.gitattributes"
git -C "$positive" add -- context.txt
git -C "$positive" add -- masked.fixture .gitattributes
git -C "$positive" commit -q -m baseline
git -C "$positive" config diff.mask.textconv 'printf masked-content'

private_marker='-----BEGIN RSA'
private_marker+=' PRIVATE KEY-----'
aws_key="AKIA$(printf '%016d' 0)"
classic_token="ghp_$(printf '%036d' 0)"
fine_token="github_pat_$(printf '%082d' 0)"
stripe_key="sk_live_$(printf '%024d' 0)"
jwt='eyJ'
jwt+='abcdefghij.'
jwt+='klmnopqrst.'
jwt+='uvwxyzABCD'
password_name=$(printf 'pass%s' 'word')
password_value='synthetic-value-only'
password_assignment="$password_name=\"$password_value\""
aws_key_on_later_line="AKIA$(printf '%016d' 1)"
printf '%s\n' one two three four "$aws_key_on_later_line" six seven >"$positive/context.txt"
printf '%s\n' \
    "$private_marker" \
    "$aws_key" \
    "$classic_token" \
    "$fine_token" \
    "$stripe_key" \
    "$jwt" \
    "$password_assignment" >"$positive/ordinary.txt"

newline_path=$(printf 'staged\ncredential.txt')
printf '%s\n' "$classic_token" >"$positive/$newline_path"
pathspec_path='path[credential].txt'
printf '%s\n' "$classic_token" >"$positive/$pathspec_path"
credential_path="credential-${classic_token}.txt"
printf '%s\n' "$classic_token" >"$positive/$credential_path"
password_path='credential-password=synthetic-value.txt'
printf '%s\n' "$classic_token" >"$positive/$password_path"
printf '%s\n' "$aws_key" >"$positive/masked.fixture"
git -C "$positive" add -- .
masked_diff=$(git -C "$positive" diff --cached --no-ext-diff --unified=0 -- masked.fixture)
[[ "$masked_diff" != *"$aws_key"* ]] || fail 'textconv regression fixture did not hide the staged addition'
printf -v escaped_newline_path '%q' "$newline_path"
printf -v escaped_pathspec_path '%q' "$pathspec_path"

clean="$tmp/clean"
mkdir -p "$clean"
git -C "$clean" init -q
git -C "$clean" config user.name "PromptKit scanner fixture"
git -C "$clean" config user.email "scanner-fixture@example.invalid"
printf '%s\n' 'ordinary staged content' >"$clean/README.md"
git -C "$clean" add -- README.md

invalid_root="$tmp/not-a-git-repository-$aws_key"

unscannable="$tmp/unscannable"
mkdir -p "$unscannable"
git -C "$unscannable" init -q
git -C "$unscannable" config user.name "PromptKit scanner fixture"
git -C "$unscannable" config user.email "scanner-fixture@example.invalid"
printf '%s\n' 'opaque.fixture -diff' >"$unscannable/.gitattributes"
printf '%s\n' 'ordinary staged baseline' >"$unscannable/opaque.fixture"
printf '%s\n' 'ordinary staged baseline' >"$unscannable/nul.fixture"
git -C "$unscannable" add -- .gitattributes opaque.fixture nul.fixture
git -C "$unscannable" commit -q -m baseline
printf '%s\n' "$aws_key" >"$unscannable/opaque.fixture"
printf 'prefix\0%s\n' "$aws_key" >"$unscannable/nul.fixture"
git -C "$unscannable" add -- opaque.fixture nul.fixture
for path in opaque.fixture nul.fixture; do
    binary_diff=$(git -C "$unscannable" diff --cached --no-ext-diff --no-textconv --unified=0 -- "$path")
    [[ "$binary_diff" == *'Binary files '*" differ"* ]] || fail "binary-diff regression fixture did not produce Git binary output for $path"
done

run_engine() {
    local awk_bin="$1"
    local output status category escaped_value

    status=0
    output=$(PROMPTKIT_AWK="$awk_bin" bash "$scanner" "$positive") || status=$?
    [[ "$status" -eq 1 ]] || fail "$awk_bin should return 1 when supported patterns are found"

    for category in \
        'private-key marker' \
        'AWS access-key pattern' \
        'GitHub token pattern' \
        'GitHub fine-grained token pattern' \
        'Stripe live-key pattern' \
        'JWT-like token pattern' \
        'password-assignment pattern'; do
        [[ "$output" == *"$category"* ]] || fail "$awk_bin missed the $category detector"
    done

    [[ $(grep -Fc 'GitHub token pattern' <<< "$output") -eq 5 ]] ||
        fail "$awk_bin missed a pathname positive control"
    [[ "$output" == *"$escaped_newline_path:1"* ]] ||
        fail "$awk_bin did not safely report the escaped newline path"
    [[ "$output" == *"$escaped_pathspec_path:1"* ]] ||
        fail "$awk_bin did not safely report the literal-pathspec path"
    [[ "$output" == *"context.txt:5"* ]] ||
        fail "$awk_bin reported an incorrect line number for a modified file"
    [[ "$output" == *"masked.fixture:1"* ]] ||
        fail "$awk_bin let Git textconv hide a staged credential"
    [[ "$output" == *"credential-REDACTED.txt:1"* ]] ||
        fail "$awk_bin exposed a credential-shaped filename instead of redacting it"
    [[ "$output" == *"credential-REDACTED:1"* && "$output" != *'synthetic-value'* ]] ||
        fail "$awk_bin exposed a password-shaped value in a staged filename"

    for expected in 1 2 3 4 5 6 7; do
        [[ "$output" == *"ordinary.txt:$expected"* ]] ||
            fail "$awk_bin reported an incorrect line number for ordinary.txt"
    done

    [[ $(grep -c '^Potential ' <<< "$output") -eq 13 ]] ||
        fail "$awk_bin returned an unexpected detection count"

    for escaped_value in \
        "$private_marker" "$aws_key" "$classic_token" "$fine_token" \
        "$stripe_key" "$jwt" "$password_assignment" "$aws_key_on_later_line"; do
        [[ "$output" != *"$escaped_value"* ]] || fail "$awk_bin leaked a matching value"
    done

    status=0
    output=$(PROMPTKIT_AWK="$awk_bin" bash "$scanner" "$clean") || status=$?
    [[ "$status" -eq 0 && -z "$output" ]] ||
        fail "$awk_bin should pass clean staged content without output"

    status=0
    output=$(PROMPTKIT_AWK="$awk_bin" bash "$scanner" "$invalid_root" 2>&1) || status=$?
    [[ "$status" -eq 2 ]] || fail "$awk_bin should fail closed when the repository cannot be scanned"
    [[ "$output" == *'stop before committing'* ]] ||
        fail "$awk_bin did not explain that an incomplete scan must stop"
    [[ "$output" != *"$aws_key"* ]] ||
        fail "$awk_bin exposed a raw Git diagnostic for the credential-shaped repository path"

    for path in opaque.fixture nul.fixture; do
        git -C "$unscannable" reset -q HEAD -- opaque.fixture nul.fixture
        git -C "$unscannable" add -- "$path"
        status=0
        output=$(PROMPTKIT_AWK="$awk_bin" bash "$scanner" "$unscannable" 2>&1) || status=$?
        [[ "$status" -eq 2 ]] || fail "$awk_bin should fail closed when Git classifies staged $path as binary"
        [[ "$output" == *'could not inspect a binary diff'* && "$output" != *"$aws_key"* ]] ||
            fail "$awk_bin did not fail closed without exposing binary staged content from $path"
    done

    printf 'PASS: %s detected thirteen redacted matches, ignored textconv, handled tricky paths and modified-file lines; clean input passed and scan errors and binary-classified diffs failed closed.\n' "$awk_bin"
}

run_engine awk
if command -v mawk >/dev/null 2>&1; then
    run_engine mawk

    traditional_awk="$tmp/mawk-traditional"
    printf '%s\n' '#!/usr/bin/env bash' 'exec mawk -W traditional "$@"' >"$traditional_awk"
    chmod +x "$traditional_awk"
    run_engine "$traditional_awk"
fi

printf '%s\n' 'Staged secret scan regression tests passed.'
