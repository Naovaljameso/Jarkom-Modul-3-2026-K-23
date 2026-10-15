#!/bin/bash
# Soal 14 - Worker API (nanami/todo/kirara): Nginx + PHP-FPM, catat ke DB yaga, hanya menerima dari geto

# 1. Install Nginx + PHP-FPM + driver MySQL (hanya kalau belum ada)
which nginx >/dev/null 2>&1 && which php >/dev/null 2>&1 && php -m | grep -q mysqli || \
  (apt-get update && apt-get install -y nginx php-fpm php-mysql)

# 2. Cari versi PHP
PHPV=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')

# 3. Script API
mkdir -p /var/www/api
cat > /var/www/api/index.php <<'EOF'
<?php
header('Content-Type: application/json');

// Detail database (disepakati dengan soal 13)
$db_host = "10.75.4.11";
$db_user = "k23";
$db_pass = "k23pass";
$db_name = "db_shibuya_k23";

$worker     = gethostname();
$proxy_ip   = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$client_ip  = $_SERVER['HTTP_X_REAL_IP'] ?? $proxy_ip;
$user_agent = $_SERVER['HTTP_USER_AGENT'] ?? 'unknown';

// Coba catat ke database (maksimal tunggu 2 detik)
mysqli_report(MYSQLI_REPORT_OFF);
$db_status = "belum terhubung";
$conn = mysqli_init();
$conn->options(MYSQLI_OPT_CONNECT_TIMEOUT, 2);
if (@fsockopen($db_host, 3306, $en, $es, 0.5) && @$conn->real_connect($db_host, $db_user, $db_pass, $db_name)) {
    $stmt = $conn->prepare("INSERT INTO request_logs (worker_name, client_ip, proxy_ip, user_agent) VALUES (?, ?, ?, ?)");
    if ($stmt) {
        $stmt->bind_param("ssss", $worker, $client_ip, $proxy_ip, $user_agent);
        $db_status = $stmt->execute() ? "tercatat" : "gagal insert";
        $stmt->close();
    } else {
        $db_status = "tabel belum ada";
    }
    $conn->close();
}

echo json_encode([
    "service"   => "Jujutsu API",
    "worker"    => $worker,
    "client_ip" => $client_ip,
    "proxy_ip"  => $proxy_ip,
    "db"        => $db_status,
]) . "\n";
EOF

# 4. Virtual host: hanya izinkan geto (dan localhost untuk tes)
cat > /etc/nginx/sites-available/api <<EOF
server {
    listen 80 default_server;
    server_name jujutsu.k23.com www.jujutsu.k23.com;

    root /var/www/api;
    index index.php;

    allow 10.75.4.2;   # geto
    allow 127.0.0.1;   # tes lokal
    deny all;

    location / {
        try_files \$uri /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${PHPV}-fpm.sock;
    }
}
EOF

ln -sf /etc/nginx/sites-available/api /etc/nginx/sites-enabled/api
rm -f /etc/nginx/sites-enabled/default

# 5. Jalankan PHP-FPM dan Nginx
service php${PHPV}-fpm restart
nginx -t && (service nginx restart || service nginx start)
