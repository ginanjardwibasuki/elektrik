#!/bin/bash
# ==============================================================================
# SCRIPT OTOMATIS INSTALL LXC DEBIAN 13 DI PROXMOX
# ==============================================================================
set -e

# ------------------------------------------------------------------------------
# FUNGSI: Cek dan Download Template Debian 13
# ------------------------------------------------------------------------------
check_template() {
    local template="debian-13-standard_13.6-1_amd64.tar.zst"
    local template_dir="/var/lib/vz/template/cache"

    if [ -f "$template_dir/$template" ]; then
        echo "[INFO] Template Debian 13 ditemukan secara lokal."
    else
        echo "[INFO] Template Debian 13 tidak ada, mengunduh dari repositori Proxmox..."
        pveam update >/dev/null 2>&1
        pveam download local $template
    fi
    
    # Simpan ke variabel global
    TEMPLATE="$template_dir/$template"
}

# ------------------------------------------------------------------------------
# FUNGSI: Cari VMID (Container ID) yang belum terpakai
# ------------------------------------------------------------------------------
next_vmid() {
    local last_id=$(pct list | awk 'NR>1 {print $1}' | sort -n | tail -1)
    if [ -z "$last_id" ]; then
        echo 100
    else
        echo $((last_id+1))
    fi
}

# ------------------------------------------------------------------------------
# KONFIGURASI UTAMA
# ------------------------------------------------------------------------------
echo "====================================================="
echo "  SETUP LXC DEBIAN 13 CONTAINER                      "
echo "====================================================="
echo "Gunakan default install? (y/n) [default: n]: "
read default_choice

if [[ "$default_choice" == "y" || "$default_choice" == "Y" ]]; then
    # --- PENGATURAN DEFAULT (Mode Cepat) ---
    VMID=$(next_vmid)
    HOSTNAME="debian-lxc"
    ROOT_PASS="rahasia123"
    TYPE_FLAG="-unprivileged 1"
    STORAGE="local-lvm"
    DISK=20
    CPU=1
    RAM=2048
    SWAP=2048
    BRIDGE="vmbr0"
    IP_CONFIG="ip=dhcp"
    MAC_CONFIG=""
else
    # --- PENGATURAN INTERAKTIF (Mode Kustomisasi) ---

    # 1. VMID / Container ID
    DEFAULT_VMID=$(next_vmid)
    echo -n "Container ID default [$DEFAULT_VMID]: "
    read input_vmid
    if [[ -n "$input_vmid" ]]; then
        if [[ "$input_vmid" =~ ^[0-9]+$ ]] && ! pct list | awk '{print $1}' | grep -q "^$input_vmid$"; then
            VMID=$input_vmid
        else
            echo "[ERROR] ID tidak valid atau sudah terpakai."
            exit 1
        fi
    else
        VMID=$DEFAULT_VMID
    fi

    # 2. Hostname
    echo -n "Hostname [debian-lxc]: "
    read input_host
    HOSTNAME=${input_host:-debian-lxc}

    # 3. Password Root LXC (Disembunyikan saat diketik)
    while true; do
        read -s -p "Masukkan Password Root untuk LXC: " ROOT_PASS
        echo ""
        read -s -p "Konfirmasi Password Root: " ROOT_PASS_CONFIRM
        echo ""
        if [ "$ROOT_PASS" = "$ROOT_PASS_CONFIRM" ]; then
            if [ -n "$ROOT_PASS" ]; then
                break
            else
                echo "[ERROR] Password tidak boleh kosong!"
            fi
        else
            echo "[ERROR] Password tidak cocok. Silakan coba lagi."
        fi
    done

    # 4. Tipe Container
    echo -n "Tipe Container (1=privileged, 2=unprivileged) [default: 1]: "
    read type_choice
    if [[ "$type_choice" == "1" ]]; then
        TYPE_FLAG="-unprivileged 0"
    else
        TYPE_FLAG="-unprivileged 1"
    fi

# 5. Storage Pool
    echo "Daftar storage yang MENDUKUNG instalasi LXC di node ini:"
    pvesm status -content rootdir | awk 'NR>1 {print "  - " $1 " (" $2 ")"}'
    echo -n "Pilih storage untuk RootFS [default: local-lvm]: "
    read input_storage
    STORAGE=${input_storage:-local-lvm}
    
    # 6. Spesifikasi Hardware (Hanya Angka)
    echo -n "Disk size (GB) [default: 8]: "
    read input_disk
    DISK=$(echo "${input_disk:-8}" | tr -dc '0-9')

    echo -n "Jumlah CPU core [default: 1]: "
    read input_cpu
    CPU=$(echo "${input_cpu:-1}" | tr -dc '0-9')

    echo -n "RAM size (MB) [default: 2048]: "
    read input_ram
    RAM=$(echo "${input_ram:-2048}" | tr -dc '0-9')

    echo -n "Swap size (MB) [default: 2048]: "
    read input_swap
    SWAP=$(echo "${input_swap:-2048}" | tr -dc '0-9')

    # 7. Konfigurasi Jaringan (Bridge)
    echo "Daftar bridge yang tersedia di node ini:"
    ip -br link show type bridge | awk '{print "  - " $1}'
    echo -n "Pilih bridge [default: vmbr1]: "
    read input_bridge
    BRIDGE=${input_bridge:-vmbr1}

    # 8. Konfigurasi Jaringan (MAC Address)
    echo -n "MAC Address (Kosongkan untuk Auto/Random): "
    read input_mac
    if [ -z "$input_mac" ]; then
        MAC_CONFIG=""
    else
        MAC_CONFIG=",hwaddr=$input_mac"
    fi

    # 9. Konfigurasi Jaringan (IP Address)
    echo -n "Pilih tipe IPv4 (1=DHCP, 2=Statis) [default: 1]: "
    read ip_type
    if [[ "$ip_type" == "2" ]]; then
        echo -n "Masukkan IP Address & Subnet (contoh: 192.168.1.100/24): "
        read ip_static
        echo -n "Masukkan IP Gateway (contoh: 192.168.1.1): "
        read ip_gw
        if [ -z "$ip_static" ] || [ -z "$ip_gw" ]; then
            echo "[ERROR] IP Address dan Gateway tidak boleh kosong untuk mode Statis."
            exit 1
        fi
        IP_CONFIG="ip=$ip_static,gw=$ip_gw"
    else
        IP_CONFIG="ip=dhcp"
    fi
