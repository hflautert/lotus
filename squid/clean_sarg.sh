#!/bin/bash
# Script para limpeza do SARG
# hflautert@gmail.com
# 13/03/2015

# Calculo de espaco - estimado
# Usado o maior relatorio de cada pasta  /var/www/sarg/daily weekly e monthly
# Total sarg = 5,1GB

# Mantem diários por até 3 mêses (90 relatorios) - 1.5GB
DIA="90"

# Mantem semanais por até 6 meses (24 relatorios) - 1.4GB
SEM="360"

# Mantem mensais por até 1 ano (12 relatorios) - 2.2GB
ANO="360"

# Remove diretorios antigos em cada pasta, exceto o diretorio images.
find /var/www/sarg/daily/ -type d -mtime +$DIA -prune ! -path ./images -exec rm -Rf {} \;
find /var/www/sarg/weekly/ -type d -mtime +$SEM -prune ! -path ./images -exec rm -Rf {} \;
find /var/www/sarg/monthly/ -type d -mtime +$ANO -prune ! -path ./images -exec rm -Rf {} \;
