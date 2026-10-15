#!/bin/bash
# Soal 19 - gojo: Path-Based Routing (soal 16) + Proxy Cache web + Rate Limit /api

# 1. Install Nginx (hanya kalau belum ada)
which nginx >/dev/null 2>&1 || (apt-get update && apt-get install -y nginx)

# 2. Folder penyimpanan cache
mkdir -p /var/cache/nginx/web

# 3. Config reverse proxy
cat > /etc/nginx/sites-available/gojo <<'EOF'
# Format log: + status cache, untuk analisis soal 20
log_format gojo_log '$remote_addr - [$time_local] "$request" $status '
                    'upstream=$upstream_addr cache=$upstream_cache_status rt=$request_time';

# Tempat & aturan penyimpanan cache halaman web
proxy_cache_path /var/cache/nginx/web levels=1:2 keys_zone=web_cache:10m
                 max_size=100m inactive=10m use_temp_path=off;

# Aturan rate limit: 10 request/detik per IP klien
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

upstream web_cluster {
    zone web_cluster 64k;
    server 10.75.4.3;   # maki
    server 10.75.4.4;   # panda
}

server {
    listen 80 default_server;
    server_name jujutsu.k23.com www.jujutsu.k23.com;

    access_log /var/log/nginx/gojo_access.log gojo_log;

    # Halaman web -> maki & panda, DENGAN CACHE 10 menit
    location / {
        proxy_pass http://web_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_cache web_cache;
        proxy_cache_valid 200 10m;
        add_header X-Cache-Status $upstream_cache_status always;
    }

    # API -> geto, DENGAN RATE LIMIT 10 req/s per IP
    location /api {
        limit_req zone=api_limit;
        limit_req_status 429;

        proxy_pass http://10.75.4.2;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/gojo /etc/nginx/sites-enabled/gojo
rm -f /etc/nginx/sites-enabled/default

# 4. Cek config, lalu jalankan
nginx -t && (service nginx restart || service nginx start)