fi

# ------------------------------------------------------------------------------
# EKSEKUSI PEMBUATAN CONTAINER
# ------------------------------------------------------------------------------
check_template

echo "====================================================="
echo "[INFO] Membuat container Debian 13 dengan rincian:"
echo "       - VMID          : $VMID"
echo "       - Hostname      : $HOSTNAME"
echo "       - Root Password : [TERSEMBUNYI]"
echo "       - Tipe          : $(if [[ "$TYPE_FLAG" == *"0"* ]]; then echo "Privileged"; else echo "Unprivileged"; fi)"
echo "       - Storage       : $STORAGE (${DISK}GB)"
echo "       - CPU Core      : $CPU Core"
echo "       - RAM           : ${RAM}MB"
echo "       - SWAP          : ${SWAP}MB"
echo "       - Bridge        : $BRIDGE"
echo "       - Network       : $IP_CONFIG ${MAC_CONFIG:+, MAC: ${MAC_CONFIG#*,hwaddr=}}"
echo "====================================================="

# Parameter -password ditambahkan di sini untuk menyetel password root LXC
pct create $VMID $TEMPLATE \
    -hostname $HOSTNAME \
    -password "$ROOT_PASS" \
    -storage $STORAGE \
    -rootfs $STORAGE:${DISK} \
    -cores $CPU \
    -memory $RAM \
    -swap $SWAP \
    -net0 name=eth0,bridge=$BRIDGE,firewall=0,${IP_CONFIG}${MAC_CONFIG} \
    -features nesting=1 \
    -onboot 1 \
    $TYPE_FLAG

# ------------------------------------------------------------------------------
# MENJALANKAN CONTAINER & SETUP LANJUTAN
# ------------------------------------------------------------------------------
echo "[INFO] Menjalankan Container $VMID..."
pct start $VMID

echo "[INFO] Menunggu koneksi internet aktif di dalam LXC..."
INTERNET_OK=0
for i in {1..30}; do
    if pct exec $VMID -- ping -c 1 -W 1 deb.debian.org >/dev/null 2>&1; then
        echo "[INFO] Internet terhubung (Butuh waktu $i detik)."
        INTERNET_OK=1
        break
    fi
    sleep 1
done

if [ "$INTERNET_OK" -eq 0 ]; then
    echo "[ERROR] Container gagal terhubung ke internet. Proses instalasi aplikasi dibatalkan."
    exit 1
fi

echo "[INFO] Melakukan update system dasar di LXC..."
pct exec $VMID -- bash -c "export DEBIAN_FRONTEND=noninteractive; apt update -y && apt upgrade -y"

# ------------------------------------------------------------------------------
# BAGIAN 3: INJEKSI SCRIPT APLIKASI KE DALAM LXC
# ------------------------------------------------------------------------------
echo "[INFO] Menyiapkan script instalasi Elektrik Stack..."

# Menulis Script 2 (App Installer) secara utuh ke file sementara
cat << 'EOF_MASTER_INJECT' > /tmp/install_elektrik_${VMID}.sh
#!/bin/bash
# ==============================================================================
# SCRIPT TEMPLATE AUTOINSTALL CONTAINER LXC (MODULAR VERSION)
# ==============================================================================

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
locale-gen en_US.UTF-8 2>/dev/null

mkdir -p /root/logs/
CONFIG_FILE="/root/.env_elektrik"
REPORT_FILE="/root/logs/install_report.log"
SYSTEM_REPORT_FILE="/root/logs/elektrik_report.log"
OUTPUT_LOG_FILE="/root/logs/install_output.log"
SYSTEM_OUTPUT_FILE="/root/logs/elektrik_output.log"

RED="\e[1;31m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
CYAN="\e[1;36m"
RESET="\e[0m"

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Harap jalankan script ini sebagai root (sudo).${RESET}"
        exit 1
    fi
}

init_logging() {
    exec > >(tee -a "$OUTPUT_LOG_FILE" "$SYSTEM_OUTPUT_FILE") 2>&1
    echo "==================================================================" > "$REPORT_FILE"
    echo "            LAPORAN RESUME INSTALASI SERVER ELEKTRIK              " >> "$REPORT_FILE"
    echo "            Waktu Eksekusi: $(date)" >> "$REPORT_FILE"
    echo "==================================================================" >> "$REPORT_FILE"
}

log_status() {
    local step_name="$1"
    local status="$2" 
    local detail="$3"
    local log_entry=""
    
    if [ "$status" == "SUCCESS" ]; then
        log_entry="✔ [BERHASIL] $step_name - $detail"
        echo -e "${GREEN}$log_entry${RESET}"
    else
        log_entry="❌ [GAGAL]    $step_name - $detail"
        echo -e "${RED}$log_entry${RESET}"
    fi
    echo "$log_entry" >> "$REPORT_FILE"
}

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${GREEN}[INFO] Menemukan file konfigurasi di $CONFIG_FILE${RESET}"
        echo "Memuat pengaturan sebelumnya..."
        source "$CONFIG_FILE"
    fi
}

