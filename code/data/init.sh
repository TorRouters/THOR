#!/bin/sh

ping -c1 -W2 1.1.1.1 || { echo "[-] - no internet!" ; exit 1; }
/etc/init.d/sysntpd enable
/etc/init.d/sysntpd stop
ntpd -q -p 'time1.google.com'
/etc/init.d/sysntpd start && echo -e "------------- Time synced to: $(date)"

if command -v opkg > /dev/null 2>&1; then
    echo "[+] opkg detected ..."
    opkg update && opkg install tor || { echo "[-] - coudln't install packages!" ; exit 1; }
else
    echo "[+] APK detected ..."
    apk -U add tor || { echo "[-] - coudln't install packages!" ; exit 1; }
fi


# Configure Tor client
cat << EOF > /etc/tor/custom
AutomapHostsOnResolve 1
AutomapHostsSuffixes .
VirtualAddrNetworkIPv4 172.16.0.0/12
VirtualAddrNetworkIPv6 [fc00::]/8
DNSPort 0.0.0.0:9053
DNSPort [::]:9053
TransPort 0.0.0.0:9040
TransPort [::]:9040
#MaxMemInQueues 64 MB #<---------- change this as needed
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
TOR_CHAIN="dstnat_$(uci -q get firewall.tcp_int.src)"
nft list chain inet fw4 ${TOR_CHAIN} \
| sed -e "/Intercept-TCP/\
s/^/fib daddr type != { local, broadcast }/
1i flush chain inet fw4 ${TOR_CHAIN}" \
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



# Intercept DNS traffic
uci -q delete firewall.dns_int
uci set firewall.dns_int="redirect"
uci set firewall.dns_int.name="Intercept-DNS"
uci set firewall.dns_int.src="lan"
uci set firewall.dns_int.src_dport="53"
uci set firewall.dns_int.proto="tcp udp"
uci set firewall.dns_int.target="DNAT"
uci commit firewall



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
echo "public ip: "
wget -q -O- http://ifconfig.me/ip &
echo; echo;


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
    uci -q delete wireless.@wifi-device[1].disabled

    iwinfo
    uci del wireless.@wifi-iface[1].disabled
    uci del wireless.@wifi-iface[0].disabled
    uci commit wireless
    wifi reload
fi

/etc/init.d/cron enable
/etc/init.d/cron start

html='<a style="text-align: center;" target="_blank" href="https://torrouters.com">Mantained with 💜 by TorRouters.com - visit us for support & more.</a>'
echo "$html" >> /usr/share/ucode/luci/template/themes/bootstrap/footer.ut

line='ntpd -q -p "time1.google.com" &'
echo "$line" > /etc/rc.local
echo "exit 0" >> /etc/rc.local


echo -e "192.168.7.1\tmy.torrouters.com" >> /etc/hosts


uci set system.@system[0].hostname='TorRouter'

uci del dhcp.lan.ra_slaac
uci set dhcp.lan.ra_preference='medium'

# ipv6 issue
uci set dhcp.@dnsmasq[0].filter_aaaa='1'
uci commit dhcp



# /etc/config/network
uci del network.lan.ipaddr
uci add_list network.lan.ipaddr='192.168.7.1/24'
uci set network.lan.multipath='off'
uci commit network
uci commit system


echo "[+] - disabling ipv6......"

uci set 'network.lan.ipv6=0'
uci set 'network.wan.ipv6=0'
uci set 'dhcp.lan.dhcpv6=disabled'
/etc/init.d/odhcpd disable
uci commit

uci -q delete dhcp.lan.dhcpv6
uci -q delete dhcp.lan.ra
uci commit dhcp

uci set network.lan.delegate="0"
uci set network.lan.ip6assign='0'
uci set dhcp.lan.dhcpv6='disabled'
uci del network.wan6
uci commit network

/etc/init.d/odhcpd disable
/etc/init.d/odhcpd stop




echo "[+] - displaying memory usage -----------------------------------------------"
echo

awk '/MemTotal/ {total=$2} /MemAvailable/ {available=$2} END {print "Total Memory: " total/1024 " MB\nUsed Memory: " (total-available)/1024 " MB\nFree Memory: " available/1024 " MB"}' /proc/meminfo

echo "---------------------------------------------------------------------"
echo
echo "[+] - all done"



echo "[+] - finished flashing, wait for TorRouter to appear at TorRouter.lan : 192.168.7.1......"






sync
/etc/init.d/system reload
/etc/init.d/dnsmasq restart
/etc/init.d/network restart
