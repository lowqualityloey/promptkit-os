#!/usr/bin/env bash

export PK_PICKER_RESULT PK_PICKER_ACTION

pk_picker_clear() {
    printf '\033[2J\033[H'
    if [[ "${PK_PICKER_BANNER_ACTIVE:-0}" == 1 ]]; then
        local cols banner="${PK_PICKER_BANNER_PATH:-}"
        cols="$(tput cols 2>/dev/null || true)"
        if [[ -f "$banner" && "$cols" =~ ^[0-9]+$ && "$cols" -ge 120 ]]; then
            cat "$banner"
        else
            printf '◆ PromptKit OS · Project Setup ◆\n'
        fi
        printf '\n'
    else
        printf '◆ PromptKit OS Setup ◆\n\n'
    fi
}

pk_picker_read_key() {
    local key rest
    if ! IFS= read -r -s -N 1 key; then
        PK_PICKER_KEY=cancel
        return
    fi
    if [[ "$key" == $'\e' ]]; then
        rest=""
        IFS= read -r -s -N 2 -t 0.1 rest || true
        case "$rest" in
            '[A') PK_PICKER_KEY=up ;;
            '[B') PK_PICKER_KEY=down ;;
            *) PK_PICKER_KEY=cancel ;;
        esac
    elif [[ "$key" == $'\r' || "$key" == $'\n' ]]; then
        PK_PICKER_KEY=enter
    elif [[ "$key" == ' ' ]]; then
        PK_PICKER_KEY=space
    elif [[ "$key" == 'q' || "$key" == 'Q' ]]; then
        PK_PICKER_KEY=cancel
    elif [[ "$key" == 'b' || "$key" == 'B' ]]; then
        PK_PICKER_KEY=back
    else
        PK_PICKER_KEY=other
    fi
}

pk_picker_render() {
    local title="$1" subtitle="$2" mode="$3" index="$4" i marker
    pk_picker_clear
    printf '◈ %s\n' "$title"
    [[ -z "$subtitle" ]] || printf '%s\n' "$subtitle"
    printf '\n'
    for i in "${!PK_PICKER_ITEMS[@]}"; do
        marker=' '
        [[ "$i" -eq "$index" ]] && marker='›'
        if [[ "$mode" == multi ]]; then
            if [[ ",$PK_PICKER_SELECTED," == *",${PK_PICKER_ITEMS[$i]},"* ]]; then
                printf ' %s [✓] %s\n' "$marker" "${PK_PICKER_LABELS[$i]}"
            else
                printf ' %s [ ] %s\n' "$marker" "${PK_PICKER_LABELS[$i]}"
            fi
        else
            if [[ "$i" -eq "$index" ]]; then
                printf ' %s ◉ %s\n' "$marker" "${PK_PICKER_LABELS[$i]}"
            else
                printf ' %s ○ %s\n' "$marker" "${PK_PICKER_LABELS[$i]}"
            fi
        fi
    done
    printf '\n↑/↓ Move'
    if [[ "$mode" == multi ]]; then
        printf '   Space Toggle   Enter Done'
    else
        printf '   Enter Select'
    fi
    printf '   q Cancel\n'
}

pk_picker_single() {
    local title="$1" subtitle="$2" default_index="$3"; shift 3
    local index="$default_index" count="$#"
    PK_PICKER_ITEMS=("$@")
    PK_PICKER_LABELS=("$@")
    PK_PICKER_ACTION=select
    while true; do
        pk_picker_render "$title" "$subtitle" single "$index"
        pk_picker_read_key
        case "$PK_PICKER_KEY" in
            up) index=$((index - 1)); ((index < 0)) && index=$((count - 1)) ;;
            down) index=$((index + 1)); ((index >= count)) && index=0 ;;
            enter) PK_PICKER_RESULT="$index"; PK_PICKER_BANNER_ACTIVE=0; return 0 ;;
            cancel) PK_PICKER_ACTION=cancel; PK_PICKER_BANNER_ACTIVE=0; return 0 ;;
        esac
    done
}

pk_picker_multi() {
    local title="$1" subtitle="$2" defaults="$3" index=0 count; shift 3
    PK_PICKER_ITEMS=()
    PK_PICKER_LABELS=()
    while (($# >= 2)); do
        PK_PICKER_ITEMS+=("$1")
        PK_PICKER_LABELS+=("$2")
        shift 2
    done
    PK_PICKER_SELECTED="$defaults"
    count=${#PK_PICKER_ITEMS[@]}
    PK_PICKER_ACTION=select
    while true; do
        pk_picker_render "$title" "$subtitle" multi "$index"
        pk_picker_read_key
        case "$PK_PICKER_KEY" in
            up) index=$((index - 1)); ((index < 0)) && index=$((count - 1)) ;;
            down) index=$((index + 1)); ((index >= count)) && index=0 ;;
            space)
                local item="${PK_PICKER_ITEMS[$index]}"
                if [[ ",$PK_PICKER_SELECTED," == *",$item,"* ]]; then
                    local -a selected_parts=()
                    local selected_part updated_selection=""
                    IFS=, read -r -a selected_parts <<< "$PK_PICKER_SELECTED"
                    for selected_part in "${selected_parts[@]}"; do
                        if [[ "$selected_part" != "$item" ]]; then
                            [[ -z "$updated_selection" ]] || updated_selection+=,
                            updated_selection+="$selected_part"
                        fi
                    done
                    PK_PICKER_SELECTED="$updated_selection"
                elif [[ -z "$PK_PICKER_SELECTED" ]]; then
                    PK_PICKER_SELECTED="$item"
                else
                    PK_PICKER_SELECTED="$PK_PICKER_SELECTED,$item"
                fi
                ;;
            enter) PK_PICKER_RESULT="$PK_PICKER_SELECTED"; PK_PICKER_BANNER_ACTIVE=0; return 0 ;;
            cancel) PK_PICKER_ACTION=cancel; PK_PICKER_BANNER_ACTIVE=0; return 0 ;;
        esac
    done
}
