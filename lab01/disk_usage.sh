#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 || $# -gt 4 ]]; then
    printf 'Usage: %s DIRECTORY MAXIMUM_MB [THRESHOLD_PERCENT] [EMAIL]\n' "$0" >&2
    printf 'Set DISK_USAGE_EMAIL to receive a notification when the threshold is exceeded.\n' >&2
    exit 64
fi

monitor_dir=$1
max_mb=$2
threshold=${3:-80}
email=${4:-${DISK_USAGE_EMAIL:-}}

if [[ ! -d "$monitor_dir" ]]; then
    printf 'Error: directory does not exist: %s\n' "$monitor_dir" >&2
    exit 1
fi

if [[ ! $max_mb =~ ^[1-9][0-9]*$ ]]; then
    printf 'Error: maximum volume must be a positive integer in megabytes.\n' >&2
    exit 1
fi

if [[ ! $threshold =~ ^[0-9]+([.][0-9]+)?$ ]] || ! awk "BEGIN { exit !($threshold >= 0 && $threshold <= 100) }"; then
    printf 'Error: threshold must be a number from 0 to 100 percent.\n' >&2
    exit 1
fi

used_mb=$(du -sm -- "$monitor_dir" | awk '{print $1}')
usage_percent=$(awk -v used="$used_mb" -v maximum="$max_mb" 'BEGIN { printf "%.2f", used * 100 / maximum }')
log_file=disk_usage.log
printf '%s directory=%s used_mb=%s limit_mb=%s usage_percent=%s%%\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$monitor_dir" "$used_mb" "$max_mb" "$usage_percent" >> "$log_file"
printf 'Current disk usage: %s%%\n' "$usage_percent"

if awk -v usage="$usage_percent" -v limit="$threshold" 'BEGIN { exit !(usage > limit) }'; then
    message="Disk usage for $monitor_dir is $usage_percent%, above the threshold of $threshold%."
    if [[ -z "$email" ]]; then
        printf 'Warning: %s Set DISK_USAGE_EMAIL to receive an email notification.\n' "$message" >&2
    elif ! command -v mail >/dev/null 2>&1; then
        printf 'Error: mail utility is required to send the notification.\n' >&2
        exit 1
    else
        printf '%s\n' "$message" | mail -s 'Disk usage threshold exceeded' "$email"
    fi
fi



