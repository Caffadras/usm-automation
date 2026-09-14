#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 ]]; then
    printf 'Usage: %s DIRECTORY [EXTENSION ...]\n' "$0" >&2
    exit 64
fi

cleanup_dir=$1
shift

if [[ ! -d "$cleanup_dir" ]]; then
    printf 'Error: directory does not exist: %s\n' "$cleanup_dir" >&2
    exit 1
fi

extensions=("$@")
if [[ ${#extensions[@]} -eq 0 ]]; then
    extensions=(.tmp)
fi

# Normalize extensions so both "tmp" and ".tmp" are accepted.
for index in "${!extensions[@]}"; do
    [[ ${extensions[$index]} == .* ]] || extensions[$index]=.${extensions[$index]}
done

deleted_count=0
find_args=("$cleanup_dir" -type f '(')
for index in "${!extensions[@]}"; do
    (( index > 0 )) && find_args+=(-o)
    find_args+=(-name "*${extensions[$index]}")
done
find_args+=(')' -print0)

while IFS= read -r -d '' file; do
    rm -- "$file"
    ((deleted_count += 1))
done < <(find "${find_args[@]}")

printf 'Deleted files: %d\n' "$deleted_count"


