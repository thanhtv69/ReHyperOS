download_and_extract() {
    blue "========================================="
    blue "START download and extract payload"
    local start=$(date +%s)

    if [ ! -f "$zip_name" ]; then
        green "Download $zip_name"
        sudo aria2c -x16 -j$(nproc) -U "Mozilla/5.0" -d "$PROJECT_DIR" "$URL" >/dev/null 2>&1 || error "Download $zip_name failed"
    fi

    green "Extract $zip_name"
    7za x "$zip_name" payload.bin -o"$OUT_DIR" -aos >/dev/null 2>&1
    [[ "$is_clean" == true ]] && rm -rf "$zip_name"

    green "Find missing partitions"
    local payload_output
    payload_output=$(payload-dumper-go -l "$OUT_DIR/payload.bin")
    local p_payload
    p_payload=($(echo "$payload_output" | grep -oP '\b\w+(?=\s\()'))

    local missing_partitions=""
    for p in "${p_payload[@]}"; do
        if [ ! -e "$IMAGES_DIR/$p.img" ]; then
            missing_partitions="${missing_partitions:+$missing_partitions,}$p"
        fi
    done

    if [ -n "$missing_partitions" ]; then
        green "Extract missing partitions"
        payload-dumper-go -c $max_threads -o "$IMAGES_DIR" -p "$missing_partitions" "$OUT_DIR/payload.bin" >/dev/null 2>&1 || error "Extract missing partitions failed"
        green "Missing partitions extracted [$missing_partitions]"
    else
        yellow "No missing partitions"
    fi

    [[ "$is_clean" == true ]] && rm -rf "$OUT_DIR/payload.bin"
    local end=$(date +%s)
    blue "END Find missing partitions ($((end - start))s)"
}

extract_img() {
    blue "========================================="
    blue "START extract images"
    local start=$(date +%s)
    for partition in "${EXTRACT_LIST[@]}"; do
        if [ ! -f "$IMAGES_DIR/$partition.img" ]; then
            error "Missing $partition.img"
            exit 1
        fi
        image_type=$(gettype -i $IMAGES_DIR/$partition.img)
        green "Extract $partition.img - Type: $image_type"

        rm -rf "$EXTRACTED_DIR/$partition" >/dev/null 2>&1
        extract.erofs -s -x -T$max_threads -i "$IMAGES_DIR/$partition.img" -o "$EXTRACTED_DIR"
        if [ ! -d "$EXTRACTED_DIR/$partition" ]; then
            error "Extract $partition.img failed"
            exit 1
        fi
        [[ "$is_clean" == true ]] && rm -rf "$IMAGES_DIR/$partition.img"
    done

    local end=$(date +%s)
    blue "END Find missing partitions ($((end - start))s)"

    blue "========================================="
    blue "START Install framework-res.apk, miuisystem.apk, framework-ext-res.apk"
    $APKTOOL_COMMAND "if" "$EXTRACTED_DIR/system/system/framework/framework-res.apk"
    $APKTOOL_COMMAND "if" "$EXTRACTED_DIR/system_ext/app/miuisystem/miuisystem.apk"
    $APKTOOL_COMMAND "if" "$EXTRACTED_DIR/system_ext/framework/framework-ext-res/framework-ext-res.apk"
    blue "END Install framework-res.apk, miuisystem.apk, framework-ext-res.apk"
}

