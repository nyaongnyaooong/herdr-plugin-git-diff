#!/bin/sh
# Toggle the diff tab: open it from a work tab, or close it and go back to that tab.
set -eu

herdr=${HERDR_BIN_PATH:-herdr}
dir=$HERDR_PLUGIN_STATE_DIR

# pane-<origin tab> holds "<diff pane> <diff tab>" while the diff tab is open.
# The tab is closed whole: other plugins (ai-usage) add their own panes to new tabs.
close_diff() {
    origin=${1##*/pane-}
    read -r id tab <"$1" || true
    rm -f "$1"
    if [ -n "${tab:-}" ]; then
        "$herdr" tab close "$tab" >/dev/null 2>&1 || true
    else
        # State written by the old split-pane version.
        "$herdr" plugin pane close "$id" >/dev/null 2>&1 || true
    fi
    "$herdr" tab focus "$origin" >/dev/null 2>&1 || true
}

# Pressed inside the diff tab, or in a work tab whose diff tab is still open.
for f in "$dir"/pane-*; do
    [ -f "$f" ] || continue
    read -r id tab <"$f" || true
    if [ "$id" = "$HERDR_PANE_ID" ] || [ "${tab:-}" = "${HERDR_TAB_ID:-}" ] ||
        { [ "$f" = "$dir/pane-${HERDR_TAB_ID:-}" ] && "$herdr" pane get "$id" >/dev/null 2>&1; }; then
        close_diff "$f"
        exit 0
    fi
done
rm -f "$dir/pane-${HERDR_TAB_ID:-default}"

cwd=$("$herdr" pane get "$HERDR_PANE_ID" | jq -r '.result.pane.foreground_cwd // .result.pane.cwd')
repos="$dir/repos-${HERDR_TAB_ID:-default}"
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

count=$(wc -l <"$repos" | tr -d ' ')
if [ "$count" -eq 1 ]; then
    label="diff: $(basename "$(cat "$repos")")"
else
    label="diff: 레포 ${count}개"
fi

# No --cwd: the manifest's relative pane command resolves against it.
state="$dir/pane-${HERDR_TAB_ID:-default}"
"$herdr" plugin pane open --plugin "$HERDR_PLUGIN_ID" --entrypoint diff --placement tab \
    --workspace "$HERDR_WORKSPACE_ID" --env "GIT_DIFF_REPOS=$repos" --focus |
    jq -r '.result.plugin_pane.pane | "\(.pane_id) \(.tab_id)"' >"$state"
read -r _ tab <"$state"
"$herdr" tab rename "$tab" "$label" >/dev/null
