#!/usr/bin/env bash

[ -z "${DEBUG:-}" ] || set -x

set -euo pipefail

# Icon used in fzf footer/header titles
_fzf_icon=" "
# Separator used in fzf display templates
_fzf_split="·"

if [[ "$OSTYPE" == "darwin"* ]]; then
	_fzf_open="open"
else
	_fzf_open="xdg-open"
fi

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

# Resolve the current repo's nameWithOwner (e.g. "owner/repo")
#
# Writes the result into the nameref; returns 1 and logs an error on failure.
#
# Usage: _gh_repo_name repo_ref
_git_repo_name() {
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

# Resolve the git repository root directory
#
# Writes the result into the nameref; returns 1 and logs an error on failure.
#
# Usage: _git_repo_path git_dir_ref
_git_repo_path() {
	local root
	root=$(git rev-parse --show-toplevel 2>/dev/null) ||
		root=$(git rev-parse --absolute-git-dir 2>/dev/null) ||
		return 0
	printf '%s\n' "$root"
}
