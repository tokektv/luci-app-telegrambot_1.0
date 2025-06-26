m = Map("telegrambot", "Telegram Bot")

s = m:section(NamedSection, "config", "telegrambot", "Konfigurasi")
s.addremove = false
s.anonymous = true

s:option(Value, "bot_token", "Bot Token")
s:option(Value, "chat_id", "Chat ID")
s:option(Value, "router_id", "Router ID")

return m
