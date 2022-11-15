#!/bin/sh

ping -c1 -W2 1.1.1.1 || { echo "[-] - no internet!" ; exit 1; }
opkg update && opkg install luci tor iptables-mod-extra || { echo "[-] - coudln't install packages!" ; exit 1; }


# Configure Tor client
cat << EOF > /etc/tor/custom
AutomapHostsOnResolve 1
AutomapHostsSuffixes .
VirtualAddrNetworkIPv4 172.16.0.0/12
VirtualAddrNetworkIPv6 [fc00::]/7
DNSPort 0.0.0.0:9053
DNSPort [::]:9053
TransPort 0.0.0.0:9040
TransPort [::]:9040
EOF
cat << EOF >> /etc/sysupgrade.conf
/etc/tor
EOF
uci del_list tor.conf.tail_include="/etc/tor/custom"
uci add_list tor.conf.tail_include="/etc/tor/custom"
uci commit tor

/etc/init.d/tor enable; /etc/init.d/tor restart



# Intercept TCP traffic
cat << "EOF" > /etc/nftables.d/tor.sh
nft list chain inet fw4 dstnat_lan \
| sed -e "/Intercept-TCP/\
s/^/fib daddr type != { local, broadcast }/
1i flush chain inet fw4 dstnat_lan" \
| nft -f -
EOF
uci -q delete firewall.tor_nft
uci set firewall.tor_nft="include"
uci set firewall.tor_nft.path="/etc/nftables.d/tor.sh"
uci -q delete firewall.tcp_int
uci set firewall.tcp_int="redirect"
uci set firewall.tcp_int.name="Intercept-TCP"
uci set firewall.tcp_int.src="lan"
uci set firewall.tcp_int.src_dport="0-65535"
uci set firewall.tcp_int.dest_port="9040"
uci set firewall.tcp_int.proto="tcp"
uci set firewall.tcp_int.family="any"
uci set firewall.tcp_int.target="DNAT"


# Disable LAN to WAN forwarding
uci -q delete firewall.@forwarding[0]
uci commit firewall
/etc/init.d/firewall restart


# Intercept DNS traffic
uci -q delete firewall.dns_int
uci set firewall.dns_int="redirect"
uci set firewall.dns_int.name="Intercept-DNS"
uci set firewall.dns_int.src="lan"
uci set firewall.dns_int.src_dport="53"
uci set firewall.dns_int.proto="tcp udp"
uci set firewall.dns_int.target="DNAT"
uci commit firewall
/etc/init.d/firewall restart


# Intercept IPv6 DNS traffic
uci set firewall.dns_int.family="any"
uci commit firewall
/etc/init.d/firewall restart


# Enable DNS over Tor
/etc/init.d/dnsmasq stop
uci set dhcp.@dnsmasq[0].boguspriv="0"
uci set dhcp.@dnsmasq[0].rebind_protection="0"
uci set dhcp.@dnsmasq[0].noresolv="1"
uci -q delete dhcp.@dnsmasq[0].server
uci add_list dhcp.@dnsmasq[0].server="127.0.0.1#9053"
uci add_list dhcp.@dnsmasq[0].server="::1#9053"
uci commit dhcp
/etc/init.d/dnsmasq start


# get public IP address
wget -q -O- http://ifconfig.me/ip


# Wi-Fi setting RADIO0
wifipass='TorRouters.com'
echo "starting Wi-Fi setup"
if [[ `uci get wireless.@wifi-device[0].channel` ]]; then
    if [[ `uci get wireless.@wifi-device[0].channel` -le 13 ]]; then
        uci set wireless.@wifi-device[0].channel='1'
        uci set wireless.@wifi-iface[0].ssid='Toriro-2.4ghz'
    else
        uci set wireless.@wifi-device[0].channel='44'
        uci set wireless.@wifi-iface[0].ssid='Toriro-5ghz'
    fi
    uci set wireless.@wifi-iface[0].key="$wifipass"
    uci set wireless.@wifi-iface[0].encryption='psk2+ccmp'
    uci set wireless.@wifi-device[0].disabled=0
    uci -q delete wireless.@wifi-device[0].disabled
    uci commit wireless
    wifi reload
fi

# Wi-Fi setting RADIO1
if [[ `uci get wireless.@wifi-device[1].channel` ]]; then
    if [[ `uci get wireless.@wifi-device[1].channel` -le 13 ]]; then
        uci set wireless.@wifi-device[1].channel='1'
        uci set wireless.@wifi-iface[1].ssid='Toriro-2.4ghz'
    else
        uci set wireless.@wifi-device[1].channel='44'
        uci set wireless.@wifi-iface[1].ssid='Toriro-5ghz'
    fi
    uci set wireless.@wifi-iface[1].key="$wifipass"
    uci set wireless.@wifi-iface[1].encryption='psk2+ccmp'
    uci set wireless.@wifi-device[1].disabled=0
    uci -q delete wireless.@wifi-device[1].disabled
    uci commit wireless
    wifi reload
fi

/etc/init.d/cron enable
/etc/init.d/cron start

html='<a style="padding-left: 35px;" target="_blank" href="https://torrouters.com">Mantained with 💜 by TorRouters.com - visit us for support & more.</a>'
echo "$html" >> /usr/lib/lua/luci/view/footer.htm

uci set system.@system[0].hostname='TorRouter'
uci set network.lan.ipaddr='192.168.7.1'
uci commit network
uci commit system

echo "[+] - finished flashing, wait for TorRouter to appear at 192.168.7.1......"

/etc/init.d/system reload
/etc/init.d/network reload
