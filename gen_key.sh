#!/bin/bash

# Đặt thư mục lưu trữ khóa
KEY_DIR="bin/apktool/Key"
mkdir -p "$KEY_DIR"

# Đặt tên tệp cho khóa và chứng chỉ
PRIVATE_KEY_PEM="$KEY_DIR/private_key.pem"
PUBLIC_KEY_PEM="$KEY_DIR/public_key.pem"
PRIVATE_KEY_PK8="$KEY_DIR/private_key.pk8"
CERTIFICATE_PEM="$KEY_DIR/my_certificate.pem"
CERTIFICATE_DER="$KEY_DIR/my_certificate.der"

# Tạo khóa riêng (RSA 2048-bit)
echo "Tạo khóa riêng..."
openssl genrsa -out "$PRIVATE_KEY_PEM" 2048

# Tạo khóa công khai từ khóa riêng
echo "Tạo khóa công khai..."
openssl rsa -in "$PRIVATE_KEY_PEM" -pubout -out "$PUBLIC_KEY_PEM"

# Chuyển đổi khóa riêng sang định dạng PKCS#8 (.pk8)
echo "Chuyển đổi khóa riêng sang định dạng PKCS#8..."
openssl pkcs8 -topk8 -inform PEM -outform DER -in "$PRIVATE_KEY_PEM" -out "$PRIVATE_KEY_PK8" -nocrypt

# Tạo chứng chỉ X.509 (dùng khóa riêng để ký chứng chỉ)
echo "Tạo chứng chỉ X.509..."
openssl req -new -x509 -key "$PRIVATE_KEY_PEM" -out "$CERTIFICATE_PEM" -days 365 -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=CommonName"

# Kiểm tra nếu chứng chỉ đã được tạo thành công
if [ ! -f "$CERTIFICATE_PEM" ]; then
    echo "Lỗi: Không thể tạo chứng chỉ X.509."
    exit 1
fi

# Chuyển đổi chứng chỉ PEM sang định dạng DER nếu cần
echo "Chuyển đổi chứng chỉ PEM sang định dạng DER..."
openssl x509 -outform der -in "$CERTIFICATE_PEM" -out "$CERTIFICATE_DER"

# Kiểm tra nếu chứng chỉ DER đã được tạo thành công
if [ ! -f "$CERTIFICATE_DER" ]; then
    echo "Lỗi: Không thể chuyển đổi chứng chỉ PEM sang định dạng DER."
    exit 1
fi

echo "Tất cả các tệp khóa và chứng chỉ đã được tạo thành công!"
