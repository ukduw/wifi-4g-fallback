# for ubuntu server
# NetworkManager (can also use systemd-networkd...)

# config:
    # wifi connection, id "home-wifi"
        # set connection.autoconnect=yes
    # 4g dongle as NetworkManager connection, id "4g-usb"
# ModemManager + usb_modeswitch likely needed

# commands:
    # list connections: nmcli connection show
    # nmcli connection up/down: nmcli connection up/down "4g-usb"

# (for when both are available)
    # lower metric = preferred
    # nmcli connection modify "home-wifi" ipv4.route-metric 100
    # nmcli connection modify "4g-usb" ipv4.route-metric 600


