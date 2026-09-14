#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
    printf 'Usage: %s PDF_FILE [LANGUAGE]\n' "$0" >&2
    exit 64
fi

pdf_file=$1
language=${2:-en}

if [[ ! -f "$pdf_file" ]]; then
    printf 'Error: PDF file does not exist: %s\n' "$pdf_file" >&2
    exit 1
fi

if [[ ! -r "$pdf_file" ]]; then
    printf 'Error: PDF file is not readable: %s\n' "$pdf_file" >&2
    exit 1
fi

for utility in pdftotext tesseract; do
    if ! command -v "$utility" >/dev/null 2>&1; then
        printf 'Error: required utility is missing: %s\n' "$utility" >&2
        exit 1
    fi
done

output_file=${pdf_file%.pdf}.txt
if [[ "$output_file" == "$pdf_file" ]]; then
    output_file=${pdf_file%.PDF}.txt
fi

# Prefer embedded text; use OCR for scanned PDFs with no extractable text.
temporary_text=$(mktemp)
temporary_dir=$(mktemp -d)
cleanup() {
    rm -f -- "$temporary_text"
    rm -rf -- "$temporary_dir"
}
trap cleanup EXIT

pdftotext -layout -- "$pdf_file" "$temporary_text" || :
if [[ -s "$temporary_text" ]] && grep -q '[^[:space:]]' "$temporary_text"; then
    cp -- "$temporary_text" "$output_file"
else
    if ! command -v pdftoppm >/dev/null 2>&1; then
        printf 'Error: pdftoppm is required to process scanned PDFs.\n' >&2
        exit 1
    fi
    pdftoppm -png -- "$pdf_file" "$temporary_dir/page" >/dev/null
    : > "$output_file"
    shopt -s nullglob
    images=("$temporary_dir"/page-*.png)
    if [[ ${#images[@]} -eq 0 ]]; then
        printf 'Error: no pages could be rendered from the PDF.\n' >&2
        exit 1
    fi
    for image in "${images[@]}"; do
        tesseract "$image" stdout -l "$language" 2>/dev/null >> "$output_file"
        printf '\n' >> "$output_file"
    done
fi

printf 'Text saved to: %s\n' "$output_file"


