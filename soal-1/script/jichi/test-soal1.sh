#!/bin/bash
# Soal 1 - Uji konektivitas jichi ke seluruh host infrastruktur dan ke internet
for ip in 10.75.1.2 10.75.1.3 10.75.1.4 \
          10.75.4.2 10.75.4.3 10.75.4.4 10.75.4.5 10.75.4.6 10.75.4.7 \
          10.75.4.10 10.75.4.11 10.75.4.12 8.8.8.8; do
  ping -c 1 -W 1 $ip > /dev/null && echo "$ip OK" || echo "$ip GAGAL"
done
