#!/bin/sh

# Baca konfigurasi dari UCI
TOKEN=$(uci get telegram_bot.config.token)
CHAT_ID=$(uci get telegram_bot.config.chat_id)
ROUTER_ID=$(uci get telegram_bot.config.router_id)

# File untuk menyimpan daftar perangkat yang sudah terdeteksi
KNOWN_DEVICES="/root/known_devices.txt"

# File untuk menyimpan ID update terakhir yang diproses
LAST_UPDATE_ID_FILE="/root/last_update_id.txt"

# Fungsi untuk mengirim pesan ke Telegram
send_message() {
    local message="$1"
    local keyboard="$2"
    if [ -n "$keyboard" ]; then
        curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
            -d "chat_id=$CHAT_ID" \
            -d "text=$message" \
            -d "reply_markup={\"keyboard\":$keyboard,\"resize_keyboard\":true}"
    else
        curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
            -d "chat_id=$CHAT_ID" \
            -d "text=$message"
    fi
}

# Fungsi untuk mendapatkan update dari bot
get_updates() {
    local offset="$1"
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/getUpdates" \
        -d "offset=$offset" \
        -d "timeout=10"
}

# Fungsi untuk memproses perintah
process_command() {
    local update="$1"
    local message=$(echo "$update" | jq -r '.result[-1].message.text')
    local chat_id=$(echo "$update" | jq -r '.result[-1].message.chat.id')
    local update_id=$(echo "$update" | jq -r '.result[-1].update_id')

    # Simpan ID update terakhir yang diproses
    echo "$update_id" > "$LAST_UPDATE_ID_FILE"

    if [ "$chat_id" != "$CHAT_ID" ]; then
        send_message "Akses ditolak. Chat ID tidak dikenali."
        return
    fi

    # Parsing perintah dan ID router
    local command=$(echo "$message" | awk '{print $1}')
    local target_router=$(echo "$message" | awk '{print $2}')

    # Jika perintah tidak menyertakan ID router, gunakan ID router saat ini
    if [ -z "$target_router" ]; then
        target_router="$ROUTER_ID"
    fi

    # Jika perintah tidak ditujukan ke router ini, abaikan
    if [ "$target_router" != "$ROUTER_ID" ]; then
        return
    fi

    case "$command" in
        "/start"|"Menu")
            show_menu
            ;;
        "/reboot"|"”9ã1 Reboot")
            send_message "[$ROUTER_ID] Rebooting router..."
            reboot
            ;;
        "/status"|"”9Ý6 Status")
            status=$(get_status)
            send_message "[$ROUTER_ID] $status"
            ;;
        "/restart_interface"|"”9±4 Restart Interface")
            interface=$(echo "$message" | awk '{print $3}')
            send_message "[$ROUTER_ID] Restarting $interface interface..."
            ifdown "$interface" && ifup "$interface"
            send_message "[$ROUTER_ID] $interface interface restarted."
            ;;
        "/restart_mwan3"|"”9ã4 Restart MWAN3")
            send_message "[$ROUTER_ID] Restarting MWAN3..."
            /etc/init.d/mwan3 restart
            send_message "[$ROUTER_ID] MWAN3 restarted."
            ;;
        "/online_users"|"”9Ó5 Online Users")
            online_users=$(get_online_users)
            send_message "[$ROUTER_ID] 
            ===Daftar pengguna online===
            $online_users"
            ;;
        "/clear_cache"|"•0ä3 Clear Cache")
            clear_cache
            send_message "[$ROUTER_ID] Cache berhasil dibersihkan."
            ;;
        "/ping"|"”9ß9 Ping IP")
            ip=$(echo "$message" | awk '{print $3}')
            ping_result=$(ping_ip "$ip")
            send_message "[$ROUTER_ID] Hasil ping ke $ip:\n$ping_result"
            ;;
        *)
            send_message "[$ROUTER_ID] Perintah tidak dikenali. Gunakan menu di bawah atau ketik /start untuk menampilkan menu."
            ;;
    esac
}

