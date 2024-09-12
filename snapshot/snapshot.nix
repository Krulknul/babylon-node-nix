{
  pkgs ? import <nixpkgs> { },
  dbDir,
  user,
  group,
}:

pkgs.stdenv.mkDerivation rec {
  name = "ledger-snapshot";
  version = "1.0";

  buildInputs = with pkgs; [
    bash
    aria2
    zstd
    gnutar
    makeWrapper
  ];
  phases = [ "installPhase" ];

  # No source file is needed
  src = ./snapshot.sh;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/ledger-snapshot
    chmod +x $out/bin/ledger-snapshot
    wrapProgram $out/bin/ledger-snapshot \
      --set DB_DIR ${dbDir} \
      --set USER ${user} \
      --set GROUP ${group} \
      --prefix PATH : ${pkgs.lib.makeBinPath buildInputs}
  '';
}
