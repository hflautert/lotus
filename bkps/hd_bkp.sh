#!/bin/bash

# Diretorio onde sera armazenado o arquivo de backup gerado.
BKP_LOCAL="/mnt/BACKUP/ARQUIVOS"

# Diretorio onde o HD externo sera montado.
BKP_HD_EXTERNO="/mnt/BACKUP/HD_EXTERNO"
LABEL_HD_EXTERNO="BACKUP"

# Conf de email
MAIL_TO="sysadmin@empresa.com.br"
MAIL_TO2="supervisor@empresa.com.br"
MAIL_SUB="EMPRESA BKP: Alerta"
MAIL_CON="Backup nao foi testado, verificar servidor: servidor.empresa.com.br, script de backup: $0 ."

# Caminho completo para o comando tar. # whereis tar.
PATH_RSYNC="`whereis rsync | cut -d" " -f2`"

# Variavel para o dia atual.
DATA_HOJE=$(date +%Y-%m-%d)

# Arquivo de logs padrao.
BKP_LOG="/var/log/backup_hd_$DATA_HOJE.log"
LOG()
{
        echo "$1" >> $BKP_LOG
}

LOG 

##############
# COMANDOS DE BACKUP
##############

# Verifica se existe o arquivo de log.
if [ ! -e $BKP_LOG ]; then
        touch $BKP_LOG
        LOG "Criado arquivo de log: $BKP_LOG com sucesso."
fi

# A partir daqui, comeca o backup em si.
# So altere se realmente souber o que esta fazendo.
LOG "Montagem do HD Externo"
umount /media/BACKUP
mount LABEL="$LABEL_HD_EXTERNO" $BKP_HD_EXTERNO

LOG "Iniciado sincronização com HD Externo"

cd $BKP_LOCAL
$PATH_RSYNC -a $BKP_LOCAL $BKP_HD_EXTERNO/BKP 2>> $BKP_LOG
RES_RSYNC=$(echo $?)
LOG "Terminada a sincronizado."

LOG "Desmontagem do HD Externo"
umount $BKP_HD_EXTERNO

#Testa resultado do rsync
if [ $RES_RSYNC -ne 0 ] ; then
	# Caso algum tenha erro
	MAIL_SUB="EMPRESA BKP: Erro - Backup no HD externo"
	MAIL_CON="Servidor: servidor.empresa.com.br.
Ocorreram erros durante o backup no HD externo, conferir detalhes em anexo."
	echo "$MAIL_CON" | mutt -s "$MAIL_SUB" $MAIL_TO	$MAIL_TO2 -a $BKP_LOG
else 
	MAIL_SUB="EMPRESA BKP: Sucesso - Backup no HD Externo"
	MAIL_CON="Servidor: servidor.empresa.com.br.
Backup realizado com sucesso no HD externo, detalhes em anexo."
	echo "$MAIL_CON" | mutt -s "$MAIL_SUB" $MAIL_TO $MAIL_TO2 -a $BKP_LOG
fi
