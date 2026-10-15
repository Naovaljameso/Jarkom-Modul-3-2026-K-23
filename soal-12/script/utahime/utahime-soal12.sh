#!/bin/bash
# Soal 12 - utahime: A record, CNAME, PTR, Forwarder

# 1. Pastikan BIND9 ter-install
which named >/dev/null 2>&1 || (apt-get update && apt-get install -y bind9 dnsutils)
mkdir -p /etc/bind/jarkom

# 2. Forwarder + izinkan client bertanya
cat > /etc/bind/named.conf.options <<'EOF'
options {
    directory "/var/cache/bind";
    forwarders { 192.168.122.1; };
    dnssec-validation no;
    allow-query { any; };
    allow-recursion { any; };
    listen-on-v6 { any; };
};
EOF

# 3. Daftarkan zona utama + zona reverse
cat > /etc/bind/named.conf.local <<'EOF'
zone "jujutsu.k23.com" {
    type master;
    notify yes;
    also-notify { 10.75.1.3; };
    allow-transfer { 10.75.1.3; };
    file "/etc/bind/jarkom/jujutsu.k23.com";
};

zone "1.75.10.in-addr.arpa" {
    type master;
    notify yes;
    also-notify { 10.75.1.3; };
    allow-transfer { 10.75.1.3; };
    file "/etc/bind/jarkom/1.75.10.in-addr.arpa";
};
EOF

# 4. Zona utama: A record ke gojo + CNAME www
cat > /etc/bind/jarkom/jujutsu.k23.com <<'EOF'
$TTL    604800
@       IN      SOA     ns1.jujutsu.k23.com. root.jujutsu.k23.com. (
                        2026101501 ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL
;
@       IN      NS      ns1.jujutsu.k23.com.
@       IN      NS      ns2.jujutsu.k23.com.
ns1     IN      A       10.75.1.2
ns2     IN      A       10.75.1.3
@       IN      A       10.75.1.4
www     IN      CNAME   jujutsu.k23.com.
EOF

# 5. Zona reverse: IP gojo -> nama domain
cat > /etc/bind/jarkom/1.75.10.in-addr.arpa <<'EOF'
$TTL    604800
@       IN      SOA     ns1.jujutsu.k23.com. root.jujutsu.k23.com. (
                        2026101501 ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL
;
@       IN      NS      ns1.jujutsu.k23.com.
@       IN      NS      ns2.jujutsu.k23.com.
4       IN      PTR     jujutsu.k23.com.
EOF

# 6. Cek salah ketik, lalu jalankan ulang
named-checkconf
named-checkzone jujutsu.k23.com /etc/bind/jarkom/jujutsu.k23.com
named-checkzone 1.75.10.in-addr.arpa /etc/bind/jarkom/1.75.10.in-addr.arpa
service named restart
