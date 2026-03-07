#!/usr/bin/env bats

# git_core.bats — unit tests for scripts/git_core.sh

SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../scripts" && pwd)"

setup() {
	# Create a temp git repo for is_repo / root tests
	TEST_REPO=$(mktemp -d)
	git -C "$TEST_REPO" init -q
	git -C "$TEST_REPO" commit --allow-empty -m "init"
	TEST_OUTSIDE=$(mktemp -d)
}

teardown() {
	rm -rf "$TEST_REPO" "$TEST_OUTSIDE"
}

# ---------------------------------------------------------------------------
# _git_is_repo
# ---------------------------------------------------------------------------

@test "_git_is_repo returns 0 inside a git repo" {
	cd "$TEST_REPO"
	source "$SCRIPTS_DIR/git_core.sh"
	run _git_is_repo
	[ "$status" -eq 0 ]
}

@test "_git_is_repo returns 1 outside a git repo" {
	cd "$TEST_OUTSIDE"
	source "$SCRIPTS_DIR/git_core.sh"
	run _git_is_repo
	[ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# _git_root
# ---------------------------------------------------------------------------

@test "_git_root returns repo root" {
	cd "$TEST_REPO"
	source "$SCRIPTS_DIR/git_core.sh"
	result=$(_git_root)
	# Expand ~ back to $HOME for comparison; resolve symlinks (macOS /var -> /private/var)
	expanded="${result/#\~/$HOME}"
	[ "$(realpath "$expanded")" = "$(realpath "$TEST_REPO")" ]
}

# ---------------------------------------------------------------------------
# _git_opener
# ---------------------------------------------------------------------------

@test "_git_opener returns a non-empty string" {
	source "$SCRIPTS_DIR/git_core.sh"
	result=$(_git_opener)
	[ -n "$result" ]
}

@test "_git_opener returns open or xdg-open" {
	source "$SCRIPTS_DIR/git_core.sh"
	result=$(_git_opener)
	[[ "$result" == "open" || "$result" == "xdg-open" ]]
}

# ---------------------------------------------------------------------------
# _git_fzf_options
# ---------------------------------------------------------------------------

@test "_git_fzf_options sets _fzf_options array with defaults" {
	source "$SCRIPTS_DIR/git_core.sh"
	GIT_FZF_FLAGS=""
	_git_fzf_options
	# Should contain at least --ansi
	[[ " ${_fzf_options[*]} " == *"--ansi"* ]]
}

@test "_git_fzf_options appends GIT_FZF_FLAGS" {
	source "$SCRIPTS_DIR/git_core.sh"
	export GIT_FZF_FLAGS="--height 50%"
	_git_fzf_options
	[[ " ${_fzf_options[*]} " == *"--height"* ]]
}

@test "_git_fzf_options appends per-command GIT_FZF_WORKTREE_OPTS" {
	source "$SCRIPTS_DIR/git_core.sh"
	export GIT_FZF_FLAGS=""
	export GIT_FZF_WORKTREE_OPTS="--border rounded"
	_git_fzf_options "WORKTREE"
	[[ " ${_fzf_options[*]} " == *"--border"* ]]
}

@test "_git_fzf_options per-command opts override global flags ordering" {
	source "$SCRIPTS_DIR/git_core.sh"
	export GIT_FZF_FLAGS="--height 20%"
	export GIT_FZF_WORKTREE_OPTS="--height 80%"
	_git_fzf_options "WORKTREE"
	# Both appear; per-command last (higher precedence for fzf last-wins)
	local joined="${_fzf_options[*]}"
	[[ "$joined" == *"20%"*"80%"* ]]
}
