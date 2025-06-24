#!/bin/sh

. /etc/telegrambot.conf

API_URL="https://api.telegram.org/bot$BOT_TOKEN"

get_updates() {
  curl -s "$API_URL/getUpdates?timeout=30&offset=$OFFSET"
}

send_message() {
  local text="$1"
  curl -s -X POST "$API_URL/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$text"
}

handle_command() {
  local cmd="$1"
  case "$cmd" in
    /reboot@$ROUTER_ID)
      send_message "Rebooting $ROUTER_ID..."
      reboot
      ;;
    /online@$ROUTER_ID)
      online=$(cat /tmp/dhcp.leases | awk '{print $3, $4}')
      send_message "Online users on $ROUTER_ID:\n$online"
      ;;
    /restartlan@$ROUTER_ID)
      ifup lan && send_message "LAN interface restarted on $ROUTER_ID."
      ;;
    /restartwan@$ROUTER_ID)
      ifup wan && send_message "WAN interface restarted on $ROUTER_ID."
      ;;
    /ping*@*)
      target=$(echo "$cmd" | cut -d@ -f1 | cut -d_ -f2)
      ping -c 4 "$target" > /tmp/pingresult
      result=$(cat /tmp/pingresult)
      send_message "Ping result on $ROUTER_ID:\n$result"
      ;;
    *)
      # Ignore unmatched commands
      ;;
  esac
}

main_loop() {
  OFFSET=0
  while true; do
    UPDATES=$(get_updates)
    echo "$UPDATES" | jq -c '.result[]' | while read -r update; do
      OFFSET=$(echo "$update" | jq '.update_id + 1')
      CHAT=$(echo "$update" | jq -r '.message.chat.id')
      TEXT=$(echo "$update" | jq -r '.message.text')

      if [ "$CHAT" = "$CHAT_ID" ]; then
        handle_command "$TEXT"
      fi
    done
    sleep 2
  done
}

main_loop
