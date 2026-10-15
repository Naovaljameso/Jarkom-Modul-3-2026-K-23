#!/bin/bash
# Soal 11 - shoko sebagai DNS Slave untuk jujutsu.k23.com

# 1. Install BIND9 (hanya kalau belum ada)
which named >/dev/null 2>&1 || (apt-get update && apt-get install -y bind9 dnsutils)

# 2. Daftarkan zona sebagai slave, ambil salinan dari utahime
cat > /etc/bind/named.conf.local <<'EOF'
zone "jujutsu.k23.com" {
    type slave;
    masters { 10.75.1.2; };
    file "/var/lib/bind/jujutsu.k23.com";
};
EOF

# 3. Cek salah ketik, lalu jalankan
named-checkconf
service named restart
