#!/bin/sh
set -eu

# Validate input argument
if [ $# -lt 1 ] || [ -z "$1" ]; then
    echo "Error: Video file path argument is required." >&2
    echo "Usage: $0 <video-file-path>" >&2
    exit 1
fi

FILE="$1"

# Validate that file exists and is a regular file
if [ ! -f "$FILE" ]; then
    echo "Error: File '$FILE' does not exist." >&2
    exit 1
fi

# Compute SHA-256 hash (portable across Linux and macOS)
if command -v sha256sum >/dev/null 2>&1; then
    SHA256=$(sha256sum "$FILE" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
    SHA256=$(shasum -a 256 "$FILE" | awk '{print $1}')
else
    echo "Error: Neither sha256sum nor shasum is available." >&2
    exit 1
fi

# Current UTC timestamp in ISO 8601 format
INGESTED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Append audit entry to manifest
OUTPUT_DIR="output"
mkdir -p "$OUTPUT_DIR"
MANIFEST="${OUTPUT_DIR}/evidence_manifest.jsonl"

printf '{"file":"%s","sha256":"%s","ingested_at":"%s"}\n' "$FILE" "$SHA256" "$INGESTED_AT" >> "$MANIFEST"

# Log to console
echo "File: $FILE"
echo "SHA-256: $SHA256"
