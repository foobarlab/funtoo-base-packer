#!/bin/bash -ue
# vim: ts=4 sw=4 et

. ./lib/functions.sh

create_sum() {
    # TODO check given param(s)
    find "$PWD/$1" -type d |\
    sort |\
    while read dir; \
    do cd "${dir}"; \
        [ ! -f checksums.b2 ] && step "Processing " "${dir}" || result "Skipped '" "${dir}" "': checksums.b2 allready present" ; \
        [ ! -f checksums.b2 ] &&  b2sum * > checksums.b2 ; \
        chmod a=r "${dir}"/checksums.b2 ; \
    done
}

check_sum() {
    # TODO check given param(s)
    find "$PWD/$1" -name checksums.b2 | \
    sort | \
    while read file; \
        do cd "${file%/*}"; \
        b2sum -c checksums.b2; \
    done > checksums.log
}

#highlight "Creating distfiles dir ..."
#mkdir -p "$PWD/distfiles" || true

if [[ -d "$PWD/distfiles" ]]; then
    highlight "Check distfiles ..."
    check_sum "distfiles"
    cat "$PWD/checksums.log"

    highlight "Downloading distfiles ..."
    todo "Download distfiles if missing file checksums found (count files) ..."
    result "Nothing to download yet."

    highlight "Re-creating checksum ..."
    todo "Re-create checksum if needed ..."
    create_sum "distfiles"

    highlight "Re-checking checksum ..."
    todo "Re-check checksums, abort/continue if distfiles were still missing or download failed."
    check_sum "distfiles"
    cat "$PWD/checksums.log"
else
    warn "No distfiles dir found."
fi
