#!/bin/bash

# Deseja manter backups antigos de quantos dias?
MANT_BKP_SER="2"
MANT_BKP_WWW="1"
MANT_BKP_SQL="30"

# Diretorio onde sera armazenado o arquivo de backup gerado.
BKP_LOCAL="/mnt/BACKUP/ARQUIVOS"

# Edite esse arquivo para definir diretorios e/ou arquivos que NAO serao empacotados/compactados.
BKP_EXCLUDE="/mnt/BACKUP/Scripts/exclude"

# Caminho completo para o comando tar. # whereis tar.
PATH_TAR="`whereis tar | cut -d" " -f2`"

# Variavel para o dia atual.
DATA_HOJE=$(date +%Y-%m-%d)

# Prefixo para gerar o arquivo. Esse nome sera seguido da data.
BKP_PREFIX="bkp_`hostname -s`"
BKP_PREFIX_WWW="www_`hostname -s`"
BKP_NOME="$BKP_PREFIX-$DATA_HOJE"
BKP_NOME_WWW="$BKP_PREFIX_WWW-$DATA_HOJE"

# Arquivo de logs padrao.
BKP_LOG="/var/log/backup_$DATA_HOJE.log"

#Funcao de log
LOG()
{
        echo "$1" >> $BKP_LOG
}

# Conf de email
MAIL_TO="sysadmin@empresa.com.br"
MAIL_TO2="supervisor@empresa2.com.br"
MAIL_SUB="EMPRESA BKP: Alerta"
MAIL_CON="Backup nao foi testado, verificar servidor: servidor.empresa.com.br, script de backup: $0 ."

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
LOG "Iniciado backup $BKP_NOME"

cd $BKP_LOCAL
find . -type f -name "$BKP_PREFIX*" -ctime +$MANT_BKP_SER -exec rm -Rf {} \;
LOG "Arquivos antigos apagados com sucesso."
        
find . -type f -name "$BKP_PREFIX_WWW*" -ctime +$MANT_BKP_WWW -exec rm -Rf {} \;
LOG "Arquivos antigos apagados com sucesso."

# Comeca gerar o aquivo de Backup.
LOG "Iniciando compactacao de $BKP_NOME.tgz"
cd /
$PATH_TAR -X $BKP_EXCLUDE -czf $BKP_LOCAL/$BKP_NOME.tgz . 2>> $BKP_LOG
B1=$(echo $?)
LOG "Terminada a compactacao de $BKP_NOME.tgz"

LOG "Iniciando compactacao de $BKP_NOME_WWW.tgz"
cd /var/www/sites
$PATH_TAR -czf $BKP_LOCAL/$BKP_NOME_WWW.tgz . 2>> $BKP_LOG
B2=$(echo $?)
LOG "Terminada a compactacao de $BKP_NOME.tgz"

##############
# COMANDOS DE BACKUP DO MYSQL
##############
mysqldump -u root -p"ellite87" --all-databases > $BKP_LOCAL/MySQL/mysql_$DATA_HOJE.sql
B3=$(echo $?)

cd  $BKP_LOCAL/MySQL
find . -type f -name "mysql_*" -ctime +$MANT_BKP_SQL -exec rm -Rf {} \;

#Testa resultado de todos os backups
if [ $B1 -ne 0 ] || [ $B2 -ne 0 ] || [ $B3 -ne 0 ] ; then
	# Caso algum tenha erro
	MAIL_SUB="EMPRESA BKP: Erro - Backups locais"
	MAIL_CON="Servidor: servidor.empresa.com.br.
Ocorreram erros durante o backup local do servidor, conferir detalhes em anexo."
	echo "$MAIL_CON" | mutt -s "$MAIL_SUB" $MAIL_TO	$MAIL_TO2 -a $BKP_LOG
else 
	MAIL_SUB="EMPRESA BKP: Sucesso - Backups locais"
	MAIL_CON="Servidor: servidor.empresa.com.br.
Backup local realizado com sucesso, detalhes em anexo."
	echo "$MAIL_CON" | mutt -s "$MAIL_SUB" $MAIL_TO $MAIL_TO2 -a $BKP_LOG
fi
