generate_public_xml() {
    local input_dir=$1
    local output_file=$2

    # Check if the input directory exists
    if [ ! -d "$input_dir" ]; then
        echo "Input directory does not exist."
        return 1
    fi

    # Initialize counters for IDs
    local array_id_counter=0
    local plurals_id_counter=0
    local string_id_counter=0

    generate_id() {
        local type=$1
        local array_counter=$2
        local plurals_counter=$3
        local string_counter=$4
        local id=""

        case $type in
        "array")
            id=$(printf "0x7f02%04x" $array_counter)
            ;;
        "plurals")
            id=$(printf "0x7f03%04x" $plurals_counter)
            ;;
        "string")
            id=$(printf "0x7f04%04x" $string_counter)
            ;;
        *)
            echo "Unknown type: $type"
            return 1
            ;;
        esac

        echo "$id"
    }

    # Start creating the public.xml file
    echo '<?xml version="1.0" encoding="utf-8"?>' >"$output_file"
    echo '<resources>' >>"$output_file"

    # Iterate through all XML files in the directory
    for file in "$input_dir"/*.xml; do
        # Get the base name of the file without the extension
        local basename=$(basename "$file" .xml)

        # Determine the resource type based on the file name
        local type=""
        if [[ $basename == *"strings"* ]]; then
            type="string"
        elif [[ $basename == *"arrays"* ]]; then
            type="array"
        elif [[ $basename == *"plurals"* ]]; then
            type="plurals"
        else
            continue # Skip this file if it doesn't match any known type
        fi

        # Extract resource names and add to public.xml
        grep -oP '(?<=name=")[^"]+' "$file" | while read -r name; do
            local id
            id=$(generate_id "$type" $array_id_counter $plurals_id_counter $string_id_counter) # Generate a new unique ID

            # Update the counters based on the type
            case $type in
            "array")
                array_id_counter=$((array_id_counter + 1))
                ;;
            "plurals")
                plurals_id_counter=$((plurals_id_counter + 1))
                ;;
            "string")
                string_id_counter=$((string_id_counter + 1))
                ;;
            esac

            # echo "Generated ID: $id" # Debug output
            echo "    <public type=\"$type\" name=\"$name\" id=\"$id\" />" >>"$output_file"
        done
    done

    # Finish the public.xml file
    echo '</resources>' >>"$output_file"

    echo "Creation of $output_file completed!"
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
    curl -k --location --remote-name --max-time 20 "$url" || cp -f $FILES_DIR/MIUI-14-XML-Vietnamese-master.zip $vietnamese_dir/master.zip
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
        ["com.xiaomi.macro"]="com.xiaomi.macro"
        ["framework-res"]="android"
    )
    # for dir in "$vietnamese_master"/*/; do
    #     dirname=$(basename "$dir" .apk)
    #     if [[ -n "${BUILD_APK_LIST[$dirname]}" ]] || [[ "$dirname" == "framework-ext-res" ]]; then
    #         continue
    #     fi

    #     apk_path=""
    #     if [ -d "$EXTRACTED_DIR"/*/*/"$dirname" ]; then
    #         apk_path=$(find "$EXTRACTED_DIR"/*/*/"$dirname" -name "*.apk" -type f -print -quit)
    #     fi

    #     if [ -z "$apk_path" ] && [ -d "$EXTRACTED_DIR/system"/*/*/"$dirname" ]; then
    #         apk_path=$(find "$EXTRACTED_DIR"/system/*/*/"$dirname" -name "*.apk" -type f -print -quit)
    #     fi

    #     if [ -z "$apk_path" ]; then
    #         continue
    #     fi

    #     apk_info=$($APKEDITTOR_COMMAND info -i "$apk_path")
    #     package_name=$(echo "$apk_info" | grep '^package=' | awk -F'=' '{print $2}' | tr -d '" ')
    #     # app_name=$(echo "$apk_info" | grep '^AppName=' | awk -F'=' '{print $2}' | tr -d '" ')

    #     if [[ $(printf "%s\n" "${BUILD_APK_LIST[@]}" | grep -Fxq "$package_name") ]]; then
    #         continue
    #     fi
    #     BUILD_APK_LIST["$dirname"]="$package_name"
    #     yellow "Add $dirname with $package_name to list Overlay"
    # done

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

        local manifest_content="<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\"?><manifest xmlns:android=\"http://schemas.android.com/apk/res/android\" android:compileSdkVersion=\"23\" android:compileSdkVersionCodename=\"6.0-$SHORT_DATE\" package=\"overlay.$package_name\" platformBuildVersionCode=\"$SHORT_DATE\" platformBuildVersionName=\"$ALL_DATE\">\n    <overlay android:isStatic=\"true\" android:priority=\"1\" android:targetPackage=\"$package_name\"/>\n</manifest>"
        local apktool_content="version: 2.9.3\napkFileName: $apk_name.apk\nisFrameworkApk: false\nusesFramework:\n  ids:\n  - 1\n  tag: null\nsdkInfo:\npackageInfo:\n  forcedPackageId: 127\n  renameManifestPackage: null\nversionInfo:\n  versionCode: $SHORT_DATE\n  versionName: $ALL_DATE\nresourcesAreCompressed: false\nsharedLibrary: false\nsparseResources: false\ndoNotCompress:\n- resources.arsc"
        echo -e $manifest_content >"$vietnamese_dir/$apk_name/AndroidManifest.xml"
        echo -e $apktool_content >"$vietnamese_dir/$apk_name/apktool.yml"

        find "$vietnamese_master/$apk_name.apk/res/values-vi" -name "*.xml" -exec cp {} "$vietnamese_dir/$apk_name/res/values-vi" \;

        generate_public_xml "$vietnamese_dir/$apk_name/res/values-vi" "$vietnamese_dir/$apk_name/res/values/public.xml"

        $APK_TOOL b -c -f $vietnamese_dir/$apk_name -o $vietnamese_dir/${apk_name}_tmp.apk >/dev/null 2>&1 || error "ERROR: Build overlay $apk_name.apk failed"
        zipalign -f 4 $vietnamese_dir/${apk_name}_tmp.apk $vietnamese_dir/packed/${apk_name}.apk >/dev/null 2>&1 || error "ERROR: Zipalign overlay $apk_name.apk failed"
        rm -rf $vietnamese_dir/${apk_name}_tmp.apk
        $APKSIGNER_COMMAND sign --key $BIN_DIR/apktool/Key/testkey.pk8 --cert $BIN_DIR/apktool/Key/testkey.x509.pem $vietnamese_dir/packed/$apk_name.apk # >/dev/null 2>&1 || error "ERROR: Sign overlay $apk_name.apk failed"
        if [ -f "$vietnamese_dir/packed/$apk_name.apk" ]; then
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

