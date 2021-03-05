#!/bin/sh

ping -c1 -W2 1.1.1.1 || { echo "[-] - no internet!" ; exit 1; }

opkg update && opkg install tor || { echo "[-] - coudln't install packages!" ; exit 1; }


# Configure Tor client
cat << EOF > /etc/tor/main
AutomapHostsOnResolve 1
VirtualAddrNetworkIPv4 172.16.0.0/12
VirtualAddrNetworkIPv6 fc00::/7
DNSPort 0.0.0.0:9053
DNSPort [::]:9053
TransPort 0.0.0.0:9040
TransPort [::]:9040
EOF


uci del_list tor.conf.tail_include="/etc/tor/main"
uci add_list tor.conf.tail_include="/etc/tor/main"
uci commit tor
/etc/init.d/tor enable
/etc/init.d/tor restart



uci -q delete uhttpd.main.listen_http
uci add_list uhttpd.main.listen_http="0.0.0.0:8080"
uci add_list uhttpd.main.listen_http="[::]:8080"
uci -q delete uhttpd.main.listen_https
uci add_list uhttpd.main.listen_https="0.0.0.0:8443"
uci add_list uhttpd.main.listen_https="[::]:8443"
uci commit uhttpd
/etc/init.d/uhttpd restart



## FIREWALL
# Intercept SSH, HTTP and HTTPS traffic
uci -q delete firewall.ssh_int
uci set firewall.ssh_int="redirect"
uci set firewall.ssh_int.name="Intercept-SSH"
uci set firewall.ssh_int.src="lan"
uci set firewall.ssh_int.src_dport="22"
uci set firewall.ssh_int.proto="tcp"
uci set firewall.ssh_int.target="DNAT"
uci -q delete firewall.http_int
uci set firewall.http_int="redirect"
uci set firewall.http_int.name="Intercept-HTTP"
uci set firewall.http_int.src="lan"
uci set firewall.http_int.src_dport="8080"
uci set firewall.http_int.proto="tcp"
uci set firewall.http_int.target="DNAT"
uci -q delete firewall.https_int
uci set firewall.https_int="redirect"
uci set firewall.https_int.name="Intercept-HTTPS"
uci set firewall.https_int.src="lan"
uci set firewall.https_int.src_dport="8443"
uci set firewall.https_int.proto="tcp"
uci set firewall.https_int.target="DNAT"
 
# Intercept DNS and TCP traffic
uci -q delete firewall.dns_int
uci set firewall.dns_int="redirect"
uci set firewall.dns_int.name="Intercept-DNS"
uci set firewall.dns_int.src="lan"
uci set firewall.dns_int.src_dport="53"
uci set firewall.dns_int.dest_port="9053"
uci set firewall.dns_int.proto="udp"
uci set firewall.dns_int.target="DNAT"
uci -q delete firewall.tcp_int
uci set firewall.tcp_int="redirect"
uci set firewall.tcp_int.name="Intercept-TCP"
uci set firewall.tcp_int.src="lan"
uci set firewall.tcp_int.dest_port="9040"
uci set firewall.tcp_int.proto="tcp"
uci set firewall.tcp_int.extra="--syn"
uci set firewall.tcp_int.target="DNAT"
 
# Disable LAN to WAN forwarding
uci rename firewall.@forwarding[0]="lan_wan"
uci set firewall.lan_wan.enabled="0"
uci commit firewall
/etc/init.d/firewall restart


#get public IP address
wget -q -O- http://ifconfig.me/ip



#Wi-Fi setting RADIO0
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
    uci commit wireless
    wifi reload
fi

#Wi-Fi setting RADIO1
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
    uci commit wireless
    wifi reload
fi

/etc/init.d/cron enable
/etc/init.d/cron start

html='<a style="padding-left: 35px;" target="_blank" href="https://torRouters.com">Mantained with 💜 by TorRouters.com - visit us for support & more stuff</a>'
echo "$html" >> /usr/lib/lua/luci/view/footer.htm

uci set system.@system[0].hostname='TorRouter'
uci set network.lan.ipaddr='192.168.7.1'
uci commit network
uci commit system

echo "[+] - finished flashing, wait for TorRouter to appear at 192.168.7.1......"

/etc/init.d/system reload
/etc/init.d/network reload
