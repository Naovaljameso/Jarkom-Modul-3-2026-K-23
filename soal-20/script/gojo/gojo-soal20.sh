#!/bin/bash
L=/var/log/nginx/gojo_access.log
E=/var/log/nginx/error.log

echo "== Status per path =="
awk '{
  if ($8==429) k="ditolak-rate-limit";
  else if ($9=="upstream=-") k="dijawab-gojo(cache)";
  else k="diteruskan-ke-upstream";
  print $6, $8, k
}' $L | sort | uniq -c

echo "== Cache untuk / =="
awk '$6=="/" {print $10}' $L | sort | uniq -c

echo "== Kategori =="
awk '{
  s=$8
  if (s==429) rl++
  else if (s>=500) app++
  else if (s==499) conn++
  else if (s>=200 && s<400) ok++
} END {
  printf "berhasil (2xx/3xx)          = %d\n", ok
  printf "ditolak rate limit (429)    = %d\n", rl
  printf "gagal aplikasi (5xx)        = %d\n", app
  printf "koneksi diputus klien (499) = %d\n", conn
}' $L

echo "== error.log =="
echo "limiting requests        : $(grep -c 'limiting requests' $E)"
echo "gagal koneksi ke upstream: $(grep -cE 'connect\(\) failed|upstream timed out|no live upstreams' $E)"
