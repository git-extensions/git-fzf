#!/usr/bin/env bats

# git_worktree_cmd.bats — unit tests for scripts/git_worktree_cmd.sh

bats_require_minimum_version 1.5.0

SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../scripts" && pwd)"
CMD="$SCRIPTS_DIR/git_worktree_cmd.sh"

setup() {
	# Create a temp git repo with a commit so worktrees work
	TEST_REPO=$(mktemp -d)
	BARE_REPO=""
	git -C "$TEST_REPO" init -q
	git -C "$TEST_REPO" config user.email "test@test.com"
	git -C "$TEST_REPO" config user.name "Test"
	git -C "$TEST_REPO" commit --allow-empty -m "Initial commit"

	# Create an extra worktree
	git -C "$TEST_REPO" worktree add "$TEST_REPO-wt" -b wt-branch
}

teardown() {
	rm -rf "$TEST_REPO" "$TEST_REPO-wt" "$TEST_REPO-detached"
	if [[ -n "${BARE_REPO:-}" ]]; then rm -rf "$BARE_REPO"; fi
}

@test "git_worktree_cmd.sh lists main worktree path" {
	cd "$TEST_REPO"
	run "$CMD" list
	[ "$status" -eq 0 ]
	echo "$output" | grep -q "$TEST_REPO"
}

@test "git_worktree_cmd.sh lists secondary worktree" {
	cd "$TEST_REPO"
	run "$CMD" list
	[ "$status" -eq 0 ]
	echo "$output" | grep -q "$TEST_REPO-wt"
}

@test "git_worktree_cmd.sh shows branch name" {
	cd "$TEST_REPO"
	run "$CMD" list
	[ "$status" -eq 0 ]
	echo "$output" | grep -q "wt-branch"
}

# ---------------------------------------------------------------------------
# preview-help subcommand
# ---------------------------------------------------------------------------

@test "preview-help subcommand exits 0" {
	run "$CMD" preview-help
	[ "$status" -eq 0 ]
}

@test "preview-help output contains ctrl-r" {
	run "$CMD" preview-help
	[ "$status" -eq 0 ]
	echo "$output" | grep -q "ctrl-r"
}

# ---------------------------------------------------------------------------
# unknown subcommand
# ---------------------------------------------------------------------------

@test "unknown subcommand exits 1" {
	run "$CMD" unknownsubcmd
	[ "$status" -eq 1 ]
}

@test "unknown subcommand prints error to stderr" {
	run --separate-stderr "$CMD" unknownsubcmd
	echo "$stderr" | grep -q "unknown subcommand"
}

# ---------------------------------------------------------------------------
# list subcommand — _git_worktree_list_cmd (formatted output for fzf)
# ---------------------------------------------------------------------------

@test "list subcommand includes main worktree path" {
	cd "$TEST_REPO"
	run "$CMD" list
	[ "$status" -eq 0 ]
	echo "$output" | grep -q "$TEST_REPO"
}

@test "list subcommand includes branch name" {
	cd "$TEST_REPO"
	run "$CMD" list
	[ "$status" -eq 0 ]
	echo "$output" | grep -q "wt-branch"
}

@test "list subcommand shows (detached) for detached HEAD worktree" {
	git -C "$TEST_REPO" worktree add --detach "$TEST_REPO-detached"
	cd "$TEST_REPO"
	run "$CMD" list
	[ "$status" -eq 0 ]
	echo "$output" | grep -q "(detached)"
}

@test "list subcommand shows (bare) for bare clone" {
	# A bare clone's main worktree is reported as 'bare' in porcelain output
	BARE_REPO=$(mktemp -d)
	rmdir "$BARE_REPO"
	git clone --bare "$TEST_REPO" "$BARE_REPO"
	cd "$BARE_REPO"
	run "$CMD" list
	[ "$status" -eq 0 ]
	echo "$output" | grep -q "(bare)"
}
