#!/bin/bash
#CURRENT_MONTH=$(date +"%Y-%m")
#Caso tenha pastas organizadas por data
#send "tag STATUS \"Itens Enviados/$CURRENT_MONTH\" (MESSAGES)\r"
expect << EOF
spawn openssl s_client -crlf -connect dominioaconectar.com.br:993
expect "* OK"
send "tag login emailacontar@dominio.com.br ssssenhaaaaa\r"
expect "tag OK"
send "tag STATUS \"Itens Enviados\" (MESSAGES)\r"
expect "tag STATUS"
send "tag LOGOUT\r"
expect "tag OK"
expect eof
EOF