{ pkgs ? import <nixpkgs> {}, dbDir, user, group }:

pkgs.stdenv.mkDerivation {
  name = "download-snapshot";
  version = "1.0";

  buildInputs = with pkgs ;[ bash aria2 zstd gnutar ];

  # No source file is needed
  dontUnpack = true;

  installPhase =
  let script = ''
#!${pkgs.bash}/bin/bash
shopt -s extglob

function stop_node() {
    echo "Stopping the Radix node.."
    systemctl stop babylon-node
}

function download_snapshot() {
    mkdir -p ${dbDir}/download
    echo "Downloading the latest snapshot..."
    max_retries=5
    attempt_num=1
    while [ \$attempt_num -le \$max_retries ]
    do
      echo "Attempt \$attempt_num of \$max_retries: "
      if ${pkgs.aria2}/bin/aria2c -x3 -s16 -k4M --piece-length=4M --disk-cache=256M --lowest-speed-limit=250k ftp://snapshots.radix.live/\$(date +"%Y-%m-%d")/RADIXDB-INDEX.tar.zst.metalink -d ${dbDir}/download; then
        echo "Download successful!"
        break
      else
        echo "Download failed."
      fi
      ((attempt_num++))
    done

    if [ \$attempt_num -gt \$max_retries ]; then
      echo "Failed to download after \$max_retries attempts, aborting."
      exit 1
    fi
}

function wipe_ledger() {
    echo "Wiping the ledger database directory..."
    rm -rf ${dbDir}/!(download)
}

function extract_snapshot() {
    echo "Extracting the snapshot..."
    ${pkgs.zstd}/bin/zstd -d ${dbDir}/download/RADIXDB-INDEX.tar.zst --stdout | tar -xf - -C ${dbDir} --checkpoint=10000 --checkpoint-action=exec='echo -n "."'
    echo "\\nExtraction complete."
}

function set_ownership() {
    echo "Setting ownership of the database directory..."
    chown -R ${user}:${group} ${dbDir}
}

function cleanup() {
    echo "Cleaning up..."
    rm -rf ${dbDir}/download
    rm -rf ${dbDir}/address-book
}

function start_node() {
    echo "Starting the Radix node.."
    systemctl start babylon-node
}

case "\$1" in
    download)
        download_snapshot
        ;;
    extract)
        extract_snapshot
        set_ownership
        ;;
    all)
        stop_node
        download_snapshot
        wipe_ledger
        extract_snapshot
        cleanup
        set_ownership
        start_node
        ;;
    *)
        echo "Usage: \$0 {download|extract|all}"
        ;;
esac
  '';
  in
  ''
    mkdir -p $out/bin
    cat > $out/bin/download-snapshot <<EOF
    ${script}
    EOF
    chmod +x $out/bin/download-snapshot
  '';
}