#!/bin/bash
echo "nameserver 192.168.122.1" > /etc/resolv.conf
[ -x /usr/sbin/mariadbd ] || (apt-get update -y && apt-get install -y mariadb-server mariadb-client)

cat > /etc/mysql/mariadb.conf.d/99-k23-slave.cnf <<'EOF'
[mysqld]
bind-address = 0.0.0.0
server-id    = 2
relay-log    = relay-bin
read_only    = 1
EOF

service mariadb restart
for i in $(seq 1 30); do mariadb -u root -e "SELECT 1" >/dev/null 2>&1 && break; sleep 1; done

for i in $(seq 1 60); do mariadb -h 10.75.4.11 -u repl -preplpass -e "SELECT 1" >/dev/null 2>&1 && break; sleep 2; done

if mariadb -u root -e "SHOW SLAVE STATUS" | grep -q .; then
    mariadb -u root -e "START SLAVE;"
else
    FIRST_LOG=$(mariadb -h 10.75.4.11 -u repl -preplpass -N -e "SHOW BINARY LOGS" | head -1 | awk '{print $1}')
    mariadb -u root -e "CHANGE MASTER TO MASTER_HOST='10.75.4.11', MASTER_USER='repl', MASTER_PASSWORD='replpass', MASTER_PORT=3306, MASTER_LOG_FILE='$FIRST_LOG', MASTER_LOG_POS=4, MASTER_USE_GTID=no, MASTER_CONNECT_RETRY=10; START SLAVE;"
fi

sleep 3
mariadb -u root -e "SHOW SLAVE STATUS\G" | grep -E "Master_Host|Slave_IO_Running|Slave_SQL_Running|Last_IO_Error|Last_SQL_Error"
