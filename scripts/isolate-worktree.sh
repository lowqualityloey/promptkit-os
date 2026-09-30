#!/usr/bin/env bash
# PromptKit OS Git Worktree Isolation Utility
# Creates, lists, merges, and safely removes isolated Git worktrees
# for risky multi-file tasks, spike explorations, or subagent runs.
set -euo pipefail

ACTION="${1:-list}"
TASK_ID="${2:-}"
FORCE=0

if [[ "${3:-}" == "--force" || "${4:-}" == "--force" ]]; then
    FORCE=1
fi
if [[ "$ACTION" == "--force" ]]; then
    ACTION="${2:-list}"
    TASK_ID="${3:-}"
    FORCE=1
fi
if [[ "$TASK_ID" == "--force" ]]; then
    TASK_ID=""
    FORCE=1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then
    echo "Error: Not inside a git repository." >&2
    exit 1
fi

WORKTREE_BASE="$REPO_ROOT/.worktrees"
GITIGNORE="$REPO_ROOT/.gitignore"

# Ensure .worktrees/ is in .gitignore
if [[ -f "$GITIGNORE" ]]; then
    if ! grep -q "^\.worktrees/\?$" "$GITIGNORE"; then
        echo -e "\n# PromptKit OS isolated worktrees\n.worktrees/" >> "$GITIGNORE"
        echo "  [+] Added .worktrees/ to .gitignore"
    fi
else
    echo -e "# PromptKit OS isolated worktrees\n.worktrees/" > "$GITIGNORE"
    echo "  [+] Created .gitignore with .worktrees/"
fi

case "$ACTION" in
    create)
        if [[ -z "$TASK_ID" ]]; then
            echo "Error: TaskId is required for 'create'. Usage: ./scripts/isolate-worktree.sh create <task-id>" >&2
            exit 1
        fi
        BRANCH_NAME="worktree/$TASK_ID"
        TARGET_PATH="$WORKTREE_BASE/$TASK_ID"

        if [[ -d "$TARGET_PATH" ]]; then
            echo "Warning: Worktree path already exists: $TARGET_PATH"
            exit 0
        fi

        mkdir -p "$WORKTREE_BASE"
        echo -e "\033[0;36m🌿 Creating isolated worktree at $TARGET_PATH on branch '$BRANCH_NAME'...\033[0m"
        if ! git worktree add -b "$BRANCH_NAME" "$TARGET_PATH"; then
            echo "Error: Failed to create worktree at $TARGET_PATH." >&2
            exit 1
        fi
        echo -e "\033[0;32m  ✅ Worktree created successfully.\033[0m"
        echo "  To enter worktree: cd $TARGET_PATH"
        ;;

    list|status)
        echo -e "\033[0;36m📋 Active Git Worktrees:\033[0m"
        git worktree list
        ;;

    merge)
        if [[ -z "$TASK_ID" ]]; then
            echo "Error: TaskId is required for 'merge'. Usage: ./scripts/isolate-worktree.sh merge <task-id>" >&2
            exit 1
        fi
        BRANCH_NAME="worktree/$TASK_ID"
        echo -e "\033[0;36m🔀 Merging branch '$BRANCH_NAME' into current branch...\033[0m"
        if ! git merge "$BRANCH_NAME"; then
            echo "Error: Failed to merge branch '$BRANCH_NAME'." >&2
            exit 1
        fi
        echo -e "\033[0;32m  ✅ Merge completed. Remember to remove the worktree with 'remove $TASK_ID' when finished.\033[0m"
        ;;

    remove)
        if [[ -z "$TASK_ID" ]]; then
            echo "Error: TaskId is required for 'remove'. Usage: ./scripts/isolate-worktree.sh remove <task-id> [--force]" >&2
            exit 1
        fi
        BRANCH_NAME="worktree/$TASK_ID"
        TARGET_PATH="$WORKTREE_BASE/$TASK_ID"

        echo -e "\033[0;36m🧹 Removing worktree at $TARGET_PATH...\033[0m"
        if [[ -d "$TARGET_PATH" ]]; then
            if [[ "$FORCE" -eq 1 ]]; then
                if ! git worktree remove "$TARGET_PATH" --force; then
                    echo "Error: Failed to forcefully remove worktree at $TARGET_PATH." >&2
                    exit 1
                fi
            else
                if ! git worktree remove "$TARGET_PATH"; then
                    echo -e "\033[0;31mError: Worktree has uncommitted changes or unmerged branches.\033[0m" >&2
                    echo "Use --force to forcefully remove it." >&2
                    exit 1
                fi
            fi
        else
            if ! git worktree prune; then
                echo "Error: Failed to prune git worktree." >&2
                exit 1
            fi
        fi

        if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
            if [[ "$FORCE" -eq 1 ]]; then
                if ! git branch -D "$BRANCH_NAME"; then
                    echo "Error: Failed to forcefully delete branch $BRANCH_NAME." >&2
                    exit 1
                fi
                echo "  [-] Force deleted branch $BRANCH_NAME"
            else
                if ! git branch -d "$BRANCH_NAME"; then
                    echo -e "\033[0;31mError: Branch $BRANCH_NAME is not fully merged.\033[0m" >&2
                    echo "Use --force to forcefully delete it." >&2
                    exit 1
                fi
                echo "  [-] Deleted branch $BRANCH_NAME"
            fi
        fi
        echo -e "\033[0;32m  ✅ Worktree cleaned up successfully.\033[0m"
        ;;

    *)
        echo "Usage: ./scripts/isolate-worktree.sh [create|list|merge|remove|status] [task-id] [--force]" >&2
        exit 1
        ;;
esac
