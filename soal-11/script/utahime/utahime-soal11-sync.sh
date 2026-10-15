#!/bin/bash
# Soal 11 - Uji sinkronisasi: naikkan serial di Master
sed -i 's/2026101401/2026101402/' /etc/bind/jarkom/jujutsu.k23.com
named-checkzone jujutsu.k23.com /etc/bind/jarkom/jujutsu.k23.com
rndc reload jujutsu.k23.com
