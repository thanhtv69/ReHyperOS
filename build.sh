#!/bin/bash
URL="${1:-"https://bn.d.miui.com/OS1.0.18.0.UMLCNXM/miui_COROT_OS1.0.18.0.UMLCNXM_a086066b44_14.0.zip"}"
GITHUB_ENV="$2"
GITHUB_WORKSPACE="$3"

# Thiết lập quyền truy cập cho tất cả các tệp trong thư mục hiện tại
sudo chmod 777 -R ./*
is_clean=$([ -n "$1" ] && echo true || echo false)
# export PATH="./lib:$PATH"
PROJECT_DIR=$(pwd)

BIN_DIR=$PROJECT_DIR/bin
OUT_DIR=$PROJECT_DIR/out
FILES_DIR=$PROJECT_DIR/files

IMAGES_DIR=$OUT_DIR/images
EXTRACTED_DIR=$OUT_DIR/extracted
READY_DIR=$OUT_DIR/ready_flash
APKTOOL_COMMAND="java -jar $BIN_DIR/apktool/apktool.jar"
BAKSMALI_COMMAND="java -jar $BIN_DIR/apktool/baksmali.jar"
SMALI_COMMAND="java -jar $BIN_DIR/apktool/smali.jar"

# project_dir=$(pwd)
# work_dir=${project_dir}/out
# tools_dir=${work_dir}/bin/$(uname)/$(uname -m)
export PATH=$(pwd)/bin/$(uname)/$(uname -m)/:$PATH
echo $(uname)/$(uname -m)

EXTRACT_LIST=('product' 'system' 'system_ext' 'vendor')
SUPER_LIST=('mi_ext' 'odm' 'product' 'system' 'system_dlkm' 'system_ext' 'vendor' 'vendor_dlkm' 'odm_dlkm')
super_size=9126805504
build_type="erofs" # erofs - ext4

zip_name=$(echo ${URL} | cut -d"/" -f5)
os_version=$(echo ${URL} | cut -d"/" -f4)
android_version=$(echo ${URL} | cut -d"_" -f5 | cut -d"." -f1)
build_time=$(TZ="Asia/Ho_Chi_Minh" date +"%Y%m%d_%H%M%S")
max_threads=$(lscpu | grep "^CPU(s):" | awk '{print $2}')

download_and_extract() {
    if [ ! -f "$zip_name" ]; then
        echo "Đang tải xuống... [$zip_name]"
        sudo aria2c -x16 -j$(nproc) -U "Mozilla/5.0" -d "$PROJECT_DIR" "$URL"
    fi

    echo "Đang giải nén... [payload.bin]"
    7za x "$zip_name" payload.bin -o"$OUT_DIR" -aos >/dev/null 2>&1
    [ "$is_clean" = true ] && rm -rf "$zip_name"

    echo "Đang tìm các phân vùng thiếu"
    payload_output=$(payload-dumper-go -l "$OUT_DIR/payload.bin")
    p_payload=($(echo "$payload_output" | grep -oP '\b\w+(?=\s\()'))

    # missing_partitions=""
    # for p in "${p_payload[@]}"; do
    #     if [ ! -e "$IMAGES_DIR/$p.img" ]; then
    #         if [ -z "$missing_partitions" ]; then
    #             missing_partitions="$p"
    #         else
    #             missing_partitions="$missing_partitions,$p"
    #         fi
    #     fi
    # done
    missing_partitions=$(for p in "${p_payload[@]}"; do [ ! -e "$IMAGES_DIR/$p.img" ] && echo -n "${missing_partitions:+$missing_partitions,}$p"; done)

    if [ ! -z "$missing_partitions" ]; then
        echo "Đang giải nén các phân vùng thiếu: [$missing_partitions]"
        payload-dumper-go -c "$max_threads" -o "$IMAGES_DIR" -p "$missing_partitions" "$OUT_DIR/payload.bin" >/dev/null 2>&1 || echo "Lỗi giải nén [payload.bin]"
        echo "Đã giải nén [$missing_partitions]"
    else
        echo "Đã đủ các phân vùng"
    fi
    [ "$is_clean" = true ] && rm -rf "$OUT_DIR/payload.bin"

    for partition in "${EXTRACT_LIST[@]}"; do
        if [ ! -f "$IMAGES_DIR/$partition.img" ]; then
            echo "Không tìm thấy $partition.img"
            exit 1
        fi
        echo "Đang giải nén tệp image... [$partition]"
        extract.erofs -x -i "$IMAGES_DIR/$partition.img" -o "$EXTRACTED_DIR" >/dev/null 2>&1
        if [ ! -d "$EXTRACTED_DIR/$partition" ]; then
            echo "Giải nén $partition.img thất bại"
            exit 1
        fi
        [ "$is_clean" = true ] && rm -rf "$IMAGES_DIR/$partition.img"
    done
}

read_info() {
    product_build_prop="$EXTRACTED_DIR/product/etc/build.prop"
    vendor_build_prop="$EXTRACTED_DIR/vendor/build.prop"

    # Đọc thông tin sdk_version
    sdk_version=$(grep -w ro.product.build.version.sdk "$product_build_prop" | cut -d"=" -f2)

    # Đọc thông tin device
    device=$(grep -w ro.product.mod_device "$vendor_build_prop" | cut -d"=" -f2)

    echo "======================="
    echo "Thông tin hệ thống:"
    echo "======================="
    echo "SDK Version: $sdk_version"
    echo "Device: $device"
    echo "======================="
}

repack_img_and_super() {
    # Kiểm tra và tạo thư mục READY_DIR nếu cần
    if [ ! -d "$READY_DIR/images" ]; then
        echo "Đang tạo thư mục $READY_DIR/images..."
        mkdir -p "$READY_DIR/images"
    fi

    # Lặp qua danh sách các phân vùng để đóng gói lại
    for partition in "${EXTRACT_LIST[@]}"; do
        echo "Đang đóng gói lại... [$partition]"

        # Đặt tên các tệp đầu vào và đầu ra
        input_folder_image="$EXTRACTED_DIR/$partition"
        output_image="$READY_DIR/images/$partition.img"

        fs_config_file="$EXTRACTED_DIR/config/${partition}_fs_config"
        file_contexts_file="$EXTRACTED_DIR/config/${partition}_file_contexts"

        # Chạy các tập lệnh Python để áp dụng cấu hình và bối cảnh
        python3 "$BIN_DIR/fspatch.py" "$input_folder_image" "$fs_config_file" >/dev/null 2>&1
        python3 "$BIN_DIR/contextpatch.py" "$input_folder_image" "$file_contexts_file" >/dev/null 2>&1

        # Thực hiện công cụ mkfs.erofs để đóng gói
        mkfs.erofs -zlz4hc -T 1230768000 --mount-point="$partition" --fs-config-file="$fs_config_file" --file-contexts="$file_contexts_file" "$output_image" "$input_folder_image" >/dev/null 2>&1 || echo "Lỗi đóng gói [$partition]"

        # Kiểm tra nếu quá trình đóng gói thất bại
        if [ ! -f "$output_image" ]; then
            echo "Quá trình đóng gói lại file [$output_image] thất bại."
            exit 1
        fi

        echo "Đã đóng gói lại thành công file $partition.img"
    done

    # Đóng gói các phân vùng thành super
    echo "Đóng gói các phân vùng thành [super.img]"
    super_out=$READY_DIR/images/super.img
    lpargs="-F --virtual-ab --output $super_out --metadata-size 65536 --super-name super --metadata-slots 3 --device super:$super_size --group=qti_dynamic_partitions_a:$super_size --group=qti_dynamic_partitions_b:$super_size"
    total_subsize=0
    for pname in "${SUPER_LIST[@]}"; do
        image_sub="$READY_DIR/images/$pname.img"
        if ! printf '%s\n' "${EXTRACT_LIST[@]}" | grep -q "^$pname$"; then
            cp -rf "$IMAGES_DIR/$pname.img" "$READY_DIR/images"
        fi
        subsize=$(du -sb $image_sub | tr -cd 0-9)
        total_subsize=$((total_subsize + subsize))
        args="--partition ${pname}_a:none:${subsize}:qti_dynamic_partitions_a --image ${pname}_a=${image_sub} --partition ${pname}_b:none:0:qti_dynamic_partitions_b"
        lpargs="$lpargs $args"
        echo "[$pname] size: $(printf "%'d" "$subsize")"
    done

    if [ "$total_subsize" -gt "$super_size" ]; then
        echo "Lỗi: Tổng kích thước ($total_subsize bytes) vượt quá kích thước tối đa cho phép ($super_size bytes)!"
        exit 1
    fi
    echo "Tổng kích thước: $(printf "%'d" "$total_subsize")/$(printf "%'d" "$super_size") bytes"

    lpmake $lpargs
    if [ -f "$super_out" ]; then
        echo "Đóng gói thành công super.img"@
        find "$READY_DIR/images" -type f -name '*.img' | grep -E "$(
            IFS=\|
            echo "${SUPER_LIST[*]}"
        )" | xargs rm -rf
    else
        echo "Không thể đóng gói super.img"
        exit 1
    fi
}

genrate_script() {
    echo "Tạo script để flash"
    for img_file in "$IMAGES_DIR"/*.img; do
        partition_name=$(basename "$img_file" .img)
        if ! printf '%s\n' "${EXTRACT_LIST[@]}" | grep -q "^$partition_name$" &&
            ! printf '%s\n' "${SUPER_LIST[@]}" | grep -q "^$partition_name$"; then
            cp -rf "$img_file" "$READY_DIR/images"
        fi
    done

    7za x $FILES_DIR/flash_tool.7z -o$READY_DIR -aoa >/dev/null 2>&1
    sed -i "s/Model_code/${device}/g" "$READY_DIR/FlashROM.bat"
}

zip_rom() {
    echo "Nén super.img"
    super_img=$READY_DIR/images/super.img
    super_zst=$READY_DIR/images/super.img.zst

    sudo find "$READY_DIR"/images/*.img -exec touch -t 200901010000.00 {} \;
    zstd -19 -f "$super_img" -o "$super_zst" --rm
    echo "Zip rom..."
    7za a "$READY_DIR"/miui.zip "$READY_DIR"/bin/* "$READY_DIR"/images/* "$READY_DIR"/FlashROM.bat -y -mx9
    md5=$(md5sum "$READY_DIR/miui.zip" | awk '{ print $1 }')
    rom_name="ReHyper_${device}_${os_version}_${md5:0:8}_${build_time}VN_${android_version}.0.zip"
    mv "$READY_DIR/miui.zip" "$READY_DIR/$rom_name"
}

remove_bloatware() {
    echo "Remove bloatware packages"
    bloatware=('product/data-app/com.iflytek.inputmethod.miui' 'product/data-app/BaiduIME' 'product/data-app/MiRadio' 'product/data-app/MIUIDuokanReader' 'product/data-app/SmartHome' 'product/data-app/MIUIVirtualSim' 'product/data-app/NewHomeMIUI15' 'product/data-app/MIUIGameCenter' 'product/data-app/MIUIYoupin' 'product/data-app/MIService' 'product/data-app/MIUIMiDrive' 'product/data-app/MIUIVipAccount' 'product/data-app/MIUIXiaoAiSpeechEngine' 'product/data-app/MIUIEmail' 'product/data-app/Health' 'product/app/UPTsmService' 'product/app/MIUISuperMarket' 'product/data-app/MiShop' 'product/data-app/MIUIMusicT' 'product/data-app/MIGalleryLockscreen-MIUI15' 'product/data-app/MIpay' 'product/priv-app/MIUIBrowser' 'product/priv-app/MiGameCenterSDKService' 'product/app/PaymentService' 'product/app/system' 'product/app/XiaoaiRecommendation' 'product/app/AiAsstVision' 'product/app/MIUIAiasstService' 'product/priv-app/MIUIYellowPage' 'product/priv-app/MIUIAICR' 'product/app/VoiceAssistAndroidT' 'product/priv-app/MIUIQuickSearchBox' 'product/app/OtaProvision' 'product/app/MiteeSoterService' 'product/data-app/ThirdAppAssistant' 'product/app/MIS' 'product/app/HybridPlatform' 'product/priv-app/VoiceTrigger' 'system_ext/app/digitalkey' 'product/app/MIUIgreenguard' 'product/app/MiBugReport' 'product/app/MSA' 'system/system/priv-app/Stk1' 'product/app/MiteeSoterService' 'system_ext/app/MiuiDaemon' 'product/app/MIUIReporter' 'product/app/Updater' 'product/app/WMService' 'product/app/SogouInput' 'system/system/app/Stk' 'product/app/CarWith' 'product/priv-app/Backup' 'product/priv-app/MIUICloudBackup' 'product/priv-app/MIUIContentExtension' 'product/priv-app/GooglePlayServicesUpdater' 'product/app/MIUISecurityInputMethod')
    for pkg in "${bloatware[@]}"; do
        if [[ -d "$EXTRACTED_DIR"/$pkg ]]; then
            echo "Removing $pkg"
            rm -rf "$EXTRACTED_DIR"/$pkg
        fi
    done
}

add_vn() {
    echo "Add VietNameses"
    cp -rf "$FILES_DIR/common/." "$EXTRACTED_DIR/"
}

disable_avb_and_dm_verity() {
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

google_photo() {
    echo "Modding google photos"
    mkdir -p "$OUT_DIR/tmp"
    cp -rf "$EXTRACTED_DIR/system/system/framework/framework.jar" "$OUT_DIR/tmp/"
    $APKTOOL -d -f -t "$OUT_DIR/tmp/framework.jar" -o "$OUT_DIR/tmp/framework_out"
    echo "Done modding google photos"
}

# Replace Smali code in an APK or JAR file, without supporting resource patches.
# $1: Target APK/JAR file
# $2: Target Smali file (supports relative paths for Smali files)
# $3: Value to be replaced
# $4: Replacement value

decompile_smali() {
    local targetfilefullpath="$1"
    local tmp="${OUT_DIR}/tmp"
    local targetfilename=$(basename "$targetfilefullpath")
    local foldername="${targetfilename%.*}"

    echo "Decompiling $targetfilename"

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
            ${BAKSMALI_COMMAND} d --api ${sdk_version} "$dexfile" -o "$tmp/$foldername/$smalifname" # 2>&1 || echo "ERROR Baksmaling failed"
            echo "Decompiled $smalifname completed"
        else
            echo "No .dex files found in $tmp/$foldername"
        fi
        unset dexfile
    done
}

recompile_smali() {
    echo "Recompiling $targetfilename"
    local targetfilefullpath="$1"
    local tmp="${OUT_DIR}/tmp"
    local targetfilename=$(basename $targetfilefullpath)
    local foldername=${targetfilename%.*}

    for dir in "$tmp/$foldername"/*/; do
        if [[ -d "$dir" ]]; then
            local dir_name=$(basename "$dir")
            ${SMALI_COMMAND} a --api ${sdk_version} $tmp/$foldername/${dir_name} -o $tmp/$foldername/${dir_name}.dex # >/dev/null 2>&1 || echo "ERROR Smaling failed"
            pushd $tmp/$foldername/ >/dev/null || exit
            7za a -y -mx0 -tzip $targetfilename ${dir_name}.dex >/dev/null 2>&1 || echo "Failed to modify $targetfilename"
            popd >/dev/null || exit
            echo "Recompiled $dir_name completed"
        fi
        unset dir
    done

    if [[ $targetfilename == *.apk ]]; then
        echo "APK file detected, initiating ZipAlign process..."
        rm -rf ${targetfilefullpath}
        zipalign -p -f -v 4 $tmp/$foldername/$targetfilename ${targetfilefullpath} >/dev/null 2>&1 || echo "zipalign error,please check for any issues"
        echo "APK ZipAlign process completed."
        echo "Copying APK to target ${targetfilefullpath}"
    else
        echo "Copying file to target ${targetfilefullpath}"
        cp -rf $tmp/$foldername/$targetfilename ${targetfilefullpath}
    fi

    rm -rf $tmp/$foldername
    if [ -d "$tmp" ] && [ -z "$(ls -A "$tmp")" ]; then
        rm -rf "$tmp"
    fi
}
#-----------------------------------------------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------------------------------------------------------
# TODO MOD
# echo "Modding icons"
# git clone --depth=1 https://github.com/pzcn/Perfect-Icons-Completion-Project.git icons &>/dev/null
# for pkg in "$GITHUB_WORKSPACE"/images/product/media/theme/miui_mod_icons/dynamic/*; do
#     if [[ -d "$GITHUB_WORKSPACE"/icons/icons/$pkg ]]; then
#         rm -rf "$GITHUB_WORKSPACE"/icons/icons/$pkg
#     fi
# done
# rm -rf "$GITHUB_WORKSPACE"/icons/icons/com.xiaomi.scanner
# mv "$GITHUB_WORKSPACE"/images/product/media/theme/default/icons "$GITHUB_WORKSPACE"/images/product/media/theme/default/icons.zip
# rm -rf "$GITHUB_WORKSPACE"/images/product/media/theme/default/dynamicicons
# mkdir -p "$GITHUB_WORKSPACE"/icons/res
# mv "$GITHUB_WORKSPACE"/icons/icons "$GITHUB_WORKSPACE"/icons/res/drawable-xxhdpi
# cd "$GITHUB_WORKSPACE"/icons
# zip -qr "$GITHUB_WORKSPACE"/images/product/media/theme/default/icons.zip res
# cd "$GITHUB_WORKSPACE"/icons/themes/Hyper/
# zip -qr "$GITHUB_WORKSPACE"/images/product/media/theme/default/dynamicicons.zip layer_animating_icons
# cd "$GITHUB_WORKSPACE"/icons/themes/common/
# zip -qr "$GITHUB_WORKSPACE"/images/product/media/theme/default/dynamicicons.zip layer_animating_icons
# mv "$GITHUB_WORKSPACE"/images/product/media/theme/default/icons.zip "$GITHUB_WORKSPACE"/images/product/media/theme/default/icons
# mv "$GITHUB_WORKSPACE"/images/product/media/theme/default/dynamicicons.zip "$GITHUB_WORKSPACE"/images/product/media/theme/default/dynamicicons
# rm -rf "$GITHUB_WORKSPACE"/icons

