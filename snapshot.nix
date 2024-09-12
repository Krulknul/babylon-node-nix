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
  - Stop your Babylon node.
  - Download the latest snapshot from snapshots.radix.live.
  - Wipe the ledger database directory as set in your NixOS configuration.
  - Extract the snapshot to the database directory.
  - Start your Babylon node.

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

    echo "Stopping the Radix node.."
    systemctl stop babylon-node


    CURRENT_DATE=$(date +"%Y-%m-%d")

    mkdir ${dbDir}/download
    echo "Downloading the latest snapshot..."
    max_retries=5
    attempt_num=1
    while [ \$attempt_num -le \$max_retries ]
    do
      ${pkgs.aria2}/bin/aria2c -x3 -s16 -k4M --piece-length=4M --disk-cache=256M --lowest-speed-limit=250k ftp://snapshots.radix.live/\$CURRENT_DATE/RADIXDB-INDEX.tar.zst.metalink -d ${dbDir}/download && break
      echo "Download failed, attempt \$attempt_num of \$max_retries..."
      ((attempt_num++))
    done

    if [ \$attempt_num -gt \$max_retries ]; then
      echo "Failed to download after \$max_retries attempts, aborting."
      exit 1
    fi

    shopt -s extglob
    echo "Wiping the ledger database directory..."
    rm -rf ${dbDir}/** !(${dbDir}/download)

    echo "Extracting the snapshot..."
    ${pkgs.zstd}/bin/zstd -d ${dbDir}/download/RADIXDB-INDEX.tar.zst --stdout | ${pkgs.gnutar}/bin/tar xvf - -C ${dbDir}

    echo "Cleaning up..."
    rm -rf ${dbDir}/download
    rm -rf ${dbDir}/address-book

    echo "Starting the Radix node.."
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