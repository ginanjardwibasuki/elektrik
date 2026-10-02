#!/bin/bash

echo "=== SETUP KONEKSI DATABASE ==="

# Meminta input dari pengguna dengan nilai default (opsional)
read -p "Masukkan Database Host [localhost]: " DB_HOST
DB_HOST=${DB_HOST:-localhost}

read -p "Masukkan Database Username [root]: " DB_USER
DB_USER=${DB_USER:-root}

read -s -p "Masukkan Database Password: " DB_PASS
echo "" # Baris baru setelah password

read -p "Masukkan Nama Database [elektrik]: " DB_NAME
DB_NAME=${DB_NAME:-elektrik}

# Tentukan lokasi file koneksi.php (sesuaikan foldernya jika ada di subfolder)
TARGET_FILE="elektrik/helper/koneksi.php"

echo "Menulis konfigurasi ke $TARGET_FILE..."

# Menulis isi file secara dinamis menggunakan variabel Bash
cat <<EOF > "$TARGET_FILE"
<?php

\$host = '$DB_HOST';
\$username = '$DB_USER';
\$password = '$DB_PASS';
\$database = '$DB_NAME';

try {
    //code...
    \$db = mysqli_connect(\$host, \$username, \$password, \$database);
    \$db->set_charset('utf8mb4');
} catch (\Throwable \$th) {
    throw \$th;
}
EOF

echo "Selesai! File $TARGET_FILE berhasil dibuat dengan konfigurasi baru."

# 2. Membuat file backend/.env
TARGET_ENV="backend/.env"

# Pastikan folder backend ada
mkdir -p "$(dirname "$TARGET_ENV")"

echo "Menulis konfigurasi ke $TARGET_ENV..."

cat <<EOF > "$TARGET_ENV"
DB_HOST=$DB_HOST
DB_USER=$DB_USER
DB_PASS=$DB_PASS
DB_NAME=$DB_NAME
EOF

echo "Selesai! File $TARGET_PHP dan $TARGET_ENV berhasil dibuat dengan konfigurasi baru."

# Tambahkan di bagian autoinstall.sh Anda
read -p "Masukkan URL Socket.js / Backend [https://nodebattery.adaro-indonesia.my.id]: " SOCKET_URL
SOCKET_URL=${SOCKET_URL:-https://nodebattery.adaro-indonesia.my.id}

TARGET_JS_CONFIG="elektrik/pages/assets/js/config.js"
mkdir -p "$(dirname "$TARGET_JS_CONFIG")"

echo "Menulis konfigurasi Socket ke $TARGET_JS_CONFIG..."
cat <<EOF > "$TARGET_JS_CONFIG"
const CONFIG = {
    SOCKET_URL: "$SOCKET_URL"
};
EOF

# --- SETUP URL CONFIG UNTUK PHP ---
read -p "Masukkan Base URL / Backend API [https://nodebattery.adaro-indonesia.my.id]: " BASE_URL
BASE_URL=${BASE_URL:-https://nodebattery.adaro-indonesia.my.id}

TARGET_URL_CONFIG="elektrik/helper/url_config.php"


echo "Menulis konfigurasi URL ke $TARGET_URL_CONFIG..."

# Menulis isi file secara dinamis
cat <<EOF > "$TARGET_URL_CONFIG"
<?php
define('BASE_URL', '$BASE_URL');
EOF

echo "Selesai! File $TARGET_URL_CONFIG berhasil dibuat dengan URL: $BASE_URL"