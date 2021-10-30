#!/bin/bash -ue
# vim: ts=4 sw=4 et

source "${BUILD_BIN_CONFIG:-./bin/config.sh}" quiet

title "CLEANUP TEMP"

source "${BUILD_DIR_BIN}/clean_box.sh"

highlight "Cleaning temporary files ..."

deleteitem="${BUILD_ROOT}/download"
step "Cleanup broken wget downloads: '${deleteitem}' ..."
rm -f "${deleteitem}" || true

deleteitem="${BUILD_ROOT}/.vagrant/"
step "Remove vagrant dir: '${deleteitem}' ..."
rm -rf "${deleteitem}" || true

deleteitem="${BUILD_ROOT}/packer_cache/"
step "Remove packer_cache: '${deleteitem}' ..."
rm -rf "${deleteitem}" || true

deleteitem="${BUILD_ROOT}/output-gold/"
step "Remove packer output dir: '${deleteitem}' ..."
rm -rf "${deleteitem}" || true

final "All done. Removed temporary files. Type 'make clean' to remove build dir."
