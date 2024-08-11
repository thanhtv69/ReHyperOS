error() {
    if [ "$#" -eq 1 ]; then
        local message="[$(date +%Y-%m-%d\ %H:%M:%S)] \033[1;31m$1\033[0m"
        echo -e "$message"                                    # In ra terminal với màu
        echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1" >>"$LOG_FILE" # Ghi vào log không có màu
    else
        echo "Usage: error <English>"
    fi
}

yellow() {
    if [ "$#" -eq 1 ]; then
        local message="[$(date +%Y-%m-%d\ %H:%M:%S)] \033[1;33m$1\033[0m"
        echo -e "$message"                                    # In ra terminal với màu
        echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1" >>"$LOG_FILE" # Ghi vào log không có màu
    else
        echo "Usage: yellow <English>"
    fi
}

blue() {
    if [ "$#" -eq 1 ]; then
        local message="[$(date +%Y-%m-%d\ %H:%M:%S)] \033[1;34m$1\033[0m"
        echo -e "$message"                                    # In ra terminal với màu
        echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1" >>"$LOG_FILE" # Ghi vào log không có màu
    else
        echo "Usage: blue <English>"
    fi
}

green() {
    if [ "$#" -eq 1 ]; then
        local message="[$(date +%Y-%m-%d\ %H:%M:%S)] \033[1;32m$1\033[0m"
        echo -e "$message"                                    # In ra terminal với màu
        echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1" >>"$LOG_FILE" # Ghi vào log không có màu
    else
        echo "Usage: green <English>"
    fi
}

remove_bloatware() {
    blue "========================================="
    blue "START Remove bloatware packages"
    tr -d '\r' <"$PROJECT_DIR/bloatware" | tr -s '\n' | while IFS= read -r pkg; do
        pkg=$(echo "$pkg" | xargs) # Loại bỏ khoảng trắng thừa
        if [[ -n "$pkg" && "$pkg" != \#* ]]; then
            path="$EXTRACTED_DIR/$pkg"
            if [[ -d "$path" ]]; then
                green "Removing directory $path"
                rm -rf "$path"
            elif [[ -f "$path" ]]; then
                green "Removing file $path"
                rm -f "$path"
            fi
        fi
    done
    blue "END Remove bloatware packages"
}

add_google() {
    blue "========================================="
    blue "START Add Google Play Store, Gboard"
    cp -rf "$FILES_DIR/common/." "$EXTRACTED_DIR/"
    blue "END Add Google Play Store, Gboard"
}

disable_avb_and_dm_verity() {
    blue "========================================="
    blue "- Disable AVB and dm-verity"
    # find "$EXTRACTED_DIR/" -type f -name 'fstab.*' | while read -r file; do
    find "$EXTRACTED_DIR/" -path "*/etc/*" -type f -name 'fstab.*' | while read -r file; do
        green "Xử lý: $file"
        sed -i -E \
            -e 's/,avb(=[^,]+)?,/,/' \
            -e 's/,avb_keys=[^,]+avbpubkey//' \
            -e 's/,fileencryption=[^,]+,/,/' \
            -e 's/,metadata_encryption=[^,]+,/,/' \
            -e 's/,keydirectory=[^,]+,/,/' \
            "$file"
    done
    blue "END Disable AVB and dm-verity"
    # # Thêm # và khoảng trắng vào đầu các dòng bắt đầu bằng "overlay"
    # sed -i '/^overlay/ s/^/# &/' "$file"
}

modify() {
    blue "========================================="
    blue "Modifying features"

    sed -i 's/persist.miui.extm.enable=1/persist.miui.extm.enable=0/g' "$EXTRACTED_DIR/system_ext/etc/build.prop"
    sed -i 's/persist.miui.extm.enable=1/persist.miui.extm.enable=0/g' "$EXTRACTED_DIR/product/etc/build.prop"

    sed -i 's/<bool name=\"support_hfr_video_pause\">false<\/bool>/<bool name=\"support_hfr_video_pause\">true<\/bool>/g' $EXTRACTED_DIR/product/etc/device_features/*.xml
    sed -i 's/<bool name=\"support_dolby\">false<\/bool>/<bool name=\"support_dolby\">true<\/bool>/g' $EXTRACTED_DIR/product/etc/device_features/*.xml
    sed -i 's/<bool name=\"support_video_hfr_mode\">false<\/bool>/<bool name=\"support_video_hfr_mode\">true<\/bool>/g' $EXTRACTED_DIR/product/etc/device_features/*.xml
    sed -i 's/<bool name=\"support_hifi\">false<\/bool>/<bool name=\"support_hifi\">true<\/bool>/g' $EXTRACTED_DIR/product/etc/device_features/*.xml

    blue "END Modifying features"
}

replace_package_install() {
    blue "========================================="
    blue "START Replace Package Installer"
    rm -rf "$EXTRACTED_DIR/product/priv-app/MIUIPackageInstaller"
    mkdir -p "$EXTRACTED_DIR/product/priv-app/ModPackageInstaller"
    cp -rf "$FILES_DIR/ModPackageInstaller/MiuiPackageInstaller.apk" "$EXTRACTED_DIR/product/priv-app/ModPackageInstaller/MiuiPackageInstaller.apk"

    sed -i 's/^ro\.control_privapp_permissions=.*$/ro.control_privapp_permissions=kashi/' "$EXTRACTED_DIR/vendor/build.prop"
    blue "END Replace Package Installer"
}
