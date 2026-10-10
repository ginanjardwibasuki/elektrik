#!/bin/bash
# ==============================================================================
#   ⚡ ELEKTRIK STACK INSTALLER - Standalone LXC Edition
#   Version : 2.0.1
#   Target  : Debian 13 (LXC container, root access)
#   Usage   : bash install_elektrik.sh
#   Feature : Idempotent, Enterprise UI, Multi-Run Safe
# ==============================================================================

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

SCRIPT_VERSION="2.0.1"
CONFIG_DIR="/root/config"
CONFIG_FILE="${CONFIG_DIR}/elektrik.conf"
MARKER_FILE="${CONFIG_DIR}/.elektrik_installed"
LOG_DIR="/root/logs"
REPORT_FILE="${LOG_DIR}/install_report.log"
OUTPUT_LOG_FILE="${LOG_DIR}/install_output.log"
WEB_DIR="/var/www/elektrik"
BACKEND_DIR="${WEB_DIR}/backend"
GIT_REPO="https://github.com/ginanjardwibasuki/elektrik.git"

mkdir -p "${CONFIG_DIR}" "${LOG_DIR}"
chmod 700 "${CONFIG_DIR}"

# ─── Colors ───────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
    BOLD="\e[1m"; DIM="\e[2m"; RED="\e[1;31m"; GREEN="\e[1;32m"; YELLOW="\e[1;33m"
    BLUE="\e[1;34m"; MAGENTA="\e[1;35m"; CYAN="\e[1;36m"; WHITE="\e[1;37m"
    GREY="\e[0;90m"; RESET="\e[0m"
else
    BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; MAGENTA=""; CYAN=""; WHITE=""; GREY=""; RESET=""
fi

# ─── UI Library ───────────────────────────────────────────────────────────────
ui_banner() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}                                                                          ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}   ${BOLD}${WHITE}⚡ ELEKTRIK STACK INSTALLER${RESET}   ${GREY}Standalone LXC Edition${RESET}             ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}   ${GREY}Version ${SCRIPT_VERSION}  •  Idempotent Multi-Run Deployment${RESET}             ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}                                                                          ${CYAN}║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════╝${RESET}"
}
ui_section() {
    echo ""
    echo -e "${BLUE}┌──────────────────────────────────────────────────────────────────────────┐${RESET}"
    printf "${BLUE}│${RESET} ${BOLD}${WHITE}[%s] %-68s${RESET} ${BLUE}│${RESET}\n" "$1" "$2"
    echo -e "${BLUE}└──────────────────────────────────────────────────────────────────────────┘${RESET}"
}
ui_info()    { printf "  ${BLUE}ℹ${RESET}  %s\n" "$1"; }
ui_step()    { printf "  ${MAGENTA}➜${RESET}  %s\n" "$1"; }
ui_ok()      { printf "  ${GREEN}✔${RESET}  %s\n" "$1"; }
ui_skip()    { printf "  ${YELLOW}○${RESET}  %s ${GREY}(sudah ada, dilewati)${RESET}\n" "$1"; }
ui_warn()    { printf "  ${YELLOW}⚠${RESET}  %s\n" "$1"; }
ui_fail()    { printf "  ${RED}✖${RESET}  %s\n" "$1"; }
ui_divider() { echo -e "${GREY}  ────────────────────────────────────────────────────────────────────${RESET}"; }
ui_input() {
    local prompt="$1" default="$2" var
    if [ -n "$default" ]; then
        printf "  ${CYAN}▸${RESET}  %s ${GREY}[%s]${RESET}: " "$prompt" "$default" >&2
        read var; echo "${var:-$default}"
    else
        printf "  ${CYAN}▸${RESET}  %s: " "$prompt" >&2
        read var; echo "$var"
    fi
}
ui_password() {
    local prompt="$1" var
    printf "  ${CYAN}▸${RESET}  %s: " "$prompt" >&2
    read -s var; echo "" >&2; echo "$var"
}

# ─── Helpers ──────────────────────────────────────────────────────────────────
pkg_installed() { dpkg -l "$1" 2>/dev/null | grep -q "^ii"; }
cmd_exists()    { command -v "$1" >/dev/null 2>&1; }

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Script ini harus dijalankan sebagai root.${RESET}"; exit 1
    fi
}

check_debian() {
    if [ ! -f /etc/os-release ]; then
        ui_fail "Tidak bisa mendeteksi OS."; exit 1
    fi
    . /etc/os-release
    ui_info "OS terdeteksi: ${PRETTY_NAME}"
}

check_internet() {
    ui_info "Memeriksa koneksi internet..."
    local ok=0
    for i in {1..15}; do
        if ping -c 1 -W 1 deb.debian.org >/dev/null 2>&1; then
            ui_ok "Internet terhubung (${i}s)"; ok=1; break
        fi
        sleep 1
    done
    if [ "$ok" -eq 0 ]; then
        ui_fail "Tidak ada koneksi internet. Periksa jaringan container."; exit 1
    fi
}

init_logging() {
    exec > >(tee -a "$OUTPUT_LOG_FILE") 2>&1
    {
        echo "══════════════════════════════════════════════════════════════════"
        echo "   LAPORAN RESUME INSTALASI SERVER ELEKTRIK"
        echo "   Waktu    : $(date)"
        echo "   Versi    : $SCRIPT_VERSION"
        echo "   Mode     : ${MODE:-fresh}"
        echo "   Host     : $(hostname)"
        echo "══════════════════════════════════════════════════════════════════"
    } > "$REPORT_FILE"
}

log_status() {
    local step="$1" status="$2" detail="$3" entry=""
    case "$status" in
        SUCCESS) entry="✔ [OK]      $step - $detail" ;;
        SKIPPED) entry="○ [SKIP]    $step - $detail" ;;
        UPDATED) entry="↻ [UPDATE]  $step - $detail" ;;
        *)       entry="✖ [FAILED]  $step - $detail" ;;
    esac
    echo "$entry" >> "$REPORT_FILE"
}

detect_prior_install() { [ -f "$MARKER_FILE" ]; }

show_prior_install_info() {
    # shellcheck disable=SC1090
    source "$MARKER_FILE" 2>/dev/null || true
    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}║${RESET}  ${BOLD}⚠  INSTALASI SEBELUMNYA TERDETEKSI${RESET}                                      ${YELLOW}║${RESET}"
    echo -e "${YELLOW}╠══════════════════════════════════════════════════════════════════════════╣${RESET}"
    printf "${YELLOW}║${RESET}  Versi Terpasang : ${WHITE}%-54s${RESET} ${YELLOW}║${RESET}\n" "${MARKER_VERSION:-unknown}"
    printf "${YELLOW}║${RESET}  Tanggal Install : ${WHITE}%-54s${RESET} ${YELLOW}║${RESET}\n" "${MARKER_DATE:-unknown}"
    printf "${YELLOW}║${RESET}  Config File     : ${WHITE}%-54s${RESET} ${YELLOW}║${RESET}\n" "$CONFIG_FILE"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════════════════╝${RESET}"
}

