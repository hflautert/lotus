#!/bin/bash
# Script que conecta em um conta, confere o número de itens enviados e envia um alerta
# caso não tenha emails enviados em um tempo determinado
# Criado para monitorar emails da nfe

MAIL_TO="monitor@dominio.com.br"
MAIL_FROM="monitor@dominio.com.br"

# Funcao para gravar log
LOG()
{
        logger -t nfecounter[$$] $1
}

SENT_ITENS=$(/usr/local/bin/connect_imap.sh | grep "(MESSAGES " | awk '{print $6}' | cut -d\) -f1)

# Se existe contagem anterior, faz a comparação
if [ -s OLD_SENT_ITENS.txt ]
then
                #Se o numero atual é igual ao anterior
                #alerta nao foram gerados emails nfe
                OLD_SENT_ITENS=$(cat OLD_SENT_ITENS.txt)
                if [ $OLD_SENT_ITENS -eq $SENT_ITENS ]
                then
                        LOG "Não foram gerados emails da NFE nos últimos 30 minutos"
                        MAIL_BODY="Não foram gerados emails da NFE nos últimos 30 minutos"
                        SUBJECT="Piá - NFEs não estão sendo geradas"
                        echo "$MAIL_BODY" | mail -r $MAIL_FROM -s "$SUBJECT" $MAIL_TO

                else
                        #Se o numero atual é maior
                        #Os emails estão sendo gerados
                        LOG "Os emails da nfe estão sendo gerados"
                        #Armazena numero anterior em arquivo
                        echo $SENT_ITENS > OLD_SENT_ITENS.txt
                        exit 0
                        #Caso seja menor, o mes trocou, o valor irá se igualar e a próxima contagem irá detectar.
                fi
else
echo $SENT_ITENS > OLD_SENT_ITENS.txt
fi