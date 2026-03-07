#!/usr/bin/env bash

[ -z "${DEBUG:-}" ] || set -x

set -euo pipefail

_git_tmux_source_dir=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=./git_core.sh
source "$_git_tmux_source_dir/git_core.sh"

# git_tmux.sh — tmux integration helper for git-fzf
#
# Called as a subprocess by fzf bindings in git_worktree.sh when running
# inside a tmux session.
#
# SUBCOMMANDS:
#   new-window <dir>
#       Open a new tmux window at <dir>, named owner/repo/<basename dir>.
#
#   new-session <dir>
#       Create (or reuse) a tmux session named owner/repo/<basename dir>
#       at <dir> and switch the client to it. Idempotent — switches to an
#       existing session if one with that name already exists.

# _tmux_get_name()
#
# Build the tmux window/session name for a worktree directory.
# Format: owner/repo/<basename dir>
#
# PARAMETERS:
#   $1 - absolute worktree directory path
#
# RETURNS:
#   Name string printed to stdout.
#
_tmux_get_name() {
	local dir="$1"
	printf '%s' "$(_git_get_repo "$dir")/$(basename "$dir")"
}

# ------------------------------------------------------------------------------
# Direct Execution Support
# ------------------------------------------------------------------------------
# When run directly (not sourced), dispatch to the appropriate function.
# ------------------------------------------------------------------------------
main() {
	local subcommand="${1:-}"

	case "$subcommand" in
	new-window)
		if [[ -z "${2:-}" ]]; then
			gum log --level error "new-window requires a directory"
			exit 1
		fi
		local window_dir
		window_dir="$(_git_expand_path "$2")"

		local window_name
		window_name="$(_tmux_get_name "$window_dir")"

		tmux new-window -n "$window_name" -c "$window_dir"
		;;
	new-session)
		if [[ -z "${2:-}" ]]; then
			gum log --level error "new-session requires a directory"
			exit 1
		fi
		local session_dir
		session_dir="$(_git_expand_path "$2")"

		local session_name
		session_name="$(_tmux_get_name "$session_dir")"

		tmux has-session -t "=$session_name" 2>/dev/null || tmux new-session -d -s "$session_name" -c "$session_dir"
		tmux switch-client -t "=$session_name"
		;;
	*)
		gum log --level error "unknown subcommand '$subcommand'"
		gum log --level info "Usage: new-window <dir> | new-session <dir>"
		exit 1
		;;
	esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