# echo "Remove bloatware packages"
# bloatware=('product/data-app/com.iflytek.inputmethod.miui' 'product/data-app/BaiduIME' 'product/data-app/MiRadio' 'product/data-app/MIUIDuokanReader' 'product/data-app/SmartHome' 'product/data-app/MIUIVirtualSim' 'product/data-app/NewHomeMIUI15' 'product/data-app/MIUIGameCenter' 'product/data-app/MIUIYoupin' 'product/data-app/MIService' 'product/data-app/MIUIMiDrive' 'product/data-app/MIUIVipAccount' 'product/data-app/MIUIXiaoAiSpeechEngine' 'product/data-app/MIUIEmail' 'product/data-app/Health' 'product/app/UPTsmService' 'product/app/MIUISuperMarket' 'product/data-app/MiShop' 'product/data-app/MIUIMusicT' 'product/data-app/MIGalleryLockscreen-MIUI15' 'product/data-app/MIpay' 'product/priv-app/MIUIBrowser' 'product/priv-app/MiGameCenterSDKService' 'product/app/PaymentService' 'product/app/system' 'product/app/XiaoaiRecommendation' 'product/app/AiAsstVision' 'product/app/MIUIAiasstService' 'product/priv-app/MIUIYellowPage' 'product/priv-app/MIUIAICR' 'product/app/VoiceAssistAndroidT' 'product/priv-app/MIUIQuickSearchBox' 'product/app/OtaProvision' 'product/app/MiteeSoterService' 'product/data-app/ThirdAppAssistant' 'product/app/MIS' 'product/app/HybridPlatform' 'product/priv-app/VoiceTrigger' 'system_ext/app/digitalkey' 'product/app/MIUIgreenguard' 'product/app/MiBugReport' 'product/app/MSA' 'system/system/priv-app/Stk1' 'product/app/MiteeSoterService' 'system_ext/app/MiuiDaemon' 'product/app/MIUIReporter' 'product/app/Updater' 'product/app/WMService' 'product/app/SogouInput' 'system/system/app/Stk' 'product/app/CarWith' 'product/priv-app/Backup' 'product/priv-app/MIUICloudBackup' 'product/priv-app/MIUIContentExtension' 'product/priv-app/GooglePlayServicesUpdater' 'product/app/MIUISecurityInputMethod')
# for pkg in "${bloatware[@]}"; do
#     if [[ -d "$GITHUB_WORKSPACE"/images/$pkg ]]; then
#         echo "Removing $pkg"
#         rm -rf "$GITHUB_WORKSPACE"/images/$pkg
#     fi
# done

function main() {
    download_and_extract
    read_info
    disable_avb_and_dm_verity

    # modify
    remove_bloatware
    add_vn

    # build
    repack_img_and_super
    genrate_script
    # zip_rom
    # set_info_release
}
read_info
# main
framework="$EXTRACTED_DIR"/system/system/framework/framework.jar
powerkeeper="$EXTRACTED_DIR"/system/system/app/PowerKeeper/PowerKeeper.apk
decompile_smali "$powerkeeper"
recompile_smali "$powerkeeper"

# echo "rom_path=$rom_path" >>"$GITHUB_ENV"
# echo "rom_name=$rom_name" >>"$GITHUB_ENV"
# echo "os_version=$os_version" >>"$GITHUB_ENV"
# echo "device_name=$device" >>"$GITHUB_ENV"
# echo "rom_md5=$md5" >>"$GITHUB_ENV"
