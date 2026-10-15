#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
exec 9>/root/.tengen-soal10.lock
flock -n 9 || exit 0
exec >>/root/tengen-soal10.log 2>&1
echo "===== $(date) ====="

ip route replace default via 10.75.4.1
echo "nameserver 192.168.122.1" > /etc/resolv.conf

for i in $(seq 1 90); do
    ping -c1 -W2 8.8.8.8 >/dev/null 2>&1 && getent hosts deb.debian.org >/dev/null && break
    echo "menunggu internet ($i)"; sleep 2
done

for t in 1 2 3; do
    pgrep -x dhcpd >/dev/null && break
    bash /root/tengen-setup.sh
    sleep 3
done

pgrep -a dhcpd && echo "DHCP SERVER AKTIF" || echo "DHCP SERVER GAGAL"
