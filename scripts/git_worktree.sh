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
#   with keyboard shortcuts for common worktree operations. On Enter, prints
#   a 'builtin cd -- <path>' shell command to stdout (eval to apply).
#
# PARAMETERS:
#   $@ - Optional flags (currently passed through; --help/-h shows git help)
#
# RETURNS:
#   0 - Success; prints 'builtin cd -- <path>' to stdout
#   1 - Failure (not in a git repo, or no worktrees found)
#
# KEYBOARD SHORTCUTS:
#   enter     - Print cd command for selected worktree (eval to apply)
#   ctrl-o    - Open directory in file manager (open / xdg-open)
#   ctrl-r    - Reload worktree list
#   alt-x     - Remove selected worktree
#   alt-p     - Prune stale worktrees + reload
#   alt-h     - Toggle preview (keyboard shortcuts)
#
_git_worktree_list() {
	if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
		git worktree --help
		return $?
	fi

	if ! _git_is_repo; then
		gum log --level warn "Not inside a git repository."
		return 1
	fi

	local git_worktree_list
	git_worktree_list=$("$_git_worktree_source_dir/git_worktree_cmd.sh")

	if [[ -z "$git_worktree_list" ]]; then
		gum log --level warn "No git worktrees found."
		return 1
	fi

	local git_root
	git_root=$(_git_root)

	local git_worktree_reload
	git_worktree_reload="$_git_worktree_source_dir/git_worktree_cmd.sh"

	local git_opener
	git_opener=$(_git_opener)

	# Build fzf options with user-provided flags
	_git_fzf_options "WORKTREE"

	# shellcheck disable=SC2154  # _fzf_options/_fzf_icon/_fzf_split set by sourced git_core.sh
	# Interactive worktree browser
	echo "$git_worktree_list" | fzf "${_fzf_options[@]}" \
		--with-nth 1.. \
		--footer "$_fzf_icon Git Worktrees $_fzf_split $git_root" \
		--preview-label " Keyboard Shortcuts " \
		--preview "$_git_worktree_source_dir/git_worktree_cmd.sh preview-help" \
		--bind "load:change-footer($_fzf_icon Git Worktrees $_fzf_split $git_root)" \
		--bind "enter:become($_git_worktree_source_dir/git_worktree_cmd.sh cd {1})" \
		--bind "ctrl-o:execute-silent($git_opener {1})" \
		--bind "ctrl-r:change-footer($_fzf_icon Git Worktrees $_fzf_split $git_root $_fzf_split Reloading...)+reload($git_worktree_reload)" \
		--bind "alt-x:execute-silent($_git_worktree_source_dir/git_worktree_cmd.sh remove {1})+reload($git_worktree_reload)" \
		--bind "alt-p:execute-silent($_git_worktree_source_dir/git_worktree_cmd.sh prune)+reload($git_worktree_reload)" \
		--bind "alt-h:toggle-preview"
}
