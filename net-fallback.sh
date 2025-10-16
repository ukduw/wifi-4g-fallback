# save in /usr/local/bin/net-fallback.sh
# chmod +x

# !/usr/bin/env bash
# net-fallback.sh
# Requires: nmcli, ping, logger
# Config:
WIFI_CONN="home-wifi"
MOBILE_CONN="4g-usb"
CHECK_HOST="1.1.1.1" # reliable ip to ping (Cloudflare)
CHECK_URL="https://cloudflare.com/robots.txt" # optional http check...
FAIL_THRESHOLD=3
RECOVER_THRESHOLD=3 # consider decreasing both...
SLEEP_LOOP=15 # consider decreasing... minimum additional downtime would be 45 