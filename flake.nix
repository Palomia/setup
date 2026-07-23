{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-etienne = {
      url = "github:etrobert/setup";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nix-etienne,
    }:
    let
      configuration =
        { pkgs, lib, ... }:
        {
          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages =
            with pkgs;
            [
              bat
              gh
              fzf
              claude-code
              vim
              neovim
              tmux
              ripgrep
              ghostty-bin.terminfo
            ]
            ++ (with nix-etienne.packages.aarch64-darwin; [
              batr
              (git-wrapped.override { userConfig = ./gitconfig-user; })
            ]);

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";
          nix.enable = false;

          security.pam.services.sudo_local.touchIdAuth = true;

          # Enable alternative shell support in nix-darwin.
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";
          nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "claude-code" ];

          programs.direnv = {
            enable = true;
            settings.global.hide_env_diff = true;
          };
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#ACLKMVTH44411
      darwinConfigurations."ACLKMVTH44411" = nix-darwin.lib.darwinSystem {
        modules = [ configuration ];
      };

      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-tree;
    };
}
