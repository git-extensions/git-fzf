#!/usr/bin/env bash

[ -z "${DEBUG:-}" ] || set -x

set -euo pipefail

_git_worktree_source_dir=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=./git_core.sh
source "$_git_worktree_source_dir/git_core.sh"

# git_worktree.sh - Git Worktree interactive browser for git-fzf
#
# This file is sourced by the main git-fzf script and provides
# the interactive worktree browser functionality.

# _git_worktree_list()
#
# Interactive fuzzy finder for Git worktrees
#
# DESCRIPTION:
#   Displays a list of git worktrees in an interactive fuzzy finder (fzf)
#   with keyboard shortcuts for common worktree operations. Prints the
#   selected worktree path to stdout on Enter as an absolute path.
#
# PARAMETERS:
#   $@ - --help or -h shows 'git worktree list --help'; all other flags are ignored
#
# RETURNS:
#   0   - Enter pressed; prints tilde-compressed path to stdout
#   1   - Failure (not in a git repo, or no worktrees found)
#   130 - ESC or Ctrl-C pressed (fzf standard exit code); nothing printed
#
# KEYBOARD SHORTCUTS:
#   ctrl-o    - Open directory in file manager (open / xdg-open)
#   ctrl-r    - Reload worktree list
#   alt-x     - Remove selected worktree
#   alt-p     - Prune stale worktrees + reload
#   alt-h     - Toggle preview (keyboard shortcuts)
#
_git_worktree_list() {
	if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
		git worktree list --help
		return
	fi

	if ! _git_is_repo; then
		gum log --level error "Not inside a git repository."
		return 1
	fi

	local git_worktree_cmd
	git_worktree_cmd="$_git_worktree_source_dir/git_worktree_cmd.sh"

	local git_worktree_list
	git_worktree_list=$("$git_worktree_cmd" list)

	if [[ -z "$git_worktree_list" ]]; then
		gum log --level error "No git worktrees found."
		return 1
	fi

	git_worktree_cmd+=" list"
	[ $# -gt 0 ] && git_worktree_cmd+="$(printf ' %q' "$@")"

	local git_repo_path
	git_repo_path=$(_git_repo_path)

	local git_repo_name
	git_repo_name="$(_git_repo_name "$git_repo_path")"

	git_repo_path="~${git_repo_path#"$HOME"}"

	local git_worktree_footer
	git_worktree_footer="$_fzf_icon Git Worktrees $_fzf_split $git_repo_path"

	# Build fzf options with user-provided flags
	_git_fzf_options "WORKTREE"

	# Register tmux bindings only when running inside a tmux session
	if [[ -n "${TMUX:-}" ]]; then
		local git_tmux_cmd
		git_tmux_cmd="$_git_worktree_source_dir/git_tmux_cmd.sh"

		local git_worktree_name
		# shellcheck disable=SC2016
		git_worktree_name='$(basename {1})'

		_fzf_options+=(--bind "alt-W:execute-silent($git_tmux_cmd new-window worktrees/$git_worktree_name -c '{1}')+abort")
		_fzf_options+=(--bind "alt-S:execute-silent($git_tmux_cmd new-session $git_repo_name/$git_worktree_name -c '{1}')+abort")
	fi

	# shellcheck disable=SC2154  # _fzf_options/_fzf_icon/_fzf_split set by sourced git_core.sh
	# Interactive worktree browser
	echo "$git_worktree_list" | fzf "${_fzf_options[@]}" \
		--accept-nth 1 \
		--footer "$git_worktree_footer" \
		--preview-label " Keyboard Shortcuts " \
		--preview "$_git_worktree_source_dir/git_worktree_cmd.sh preview-help" \
		--bind "load:change-footer($git_worktree_footer)" \
		--bind "ctrl-r:change-footer($git_worktree_footer $_fzf_split Reloading...)+reload($git_worktree_cmd)" \
		--bind "ctrl-o:change-footer($git_worktree_footer $_fzf_split Opening...)+execute(open '{1}')" \
		--bind "alt-p:change-footer($git_worktree_footer $_fzf_split Pruning...)+execute-silent(git worktree prune)+reload($git_worktree_cmd)" \
		--bind "alt-x:change-footer($git_worktree_footer $_fzf_split Removing...)+execute-silent(git worktree remove '{1}')+reload($git_worktree_cmd)" \
		--bind "alt-h:toggle-preview"
}
