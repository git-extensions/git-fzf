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
#   GIT_FZF_FLAGS - Shell-quoted space-separated tokens (set by main entry point via printf '%q')
#   GIT_FZF_<COMMAND>_OPTS - Per-command fzf options (e.g., GIT_FZF_WORKTREE_OPTS)
#
# EXAMPLE:
#   _git_fzf_options "WORKTREE"
#   printf '%s\n' "$data" | fzf "${_fzf_options[@]}" ...
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

# _git_expand_path()
#
# Expand a leading ~ to $HOME in a path.
#
# PARAMETERS:
#   $1 - Path to expand (absolute or ~/…)
#
# RETURNS:
#   Expanded path printed to stdout.
#
# NOTE:
#   Only ~/… form is handled. Bare ~username is not supported and will
#   produce an incorrect result. Worktree paths are always absolute or ~/…
#   so this is not a concern in practice.
#
_git_expand_path() {
	printf '%s' "${1/#~/$HOME}"
}

# _git_open()
#
# Open a path in the system file manager, expanding a leading ~ to $HOME.
#
# PARAMETERS:
#   $1 - Path to open (absolute or ~/…)
#
_git_open() {
	local path
	path=$(_git_expand_path "$1")
	if [[ "$OSTYPE" == "darwin"* ]]; then
		open "$path"
	else
		xdg-open "$path"
	fi
}

# _git_is_repo()
#
# Check if the current directory is inside a git repository (work tree or bare).
#
# RETURNS:
#   0 if inside a git repository, 1 otherwise.
#
_git_is_repo() {
	git rev-parse --git-dir &>/dev/null
}

# _git_root()
#
# Get the root directory of the current git repository.
#
# RETURNS:
#   Absolute path to the repository root, or empty string on error.
#   For bare repositories, falls back to --absolute-git-dir (the .git directory itself).
#
_git_root() {
	local root
	root=$(git rev-parse --show-toplevel 2>/dev/null) ||
		root=$(git rev-parse --absolute-git-dir 2>/dev/null) ||
		return 0
	printf '%s\n' "$root"
}

# _git_get_repo()
#
# Extract owner/repo from the git remote origin URL for a given directory.
# Falls back to basename of the directory if origin is not configured.
#
# PARAMETERS:
#   $1 - directory path
#
# RETURNS:
#   owner/repo string printed to stdout.
#
_git_get_repo() {
	local url
	url=$(git -C "$1" remote get-url origin 2>/dev/null) || {
		basename "$1"
		return
	}
	url="${url%.git}"
	if [[ "$url" =~ [:/]([^/:]+/[^/:]+)$ ]]; then
		printf '%s' "${BASH_REMATCH[1]}"
	else
		basename "$1"
	fi
}

# ------------------------------------------------------------------------------
# Direct Execution Support
# ------------------------------------------------------------------------------
# When run directly (not sourced), dispatch to the appropriate function.
# ------------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	case "${1:-}" in
	open)
		if [[ -z "${2:-}" ]]; then
			gum log --level error "open requires a path"
			exit 1
		fi
		_git_open "$2"
		;;
	*) git "$@" ;;
	esac
fi
