#!/bin/bash
URL="${1:-"https://bn.d.miui.com/OS1.0.18.0.UMLCNXM/miui_COROT_OS1.0.18.0.UMLCNXM_a086066b44_14.0.zip"}"
GITHUB_ENV="$2"
GITHUB_WORKSPACE="$3"

# Thiết lập quyền truy cập cho tất cả các tệp trong thư mục hiện tại
sudo chmod 777 -R ./bin/*
is_clean=$([ -n "$1" ] && echo true || echo false)
# export PATH="./lib:$PATH"
PROJECT_DIR=$(pwd)

BIN_DIR=$PROJECT_DIR/bin
OUT_DIR=$PROJECT_DIR/out
FILES_DIR=$PROJECT_DIR/files
LOG_FILE=$OUT_DIR/build.log

IMAGES_DIR=$OUT_DIR/images
EXTRACTED_DIR=$OUT_DIR/extracted
READY_DIR=$OUT_DIR/ready_flash
APKTOOL_COMMAND="java -jar $BIN_DIR/apktool/apktool.jar"
APKEDITTOR_COMMAND="java -jar $BIN_DIR/apktool/APKEditor-1.3.9.jar"
APKSIGNER_COMMAND="java -jar $BIN_DIR/apktool/apksigner.jar"
BAKSMALI_COMMAND="java -jar $BIN_DIR/apktool/baksmali.jar"
SMALI_COMMAND="java -jar $BIN_DIR/apktool/smali.jar"

export PATH=$(pwd)/bin/$(uname)/$(uname -m)/:$PATH
echo $(uname)/$(uname -m)

EXTRACT_LIST=('product' 'system' 'system_ext' 'vendor')
SUPER_LIST=('mi_ext' 'odm' 'product' 'system' 'system_dlkm' 'system_ext' 'vendor' 'vendor_dlkm' 'odm_dlkm')
super_size=9126805504
build_type="erofs" # erofs - ext4
sdk_version="34"

zip_name=$(echo ${URL} | cut -d"/" -f5)
os_version=$(echo ${URL} | cut -d"/" -f4)
android_version=$(echo ${URL} | cut -d"_" -f5 | cut -d"." -f1)
build_time=$(TZ="Asia/Ho_Chi_Minh" date +"%Y%m%d_%H%M%S")
max_threads=$(lscpu | grep "^CPU(s):" | awk '{print $2}')

source modules/framework.sh
source modules/packing.sh
source modules/smali.sh
source modules/vh.sh

read_info() {
    product_build_prop="$EXTRACTED_DIR/product/etc/build.prop"
    vendor_build_prop="$EXTRACTED_DIR/vendor/build.prop"

    # Đọc thông tin sdk_version
    sdk_version=$(grep -w ro.product.build.version.sdk "$product_build_prop" | cut -d"=" -f2)
    echo "- SDK Version: $sdk_version"

    # Đọc thông tin device
    device=$(grep -w ro.product.mod_device "$vendor_build_prop" | cut -d"=" -f2)
    echo "- Device: $device"

    echo "======================="
    echo "Thông tin hệ thống:"
    echo "======================="
    echo "SDK Version: $sdk_version"
    echo "Device: $device"
    echo "======================="
}

remove_bloatware() {
    echo ""
    echo "========================================="
    echo "- Remove bloatware" >>"$LOG_FILE"
    echo "Remove bloatware packages"
    tr -d '\r' <"$PROJECT_DIR/bloatware" | tr -s '\n' | while IFS= read -r pkg; do
        pkg=$(echo "$pkg" | xargs) # Loại bỏ khoảng trắng thừa
        if [[ -n "$pkg" && "$pkg" != \#* ]]; then
            path="$EXTRACTED_DIR/$pkg"
            if [[ -d "$path" ]]; then
                # echo "Removing directory $path"
                rm -rf "$path"
            elif [[ -f "$path" ]]; then
                # echo "Removing file $path"
                rm -f "$path"
            fi
        fi
    done
}

add_google() {
    echo -e "\n========================================="
    echo "- Add Google Play Store, Gboard" >>"$LOG_FILE"
    echo "Add Google Play Store, Gboard"
    cp -rf "$FILES_DIR/common/." "$EXTRACTED_DIR/"
}

disable_avb_and_dm_verity() {
    echo -e "\n========================================="
    echo "- Disable AVB and dm-verity" >>"$LOG_FILE"
    echo 'Đang vô hiệu hóa xác minh AVB và mã hóa dữ liệu'
    # find "$EXTRACTED_DIR/" -type f -name 'fstab.*' | while read -r file; do
    find "$EXTRACTED_DIR/" -path "*/etc/*" -type f -name 'fstab.*' | while read -r file; do
        echo "Xử lý: $file"
        sed -i -E \
            -e 's/,avb(=[^,]+)?,/,/' \
            -e 's/,avb_keys=[^,]+avbpubkey//' \
            -e 's/,fileencryption=[^,]+,/,/' \
            -e 's/,metadata_encryption=[^,]+,/,/' \
            -e 's/,keydirectory=[^,]+,/,/' \
            "$file"
    done

    # # Thêm # và khoảng trắng vào đầu các dòng bắt đầu bằng "overlay"
    # sed -i '/^overlay/ s/^/# &/' "$file"
}

modify() {
    echo ""
    echo "========================================="
    echo "Modifying features"
    sed -i 's/persist.miui.extm.enable=1/persist.miui.extm.enable=0/g' "$EXTRACTED_DIR/system_ext/etc/build.prop"
    sed -i 's/persist.miui.extm.enable=1/persist.miui.extm.enable=0/g' "$EXTRACTED_DIR/product/etc/build.prop"

    sed -i 's/<bool name=\"support_hfr_video_pause\">false<\/bool>/<bool name=\"support_hfr_video_pause\">true<\/bool>/g' $EXTRACTED_DIR/product/etc/device_features/*.xml
    sed -i 's/<bool name=\"support_dolby\">false<\/bool>/<bool name=\"support_dolby\">true<\/bool>/g' $EXTRACTED_DIR/product/etc/device_features/*.xml
    sed -i 's/<bool name=\"support_video_hfr_mode\">false<\/bool>/<bool name=\"support_video_hfr_mode\">true<\/bool>/g' $EXTRACTED_DIR/product/etc/device_features/*.xml
    sed -i 's/<bool name=\"support_hifi\">false<\/bool>/<bool name=\"support_hifi\">true<\/bool>/g' $EXTRACTED_DIR/product/etc/device_features/*.xml
}
#----------------------------------------------------------------------------------------------------------------------------------
main() {
    # tạo file log
    start_time=$(date +%s)
    rm -f "$LOG_FILE" >/dev/null 2>&1
    mkdir -p "$OUT_DIR"
    touch "$LOG_FILE"

    download_and_extract
    read_info
    disable_avb_and_dm_verity
    remove_bloatware
    viet_hoa
    add_google
    #==============================================
    framework="$EXTRACTED_DIR"/system/system/framework/framework.jar
    services="$EXTRACTED_DIR"/system/system/framework/services.jar
    miui_framework="$EXTRACTED_DIR"/system_ext/framework/miui-framework.jar
    miui_services="$EXTRACTED_DIR"/system_ext/framework/miui-services.jar

    decompile_smali "$framework"
    decompile_smali "$services"
    decompile_smali "$miui_framework"
    decompile_smali "$miui_services"

    framework_patcher
    google_photo_cts

    recompile_smali "$framework"
    recompile_smali "$services"
    recompile_smali "$miui_framework"
    recompile_smali "$miui_services"

    modify
    #==============================================
    repack_img_and_super
    genrate_script
    zip_rom

    end_time=$(date +%s)
    echo "Build ROM trong $(($end_time - $start_time)) giây"
}
main
# viet_hoa
