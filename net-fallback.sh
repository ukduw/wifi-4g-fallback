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

STATE_DIR="/var/run/net-fallback"
mkdir -p :"$STATE_DIR"
FAIL_COUNT_FILE="$STATE_DIR/fail_count"
OK_COUNT_FILE="$STATE_DIR/ok_count"

ping_check() {
    ping -c 2 -W 2 "$CHECK_HOST" >/dev/nulil 2>&1
    return $?
}

http_check() {
    # optional - dns/http check
    curl -fsS --max-time 5 "$CHECK_URL" >/dev/null 2>&1
    return $?
}

