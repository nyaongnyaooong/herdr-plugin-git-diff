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
repos="$HERDR_PLUGIN_STATE_DIR/repos-${HERDR_TAB_ID:-default}"
if root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null); then
    printf '%s\n' "$root" >"$repos"
else
    # Parent folder holding several repos: show only the ones with uncommitted changes.
    find "$cwd" -maxdepth 3 -name node_modules -prune -o -name .git -print 2>/dev/null |
        while IFS= read -r git_dir; do
            repo=$(dirname "$git_dir")
            if [ -n "$(git -C "$repo" status --porcelain 2>/dev/null)" ]; then
                printf '%s\n' "$repo"
            fi
        done | sort >"$repos"
    if [ ! -s "$repos" ]; then
        "$herdr" notification show "Git Diff" --body "변경된 git 저장소가 없습니다: $cwd" >/dev/null
        exit 0
    fi
fi

# No --cwd: the manifest's relative pane command resolves against it.
"$herdr" plugin pane open --plugin "$HERDR_PLUGIN_ID" --entrypoint diff --placement split \
    --target-pane "$HERDR_PANE_ID" --direction right --env "GIT_DIFF_REPOS=$repos" --no-focus |
    jq -r '.result.plugin_pane.pane.pane_id' >"$state"
