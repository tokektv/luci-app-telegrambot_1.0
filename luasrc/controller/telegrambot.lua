module("luci.controller.telegrambot", package.seeall)

function index()
  entry({"admin", "services", "telegrambot"}, cbi("telegrambot"), "Telegram Bot", 60)
end
