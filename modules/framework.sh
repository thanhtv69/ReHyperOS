framework_patcher() {
    blue "========================================="
    start_time=$(date +%s)
    blue "START Framework patcher by Jefino9488"
    cd $OUT_DIR
    local url="https://github.com/Jefino9488/FrameworkPatcher/archive/refs/heads/master.zip"
    local framework_patcher="$OUT_DIR/FrameworkPatcher-main"
    
    curl --location --remote-name --max-time 30 "$url" || cp -f $FILES_DIR/FrameworkPatcher-main.zip $OUT_DIR/master.zip
    7za x master.zip -aoa
    rm -rf master.zip
    
    green "Moving framework/classes to classes..."
    mv -f "$OUT_DIR/tmp/framework/classes" "$framework_patcher/classes"
    green "Moving framework/classes2 to classes2..."
    mv -f "$OUT_DIR/tmp/framework/classes2" "$framework_patcher/classes2"
    green "Moving framework/classes3 to classes3..."
    mv -f "$OUT_DIR/tmp/framework/classes3" "$framework_patcher/classes3"
    green "Moving framework/classes4 to classes4..."
    mv -f "$OUT_DIR/tmp/framework/classes4" "$framework_patcher/classes4"
    green "Moving framework/classes5 to classes5..."
    mv -f "$OUT_DIR/tmp/framework/classes5" "$framework_patcher/classes5"
    green "Moving services/classes to services_classes..."
    mv -f "$OUT_DIR/tmp/services/classes" "$framework_patcher/services_classes"
    green "Moving services/classes2 to services_classes2..."
    mv -f "$OUT_DIR/tmp/services/classes2" "$framework_patcher/services_classes2"
    green "Moving services/classes3 to services_classes3..."
    mv -f "$OUT_DIR/tmp/services/classes3" "$framework_patcher/services_classes3"
    green "Moving miui-framework/classes to miui_framework_classes..."
    mv -f "$OUT_DIR/tmp/miui-framework/classes" "$framework_patcher/miui_framework_classes"
    green "Moving miui-services/classes to miui_services_classes..."
    mv -f "$OUT_DIR/tmp/miui-services/classes" "$framework_patcher/miui_services_classes"
    
    cd $framework_patcher
    if [[ "$core_patch" == true ]]; then
        yellow "Core patching"
        python3 "framework_patch.py"
        python3 "miui-service_Patch.py"
    else
        yellow "Not core patching"
        python3 "nframework_patch.py"
        python3 "nservices_patch.py"
    fi
    python3 "miui-framework_patch.py"
    python3 "miui-service_Patch.py"
    
    cp -rf "$framework_patcher/magisk_module/system/." $EXTRACTED_DIR
    
    green "Moving classes to framework..."
    mv -f "$framework_patcher/classes" "$OUT_DIR/tmp/framework/classes"
    green "Moving classes2 to framework..."
    mv -f "$framework_patcher/classes2" "$OUT_DIR/tmp/framework/classes2"
    green "Moving classes3 to framework..."
    mv -f "$framework_patcher/classes3" "$OUT_DIR/tmp/framework/classes3"
    green "Moving classes4 to framework..."
    mv -f "$framework_patcher/classes4" "$OUT_DIR/tmp/framework/classes4"
    green "Moving classes5 to framework..."
    mv -f "$framework_patcher/classes5" "$OUT_DIR/tmp/framework/classes5"
    green "Moving services_classes to services..."
    mv -f "$framework_patcher/services_classes" "$OUT_DIR/tmp/services/classes"
    green "Moving services_classes2 to services..."
    mv -f "$framework_patcher/services_classes2" "$OUT_DIR/tmp/services/classes2"
    green "Moving services_classes3 to services..."
    mv -f "$framework_patcher/services_classes3" "$OUT_DIR/tmp/services/classes3"
    green "Moving miui_framework_classes to miui-framework..."
    mv -f "$framework_patcher/miui_framework_classes" "$OUT_DIR/tmp/miui-framework/classes"
    green "Moving miui_services_classes to miui-services..."
    mv -f "$framework_patcher/miui_services_classes" "$OUT_DIR/tmp/miui-services/classes"
    
    cd $PROJECT_DIR
    rm -rf $framework_patcher
    end_time=$(date +%s)
    blue "END Framework patcher by Jefino9488 ($(($end_time - $start_time))s)"
}

# google_photo_cts() {
#     blue "\n========================================="
#     blue "Mod google photos unlimited, bypass CTS, spoofing Device"
#     start_time=$(date +%s)

#     # TODO switch snap and mtk
#     7za x "$FILES_DIR/gg_cts/mtk.zip" "android/app" -o"$OUT_DIR/tmp/framework/classes" -aoa >/dev/null 2>&1
#     7za x "$FILES_DIR/gg_cts/mtk.zip" "android/security" -o"$OUT_DIR/tmp/framework/classes3" -aoa >/dev/null 2>&1
#     7za x "$FILES_DIR/gg_cts/mtk.zip" "com" -o"$OUT_DIR/tmp/framework/classes5" -aoa >/dev/null 2>&1

