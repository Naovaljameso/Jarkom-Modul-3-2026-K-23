#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
exec 9>/root/.jichi-soal10.lock
flock -n 9 || exit 0
exec >>/root/jichi-soal10.log 2>&1
echo "===== $(date) ====="

sysctl -w net.ipv4.ip_forward=1
iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -P FORWARD ACCEPT
echo "nameserver 192.168.122.1" > /etc/resolv.conf

for i in $(seq 1 90); do
    ping -c1 -W2 8.8.8.8 >/dev/null 2>&1 && getent hosts deb.debian.org >/dev/null && break
    echo "menunggu internet ($i)"; sleep 2
done

export DEBIAN_FRONTEND=noninteractive
for t in 1 2 3; do
    command -v dhcrelay >/dev/null && break
    apt-get update && apt-get install -y isc-dhcp-relay
    sleep 3
done

pgrep -x dhcrelay >/dev/null || dhcrelay -i eth2 -i eth3 -i eth4 10.75.4.10
sleep 1
pgrep -a dhcrelay && echo "DHCP RELAY AKTIF" || echo "DHCP RELAY GAGAL"
