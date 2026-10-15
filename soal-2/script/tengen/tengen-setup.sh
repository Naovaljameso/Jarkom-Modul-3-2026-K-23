#!/bin/bash
# Setup gateway dan DNS buat narik paket instalasi
ip route add default via 10.75.4.1 2>/dev/null
echo "nameserver 192.168.122.1" > /etc/resolv.conf

export DEBIAN_FRONTEND=noninteractive
which dhcpd >/dev/null 2>&1 || { apt-get update && apt-get install -y isc-dhcp-server tcpdump nano; }

sed -i 's/^INTERFACESv4=.*/INTERFACESv4="eth0"/' /etc/default/isc-dhcp-server
touch /var/lib/dhcp/dhcpd.leases

# Konfigurasi rule DHCP Server (Pool, DNS options, Lease time, dan Fixed IP)
cat > /etc/dhcp/dhcpd.conf << 'DHCF'
default-lease-time 600;
max-lease-time 7200;
ddns-update-style none;
authoritative;

option domain-name "jujutsu.k23.com";
option domain-search "k23.com", "jujutsu.k23.com";
option domain-name-servers 10.75.1.2, 10.75.1.3;

# Kirim option 119 (domain-search) walaupun client tidak memintanya
if exists dhcp-parameter-request-list {
    option dhcp-parameter-request-list = concat(option dhcp-parameter-request-list, 77);
}

# Subnet Network 4 (Lokal Data Center)
subnet 10.75.4.0 netmask 255.255.255.0 {
}

# Subnet Network 2 (Divisi A)
subnet 10.75.2.0 netmask 255.255.255.0 {
    option routers 10.75.2.1;
    option broadcast-address 10.75.2.255;

    class "pool1" { match hardware; }
    subclass "pool1" 1:02:42:03:57:32:00; # MAC itadori
    subclass "pool1" 1:02:42:18:a2:cc:00; # MAC fushiguro

    class "pool2" { match hardware; }
    subclass "pool2" 1:02:42:f9:90:c8:00; # MAC zenin
    subclass "pool2" 1:02:42:ba:b5:0f:00; # MAC okkotsu

    pool {
        allow members of "pool1";
        range 10.75.2.10 10.75.2.35;
    }
    pool {
        allow members of "pool2";
        range 10.75.2.70 10.75.2.95;
    }
}

# Subnet Network 3 (Divisi B)
subnet 10.75.3.0 netmask 255.255.255.0 {
    option routers 10.75.3.1;
    option broadcast-address 10.75.3.255;

    class "short_lease" { match hardware; }
    subclass "short_lease" 1:02:42:fa:45:19:00; # MAC ino
    subclass "short_lease" 1:02:42:51:9c:cc:00; # MAC kusakabe

    class "long_lease" { match hardware; }
    subclass "long_lease" 1:02:42:da:49:14:00; # MAC miwa

    pool {
        allow members of "short_lease";
        default-lease-time 1800;
        max-lease-time 1800;
        range 10.75.3.10 10.75.3.89;
    }
    pool {
        allow members of "long_lease";
        default-lease-time 43200;
        max-lease-time 43200;
        range 10.75.3.100 10.75.3.199;
    }
}

# Static Lease Kugisaki (VIP)
host kugisaki {
    hardware ethernet 02:42:97:95:f8:00;
    fixed-address 10.75.3.99;
    option routers 10.75.3.1;
}
DHCF

# Validasi config dulu; kalau salah, jangan matikan dhcpd yang sedang jalan
/usr/sbin/dhcpd -t -q -cf /etc/dhcp/dhcpd.conf || { echo "dhcpd.conf ERROR, dhcpd tidak di-restart"; exit 1; }

# Restart daemon DHCP
pkill dhcpd 2>/dev/null
sleep 1
/usr/sbin/dhcpd -4 -cf /etc/dhcp/dhcpd.conf eth0
