# https://status.nixos.org/
{ pkgs ? (
    import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/21.11.tar.gz") { })
, lib ? pkgs.lib
, stdenv ? pkgs.stdenv
, ...
}:

let
  node = pkgs.nodejs-16_x;
  yarn = pkgs.yarn.override { nodejs = node; };
  paths = with pkgs;
    [
      cmake
      file
      gcc
      git
      gnumake
      libffi
      libpcap
      libxml2
      libxslt
      node
      nodePackages.typescript
      nodePackages.typescript-language-server
      pkg-config
      pkgconfig
      redis
      shellcheck
      yarn
      zlib
    ];

  env = pkgs.buildEnv {
    name = "john-bot-env";
    paths = paths;
    extraOutputsToInstall = [ "bin" "lib" "include" ];
  };

  makeCpath = lib.makeSearchPathOutput "include" "include";
  makePathExpression = new:
    builtins.concatStringsSep ":" [ new (builtins.getEnv "PATH") ];
in
pkgs.mkShell rec {
  name = "john-bot";
  phases = [ "noPhase" ];
  noPhase = ''
    mkdir -p $out/bin
    ln -s ${env}/bin/* $out/bin/
  '';
  buildInputs = paths;

  PROJECT_ROOT = toString ./. + "/";

  CPATH = makeCpath [ env ];
  NODE_MODULES = PROJECT_ROOT + "/node_modules/.bin";
  LIBRARY_PATH = lib.makeLibraryPath [ env ];
  PATH = makePathExpression (lib.makeBinPath [ PROJECT_ROOT NODE_MODULES env ]);

  shellHook = ''
    unset CC

    XDG_DATA_HOME="$HOME/.local/share"

    export PATH=${PATH}:$PATH
  '';
}