select_mode() {
    echo ""
    echo -e "${CYAN}  Pilih mode operasi:${RESET}"
    echo ""
    echo -e "   ${GREEN}[1]${RESET} ${BOLD}Upgrade${RESET}       ${GREY}– Update komponen, pertahankan data & config${RESET} ${YELLOW}(Rekomendasi)${RESET}"
    echo -e "   ${GREEN}[2]${RESET} ${BOLD}Config Only${RESET}   ${GREY}– Hanya ubah konfigurasi (kredensial, domain, dll)${RESET}"
    echo -e "   ${GREEN}[3]${RESET} ${BOLD}Fresh Install${RESET} ${GREY}– Instalasi ulang dari awal (backup config lama)${RESET}"
    echo -e "   ${GREEN}[4]${RESET} ${BOLD}Cancel${RESET}        ${GREY}– Keluar tanpa melakukan apapun${RESET}"
    echo ""
    local choice=$(ui_input "Pilih [1-4]" "1")
    case "$choice" in
        1) MODE="upgrade" ;;
        2) MODE="config" ;;
        3) MODE="fresh" ;;
        4) echo "Dibatalkan."; exit 0 ;;
        *) MODE="upgrade" ;;
    esac
}

save_marker() {
    cat > "$MARKER_FILE" <<EOF
MARKER_VERSION="$SCRIPT_VERSION"
MARKER_DATE="$(date '+%Y-%m-%d %H:%M:%S')"
MARKER_MODE="$MODE"
EOF
    chmod 600 "$MARKER_FILE"
}

# ─── Config Management ────────────────────────────────────────────────────────
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        # shellcheck disable=SC1090
        source "$CONFIG_FILE"
        return 0
    fi
    return 1
}

save_config() {
    cat > "$CONFIG_FILE" <<EOF
# ELEKTRIK STACK CONFIGURATION
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# Version: $SCRIPT_VERSION
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
}

prompt_config() {
    ui_section "1/4" "KONFIGURASI DATABASE & APLIKASI"
    ui_info "Host/User default: localhost/root (tekan Enter untuk default)"
    ui_info "Password DB disembunyikan; Port backend default 2083"
    ui_divider
    local INPUT
    INPUT=$(ui_input "Database Host" "${DB_HOST:-localhost}"); DB_HOST="$INPUT"
    INPUT=$(ui_input "Database Username" "${DB_USER:-root}"); DB_USER="$INPUT"
    INPUT=$(ui_password "Database Password [***]"); [ -n "$INPUT" ] && DB_PASS="$INPUT"
    INPUT=$(ui_input "Database Name" "${DB_NAME:-elektrik}"); DB_NAME="$INPUT"
    INPUT=$(ui_input "Port Backend Node.js" "${BACKEND_PORT:-2083}"); BACKEND_PORT="$INPUT"

    ui_section "2/4" "KONFIGURASI DOMAIN & URL"
    ui_info "Masukkan domain tanpa http:// atau https://"
    ui_divider
    INPUT=$(ui_input "Domain Utama" "${DOMAIN:-}"); DOMAIN="$INPUT"
    INPUT=$(ui_input "Subdomain Website" "${CF_PRE_WEB:-elektrik}"); CF_PRE_WEB="$INPUT"
    INPUT=$(ui_input "Subdomain Backend/Socket" "${CF_PRE_SOCKET:-api}"); CF_PRE_SOCKET="$INPUT"
    CF_WEB_NAME="${CF_PRE_WEB}.${DOMAIN}"
    SOCKET_URL="${CF_PRE_SOCKET}.${DOMAIN}"
    CF_ROOT_DOMAIN="${DOMAIN}"

    ui_section "3/4" "KONFIGURASI CLOUDFLARE API"
    ui_info "Dashboard: dash.cloudflare.com | Token: profile/api-tokens"
    ui_info "Permission: Account|Tunnel|Edit, Zone|DNS|Edit, Zone|Zone|Read"
    ui_divider
    INPUT=$(ui_input "Cloudflare Account ID" "${CF_ACCOUNT_ID:-}"); CF_ACCOUNT_ID="$INPUT"
    INPUT=$(ui_input "Cloudflare Zone ID" "${CF_ZONE_ID:-}"); CF_ZONE_ID="$INPUT"
    INPUT=$(ui_password "Cloudflare API Token [***]"); [ -n "$INPUT" ] && CF_API_TOKEN="$INPUT"

    ui_section "4/4" "AUTO-BACKUP TELEGRAM"
    ui_info "Bot: @BotFather (/newbot)  |  Chat ID: @userinfobot"
    ui_divider
    INPUT=$(ui_input "Aktifkan Auto-Backup Harian (y/n)" "${ENABLE_BACKUP:-y}"); ENABLE_BACKUP="$INPUT"
    if [[ "$ENABLE_BACKUP" =~ ^[Yy]$ ]]; then
        INPUT=$(ui_input "Token Bot Telegram" "${TG_BOT_TOKEN:-}"); TG_BOT_TOKEN="$INPUT"
        INPUT=$(ui_input "Chat ID Telegram" "${TG_CHAT_ID:-}"); TG_CHAT_ID="$INPUT"
    fi

    save_config
    log_status "Konfigurasi" "SUCCESS" "Disimpan ke $CONFIG_FILE"
    ui_ok "Konfigurasi tersimpan di $CONFIG_FILE"
}

# ─── Modules ──────────────────────────────────────────────────────────────────
mod_ssh_config() {
    ui_section "01" "Konfigurasi SSH Daemon"
    local changed=0
    if grep -qE "^#?PermitRootLogin" /etc/ssh/sshd_config 2>/dev/null; then
        sed -i 's/^#\?[[:space:]]*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config; changed=1
    else
        echo "PermitRootLogin yes" >> /etc/ssh/sshd_config; changed=1
    fi
    if grep -qE "^#?PasswordAuthentication" /etc/ssh/sshd_config 2>/dev/null; then
        sed -i 's/^#\?[[:space:]]*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config; changed=1
    else
        echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config; changed=1
    fi
    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true
    if [ "$changed" -eq 1 ]; then
        ui_ok "SSH dikonfigurasi (PermitRootLogin + PasswordAuth)"
        log_status "SSH Config" "SUCCESS" "Konfigurasi diterapkan"
    else
        ui_skip "SSH sudah terkonfigurasi"
        log_status "SSH Config" "SKIPPED" "Sudah aktif"
    fi
}

