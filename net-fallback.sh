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
    ping -c 2 -W 2 "$CHECK_HOST" >/dev/null 2>&1
    return $?
}

http_check() {
    # optional - dns/http check
    curl -fsS --max-time 5 "$CHECK_URL" >/dev/null 2>&1
    return $?
}

is_wifi_default_route() {
    wifi_dev=$(nmcli -g GENERAL.DEVICE connection show "$WIFI_CONN" 2>/dev/null)
    if [ -z "$wifi_dev" ]; then
        return 1
    fi
    ip route get 8.8.8.8 2>/dev/null | grep -q "dev $wifi_dev"
    return $?
}

bring_up_mobile() {
    logger -t net-fallback "Bringing up mobile ($MOBILE_CONN)"
    nmcli connection up "$MOBILE_CONN" >/dev/null 2>&1
    sleep 2
}

bring_down_mobile() {
    logger -t net-fallback "Bringing down mobile ("$MOBILE_CONN")"
    nmcli connection down "$MOBILE_CONN" >/dev/null 2>&1
}

main_check() {
    if ping_check && http_check; then
        return 0
    else
        return 1
    fi
}


mode="" # "once" to only run once
run_once(){
    if main_check; then
        ok_count=$(cat "$OK_COUNT_FILE" 2>/dev/null || echo 0)
        ok_count=$((ok_count+1))
        echo "$ok_count" > "$OK_COUNT_FILE"
        echo 0 > "$FAIL_COUNT_FILE"
        if [ "$ok_count" -ge "$RECOVER_THRESHOLD" ]; then
            if nmcli -t -f NAME,DEVICE connection show --active | grep -q "^MOBILE_CONN"
                bring_down_mobile
                logger -t net-fallback "Recovered; bringing mobile down"
            fi
        fi
    else
        fail_count=$(cat "$FAIL_COUNT_FILE" 2>/dev/null || echo 0)
        fail_count=$((fail_count+1))
        echo "$fail_count" > "$FAIL_COUNT_FILE"
        echo 0 > "$OK_COUNT_FILE"
        if [ "$fail_count" -ge "$FAIL_THRESHOLD" ]; then
            if ! nmcli -t -f NAME connection show --active | grep -q "^$MOBILE_CONN"
                bring_up_mobile
                logger -t net-failover "Wifi down; bringing mobile fallback up"
            fi
        fi
    fi
}

if [ "$mode" = "once" ]; then
    run_once
    exit 0
fi

# continuous loop
while true; do
    run_once
    sleep $SLEEP_LOOP
done