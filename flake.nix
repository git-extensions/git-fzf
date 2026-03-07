{
  description = "git-fzf development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            bash
            git
            fzf
            gum
            gawk
            bats
            shellcheck
          ];

          shellHook = ''
            if ! fzf --version | awk -F'[. ]' '$1>=0 && $2>=54 {found=1} END {exit !found}' 2>/dev/null; then
              echo "warning: fzf 0.54+ recommended — some keybindings may not work with older versions"
            fi
          '';
        };
      }
    );
}
