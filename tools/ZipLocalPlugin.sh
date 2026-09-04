#!/usr/bin/env bash
# macOS/Linux equivalent of run.cmd: zip the plugin, install it, launch calibre in debug mode.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# echo "$SCRIPT_DIR"
ZIP_PATH="$SCRIPT_DIR/../_garage/Annotations-test.zip"

cd "$SCRIPT_DIR/.."

EXCLUDES=()
while IFS= read -r pattern || [ -n "$pattern" ]; do
    [ -z "$pattern" ] && continue
    case "$pattern" in
        */) pattern="${pattern}*" ;;  # "dir/" alone won't match dir contents
    esac
    EXCLUDES+=("$pattern")
done < .distignore

rm -f "$ZIP_PATH"
zip -r "$ZIP_PATH" . -x "${EXCLUDES[@]}"

# calibre-customize -a "$ZIP_PATH"
# calibre-debug -g
