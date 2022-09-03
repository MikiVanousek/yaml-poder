{ pkgs ? import <nixpkgs> {} }:
let
  pypkgs = pkgs.python310Packages;
in
  pkgs.mkShell {
    nativeBuildInputs = [ pypkgs.feedgen pypkgs.markdown2 pypkgs.pyyaml ];
}
