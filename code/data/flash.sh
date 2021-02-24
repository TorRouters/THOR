#!/bin/sh
set -e

ping -c1 -W2 openwrt || { echo "[-] - no router!" ; exit 1; }

read -p "[*] - copying files to router, sure?"

scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null init.sh root@openwrt:/tmp/
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null auto-update.sh root@openwrt:/root/
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null cron.sh root@openwrt:/etc/crontabs/root
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@openwrt 'sh /tmp/init.sh'

echo "[+] - TorRouter is at 192.168.7.1"