#     local build_prop_org="$EXTRACTED_DIR/system/system/build.prop"
#     local build_prop_mod="$FILES_DIR/gg_cts/build.prop"
#     while IFS= read -r line; do
#         if ! grep -Fxq "$line" "$build_prop_org"; then
#             sed -i "/# end of file/i $line" "$build_prop_org"
#         fi
#     done <$build_prop_mod

#     local white_key_org="$EXTRACTED_DIR/system_ext/etc/cust_prop_white_keys_list"
#     local white_key_mod="$FILES_DIR/gg_cts/cust_prop_white_keys_list"
#     while IFS= read -r line; do
#         if ! grep -Fxq "$line" "$white_key_org"; then
#             printf "\n%s" "$line" >>"$white_key_org"
#         fi
#     done <$white_key_mod

#     mkdir -p "$EXTRACTED_DIR/product/app/SoraOS"
#     cp -f "$FILES_DIR/gg_cts/SoraOS.apk" "$EXTRACTED_DIR/product/app/SoraOS/SoraOS.apk"

#     sed -i 's/ro.product.first_api_level=33/ro.product.first_api_level=32/g' "$EXTRACTED_DIR/vendor/build.prop"

#     end_time=$(date +%s)
#     blue "Done modding google photos in $((end_time - start_time))s"
# }
google_photo_cts() {
    blue "========================================="
    blue "START Modding google photos"
    
    # python3 "${FILES_DIR}/gg_cts/update_device.py" || yellow "Update device fail!"
    
    local target_folder="${OUT_DIR}/tmp/framework"
    local application_smali="$target_folder/classes/android/app/Application.smali"
    local application_stub_smali="$target_folder/classes/android/app/ApplicationStub.smali"
    
    sed -i '/^.method public onCreate/,/^.end method/{//!d}' "$application_smali"
    sed -i -e '/^.method public onCreate/a\    .registers 1\n    invoke-static {p0}, Landroid/app/ApplicationStub;->onCreate(Landroid/app/Application;)V\n    return-void' "$application_smali"
    
    if [ ! -f "$application_stub_smali" ]; then
        error "File $application_stub_smali does not exist. Please update guide for Google Photos"
        exit 1
    fi
    
    cp -f "${FILES_DIR}/gg_cts/ApplicationStub.smali" "$application_stub_smali"
    cp -f "${FILES_DIR}/gg_cts/nexus.xml" "$EXTRACTED_DIR/system/system/etc/sysconfig"
    
    blue "END Modding google photos"
}

download_changhuapeng_classes() {
    local output_file="$1"
    local specified_file="$2"
    local repo_api="https://api.github.com/repos/thanhtv69/FukkFramework/releases/latest"
    
    # Xóa tệp đầu ra nếu đã tồn tại
    [ -f "$output_file" ] && rm "$output_file"
    
    # Lấy URL tải về tất cả các tệp .dex
    local file_urls
    file_urls=$(curl -k -s "$repo_api" | jq -r '.assets[] | select(.name | endswith(".dex")) | .browser_download_url')
    
    # Kiểm tra nếu có ít nhất một URL
    if [ -n "$file_urls" ]; then
        local file_url
        
        if [ -n "$specified_file" ]; then
            # Nếu đã chỉ định tên file, chọn URL chứa tên file đó
            file_url=$(echo "$file_urls" | grep "$specified_file")
            if [ -z "$file_url" ]; then
                echo "Không tìm thấy URL tải cho tệp $specified_file"
                return 1
            fi
        else
            # Nếu không chỉ định, chọn URL ngẫu nhiên từ danh sách
            file_url=$(echo "$file_urls" | shuf -n 1)
        fi
        
        yellow "$file_url"
        
        # Tải xuống tệp .dex từ URL đã chọn và kiểm tra sự thành công
        curl -k -L -o "$output_file" "$file_url"
        if [ $? -eq 0 ]; then
            echo "Tệp đã được tải về $output_file"
        else
            echo "Lỗi: Tải tệp không thành công."
            return 1
        fi
    else
        echo "Không tìm thấy URL tải tệp .dex"
        return 1
    fi
}


