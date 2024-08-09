#!/bin/bash
URL="${1:-"https://bn.d.miui.com/OS1.0.18.0.UMLCNXM/miui_COROT_OS1.0.18.0.UMLCNXM_a086066b44_14.0.zip"}"
GITHUB_ENV="$2"
GITHUB_WORKSPACE="$3"

# Thiết lập quyền truy cập cho tất cả các tệp trong thư mục hiện tại
# sudo chmod 777 -R ./*
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
APKSIGNER_COMMAND="java -jar $BIN_DIR/apktool/apksigner.jar"
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
sdk_version="34"

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

    missing_partitions=""
    for p in "${p_payload[@]}"; do
        if [ ! -e "$IMAGES_DIR/$p.img" ]; then
            if [ -z "$missing_partitions" ]; then
                missing_partitions="$p"
            else
                missing_partitions="$missing_partitions,$p"
            fi
        fi
    done

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
        rm -rf "$EXTRACTED_DIR/$partition" >/dev/null 2>&1
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
        echo "Đóng gói thành công super.img"
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

    find "$READY_DIR"/images/*.img -exec touch -t 200901010000.00 {} \;
    zstd -19 -f "$super_img" -o "$super_zst" --rm
    echo "Zip rom..."
    cd $READY_DIR
    7za -tzip a miui.zip bin/* images/* FlashROM.bat -y -mx9
    cd $PROJECT_DIR
    md5=$(md5sum "$READY_DIR/miui.zip" | awk '{ print $1 }')
    rom_name="ReHyper_${device}_${os_version}_${md5:0:8}_${build_time}VN_${android_version}.0.zip"
    mv "$READY_DIR/miui.zip" "$READY_DIR/$rom_name"
}

remove_bloatware() {
    echo "Remove bloatware packages"
    tr -d '\r' <"$PROJECT_DIR/bloatware" | tr -s '\n' | while IFS= read -r pkg; do
        pkg=$(echo "$pkg" | xargs) # Loại bỏ khoảng trắng thừa
        if [[ -n "$pkg" && "$pkg" != \#* ]]; then
            path="$EXTRACTED_DIR/$pkg"
            if [[ -d "$path" ]]; then
                echo "Removing directory $path"
                rm -rf "$path"
            elif [[ -f "$path" ]]; then
                echo "Removing file $path"
                rm -f "$path"
            else
                echo "Path $path does not exist."
            fi
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

google_photo_cts() {
    echo "Modding google photos"

    # TODO switch snap and mtk
    7za x "$FILES_DIR/gg_cts/mtk.zip" "android/app" -o"$OUT_DIR/tmp/framework/classes" -aoa >/dev/null 2>&1
    7za x "$FILES_DIR/gg_cts/mtk.zip" "android/security" -o"$OUT_DIR/tmp/framework/classes3" -aoa >/dev/null 2>&1
    7za x "$FILES_DIR/gg_cts/mtk.zip" "com" -o"$OUT_DIR/tmp/framework/classes5" -aoa >/dev/null 2>&1

    local build_prop_org="$EXTRACTED_DIR/system/system/build.prop"
    local build_prop_mod="$FILES_DIR/gg_cts/build.prop"
    while IFS= read -r line; do
        if ! grep -Fxq "$line" "$build_prop_org"; then
            sed -i "/# end of file/i $line" "$build_prop_org"
        fi
    done <$build_prop_mod

    local white_key_org="$EXTRACTED_DIR/system_ext/etc/cust_prop_white_keys_list"
    local white_key_mod="$FILES_DIR/gg_cts/cust_prop_white_keys_list"
    while IFS= read -r line; do
        if ! grep -Fxq "$line" "$white_key_org"; then
            printf "\n%s" "$line" >>"$white_key_org"
        fi
    done <$white_key_mod

    mkdir -p "$EXTRACTED_DIR/product/app/SoraOS"
    cp -f "$FILES_DIR/gg_cts/SoraOS.apk" "$EXTRACTED_DIR/product/app/SoraOS/SoraOS.apk"

    sed -i 's/ro.product.first_api_level=33/ro.product.first_api_level=32/g' "$EXTRACTED_DIR/vendor/build.prop"
    echo "Done modding google photos"
}

modify() {
    sed -i 's/persist.miui.extm.enable=1/persist.miui.extm.enable=0/g' "$EXTRACTED_DIR/system_ext/etc/build.prop"
    sed -i 's/persist.miui.extm.enable=1/persist.miui.extm.enable=0/g' "$EXTRACTED_DIR/product/etc/build.prop"

    sed -i 's/<bool name=\"support_hfr_video_pause\">false<\/bool>/<bool name=\"support_hfr_video_pause\">true<\/bool>/g' $EXTRACTED_DIR/product/etc/device_features/*.xml
    sed -i 's/<bool name=\"support_dolby\">false<\/bool>/<bool name=\"support_dolby\">true<\/bool>/g' $EXTRACTED_DIR/product/etc/device_features/*.xml
    sed -i 's/<bool name=\"support_video_hfr_mode\">false<\/bool>/<bool name=\"support_video_hfr_mode\">true<\/bool>/g' $EXTRACTED_DIR/product/etc/device_features/*.xml
    sed -i 's/<bool name=\"support_hifi\">false<\/bool>/<bool name=\"support_hifi\">true<\/bool>/g' $EXTRACTED_DIR/product/etc/device_features/*.xml
}

framework_patcher() {
    cd $OUT_DIR
    local repo_dir="FrameworkPatcher"
    local url="https://github.com/Jefino9488/FrameworkPatcher/archive/refs/heads/master.zip"

    curl --progress-bar --location --remote-name "$url" >/dev/null 2>&1
    7za x master.zip -aoa >/dev/null 2>&1

    mv -rf "$OUT_DIR/tmp/framework/classes" "$repo_dir/classes"
    mv -rf "$OUT_DIR/tmp/framework/classes2" "$repo_dir/classes2"
    mv -rf "$OUT_DIR/tmp/framework/classes3" "$repo_dir/classes3"
    mv -rf "$OUT_DIR/tmp/framework/classes4" "$repo_dir/classes4"
    mv -rf "$OUT_DIR/tmp/framework/classes5" "$repo_dir/classes5"
    mv -rf "$OUT_DIR/tmp/services/classes" "$repo_dir/services_classes"
    mv -rf "$OUT_DIR/tmp/services/classes2" "$repo_dir/services_classes2"
    mv -rf "$OUT_DIR/tmp/services/classes3" "$repo_dir/services_classes3"
    mv -rf "$OUT_DIR/tmp/miui-framework/classes" "$repo_dir/miui_framework_classes"
    mv -rf "$OUT_DIR/tmp/miui-services/classes" "$repo_dir/miui_services_classes"

    python3 "framework_patch.py"
    python3 "miui-service_Patch.py"
    python3 "miui-framework_patch.py"
    python3 "miui-service_Patch.py"

    cp -rf "$repo_dir/magisk_module/system" $EXTRACTED_DIR

    mv -rf "$repo_dir/classes" "$OUT_DIR/tmp/framework/classes"
    mv -rf "$repo_dir/classes2" "$OUT_DIR/tmp/framework/classes2"
    mv -rf "$repo_dir/classes3" "$OUT_DIR/tmp/framework/classes3"
    mv -rf "$repo_dir/classes4" "$OUT_DIR/tmp/framework/classes4"
    mv -rf "$repo_dir/classes5" "$OUT_DIR/tmp/framework/classes5"
    mv -rf "$repo_dir/services_classes" "$OUT_DIR/tmp/services/classes"
    mv -rf "$repo_dir/services_classes2" "$OUT_DIR/tmp/services/classes2"
    mv -rf "$repo_dir/services_classes3" "$OUT_DIR/tmp/services/classes3"
    mv -rf "$repo_dir/miui_framework_classes" "$OUT_DIR/tmp/miui-framework/classes"
    mv -rf "$repo_dir/miui_services_classes" "$OUT_DIR/tmp/miui-services/classes"
    cd $PROJECT_DIR
}

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

generate_public_xml() {
    local input_dir=$1
    local output_file=$2

    # Kiểm tra xem thư mục đầu vào có tồn tại không
    if [ ! -d "$input_dir" ]; then
        echo "Thư mục đầu vào không tồn tại."
        return 1
    fi

    # Bắt đầu tạo file public.xml
    echo '<?xml version="1.0" encoding="utf-8"?>' > "$output_file"
    echo '<resources>' >> "$output_file"

    # Duyệt qua tất cả các file XML trong thư mục
    for file in "$input_dir"/*.xml; do
        # Lấy tên file mà không có phần mở rộng
        local basename=$(basename "$file" .xml)
        
        # Xác định loại tài nguyên dựa trên tên file
        local type=""
        if [[ $basename == *"strings"* ]]; then
            type="string"
        elif [[ $basename == *"arrays"* ]]; then
            type="array"
        elif [[ $basename == *"plurals"* ]]; then
            type="plurals"
        else
            continue  # Nếu không khớp với bất kỳ loại nào, bỏ qua file này
        fi
        
        # Trích xuất tên tài nguyên và thêm vào public.xml
        grep -oP '(?<=name=")[^"]+' "$file" | while read -r name; do
            echo "    <public type=\"$type\" name=\"$name\" />" >> "$output_file"
        done
    done

    # Kết thúc file public.xml
    echo '</resources>' >> "$output_file"

    echo "Tạo $output_file hoàn thành!"
}

# Ví dụ cách sử dụng hàm:
# generate_public_xml "/path/to/xml/files" "public.xml"


viet_hoa() {
    local url="https://github.com/butinhi/MIUI-14-XML-Vietnamese/archive/refs/heads/master.zip"
    local vietnamese_dir="$OUT_DIR/vietnamese"
    local vietnamese_master="$vietnamese_dir/MIUI-14-XML-Vietnamese-master/Vietnamese/main"

    mkdir -p "$vietnamese_dir/packed"
    cd "$vietnamese_dir"

    Tải file ZIP từ URL và lưu với tên đã chỉ định
    curl --progress-bar --location --remote-name "$url" >/dev/null 2>&1
    7za x master.zip -aoa >/dev/null 2>&1

    declare -A BUILD_APK_LIST=(
        ["AuthManager"]="com.lbe.security.miui"
        ["Calendar"]="com.android.calendar"
        ["Cit"]="com.miui.cit"
        ["CleanMaster"]="com.miui.cleanmaster"
        ["CloudBackup"]="com.miui.cloudbackup"
        ["CloudService"]="com.miui.cloudservice"
        ["Contacts"]="com.android.contacts"
        ["InCallUI"]="com.android.incallui"
        ["MiCloudSync"]="com.miui.micloudsync"
        ["MiGalleryLockscreen"]="com.mfashiongallery.emag"
        ["MiMover"]="com.miui.huanji"
        ["MiSettings"]="com.xiaomi.misettings"
        ["MiShare"]="com.miui.mishare.connectivity"
        ["MiuiContentCatcher"]="com.miui.contentcatcher"
        ["MiuiFreeformService"]="com.miui.freeform"
        ["MiuiGallery"]="com.miui.gallery"
        ["MiuiHome"]="com.miui.home"
        ["MiuiPackageInstaller"]="com.miui.packageinstaller"
        ["MiuiSystemUI"]="com.android.systemui"
        ["Mms"]="com.android.mms"
        ["PersonalAssistant"]="com.miui.personalassistant"
        ["PowerKeeper"]="com.miui.powerkeeper"
        ["SecurityAdd"]="com.miui.securityadd"
        ["SecurityCenter"]="com.miui.securitycenter"
        ["Settings"]="com.android.settings"
        ["TeleService"]="com.android.phone"
        ["ThemeManager"]="com.android.thememanager"
        ["Weather"]="com.miui.weather2"
        ["XiaomiAccount"]="com.xiaomi.account"
        ["XiaomiSimActivateService"]="com.xiaomi.simactivate.service"
        ["com.xiaomi.macro"]="com.xiaomi.macro"
        ["MiLinkService"]="com.milink.service"
        ["framework-res"]="android"
        ["NQNfcNci"]="com.android.nfc"
        ["MiuiBluetooth"]="com.xiaomi.bluetooth"
        ["AICallAssistant"]="com.xiaomi.aiasst.service"
        ["GalleryEditor"]="com.miui.mediaeditor"
        ["MiAI"]="com.miui.voiceassist"
        ["MiAITranslate"]="com.xiaomi.aiasst.vision"
        ["SmartCards"]="com.miui.tsmclient"
        ["Taplus"]="com.miui.contentextension"
        ["ContactsProvider"]="com.android.providers.contacts"
        ["TelephonyProvider"]="com.android.providers.telephony"
        ["CalendarProvider"]="com.android.providers.calendar"
        ["Telecom"]="com.android.server.telecom"
        ["MiuiAod"]="com.miui.aod"
        ["MiuiCamera"]="com.android.camera"
        ["MiuixEditor"]="com.miui.phrase"
        ["DownloadProvider"]="com.android.providers.downloads"
        ["DownloadProviderUi"]="com.android.providers.downloads.ui"
        ["PermissionController"]="com.android.permissioncontroller"
        ["VpnDialogs"]="com.android.vpndialogs"
        ["MiuiExtraPhoto"]="com.miui.extraphoto"
        ["Provision"]="com.android.provision"
        ["Traceur"]="com.android.traceur"
    )

    ALL_DATE=$(date +%Y.%m.%d)
    SHORT_DATE=$(date +%y%m%d)

    for apk_name in "${!BUILD_APK_LIST[@]}"; do
        package_name="${BUILD_APK_LIST[$apk_name]}"
        echo "Tên APK: $apk_name, Tên package: $package_name"
        rm -rf "$vietnamese_dir/$apk_name"
        mkdir -p "$vietnamese_dir/$apk_name/res/values"
        mkdir -p "$vietnamese_dir/$apk_name/res/values-vi"
        touch "$vietnamese_dir/$apk_name/apktool.yml"

        touch "$vietnamese_dir/$apk_name/res/values-vi/strings.xml"
        echo -e '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n</resources>' > $vietnamese_dir/$apk_name/res/values-vi/strings.xml

        AndroidManifest="$vietnamese_dir/$apk_name/AndroidManifest.xml"
        ApktoolJson="$vietnamese_dir/$apk_name/apktool.yml"
        Code1="<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\"?>\n<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\"\n    android:compileSdkVersion=\"23\"\n    android:compileSdkVersionCodename=\"6.0-$SHORT_DATE\"\n    package=\"overlay.com.miui.mediaeditor\"\n    platformBuildVersionCode=\"$SHORT_DATE\"\n    platformBuildVersionName=\"$ALL_DATE\">\n\n    <overlay\n        android:isStatic=\"true\"\n        android:priority=\"1\"\n        android:targetPackage=\"$package_name\" />\n</manifest>"
        Code2="version: v2.9.0-17-44416481-SNAPSHOT\napkFileName: $apk_name.apk\nisFrameworkApk: false\nusesFramework:\n  ids:\n  - 1\n  tag: null\nsdkInfo:\npackageInfo:\n  forcedPackageId: 127\n  renameManifestPackage: null\nversionInfo:\n  versionCode: $SHORT_DATE\n  versionName: $ALL_DATE\nresourcesAreCompressed: false\nsharedLibrary: false\nsparseResources: false\ndoNotCompress:\n- resources.arsc"
        echo -e $Code1 >"$AndroidManifest"
        echo -e $Code2 >"$ApktoolJson"

        cp -rf "$vietnamese_master/$apk_name.apk/res/." "$vietnamese_dir/$apk_name/res/"
        generate_public_xml "$vietnamese_dir/$apk_name/res/values-vi" "$vietnamese_dir/$apk_name/res/values/public.xml"

        $APKTOOL_COMMAND b -c -f $vietnamese_dir/$apk_name -o tmp/${apk_name}_tmp.apk
        zipalign -f 4 tmp/${apk_name}_tmp.apk packed/${apk_name}.apk
        $APKSIGNER_COMMAND sign --key $BIN_DIR/apktool/key/testkey.pk8 --cert $BIN_DIR/apktool/key/testkey.x509.pem packed/$apk_name.apk
        # break
    done
    cp -rf "$vietnamese_dir/packed/." "$EXTRACTED_DIR/product/overlay/"

    # rm -rf "$vietnamese_dir"
    cd "$PROJECT_DIR"
}

#-----------------------------------------------------------------------------------------------------------------------------------
main() {
    download_and_extract
    read_info
    disable_avb_and_dm_verity
    remove_bloatware
    # add_vn
    viet_hoa
    #==============================================
    framework="$EXTRACTED_DIR"/system/system/framework/framework.jar
    services="$EXTRACTED_DIR"/system/system/framework/services.jar
    miui_framework="$EXTRACTED_DIR"/system_ext/framework/miui-framework.jar
    miui_services="$EXTRACTED_DIR"/system_ext/framework/miui-services.jar
    decompile_smali "$framework"
    google_photo_cts
    recompile_smali "$framework"
    modify
    #==============================================
    # build
    repack_img_and_super
    genrate_script
    # zip_rom
    # set_info_release
}

main
# framework_patcher
# viet_hoa


# python3 "${PROJECT_DIR}/fw_patcher.py"
# echo "rom_path=$rom_path" >>"$GITHUB_ENV"
# echo "rom_name=$rom_name" >>"$GITHUB_ENV"
# echo "os_version=$os_version" >>"$GITHUB_ENV"
# echo "device_name=$device" >>"$GITHUB_ENV"
# echo "rom_md5=$md5" >>"$GITHUB_ENV"
