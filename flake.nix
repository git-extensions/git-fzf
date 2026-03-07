{
  description = "git-fzf — interactive fuzzy finder for Git";

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
        runtimeDeps = with pkgs; [ fzf gum gawk ];
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "git-fzf";
          version = pkgs.lib.removeSuffix "\n" (builtins.readFile ./version.txt);
          src = ./.;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          installPhase = ''
            mkdir -p $out/share/git-fzf/scripts $out/bin
            cp git-fzf version.txt $out/share/git-fzf/
            cp scripts/*.sh scripts/*.awk $out/share/git-fzf/scripts/
            chmod +x $out/share/git-fzf/git-fzf $out/share/git-fzf/scripts/*.sh
            makeWrapper $out/share/git-fzf/git-fzf $out/bin/git-fzf \
              --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps}
          '';

          meta = {
            description = "Interactive fuzzy finder for Git worktrees";
            homepage = "https://github.com/git-extensions/git-fzf";
            license = pkgs.lib.licenses.mit;
            maintainers = [ ];
            platforms = pkgs.lib.platforms.unix;
          };
        };

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
            if ! fzf --version | awk -F'[. ]' '$1>0 || ($1==0 && $2>=54) {found=1} END {exit !found}' 2>/dev/null; then
              echo "warning: fzf 0.54+ recommended — some keybindings may not work with older versions"
            fi
          '';
        };
      }
    );
}