changhuapeng_patch() {
    blue "========================================="
    blue "START Patching changhuapeng"
    
    dex_count=$(find "$OUT_DIR/tmp/framework" -name "*.dex" | wc -l)
    next_dex_index=$((dex_count + 1))
    new_dex_name="classes${next_dex_index}.dex"
    download_changhuapeng_classes "$OUT_DIR/tmp/framework/$new_dex_name" || cp -f "${FILES_DIR}/gg_cts/classes.dex" "$OUT_DIR/tmp/framework/$new_dex_name"
    7za a -y -mx0 -tzip "$OUT_DIR/tmp/framework/framework.jar" "$OUT_DIR/tmp/framework/$new_dex_name" >/dev/null 2>&1 || error "Failed to zip $new_dex_name"
    rm "$OUT_DIR/tmp/framework/$new_dex_name"
    
    # AndroidKeyStoreSpi-------------------------------------------------------------------------------------
    AndroidKeyStoreSpi="$OUT_DIR/tmp/framework/classes3/android/security/keystore2/AndroidKeyStoreSpi.smali"
    method_body=$(sed -n '/.method public engineGetCertificateChain/,/.end method/p' "$AndroidKeyStoreSpi")
    return_lines=$(echo "$method_body" | grep -n 'return-object' | cut -d: -f1)
    second_return_line_number=$(echo "$return_lines" | sed -n '2p')
    if [ -z "$second_return_line_number" ]; then
        error "Not found second return line in $AndroidKeyStoreSpi"
        exit 1
    fi
    v3_register=$(echo "$method_body" | sed -n "${second_return_line_number}p" | awk '{print $2}')
    if [ -z "$v3_register" ]; then
        error "No v3 register found in $AndroidKeyStoreSpi"
        exit 1
    fi
    new_code="invoke-static {${v3_register}}, Lcom/android/internal/util/framework/Android;->engineGetCertificateChain([Ljava/security/cert/Certificate;)[Ljava/security/cert/Certificate;\n    move-result-object ${v3_register}"
    sed -i "/.method public engineGetCertificateChain/,/.end method/ {
        /return-object ${v3_register}/i\\
    ${new_code}
    }" "$AndroidKeyStoreSpi"
    green "Updated AndroidKeyStoreSpi.smali"
    
    # Instrumentation-----------------------------------------------------------------------------
    Instrumentation="$OUT_DIR/tmp/framework/classes/android/app/Instrumentation.smali"
    context_register=$(grep -A 10 '.method public static newApplication' "$Instrumentation" | grep -oP '(?<=.param )\w+(?=, "context")')
    if [ -z "$context_register" ]; then
        error "No context register found in $Instrumentation"
        exit 1
    fi
    new_code="invoke-static {$context_register}, Lcom/android/internal/util/framework/Android;->newApplication(Landroid/content/Context;)V"
    sed -i "/.method public static newApplication/,/.end method/ {
        /return-object/ {
            i\\
    $new_code
        }
    }" "$Instrumentation"
    green "Updated Instrumentation.smali - public static newApplication1"
    
    context_register=$(grep -A 10 '.method public newApplication' "$Instrumentation" | grep -oP '(?<=.param )\w+(?=, "context")')
    if [ -z "$context_register" ]; then
        error "No context register found in $Instrumentation"
        exit 1
    fi
    
    new_code="invoke-static {$context_register}, Lcom/android/internal/util/framework/Android;->newApplication(Landroid/content/Context;)V"
    sed -i "/.method public newApplication/,/.end method/ {
        /return-object/ {
            i\\
    $new_code
        }
    }" "$Instrumentation"
    green "Updated Instrumentation.smali - public newApplication"
    
    # ApplicationPackageManager----------------------------------------------------------------------
    ApplicationPackageManager="$OUT_DIR/tmp/framework/classes/android/app/ApplicationPackageManager.smali"
    if [ ! -f "$ApplicationPackageManager" ]; then
        error "File $ApplicationPackageManager does not exist. Please update guide"
        exit 1
    fi
    sed -i '/^.method public hasSystemFeature(Ljava\/lang\/String;)Z/,/^.end method/{//!d}' "$ApplicationPackageManager"
    sed -i -e '/^.method public hasSystemFeature(Ljava\/lang\/String;)Z/a\    .registers 3\n    .param p1, "name"    # Ljava/lang/String;\n\n    .line 768\n    const/4 v0, 0x0\n\n    invoke-virtual {p0, p1, v0}, Landroid/app/ApplicationPackageManager;->hasSystemFeature(Ljava/lang/String;I)Z\n\n    move-result v0\n\n    invoke-static {v0, p1}, Lcom/android/internal/util/framework/Android;->hasSystemFeature(ZLjava/lang/String;)Z\n\n    move-result v0\n\n    return v0' "$ApplicationPackageManager"
    green "Updated ApplicationPackageManager.smali"
    
    # Very important! Remove all "boot-framework.*" files!
    
    find "$EXTRACTED_DIR/system/system/framework/" -type f -name "boot-framework.*" -exec rm {} +
    
    rm -f "$EXTRACTED_DIR/system/system/framework/arm/boot-framework.vdex"
    rm -f "$EXTRACTED_DIR/system/system/framework/arm64/boot-framework.vdex"
    
    blue "END Patching changhuapeng"
}
