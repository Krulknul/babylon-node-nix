{ pkgs ? import <nixpkgs> {}, dbDir }:

pkgs.stdenv.mkDerivation {
  name = "download-snapshot";
  version = "1.0";

  buildInputs = with pkgs ;[ bash aria2 zstd gnutar ];

  # No source file is needed
  dontUnpack = true;

  installPhase =
  let script = ''
    #!${pkgs.bash}/bin/bash
    echo "Running this script will:
    - Stop your Radix node.
    - Wipe the ledger database directory as set in your NixOS configuration.
    - Download the latest snapshot from snapshots.radix.live.
    - Extract the snapshot to the database directory.
    - Start your Radix node.
    Are you sure you wish to continue? [y/N]
    "

    while true; do
        read -p "Do you wish to continue? (y/N) " yn
        case \$yn in
            [Yy]*) break;;
            [Nn]* ) echo "Aborting"; exit;;
            * ) echo "Aborting."; exit;;
        esac
    done

    # Stop the Radix node
    systemctl stop babylon-node

    # Wipe the ledger database directory
    rm -rf ${dbDir}/**
    mkdir ${dbDir}/download

    CURRENT_DATE=$(date +"%Y-%m-%d")

    # Download the latest snapshot
    ${pkgs.aria2}/bin/aria2c -x3 -s16 -k4M --piece-length=4M --disk-cache=256M --lowest-speed-limit=250k ftp://snapshots.radix.live/$CURRENT_DATE/RADIXDB-INDEX.tar.zst.metalink -d ${dbDir}/download

    # Extract the snapshot
    ${pkgs.zstd}/bin/zstd -d ./dir/download/RADIXDB-INDEX.tar.zst --stdout | tar xvf - -C ${dbDir}

    # Clean up
    rm -rf ${dbDir}/download
    rm -rf ${dbDir}/address-book

    # Start the Radix node
    systemctl start babylon-node
  '';
  in
  ''
    mkdir -p $out/bin
    cat > $out/bin/download-snapshot <<EOF
    ${script}
    EOF
    chmod +x $out/bin/download-snapshot
  '';

  meta = {
    description = "A simple inline hello world script";
    homepage = "https://example.com";
    license = pkgs.lib.licenses.mit;
  };
}