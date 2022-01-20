#!/bin/bash -ue
# vim: ts=4 sw=4 et

source "${BUILD_BIN_CONFIG:-./bin/config.sh}" quiet

title "CLEANUP"

source "${BUILD_DIR_BIN}/clean_box.sh"

highlight "Cleaning sources ..."

deleteitem="${BUILD_ROOT}/download"
step "Cleanup broken wget downloads: '${deleteitem}'"
rm -f "${deleteitem}" || true

deleteitem="${BUILD_ROOT}/.vagrant/"
step "Remove vagrant dir: '${deleteitem}'"
rm -rf "${deleteitem}" || true

deleteitem="${BUILD_ROOT}/packer_cache/"
step "Remove packer_cache: '${deleteitem}'"
rm -rf "${deleteitem}" || true

deleteitem="${BUILD_ROOT}/output-gold/"
step "Remove packer output dir: '${deleteitem}'"
rm -rf "${deleteitem}" || true

# always delete build_version as this is generated on config time
deleteitem="${BUILD_DIR_BUILD}/build_version"
step "Remove build version: '${deleteitem}'"
rm -f "${deleteitem}" || true

# delete all items except build_number
for file in "${BUILD_DIR_BUILD}"/* ; do
    if [ -f "$file" ]; then
        if [ "$file" == "${BUILD_DIR_BUILD}/build_number" ]; then
            step "Skipping build number: '${file}'"
        else
            step "Remove build related file: '${file}'"
            rm -f "$file" || true
        fi
    else
        if [ "$file" == "${BUILD_DIR_BUILD}/*" ]; then
            step "Remove build dir: '${BUILD_DIR_BUILD}'"
            rm -rf "${BUILD_DIR_BUILD}" || true
        else
            warn "Location '${file}' not expected! Skipping ..."
        fi
    fi
done

final "All done. You may now run 'make build' to build a fresh box."
