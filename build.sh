#!/bin/bash
URL="${1:-"https://bn.d.miui.com/OS1.0.18.0.UMLCNXM/miui_COROT_OS1.0.18.0.UMLCNXM_a086066b44_14.0.zip"}"
GITHUB_ENV="$2"
GITHUB_WORKSPACE="$3"

# Thiết lập quyền truy cập cho tất cả các tệp trong thư mục hiện tại
sudo chmod 777 -R ./*
is_clean=$([ -n "$1" ] && echo true || echo false)
# export PATH="./lib:$PATH"
PROJECT_DIR=$(pwd)
OUT_DIR=$PROJECT_DIR/out

# project_dir=$(pwd)
# work_dir=${project_dir}/out
# tools_dir=${work_dir}/bin/$(uname)/$(uname -m)
export PATH=$(pwd)/bin/$(uname)/$(uname -m)/:$PATH
echo $(uname)/$(uname -m)


extract_list=('product' 'system' 'system_ext' 'vendor')
super_list=('mi_ext' 'odm' 'product' 'system' 'system_dlkm' 'system_ext' 'vendor' 'vendor_dlkm' 'odm_dlkm')

zip_name=$(echo ${URL} | cut -d"/" -f5)
os_version=$(echo ${URL} | cut -d"/" -f4)
android_version=$(echo ${URL} | cut -d"_" -f5 | cut -d"." -f1)
build_time=$(TZ="Asia/Ho_Chi_Minh" date +"%Y%m%d_%H%M%S")

download_and_extract(){
    if [ ! -f "$zip_name" ]; then
        echo "Downloading... [$zip_name]"
        sudo aria2c -x16 -j$(nproc) -U "Mozilla/5.0" -d "$WORK_DIR" "$URL"
    fi

    echo "Extracting... [payload.bin]"
    # 7zzs e -aos "$zip_name" payload.bin -o"$OUT_DIR" >/dev/null 2>&1
    unzip -n $zip_name payload.bin -d $OUT_DIR
    [ "$is_clean" = true ] &&  rm -rf $zip_name

    echo "Extracting all images"
    # payload_extract -s -o "$OUT_DIR/images" -i "$OUT_DIR/payload.bin" -x -T0
    # payload-dumper-go -o "$OUT_DIR/images" "$OUT_DIR/payload.bin" >/dev/null 2>&1
    [ "$is_clean" = true ] && rm -rf "$OUT_DIR/payload.bin"

    for partition in "${extract_list[@]}"; do
        echo "Extracting... [$partition]"
        extract.erofs -i $OUT_DIR/images/$partition.img -o "$OUT_DIR"
        if [ ! -d "$OUT_DIR/$partition" ]; then
            echo "Extract $partition.img failed"
            exit 1
        fi
        rm -rf "$OUT_DIR/images/$partition.img"
    done
}

read_info() {
    sdk_version=$(grep -w ro.product.build.version.sdk "$OUT_DIR/product/etc/build.prop" | cut -d"=" -f2)
    device=$(grep -w ro.product.mod_device "$OUT_DIR/vendor/build.prop" | cut -d"=" -f2)
    echo "SDK=$sdk_version"
    echo "DEVICE=$device"
}

repack_img_and_super(){
    for partition in "${extract_list[@]}"; do
        echo "Repacking... [$partition]"

        # Đặt tên các tệp đầu vào và đầu ra
        input_folder_image="$OUT_DIR/$partition"
        output_image="$OUT_DIR/images/$partition.img"

        fs_config_file="$OUT_DIR/config/$partition"_fs_config
        file_contexts_file="$OUT_DIR/config/$partition"_file_contexts

        # Chạy các tập lệnh Python để áp dụng cấu hình và bối cảnh
        python3 fspatch.py "$input_folder_image" "$fs_config_file"
        python3 contextpatch.py "$input_folder_image" "$file_contexts_file"

        # Thực hiện công cụ make.erofs để đóng gói
        mkfs.erofs -zlz4hc -T 1230768000 \
            --mount-point="/$partition" \
            --fs-config-file="$fs_config_file" \
            --file-contexts="$file_contexts_file" \
            "$output_image" "$input_folder_image"

        if [ ! -f "$output_image" ]; then
            echo "Image [$output_image] repack process failed."
            exit 1
        fi
    done
}

#-----------------------------------------------------------------------------------------------------------------------------------
download_and_extract
read_info
# modify
repack_img_and_super
# pack_rom
# set_info_release
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
# bloatware=('product/data-app/com.iflytek.inputmethod.miui' 'product/data-app/BaiduIME' 'product/data-app/MiRadio' 'product/data-app/MIUIDuokanReader' 'product/data-app/SmartHome' 'product/data-app/MIUIVirtualSim' 'product/data-app/NewHomeMIUI15' 'product/data-app/MIUIGameCenter' 'product/data-app/MIUIYoupin' 'product/data-app/MIService' 'product/data-app/MIUIMiDrive' 'product/data-app/MIUIVipAccount' 'product/data-app/MIUIXiaoAiSpeechEngine' 'product/data-app/MIUIEmail' 'product/data-app/Health' 'product/app/UPTsmService' 'product/app/MIUISuperMarket' 'product/data-app/MiShop' 'product/data-app/MIUIMusicT' 'product/data-app/MIGalleryLockscreen-MIUI15' 'product/data-app/MIpay' 'product/priv-app/MIUIBrowser' 'product/priv-app/MiGameCenterSDKService' 'product/app/PaymentService' 'product/app/system' 'product/app/XiaoaiRecommendation' 'product/app/AiAsstVision' 'product/app/MIUIAiasstService' 'product/priv-app/MIUIYellowPage' 'product/priv-app/MIUIAICR' 'product/app/VoiceAssistAndroidT' 'product/priv-app/MIUIQuickSearchBox' 'product/app/OtaProvision' 'product/app/MiteeSoterService' 'product/data-app/ThirdAppAssistant' 'product/app/MIS' 'product/app/HybridPlatform' 'product/priv-app/VoiceTrigger' 'system_ext/app/digitalkey' 'product/app/MIUIgreenguard' 'product/app/MiBugReport' 'product/app/CatchLog' 'product/app/MSA' 'system/system/priv-app/Stk1' 'product/app/MiteeSoterService' 'system_ext/app/MiuiDaemon' 'product/app/MIUIReporter' 'product/app/Updater' 'product/app/WMService' 'product/app/SogouInput' 'system/system/app/Stk' 'product/app/CarWith' 'product/priv-app/Backup' 'product/priv-app/MIUICloudBackup' 'product/priv-app/MIUIContentExtension' 'product/priv-app/GooglePlayServicesUpdater' 'product/app/MIUISecurityInputMethod')
# for pkg in "${bloatware[@]}"; do
#     if [[ -d "$GITHUB_WORKSPACE"/images/$pkg ]]; then
#         echo "Removing $pkg"
#         rm -rf "$GITHUB_WORKSPACE"/images/$pkg
#     fi
# done

# echo "Copying files to build folder"
#  split --bytes=15M --numeric-suffixes=1 --suffix-length=1 Phonesky.apk Phonesky.apk.
# cat "$GITHUB_WORKSPACE"/lib/files/product/app/Gboard/Gboard.apk.* >$GITHUB_WORKSPACE/lib/files/product/app/Gboard/Gboard.apk
# rm "$GITHUB_WORKSPACE"/lib/files/product/app/Gboard/Gboard.apk.*
# cat "$GITHUB_WORKSPACE"/lib/files/product/priv-app/Phonesky/Phonesky.apk.* >$GITHUB_WORKSPACE/lib/files/product/priv-app/Phonesky/Phonesky.apk
# rm "$GITHUB_WORKSPACE"/lib/files/product/priv-app/Phonesky/Phonesky.apk.*
# sudo cp -rf "$GITHUB_WORKSPACE/lib/files/." "$GITHUB_WORKSPACE/images/"


# #------------------------------------------------------------------------------------------------------------------------------------------------------
# # Repack các image đã giải nén
# # Duyệt qua từng mục trong danh sách extract_list
# for partition in "${extract_list[@]}"; do
#     echo "Repacking... $partition"

#     # Đặt tên các tệp đầu vào và đầu ra
#     input_folder_image="$GITHUB_WORKSPACE/images/$partition"
#     output_image="$GITHUB_WORKSPACE/images/$partition.img"

#     fs_config_file="$GITHUB_WORKSPACE/images/config/$partition"_fs_config
#     file_contexts_file="$GITHUB_WORKSPACE/images/config/$partition"_file_contexts

#     # Chạy các tập lệnh Python để áp dụng cấu hình và bối cảnh
#     python3 "$GITHUB_WORKSPACE/lib/fspatch.py" "$input_folder_image" "$fs_config_file"
#     python3 "$GITHUB_WORKSPACE/lib/contextpatch.py" "$input_folder_image" "$file_contexts_file"

#     # Thực hiện công cụ make.erofs để đóng gói
#     $GITHUB_WORKSPACE/lib/mkfs.erofs --quiet -zlz4hc -T 1230768000 \
#         --mount-point="/$partition" \
#         --fs-config-file="$fs_config_file" \
#         --file-contexts="$file_contexts_file" \
#         "$output_image" "$input_folder_image"
#     sudo rm -rf "$input_folder_image"
# done

# # Danh sách các phân vùng
# super_list=('mi_ext' 'odm' 'product' 'system' 'system_dlkm' 'system_ext' 'vendor' 'vendor_dlkm' 'odm_dlkm')

# # Đặt các biến chung
# super_size=9126805504

# # Tạo các tham số cho lệnh $lpmake
# partition_params=""

# p_size=0
# for item in "${super_list[@]}"; do
#     item_size=$(du -sb "$GITHUB_WORKSPACE"/images/${item}.img | tr -cd 0-9)
#     echo "Partition $item size: $item_size"
#     p_size=$((p_size + item_size))
#     # partition_params+="--partition ${item}_a:readonly:$item_size:qti_dynamic_partitions_a --partition ${item}_b:readonly:0:qti_dynamic_partitions_b "
#     partition_params+="--partition ${item}_a:readonly:$item_size:qti_dynamic_partitions_a --partition ${item}_b:none:0:qti_dynamic_partitions_b "
#     partition_params+="--image ${item}_a=$GITHUB_WORKSPACE/images/${item}.img "
# done

# # Nếu tất cả size lớn hơn super size thì dừng
# echo "Partition total size: $p_size"
# echo "Super size: $super_size"
# if [ $p_size -gt $super_size ]; then
#     echo "Partition size is greater than super size"
#     exit 1
# fi

# # Thực thi lệnh $lpmake với các tham số
# "$GITHUB_WORKSPACE"/lib/lpmake \
#     --metadata-size 65536 \
#     --super-name super \
#     --block-size 4096 \
#     $partition_params \
#     --device super:$super_size \
#     --metadata-slots 3 \
#     --group qti_dynamic_partitions_a:$super_size \
#     --group qti_dynamic_partitions_b:$super_size \
#     --virtual-ab \
#     -F \
#     --output "$GITHUB_WORKSPACE/images/super.img"

# if [ -f "$GITHUB_WORKSPACE/images/super.img" ]; then
#     echo "Pack super.img done."
# else
#     error "Pack super.img failed."
#     exit 1
# fi

# for item in "${super_list[@]}"; do
#     rm -rf "$GITHUB_WORKSPACE/images/${item}.img"
# done

# # Nén super.img
# sudo find "$GITHUB_WORKSPACE"/images/*.img -exec touch -t 200901010000.00 {} \;
# $GITHUB_WORKSPACE"/lib/zstd" -12 -f "$GITHUB_WORKSPACE"/images/super.img -o "$GITHUB_WORKSPACE"/images/super.img.zst --rm

# # Đóng gói rom
# sudo cp -rf "$GITHUB_WORKSPACE/lib/flash_tool/." "$GITHUB_WORKSPACE/flash_tool/"
# sed -i "s/Model_code/${device}/g" "$GITHUB_WORKSPACE/flash_tool/FlashROM.bat"

# # Nén FlashROM.bat, thư mục bin và images thành 1 file
# "$GITHUB_WORKSPACE/lib/7zzs" a -tzip "$GITHUB_WORKSPACE"/miui.zip "$GITHUB_WORKSPACE"/flash_tool/* "$GITHUB_WORKSPACE"/images/* -y -mx2
# sudo rm -rf "$GITHUB_WORKSPACE"/images
# md5=$(md5sum "$GITHUB_WORKSPACE/miui.zip" | awk '{ print $1 }')
# rom_name="ReHyper_${device}_${os_version}_${md5:0:8}_${build_time}VN_${android_version}.0.zip"
# mv "$GITHUB_WORKSPACE/miui.zip" "$GITHUB_WORKSPACE/$rom_name"
# rom_path="$GITHUB_WORKSPACE/$rom_name"

# echo "rom_path=$rom_path" >>"$GITHUB_ENV"
# echo "rom_name=$rom_name" >>"$GITHUB_ENV"
# echo "os_version=$os_version" >>"$GITHUB_ENV"
# echo "device_name=$device" >>"$GITHUB_ENV"
# echo "rom_md5=$md5" >>"$GITHUB_ENV"