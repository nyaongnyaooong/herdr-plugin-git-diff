#!/bin/sh
# Toggle the diff pane next to the focused pane: close it if open, else open it.
set -eu

herdr=${HERDR_BIN_PATH:-herdr}
state="$HERDR_PLUGIN_STATE_DIR/pane-${HERDR_TAB_ID:-default}"

if [ -f "$state" ]; then
    id=$(cat "$state")
    rm -f "$state"
    if "$herdr" pane get "$id" >/dev/null 2>&1; then
        "$herdr" plugin pane close "$id" >/dev/null
        exit 0
    fi
fi

cwd=$("$herdr" pane get "$HERDR_PANE_ID" | jq -r '.result.pane.foreground_cwd // .result.pane.cwd')
if ! root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null); then
    "$herdr" notification show "Git Diff" --body "git 저장소가 아닙니다: $cwd" >/dev/null
    exit 0
fi

"$herdr" plugin pane open --plugin "$HERDR_PLUGIN_ID" --entrypoint diff --placement split \
    --target-pane "$HERDR_PANE_ID" --direction right --cwd "$root" --no-focus |
    jq -r '.result.plugin_pane.pane.pane_id' >"$state"
