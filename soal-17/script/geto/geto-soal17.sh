#!/bin/bash
pgrep nginx >/dev/null || bash /root/geto-soal18.sh

cat > /etc/nginx/conf.d/geto-realip.conf <<'EOF'
set_real_ip_from 10.75.1.4;
real_ip_header   X-Real-IP;

map $http_x_forwarded_for $geto_xff {
    ""      $realip_remote_addr;
    default "$http_x_forwarded_for, $realip_remote_addr";
}
EOF

grep -rl 'proxy_add_x_forwarded_for' /etc/nginx/sites-available/ | xargs -r sed -i 's/\$proxy_add_x_forwarded_for/$geto_xff/'

nginx -t && service nginx restart
