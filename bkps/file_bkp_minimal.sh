#!/bin/bash
# hflautert@gmail.com

### LEIAME
# Salve em /usr/local/bin/
# chmod +x file_bkp_minimal.sh
# Adicione na /etc/crontab
# 1  18  *  *  * root  file_bkp_minimal.sh > /dev/null 2>&1
###

# Configuracao
MANT_BKP="7"
BKP_INCLUDE="etc var/log"
BKP_DEST="/backup"

# Variavies do script
DATA_HOJE=$(date +%Y-%m-%d)
BKP_PREFIX="bkp_$(hostname -s)"
BKP_LOG="/var/log/$BKP_PREFIX"_"$DATA_HOJE.log"
BKP_NOME="$BKP_PREFIX"_"$DATA_HOJE"

#Funcao de log
LOG()
{
        echo -e "$1\n" >> $BKP_LOG
}

# Verifica se existe diretorio earquivo de log.
if [ ! -e $BKP_LOG ]; then
        touch $BKP_LOG
        LOG "Criado arquivo de log: $BKP_LOG com sucesso."
fi

if [ ! -d $BKP_DEST ]; then
        mkdir -p $BKP_DEST
        LOG "Criado diretorio destino $BKP_DEST com sucesso."
fi

#Limpa logs e arquivos antigos.
cd /var/log
find . -type f -name "$BKP_PREFIX*" -ctime +$MANT_BKP -exec rm -Rf {} \;
LOG "Logs antigos apagados com sucesso."

cd $BKP_DEST
find . -type f -name "$BKP_PREFIX*" -ctime +$MANT_BKP -exec rm -Rf {} \;
LOG "Arquivos antigos apagados com sucesso."

# Comeca gerar o aquivo de Backup.
LOG "Iniciando compactacao de $BKP_NOME.tgz"
cd /
tar -czf $BKP_DEST/$BKP_NOME.tgz $BKP_INCLUDE 2>> $BKP_LOG
BKP_OK=$(echo $?)

LOG "Terminada a compactacao de $BKP_NOME.tgz"

if [ $BKP_OK -ne 0 ] ; then
        LOG "Ocorreram erros durante o backup local do servidor."
else
        LOG "Backup local realizado com sucesso."
fi
