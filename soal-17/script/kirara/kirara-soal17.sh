#!/bin/bash
H=$(hostname)
pgrep nginx >/dev/null || bash /root/$H-soal14.sh

cat > /var/www/api/index.php <<'EOF'
<?php
header('Content-Type: application/json');

$trusted_proxy = '10.75.4.2';
$proxy_ip  = $_SERVER['REMOTE_ADDR'];
$client_ip = $proxy_ip;
$real_ip   = $_SERVER['HTTP_X_REAL_IP'] ?? '';
if ($proxy_ip === $trusted_proxy && filter_var($real_ip, FILTER_VALIDATE_IP)) {
    $client_ip = $real_ip;
}

$worker = gethostname();
$ua     = $_SERVER['HTTP_USER_AGENT'] ?? '';
$xff    = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? '-';
$db     = 'gagal';

mysqli_report(MYSQLI_REPORT_OFF);
$conn = mysqli_init();
$conn->options(MYSQLI_OPT_CONNECT_TIMEOUT, 2);
if (@fsockopen('10.75.4.11', 3306, $en, $es, 0.5) &&
    @$conn->real_connect('10.75.4.11', 'k23', 'k23pass', 'db_shibuya_k23')) {
    $st = $conn->prepare("INSERT INTO request_logs (worker_name, client_ip, proxy_ip, user_agent) VALUES (?, ?, ?, ?)");
    $st->bind_param('ssss', $worker, $client_ip, $proxy_ip, $ua);
    if ($st->execute()) { $db = 'tercatat'; }
    $conn->close();
}

echo json_encode([
    'service'        => 'Jujutsu API',
    'worker'         => $worker,
    'client_ip'      => $client_ip,
    'proxy_ip'       => $proxy_ip,
    'x_forwarded_for'=> $xff,
    'db'             => $db
]);
EOF
echo "[$H] soal 17 siap"
