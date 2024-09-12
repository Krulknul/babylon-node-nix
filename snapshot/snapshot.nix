{ pkgs ? import <nixpkgs> {}, dbDir ? ".", user ? "bing", group ? "bing" }:

pkgs.stdenv.mkDerivation rec {
  name = "download-snapshot";
  version = "1.0";

  buildInputs = with pkgs ;[ bash aria2 zstd gnutar makeWrapper cowsay ];
  phases = [ "installPhase" ];

  # No source file is needed
  src = ./snapshot.sh;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/download-snapshot
    chmod +x $out/bin/download-snapshot
    wrapProgram $out/bin/download-snapshot \
      --set DB_DIR ${dbDir} \
      --set USER ${user} \
      --set GROUP ${group} \
      --prefix PATH : ${pkgs.lib.makeBinPath buildInputs}
  '';
}