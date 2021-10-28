#!/bin/bash -ue
# vim: ts=4 sw=4 et

source "${BUILD_LIB_UTILS:-./bin/lib/utils.sh}" "$*"

require_commands wget b2sum

highlight "Processing distfiles ..."

if [[ -f "$BUILD_FILE_DISTFILESLIST" ]]; then
    step "Ensure dir '${BUILD_DIR_DISTFILES##*/}' dir exists ..."
    mkdir -p "$BUILD_DIR_DISTFILES" || true
    step "Parsing '${BUILD_FILE_DISTFILESLIST}' ..."
    line_number=0
    old_IFS=$IFS # save the field separator
    IFS=$'\n' # new field separator, the end of line
    for line in $(cat "$BUILD_FILE_DISTFILESLIST"); do
        line_number=$((line_number+1))
        shopt -s extglob; line=${line##*( )}; line="${line%%*( )}"; shopt -u extglob # remove leading and trailing spaces
        [[ $line =~ ^#.* ]] && continue # skip comments
        file_hash=""
        file_name=""
        file_url=""
        count=0
        IFS=$' ' read -ra file_info <<< "$line"
        for i in "${file_info[@]}"; do
            count=$((count+1))
            case $count in
                1) file_hash="$i" ;; # BLAKE2B
                2) file_name="$i" ;; # filename
                3) file_url="$i"  ;; # download url
                *) error "More than three space separated values in line $line_number: $line"; exit 1 ;;
            esac
        done
        if [ ! $count -eq 3 ]; then
            error "Expected three space separated values, but got only $count in line $line_number: $line"
            exit 1
        fi
        step "Looking for file '$file_name' ..."
        if [ ! -f "${BUILD_DIR_DISTFILES}/$file_name" ]; then
            step "Downloading '$file_name' ..."
            wget -c "$file_url" -O "${BUILD_DIR_DISTFILES}/$file_name" || warn "Something went wrong."
            todo "Check wget exit status"
        fi
        step "Verifying file integrity ..."
        if [ -f "${BUILD_DIR_DISTFILES}/$file_name" ]; then
            file_expected_hash=$(cat "${BUILD_DIR_DISTFILES}/$file_name" | b2sum -b | sed -e "s/ .*//g")
            if [[ "$file_hash" = "$file_expected_hash" ]]; then
                success "$file_name"
                continue
            else
                warn "Verification failed, checksum did not match!"
                result $file_expected_hash
                result $file_hash
            fi
            # checksum did not match
            todo "Report and offer delete and restart of this script"
        else
            error "Unable to download '$file_name' from '$file_url'."
            exit 1
        fi
    done
    IFS=$old_IFS # restore default field separator

else
    step "File '${BUILD_FILE_DISTFILESLIST##*/}' not found."
fi
