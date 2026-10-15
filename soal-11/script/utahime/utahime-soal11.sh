#!/bin/bash
# Soal 11 - utahime sebagai DNS Master untuk jujutsu.k23.com

# 1. Install BIND9 (hanya kalau belum ada)
which named >/dev/null 2>&1 || (apt-get update && apt-get install -y bind9 dnsutils)

# 2. Folder untuk menyimpan file zona
mkdir -p /etc/bind/jarkom

# 3. Daftarkan zona + izin transfer ke shoko
cat > /etc/bind/named.conf.local <<'EOF'
zone "jujutsu.k23.com" {
    type master;
    notify yes;
    also-notify { 10.75.1.3; };
    allow-transfer { 10.75.1.3; };
    file "/etc/bind/jarkom/jujutsu.k23.com";
};
EOF

# 4. Isi buku teleponnya (file zona)
cat > /etc/bind/jarkom/jujutsu.k23.com <<'EOF'
$TTL    604800
@       IN      SOA     ns1.jujutsu.k23.com. root.jujutsu.k23.com. (
                        2026101401 ; Serial (YYYYMMDDXX)
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL
;
@       IN      NS      ns1.jujutsu.k23.com.
@       IN      NS      ns2.jujutsu.k23.com.
ns1     IN      A       10.75.1.2
ns2     IN      A       10.75.1.3
EOF

# 5. Cek tidak ada salah ketik, lalu jalankan
named-checkconf
named-checkzone jujutsu.k23.com /etc/bind/jarkom/jujutsu.k23.com
service named restart
