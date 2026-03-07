#!/usr/bin/env bats

# git_fzf.bats — smoke tests for the git-fzf entry script

GIT_FZF="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/git-fzf"

@test "git-fzf --version exits 0" {
	run "$GIT_FZF" --version
	[ "$status" -eq 0 ]
}

@test "git-fzf --version outputs a semver string" {
	run "$GIT_FZF" --version
	[ "$status" -eq 0 ]
	[[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "git-fzf --help exits 0" {
	run "$GIT_FZF" --help
	[ "$status" -eq 0 ]
}

@test "git-fzf --help mentions worktree command" {
	run "$GIT_FZF" --help
	[ "$status" -eq 0 ]
	echo "$output" | grep -q "worktree"
}
