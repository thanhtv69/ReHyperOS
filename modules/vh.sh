generate_public_xml() {
    local input_dir=$1
    local output_file=$2

    # Kiểm tra xem thư mục đầu vào có tồn tại không
    if [ ! -d "$input_dir" ]; then
        echo "Thư mục đầu vào không tồn tại."
        return 1
    fi

    # Bắt đầu tạo file public.xml
    echo '<?xml version="1.0" encoding="utf-8"?>' >"$output_file"
    echo '<resources>' >>"$output_file"

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
            continue # Nếu không khớp với bất kỳ loại nào, bỏ qua file này
        fi

        # Trích xuất tên tài nguyên và thêm vào public.xml
        grep -oP '(?<=name=")[^"]+' "$file" | while read -r name; do
            echo "    <public type=\"$type\" name=\"$name\" />" >>"$output_file"
        done
    done

    # Kết thúc file public.xml
    echo '</resources>' >>"$output_file"

    # echo "Tạo $output_file hoàn thành!"
}

viet_hoa() {
    blue "========================================="
    blue "START Add Vietnamese and Lunar Calendar"
    start_time=$(date +%s)
    local url="https://github.com/butinhi/MIUI-14-XML-Vietnamese/archive/refs/heads/master.zip"
    local vietnamese_dir="$OUT_DIR/vietnamese"
    local vietnamese_master="$vietnamese_dir/MIUI-14-XML-Vietnamese-master/Vietnamese/main"

    mkdir -p "$vietnamese_dir/packed"
    cd "$vietnamese_dir"

    # Tải file ZIP từ URL và lưu với tên đã chỉ định
    curl --location --remote-name "$url" || cp -f $FILES_DIR/MIUI-14-XML-Vietnamese-master.zip $vietnamese_dir/master.zip
    7za x master.zip -aoa
    rm -f master.zip
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
        ["MiuiFrequentPhrase"]="com.miui.phrase"
        ["MiuixEditor"]="com.miuix.editor"
        ["DownloadProvider"]="com.android.providers.downloads"
        ["DownloadProviderUi"]="com.android.providers.downloads.ui"
        ["PermissionController"]="com.android.permissioncontroller"
        ["VpnDialogs"]="com.android.vpndialogs"
        ["MiuiExtraPhoto"]="com.miui.extraphoto"
        ["Provision"]="com.android.provision"
        ["Traceur"]="com.android.traceur"
        ["Bluetooth"]="com.android.bluetooth"
    )

    strings_file=$vietnamese_master/*/res/values-vi/strings.xml
    green "Remove CopyRight"
    sed -i 's/๖ۣۜßεℓ/Community/g' $strings_file
    sed -i 's/MIUI.VN/Open Source/g' $strings_file

    green "Add Lunarian Calendar"
    sed -i \
        -e '/<string name="aod_lock_screen_date">/s/>.*<\/string>/>\EEE, dd\/MM || e\/N<\/string>/' \
        -e '/<string name="aod_lock_screen_date_12">/s/>.*<\/string>/>\EEE, dd\/MM || e\/N<\/string>/' \
        -e '/<string name="status_bar_clock_date_format">/s/>.*<\/string>/>\EE, dd\/MM || e\/N<\/string>/' \
        -e '/<string name="status_bar_clock_date_format_12">/s/>.*<\/string>/>\EE, dd\/MM || e\/N<\/string>/' \
        -e '/<string name="status_bar_clock_date_time_format">/s/>.*<\/string>/>\H:mm • EEEE, dd\/MM || e\/N YY YYYY<\/string>/' \
        -e '/<string name="status_bar_clock_date_time_format_12">/s/>.*<\/string>/>\h:mm aa • EEEE, dd\/MM || e\/N YY YYYY<\/string>/' \
        -e '/<string name="miui_magazine_c_clock_style2_date">/s/>.*<\/string>/>\EE, dd\/MM || e\/N YY<\/string>/' \
        -e '/<string name="format_month_day_week">/s/>.*<\/string>/>\EEEE, dd\/MM || e\/N<\/string>/' \
        $strings_file

    green "Edit Date Format"
    sed -i -E '/<string name="chinese_day_[0-9]">[1-9]<\/string>/s/([1-9])<\/string>/0\1<\/string>/g' $strings_file

    green "Edit Month Format"
    sed -i -E '/<string name="chinese_month_.*">[1-9]<\/string>/s/([1-9])<\/string>/0\1<\/string>/g' $strings_file
    local ALL_DATE=$(date +%Y.%m.%d)
    local SHORT_DATE=$(date +%y%m%d)

    for apk_name in "${!BUILD_APK_LIST[@]}"; do
        local package_name="${BUILD_APK_LIST[$apk_name]}"
        green "START generate $apk_name with package name: $package_name"
        rm -rf "$vietnamese_dir/$apk_name"
        mkdir -p "$vietnamese_dir/$apk_name/res/values"
        mkdir -p "$vietnamese_dir/$apk_name/res/values-vi"
        touch "$vietnamese_dir/$apk_name/apktool.yml"

        local manifest_content="<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\"?>\n<manifest\n	xmlns:android=\"http://schemas.android.com/apk/res/android\"\n    android:compileSdkVersion=\"$sdk_version\"\n    android:compileSdkVersionCodename=\"$version_release\"\n    package=\"overlay.$package_name\" \n    platformBuildVersionCode=\"$sdk_version\" \n    platformBuildVersionName=\"$version_release\">\n    <application\n    android:extractNativeLibs=\"false\" \n    android:hasCode=\"false\"/>\n    <overlay \n    android:isStatic=\"true\" \n    android:priority=\"0\" \n    android:targetPackage=\"$package_name\"/>\n</manifest>"
        local apktool_content="version: 2.9.3\napkFileName: $apk_name.apk\nisFrameworkApk: false\nusesFramework:\n  ids:\n  - 1\n  tag: null\nsdkInfo:\n  minSdkVersion: 23\n  targetSdkVersion: $sdk_version\npackageInfo:\n  forcedPackageId: 127\n  renameManifestPackage: null\nversionInfo:\n  versionCode: 1\n  versionName: 1.0\nresourcesAreCompressed: false\nsharedLibrary: false\nsparseResources: false\ndoNotCompress:\n- resources.arsc"
        echo -e $manifest_content >"$vietnamese_dir/$apk_name/AndroidManifest.xml"
        echo -e $apktool_content >"$vietnamese_dir/$apk_name/apktool.yml"

        find "$vietnamese_master/$apk_name.apk/res/values-vi" -name "*.xml" -exec cp {} "$vietnamese_dir/$apk_name/res/values-vi" \;

        generate_public_xml "$vietnamese_dir/$apk_name/res/values-vi" "$vietnamese_dir/$apk_name/res/values/public.xml"

        # $APKTOOL_COMMAND b -c -f $vietnamese_dir/$apk_name -o $vietnamese_dir/${apk_name}_tmp.apk
        # zipalign -f 4 $vietnamese_dir/${apk_name}_tmp.apk $vietnamese_dir/packed/${apk_name}.apk
        # rm -rf $vietnamese_dir/${apk_name}_tmp.apk

        $APKTOOL_COMMAND b -c -f $vietnamese_dir/$apk_name -o $vietnamese_dir/${apk_name}_tmp.apk >/dev/null 2>&1 || error "ERROR: Build overlay $apk_name.apk failed"
        zipalign -f 4 $vietnamese_dir/${apk_name}_tmp.apk $vietnamese_dir/packed/${apk_name}.apk >/dev/null 2>&1 || error "ERROR: Zipalign overlay $apk_name.apk failed"
        rm -rf $vietnamese_dir/${apk_name}_tmp.apk
        $APKSIGNER_COMMAND sign --key $BIN_DIR/apktool/Key/private_key.pk8 --cert $BIN_DIR/apktool/Key/my_certificate.pem $vietnamese_dir/packed/$apk_name.apk >/dev/null 2>&1 || error "ERROR: Sign overlay $apk_name.apk failed"
        # $APKSIGNER_COMMAND sign --ks $BIN_DIR/apktool/Key/release.jks $vietnamese_dir/packed/$apk_name.apk

        if [ -f "$vietnamese_dir/packed/$apk_name.apk" ]; then
            rm -rf "$vietnamese_dir/$apk_name"
        else
            error "ERROR: Create overlay $apk_name.apk failed"
            exit 1
        fi

        green "END generate $apk_name with package name: $package_name"
        # break
    done
    # cp -rf "$vietnamese_dir/packed/." "$EXTRACTED_DIR/product/overlay/"
    find "$vietnamese_dir/packed/" -name "*.apk" -exec cp -rf {} "$EXTRACTED_DIR/product/overlay/" \;

    rm -rf "$vietnamese_dir"
    cd "$PROJECT_DIR"

    end_time=$(date +%s)
    blue "END Add Vietnamese and Lunar calendar in $(($end_time - $start_time))s"
}