# Fungsi untuk menampilkan menu
show_menu() {
    local keyboard='[["”9Ý6 Status","”9Ó5 Online Users"],["”9±4 Restart Interface","”9ã4 Restart MWAN3"],["”9ã1 Reboot","•0ä3 Clear Cache"],["”9ß9 Ping IP"]]'
    send_message "[$ROUTER_ID] Silakan pilih perintah dari menu di bawah:\n\nUntuk melakukan ping, ketik /ping <IP> (contoh: /ping 192.168.1.1)." "$keyboard"
}

# Ambil status router
get_status() {
    local uptime=$(cat /proc/uptime | awk '{print $1}')
    local load=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
    local memory=$(free -m | awk 'NR==2{print $3 "MB used / " $2 "MB total"}')
    local disk=$(df -h / | awk 'NR==2{print $3 " used / " $2 " total"}')
    local wan_ip=$(curl -s ifconfig.me)

    echo "=== Status Router ==="
    echo "Uptime: $(printf '%02d:%02d:%02d\n' $((${uptime%.*}/3600)) $((${uptime%.*}%3600/60)) $((${uptime%.*}%60)))"
    echo "Load Average: $load"
    echo "Memory Usage: $memory"
    echo "Disk Usage: $disk"
    echo "WAN IP: $wan_ip"
}

# Fungsi untuk menampilkan pengguna online
get_online_users() {
    local online_users=""
# Path ke file dhcp.leases
DHCP_LEASES_FILE="/tmp/dhcp.leases"

# Cek apakah file dhcp.leases ada
if [ ! -f "$DHCP_LEASES_FILE" ]; then
  echo "File dhcp.leases tidak ditemukan!"
  exit 1
fi

# Menampilkan header
printf "%-15s %s\n" "IP Address" "Hostname"

# Membaca dan menampilkan isi file dhcp.leases
while read -r line; do
  # Memisahkan kolom berdasarkan spasi
  ip_address=$(echo "$line" | awk '{print $3}')
  hostname=$(echo "$line" | awk '{print $4}')

  # Menampilkan data (hanya IP dan Hostname)
  printf "%-15s %s\n" "$ip_address" "$hostname"
done < "$DHCP_LEASES_FILE"
}

# Fungsi untuk membersihkan cache
clear_cache() {
    echo "Membersihkan cache..."
    # Bersihkan cache memori
    sync
    echo 3 > /proc/sys/vm/drop_caches

    # Bersihkan cache DNS
    if [ -f /var/run/dnsmasq.pid ]; then
        kill -HUP $(cat /var/run/dnsmasq.pid)
    fi

    # Bersihkan cache dari /tmp
    rm -rf /tmp/*
}

# Fungsi untuk melakukan ping ke IP lokal
ping_ip() {
    local ip="$1"
    if [ -z "$ip" ]; then
        echo "IP tidak boleh kosong."
        return
    fi

    # Lakukan ping dengan 4 paket
    ping -c 4 "$ip"
}

# Fungsi untuk memeriksa perangkat baru
check_new_devices() {
    touch "$KNOWN_DEVICES"
    while read -r line; do
        mac=$(echo "$line" | awk '{print $2}')
        if ! grep -q "$mac" "$KNOWN_DEVICES"; then
            name=$(echo "$line" | awk '{print $4}')
            ip=$(echo "$line" | awk '{print $3}')
            send_message "[$ROUTER_ID] Perangkat baru terdeteksi: $name ($mac) dengan IP $ip."
            echo "$mac" >> "$KNOWN_DEVICES"
        fi
    done < /tmp/dhcp.leases
}

# Loop utama untuk memantau perintah dan perangkat baru
while true; do
    # Ambil ID update terakhir yang diproses
    LAST_UPDATE_ID=$(cat "$LAST_UPDATE_ID_FILE" 2>/dev/null || echo "0")

    # Dapatkan update baru dari bot
    updates=$(get_updates "$((LAST_UPDATE_ID + 1))")

    # Jika ada update baru, proses perintah
    if [ -n "$updates" ] && [ "$(echo "$updates" | jq '.result | length')" -gt 0 ]; then
        process_command "$updates"
    fi

    # Periksa perangkat baru
    check_new_devices

    # Tunggu sebelum memeriksa lagi
    sleep 5
done
