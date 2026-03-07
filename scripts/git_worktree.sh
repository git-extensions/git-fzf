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
#   selected worktree path to stdout on Enter. Paths under $HOME are
#   printed in ~/... form; all others are absolute.
#
# PARAMETERS:
#   $@ - --help or -h shows 'git worktree list --help'; all other flags are ignored
#
# RETURNS:
#   0   - Enter pressed; prints selected worktree path to stdout
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
	git_worktree_list=$("$git_worktree_cmd")

	if [[ -z "$git_worktree_list" ]]; then
		gum log --level error "No git worktrees found."
		return 1
	fi

	local git_root
	git_root=$(_git_root)

	# Build fzf options with user-provided flags
	_git_fzf_options "WORKTREE"

	# shellcheck disable=SC2154  # _fzf_options/_fzf_icon/_fzf_split set by sourced git_core.sh
	# Interactive worktree browser
	printf '%s' "$git_worktree_list" | fzf "${_fzf_options[@]}" \
		--accept-nth 1 \
		--footer "$_fzf_icon Git Worktrees $_fzf_split $git_root" \
		--preview-label " Keyboard Shortcuts " \
		--preview "$git_worktree_cmd preview-help" \
		--bind "ctrl-r:change-footer($_fzf_icon Git Worktrees $_fzf_split $git_root $_fzf_split Reloading...)+reload($git_worktree_cmd)" \
		--bind "ctrl-o:change-footer($_fzf_icon Git Worktrees $_fzf_split $git_root $_fzf_split Opening...)+execute-silent($_git_worktree_source_dir/git_core.sh open {1})" \
		--bind "alt-p:change-footer($_fzf_icon Git Worktrees $_fzf_split $git_root $_fzf_split Pruning...)+execute-silent($git_worktree_cmd prune)+reload($git_worktree_cmd)" \
		--bind "alt-x:change-footer($_fzf_icon Git Worktrees $_fzf_split $git_root $_fzf_split Removing...)+execute-silent($git_worktree_cmd remove {1})+reload($git_worktree_cmd)" \
		--bind "alt-h:toggle-preview"
}
