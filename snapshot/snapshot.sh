shopt -s extglob

function stop_node() {
    echo "Stopping the Radix node.."
    systemctl stop babylon-node
}

function download_snapshot() {
    mkdir -p $DB_DIR/download
    rm -rf $DB_DIR/download/*
    echo "Downloading the latest snapshot..."
    CURRENT_DATE = $(date +"%Y-%m-%d")
    max_retries=5
    attempt_num=1
    while [ $attempt_num -le $max_retries ]
    do
      echo "Attempt $attempt_num of $max_retries: "
      if aria2c -x3 -s16 -k4M --piece-length=4M --disk-cache=256M --lowest-speed-limit=250k ftp://snapshots.radix.live/$CURRENT_DATE/RADIXDB-INDEX.tar.zst.metalink -d $DB_DIR/download; then
        echo "Download successful!"
        break
      else
        echo "Download failed."
      fi
      ((attempt_num++))
    done

    if [ $attempt_num -gt $max_retries ]; then
      echo "Failed to download after $max_retries attempts, aborting."
      exit 1
    fi
}

function wipe_ledger() {
    echo "Wiping the ledger database directory..."
    if rm -rf $DB_DIR/!(download); then
        echo "Wipe complete."
    else
        echo "Failed to wipe the database directory."
        exit 1
    fi
}

function extract_snapshot() {
    echo "Extracting the snapshot..."
    zstd -d -T0 -c $DB_DIR/download/RADIXDB-INDEX.tar.zst | pv -s $(zstd --list $DB_DIR/download/RADIXDB-INDEX.tar.zst | awk 'NR==4 {print $4}') | tar -xf - -C $DB_DIR
    echo "Extraction complete."
}

function set_ownership() {
    echo "Setting ownership of the database directory..."
    chown -R $USER:$GROUP $DB_DIR
}

function cleanup() {
    echo "Cleaning up..."
    if rm -rf $DB_DIR/download && rm -rf $DB_DIR/address-book; then
        echo "Cleanup complete."
    else
        echo "Failed to clean up."
        exit 1
    fi
}

function start_node() {
    echo "Starting the Radix node.."
    systemctl start babylon-node
}

function yes_no() {
    while true; do
        read -p "Do you wish to continue? (y/N) " yn
        case $yn in
            [Yy]*) break;;
            [Nn]* ) echo "Aborting"; exit;;
            * ) echo "Aborting."; exit;;
        esac
    done
}

function download() {
    echo "Running this script will:
    - Create a directory at $DB_DIR/download if it does not exist.
    - Wipe that directory to start clean.
    - Download the latest snapshot from snapshots.radix.live to that directory."

    yes_no
    download_snapshot

}

function extract() {
    echo "Running this script will:
    - Wipe the ledger database directory as set in your NixOS configuration ($DB_DIR), except for the download directory.
    - Extract the snapshot to the database directory.
    - Set ownership of the database directory to $USER:$GROUP."

    yes_no
    wipe_ledger
    extract_snapshot
    set_ownership
}

function all() {
    echo "Running this script will:
    - Stop your Radix node.
    - Wipe the ledger database directory as set in your NixOS configuration.
    - Download the latest snapshot from snapshots.radix.live.
    - Extract the snapshot to the database directory.
    - Start your Radix node."

    yes_no
    stop_node
    download_snapshot
    wipe_ledger
    extract_snapshot
    cleanup
    set_ownership
    start_node
}

function help() {
    echo "Usage: ledger-snapshot [install|download|extract|help]

Subcommands:
    install - Run all steps: download and extract the database, and restart the Radix node.
    download - Only download the latest snapshot from snapshots.radix.live.
    extract - Extract the snapshot to the database directory.
    help - Display this help message.

Each command will list its steps and ask for confirmation before proceeding.
This script automatically detects and uses the database directory and user/group ownership variables from your NixOS configuration to make the process as seamless as possible.
"
}

case "$1" in
    download)
        download
        ;;
    extract)
        extract
        ;;
    install)
        all
        ;;
    help)
        help
        ;;
    *)
        help
        ;;
esac