mod_fail2ban() {
    ui_section "02" "Fail2ban (Brute-force Protection)"
    if pkg_installed fail2ban; then
        ui_skip "Paket fail2ban sudah terpasang"
    else
        ui_step "Menginstal fail2ban..."
        apt install -y fail2ban >/dev/null 2>&1 || true
    fi
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
    systemctl enable fail2ban >/dev/null 2>&1 || true
    systemctl restart fail2ban 2>/dev/null || true
    ui_ok "Fail2ban aktif"
    log_status "Fail2ban" "SUCCESS" "Konfigurasi diterapkan"
}

mod_system_update() {
    ui_section "03" "Update & Upgrade Sistem"
    ui_step "Menjalankan apt update && apt upgrade..."
    export DEBIAN_FRONTEND=noninteractive
    apt update -qq && apt upgrade -y -qq
    ui_ok "Paket sistem diperbarui"
    log_status "System Update" "SUCCESS" "Selesai"
}

mod_timezone() {
    ui_section "04" "Zona Waktu Server"
    local current_tz=$(timedatectl show --property=Timezone --value 2>/dev/null || readlink /etc/localtime | sed 's|.*/zoneinfo/||')
    if [ "$current_tz" = "Asia/Jakarta" ]; then
        ui_skip "Timezone sudah Asia/Jakarta"
        log_status "Timezone" "SKIPPED" "Sudah benar"
        return
    fi
    ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
    export DEBIAN_FRONTEND=noninteractive
    dpkg-reconfigure -f noninteractive tzdata > /dev/null 2>&1
    ui_ok "Timezone diset ke Asia/Jakarta (UTC+7)"
    log_status "Timezone" "SUCCESS" "Asia/Jakarta"
}

