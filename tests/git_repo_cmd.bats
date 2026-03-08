#!/usr/bin/env bats

# git_repo_cmd.bats — unit tests for scripts/git_repo_cmd.sh

bats_require_minimum_version 1.5.0

SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../scripts" && pwd)"
CMD="$SCRIPTS_DIR/git_repo_cmd.sh"

setup() {
	# Create a fake projects directory tree: Projects/github.com/org/repo
	TEST_PROJECTS=$(mktemp -d)
	TEST_REPO="$TEST_PROJECTS/github.com/org/myrepo"
	mkdir -p "$TEST_REPO"
	TEST_REPO2="$TEST_PROJECTS/github.com/org/otherrepo"
	mkdir -p "$TEST_REPO2"
}

teardown() {
	rm -rf "$TEST_PROJECTS"
}

# ---------------------------------------------------------------------------
# projects-dir subcommand
# ---------------------------------------------------------------------------

@test "projects-dir returns GIT_FZF_REPO_PATH when set" {
	GIT_FZF_REPO_PATH="$TEST_PROJECTS" run "$CMD" projects-dir
	[ "$status" -eq 0 ]
	[ "$output" = "$TEST_PROJECTS" ]
}

@test "projects-dir returns git config value when env not set" {
	git config --global fzf.repoDir "$TEST_PROJECTS"
	run "$CMD" projects-dir
	git config --global --unset fzf.repoDir
	[ "$status" -eq 0 ]
	[ "$output" = "$TEST_PROJECTS" ]
}

@test "projects-dir env takes precedence over git config" {
	OTHER_DIR=$(mktemp -d)
	git config --global fzf.repoDir "$OTHER_DIR"
	GIT_FZF_REPO_PATH="$TEST_PROJECTS" run "$CMD" projects-dir
	git config --global --unset fzf.repoDir
	rm -rf "$OTHER_DIR"
	[ "$status" -eq 0 ]
	[ "$output" = "$TEST_PROJECTS" ]
}

@test "projects-dir expands tilde" {
	GIT_FZF_REPO_PATH="~/Projects" run "$CMD" projects-dir
	[ "$status" -eq 0 ]
	[[ "$output" != *"~"* ]]
}

# ---------------------------------------------------------------------------
# list subcommand
# ---------------------------------------------------------------------------

@test "list subcommand exits 0 with valid projects dir" {
	GIT_FZF_REPO_PATH="$TEST_PROJECTS" run "$CMD" list
	[ "$status" -eq 0 ]
}

@test "list subcommand emits repo paths" {
	GIT_FZF_REPO_PATH="$TEST_PROJECTS" run "$CMD" list
	[ "$status" -eq 0 ]
	echo "$output" | grep -q "myrepo"
}

@test "list subcommand emits multiple repos" {
	GIT_FZF_REPO_PATH="$TEST_PROJECTS" run "$CMD" list
	[ "$status" -eq 0 ]
	echo "$output" | grep -q "myrepo"
	echo "$output" | grep -q "otherrepo"
}

@test "list subcommand exits 0 with empty projects dir" {
	EMPTY_DIR=$(mktemp -d)
	GIT_FZF_REPO_PATH="$EMPTY_DIR" run "$CMD" list
	[ "$status" -eq 0 ]
	rm -rf "$EMPTY_DIR"
}

@test "list subcommand output has no trailing slash" {
	GIT_FZF_REPO_PATH="$TEST_PROJECTS" run "$CMD" list
	[ "$status" -eq 0 ]
	# No line should end with /
	! echo "$output" | grep -q '/$'
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