prompt_config() {
    clear
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "${CYAN}             [1/4] KONFIGURASI DATABASE & APLIKASI                  ${RESET}"
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "${YELLOW}📌 PETUNJUK PENGISIAN:${RESET}"
    echo -e "  • ${GREEN}Host & User${RESET}  : Default 'localhost' & 'root' (Tekan [Enter] untuk default)."
    echo -e "  • ${GREEN}Password DB${RESET}  : Disembunyikan demi keamanan (karakter tidak tampil)."
    echo -e "  • ${GREEN}Port Backend${RESET} : Port untuk service Node.js/PM2 (Default: 2083)."
    echo -e "${CYAN}--------------------------------------------------------------------${RESET}"
    echo ""

    read -p "Masukkan Database Host [${DB_HOST:-localhost}]: " INPUT
    DB_HOST=${INPUT:-${DB_HOST:-localhost}}

    read -p "Masukkan Database Username [${DB_USER:-root}]: " INPUT
    DB_USER=${INPUT:-${DB_USER:-root}}

    read -s -p "Masukkan Database Password [${DB_PASS:-}]: " INPUT
    DB_PASS=${INPUT:-${DB_PASS}}
    echo ""

    read -p "Masukkan Nama Database [${DB_NAME:-elektrik}]: " INPUT
    DB_NAME=${INPUT:-${DB_NAME:-elektrik}}

    read -p "Masukkan Port Backend Node.js [${BACKEND_PORT:-2083}]: " INPUT
    BACKEND_PORT=${INPUT:-${BACKEND_PORT:-2083}}

    clear
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "${CYAN}                 [2/4] KONFIGURASI DOMAIN & URL                     ${RESET}"
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "${YELLOW}📌 PETUNJUK PENGISIAN:${RESET}"
    echo -e "  • ${GREEN}Domain Utama${RESET}    : Masukkan domain Anda (misal: 'domainku.com')."
    echo -e "                    *Jangan sertakan http:// atau https://*"
    echo -e "  • ${GREEN}Subdomain Web${RESET}   : Awalan web utama. Misal: 'elektrik' -> elektrik.domainku.com"
    echo -e "  • ${GREEN}Subdomain Socket${RESET}: Awalan API/Socket. Misal: 'api' -> api.domainku.com"
    echo -e "${CYAN}--------------------------------------------------------------------${RESET}"
    echo ""

    read -p "Masukkan Domain Utama [${DOMAIN:-}]: " INPUT
    DOMAIN=${INPUT:-${DOMAIN}}

    read -p "Masukkan Subdomain Website [${CF_PRE_WEB:-elektrik}]: " INPUT
    CF_PRE_WEB=${INPUT:-${CF_PRE_WEB:-elektrik}}

    read -p "Masukkan Subdomain Backend/Socket [${CF_PRE_SOCKET:-api}]: " INPUT
    CF_PRE_SOCKET=${INPUT:-${CF_PRE_SOCKET:-api}}

    CF_WEB_NAME="${CF_PRE_WEB}.${DOMAIN}"
    SOCKET_URL="${CF_PRE_SOCKET}.${DOMAIN}"
    CF_ROOT_DOMAIN="${DOMAIN}"

    clear
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "${CYAN}          [3/4] KONFIGURASI CLOUDFLARE API (OTOMATISASI TUNNEL)      ${RESET}"
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "${YELLOW}📌 CARA MENDAPATKAN ID & TOKEN CLOUDFLARE:${RESET}"
    echo -e "  1. ${GREEN}Account ID & Zone ID${RESET}:"
    echo -e "     • Buka Dashboard Cloudflare (https://dash.cloudflare.com/)"
    echo -e "     • Klik domain Anda -> Scroll bawah di menu 'Overview' sebelah kanan."
    echo -e "  2. ${GREEN}API Token${RESET}:"
    echo -e "     • Buka: https://dash.cloudflare.com/profile/api-tokens"
    echo -e "     • Buat 'Custom Token' dengan Izin (Permissions):"
    echo -e "       - Account | Cloudflare Tunnel | Edit"
    echo -e "       - Zone    | DNS               | Edit"
    echo -e "       - Zone    | Zone              | Read"
    echo -e "${CYAN}--------------------------------------------------------------------${RESET}"
    echo ""

    read -p "Masukkan Cloudflare Account ID [${CF_ACCOUNT_ID:-}]: " INPUT
    CF_ACCOUNT_ID=${INPUT:-${CF_ACCOUNT_ID}}

    read -p "Masukkan Cloudflare Zone ID [${CF_ZONE_ID:-}]: " INPUT
    CF_ZONE_ID=${INPUT:-${CF_ZONE_ID}}

    read -p "Masukkan Cloudflare API Token [${CF_API_TOKEN:-}]: " INPUT
    CF_API_TOKEN=${INPUT:-${CF_API_TOKEN}}

    clear
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "${CYAN}             [4/4] KONFIGURASI AUTO-BACKUP TELEGRAM                 ${RESET}"
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "${YELLOW}📌 CARA MENDAPATKAN TOKEN & CHAT ID TELEGRAM:${RESET}"
    echo -e "  1. ${GREEN}Bot Token${RESET}: Chat @BotFather di Telegram -> kirim /newbot."
    echo -e "     • Salin API Token yang diberikan."
    echo -e "     • ${YELLOW}Wajib klik [START] pada bot baru Anda di Telegram!${RESET}"
    echo -e "  2. ${GREEN}Chat ID${RESET}  : Chat @userinfobot atau @myidbot di Telegram."
    echo -e "     • Salin ID angka milik Anda (misal: 123456789)."
    echo -e "${CYAN}--------------------------------------------------------------------${RESET}"
    echo ""

    read -p "Aktifkan Auto-Backup Harian (y/n)? [${ENABLE_BACKUP:-y}]: " INPUT
    ENABLE_BACKUP=${INPUT:-${ENABLE_BACKUP:-y}}

    if [[ "$ENABLE_BACKUP" =~ ^[Yy]$ ]]; then
        echo ""
        read -p "Masukkan Token Bot Telegram [${TG_BOT_TOKEN:-}]: " INPUT
        TG_BOT_TOKEN=${INPUT:-${TG_BOT_TOKEN}}
        
        read -p "Masukkan Chat ID Telegram [${TG_CHAT_ID:-}]: " INPUT
        TG_CHAT_ID=${INPUT:-${TG_CHAT_ID}}
    fi

    save_config
}

