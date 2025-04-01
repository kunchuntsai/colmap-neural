# shell.nix - Compatibility wrapper for flake.nix
# This allows users without flakes enabled to use: nix-shell

{ pkgs ? import <nixpkgs> {
    config.allowUnfree = true;
    config.permittedInsecurePackages = [
      "freeimage-unstable-2021-11-01"
    ];
  }
}:

let
  flake = builtins.getFlake (toString ./.);
  system = builtins.currentSystem;
in
  flake.devShells.${system}.default