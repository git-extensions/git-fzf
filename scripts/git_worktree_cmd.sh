#!/usr/bin/env bash

[ -z "${DEBUG:-}" ] || set -x

set -euo pipefail

_git_worktree_cmd_source_dir=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=./git_core.sh
source "$_git_worktree_cmd_source_dir/git_core.sh"

# git_worktree_cmd.sh - Git Worktree commands for git-fzf
#
# Invoked as a subprocess by git_worktree.sh. Provides worktree
# data emission and fzf action dispatch (list, preview-help, remove, prune).

# _git_worktree_emit_row()
#
# Emit one tab-separated worktree row to stdout.
#
# PARAMETERS:
#   $1 - absolute path (emitted as-is; ~/substitution done by renderer for display)
#   $2 - branch   $3 - sha7   $4 - commit subject
#
_git_worktree_emit_row() {
	printf "%s\t%s\t%s\t%s\n" "$1" "${2:-HEAD}" "${3:-}" "${4:-}"
}

# _git_worktree_flush_block()
#
# Resolve branch label, fetch commit subject, and emit one TSV row.
# Called for each completed porcelain block (both mid-stream and trailing).
#
# PARAMETERS:  $1=path  $2=branch  $3=sha7  $4=detached(0/1)  $5=bare(0/1)
#
_git_worktree_flush_block() {
	local path="$1" branch="$2" sha="$3" detached="$4" bare="$5" msg=""
	[[ $detached -eq 1 ]] && branch="(detached)"
	[[ $bare -eq 1 ]] && branch="(bare)"
	[[ -n "$sha" ]] && msg=$(git log -1 --format="%s" "$sha" 2>/dev/null || true)
	msg="${msg//$'\t'/ }"
	_git_worktree_emit_row "$path" "$branch" "$sha" "$msg"
}

# _git_worktree_cmd_list()
#
# Parse 'git worktree list --porcelain' and emit tab-separated rows.
#
# DESCRIPTION:
#   Reads porcelain worktree output (blocks separated by blank lines) and
#   emits one tab-separated line per worktree:
#       PATH\tBRANCH\tSHA7\tCOMMIT_SUBJECT
#   PATH is the absolute path as reported by git.
#   No colors, no spinner — pure data. Exposed as the 'list' subcommand so
#   it can be called directly via 'git_worktree_cmd.sh list'.
#
# RETURNS:
#   Tab-separated rows (no header), one per worktree. Empty output when not
#   in a git repo or no worktrees exist.
#
_git_worktree_cmd_list() {
	local worktrees
	worktrees=$(git worktree list --porcelain 2>/dev/null) || return 0
	[[ -z "$worktrees" ]] && return 0

	local path="" sha="" branch="" detached=0 bare=0

	while IFS= read -r line || [[ -n "$line" ]]; do
		if [[ "$line" == worktree\ * ]]; then
			path="${line#worktree }"
		elif [[ "$line" == HEAD\ * ]]; then
			sha="${line#HEAD }"
			sha="${sha:0:7}"
		elif [[ "$line" == branch\ * ]]; then
			branch="${line#branch }"
			branch="${branch#refs/heads/}"
		elif [[ "$line" == "detached" ]]; then
			detached=1
		elif [[ "$line" == "bare" ]]; then
			bare=1
		elif [[ -z "$line" && -n "$path" ]]; then
			_git_worktree_flush_block "$path" "$branch" "$sha" "$detached" "$bare"
			path=""; sha=""; branch=""; detached=0; bare=0
		fi
	done <<<"$worktrees"

	# Emit last block if porcelain output did not end with a blank line
	[[ -n "$path" ]] && _git_worktree_flush_block "$path" "$branch" "$sha" "$detached" "$bare"
}

# _git_worktree_list_cmd()
#
# List git worktrees with colored, formatted output.
#
# DESCRIPTION:
#   Calls the 'list' subcommand (this script) via gum spin for a loading
#   indicator, then renders the tab-separated rows as an ANSI-colored table
#   with a header suitable for fzf consumption.
#
# RETURNS:
#   Colored table with header + one row per worktree.
#   Empty output (exit 0) when there are no worktrees to display.
#
_git_worktree_list_cmd() {
	local raw
	raw=$(gum spin --title "Loading worktrees..." -- \
		"$_git_worktree_cmd_source_dir/git_worktree_cmd.sh" list)

	[[ -z "$raw" ]] && return 0

	{
		printf "PATH\tBRANCH\tCOMMIT\tMESSAGE\n"
		printf '%s\n' "$raw"
	} |
		awk -v styles="bold,status,faint,faint" \
			-v max_widths="0,35,0,0" \
			-v home="$HOME" \
			-f "$_git_worktree_cmd_source_dir/git_render.awk"
}

# _git_worktree_preview_help()
#
# Display keyboard shortcuts for worktree list
#
# DESCRIPTION:
#   Outputs formatted help text showing available keyboard shortcuts
#   for the worktree list. Designed to be displayed in fzf preview window.
#
_git_worktree_preview_help() {
	gum format <<'EOF'
| Key | Action |
|-----|--------|
| **`ctrl-o`** | Open directory in file manager |
| **`ctrl-r`** | Reload list |
| **`alt-x`** | Remove selected worktree |
| **`alt-p`** | Prune stale worktrees |
| **`alt-h`** | Toggle help |
| **`ESC`** | Exit (no output) |
EOF
}

# ------------------------------------------------------------------------------
# Direct Execution Support
# ------------------------------------------------------------------------------
# When run directly (not sourced), dispatch to the appropriate function.
# ------------------------------------------------------------------------------
main() {
	local subcommand="${1:-}"

	case "$subcommand" in
	list)
		_git_worktree_cmd_list
		;;
	preview-help)
		_git_worktree_preview_help
		;;
	remove)
		shift
		if [[ -z "${1:-}" ]]; then
			gum log --level error "remove requires a worktree path"
			exit 1
		fi
		git worktree remove "$@"
		;;
	prune)
		git worktree prune
		;;
	"")
		_git_worktree_list_cmd
		;;
	*)
		gum log --level error "unknown subcommand '$subcommand'"
		exit 1
		;;
	esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
