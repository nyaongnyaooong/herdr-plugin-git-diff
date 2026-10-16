#!/bin/sh
# Toggle the diff pane next to the focused pane: close it if open, else open it.
set -eu

herdr=${HERDR_BIN_PATH:-herdr}
state="$HERDR_PLUGIN_STATE_DIR/pane-${HERDR_TAB_ID:-default}"

# State files hold "<pane_id>" for a split, "<pane_id> <tab_id>" for a diff tab.
# A diff tab is closed whole: other plugins (ai-usage) add their own panes to new tabs.
close_diff() {
    rm -f "$1"
    if [ -n "${3:-}" ]; then
        "$herdr" tab close "$3" >/dev/null
    else
        "$herdr" plugin pane close "$2" >/dev/null
    fi
}

# Pressed inside the diff pane itself (e.g. in its own tab): close it.
for f in "$HERDR_PLUGIN_STATE_DIR"/pane-*; do
    [ -f "$f" ] || continue
    read -r id tab <"$f" || true
    if [ "$id" = "$HERDR_PANE_ID" ]; then
        close_diff "$f" "$id" "${tab:-}"
        exit 0
    fi
done

if [ -f "$state" ]; then
    read -r id tab <"$state" || true
    if "$herdr" pane get "$id" >/dev/null 2>&1; then
        close_diff "$state" "$id" "${tab:-}"
        exit 0
    fi
    rm -f "$state"
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
# A tab already split left/right gets the diff in a new tab instead.
if "$herdr" pane layout --pane "$HERDR_PANE_ID" |
    jq -e '.result.layout.splits | any(.direction == "right")' >/dev/null; then
    "$herdr" plugin pane open --plugin "$HERDR_PLUGIN_ID" --entrypoint diff --placement tab \
        --workspace "$HERDR_WORKSPACE_ID" --env "GIT_DIFF_REPOS=$repos" --focus |
        jq -r '.result.plugin_pane.pane | "\(.pane_id) \(.tab_id)"' >"$state"
    exit 0
fi

"$herdr" plugin pane open --plugin "$HERDR_PLUGIN_ID" --entrypoint diff --placement split \
    --target-pane "$HERDR_PANE_ID" --direction right --env "GIT_DIFF_REPOS=$repos" --no-focus |
    jq -r '.result.plugin_pane.pane.pane_id' >"$state"
# New splits start at 0.5; shrink the Claude pane to 0.25 so it is 1:3 with the diff.
"$herdr" pane resize --pane "$HERDR_PANE_ID" --direction left --amount 0.25 >/dev/null
