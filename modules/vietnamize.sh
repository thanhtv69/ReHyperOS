generate_public_xml() {
    local input_dir=$1
    local output_file=$2

    # Check if the input directory exists
    if [[ ! -d "$input_dir" ]]; then
        log_error "Input directory does not exist."
        return 1
    fi

    # Create the output directory if it doesn't exist
    local output_folder
    output_folder=$(dirname "$output_file")
    if [[ ! -d "$output_folder" ]]; then
        mkdir -p "$output_folder"
    fi

    # Start creating the public.xml file
    echo '<?xml version="1.0" encoding="utf-8"?>' > "$output_file"
    echo '<resources>' >> "$output_file"

    # Iterate through all files in the directory
    find "$input_dir" -type f | while read -r file_path; do
        file_name=$(basename "$file_path")
        basename="${file_name%.*}"

        # Determine the resource type based on the file name
        resource_type=""

        if [[ "$file_name" == *"strings.xml" ]]; then
            resource_type="string"
        elif [[ "$file_name" == *"arrays.xml" ]]; then
            resource_type="array"
        elif [[ "$file_name" == *"plurals.xml" ]]; then
            resource_type="plurals"
        elif [[ "$file_name" == *"public.xml" ]]; then
            continue
        elif [[ "$file_name" == *.html ]]; then
            resource_type="raw"
            echo "    <public type=\"$resource_type\" name=\"$basename\" />" >> "$output_file"
            continue
        else
            log_warn "Skipping unknown resource type: $file_name"
            continue
        fi

        # Extract resource names and add to public.xml
        grep -oP 'name="\K[^"]+' "$file_path" | while read -r name; do
            echo "    <public type=\"$resource_type\" name=\"$name\" />" >> "$output_file"
        done
    done

    # Finish the public.xml file
    echo '</resources>' >> "$output_file"
}

