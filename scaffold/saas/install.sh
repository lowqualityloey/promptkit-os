#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-$(pwd)}"

IS_TTY=0
if [[ -t 0 && -t 1 && -z "${PROMPTKIT_NO_INTERACTIVE:-}" ]]; then
    IS_TTY=1
fi

# 1. Warn if non-empty
if [[ -d "$PROJECT_ROOT" && "$(ls -A "$PROJECT_ROOT")" ]]; then
    echo -e "\033[0;33m⚠️  Warning: Target directory is not empty ($PROJECT_ROOT)\033[0m"
    if [[ "$IS_TTY" -eq 1 ]]; then
        read -p "Continue anyway? [y/N] " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Aborting."
            exit 1
        fi
    else
        echo "Non-interactive mode, aborting on non-empty directory."
        exit 1
    fi
fi

# Auth Provider Interactive Menu
AUTH_PROVIDER="next-auth"
if [[ "$IS_TTY" -eq 1 ]]; then
    echo -e "\n\033[0;36m💡 Auth Provider Selection\033[0m"
    echo -e "\033[0;90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "  \033[1;33m[1] NextAuth (v5) (Recommended)\033[0m"
    echo -e "  \033[0;90m[2] Lucia (coming soon)\033[0m"
    echo -e "  \033[0;90m[3] Clerk (coming soon)\033[0m"
    echo -e "\033[0;90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    read -p "Choose auth provider [1-3, default 1]: " auth_choice
    if [[ "$auth_choice" == "2" || "$auth_choice" == "3" ]]; then
        echo -e "\033[0;33mComing in a future release. Defaulting to NextAuth.\033[0m"
    fi
fi

# Copy boilerplate
echo -e "Scaffolding Next.js App Router + NextAuth + Stripe + Prisma + PostgreSQL boilerplate..."
TEMPLATE_DIR="$SCRIPT_DIR/templates/nextjs-app"
if [[ ! -d "$TEMPLATE_DIR" ]]; then
    echo -e "\033[0;31mError: Template directory not found at $TEMPLATE_DIR\033[0m"
    exit 1
fi
cp -a "$TEMPLATE_DIR/." "$PROJECT_ROOT/"

# npm install prompt
RUN_NPM=0
if [[ "$IS_TTY" -eq 1 ]]; then
    read -p "Run npm install? [Y/n] " npm_choice
    if [[ "$npm_choice" =~ ^[Yy]$ ]] || [[ -z "$npm_choice" ]]; then
        RUN_NPM=1
    fi
fi

if [[ "$RUN_NPM" -eq 1 ]]; then
    echo "Running npm install..."
    (cd "$PROJECT_ROOT" && npm install)
fi

# prisma generate prompt
RUN_PRISMA=0
if [[ "$IS_TTY" -eq 1 ]]; then
    read -p "Run npx prisma generate? [Y/n] " prisma_choice
    if [[ "$prisma_choice" =~ ^[Yy]$ ]] || [[ -z "$prisma_choice" ]]; then
        RUN_PRISMA=1
    fi
fi

if [[ "$RUN_PRISMA" -eq 1 ]]; then
    echo "Running npx prisma generate..."
    (cd "$PROJECT_ROOT" && npx prisma generate)
fi

echo -e "\n\033[0;32mSaaS Scaffold complete! ✨\033[0m"
