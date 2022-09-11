{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    nativeBuildInputs = with pkgs; [ 
      python310
      python310Packages.markdown
      python310Packages.feedgen
      python310Packages.markdown2
      python310Packages.pyyaml
    ];
}
