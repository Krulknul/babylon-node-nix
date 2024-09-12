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

function stop_node() {
    echo -e "\e[32mStopping the Radix node..\e[0m"
    systemctl stop babylon-node
}

function download_snapshot() {
    mkdir -p ${dbDir}/download
    echo -e "\e[34mDownloading the latest snapshot...\e[0m"
    max_retries=5
    attempt_num=1
    while [ \$attempt_num -le \$max_retries ]
    do
      echo -n "\e[34mAttempt \$attempt_num of \$max_retries: \e[0m"
      if ${pkgs.aria2}/bin/aria2c -x3 -s16 -k4M --piece-length=4M --disk-cache=256M --lowest-speed-limit=250k ftp://snapshots.radix.live/\$(date +"%Y-%m-%d")/RADIXDB-INDEX.tar.zst.metalink -d ${dbDir}/download; then
        echo -e "\e[32mDownload successful!\e[0m"
        break
      else
        echo -e "\e[31mDownload failed.\e[0m"
      fi
      ((attempt_num++))
    done

    if [ \$attempt_num -gt \$max_retries ]; then
      echo -e "\e[31mFailed to download after \$max_retries attempts, aborting.\e[0m"
      exit 1
    fi
}

function wipe_ledger() {
    shopt -s extglob
    echo -e "\e[33mWiping the ledger database directory...\e[0m"
    rm -rf ${dbDir}/!(download)
}

function extract_snapshot() {
    echo -e "\e[34mExtracting the snapshot...\e[0m"
    ${pkgs.zstd}/bin/zstd -d ${dbDir}/download/RADIXDB-INDEX.tar.zst --stdout | tar -xvf - -C ${dbDir} --checkpoint=10 --checkpoint-action=exec='echo -n "."'
    echo -e "\n\e[32mExtraction complete.\e[0m"
}

function cleanup() {
    echo -e "\e[33mCleaning up...\e[0m"
    rm -rf ${dbDir}/download
    rm -rf ${dbDir}/address-book
}

function start_node() {
    echo -e "\e[32mStarting the Radix node..\e[0m"
    systemctl start babylon-node
}

case "\$1" in
    download)
        download_snapshot
        ;;
    extract)
        extract_snapshot
        ;;
    all)
        stop_node
        download_snapshot
        wipe_ledger
        extract_snapshot
        cleanup
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