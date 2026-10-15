#!/bin/bash
# Soal 14 - Worker frontend (maki/panda): Nginx + PHP-FPM, hanya menerima dari gojo

# 1. Install Nginx + PHP-FPM (hanya kalau belum ada)
which nginx >/dev/null 2>&1 && which php >/dev/null 2>&1 || \
  (apt-get update && apt-get install -y nginx php-fpm)

# 2. Cari versi PHP yang ter-install (misal 8.4) untuk nama service & socket
PHPV=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')

# 3. Halaman web yang menampilkan hostname
mkdir -p /var/www/frontend
cat > /var/www/frontend/index.php <<'EOF'
<?php
$host = gethostname();
?>
<!DOCTYPE html>
<html>
<head><title>Jujutsu High - <?php echo $host; ?></title></head>
<body>
  <h1>Jujutsu High Frontend</h1>
  <p>Dilayani oleh: <b><?php echo $host; ?></b></p>
</body>
</html>
EOF

# 4. Virtual host: hanya izinkan gojo (dan localhost untuk tes)
cat > /etc/nginx/sites-available/frontend <<EOF
server {
    listen 80 default_server;
    server_name jujutsu.k23.com www.jujutsu.k23.com;

    root /var/www/frontend;
    index index.php;

    allow 10.75.1.4;   # gojo
    allow 127.0.0.1;   # tes lokal
    deny all;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${PHPV}-fpm.sock;
    }
}
EOF

ln -sf /etc/nginx/sites-available/frontend /etc/nginx/sites-enabled/frontend
rm -f /etc/nginx/sites-enabled/default

# 5. Jalankan PHP-FPM dan Nginx
service php${PHPV}-fpm restart
nginx -t && (service nginx restart || service nginx start)