vietnamize2() {
    local url="https://github.com/butinhi/MIUI-14-XML-Vietnamese/archive/refs/heads/master.zip"
    local vietnamese_dir="$OUT_DIR/vn"
    local vietnamese_master="$vietnamese_dir/MIUI-14-XML-Vietnamese-master/Vietnamese/main"

    mkdir -p "$vietnamese_dir/packed"
    cd "$vietnamese_dir"

    # Tải file ZIP từ URL và lưu với tên đã chỉ định
    curl -k --location --remote-name --max-time 20 "$url" || cp -f $FILES_DIR/MIUI-14-XML-Vietnamese-master.zip $vietnamese_dir/master.zip
    7za x master.zip -aoa
    rm -f master.zip

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

    7za x $FILES_DIR/Overlay-24.06.07.zip -o"$vietnamese_dir/old/" -aoa
    for file in "$vietnamese_dir/old"/*.apk; do
        if [ -f "$file" ]; then
            # local apk_name=$(basename "$file")
            local apk_name=$(basename "$file" .apk)

            $APK_TOOL d i $file -o$vietnamese_dir/$apk_name >/dev/null 2>&1 || error "ERROR: Decompile overlay $apk_name.apk failed"

            find "$vietnamese_master/$apk_name.apk/res/values-vi" -name "*.xml" -exec cp -f {} "$vietnamese_dir/$apk_name/res/values-vi" \;

            generate_public_xml "$vietnamese_dir/$apk_name/res/values-vi" "$vietnamese_dir/$apk_name/res/values/public.xml"

            $APK_TOOL b -c -f $vietnamese_dir/$apk_name -o $vietnamese_dir/${apk_name}_tmp.apk >/dev/null 2>&1 || error "ERROR: Build overlay $apk_name.apk failed"
            zipalign -f 4 $vietnamese_dir/${apk_name}_tmp.apk $vietnamese_dir/packed/${apk_name}.apk >/dev/null 2>&1 || error "ERROR: Zipalign overlay $apk_name.apk failed"
            rm -rf $vietnamese_dir/${apk_name}_tmp.apk
            $APKSIGNER_COMMAND sign --key $BIN_DIR/apktool/Key/testkey.pk8 --cert $BIN_DIR/apktool/Key/testkey.x509.pem $vietnamese_dir/packed/$apk_name.apk # >/dev/null 2>&1 || error "ERROR: Sign overlay $apk_name.apk failed"
            if [ -f "$vietnamese_dir/packed/$apk_name.apk" ]; then
                rm -rf "$vietnamese_dir/$apk_name"
            else
                error "ERROR: Create overlay $apk_name.apk failed"
                exit 1
            fi
        fi
    done

    # cp -rf "$vietnamese_dir/packed/." "$EXTRACTED_DIR/product/overlay/"
    find "$vietnamese_dir/packed/" -name "*.apk" -exec cp -rf {} "$EXTRACTED_DIR/product/overlay/" \;

    rm -rf "$vietnamese_dir"
    cd "$PROJECT_DIR"
}
