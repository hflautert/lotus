#!/bin/sh

# Le os os bloqueios mais comuns das blacklists das ultimas 8 horas e envia por e-mail
# para facilitar a remocao dos IPs

# Diretório dos logs
dir=/var/log/pmta_to_process
dir_temp=/tmp/pmta_temp
mkdir -p $dir_temp

# Arquivo a ser enviado por email
resultado=/var/log/blacklist

# Host
host=`hostname -s`

# Vai para o diretório
cd $dir

###
# Cria lista com arquivos das 8 ultimas horas 480min
find . -type f -cmin -480 | awk -F"./" '{print $2}' > /tmp/lista_pmta_temp

cd $dir_temp

# Cria links simbólicos temporarios para permitir os filtros fgrep + AWK + sort + uniq
for i in $(cat /tmp/lista_pmta_temp)
do
ln -s "$dir/$i" "$i"
done

#
###

# Cria arquivo temporario para guardar resultados
> $resultado

# Inicia os filtros
echo "Principais blacklists" >> $resultado
echo -e "\n" >> $resultado
echo "Bloqueados pela Trend Micro RBL"  >> $resultado
echo "Para remover acesse:" >> $resultado
fgrep "deferred using Trend Micro" * | awk -F"Please see" '{print $2}' | awk -F",," '{print $1}' | sort | uniq >> $resultado
fgrep "blocked using Trend Micro RBL" * | awk -F"Please see" '{print $2}' | awk -F";" '{print $1}' | awk -F",," '{print $1}' | sort | uniq >> $resultado

echo -e "\n" >> $resultado

echo "Bloqueados pela Barracuda"  >> $resultado
echo "Para remover acesse:" >> $resultado
fgrep "http://www.barracudanetworks.com" * | awk -F";" '{print $4}'| awk -F"," '{print $1}' | sort | uniq >> $resultado

echo -e "\n" >> $resultado

echo "Bloqueados pela SORBS"  >> $resultado
echo "Para remover acesse:" >> $resultado
echo "http://www.sorbs.net/cgi-bin/support.pl" >> $resultado
fgrep "http://www.sorbs.net/lookup.shtml" * | awk -F"?" '{print $2}'| awk -F"," '{print $3}' | sort | uniq

echo -e "\n" >> $resultado

echo "Bloqueado pelo UOL"  >> $resultado
echo "Para remover informe os bloqueios para UOL" >> $resultado
echo "Fone INOC-DBA: 15201*800 ou security@uol.com.br" >> $resultado
fgrep "BARREIRA" * | awk -F":" '{print $6}'| awk -F"Restricted" '{print $1}' | sort | uniq >> $resultado

echo -e "\n" >> $resultado

echo "Bloqueados pela CSI Cloudmark"  >> $resultado
echo "Para remover acesse:" >> $resultado
echo "http://csi.cloudmark.com/en/reset/" >> $resultado
fgrep "http://csi.cloudmark.com/reset-request" * | awk -F"=" '{print $3}' | awk -F"for|if|,|to" '{print $1}' | awk -F "[" '{print $1}'| sort | uniq >> $resultado

echo -e "\n" >> $resultado

echo "Acesse a $host e veja os demais bloqueios rodando: /usr/scripts/get_other_blacklists.sh" >> $resultado

cat -v $resultado | mail -s "Problemas de envio por blacklists - $host" sysadmin@yourcompany.com

# Limpa temporários
rm -Rf $dir_temp
rm -Rf /tmp/lista_pmta_temp
rm -Rf $resultado
