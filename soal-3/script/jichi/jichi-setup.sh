#!/bin/bash
# Setup IP tiap interface Jichi sesuai ketentuan network
ip addr add 10.75.1.1/24 dev eth1 2>/dev/null
ip addr add 10.75.2.1/24 dev eth2 2>/dev/null
ip addr add 10.75.3.1/24 dev eth3 2>/dev/null
ip addr add 10.75.4.1/24 dev eth4 2>/dev/null

ip link set eth1 up
ip link set eth2 up
ip link set eth3 up
ip link set eth4 up

# Konfigurasi Routing & NAT biar subnet di bawahnya bisa akses internet
# (-C mengecek dulu supaya aturan MASQUERADE tidak dobel kalau script dijalankan ulang)
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -P FORWARD ACCEPT

# Install dan konfigurasi DHCP Relay mengarah ke IP Tengen (Data Center)
export DEBIAN_FRONTEND=noninteractive
which dhcrelay >/dev/null 2>&1 || { echo "nameserver 192.168.122.1" > /etc/resolv.conf && apt-get update && apt-get install -y isc-dhcp-relay; }

pkill dhcrelay 2>/dev/null
dhcrelay -i eth2 -i eth3 -i eth4 10.75.4.10