repack_img_and_super() {
    blue "========================================="
    blue "START repack images and super"
    local start=$(date +%s)

    if [ ! -d "$READY_DIR/images" ]; then
        green "Create $READY_DIR/images"
        mkdir -p "$READY_DIR/images"
    fi

    for fstab in $(find $EXTRACTED_DIR/*/ -type f -name "fstab.*"); do
        if [[ "$build_type" == "ext4" ]]; then
            sed -i '/^overlay/ s/^/# /' "$fstab"
            sed -i '/^system .* erofs/ s/^/# /' "$fstab"
            sed -i '/^system_ext .* erofs/ s/^/# /' "$fstab"
            sed -i '/^vendor .* erofs/ s/^/# /' "$fstab"
            sed -i '/^product .* erofs/ s/^/# /' "$fstab"
        else
            sed -i '/^# overlay/ s/^# //' "$fstab"
            sed -i '/^# system .* erofs/ s/^# //' "$fstab"
            sed -i '/^# system_ext .* erofs/ s/^# //' "$fstab"
            sed -i '/^# vendor .* erofs/ s/^# //' "$fstab"
            sed -i '/^# product .* erofs/ s/^# //' "$fstab"
        fi
    done
    

    for partition in "${EXTRACT_LIST[@]}"; do
        green "Repack $partition.img"
        start=$(date +%s)

        local input_folder_image="$EXTRACTED_DIR/$partition"
        local output_image="$READY_DIR/images/$partition.img"
        local fs_config_file="$EXTRACTED_DIR/config/${partition}_fs_config"
        local file_contexts_file="$EXTRACTED_DIR/config/${partition}_file_contexts"

        python3 "$BIN_DIR/fspatch.py" "$input_folder_image" "$fs_config_file" >/dev/null 2>&1
        python3 "$BIN_DIR/contextpatch.py" "$input_folder_image" "$file_contexts_file" >/dev/null 2>&1

        if [[ "$build_type" == "ext4" && " ${EXT4_LIST[*]} " == *" $partition "* ]]; then
            
            this_size=$(du -sb $EXTRACTED_DIR/${partition} |tr -cd 0-9)
            green "Original Size: $(echo "scale=2; $this_size / 1048576" | bc) MB"
            this_size=$(echo "scale=2; $this_size * 1.2" | bc)
            green "New Size (+20%): $(echo "scale=2; $this_size / 1048576" | bc) MB"
            make_ext4fs -J -T 1230768000 -S $file_contexts_file -l $this_size -C $fs_config_file -L $partition -a $partition $output_image $input_folder_image
        else
            mkfs.erofs --quiet -zlz4hc --workers=$max_threads -T 1230768000 --mount-point="$partition" --fs-config-file="$fs_config_file" --file-contexts="$file_contexts_file" "$output_image" "$input_folder_image"
        fi
        
        if [ ! -f "$output_image" ]; then
            error "Mkfs erofs $partition failed"
            exit 1
        fi
        [[ "$is_clean" == true ]] && rm -rf "$EXTRACTED_DIR/$partition"
        local end=$(date +%s)
        green "END Repack $partition.img ($((end - start))s)"
    done

    blue "Repack super.img"
    start=$(date +%s)
    local super_out="$READY_DIR/images/super.img"
    local lpargs="-F --virtual-ab --output $super_out --metadata-size 65536 --super-name super --metadata-slots 3 --device super:$super_size --group=qti_dynamic_partitions_a:$super_size --group=qti_dynamic_partitions_b:$super_size"
    local total_subsize=0

    for pname in "${SUPER_LIST[@]}"; do
        local image_sub="$READY_DIR/images/$pname.img"
        if ! printf '%s\n' "${EXTRACT_LIST[@]}" | grep -q "^$pname$"; then
            cp -rf "$IMAGES_DIR/$pname.img" "$READY_DIR/images"
        fi
        local subsize=$(du -sb "$image_sub" | tr -cd 0-9)
        total_subsize=$((total_subsize + subsize))
        local args="--partition ${pname}_a:none:${subsize}:qti_dynamic_partitions_a --image ${pname}_a=${image_sub} --partition ${pname}_b:none:0:qti_dynamic_partitions_b"
        lpargs="$lpargs $args"
        green "[$pname] size: $(printf "%'d" "$subsize")"
    done

    if [ "$total_subsize" -gt "$super_size" ]; then
        error "Total subsize ($total_subsize bytes) is greater than super size ($super_size bytes)!"
        exit 1
    fi
    green "Total subsize: $(printf "%'d" "$total_subsize")/$(printf "%'d" "$super_size") bytes"

    lpmake $lpargs
    if [ -f "$super_out" ]; then
        green "Super image: $super_out"
        find "$READY_DIR/images" -type f -name '*.img' | grep -E "$(
            IFS=\|
            echo "${SUPER_LIST[*]}"
        )" | xargs rm -rf
    else
        error "LPmake super.img failed"
        exit 1
    fi
    local end=$(date +%s)
    blue "END Repack super.img ($((end - start))s)"
}

generate_script() {
    blue "========================================="
    blue "START Generate script to flash"

    for img_file in "$IMAGES_DIR"/*.img; do
        local partition_name=$(basename "$img_file" .img)
        if ! printf '%s\n' "${EXTRACT_LIST[@]}" | grep -q "^$partition_name$" &&
            ! printf '%s\n' "${SUPER_LIST[@]}" | grep -q "^$partition_name$"; then
            cp -rf "$img_file" "$READY_DIR/images"
        fi
    done

    [[ "$is_clean" == true ]] && rm -rf "$IMAGES_DIR"
    7za x "$FILES_DIR/flash_tool.7z" -o"$READY_DIR" -aoa >/dev/null 2>&1
    sed -i "s/Model_code/${device}/g" "$READY_DIR/FlashROM."*

    blue "END Generate script to flash"
}
zip_rom() {
    blue "========================================="
    blue "START ZSTD super.img"
    local start_time=$(date +%s)
    local super_img="$READY_DIR/images/super.img"
    local super_zst="$READY_DIR/images/super.img.zst"

    find "$READY_DIR"/images/*.img -exec touch -t 200901010000.00 {} \;
    zstd -f "$super_img" -o "$super_zst" --rm

    local end_time=$(date +%s)
    blue "ZSTD super.img ($((end_time - start_time))s)"

    blue "========================================="
    blue "START Zip rom"
    local start_time=$(date +%s)
    cp -rf "$LOG_FILE" "$READY_DIR"
    cd "$READY_DIR"
    local log_file_name=$(basename "$LOG_FILE")
    7za -tzip a miui.zip bin/* images/* FlashROM.bat "$log_file_name" -y
    cd "$PROJECT_DIR"
    local md5=$(md5sum "$READY_DIR/miui.zip" | awk '{ print $1 }')
    local rom_name="ReHyper_${device}_${os_version}_${md5:0:8}_${build_time}VN_${android_version}.0_[${build_type}].zip"
    local rom_path="$READY_DIR/$rom_name"
    mv "$READY_DIR/miui.zip" "$rom_path"

    echo "rom_path=$rom_path" >>"$GITHUB_ENV"
    echo "rom_name=$rom_name" >>"$GITHUB_ENV"
    echo "rom_md5=$md5" >>"$GITHUB_ENV"
    echo "os_version=$os_version" >>"$GITHUB_ENV"
    echo "device_name=$device" >>"$GITHUB_ENV"

    local end_time=$(date +%s)
    blue "END Zip rom ($((end_time - start_time))s)"
}
