#!/bin/bash
# Soal 18 - geto: api_cluster dengan worker cadangan (kirara) + passive health check
#   nanami & todo = utama (WRR 3:1, max_fails=2 fail_timeout=5s)
#   kirara        = backup

# 1. Install Nginx (hanya kalau belum ada)
which nginx >/dev/null 2>&1 || (apt-get update && apt-get install -y nginx)

# 2. Config load balancer
cat > /etc/nginx/sites-available/lb-api <<'EOF'
# Format log: mencatat worker mana yang menjawab (upstream)
log_format geto_log '$remote_addr - [$time_local] "$request" $status '
                    'upstream=$upstream_addr ustatus=$upstream_status realip=$http_x_real_ip';

upstream api_cluster {
    zone api_cluster 64k;
    server 10.75.4.5 weight=3 max_fails=2 fail_timeout=5s;   # nanami (utama)
    server 10.75.4.6 weight=1 max_fails=2 fail_timeout=5s;   # todo   (utama)
    server 10.75.4.7 backup;                                 # kirara (cadangan)
}

server {
    listen 80 default_server;
    server_name jujutsu.k23.com www.jujutsu.k23.com;

    access_log /var/log/nginx/geto_access.log geto_log;

    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/lb-api /etc/nginx/sites-enabled/lb-api
rm -f /etc/nginx/sites-enabled/default

# 3. Cek config, lalu jalankan
nginx -t && (service nginx restart || service nginx start)
