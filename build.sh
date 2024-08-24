#!/bin/bash
sudo chmod 777 -R ./bin/*
source modules/framework.sh
source modules/packing.sh
source modules/smali.sh
source modules/vietnamize.sh
source modules/common.sh

URL="${1:-"https://bn.d.miui.com/V14.0.14.0.TMLCNXM/miui_COROT_V14.0.14.0.TMLCNXM_0c4fddade3_13.0.zip"}"
GITHUB_ENV="$2"
core_patch=${3:-true}
build_type="${4:-"erofs"}" # erofs/ext4

# Thiết lập quyền truy cập cho tất cả các tệp trong thư mục hiện tại
is_clean=$([ -n "$1" ] && echo true || echo false)
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
APK_TOOL="$BIN_DIR/apktool/apktool"

# export PATH=$(pwd)/bin/$(uname)/$(uname -m)/:$PATH
# echo $(uname)/$(uname -m)
export PATH="$BIN_DIR:$PATH"

EXTRACT_LIST=('product' 'system' 'system_ext' 'vendor')
SUPER_LIST=('mi_ext' 'odm' 'product' 'system' 'system_dlkm' 'system_ext' 'vendor' 'vendor_dlkm' 'odm_dlkm')
EXT4_LIST=('product' 'system' 'system_ext')
# super_size=9126805504
sdk_version="34"
version_release=14

zip_name=$(echo ${URL} | cut -d"/" -f5)
os_version=$(echo ${URL} | cut -d"/" -f4)
android_version=$(echo ${URL} | cut -d"_" -f5 | cut -d"." -f1)
build_time=$(TZ="Asia/Ho_Chi_Minh" date +"%Y%m%d_%H%M%S")
max_threads=$(lscpu | grep "^CPU(s):" | awk '{print $2}')

read_info() {
    product_build_prop="$EXTRACTED_DIR/product/etc/build.prop"
    vendor_build_prop="$EXTRACTED_DIR/vendor/build.prop"
    
    # Đọc thông tin sdk_version
    sdk_version=$(grep -w ro.product.build.version.sdk "$product_build_prop" | cut -d"=" -f2)
    green "- SDK Version: $sdk_version"
    
    # Đọc thông tin device
    device=$(grep -w ro.product.mod_device "$vendor_build_prop" | cut -d"=" -f2)
    green "- Device: $device"
    
    # Đọc thông tin version_release
    version_release=$(grep -w ro.product.build.version.release "$product_build_prop" | cut -d"=" -f2)
    green "- Version Release: $version_release"
}
#----------------------------------------------------------------------------------------------------------------------------------
main() {
    rm -f "$LOG_FILE" >/dev/null 2>&1
    mkdir -p "$OUT_DIR"
    touch "$LOG_FILE"
    
    blue "========================================="
    blue "START build"
    start_build=$(date +%s)
    yellow "Core patch: $core_patch"
    yellow "Build type: $build_type"
    
    download_and_extract
    extract_img
    read_info
    disable_avb_and_dm_verity
    vietnamize
    remove_bloatware
    add_google
    # # ==============================================
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
    # # changhuapeng_patch
    
    recompile_smali "$framework"
    recompile_smali "$services"
    recompile_smali "$miui_framework"
    recompile_smali "$miui_services"
    
    modify
    replace_package_install
    # # #==============================================
    repack_img_and_super
    generate_script
    zip_rom
    
    end_build=$(date +%s)
    blue "END build in $((end_build - start_build)) seconds"
}
find "$PROJECT_DIR" -type f -name "*.sh" -exec dos2unix -q {} +
main