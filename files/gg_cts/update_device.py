import re
import requests

# Lấy dữ liệu từ URL
url = "https://raw.githubusercontent.com/chiteroman/PlayIntegrityFix/main/module/pif.json"
response = requests.get(url)
pif = response.json()

# Đọc nội dung từ file
file_path = 'files/gg_cts/ApplicationStub.smali'
with open(file_path, 'r', encoding='utf-8') as file:
    content = file.read()

# Mẫu tìm kiếm
pattern = r'"com\.google\.android\.gms"(?:\n.*)+.*com.google\.android\.apps\.photos'

match = re.search(pattern, content)
if match:
    old_code = match.group(0)

    # Các mẫu thay thế
    patterns = {
        'BRAND': r'(const-string \w+, "BRAND"\n+\s+const-string.* \w+, ")([^"]+)',
        'PRODUCT': r'(const-string \w+, "PRODUCT"\n+\s+const-string.* \w+, ")([^"]+)',
        'DEVICE': r'(const-string \w+, "DEVICE"\n+\s+const-string.* \w+, ")([^"]+)',
        'MANUFACTURER': r'(const-string \w+, "MANUFACTURER"\n+\s+const-string.* \w+, ")([^"]+)',
        'MODEL': r'(const-string \w+, "MODEL"\n+\s+const-string.* \w+, ")([^"]+)',
        'FINGERPRINT': r'(const-string \w+, "FINGERPRINT"\n+\s+const-string.* \w+, ")([^"]+)',
        'ID': r'(const-string \w+, "ID"\n+\s+const-string.* \w+, ")([^"]+)',
    }

    # Thay thế các giá trị trong mã
    new_code = old_code
    for key, pat in patterns.items():
        if key in pif:
            new_code = re.sub(pat, r'\1' + pif[key], new_code)

    # Thay thế nội dung trong file
    new_content = content.replace(old_code, new_code)
    with open(file_path, 'w', encoding='utf-8') as file:
        file.write(new_content)

    print("Đã thay thế các giá trị trong file.")
else:
    print("Mẫu không tìm thấy trong nội dung.")
