#!/bin/bash -ue
# vim: ts=4 sw=4 et

. ./lib/functions.sh "$*"

require_commands wget b2sum

highlight "Processing distfiles ..."

if [[ -f "$PWD/distfiles.list" ]]; then
    step "Ensure 'distfiles' dir exists ..."
    mkdir -p "$PWD/distfiles" || true
    step "Parsing 'distfiles.list' ..."
    line_number=0
    old_IFS=$IFS # save the field separator
    IFS=$'\n' # new field separator, the end of line
    for line in $(cat "$PWD/distfiles.list"); do
        line_number=$((line_number+1))
        shopt -s extglob; line=${line##*( )}; line="${line%%*( )}"; shopt -u extglob # remove leading and trailing spaces
        [[ $line =~ ^#.* ]] && continue # skip comments
        #info "Line: $line"
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

        # DEBUG
        #result "File: $file_name"
        #result "Blake2b -> $file_hash"
        #result "URL -> $file_url"

        success "Processing file '$file_name' ..."
        step "Check if file is present ..."
        if [ ! -f "$PWD/distfiles/$file_name" ]; then
            warn "File is missing."
            step "Downloading file ..."
            wget -c "$file_url" -O "$PWD/distfiles/$file_name"
            todo "Check wget exit status"
        fi
        step "Verifying file integrity ..."
        if [ -f "$PWD/distfiles/$file_name" ]; then
            file_expected_hash=$(cat "$PWD/distfiles/$file_name" | b2sum -b | sed -e "s/ .*//g")
            if [[ "$file_hash" = "$file_expected_hash" ]]; then
                result "OK, checksum matched."
                continue
            else
                warn "Failed, checksum did not match"
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
    info "File 'distfiles.list' not found."
fi
