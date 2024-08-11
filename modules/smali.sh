decompile_smali() {
    local targetfilefullpath="$1"
    local tmp="${OUT_DIR}/tmp"
    local targetfilename=$(basename "$targetfilefullpath")
    local foldername="${targetfilename%.*}"

    blue "START decompile $targetfilename"

    # Xóa thư mục tạm thời nếu tồn tại và tạo lại thư mục
    rm -rf "$tmp/$foldername/"
    mkdir -p "$tmp/$foldername/"

    # Sao chép tệp mục tiêu vào thư mục tạm thời
    cp -rf "$targetfilefullpath" "$tmp/$foldername/"

    # Giải nén các tệp .dex từ tệp mục tiêu
    7za x -y "$tmp/$foldername/$targetfilename" "*.dex" -o"$tmp/$foldername" >/dev/null

    # Lặp qua các tệp .dex và decompile
    for dexfile in "$tmp/$foldername"/*.dex; do
        if [[ -e "$dexfile" ]]; then
            smalifname=$(basename "${dexfile%.*}")
            $BAKSMALI_COMMAND d --api $sdk_version "$dexfile" -o "$tmp/$foldername/$smalifname" >/dev/null 2>&1 || error "Decompiled $smalifname failed"
            green "Decompiled $smalifname completed"
        else
            error "No .dex files found in $tmp/$foldername"
        fi
        unset dexfile
    done
    blue "END decompile $targetfilename"
}

recompile_smali() {
    local targetfilefullpath="$1"
    local tmp="${OUT_DIR}/tmp"
    local targetfilename=$(basename $targetfilefullpath)
    local foldername=${targetfilename%.*}
    blue "START recompile $targetfilename"

    for dir in "$tmp/$foldername"/*/; do
        if [[ -d "$dir" ]]; then
            local dir_name=$(basename "$dir")
            ${SMALI_COMMAND} a --api ${sdk_version} $tmp/$foldername/${dir_name} -o $tmp/$foldername/${dir_name}.dex >/dev/null 2>&1 || error "ERROR Smaling failed"
            pushd $tmp/$foldername/ >/dev/null || exit
            7za a -y -mx0 -tzip $targetfilename ${dir_name}.dex >/dev/null 2>&1 || error "Failed to modify $targetfilename"
            popd >/dev/null || exit
            green "Recompiled $dir_name completed"
        fi
        unset dir
    done

    if [[ $targetfilename == *.apk ]]; then
        green "APK file detected, initiating ZipAlign process..."
        rm -rf ${targetfilefullpath}
        zipalign -p -f -v 4 $tmp/$foldername/$targetfilename ${targetfilefullpath} >/dev/null 2>&1 || error "zipalign error,please check for any issues"
        green "APK ZipAlign process completed."
        $APKSIGNER_COMMAND sign --key $BIN_DIR/apktool/Key/testkey.pk8 --cert $BIN_DIR/apktool/Key/testkey.x509.pem ${targetfilefullpath} /dev/null 2>&1 || error "APK signing error,please check for any issues"
        green "APK signing process completed."
    else
        green "Copying file to target ${targetfilefullpath}"
        cp -rf $tmp/$foldername/$targetfilename ${targetfilefullpath}
    fi

    rm -rf $tmp/$foldername
    if [ -d "$tmp" ] && [ -z "$(ls -A "$tmp")" ]; then
        rm -rf "$tmp"
    fi

    blue "END recompile $targetfilename"
}