save_config() {
    echo "Menyimpan pengaturan konfigurasi Anda ke $CONFIG_FILE..."
    cat <<EOF > "$CONFIG_FILE"
DB_HOST="$DB_HOST"
DB_USER="$DB_USER"
DB_PASS="$DB_PASS"
DB_NAME="$DB_NAME"
BACKEND_PORT="$BACKEND_PORT"
DOMAIN="$DOMAIN"
CF_PRE_WEB="$CF_PRE_WEB"
CF_PRE_SOCKET="$CF_PRE_SOCKET"
CF_ACCOUNT_ID="$CF_ACCOUNT_ID"
CF_ZONE_ID="$CF_ZONE_ID"
CF_API_TOKEN="$CF_API_TOKEN"
ENABLE_BACKUP="$ENABLE_BACKUP"
TG_BOT_TOKEN="$TG_BOT_TOKEN"
TG_CHAT_ID="$TG_CHAT_ID"
EOF
    chmod 600 "$CONFIG_FILE"
    log_status "Konfigurasi Awal" "SUCCESS" "Pengaturan disimpan ke $CONFIG_FILE"
}

mod_ssh_config() {
    echo "=== Mengonfigurasi /etc/ssh/sshd_config ==="
    if grep -qE "^#?PermitRootLogin" /etc/ssh/sshd_config; then
        sed -i 's/^#\?[[:space:]]*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
    else
        echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
    fi
    if grep -qE "^#?PasswordAuthentication" /etc/ssh/sshd_config; then
        sed -i 's/^#\?[[:space:]]*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    else
        echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
    fi
    systemctl restart ssh || systemctl restart sshd || true
    log_status "Konfigurasi SSH" "SUCCESS" "PermitRootLogin & PasswordAuthentication aktif"
}

mod_fail2ban() {
    echo "=== Menginstal & Mengonfigurasi Fail2ban ==="
    if apt install -y fail2ban; then
        cat <<'EOF' > /etc/fail2ban/jail.local
[DEFAULT]
bantime  = 24h
findtime = 10m
maxretry = 10

[sshd]
enabled  = true
port     = ssh
logpath  = %(sshd_log)s
backend  = %(sshd_backend)s
EOF
        systemctl enable fail2ban && systemctl restart fail2ban
        log_status "Instalasi & Konfigurasi Fail2ban" "SUCCESS" "Fail2ban aktif"
    else
        log_status "Instalasi Fail2ban" "FAILED" "Gagal menginstal paket"
    fi
}

mod_system_update() {
    echo "=== Melakukan Update & Upgrade Sistem ==="
    export DEBIAN_FRONTEND=noninteractive
    apt update && apt upgrade -y
    log_status "Update Sistem" "SUCCESS" "Paket sistem diperbarui"
}

mod_timezone() {
    echo "=== Mengatur Zona Waktu Server ke Asia/Jakarta (UTC+7) ==="

    ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
    export DEBIAN_FRONTEND=noninteractive
    dpkg-reconfigure -f noninteractive tzdata > /dev/null 2>&1
    
    log_status "Pengaturan Timezone" "SUCCESS" "Timezone diset ke Asia/Jakarta (UTC+7)"
}

