#!/bin/sh

# === KONFIGURASI ===
REPO_URL="https://github.com/username/repo-name"
PACKAGE_DIR="luci-app-telegrambot"
TMP_DIR="/tmp/$PACKAGE_DIR"

echo "[*] Instalasi Telegram Bot + LuCI..."

# === DEPENDENSI ===
echo "[*] Memasang dependensi (curl, jq, luci-base)..."
opkg update
opkg install curl jq luci-base luci-compat

# === DOWNLOAD DARI GITHUB ===
echo "[*] Mengunduh paket dari GitHub..."
rm -rf $TMP_DIR
git clone "$REPO_URL.git" $TMP_DIR || {
    echo "[!] Gagal mengunduh repo dari GitHub."
    exit 1
}

# === SALIN FILE KE SISTEM ===
echo "[*] Menyalin file LuCI dan skrip bot..."
cp -r $TMP_DIR/root/* /
cp -r $TMP_DIR/luasrc /usr/lib/lua/luci/

# === IZINKAN FILE EKSEKUSI ===
chmod +x /usr/bin/telegrambot.sh
chmod +x /etc/init.d/telegrambot

# === INISIASI CONFIG JIKA BELUM ADA ===
CONFIG_FILE="/etc/config/telegrambot"
if [ ! -f "$CONFIG_FILE" ]; then
    cat <<EOF > "$CONFIG_FILE"
config telegrambot 'config'
	option bot_token 'ISI_TOKEN_DISINI'
	option chat_id 'ISI_CHATID_DISINI'
	option router_id 'router01'
EOF
fi

# === ENABLE & START SERVICE ===
echo "[*] Mengaktifkan dan menjalankan service bot..."
/etc/init.d/telegrambot enable
/etc/init.d/telegrambot start

echo "[✓] Instalasi selesai!"
echo "📍 Konfigurasi tersedia di LuCI: Services > Telegram Bot"
