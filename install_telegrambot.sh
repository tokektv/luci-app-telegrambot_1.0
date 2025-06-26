#!/bin/sh

# === SETTING ===
RAW_URL="https://raw.githubusercontent.com/username/repo-name/main/luci-app-telegrambot"

echo "[*] Instalasi Telegram Bot + LuCI (versi RAW)..."

# --- PASANG DEPENDENSI ---
opkg update
opkg install curl jq luci-base luci-compat

# --- BUAT DIREKTORI TUJUAN ---
mkdir -p /usr/lib/lua/luci/controller
mkdir -p /usr/lib/lua/luci/model/cbi
mkdir -p /usr/lib/lua/luci/view/telegrambot
mkdir -p /usr/bin
mkdir -p /etc/init.d
mkdir -p /etc/config

# --- UNDUH FILE UTAMA ---
echo "[*] Mengunduh file LuCI..."
wget -O /usr/lib/lua/luci/controller/telegrambot.lua "$RAW_URL/luasrc/controller/telegrambot.lua"
wget -O /usr/lib/lua/luci/model/cbi/telegrambot.lua "$RAW_URL/luasrc/model/cbi/telegrambot.lua"
wget -O /usr/lib/lua/luci/view/telegrambot/status.htm "$RAW_URL/luasrc/view/telegrambot/status.htm"

echo "[*] Mengunduh skrip bot..."
wget -O /usr/bin/telegrambot.sh "$RAW_URL/root/usr/bin/telegrambot.sh"
wget -O /etc/init.d/telegrambot "$RAW_URL/root/etc/init.d/telegrambot"
wget -O /etc/config/telegrambot "$RAW_URL/root/etc/config/telegrambot"

# --- IZINKAN EKSEKUSI ---
chmod +x /usr/bin/telegrambot.sh
chmod +x /etc/init.d/telegrambot

# --- ENABLE & START SERVICE ---
/etc/init.d/telegrambot enable
/etc/init.d/telegrambot start

echo "[✓] Instalasi selesai!"
echo "📍 Konfigurasi tersedia di LuCI: Services > Telegram Bot"