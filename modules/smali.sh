decompile_smali() {
    local file_path="$1"
    local temp_dir="${OUT_DIR}/tmp"
    local file_name=$(basename "$file_path")
    local base_name="${file_name%.*}"
    local dex_file
    local smali_name

    blue "START decompile $file_name"

    rm -rf "$temp_dir/$base_name/"
    mkdir -p "$temp_dir/$base_name/"
    cp -rf "$file_path" "$temp_dir/$base_name/"
    7za x -y "$temp_dir/$base_name/$file_name" "*.dex" -o"$temp_dir/$base_name" >/dev/null

    for dex_file in "$temp_dir/$base_name"/*.dex; do
        if [[ -e "$dex_file" ]]; then
            smali_name=$(basename "${dex_file%.*}")
            $BAKSMALI_COMMAND d --api $sdk_version "$dex_file" -o "$temp_dir/$base_name/$smali_name" >/dev/null 2>&1 || error "Decompiled $smali_name failed"
            green "Decompiled $smali_name completed"
        else
            error "No .dex files found in $temp_dir/$base_name"
        fi
    done

    blue "END decompile $file_name"
}

recompile_smali() {
    local file_path="$1"
    local tmp_dir="${OUT_DIR}/tmp"
    local file_name=$(basename "$file_path")
    local base_name="${file_name%.*}"

    blue "START recompile $file_name"

    for dir in "$tmp_dir/$base_name"/*/; do
        if [[ -d "$dir" ]]; then
            local smali_dir=$(basename "$dir")
            ${SMALI_COMMAND} a --api ${sdk_version} "$tmp_dir/$base_name/$smali_dir" -o "$tmp_dir/$base_name/$smali_dir.dex" >/dev/null 2>&1 || error "ERROR Smaling failed"
            pushd "$tmp_dir/$base_name/" >/dev/null || exit
            7za a -y -mx0 -tzip "$file_name" "$smali_dir.dex" >/dev/null 2>&1 || error "Failed to modify $file_name"
            popd >/dev/null || exit
            green "Recompiled $smali_dir completed"
        fi
    done

    if [[ $file_name == *.apk ]]; then
        green "APK file detected, initiating ZipAlign process..."
        rm -rf "$file_path"
        zipalign -p -f -v 4 "$tmp_dir/$base_name/$file_name" "$file_path" >/dev/null 2>&1 || error "zipalign error, please check for any issues"
        green "APK ZipAlign process completed."
        $APKSIGNER_COMMAND sign --key "$BIN_DIR/apktool/Key/testkey.pk8" --cert "$BIN_DIR/apktool/Key/testkey.x509.pem" "$file_path" >/dev/null 2>&1 || error "APK signing error, please check for any issues"
        green "APK signing process completed."
    else
        # green "Copying file to target $file_path"
        # cp -rf "$tmp_dir/$base_name/$file_name" "$file_path"
        zipalign -p -f -v 4 "$tmp_dir/$base_name/$file_name" "$file_path" >/dev/null 2>&1 || error "zipalign error, please check for any issues"
    fi

    rm -rf "$tmp_dir/$base_name"
    if [ -d "$tmp_dir" ] && [ -z "$(ls -A "$tmp_dir")" ]; then
        rm -rf "$tmp_dir"
    fi

    blue "END recompile $file_name"
}
