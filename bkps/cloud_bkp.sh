#!/bin/bash

# Informações para conexão ao servidor remoto
SERVIDOR="8.188.1.11"
PORTA_SSH="2201"
USUARIO="user"

# Informações de armazenamento
PASTA_LOCAL1="/var/www/sites"
PASTA_LOCAL2="/storage/samba/dados"
PASTA_LOCAL3="/mnt/BACKUP/ARQUIVOS/MySQL"
PASTA_LOCAL4="/etc"
PASTA_REMOTA="~/BKP"

# Conf de email
MAIL_TO="sysadmin@empresa.com.br"
MAIL_TO2="supervisor@empresa2.com.br"
MAIL_SUB="EMPRESA BKP: Alerta"
MAIL_CON="Backup nao foi testado, verificar servidor: server.empresa.com.br, script de backup: $0 ."

# Arquivo de LOG.
DATA="`date +%Y_%m_%d`"
LOG="/var/log/sincronizacao_$DATA.log"

# Comando de sincronização
echo "`date` - Inicio da sincronização dos sites com o servidor" >> $LOG
rsync --delete -ave "ssh -p $PORTA_SSH -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" --progress $PASTA_LOCAL1 $USUARIO@$SERVIDOR:$PASTA_REMOTA >> $LOG 2>> $LOG
B1=$(echo $?)
echo "`date` - Fim da sincronização dos sites com o servidor" >> $LOG


echo "`date` - Inicio da sincronização dos dados com o servidor" >> $LOG
rsync --delete -ave "ssh -p $PORTA_SSH -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" --progress $PASTA_LOCAL2 $USUARIO@$SERVIDOR:$PASTA_REMOTA >> $LOG 2>> $LOG
B2=$(echo $?)
echo "`date` - Fim da sincronização dos dados com o servidor" >> $LOG


echo "`date` - Inicio da sincronização dos bancos de dados com o servidor" >> $LOG
rsync --delete -ave "ssh -p $PORTA_SSH -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" --progress $PASTA_LOCAL3 $USUARIO@$SERVIDOR:$PASTA_REMOTA >> $LOG 2>> $LOG
B3=$(echo $?)
echo "`date` - Fim da sincronização dos bancos de dados com o servidor" >> $LOG


echo "`date` - Inicio da sincronização das configurações com o servidor" >> $LOG
rsync --delete -ave "ssh -p $PORTA_SSH -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" --progress $PASTA_LOCAL4 $USUARIO@$SERVIDOR:$PASTA_REMOTA >> $LOG 2>> $LOG
B4=$(echo $?)
echo "`date` - Fim da sincronização das configurações com o servidor" >> $LOG

#Testa resultado de todos os rsync
if [ $B1 -ne 0 ] || [ $B2 -ne 0 ] || [ $B3 -ne 0 ] || [ $B4 -ne 0 ] ; then
	# Caso algum tenha erro
	MAIL_SUB="EMPRESA BKP: Erro - Backups na nuvem"
	MAIL_CON="Servidor: server.empresa.com.br.
Ocorreram erros durante o backup enviado para a nuvem, conferir detalhes em anexo"
	echo "$MAIL_CON" | mutt -s "$MAIL_SUB" $MAIL_TO	$MAIL_TO2 -a $LOG
else 
	MAIL_SUB="EMPRESA BKP: Sucesso - Backups na nuvem"
	MAIL_CON="Servidor: server.empresa.com.br.
Enviado backup para a nuvem com sucesso, detalhes em anexo."
	echo "$MAIL_CON" | mutt -s "$MAIL_SUB" $MAIL_TO $MAIL_TO2 -a $LOG
fi
