#!/usr/bin/env bash
# Advisory-only PreToolUse hook for Edit/Write/NotebookEdit.
#
# jj's working copy is always the current change (@) and auto-snapshots on
# every edit - unlike git, nothing stops you from editing into an undescribed
# change, or into a change you didn't mean to be on if something upstream ran
# jj edit/new/undo mid-session. This surfaces a hint at two such moments:
#   1. First edit this session into a change with no description yet.
#   2. The current change id drifted since this session last checked it.
#
# Never blocks - always exits 0. Fails open silently if jj/jq are missing,
# the target path isn't inside a jj repo, or any jj/jq call errors.
#
# Claude Code only - no Cursor port (yet). Cursor CAN do advisory allow+message,
# just not on preToolUse: that hook's output is allow/deny only, with
# agent_message/user_message shown only on deny. The actual equivalent is
# postToolUse, whose output supports additional_context (injected into the
# conversation after the tool runs, without blocking). Porting this hook would
# mean moving the check to after the edit instead of before - not yet done.
# See repo root CONTRIBUTING.md "Writing hooks for both tools" (confirmed against
# cursor.com/docs/hooks, 2026-09-12).
set -uo pipefail

command -v jj >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')"
[ -n "$file_path" ] || exit 0

dir="$(dirname "$file_path")"
[ -d "$dir" ] || exit 0

root="$(cd "$dir" 2>/dev/null && jj root --quiet 2>/dev/null)" || exit 0
[ -n "$root" ] || exit 0

session_id="$(printf '%s' "$input" | jq -r '.session_id // "unknown"')"
state_key="$(printf '%s' "$root" | md5sum | cut -d' ' -f1)"
state_file="/tmp/claude-jj-wc-${session_id}-${state_key}"

current_id="$(cd "$root" && jj log -r @ --no-graph -T 'change_id' 2>/dev/null)" || exit 0
[ -n "$current_id" ] || exit 0

message=""

if [ ! -f "$state_file" ]; then
  desc="$(cd "$root" && jj log -r @ --no-graph -T 'description' 2>/dev/null)"
  if [ -z "$(printf '%s' "$desc" | tr -d '[:space:]')" ]; then
    message="jj working copy ($root) has no change description yet, and this is the first edit into it this session. Worth a beat to set one (jj describe -m \"WIP: ...\") before continuing - unless deliberately using this as an anonymous scratch change to squash into a target change later."
  fi
else
  prev_id="$(cat "$state_file" 2>/dev/null || true)"
  if [ -n "$prev_id" ] && [ "$prev_id" != "$current_id" ]; then
    message="jj working copy ($root) changed since this session last edited it (was $prev_id, now $current_id) - something ran jj edit/new/undo. Confirm this is really the change you mean to be editing."
  fi
fi

printf '%s' "$current_id" > "$state_file"

if [ -n "$message" ]; then
  jq -n --arg msg "$message" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "allow"}, systemMessage: $msg}'
fi
exit 0
