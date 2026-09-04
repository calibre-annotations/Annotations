#!/usr/bin/env bash
# macOS/Linux equivalent of BuildLanguageFiles.cmd, plus the compile step it never had.
# Extracts translatable strings from the source, merges them into each language's
# .po file, then compiles the .mo catalogues that calibre's load_translations() reads.
# Needs GNU gettext (macOS: brew install gettext).
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

# german.po duplicates de.po and has never shipped compiled; default.po is the template.
LANGUAGES=(es fr it de ja ko zh_CN zh_TW nl pt_BR ru tr uk vi)

for tool in xgettext msginit msgmerge msgattrib msgfmt; do
    command -v "$tool" > /dev/null || {
        echo "$tool not found. Install GNU gettext (macOS: brew install gettext)." >&2
        exit 1
    }
done

# Array, not a bare list: "annotated_books - Copy.py" has a space in it.
SOURCES=()
while IFS= read -r f; do
    SOURCES+=("$f")
done < <(git ls-files '*.py' | grep -v '^readers/_' | grep -v ' - Copy')

xgettext --from-code=UTF-8 --package-name="Annotations Plugin" \
    --output=translations/default.po "${SOURCES[@]}"

for lang in "${LANGUAGES[@]}"; do
    echo "-- $lang"
    if [ ! -f "translations/$lang.po" ]; then
        msginit --input=translations/default.po --locale="$lang" \
            --output-file="translations/$lang.po" --no-translator
    fi
    msgmerge --update --backup=none "translations/$lang.po" translations/default.po

    # Don't ship a .mo for a language nobody has started. msgattrib keeps the
    # header alongside any real translations, so >1 means there is something.
    entries=$(msgattrib --translated --no-fuzzy --no-obsolete "translations/$lang.po" | grep -c '^msgid "' || true)
    if [ "$entries" -gt 1 ]; then
        msgfmt --statistics --output-file="translations/$lang.mo" "translations/$lang.po"
    else
        echo "   nothing translated yet, no .mo written"
    fi
done