vietnamize() {
    blue "========================================="
    blue "START Add Vietnamese and Lunar Calendar"
    start_time=$(date +%s)
    local url="https://github.com/butinhi/MIUI-14-XML-Vietnamese/archive/refs/heads/master.zip"
    local vietnamese_dir="$OUT_DIR/vietnamese"
    local vietnamese_master="$vietnamese_dir/MIUI-14-XML-Vietnamese-master/Vietnamese/main"
    
    mkdir -p "$vietnamese_dir/packed"
    cd "$vietnamese_dir"
    
    # Tải file ZIP từ URL và lưu với tên đã chỉ định
    curl -k --location --remote-name --max-time 60 "$url" || { error "Failed to download $url" && exit 1; }
    7za x master.zip -aoa
    rm -f master.zip
    declare -A BUILD_APK_LIST=(
        ["AICallAssistant"]="com.xiaomi.aiasst.service"
        ["AuthManager"]="com.lbe.security.miui"
        ["Calendar"]="com.android.calendar"
        ["CalendarProvider"]="com.android.providers.calendar"
        ["Cit"]="com.miui.cit"
        ["CleanMaster"]="com.miui.cleanmaster"
        ["CloudBackup"]="com.miui.cloudbackup"
        ["CloudService"]="com.miui.cloudservice"
        ["Contacts"]="com.android.contacts"
        ["ContactsProvider"]="com.android.providers.contacts"
        ["DownloadProvider"]="com.android.providers.downloads"
        ["DownloadProviderUi"]="com.android.providers.downloads.ui"
        ["GalleryEditor"]="com.miui.mediaeditor"
        ["InCallUI"]="com.android.incallui"
        ["MiAI"]="com.miui.voiceassist"
        ["MiAITranslate"]="com.xiaomi.aiasst.vision"
        ["MiCloudSync"]="com.miui.micloudsync"
        ["MiGalleryLockscreen"]="com.mfashiongallery.emag"
        ["MiLinkService"]="com.milink.service"
        ["MiMover"]="com.miui.huanji"
        ["MiSettings"]="com.xiaomi.misettings"
        ["MiShare"]="com.miui.mishare.connectivity"
        ["MiuiAod"]="com.miui.aod"
        ["MiuiBluetooth"]="com.xiaomi.bluetooth"
        ["MiuiCamera"]="com.android.camera"
        ["MiuiContentCatcher"]="com.miui.contentcatcher"
        ["MiuiExtraPhoto"]="com.miui.extraphoto"
        ["MiuiFreeformService"]="com.miui.freeform"
        ["MiuiFrequentPhrase"]="com.miui.phrase"
        ["MiuiGallery"]="com.miui.gallery"
        ["MiuiHome"]="com.miui.home"
        ["MiuiPackageInstaller"]="com.miui.packageinstaller"
        ["MiuiSystemUI"]="com.android.systemui"
        ["MiuixEditor"]="com.miuix.editor"
        ["Mms"]="com.android.mms"
        ["NQNfcNci"]="com.android.nfc"
        ["PermissionController"]="com.android.permissioncontroller"
        ["PersonalAssistant"]="com.miui.personalassistant"
        ["PowerKeeper"]="com.miui.powerkeeper"
        ["Provision"]="com.android.provision"
        ["SecurityAdd"]="com.miui.securityadd"
        ["SecurityCenter"]="com.miui.securitycenter"
        ["Settings"]="com.android.settings"
        ["SmartCards"]="com.miui.tsmclient"
        ["Taplus"]="com.miui.contentextension"
        ["TeleService"]="com.android.phone"
        ["Telecom"]="com.android.server.telecom"
        ["TelephonyProvider"]="com.android.providers.telephony"
        ["ThemeManager"]="com.android.thememanager"
        ["Traceur"]="com.android.traceur"
        ["VpnDialogs"]="com.android.vpndialogs"
        ["Weather"]="com.miui.weather2"
        ["XiaomiAccount"]="com.xiaomi.account"
        ["XiaomiSimActivateService"]="com.xiaomi.simactivate.service"
        ["MiuiMacro"]="com.xiaomi.macro"
        ["framework-res"]="android"
    )
    
    strings_file=$vietnamese_master/*/res/values-vi/strings.xml
    green "Remove CopyRight"
    sed -i 's/๖ۣۜßεℓ/Community/g' $strings_file
    sed -i 's/MIUI.VN/Open Source/g' $strings_file
    
    green "Add Lunarian Calendar"
    sed -i \
    -e '/<string name="aod_lock_screen_date">/s/>.*<\/string>/>\EEE, dd\.MM\.YYYY 💕 e\/N YY<\/string>/' \
    -e '/<string name="aod_lock_screen_date_12">/s/>.*<\/string>/>\EEE, dd\.MM\.YYYY 💕 e\/N YY<\/string>/' \
    -e '/<string name="status_bar_clock_date_format">/s/>.*<\/string>/>\EE, dd\/MM 💕 e\/N<\/string>/' \
    -e '/<string name="status_bar_clock_date_format_12">/s/>.*<\/string>/>\EE, dd\/MM 💕 e\/N<\/string>/' \
    -e '/<string name="status_bar_clock_date_time_format">/s/>.*<\/string>/>\H:mm | EEEE, dd\.MM\.YYYY 💕 e\/N YY<\/string>/' \
    -e '/<string name="status_bar_clock_date_time_format_12">/s/>.*<\/string>/>\h:mm aa | EEEE, dd\.MM\.YYYY 💕 e\/N YY<\/string>/' \
    -e '/<string name="miui_magazine_c_clock_style2_date">/s/>.*<\/string>/>\EE, dd\/MM 💕 e\/N YY<\/string>/' \
    -e '/<string name="format_month_day_week">/s/>.*<\/string>/>\EEEE, dd\/MM 💕 e\/N<\/string>/' \
    $strings_file
    
    green "Edit Date Format"
    sed -i -E '/<string name="chinese_day_[0-9]">[1-9]<\/string>/s/([1-9])<\/string>/0\1<\/string>/g' $strings_file
    
    green "Edit Month Format"
    sed -i -E '/<string name="chinese_month_.*">[1-9]<\/string>/s/([1-9])<\/string>/0\1<\/string>/g' $strings_file
    
    local ALL_DATE=$(date +%Y.%m.%d)
    local SHORT_DATE=$(date +%y%m%d)
    
    for apk_name in "${!BUILD_APK_LIST[@]}"; do
        local package_name="${BUILD_APK_LIST[$apk_name]}"
        # green "START generate $apk_name with package name: $package_name"
        rm -rf "$vietnamese_dir/$apk_name"
        mkdir -p "$vietnamese_dir/$apk_name/res/values"
        mkdir -p "$vietnamese_dir/$apk_name/res/values-vi"
        touch "$vietnamese_dir/$apk_name/apktool.yml"
        touch "$vietnamese_dir/$apk_name/AndroidManifest.xml"
        touch "$vietnamese_dir/$apk_name/res/values-vi/strings.xml"
        echo -e '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n</resources>' > "$vietnamese_dir/$apk_name/res/values-vi/strings.xml"
        
        local manifest_content="<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\"?><manifest xmlns:android=\"http://schemas.android.com/apk/res/android\" android:compileSdkVersion=\"$sdk_version\" android:compileSdkVersionCodename=\"$version_release\" package=\"vn.overlay.$package_name\" platformBuildVersionCode=\"$sdk_version\" platformBuildVersionName=\"$version_release\">\n    <overlay android:isStatic=\"true\" android:priority=\"999\" android:targetPackage=\"$package_name\"/>\n</manifest>"
        local apktool_content="version: 2.9.3\napkFileName: $apk_name.apk\nisFrameworkApk: false\nusesFramework:\n  ids:\n  - 1\n  tag: null\nsdkInfo:\npackageInfo:\n  forcedPackageId: 127\n  renameManifestPackage: null\nversionInfo:\n  versionCode: $sdk_version\n  versionName: $version_release\nresourcesAreCompressed: false\nsharedLibrary: false\nsparseResources: false\ndoNotCompress:\n- resources.arsc"
        echo -e $manifest_content >"$vietnamese_dir/$apk_name/AndroidManifest.xml"
        echo -e $apktool_content >"$vietnamese_dir/$apk_name/apktool.yml"
        
        if [ ! -d "$vietnamese_master/$apk_name.apk/res/values-vi" ]; then
            yellow "WARNING: $vietnamese_master/$apk_name.apk/res/values-vi doesn't exist"
            continue
        fi

        cp -rf "$vietnamese_master/$apk_name.apk/res/." "$vietnamese_dir/$apk_name/res/"
        
        generate_public_xml "$vietnamese_dir/$apk_name/res" "$vietnamese_dir/$apk_name/res/values/public.xml"
        
        
        $APK_TOOL b -api $sdk_version -c -f $vietnamese_dir/$apk_name -o $vietnamese_dir/${apk_name}_tmp.apk # >/dev/null 2>&1 || error "ERROR: Build overlay $apk_name.apk failed"
        zipalign -f 4 $vietnamese_dir/${apk_name}_tmp.apk $vietnamese_dir/packed/${apk_name}.apk >/dev/null 2>&1 || error "ERROR: Zipalign overlay $apk_name.apk failed"
        rm -rf $vietnamese_dir/${apk_name}_tmp.apk
        $APKSIGNER_COMMAND sign --key $BIN_DIR/apktool/Key/testkey.pk8 --cert $BIN_DIR/apktool/Key/testkey.x509.pem $vietnamese_dir/packed/$apk_name.apk # >/dev/null 2>&1 || error "ERROR: Sign overlay $apk_name.apk failed"
        if [ -f "$vietnamese_dir/packed/$apk_name.apk" ]; then
            green "Done [$apk_name]"
            rm -rf "$vietnamese_dir/$apk_name"
        else
            error "ERROR: Create overlay $apk_name.apk failed"
            exit 1
        fi
    done
    # cp -rf "$vietnamese_dir/packed/." "$EXTRACTED_DIR/product/overlay/"
    find "$vietnamese_dir/packed/" -name "*.apk" -exec cp -rf {} "$EXTRACTED_DIR/product/overlay/" \;
    
    rm -rf "$vietnamese_dir"
    cd "$PROJECT_DIR"
    
    end_time=$(date +%s)
    blue "END Add Vietnamese and Lunar calendar in $(($end_time - $start_time))s"
}
