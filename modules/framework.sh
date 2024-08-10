framework_patcher() {
    echo -e "\n========================================="
    start_time=$(date +%s)
    echo "- Framework patcher by Jefino9488" >>"$LOG_FILE"
    echo "Modding framework"
    cd $OUT_DIR
    local url="https://github.com/Jefino9488/FrameworkPatcher/archive/refs/heads/master.zip"
    local framework_patcher="$OUT_DIR/FrameworkPatcher-main"

    curl -s --location --remote-name "$url"
    7za x master.zip -aoa >/dev/null 2>&1
    rm -rf master.zip

    echo "Moving framework/classes to classes..."
    mv -f "$OUT_DIR/tmp/framework/classes" "$framework_patcher/classes"
    echo "Moving framework/classes2 to classes2..."
    mv -f "$OUT_DIR/tmp/framework/classes2" "$framework_patcher/classes2"
    echo "Moving framework/classes3 to classes3..."
    mv -f "$OUT_DIR/tmp/framework/classes3" "$framework_patcher/classes3"
    echo "Moving framework/classes4 to classes4..."
    mv -f "$OUT_DIR/tmp/framework/classes4" "$framework_patcher/classes4"
    echo "Moving framework/classes5 to classes5..."
    mv -f "$OUT_DIR/tmp/framework/classes5" "$framework_patcher/classes5"
    echo "Moving services/classes to services_classes..."
    mv -f "$OUT_DIR/tmp/services/classes" "$framework_patcher/services_classes"
    echo "Moving services/classes2 to services_classes2..."
    mv -f "$OUT_DIR/tmp/services/classes2" "$framework_patcher/services_classes2"
    echo "Moving services/classes3 to services_classes3..."
    mv -f "$OUT_DIR/tmp/services/classes3" "$framework_patcher/services_classes3"
    echo "Moving miui-framework/classes to miui_framework_classes..."
    mv -f "$OUT_DIR/tmp/miui-framework/classes" "$framework_patcher/miui_framework_classes"
    echo "Moving miui-services/classes to miui_services_classes..."
    mv -f "$OUT_DIR/tmp/miui-services/classes" "$framework_patcher/miui_services_classes"

    cd $framework_patcher
    python3 "framework_patch.py"
    python3 "miui-service_Patch.py"
    python3 "miui-framework_patch.py"
    python3 "miui-service_Patch.py"

    cp -rf "$framework_patcher/magisk_module/system/." $EXTRACTED_DIR

    echo "Moving classes to framework..."
    mv -f "$framework_patcher/classes" "$OUT_DIR/tmp/framework/classes"
    echo "Moving classes2 to framework..."
    mv -f "$framework_patcher/classes2" "$OUT_DIR/tmp/framework/classes2"
    echo "Moving classes3 to framework..."
    mv -f "$framework_patcher/classes3" "$OUT_DIR/tmp/framework/classes3"
    echo "Moving classes4 to framework..."
    mv -f "$framework_patcher/classes4" "$OUT_DIR/tmp/framework/classes4"
    echo "Moving classes5 to framework..."
    mv -f "$framework_patcher/classes5" "$OUT_DIR/tmp/framework/classes5"
    echo "Moving services_classes to services..."
    mv -f "$framework_patcher/services_classes" "$OUT_DIR/tmp/services/classes"
    echo "Moving services_classes2 to services..."
    mv -f "$framework_patcher/services_classes2" "$OUT_DIR/tmp/services/classes2"
    echo "Moving services_classes3 to services..."
    mv -f "$framework_patcher/services_classes3" "$OUT_DIR/tmp/services/classes3"
    echo "Moving miui_framework_classes to miui-framework..."
    mv -f "$framework_patcher/miui_framework_classes" "$OUT_DIR/tmp/miui-framework/classes"
    echo "Moving miui_services_classes to miui-services..."
    mv -f "$framework_patcher/miui_services_classes" "$OUT_DIR/tmp/miui-services/classes"

    cd $PROJECT_DIR
    rm -rf $framework_patcher
    end_time=$(date +%s)
    echo "Framework patching xong trong $(($end_time - $start_time)) giây"
}

# google_photo_cts() {
#     echo -e "\n========================================="
#     echo "- Mod google photos unlimited, bypass CTS, spoofing Device" >>"$LOG_FILE"
#     echo "Modding google photos"
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
#     echo "Done modding google photos in $((end_time - start_time))s"
# }

google_photo_cts() {
    echo -e "\n========================================="
    echo "- Google photos Unlimited" >>"$LOG_FILE"
    echo "Modding google photos"
    python3 "${FILES_DIR}/gg_cts/update_device.py"
    local target_folder="${OUT_DIR}/tmp/framework"
    local application_smali="$target_folder/classes/android/app/Application.smali"
    local application_stub_smali="$target_folder/classes/android/app/ApplicationStub.smali"
    sed -i '/^.method public onCreate/,/^.end method/{//!d}' "$application_smali"
    sed -i -e '/^.method public onCreate/a\    .registers 1\n    invoke-static {p0}, Landroid/app/ApplicationStub;->onCreate(Landroid/app/Application;)V\n    return-void' $application_smali
    
    cp -f "${FILES_DIR}/gg_cts/ApplicationStub.smali" "$application_stub_smali"
    cp -f "${FILES_DIR}/gg_cts/nexus.xml" "$EXTRACTED_DIR/system/system/etc/sysconfig"

    sed -i 's/ro.product.first_api_level=33/ro.product.first_api_level=32/g' "$EXTRACTED_DIR/vendor/build.prop"

    echo "Done modding google photos"
}
