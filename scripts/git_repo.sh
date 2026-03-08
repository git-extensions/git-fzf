#!/usr/bin/env bash

[ -z "${DEBUG:-}" ] || set -x

set -euo pipefail

_git_repo_source_dir=$(dirname "${BASH_SOURCE[0]}")
# shellcheck source=./git_repo_cmd.sh
source "$_git_repo_source_dir/git_repo_cmd.sh"

# git_repo.sh - Git Repository interactive browser for git-fzf
#
# This file is sourced by the main git-fzf script and provides
# the interactive repository browser functionality.

# _git_repo_list()
#
# Interactive fuzzy finder for local git repositories
#
# DESCRIPTION:
#   Displays a list of local git repositories under the configured projects
#   directory in an interactive fuzzy finder (fzf). Prints the selected
#   repository path to stdout on Enter as an absolute path.
#
# PARAMETERS:
#   $@ - --help or -h shows usage; all other flags are ignored
#
# RETURNS:
#   0   - Enter pressed; prints tilde-compressed path to stdout
#   1   - Failure (no repositories found)
#   130 - ESC or Ctrl-C pressed (fzf standard exit code); nothing printed
#
# KEYBOARD SHORTCUTS:
#   ctrl-o    - Open directory in file manager (open / xdg-open)
#   ctrl-r    - Reload repository list
#   alt-h     - Toggle preview (keyboard shortcuts)
#
_git_repo_list() {
	if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
		cat <<'EOF'
git fzf repo - Browse and navigate local git repositories

USAGE:
    git fzf repo

ENVIRONMENT:
    GIT_FZF_REPO_PATH    Root directory to scan for repos (default: ~/Projects)
    GIT_FZF_REPO_OPTS    Per-command fzf options
EOF
		return
	fi

	local git_repo_cmd
	git_repo_cmd="$_git_repo_source_dir/git_repo_cmd.sh"

	local git_repo_list
	git_repo_list=$("$git_repo_cmd" list)

	if [[ -z "$git_repo_list" ]]; then
		gum log --level error "No git repositories found."
		return 1
	fi

	local git_repo_path
	git_repo_path=$(_git_config_repo_path)

	git_repo_path="~${git_repo_path#"$HOME"}"

	local git_repo_footer
	git_repo_footer="$_fzf_icon Repositories $_fzf_split $git_repo_path"

	# Build fzf options with user-provided flags
	_git_fzf_options "REPO"

	# Register tmux bindings only when running inside a tmux session
	if [[ -n "${TMUX:-}" ]]; then
		local git_tmux_cmd
		git_tmux_cmd="$_git_repo_source_dir/git_tmux_cmd.sh"

		local git_repo_name
		# shellcheck disable=SC2016
		git_repo_name='$(basename $(dirname {1}))/$(basename {1})'

		_fzf_options+=(--bind "alt-W:execute-silent($git_tmux_cmd new-window $git_repo_name -c '{1}')+abort")
		_fzf_options+=(--bind "alt-S:execute-silent($git_tmux_cmd new-session $git_repo_name -c '{1}')+abort")
	fi

	# shellcheck disable=SC2154  # _fzf_options/_fzf_icon/_fzf_split/_fzf_open set by sourced git_core.sh
	echo "$git_repo_list" | fzf "${_fzf_options[@]}" \
		--accept-nth 1 \
		--with-nth 2.. \
		--footer "$git_repo_footer" \
		--preview-label " Keyboard Shortcuts " \
		--preview "$git_repo_cmd preview-help" \
		--bind "load:change-footer($git_repo_footer)" \
		--bind "ctrl-r:change-footer($git_repo_footer $_fzf_split Reloading...)+reload($git_repo_cmd list)" \
		--bind "ctrl-o:change-footer($git_repo_footer $_fzf_split Opening...)+execute($_fzf_open '{1}')" \
		--bind "alt-h:toggle-preview"
}