mod_motd() {
    ui_section "05" "Custom MOTD (Login Banner)"
    chmod -x /etc/update-motd.d/* 2>/dev/null || true
    rm -f /etc/motd 2>/dev/null
    touch /etc/motd

    cat << 'EOF' > /etc/profile.d/99-elektrik-motd.sh
#!/bin/bash
# Dynamic MOTD - reads live config
if [ -f /root/config/elektrik.conf ]; then
    source /root/config/elektrik.conf
fi

OS_NAME=$(grep -oP '(?<=^PRETTY_NAME=").*(?=")' /etc/os-release 2>/dev/null || echo "Linux")
HOST_NAME=$(hostname)
IP_ADDR=$(hostname -I | awk '{print $1}')
UPTIME=$(uptime -p 2>/dev/null | sed 's/up //')
LOAD=$(cut -d' ' -f1-3 /proc/loadavg)

CYAN="\e[1;36m"; GREEN="\e[1;32m"; YELLOW="\e[1;33m"; WHITE="\e[1;37m"
GREY="\e[0;90m"; RESET="\e[0m"; BOLD="\e[1m"

clear
echo -e ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${RESET}   ${BOLD}${WHITE}⚡ ELEKTRIK LXC CONTAINER${RESET}                                                ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET}   ${GREY}Powered by Anjarokz  •  github.com/ginanjardwibasuki/elektrik${RESET}         ${CYAN}║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════╝${RESET}"
echo -e ""
echo -e "  ${BOLD}${WHITE}▎ SYSTEM INFORMATION${RESET}"
echo -e "  ${GREY}──────────────────────────────────────────────────────────────────────${RESET}"
printf "  ${GREY}│${RESET} %-14s ${CYAN}%s${RESET}\n" "OS"         "$OS_NAME"
printf "  ${GREY}│${RESET} %-14s ${CYAN}%s${RESET}\n" "Hostname"   "$HOST_NAME"
printf "  ${GREY}│${RESET} %-14s ${CYAN}%s${RESET}\n" "IP Address" "$IP_ADDR"
printf "  ${GREY}│${RESET} %-14s ${CYAN}%s${RESET}\n" "Uptime"     "${UPTIME:-n/a}"
printf "  ${GREY}│${RESET} %-14s ${CYAN}%s${RESET}\n" "Load Avg"   "$LOAD"
echo -e ""
echo -e "  ${BOLD}${WHITE}▎ APPLICATION ENDPOINTS${RESET}"
echo -e "  ${GREY}──────────────────────────────────────────────────────────────────────${RESET}"
printf "  ${GREY}│${RESET} %-14s ${YELLOW}https://%s${RESET}\n" "Website"    "$CF_WEB_NAME"
printf "  ${GREY}│${RESET} %-14s ${YELLOW}https://%s${RESET}\n" "API/Socket" "$SOCKET_URL"
echo -e ""
echo -e "  ${BOLD}${WHITE}▎ QUICK COMMANDS${RESET}"
echo -e "  ${GREY}──────────────────────────────────────────────────────────────────────${RESET}"
printf "  ${GREY}│${RESET} ${GREEN}%-16s${RESET} ${GREY}→${RESET}  ${WHITE}%s${RESET}\n" "elektrik-config" "Ubah konfigurasi (kredensial, domain, token)"
printf "  ${GREY}│${RESET} ${GREEN}%-16s${RESET} ${GREY}→${RESET}  ${WHITE}%s${RESET}\n" "autobackup"      "Backup server manual sekarang"
printf "  ${GREY}│${RESET} ${GREEN}%-16s${RESET} ${GREY}→${RESET}  ${WHITE}%s${RESET}\n" "autorestore"     "Panduan restore data dari backup"
echo -e ""
EOF
    chmod +x /etc/profile.d/99-elektrik-motd.sh
    ui_ok "MOTD dinamis dipasang"
    log_status "MOTD" "SUCCESS" "Banner dinamis aktif"
}

mod_dependencies() {
    ui_section "06" "Dependencies Sistem (Redis, Cron, Chromium, Puppeteer)"
    local pkgs=(ca-certificates fonts-liberation libasound2t64 libatk-bridge2.0-0 libatk1.0-0
        libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 libgcc1 libglib2.0-0
        libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6
        libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6
        libxrandr2 libxrender1 libxss1 libxtst6 apt-transport-https curl git lsb-release unzip
        wget xdg-utils gnupg redis-server cron chromium)
    local missing=()
    for p in "${pkgs[@]}"; do pkg_installed "$p" || missing+=("$p"); done

    if [ ${#missing[@]} -eq 0 ]; then
        ui_skip "Semua paket dependency sudah terpasang"
    else
        ui_step "Menginstal ${#missing[@]} paket yang belum ada..."
        apt install -y "${missing[@]}" >/dev/null 2>&1 || apt install -y "${missing[@]}"
    fi

    systemctl enable redis-server >/dev/null 2>&1 || true
    systemctl start redis-server 2>/dev/null || true
    systemctl enable cron >/dev/null 2>&1 || true
    systemctl start cron 2>/dev/null || true
    ui_ok "Redis & Cron aktif"
    log_status "Dependencies" "SUCCESS" "Paket lengkap"
}

mod_apache_php() {
    ui_section "07" "Web Server - Apache2 & PHP 8.4"
    if cmd_exists php && php -v 2>/dev/null | grep -q "PHP 8.4" && pkg_installed apache2; then
        ui_skip "Apache2 & PHP 8.4 sudah terpasang"
        log_status "Apache & PHP" "SKIPPED" "Sudah ada"
        return
    fi
    ui_step "Memasang Apache2 & PHP 8.4 fullset..."
    apt install -y apache2 lsb-release ca-certificates apt-transport-https curl >/dev/null 2>&1 || true
    if [ ! -f /etc/apt/trusted.gpg.d/php.gpg ]; then
        curl -sS https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/php.gpg
    fi
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
    apt update -qq
    apt install -y php8.4 php8.4-cli php8.4-common php8.4-mysql php8.4-zip php8.4-gd \
        php8.4-mbstring php8.4-curl php8.4-xml php8.4-bcmath php8.4-intl libapache2-mod-php8.4
    update-alternatives --set php /usr/bin/php8.4 2>/dev/null || true
    systemctl restart apache2 2>/dev/null || true
    ui_ok "Apache2 & PHP 8.4 aktif"
    log_status "Apache & PHP" "SUCCESS" "Terpasang & aktif"
}

mod_mariadb() {
    ui_section "08" "Database - MariaDB Server"
    if ! pkg_installed mariadb-server; then
        ui_step "Menginstal MariaDB Server..."
        apt install -y mariadb-server >/dev/null 2>&1
    else
        ui_skip "MariaDB Server sudah terpasang"
    fi
    systemctl enable mariadb >/dev/null 2>&1 || true
    systemctl start mariadb 2>/dev/null || true

    ui_step "Menyinkronkan kredensial database..."
    mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;" 2>/dev/null || true
    if mysql -e "SELECT 1" >/dev/null 2>&1; then
        mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';" 2>/dev/null || true
        mysql -e "ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';" 2>/dev/null || true
        mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';" 2>/dev/null || true
        mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true
    fi
    ui_ok "Database ${DB_NAME} siap"
    log_status "MariaDB" "SUCCESS" "Database & user siap"
}

mod_phpmyadmin() {
    ui_section "09" "phpMyAdmin"
    if pkg_installed phpmyadmin; then
        ui_skip "phpMyAdmin sudah terpasang"
        log_status "phpMyAdmin" "SKIPPED" "Sudah ada"
        return
    fi
    ui_step "Menginstal phpMyAdmin..."
    echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
    echo "phpmyadmin phpmyadmin/app-password-confirm password ${DB_PASS}" | debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/admin-pass password ${DB_PASS}" | debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/app-pass password ${DB_PASS}" | debconf-set-selections
    echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
    apt install -y phpmyadmin >/dev/null 2>&1
    ui_ok "phpMyAdmin terpasang"
    log_status "phpMyAdmin" "SUCCESS" "Terpasang"
}

mod_nodejs_pm2() {
    ui_section "10" "Runtime - Node.js & PM2"
    local NODE_VERSION="v20.20.2"
    local NPM_VERSION="10.8.2"
    local current_node=$(node -v 2>/dev/null || echo "")

    if [ "$current_node" = "$NODE_VERSION" ]; then
        ui_skip "Node.js $NODE_VERSION sudah terpasang"
    else
        ui_step "Menginstal Node.js $NODE_VERSION..."
        apt remove -y nodejs npm nodejs-doc >/dev/null 2>&1 || true
        cd /tmp
        wget -q https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.xz
        tar -xf node-${NODE_VERSION}-linux-x64.tar.xz
        cp -r node-${NODE_VERSION}-linux-x64/* /usr/local/
        rm -rf node-${NODE_VERSION}-linux-x64*
        npm install -g npm@${NPM_VERSION} >/dev/null 2>&1 || true
        cd /root
    fi

    if cmd_exists pm2; then
        ui_skip "PM2 sudah terpasang"
    else
        ui_step "Menginstal PM2..."
        npm install -g pm2 >/dev/null 2>&1
    fi
    ui_ok "Node.js $(node -v) & PM2 $(pm2 -v 2>/dev/null)"
    log_status "Node & PM2" "SUCCESS" "Runtime siap"
}

mod_app_deploy() {
    ui_section "11" "Deployment Aplikasi Elektrik"
    mkdir -p /var/www
    cd /var/www

    if [ -d "$WEB_DIR/.git" ]; then
        ui_step "Repository ada, menjalankan git pull..."
        cd "$WEB_DIR"
        git stash 2>/dev/null || true
        git pull --rebase 2>/dev/null || git pull 2>/dev/null || true
        cd /var/www
        log_status "Repository" "UPDATED" "git pull selesai"
    else
        if [ -d "$WEB_DIR" ]; then
            ui_warn "Folder $WEB_DIR ada tapi bukan git repo. Backup & replace."
            mv "$WEB_DIR" "${WEB_DIR}.bak.$(date +%s)"
        fi
        ui_step "Clone repository..."
        git clone -q "$GIT_REPO" "$WEB_DIR"
        log_status "Repository" "SUCCESS" "Clone selesai"
    fi

    ui_step "Menulis file konfigurasi aplikasi..."
    mkdir -p "$(dirname "$WEB_DIR/helper/koneksi.php")"
    cat <<EOF > "$WEB_DIR/helper/koneksi.php"
<?php
\$host = '${DB_HOST}';
\$username = '${DB_USER}';
\$password = '${DB_PASS}';
\$database = '${DB_NAME}';

try {
    \$db = mysqli_connect(\$host, \$username, \$password, \$database);
    \$db->set_charset('utf8mb4');
} catch (\Throwable \$th) {
    throw \$th;
}
EOF

    mkdir -p "$BACKEND_DIR"
    cat <<EOF > "$BACKEND_DIR/.env"
DB_HOST=${DB_HOST}
DB_USER=${DB_USER}
DB_PASS=${DB_PASS}
DB_NAME=${DB_NAME}
PORT=${BACKEND_PORT}
SOCKET_URL=https://${SOCKET_URL}
EOF

    mkdir -p "$WEB_DIR/pages/assets/js"
    cat <<EOF > "$WEB_DIR/pages/assets/js/config.js"
const CONFIG = {
    SOCKET_URL: "https://${SOCKET_URL}"
};
EOF

    mkdir -p "$WEB_DIR/helper"
    cat <<EOF > "$WEB_DIR/helper/url_config.php"
<?php
define('SOCKET_URL', 'https://${SOCKET_URL}');
EOF
    ui_ok "File konfigurasi ditulis"

    local table_count=$(mysql -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" -e "SHOW TABLES;" 2>/dev/null | wc -l)
    if [ "$table_count" -lt 3 ] && [ -f "$WEB_DIR/db/initial.sql" ]; then
        ui_step "Import initial.sql..."
        mysql -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" < "$WEB_DIR/db/initial.sql" 2>/dev/null || true
        ui_ok "Database initial diimpor"
        log_status "Database Import" "SUCCESS" "initial.sql"
    else
        ui_skip "Database sudah terisi (${table_count} tabel)"
        log_status "Database Import" "SKIPPED" "Sudah ada data"
    fi

    mkdir -p "$WEB_DIR/gambar"
    chown -R www-data:www-data "$WEB_DIR/gambar"
    chmod -R 755 "$WEB_DIR/gambar"

    cd "$BACKEND_DIR"
    if [ -f package.json ]; then
        if [ -d node_modules ] && [ -f package-lock.json ]; then
            ui_skip "node_modules sudah ada"
        else
            ui_step "npm install backend..."
            export PUPPETEER_SKIP_DOWNLOAD=true
            npm install --silent >/dev/null 2>&1 || npm install
        fi
        export PUPPETEER_SKIP_DOWNLOAD=true
        if pm2 describe elektrik-backend >/dev/null 2>&1; then
            ui_step "Restart PM2 elektrik-backend..."
            pm2 restart elektrik-backend >/dev/null 2>&1
        else
            ui_step "Start PM2 elektrik-backend..."
            pm2 start server.js --name "elektrik-backend" >/dev/null 2>&1
        fi
        pm2 save >/dev/null 2>&1
        pm2 startup systemd -u root --hp /root >/dev/null 2>&1 || true
        ui_ok "Backend berjalan di PM2"
        log_status "Backend PM2" "SUCCESS" "Aktif"
    fi
}

mod_apache_vhost() {
    ui_section "12" "Apache VirtualHost"
    cat << EOF > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerName ${CF_WEB_NAME}
    DocumentRoot ${WEB_DIR}

    <Directory ${WEB_DIR}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/elektrik_error.log
    CustomLog \${APACHE_LOG_DIR}/elektrik_access.log combined
</VirtualHost>
EOF
    a2enmod rewrite >/dev/null 2>&1 || true
    systemctl restart apache2 2>/dev/null || true
    chown -R www-data:www-data "$WEB_DIR" 2>/dev/null || true
    ui_ok "VirtualHost ${CF_WEB_NAME} diterapkan"
    log_status "VirtualHost" "SUCCESS" "${CF_WEB_NAME}"
}

mod_cloudflare_tunnel() {
    ui_section "13" "Cloudflare Tunnel (via API)"
    if [ -z "$CF_ACCOUNT_ID" ] || [ -z "$CF_API_TOKEN" ] || [ -z "$CF_ZONE_ID" ]; then
        ui_warn "Kredensial Cloudflare tidak lengkap, dilewati"
        log_status "Cloudflare Tunnel" "SKIPPED" "Kredensial kosong"
        return
    fi

    if ! cmd_exists cloudflared; then
        ui_step "Mengunduh cloudflared..."
        curl -L --output /usr/local/bin/cloudflared \
            https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
        chmod +x /usr/local/bin/cloudflared
    else
        ui_skip "cloudflared binary sudah ada"
    fi

    ui_step "Mencari tunnel elektrik yang sudah ada..."
    local existing_response=$(curl -s -X GET \
        "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/cfd_tunnel?is_deleted=false&name=elektrik" \
        -H "Authorization: Bearer ${CF_API_TOKEN}")
    local TUNNEL_ID=$(echo "$existing_response" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

    if [ -z "$TUNNEL_ID" ]; then
        ui_step "Membuat tunnel baru..."
        local TUNNEL_NAME="elektrik-tunnel-$(date +%s)"
        local SECRET_JSON_B64=$(dd if=/dev/urandom bs=32 count=1 status=none | base64)
        local CF_RESPONSE=$(curl -s -X POST \
            "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/cfd_tunnel" \
            -H "Authorization: Bearer ${CF_API_TOKEN}" \
            -H "Content-Type: application/json" \
            --data "{\"name\":\"${TUNNEL_NAME}\", \"tunnel_secret\":\"${SECRET_JSON_B64}\", \"config_src\":\"cloudflare\"}")
        TUNNEL_ID=$(echo "$CF_RESPONSE" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
    else
        ui_ok "Tunnel ditemukan: ${TUNNEL_ID:0:12}..."
    fi

    if [ -z "$TUNNEL_ID" ]; then
        ui_fail "Gagal membuat/menemukan tunnel Cloudflare"
        log_status "Cloudflare Tunnel" "FAILED" "Tunnel ID null"
        return
    fi

    ui_step "Menyinkronkan DNS records..."
    setup_cf_dns() {
        local name=$1 full=$2 target=$3
        local get=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records?name=${full}&type=CNAME" \
            -H "Authorization: Bearer ${CF_API_TOKEN}")
        local rid=$(echo "$get" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
        if [ -n "$rid" ] && [ "$rid" != "null" ]; then
            curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${rid}" \
                -H "Authorization: Bearer ${CF_API_TOKEN}" >/dev/null
        fi
        curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records" \
            -H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json" \
            --data "{\"type\":\"CNAME\",\"name\":\"${name}\",\"content\":\"${target}\",\"proxied\":true}" >/dev/null
    }
    setup_cf_dns "${CF_PRE_WEB}" "${CF_WEB_NAME}" "${TUNNEL_ID}.cfargotunnel.com"
    setup_cf_dns "${CF_PRE_SOCKET}" "${SOCKET_URL}" "${TUNNEL_ID}.cfargotunnel.com"
    ui_ok "DNS records disinkronkan"

    ui_step "Memperbarui konfigurasi ingress..."
    curl -s -X PUT "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/cfd_tunnel/${TUNNEL_ID}/configurations" \
        -H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json" \
        --data "{\"config\": {\"ingress\": [{\"hostname\": \"${CF_WEB_NAME}\", \"service\": \"http://localhost:80\"},{\"hostname\": \"${SOCKET_URL}\", \"service\": \"http://localhost:${BACKEND_PORT}\"},{\"service\": \"http_status:404\"}]}}" >/dev/null

    local token_resp=$(curl -s -X GET \
        "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/cfd_tunnel/${TUNNEL_ID}/token" \
        -H "Authorization: Bearer ${CF_API_TOKEN}")
    local TUNNEL_TOKEN=$(echo "$token_resp" | grep -o '"result":"[^"]*' | head -1 | cut -d'"' -f4)

    if [ -n "$TUNNEL_TOKEN" ] && [ "$TUNNEL_TOKEN" != "null" ]; then
        if systemctl is-active --quiet cloudflared 2>/dev/null; then
            ui_step "Restart cloudflared service..."
            cloudflared service uninstall >/dev/null 2>&1 || true
        fi
        rm -rf /etc/cloudflared/config.yml 2>/dev/null || true
        cloudflared service install "${TUNNEL_TOKEN}" >/dev/null 2>&1
        ui_ok "Cloudflare Tunnel aktif"
        log_status "Cloudflare Tunnel" "SUCCESS" "Tunnel ${TUNNEL_ID:0:12} aktif"
    else
        ui_fail "Gagal mendapatkan tunnel token"
        log_status "Cloudflare Tunnel" "FAILED" "Token null"
    fi
}

mod_backup_restore() {
    ui_section "14" "Backup & Restore Automation"
    mkdir -p /root/elektrik_backups

    cat > /usr/local/bin/autobackup <<EOF
#!/bin/bash
CYAN='\033[1;36m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'
ERROR_COUNT=0
show_progress() {
    local pid=\$1 msg=\$2
    local spin='-\|/' i=0
    tput civis
    while kill -0 "\$pid" 2>/dev/null; do
        i=\$(( (i+1) % 4 ))
        printf "\r\${CYAN}[%c]\${NC} %s..." "\${spin:\$i:1}" "\$msg"
        sleep 0.1
    done
    wait "\$pid"; local status=\$?
    if [ "\$status" -eq 0 ]; then
        printf "\r\${GREEN}[✓]\${NC} %-50s\n" "\$msg Selesai!"
    else
        printf "\r\${RED}[✗]\${NC} %-50s\n" "\$msg Gagal!"; ERROR_COUNT=\$((ERROR_COUNT + 1))
    fi
    tput cnorm
}
BACKUP_DIR="/root/elektrik_backups"
DATE=\$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_NAME="elektrik_backup_\$DATE"
ARCHIVE_FILE="\$BACKUP_DIR/\$BACKUP_NAME.tar.gz"
MYSQL_ERROR_LOG="/tmp/mysql_error_\$DATE.log"
DB_USER="${DB_USER}"; DB_PASS="${DB_PASS}"; DB_NAME="${DB_NAME}"
TG_BOT_TOKEN="${TG_BOT_TOKEN}"; TG_CHAT_ID="${TG_CHAT_ID}"

clear
echo -e "\${CYAN}════════════════════════════════════════════════\${NC}"
echo -e "\${CYAN}    MEMULAI PROSES BACKUP SERVER ELEKTRIK       \${NC}"
echo -e "\${CYAN}════════════════════════════════════════════════\${NC}"
echo ""
mkdir -p "\$BACKUP_DIR"
TMP_DIR="/tmp/\$BACKUP_NAME"; mkdir -p "\$TMP_DIR"

if [ -d "/var/www/elektrik/gambar" ]; then
    (cp -r /var/www/elektrik/gambar "\$TMP_DIR/") &
    show_progress \$! "Menyalin direktori gambar"
else
    mkdir -p "\$TMP_DIR/gambar"
fi

(mysqldump -u"\$DB_USER" -p"\$DB_PASS" "\$DB_NAME" > "\$TMP_DIR/database.sql" 2>"\$MYSQL_ERROR_LOG") &
show_progress \$! "Mengekspor database MySQL"

cd "\$TMP_DIR" || exit
(tar -czf "\$ARCHIVE_FILE" gambar/ database.sql 2>/dev/null) &
show_progress \$! "Mengkompresi arsip .tar.gz"
rm -rf "\$TMP_DIR"; cd /root || exit

if [ -n "\$TG_BOT_TOKEN" ] && [ -n "\$TG_CHAT_ID" ] && [ -f "\$ARCHIVE_FILE" ]; then
    FILE_SIZE=\$(stat -c%s "\$ARCHIVE_FILE" 2>/dev/null || echo 0)
    if [ "\$FILE_SIZE" -le 52428800 ]; then
        (curl -s -F document=@"\$ARCHIVE_FILE" "https://api.telegram.org/bot\$TG_BOT_TOKEN/sendDocument" \
            -F chat_id="\$TG_CHAT_ID" -F caption="✅ Backup Server Elektrik (\$(date +%F))" >/dev/null) &
        show_progress \$! "Mengirim backup ke Telegram"
    else
        (curl -s -X POST "https://api.telegram.org/bot\$TG_BOT_TOKEN/sendMessage" \
            -d chat_id="\$TG_CHAT_ID" -d text="⚠️ Backup lokal berhasil, >50MB gagal kirim Telegram." >/dev/null) &
        show_progress \$! "Notifikasi ukuran >50MB"
    fi
else
    echo -e "\${YELLOW}[!] Telegram dilewati (token/chat ID kosong)\${NC}"
fi

(find "\$BACKUP_DIR" -type f -name "elektrik_backup_*.tar.gz" ! -name "\$BACKUP_NAME.tar.gz" -mtime +7 -exec rm -f {} +) &
show_progress \$! "Cleanup backup >7 hari"

echo ""
if [ "\$ERROR_COUNT" -eq 0 ]; then
    echo -e "\${GREEN}════════════════════════════════════════════════\${NC}"
    echo -e "\${GREEN}  [✓] SEMUA PROSES BACKUP BERHASIL              \${NC}"
    echo -e "\${GREEN}════════════════════════════════════════════════\${NC}"
else
    echo -e "\${RED}  [!] BACKUP SELESAI DENGAN \$ERROR_COUNT ERROR\${NC}"
    [ -s "\$MYSQL_ERROR_LOG" ] && cat "\$MYSQL_ERROR_LOG"
fi
rm -f "\$MYSQL_ERROR_LOG" 2>/dev/null
EOF

    cat > /usr/local/bin/autorestore <<EOF
#!/bin/bash
BACKUP_FILE=\$1
DB_USER="${DB_USER}"; DB_PASS="${DB_PASS}"; DB_NAME="${DB_NAME}"

if [ -z "\$BACKUP_FILE" ]; then
    echo "❌ CARA PAKAI: autorestore /path/ke/file_backup.tar.gz"
    echo "📂 Backup tersedia di /root/elektrik_backups/:"
    ls -lh /root/elektrik_backups/ 2>/dev/null
    exit 1
fi
if [ ! -f "\$BACKUP_FILE" ]; then
    echo "❌ File \$BACKUP_FILE tidak ditemukan!"; exit 1
fi

echo "Memulai Restore Data..."
TMP_DIR="/tmp/elektrik_restore_\$\$"; mkdir -p "\$TMP_DIR"
tar -xzf "\$BACKUP_FILE" -C "\$TMP_DIR"

if [ -d "\$TMP_DIR/gambar" ]; then
    rm -rf /var/www/elektrik/gambar/*
    mkdir -p /var/www/elektrik/gambar
    cp -r "\$TMP_DIR/gambar/"* /var/www/elektrik/gambar/ 2>/dev/null
    chown -R www-data:www-data /var/www/elektrik/gambar
    chmod -R 775 /var/www/elektrik/gambar
    echo "✔ Gambar dipulihkan."
fi

if [ -f "\$TMP_DIR/database.sql" ]; then
    mysql -u"\$DB_USER" -p"\$DB_PASS" "\$DB_NAME" < "\$TMP_DIR/database.sql"
    echo "✔ Database dipulihkan."
fi
rm -rf "\$TMP_DIR"
echo "✅ RESTORE SELESAI!"
EOF

    chmod +x /usr/local/bin/autobackup /usr/local/bin/autorestore

    if [[ "$ENABLE_BACKUP" =~ ^[Yy]$ ]]; then
        (crontab -l 2>/dev/null | grep -v "/usr/local/bin/autobackup"; echo "0 2 * * * /usr/local/bin/autobackup") | crontab -
        ui_ok "Backup harian dijadwalkan (02:00)"
    else
        (crontab -l 2>/dev/null | grep -v "/usr/local/bin/autobackup") | crontab - 2>/dev/null || true
        ui_info "Auto-backup dinonaktifkan"
    fi
    log_status "Backup/Restore" "SUCCESS" "Script & cron siap"
}

mod_config_tool() {
    ui_section "15" "Konfigurasi Ulang Tool (elektrik-config)"
    cat > /usr/local/bin/elektrik-config <<'ELEKTRIK_CFG_EOF'
#!/bin/bash
# elektrik-config - Reconfigure Elektrik Stack
CONFIG_FILE="/root/config/elektrik.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "File konfigurasi tidak ditemukan: $CONFIG_FILE"; exit 1
fi
source "$CONFIG_FILE"

RED="\e[1;31m"; GREEN="\e[1;32m"; YELLOW="\e[1;33m"; CYAN="\e[1;36m"
BLUE="\e[1;34m"; WHITE="\e[1;37m"; GREY="\e[0;90m"; BOLD="\e[1m"; RESET="\e[0m"

show_menu() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}   ${BOLD}${WHITE}⚙  ELEKTRIK CONFIGURATION MANAGER${RESET}                                  ${CYAN}║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo -e ""
    echo -e "  ${BOLD}${WHITE}▎ Current Configuration${RESET}"
    echo -e "  ${GREY}──────────────────────────────────────────────────────────────────────${RESET}"
    printf "  ${GREY}│${RESET} %-18s ${CYAN}%s${RESET}\n" "DB Host"      "${DB_HOST}@${DB_NAME}"
    printf "  ${GREY}│${RESET} %-18s ${CYAN}%s${RESET}\n" "Backend Port" "$BACKEND_PORT"
    printf "  ${GREY}│${RESET} %-18s ${CYAN}%s${RESET}\n" "Domain"      "$DOMAIN"
    printf "  ${GREY}│${RESET} %-18s ${CYAN}%s${RESET}\n" "Website URL" "https://${CF_WEB_NAME}"
    printf "  ${GREY}│${RESET} %-18s ${CYAN}%s${RESET}\n" "API URL"     "https://${SOCKET_URL}"
    printf "  ${GREY}│${RESET} %-18s ${CYAN}%s${RESET}\n" "Backup"      "$ENABLE_BACKUP"
    echo -e ""
    echo -e "  ${BOLD}${WHITE}▎ Menu${RESET}"
    echo -e "  ${GREY}──────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${GREEN}[1]${RESET} Edit Database    ${GREY}(host, user, password, name)${RESET}"
    echo -e "  ${GREEN}[2]${RESET} Edit Backend Port"
    echo -e "  ${GREEN}[3]${RESET} Edit Domain & Subdomain"
    echo -e "  ${GREEN}[4]${RESET} Edit Cloudflare API"
    echo -e "  ${GREEN}[5]${RESET} Edit Telegram Backup"
    echo -e "  ${GREEN}[6]${RESET} ${BOLD}Save & Apply${RESET}  ${GREY}(update semua file terkait)${RESET}"
    echo -e "  ${GREEN}[0]${RESET} Keluar tanpa menyimpan"
    echo -e ""
    echo -en "  ${CYAN}▸${RESET}  Pilih menu: "
}

edit_db() {
    read -p "  DB Host [$DB_HOST]: " i; DB_HOST=${i:-$DB_HOST}
    read -p "  DB User [$DB_USER]: " i; DB_USER=${i:-$DB_USER}
    read -s -p "  DB Password [***]: " i; echo ""; [ -n "$i" ] && DB_PASS="$i"
    read -p "  DB Name [$DB_NAME]: " i; DB_NAME=${i:-$DB_NAME}
}
edit_backend() { read -p "  Backend Port [$BACKEND_PORT]: " i; BACKEND_PORT=${i:-$BACKEND_PORT}; }
edit_domain() {
    read -p "  Domain Utama [$DOMAIN]: " i; DOMAIN=${i:-$DOMAIN}
    read -p "  Subdomain Website [$CF_PRE_WEB]: " i; CF_PRE_WEB=${i:-$CF_PRE_WEB}
    read -p "  Subdomain Socket [$CF_PRE_SOCKET]: " i; CF_PRE_SOCKET=${i:-$CF_PRE_SOCKET}
    CF_WEB_NAME="${CF_PRE_WEB}.${DOMAIN}"; SOCKET_URL="${CF_PRE_SOCKET}.${DOMAIN}"
}
edit_cloudflare() {
    read -p "  CF Account ID [$CF_ACCOUNT_ID]: " i; CF_ACCOUNT_ID=${i:-$CF_ACCOUNT_ID}
    read -p "  CF Zone ID [$CF_ZONE_ID]: " i; CF_ZONE_ID=${i:-$CF_ZONE_ID}
    read -s -p "  CF API Token [***]: " i; echo ""; [ -n "$i" ] && CF_API_TOKEN="$i"
}
edit_telegram() {
    read -p "  Enable Backup (y/n) [$ENABLE_BACKUP]: " i; ENABLE_BACKUP=${i:-$ENABLE_BACKUP}
    if [[ "$ENABLE_BACKUP" =~ ^[Yy]$ ]]; then
        read -p "  Telegram Bot Token [$TG_BOT_TOKEN]: " i; TG_BOT_TOKEN=${i:-$TG_BOT_TOKEN}
        read -p "  Telegram Chat ID [$TG_CHAT_ID]: " i; TG_CHAT_ID=${i:-$TG_CHAT_ID}
    fi
}

save_and_apply() {
    cat > "$CONFIG_FILE" <<CFG_SAVE
# ELEKTRIK STACK CONFIGURATION
# Updated: $(date '+%Y-%m-%d %H:%M:%S')
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
CFG_SAVE
    chmod 600 "$CONFIG_FILE"

    if [ -f /var/www/elektrik/helper/koneksi.php ]; then
        cat > /var/www/elektrik/helper/koneksi.php <<PHP_KONEKSI
<?php
\$host = '${DB_HOST}';
\$username = '${DB_USER}';
\$password = '${DB_PASS}';
\$database = '${DB_NAME}';

try {
    \$db = mysqli_connect(\$host, \$username, \$password, \$database);
    \$db->set_charset('utf8mb4');
} catch (\Throwable \$th) { throw \$th; }
PHP_KONEKSI
    fi

    if [ -d /var/www/elektrik/backend ]; then
        cat > /var/www/elektrik/backend/.env <<ENV_BACKEND
DB_HOST=${DB_HOST}
DB_USER=${DB_USER}
DB_PASS=${DB_PASS}
DB_NAME=${DB_NAME}
PORT=${BACKEND_PORT}
SOCKET_URL=https://${SOCKET_URL}
ENV_BACKEND
    fi

    if [ -d /var/www/elektrik/pages/assets/js ]; then
        cat > /var/www/elektrik/pages/assets/js/config.js <<JS_CFG
const CONFIG = { SOCKET_URL: "https://${SOCKET_URL}" };
JS_CFG
    fi

    if [ -d /var/www/elektrik/helper ]; then
        cat > /var/www/elektrik/helper/url_config.php <<PHP_URL
<?php
define('SOCKET_URL', 'https://${SOCKET_URL}');
PHP_URL
    fi

    for f in /usr/local/bin/autobackup /usr/local/bin/autorestore; do
        [ -f "$f" ] || continue
        sed -i "s|^DB_USER=.*|DB_USER=\"$DB_USER\"|" "$f"
        sed -i "s|^DB_PASS=.*|DB_PASS=\"$DB_PASS\"|" "$f"
        sed -i "s|^DB_NAME=.*|DB_NAME=\"$DB_NAME\"|" "$f"
    done
    if [ -f /usr/local/bin/autobackup ]; then
        sed -i "s|^TG_BOT_TOKEN=.*|TG_BOT_TOKEN=\"$TG_BOT_TOKEN\"|" /usr/local/bin/autobackup
        sed -i "s|^TG_CHAT_ID=.*|TG_CHAT_ID=\"$TG_CHAT_ID\"|" /usr/local/bin/autobackup
    fi

    if mysql -e "SELECT 1" >/dev/null 2>&1; then
        mysql -e "ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';" 2>/dev/null || true
        mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true
    fi

    if [ -f /etc/apache2/sites-available/000-default.conf ]; then
        sed -i "s|ServerName .*|ServerName ${CF_WEB_NAME}|" /etc/apache2/sites-available/000-default.conf
    fi

    systemctl restart apache2 2>/dev/null || true
    pm2 restart elektrik-backend >/dev/null 2>&1 || true

    if [[ "$ENABLE_BACKUP" =~ ^[Yy]$ ]]; then
        (crontab -l 2>/dev/null | grep -v "/usr/local/bin/autobackup"; echo "0 2 * * * /usr/local/bin/autobackup") | crontab -
    else
        (crontab -l 2>/dev/null | grep -v "/usr/local/bin/autobackup") | crontab - 2>/dev/null || true
    fi

    echo -e ""
    echo -e "  ${GREEN}✔${RESET} Konfigurasi tersimpan & diterapkan."
    echo -e "  ${GREY}File terkait telah diperbarui. Service di-restart.${RESET}"
    echo ""
    read -p "  Tekan Enter untuk kembali ke menu..."
}

while true; do
    show_menu
    read choice
    case "$choice" in
        1) edit_db ;;
        2) edit_backend ;;
        3) edit_domain ;;
        4) edit_cloudflare ;;
        5) edit_telegram ;;
        6) save_and_apply ;;
        0) clear; exit 0 ;;
        *) echo "  Pilihan tidak valid"; sleep 1 ;;
    esac
done
ELEKTRIK_CFG_EOF
    chmod +x /usr/local/bin/elektrik-config
    ui_ok "Tool elektrik-config dipasang"
    log_status "Config Tool" "SUCCESS" "elektrik-config tersedia"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    check_root
    clear
    ui_banner
    check_debian

    if detect_prior_install; then
        show_prior_install_info
        select_mode
    else
        MODE="fresh"
        echo ""
        ui_info "Instalasi baru terdeteksi (fresh install)."
        sleep 1
    fi

    init_logging
    check_internet

    if [ "$MODE" = "config" ]; then
        if [ -f "$CONFIG_FILE" ]; then
            exec /usr/local/bin/elektrik-config
        else
            ui_fail "Config file tidak ditemukan untuk mode config-only"
            exit 1
        fi
    fi

    if load_config && [ "$MODE" = "upgrade" ]; then
        echo ""
        ui_info "Konfigurasi yang ada dimuat dari $CONFIG_FILE"
        local reuse
        reuse=$(ui_input "Gunakan konfigurasi ini? (y/n)" "y")
        if [[ ! "$reuse" =~ ^[Yy]$ ]]; then
            prompt_config
        fi
    else
        if [ "$MODE" = "fresh" ] && [ -f "$CONFIG_FILE" ]; then
            cp "$CONFIG_FILE" "${CONFIG_FILE}.bak.$(date +%s)"
            ui_warn "Config lama di-backup ke ${CONFIG_FILE}.bak.*"
        fi
        prompt_config
    fi

    ui_section "EXECUTION" "Menjalankan Modul Instalasi"
    ui_info "Mode: ${MODE}  |  Versi: ${SCRIPT_VERSION}"
    ui_divider

    mod_ssh_config
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
    mod_config_tool

    save_marker

    echo "" >> "$REPORT_FILE"
    echo "=== PROSES AUTOINSTALL SELESAI ===" >> "$REPORT_FILE"

    clear
    ui_banner
    echo -e ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}║${RESET}   ${BOLD}${WHITE}✅  INSTALASI SELESAI - MODE: ${MODE^^}${RESET}                                    ${GREEN}║${RESET}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo -e ""
    cat "$REPORT_FILE"
    echo -e ""
    echo -e "${CYAN}┌──────────────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${CYAN}│${RESET}  ${BOLD}${WHITE}PANDUAN PENGGUNAAN${RESET}                                                     ${CYAN}│${RESET}"
    echo -e "${CYAN}├──────────────────────────────────────────────────────────────────────────┤${RESET}"
    printf "${CYAN}│${RESET}  ${GREEN}elektrik-config${RESET}  ${GREY}→${RESET} ${WHITE}%-48s${RESET} ${CYAN}│${RESET}\n" "Ubah konfigurasi & kredensial"
    printf "${CYAN}│${RESET}  ${GREEN}autobackup${RESET}       ${GREY}→${RESET} ${WHITE}%-48s${RESET} ${CYAN}│${RESET}\n" "Backup manual server saat ini"
    printf "${CYAN}│${RESET}  ${GREEN}autorestore${RESET}      ${GREY}→${RESET} ${WHITE}%-48s${RESET} ${CYAN}│${RESET}\n" "Panduan restore data"
    printf "${CYAN}│${RESET}  ${GREEN}bash %s${RESET}   ${GREY}→${RESET} ${WHITE}%-48s${RESET} ${CYAN}│${RESET}\n" "$(basename "$0")" "Jalankan ulang installer kapan saja"
    echo -e "${CYAN}└──────────────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
}
main "$@"