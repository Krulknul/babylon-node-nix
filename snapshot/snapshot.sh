#!/bin/bash

shopt -s extglob

# Default values
YES=false
CURRENT_DATE=$(date +"%Y-%m-%d")

# Parse options using getopts
while getopts "yd:" opt; do
  case $opt in
    y)
      YES=true
      ;;
    d)
      CURRENT_DATE="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Shift positional parameters to get subcommand
shift $((OPTIND -1))

# Functions remain the same, using the updated variables
function stop_node() {
    echo "Stopping the Radix node..."
    systemctl stop babylon-node
}

function download_snapshot() {
    mkdir -p $DB_DIR/download
    rm -rf $DB_DIR/download/*
    echo "Downloading the latest snapshot for date $CURRENT_DATE..."
    max_retries=5
    attempt_num=1
    while [ $attempt_num -le $max_retries ]
    do
      echo "Attempt $attempt_num of $max_retries:"
      if aria2c -x3 -s16 -k4M --piece-length=4M --disk-cache=256M --lowest-speed-limit=250k "ftp://snapshots.radix.live/$CURRENT_DATE/RADIXDB-INDEX.tar.zst.metalink" -d $DB_DIR/download; then
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
    pv -s $(stat -c%s "$DB_DIR/download/RADIXDB-INDEX.tar.zst") "$DB_DIR/download/RADIXDB-INDEX.tar.zst" | tar -I 'zstd -d -T0' -xf - -C $DB_DIR
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
    echo "Starting the Radix node..."
    systemctl start babylon-node
}

function yes_no() {
    if $YES; then
        return
    fi
    while true; do
        read -p "Do you wish to continue? (y/N) " yn
        case $yn in
            [Yy]*) break;;
            [Nn]* ) echo "Aborting."; exit;;
            * ) echo "Aborting."; exit;;
        esac
    done
}

function download() {
    echo "This will:
    - Create a directory at $DB_DIR/download if it does not exist.
    - Wipe that directory to start clean.
    - Download the latest snapshot from snapshots.radix.live to that directory for date $CURRENT_DATE."

    yes_no
    download_snapshot
}

function extract() {
    echo "This will:
    - Stop your Radix node.
    - Wipe the ledger database directory at $DB_DIR, except for the download directory.
    - Extract the snapshot to the database directory.
    - Set ownership of the database directory to $USER:$GROUP.
    - Start your Radix node."

    yes_no
    stop_node
    wipe_ledger
    extract_snapshot
    set_ownership
    start_node
}

function all() {
    echo "This will:
    - Stop your Radix node.
    - Download the snapshot from snapshots.radix.live for date $CURRENT_DATE.
    - Wipe the ledger database directory at $DB_DIR, except for the download directory.
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
    echo "Usage: ledger-snapshot [-y] [-d DATE] [install|download|extract|help]

Options:
    -y          Skip confirmation prompts.
    -d DATE     Use the specified date (YYYY-MM-DD) for snapshot download.

Subcommands:
    install     Run all steps: download and extract the database, and restart the Radix node.
    download    Only download the latest snapshot from snapshots.radix.live.
    extract     Extract the snapshot to the database directory.
    help        Display this help message.

Each command will list its steps and ask for confirmation before proceeding.
This script automatically detects and uses the database directory and user/group ownership variables from your NixOS configuration to make the process as seamless as possible."
}

# Process subcommand
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