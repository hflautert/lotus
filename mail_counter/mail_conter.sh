#!/bin/bash
# Script que conecta em um conta, confere o n�mero de itens enviados e envia um alerta
# caso n�o tenha emails enviados em um tempo determinado
# Criado para monitorar emails da nfe

MAIL_TO="monitor@dominio.com.br"
MAIL_FROM="monitor@dominio.com.br"

# Funcao para gravar log
LOG()
{
        logger -t nfecounter[$$] $1
}

SENT_ITENS=$(/usr/local/bin/connect_imap.sh | grep "(MESSAGES " | awk '{print $6}' | cut -d\) -f1)

# Se existe contagem anterior, faz a compara��o
if [ -s OLD_SENT_ITENS.txt ]
then
                #Se o numero atual � igual ao anterior
                #alerta nao foram gerados emails nfe
                OLD_SENT_ITENS=$(cat OLD_SENT_ITENS.txt)
                if [ $OLD_SENT_ITENS -eq $SENT_ITENS ]
                then
                        LOG "N�o foram gerados emails da NFE nos �ltimos 30 minutos"
                        MAIL_BODY="N�o foram gerados emails da NFE nos �ltimos 30 minutos"
                        SUBJECT="Pi� - NFEs n�o est�o sendo geradas"
                        echo "$MAIL_BODY" | mail -r $MAIL_FROM -s "$SUBJECT" $MAIL_TO

                else
                        #Se o numero atual � maior
                        #Os emails est�o sendo gerados
                        LOG "Os emails da nfe est�o sendo gerados"
                        #Armazena numero anterior em arquivo
                        echo $SENT_ITENS > OLD_SENT_ITENS.txt
                        exit 0
                        #Caso seja menor, o mes trocou, o valor ir� se igualar e a pr�xima contagem ir� detectar.
                fi
else
echo $SENT_ITENS > OLD_SENT_ITENS.txt
fi