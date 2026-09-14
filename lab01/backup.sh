#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
    printf 'Usage: %s SOURCE_DIRECTORY [BACKUP_DIRECTORY]\n' "$0" >&2
    exit 64
fi

source_dir=$1
backup_dir=${2:-/backup}

if [[ ! -d "$source_dir" ]]; then
    printf 'Error: source directory does not exist: %s\n' "$source_dir" >&2
    exit 1
fi

if [[ ! -d "$backup_dir" ]]; then
    printf 'Error: backup directory does not exist: %s\n' "$backup_dir" >&2
    exit 1
fi

source_dir=${source_dir%/}
source_name=$(basename "$source_dir")
date_stamp=$(date +%Y-%m-%d_%H-%M-%S)
archive_path="$backup_dir/${source_name}_${date_stamp}.tar.gz"

# Store the directory itself in the archive while avoiding an absolute path.
parent_dir=$(dirname "$source_dir")
tar -czf "$archive_path" -C "$parent_dir" "$source_name"
printf 'Backup created: %s\n' "$archive_path"

