#!/usr/bin/env bash

[ -z "${DEBUG:-}" ] || set -x

set -euo pipefail

# Force ANSI color output even when stdout is not a TTY (e.g. piped into fzf)
export CLICOLOR_FORCE=1

# Icon used in fzf footer/header titles
_fzf_icon=" "
# Separator used in fzf display templates
_fzf_split="·"

# _git_fzf_options()
#
# Build fzf options array with user-provided flags
#
# DESCRIPTION:
#   Constructs the fzf options array by combining default options with
#   user-provided flags from GIT_FZF_FLAGS environment variable and per-command
#   GIT_FZF_<COMMAND>_OPTS environment variables. This function must be called
#   at runtime (not at source time) to pick up flags set by main().
#
#   Precedence order (last wins):
#   1. Default options (defined in code)
#   2. GIT_FZF_FLAGS (global, set via CLI)
#   3. GIT_FZF_<COMMAND>_OPTS (per-command, highest priority)
#
# PARAMETERS:
#   $1 - Optional command identifier
#        Used to lookup per-command environment variable GIT_FZF_${command_id}_OPTS
#
# RETURNS:
#   Sets _fzf_options array with merged options
#
# ENVIRONMENT:
#   GIT_FZF_FLAGS - Space-separated string of user fzf flags (set by main entry point)
#   GIT_FZF_<COMMAND>_OPTS - Per-command fzf options (e.g., GIT_FZF_WORKTREE_OPTS)
#
# EXAMPLE:
#   _git_fzf_options "WORKTREE"
#   echo "$data" | fzf "${_fzf_options[@]}" ...
#
_git_fzf_options() {
	local command_id="${1:-}"

	# Default fzf options for git-fzf
	_fzf_options=(
		--ansi
		--header-lines='1'
		--header-border='sharp'
		--footer-border='sharp'
		--input-border='sharp'
		--color='header:blue'
		--color='footer:blue'
		--layout='reverse-list'
		--preview-window='right:40:wrap:hidden:border-top'
	)

	# Add user-provided fzf flags (global)
	if [[ -n "${GIT_FZF_FLAGS:-}" ]]; then
		local user_flags=()
		eval "user_flags=($GIT_FZF_FLAGS)"
		_fzf_options+=("${user_flags[@]}")
	fi

	# Add per-command fzf options (highest precedence)
	if [[ -n "$command_id" ]]; then
		local var_name="GIT_FZF_${command_id}_OPTS"
		local cmd_flags="${!var_name:-}"
		if [[ -n "$cmd_flags" ]]; then
			local cmd_flags_array=()
			eval "cmd_flags_array=($cmd_flags)"
			_fzf_options+=("${cmd_flags_array[@]}")
		fi
	fi
}

# _git_opener()
#
# Print the available file manager opener command.
#
# RETURNS:
#   "open" on macOS, "xdg-open" otherwise.
#
_git_opener() {
	if command -v open &>/dev/null; then
		echo "open"
	else
		echo "xdg-open"
	fi
}

# _git_is_repo()
#
# Check if the current directory is inside a git work tree.
#
# RETURNS:
#   0 if inside a git repository, 1 otherwise.
#
_git_is_repo() {
	git rev-parse --is-inside-work-tree &>/dev/null
}

# _git_root()
#
# Get the root directory of the current git repository.
#
# RETURNS:
#   Path to the repository root with $HOME replaced by ~, or empty string on error.
#
_git_root() {
	local root
	root=$(git rev-parse --show-toplevel 2>/dev/null) || {
		echo ""
		return
	}
	echo "${root/#"$HOME"/\~}"
}

# ------------------------------------------------------------------------------
# Direct Execution Support
# ------------------------------------------------------------------------------
# When run directly (not sourced), pass all arguments to git.
# ------------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	git "$@"
fi
