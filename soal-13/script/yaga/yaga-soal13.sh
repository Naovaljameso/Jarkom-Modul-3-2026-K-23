#!/bin/bash
echo "nameserver 192.168.122.1" > /etc/resolv.conf
[ -x /usr/sbin/mariadbd ] || (apt-get update -y && apt-get install -y mariadb-server mariadb-client)

cat > /etc/mysql/mariadb.conf.d/99-k23-master.cnf <<'EOF'
[mysqld]
bind-address  = 0.0.0.0
server-id     = 1
log-bin       = mysql-bin
binlog_format = ROW
EOF

service mariadb restart
for i in $(seq 1 30); do mariadb -u root -e "SELECT 1" >/dev/null 2>&1 && break; sleep 1; done

mariadb -u root <<'EOF'
CREATE DATABASE IF NOT EXISTS db_shibuya_k23;
CREATE USER IF NOT EXISTS 'k23'@'10.75.4.%' IDENTIFIED BY 'k23pass';
GRANT ALL PRIVILEGES ON db_shibuya_k23.* TO 'k23'@'10.75.4.%';
CREATE USER IF NOT EXISTS 'repl'@'10.75.4.12' IDENTIFIED BY 'replpass';
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'repl'@'10.75.4.12';
FLUSH PRIVILEGES;
USE db_shibuya_k23;
CREATE TABLE IF NOT EXISTS request_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    worker_name VARCHAR(50) NOT NULL,
    client_ip VARCHAR(50) NOT NULL,
    proxy_ip VARCHAR(50) NOT NULL,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

mariadb -u root -e "SHOW MASTER STATUS;"
