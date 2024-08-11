download_and_extract() {
    echo -e "\n========================================="
    start=$(date +%s)

    # Kiểm tra xem file zip đã được tải xuống chưa
    if [ ! -f "$zip_name" ]; then
        echo "Đang tải xuống... [$zip_name]"
        sudo aria2c -x16 -j$(nproc) -U "Mozilla/5.0" -d "$PROJECT_DIR" "$URL"
        echo "- Tải xuống từ $URL" >>"$LOG_FILE"
    fi

    # Giải nén file payload.bin từ file zip
    echo "Đang giải nén... [payload.bin]"
    7za x "$zip_name" payload.bin -o"$OUT_DIR" -aos >/dev/null 2>&1
    [ "$is_clean" = true ] && rm -rf "$zip_name"

    # Tìm các phân vùng thiếu
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

    # Giải nén các phân vùng thiếu nếu có
    if [ ! -z "$missing_partitions" ]; then
        echo "Đang giải nén các phân vùng thiếu: [$missing_partitions]"
        payload-dumper-go -c "$max_threads" -o "$IMAGES_DIR" -p "$missing_partitions" "$OUT_DIR/payload.bin" >/dev/null 2>&1 || echo "Lỗi giải nén [payload.bin]"
        echo "Đã giải nén [$missing_partitions]"
    else
        echo "Đã đủ các phân vùng"
    fi
    [ "$is_clean" = true ] && rm -rf "$OUT_DIR/payload.bin"

    # Giải nén từng phân vùng cụ thể trong danh sách EXTRACT_LIST
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

    # Thông báo thời gian thực hiện
    end=$(date +%s)
    echo "Đã giải nén trong $((end - start)) giây"

    $APKTOOL_COMMAND "if" "$EXTRACTED_DIR/system/system/framework/framework-res.apk"
    $APKTOOL_COMMAND "if" "$EXTRACTED_DIR/system_ext/app/miuisystem/miuisystem.apk"
    $APKTOOL_COMMAND "if" "$EXTRACTED_DIR/system_ext/framework/framework-ext-res/framework-ext-res.apk"
}

repack_img_and_super() {
    echo -e "\n========================================="
    # Kiểm tra và tạo thư mục READY_DIR nếu cần
    if [ ! -d "$READY_DIR/images" ]; then
        echo "Đang tạo thư mục $READY_DIR/images..."
        mkdir -p "$READY_DIR/images"
    fi

    # Lặp qua danh sách các phân vùng để đóng gói lại
    for partition in "${EXTRACT_LIST[@]}"; do
        start=$(date +%s)
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
        # mkfs.erofs -zlz4hc -T 1230768000 --mount-point="$partition" --fs-config-file="$fs_config_file" --file-contexts="$file_contexts_file" "$output_image" "$input_folder_image" >/dev/null 2>&1 || echo "Mkfs erofs $partition failed"
        make.erofs -zlz4hc -T 1230768000 --mount-point="$partition" --fs-config-file="$fs_config_file" --file-contexts="$file_contexts_file" "$output_image" "$input_folder_image" >/dev/null 2>&1 || echo "Mkfs erofs $partition failed"
        # Kiểm tra nếu quá trình đóng gói thất bại
        if [ ! -f "$output_image" ]; then
            echo "Quá trình đóng gói lại file [$output_image] thất bại."
            exit 1
        fi
        [ "$is_clean" = true ] && rm -rf "$EXTRACTED_DIR/$partition"
        end=$(date +%s)
        echo -e "Mkfs erofs $partition in $((end - start)) seconds\n\n"
    done

    # Đóng gói các phân vùng thành super
    start=$(date +%s)
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
        # echo "Đóng gói thành công super.img"
        end=$(date +%s)
        echo "LPmake super.img in $((end - start)) seconds"
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
    echo -e "\n========================================="
    start_time=$(date +%s)
    echo "Nén super.img"
    super_img=$READY_DIR/images/super.img
    super_zst=$READY_DIR/images/super.img.zst

    find "$READY_DIR"/images/*.img -exec touch -t 200901010000.00 {} \;
    # zstd -19 -f "$super_img" -o "$super_zst" --rm
    zstd -f "$super_img" -o "$super_zst" --rm

    end_time=$(date +%s)
    echo "Nén super.img trong $((end_time - start_time)) seconds"

    start_time=$(date +%s)
    cp -rf $LOG_FILE $READY_DIR
    echo "Zip rom..."
    cd $READY_DIR
    log_file_name=$(basename $LOG_FILE)
    # 7za -tzip a miui.zip bin/* images/* FlashROM.bat $log_file_name -y -mx9
    7za -tzip a miui.zip bin/* images/* FlashROM.bat $log_file_name -y
    cd $PROJECT_DIR
    md5=$(md5sum "$READY_DIR/miui.zip" | awk '{ print $1 }')
    rom_name="ReHyper_${device}_${os_version}_${md5:0:8}_${build_time}VN_${android_version}.0.zip"
    rom_path="$READY_DIR/$rom_name"
    mv "$READY_DIR/miui.zip" "$rom_path"

    echo "rom_path=$rom_path" >>"$GITHUB_ENV"
    echo "rom_name=$rom_name" >>"$GITHUB_ENV"
    echo "os_version=$os_version" >>"$GITHUB_ENV"
    echo "device_name=$device" >>"$GITHUB_ENV"

    end_time=$(date +%s)
    echo "Zip rom trong $((end_time - start_time)) seconds"
}
