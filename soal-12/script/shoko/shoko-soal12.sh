#!/bin/bash
# Soal 12 - shoko: salin zona reverse + forwarder

# 1. Pastikan BIND9 ter-install
which named >/dev/null 2>&1 || (apt-get update && apt-get install -y bind9 dnsutils)

# 2. Forwarder + izinkan client bertanya (sama dengan utahime)
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

# 3. Salin zona utama + zona reverse dari utahime
cat > /etc/bind/named.conf.local <<'EOF'
zone "jujutsu.k23.com" {
    type slave;
    masters { 10.75.1.2; };
    file "/var/lib/bind/jujutsu.k23.com";
};

zone "1.75.10.in-addr.arpa" {
    type slave;
    masters { 10.75.1.2; };
    file "/var/lib/bind/1.75.10.in-addr.arpa";
};
EOF

# 4. Cek salah ketik, lalu jalankan ulang
named-checkconf
service named restart