mod_motd() {
    echo "=== Mengatur Custom MOTD ==="
    chmod -x /etc/update-motd.d/* 2>/dev/null || true
    rm -f /etc/motd 2>/dev/null
    touch /etc/motd

    cat << EOF > /etc/profile.d/99-elektrik-motd.sh
#!/bin/bash
OS_NAME=\$(grep -oP '(?<=^PRETTY_NAME=").*(?=")' /etc/os-release || echo "Linux")
HOST_NAME=\$(hostname)
IP_ADDR=\$(hostname -I | awk '{print \$1}')
clear
CYAN="\e[1;36m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
WHITE="\e[1;37m"
GREY="\e[0;90m"
RESET="\e[0m"
BOLD="\e[1m"

echo -e ""
echo -e "\${CYAN}\${BOLD} ⚡ ELEKTRIK LXC CONTAINER\${RESET}"
echo -e "  Provided by Anjarokz | github.com/ginanjardwibasuki/elektrik"
echo -e ""
echo -e "\${BOLD}  System Information\${RESET}"
echo -e "\${GREY}  ------------------\${RESET}"
echo -e "  OS            : \${CYAN}\${OS_NAME}\${RESET}"
echo -e "  Hostname      : \${CYAN}\${HOST_NAME}\${RESET}"
echo -e "  IP Address    : \${CYAN}\${IP_ADDR}\${RESET}"
echo -e "  Website URL   : \${YELLOW}https://${CF_WEB_NAME}\${RESET}"
echo -e "  Endpoint Node : \${YELLOW}https://${SOCKET_URL}\${RESET}"
echo -e ""
echo -e "\${BOLD}  Quick Commands\${RESET}"
echo -e "\${GREY}  --------------\${RESET}"
echo -e "  \${GREEN}autobackup\${RESET}   \${GREY} ->\${RESET} \${WHITE}Jalankan backup server manual saat ini juga\${RESET}"
echo -e "  \${GREEN}autorestore\${RESET}  \${GREY} ->\${RESET} \${WHITE}Tampilkan instruksi pemulihan data (restore)\${RESET}"
echo -e ""
EOF
    chmod +x /etc/profile.d/99-elektrik-motd.sh
    log_status "Custom MOTD" "SUCCESS" "MOTD dinamis dibuat"
}

mod_dependencies() {
    echo "=== Menginstal Dependencies System, Redis, Cron & Puppeteer ==="
    if apt install -y ca-certificates fonts-liberation libasound2t64 libatk-bridge2.0-0 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 libgcc1 libglib2.0-0 libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 apt-transport-https curl git lsb-release unzip wget xdg-utils gnupg redis-server cron chromium; then
        systemctl enable redis-server && systemctl start redis-server
        systemctl enable cron && systemctl start cron
        log_status "Instalasi Dependensi Dasar" "SUCCESS" "Semua paket pustaka aktif"
    else
        log_status "Instalasi Dependensi Dasar" "FAILED" "Beberapa paket gagal dipasang"
    fi
}

mod_apache_php() {
    echo "=== Menginstal Apache2 & PHP 8.4 Fullset ==="
    apt install -y apache2 lsb-release ca-certificates apt-transport-https curl
    curl -sS https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/php.gpg
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
    apt update
    if apt install -y php8.4 php8.4-cli php8.4-common php8.4-mysql php8.4-zip php8.4-gd php8.4-mbstring php8.4-curl php8.4-xml php8.4-bcmath php8.4-intl libapache2-mod-php8.4; then
        update-alternatives --set php /usr/bin/php8.4 2>/dev/null || true
        apt purge -y php8.5* 2>/dev/null || true
        systemctl restart apache2
        log_status "Instalasi Apache & PHP 8.4" "SUCCESS" "Apache dan PHP 8.4 aktif"
    else
        log_status "Instalasi Apache & PHP 8.4" "FAILED" "Gagal memasang Apache/PHP"
    fi
}

mod_mariadb() {
    echo "=== Menginstal & Mengonfigurasi MariaDB Server ==="
    if apt install -y mariadb-server && systemctl start mariadb && systemctl enable mariadb; then
        mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
        mysql -e "ALTER USER '${DB_USER}'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('${DB_PASS}');" 2>/dev/null || \
        mysql -e "SET PASSWORD FOR '${DB_USER}'@'localhost' = PASSWORD('${DB_PASS}');" 2>/dev/null || \
        mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASS}';"
        mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'${DB_HOST}';"
        mysql -e "FLUSH PRIVILEGES;"
        log_status "Instalasi & Konfigurasi MariaDB" "SUCCESS" "Database ${DB_NAME} siap"
    else
        log_status "Instalasi MariaDB" "FAILED" "Gagal menginstal MariaDB server"
    fi
}

mod_phpmyadmin() {
    echo "=== Menginstal phpMyAdmin ==="
    echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
    echo "phpmyadmin phpmyadmin/app-password-confirm password ${DB_PASS}" | debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/admin-pass password ${DB_PASS}" | debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/app-pass password ${DB_PASS}" | debconf-set-selections
    echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections

    if apt install -y phpmyadmin; then
        if [ -f /etc/phpmyadmin/config-db.php ]; then
            PMA_PASS=$(awk -F"'" '/\$dbpass/{print $2}' /etc/phpmyadmin/config-db.php)
            MYSQL_AUTH="-u${DB_USER} -p${DB_PASS}"
            mysql $MYSQL_AUTH -e "CREATE DATABASE IF NOT EXISTS phpmyadmin;"
            if [ -f /usr/share/phpmyadmin/sql/create_tables.sql ]; then
                mysql $MYSQL_AUTH phpmyadmin < /usr/share/phpmyadmin/sql/create_tables.sql
            fi
            mysql $MYSQL_AUTH -e "DROP USER IF EXISTS 'phpmyadmin'@'localhost';"
            mysql $MYSQL_AUTH -e "CREATE USER 'phpmyadmin'@'localhost' IDENTIFIED BY '${PMA_PASS}';"
            mysql $MYSQL_AUTH -e "GRANT ALL PRIVILEGES ON phpmyadmin.* TO 'phpmyadmin'@'localhost';"
            mysql $MYSQL_AUTH -e "FLUSH PRIVILEGES;"
        fi
        log_status "Instalasi phpMyAdmin" "SUCCESS" "phpMyAdmin aktif"
    else
        log_status "Instalasi phpMyAdmin" "FAILED" "Gagal menginstal phpMyAdmin"
    fi
}

mod_nodejs_pm2() {
    echo "=== Menginstal Node.js & PM2 ==="
    apt remove -y nodejs npm nodejs-doc 2>/dev/null
    NODE_VERSION="v20.20.2"
    NPM_VERSION="10.8.2"
    ARCH="x64"

    cd /tmp
    if wget https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-${ARCH}.tar.xz && \
       tar -xf node-${NODE_VERSION}-linux-${ARCH}.tar.xz && \
       cp -r node-${NODE_VERSION}-linux-${ARCH}/* /usr/local/ && \
       npm install -g npm@${NPM_VERSION}; then
        log_status "Instalasi Node.js & NPM" "SUCCESS" "Node ${NODE_VERSION} & NPM terpasang"
    else
        log_status "Instalasi Node.js & NPM" "FAILED" "Gagal mengunduh Node.js"
        return 1
    fi

    if npm install -g pm2; then
        log_status "Instalasi PM2" "SUCCESS" "PM2 berhasil dipasang global"
    else
        log_status "Instalasi PM2" "FAILED" "Gagal menginstal PM2"
    fi
}

mod_app_deploy() {
    echo "=== Melakukan Git Clone & Setup Project ==="
    mkdir -p /var/www
    cd /var/www

    if [ -d "elektrik" ]; then
        echo -e "${YELLOW}⚠️ Peringatan: Folder /var/www/elektrik sudah ada!${RESET}"
        read -p "Hapus folder lama & clone ulang? (y/n) [n]: " CONFIRM_CLONE
        CONFIRM_CLONE=${CONFIRM_CLONE:-n}
        if [[ "$CONFIRM_CLONE" =~ ^[Yy]$ ]]; then
            rm -rf elektrik
            git clone https://github.com/ginanjardwibasuki/elektrik.git elektrik
            log_status "Git Clone" "SUCCESS" "Folder lama dihapus, clone repository berhasil."
        else
            cd elektrik && git pull
            cd /var/www
            log_status "Git Pull" "SUCCESS" "Repositori diperbarui (pull)."
        fi
    else
        git clone https://github.com/ginanjardwibasuki/elektrik.git elektrik
        log_status "Git Clone" "SUCCESS" "Clone repository berhasil."
    fi

    BACKEND_DIR="/var/www/elektrik/backend"
    TARGET_FILE="/var/www/elektrik/helper/koneksi.php"
    mkdir -p "$(dirname "$TARGET_FILE")"
    cat <<EOF > "$TARGET_FILE"
<?php
\$host = '$DB_HOST';
\$username = '$DB_USER';
\$password = '$DB_PASS';
\$database = '$DB_NAME';

try {
    \$db = mysqli_connect(\$host, \$username, \$password, \$database);
    \$db->set_charset('utf8mb4');
} catch (\Throwable \$th) {
    throw \$th;
}
EOF

    # Setup initial database
    if [ -f "/var/www/elektrik/db/initial.sql" ]; then
        if mysql -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" < "/var/www/elektrik/db/initial.sql"; then
            log_status "Import Initial DB" "SUCCESS" "Database initial.sql berhasil diimpor"
        else
            log_status "Import Initial DB" "FAILED" "Gagal mengimpor initial.sql"
        fi
    else
        log_status "Import Initial DB" "FAILED" "File initial.sql tidak ditemukan"
    fi

    TARGET_ENV="$BACKEND_DIR/.env"
    mkdir -p "$(dirname "$TARGET_ENV")"
    cat <<EOF > "$TARGET_ENV"
DB_HOST=$DB_HOST
DB_USER=$DB_USER
DB_PASS=$DB_PASS
DB_NAME=$DB_NAME
PORT=$BACKEND_PORT
SOCKET_URL=https://$SOCKET_URL
EOF

    TARGET_JS_CONFIG="/var/www/elektrik/pages/assets/js/config.js"
    mkdir -p "$(dirname "$TARGET_JS_CONFIG")"
    cat <<EOF > "$TARGET_JS_CONFIG"
const CONFIG = {
    SOCKET_URL: "https://$SOCKET_URL"
};
EOF

    TARGET_URL_CONFIG="/var/www/elektrik/helper/url_config.php"
    mkdir -p "$(dirname "$TARGET_URL_CONFIG")"
    cat <<EOF > "$TARGET_URL_CONFIG"
<?php
define('SOCKET_URL', 'https://$SOCKET_URL');
EOF

    log_status "Konfigurasi File Proyek" "SUCCESS" "File config, koneksi, & .env dibuat"

    echo "=== Mengatur Kepemilikan & Izin Folder Gambar ==="
    mkdir -p /var/www/elektrik/gambar
    chown -R www-data:www-data /var/www/elektrik/gambar
    chmod -R 755 /var/www/elektrik/gambar
    log_status "Setup Folder Gambar" "SUCCESS" "Ownership www-data & permissions 755 diterapkan"

    cd "$BACKEND_DIR"
    if [ -f "package.json" ]; then
		export PUPPETEER_SKIP_DOWNLOAD=true
        if npm install; then
            log_status "NPM Install Backend" "SUCCESS" "Dependensi Node.js terinstal"
        else
            log_status "NPM Install Backend" "FAILED" "Gagal menjalankan npm install"
        fi
        if pm2 start server.js --name "elektrik-backend" && pm2 save && pm2 startup; then
            log_status "PM2 Process Execution" "SUCCESS" "Server backend berjalan di PM2"
        else
            log_status "PM2 Process Execution" "FAILED" "Gagal menjalankan server.js dengan PM2"
        fi
    else
        log_status "NPM Install Backend" "FAILED" "package.json tidak ditemukan"
    fi
}

mod_apache_vhost() {
    echo "=== Konfigurasi Apache VirtualHost ==="
    cat << EOF > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerName ${CF_WEB_NAME}
    DocumentRoot /var/www/elektrik

    <Directory /var/www/elektrik>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/elektrik_error.log
    CustomLog \${APACHE_LOG_DIR}/elektrik_access.log combined
</VirtualHost>
EOF
    if systemctl restart apache2; then
        chown -R www-data:www-data /var/www/elektrik
        mkdir -p /var/www/elektrik/gambar
        chown -R www-data:www-data /var/www/elektrik/gambar
        chmod -R 775 /var/www/elektrik/gambar
        log_status "Apache VirtualHost" "SUCCESS" "VirtualHost ${CF_WEB_NAME} diterapkan"
    else
        log_status "Apache VirtualHost" "FAILED" "Gagal menerapkan Apache config"
    fi
}

mod_cloudflare_tunnel() {
    echo "=== Otomasi Cloudflare Tunnel via API ==="
    if curl -L --output /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && chmod +x /usr/local/bin/cloudflared; then
        TUNNEL_NAME="elektrik-tunnel-$(date +%s)"
        SECRET_JSON_B64=$(dd if=/dev/urandom bs=32 count=1 status=none | base64)

        echo "Membuat tunnel baru via API Cloudflare..."
        CF_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/cfd_tunnel" \
             -H "Authorization: Bearer ${CF_API_TOKEN}" \
             -H "Content-Type: application/json" \
             --data "{\"name\":\"${TUNNEL_NAME}\", \"tunnel_secret\":\"${SECRET_JSON_B64}\", \"config_src\": \"cloudflare\"}")
        TUNNEL_ID=$(echo "$CF_RESPONSE" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

        if [ -n "$TUNNEL_ID" ]; then
            SUB_WEB="${CF_PRE_WEB}"
            SUB_NODE="${CF_PRE_SOCKET}"

            setup_cloudflare_dns() {
                local RECORD_NAME=$1
                local FULL_DOMAIN=$2
                local TUNNEL_TARGET="$3"
                local GET_RECORD=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records?name=${FULL_DOMAIN}&type=CNAME" \
                     -H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json")
                local RECORD_ID=$(echo "$GET_RECORD" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
                
                if [ -n "$RECORD_ID" ] && [ "$RECORD_ID" != "null" ]; then
                    curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${RECORD_ID}" \
                         -H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json" > /dev/null
                fi
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records" \
                     -H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json" \
                     --data "{\"type\":\"CNAME\",\"name\":\"${RECORD_NAME}\",\"content\":\"${TUNNEL_TARGET}\",\"proxied\":true}" > /dev/null
            }

            setup_cloudflare_dns "${SUB_WEB}" "${CF_WEB_NAME}" "${TUNNEL_ID}.cfargotunnel.com"
            setup_cloudflare_dns "${SUB_NODE}" "${SOCKET_URL}" "${TUNNEL_ID}.cfargotunnel.com"

            echo "Mengirim Konfigurasi Ingress ke Cloudflare..."
            curl -s -X PUT "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/cfd_tunnel/${TUNNEL_ID}/configurations" \
                 -H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json" \
                 --data "{\"config\": {\"ingress\": [{\"hostname\": \"${CF_WEB_NAME}\", \"service\": \"http://localhost:80\"},{\"hostname\": \"${SOCKET_URL}\", \"service\": \"http://localhost:${BACKEND_PORT}\"},{\"service\": \"http_status:404\"}]}}" > /dev/null

            TOKEN_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/cfd_tunnel/${TUNNEL_ID}/token" \
                 -H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json")
            TUNNEL_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"result":"[^"]*' | head -1 | cut -d'"' -f4)

            if [ -n "$TUNNEL_TOKEN" ] && [ "$TUNNEL_TOKEN" != "null" ]; then
                rm -rf /etc/cloudflared/config.yml 2>/dev/null
                rm -rf /root/.cloudflared 2>/dev/null
                cloudflared service uninstall > /dev/null 2>&1 || true
                if cloudflared service install "${TUNNEL_TOKEN}" > /dev/null 2>&1; then
                    log_status "Cloudflare Tunnel API" "SUCCESS" "Tunnel aktif & CNAME terdaftar"
                else
                    log_status "Cloudflare Tunnel API" "FAILED" "Gagal menjalankan cloudflared install"
                fi
            else
                log_status "Cloudflare Tunnel API" "FAILED" "Gagal mendapatkan Tunnel Token"
            fi
        else
            log_status "Cloudflare Tunnel API" "FAILED" "Gagal membuat Tunnel via API Cloudflare"
        fi
    else
        log_status "Cloudflare Tunnel API" "FAILED" "Gagal mengunduh binary cloudflared"
    fi
}

mod_backup_restore() {
    echo "=== Membuat Script Auto-Backup & Auto-Restore ==="
    cat << EOF > /usr/local/bin/autobackup
#!/bin/bash
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'
ERROR_COUNT=0

show_progress() {
    local pid=\$1
    local message=\$2
    local spin='-\|/'
    local i=0
    tput civis
    while kill -0 "\$pid" 2>/dev/null; do
        i=\$(( (i+1) % 4 ))
        printf "\r\${CYAN}[%c]\${NC} %s..." "\${spin:\$i:1}" "\$message"
        sleep 0.1
    done
    wait "\$pid"
    local status=\$?
    if [ "\$status" -eq 0 ]; then
        printf "\r\${GREEN}[✓]\${NC} %-50s\n" "\$message Selesai!"
    else
        printf "\r\${RED}[✗]\${NC} %-50s\n" "\$message Gagal!"
        ERROR_COUNT=\$((ERROR_COUNT + 1))
    fi
    tput cnorm
}

BACKUP_DIR="/root/elektrik_backups"
DATE=\$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_NAME="elektrik_backup_\$DATE"
ARCHIVE_FILE="\$BACKUP_DIR/\$BACKUP_NAME.tar.gz"
MYSQL_ERROR_LOG="/tmp/mysql_error_\$DATE.log"
DB_USER="${DB_USER}"
DB_PASS="${DB_PASS}"
DB_NAME="${DB_NAME}"
TG_BOT_TOKEN="${TG_BOT_TOKEN}"
TG_CHAT_ID="${TG_CHAT_ID}"

clear
echo -e "\${CYAN}================================================\${NC}"
echo -e "\${CYAN}      MEMULAI PROSES BACKUP SERVER ELEKTRIK     \${NC}"
echo -e "\${CYAN}================================================\${NC}"
echo ""

mkdir -p "\$BACKUP_DIR"
TMP_DIR="/tmp/\$BACKUP_NAME"
mkdir -p "\$TMP_DIR"

if [ -d "/var/www/elektrik/gambar" ]; then
    (cp -r /var/www/elektrik/gambar "\$TMP_DIR/") &
    show_progress \$! "Menyalin file direktori gambar"
else
    mkdir -p "\$TMP_DIR/gambar"
fi

(mysqldump -u"\$DB_USER" -p"\$DB_PASS" "\$DB_NAME" > "\$TMP_DIR/database.sql" 2> "\$MYSQL_ERROR_LOG") &
show_progress \$! "Mengekspor database MySQL"

cd "\$TMP_DIR" || exit
(tar -czf "\$ARCHIVE_FILE" gambar/ database.sql 2>/dev/null) &
show_progress \$! "Mengkompresi file menjadi .tar.gz"

rm -rf "\$TMP_DIR"
cd /root || exit

if [ -n "\$TG_BOT_TOKEN" ] && [ -n "\$TG_CHAT_ID" ]; then
    if [ -f "\$ARCHIVE_FILE" ]; then
        FILE_SIZE=\$(stat -c%s "\$ARCHIVE_FILE" 2>/dev/null || echo 0)
        if [ "\$FILE_SIZE" -le 52428800 ]; then
            (curl -s -F document=@"\$ARCHIVE_FILE" "https://api.telegram.org/bot\$TG_BOT_TOKEN/sendDocument" -F chat_id="\$TG_CHAT_ID" -F caption="✅ Berhasil: Backup Harian Server Elektrik (\$(date +%F))" > /dev/null) &
            show_progress \$! "Mengirim file backup ke Telegram"
        else
            (curl -s -X POST "https://api.telegram.org/bot\$TG_BOT_TOKEN/sendMessage" -d chat_id="\$TG_CHAT_ID" -d text="⚠️️ Backup Server berhasil lokal, tapi gagal dikirim via Telegram krn ukuran >50MB." > /dev/null) &
            show_progress \$! "Mengirim notifikasi limit ke Telegram"
        fi
    else
        echo -e "\${RED}[✗] File arsip tidak ditemukan, pengiriman Telegram dibatalkan.\${NC}"
        ERROR_COUNT=\$((ERROR_COUNT + 1))
    fi
else
    echo -e "\${YELLOW}[!] Pengiriman Telegram dilewati (Token/Chat ID kosong)\${NC}"
fi

(find "\$BACKUP_DIR" -type f -name "elektrik_backup_*.tar.gz" ! -name "\$BACKUP_NAME.tar.gz" -mtime +7 -exec rm -f {} +) &
show_progress \$! "Membersihkan file backup versi lama"

echo ""
if [ "\$ERROR_COUNT" -eq 0 ]; then
    echo -e "\${GREEN}================================================\${NC}"
    echo -e "\${GREEN}  [✓] SEMUA PROSES BACKUP BERHASIL DISELESAIKAN \${NC}"
    echo -e "\${GREEN}================================================\${NC}"
else
    echo -e "\${RED}================================================\${NC}"
    echo -e "\${RED}  [!] BACKUP SELESAI DENGAN \$ERROR_COUNT ERROR / KESALAHAN \${NC}"
    echo -e "\${RED}================================================\${NC}"
    if [ -s "\$MYSQL_ERROR_LOG" ]; then
        echo -e "\${YELLOW}Detail Error Database MySQL:\${NC}"
        cat "\$MYSQL_ERROR_LOG"
    fi
fi
rm -f "\$MYSQL_ERROR_LOG" 2>/dev/null
EOF

    cat << EOF > /usr/local/bin/autorestore
#!/bin/bash
BACKUP_FILE=\$1
DB_USER="${DB_USER}"
DB_PASS="${DB_PASS}"
DB_NAME="${DB_NAME}"

if [ -z "\$BACKUP_FILE" ]; then
    echo "❌ CARA PENGGUNAAN: autorestore /path/ke/file_backup.tar.gz"
    echo "📂 Daftar Backup Tersedia di /root/elektrik_backups/ :"
    ls -lh /root/elektrik_backups/
    exit 1
fi

if [ ! -f "\$BACKUP_FILE" ]; then
    echo "❌ File \$BACKUP_FILE tidak ditemukan!"
    exit 1
fi

echo "Memulai Proses Restore Data..."
TMP_DIR="/tmp/elektrik_restore_\$\$"
mkdir -p "\$TMP_DIR"
tar -xzf "\$BACKUP_FILE" -C "\$TMP_DIR"

if [ -d "\$TMP_DIR/gambar" ]; then
    rm -rf /var/www/elektrik/gambar/*
    mkdir -p /var/www/elektrik/gambar
    cp -r "\$TMP_DIR/gambar/"* /var/www/elektrik/gambar/ 2>/dev/null
    chown -R www-data:www-data /var/www/elektrik/gambar
    chmod -R 775 /var/www/elektrik/gambar
    echo "✔ Gambar berhasil dipulihkan."
fi

if [ -f "\$TMP_DIR/database.sql" ]; then
    mysql -u"\$DB_USER" -p"\$DB_PASS" "\$DB_NAME" < "\$TMP_DIR/database.sql"
    echo "✔ Database berhasil dipulihkan."
fi
rm -rf "\$TMP_DIR"
echo "✅ RESTORE SELESAI!"
EOF

    chmod +x /usr/local/bin/autobackup
    chmod +x /usr/local/bin/autorestore
    log_status "Sistem Backup & Restore" "SUCCESS" "Script autobackup & autorestore dibuat"

    if [[ "$ENABLE_BACKUP" =~ ^[Yy]$ ]]; then
        (crontab -l 2>/dev/null | grep -v "/usr/local/bin/autobackup"; echo "0 2 * * * /usr/local/bin/autobackup") | crontab -
        log_status "Jadwal Cron Backup" "SUCCESS" "Backup harian diaktifkan"
    fi
}

main() {
    check_root
    init_logging
    load_config
    mod_ssh_config
    prompt_config
    mod_fail2ban
    mod_system_update
    mod_timezone
    mod_motd
    mod_dependencies
    mod_apache_php
    mod_mariadb
    mod_phpmyadmin
    mod_nodejs_pm2
    mod_app_deploy
    mod_apache_vhost
    mod_cloudflare_tunnel
    mod_backup_restore

    echo "==================================================================" >> "$REPORT_FILE"
    echo "=== PROSES AUTOINSTALL SELESAI! ===" >> "$REPORT_FILE"
    cp "$REPORT_FILE" "$SYSTEM_REPORT_FILE"

    clear
    echo "=================================================================="
    echo "                    LAPORAN RESUME INSTALASI SERVER               "
    echo "=================================================================="
    cat "$REPORT_FILE"
    echo "=================================================================="
    echo "📁 CARA MENGGUNAKAN BACKUP/RESTORE MANUAL:"
    echo " - Ketik 'autobackup' di terminal untuk membackup kapan saja."
    echo " - Ketik 'autorestore' untuk melihat cara memulihkan data."
    echo "=================================================================="
}
main "$@"
EOF_MASTER_INJECT

# ------------------------------------------------------------------------------
# BAGIAN 4: PUSH & JALANKAN SCRIPT DI DALAM LXC
# ------------------------------------------------------------------------------
echo "[INFO] Mengirim file autoinstaller ke dalam LXC..."
pct push $VMID /tmp/install_elektrik_${VMID}.sh /root/install_elektrik.sh
pct exec $VMID -- chmod +x /root/install_elektrik.sh

echo "[INFO] Memulai proses instalasi interaktif di dalam LXC..."
sleep 2

# Mengeksekusi script instalasi di dalam LXC, mengikat terminal (tty)
lxc-attach -n $VMID -- /root/install_elektrik.sh

# ------------------------------------------------------------------------------
# BAGIAN 5: CLEANUP
# ------------------------------------------------------------------------------
echo "[INFO] Membersihkan file instalasi sementara..."
rm -f /tmp/install_elektrik_${VMID}.sh
pct exec $VMID -- rm -f /root/install_elektrik.sh

echo "====================================================="
echo "✅ SELURUH PROSES (PROXMOX -> LXC -> WEB STACK) SELESAI!"
echo "   Silakan masuk ke container menggunakan perintah:"
echo "   pct enter $VMID"
echo "====================================================="