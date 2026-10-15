#!/bin/sh
command -v ab >/dev/null || apk add --no-cache apache2-utils

ab -n 600 -c 30 http://jujutsu.k23.com/    > /root/soal20-ab-root.txt 2>&1
sleep 3
ab -n 600 -c 30 http://jujutsu.k23.com/api > /root/soal20-ab-api.txt  2>&1

for f in /root/soal20-ab-root.txt /root/soal20-ab-api.txt; do
    echo "=================== $f ==================="
    grep -E "Document Path|Complete requests|Failed requests|Connect: .*Receive|Non-2xx|Requests per second|Time per request|  50%|  90%|  99%| 100%" "$f"
done
