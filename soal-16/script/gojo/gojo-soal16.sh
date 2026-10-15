#!/bin/bash
# Soal 16 - gojo: Public reverse proxy, Path-Based Routing
#   /     -> maki & panda (Round Robin)
#   /api  -> geto (load balancer internal)

# 1. Install Nginx (hanya kalau belum ada)
which nginx >/dev/null 2>&1 || (apt-get update && apt-get install -y nginx)

# 2. Config reverse proxy
cat > /etc/nginx/sites-available/gojo <<'EOF'
# Format log: mencatat ke mana request diteruskan
log_format gojo_log '$remote_addr - [$time_local] "$request" $status '
                    'upstream=$upstream_addr rt=$request_time';

upstream web_cluster {
    zone web_cluster 64k;
    server 10.75.4.3;   # maki
    server 10.75.4.4;   # panda
}

server {
    listen 80 default_server;
    server_name jujutsu.k23.com www.jujutsu.k23.com;

    access_log /var/log/nginx/gojo_access.log gojo_log;

    # Halaman web -> maki & panda
    location / {
        proxy_pass http://web_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # API -> geto
    location /api {
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

# 3. Cek config, lalu jalankan
nginx -t && (service nginx restart || service nginx start)
